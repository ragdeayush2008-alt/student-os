import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/sync/sync_engine.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/data/repositories/student_repositories.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/rewards/redemption_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('phase11_test_user');
    await SyncQueue.instance.load();
    await ProgressionController.instance.load();
    await RedemptionController.instance.load();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
  });

  group('Phase 11 — Offline-First & Sync Queue Architecture', () {
    test(
      'SyncQueue enqueues, persists, and collapses record mutations',
      () async {
        final queue = SyncQueue.instance;
        expect(queue.pendingCount, 0);

        await queue.enqueue(
          table: 'tasks',
          recordId: 'task-1',
          type: SyncOperationType.upsert,
          payload: {'title': 'Math Homework'},
        );

        expect(queue.pendingCount, 1);
        expect(queue.queue.first.table, 'tasks');
        expect(queue.queue.first.recordId, 'task-1');

        // Enqueueing an updated version collapses duplicate mutation
        await queue.enqueue(
          table: 'tasks',
          recordId: 'task-1',
          type: SyncOperationType.upsert,
          payload: {'title': 'Math Homework Updated'},
        );

        expect(queue.pendingCount, 1);
        expect(queue.queue.first.payload['title'], 'Math Homework Updated');
      },
    );

    test(
      'TaskRepository performs local-first CRUD and feeds SyncQueue',
      () async {
        final repo = TaskRepository.instance;
        final task = StudentTask(
          id: 't-100',
          title: 'Review Physics Notes',
          priority: TaskPriority.high,
          dueDate: DateTime.now().add(const Duration(days: 2)),
        );

        await repo.save(task);

        final retrieved = await repo.getById('t-100');
        expect(retrieved, isNotNull);
        expect(retrieved!.title, 'Review Physics Notes');

        // Verify sync mutation was queued
        expect(SyncQueue.instance.pendingCount, greaterThanOrEqualTo(1));
        final taskMutation = SyncQueue.instance.queue.firstWhere(
          (m) => m.recordId == 't-100',
        );
        expect(taskMutation.table, 'tasks');
        expect(taskMutation.type, SyncOperationType.upsert);

        // Test delete
        await repo.delete('t-100');
        final afterDelete = await repo.getById('t-100');
        expect(afterDelete, isNull);
      },
    );
  });

  group('Phase 11 — Server-Authoritative Progression & XP Idempotency', () {
    test('XP events are deduplicated by deterministic event ID', () async {
      final progression = ProgressionController.instance;
      final initialXp = progression.totalXp;

      final event = XpEvent(
        id: 'task_completion_unique_123',
        type: XpEventType.taskCompleted,
        amount: 25,
        timestamp: DateTime.now(),
        reason: 'Completed physics assignment',
      );

      final recordedFirst = await progression.recordEvent(event);
      expect(recordedFirst, isTrue);
      expect(progression.totalXp, initialXp + 25);

      // Attempting duplicate event record returns false and does not award XP twice
      final recordedSecond = await progression.recordEvent(event);
      expect(recordedSecond, isFalse);
      expect(progression.totalXp, initialXp + 25);
    });

    test('RedemptionController queues reward transactions and entitlements for sync', () async {
      final progression = ProgressionController.instance;
      // Award enough XP to redeem starter badge (50 XP)
      await progression.recordEvent(
        XpEvent(
          id: 'exam_prep_xp_999',
          type: XpEventType.studySessionCompleted,
          amount: 100,
          timestamp: DateTime.now(),
          reason: 'Study session',
        ),
      );

      final redemption = RedemptionController.instance;
      final result = await redemption.redeemReward('badge_first_steps');

      expect(result.success, isTrue);
      expect(result.transaction, isNotNull);
      expect(result.entitlement, isNotNull);

      // Verify transactions & entitlements queued in sync engine
      final pendingTables = SyncQueue.instance.queue
          .map((m) => m.table)
          .toList();
      expect(pendingTables.contains('reward_transactions'), isTrue);
      expect(pendingTables.contains('student_entitlements'), isTrue);
    });
  });
}
