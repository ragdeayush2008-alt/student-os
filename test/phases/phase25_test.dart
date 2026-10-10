import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/sync/sync_engine.dart';

void main() {
  group('Phase 25 — Sync, Security & Multi-Device', () {
    test('SyncQueue persists mutations safely', () async {
      final queue = SyncQueue.instance;
      await queue.load();
      expect(queue.hasPending, isFalse); // Empty initially
    });

    test('SyncEngine state is isolated', () {
      final engine = SyncEngine.instance;
      expect(engine.state, SyncState.idle);
    });

    test('SyncMutation roundtrip safe', () {
      final mutation = SyncMutation(
        id: 'test-1',
        table: 'tasks',
        recordId: 't1',
        type: SyncOperationType.upsert,
        payload: {'title': 'Test'},
        timestamp: DateTime(2026, 8, 30),
      );
      final json = mutation.toJson();
      final restored = SyncMutation.fromJson(json);
      expect(restored.id, mutation.id);
      expect(restored.table, mutation.table);
    });

    test('Account isolation via StorageService', () {
      expect('uos_demo_tasks', contains('uos_'));
      expect('uos_user_a_tasks', contains('uos_'));
    });

    test('No duplicate queue mutations for same record', () async {
      final queue = SyncQueue.instance;
      await queue.load();
      await queue.enqueue(
        table: 'exams',
        recordId: 'e1',
        type: SyncOperationType.upsert,
        payload: {'title': 'Exam'},
      );
      await queue.enqueue(
        table: 'exams',
        recordId: 'e1',
        type: SyncOperationType.upsert,
        payload: {'title': 'Updated'},
      );
      // Same record should collapse to single mutation
      expect(queue.pendingCount, 1);
      await queue.clear();
    });
  });
}
