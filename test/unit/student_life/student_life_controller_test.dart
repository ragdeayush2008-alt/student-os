import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/student_life/models/life_routine_item.dart';
import 'package:student_os/features/student_life/models/sleep_record.dart';
import 'package:student_os/features/student_life/models/student_life_preferences.dart';
import 'package:student_os/features/student_life/student_life_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 30, 9);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    AppClock.freezeAt(now);
  });

  tearDown(() {
    AppClock.reset();
  });

  group('StudentLifeController — persistence and isolation', () {
    test('E1. stays memory-only when no user is signed in', () async {
      final controller = StudentLifeController.instance;
      await controller.load();

      await controller.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );
      expect(controller.sleepRecords.length, 1);

      // Nothing may be written to a shared namespace: a signed-out load
      // resets to defaults instead of restoring anything.
      await controller.load();
      expect(controller.sleepRecords, isEmpty);
    });

    test('E2. persists a logged night for the signed-in user', () async {
      AuthIsolation.instance.setAuthenticatedUser('sl_user_persist');
      final controller = StudentLifeController.instance;
      await controller.load();

      final record = await controller.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );
      expect(record.durationMinutes, 480);

      await controller.load();
      expect(controller.sleepRecords.length, 1);
      expect(controller.sleepRecords.first.id, record.id);
    });

    test('E3. never leaks sleep data between two users', () async {
      AuthIsolation.instance.setAuthenticatedUser('sl_user_iso_a');
      final controller = StudentLifeController.instance;
      await controller.load();
      await controller.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );

      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.setAuthenticatedUser('sl_user_iso_b');
      await controller.load();
      expect(controller.sleepRecords, isEmpty);

      await controller.logSleep(
        bedtime: DateTime(2026, 9, 28, 23, 30),
        wakeTime: DateTime(2026, 9, 29, 6, 30),
      );
      expect(controller.sleepRecords.length, 1);

      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.setAuthenticatedUser('sl_user_iso_a');
      await controller.load();
      expect(controller.sleepRecords.length, 1);
      expect(controller.sleepRecords.first.bedtime, DateTime(2026, 9, 29, 23));
    });

    test('E4. persists preference changes', () async {
      AuthIsolation.instance.setAuthenticatedUser('sl_user_prefs');
      final controller = StudentLifeController.instance;
      await controller.load();

      await controller.updatePreferences(
        const StudentLifePreferences(
          targetSleepMinutes: 450,
          hydration: HydrationFrequency.frequent,
        ),
      );
      await controller.load();

      expect(controller.preferences.targetSleepMinutes, 450);
      expect(controller.preferences.hydration, HydrationFrequency.frequent);
    });

    test('E5. routine completion survives a reload and is scoped per day', () async {
      AuthIsolation.instance.setAuthenticatedUser('sl_user_completion');
      final controller = StudentLifeController.instance;
      await controller.load();

      final plan = controller.dailyPlan(now);
      final wakeItem = plan.items.firstWhere(
        (i) => i.kind == LifeRoutineKind.wake,
      );
      expect(controller.isRoutineItemDone(now, wakeItem.id), isFalse);

      await controller.toggleRoutineItemDone(now, wakeItem.id);
      expect(controller.isRoutineItemDone(now, wakeItem.id), isTrue);
      expect(
        controller.isRoutineItemDone(now.add(const Duration(days: 1)), wakeItem.id),
        isFalse,
      );

      await controller.load();
      expect(controller.isRoutineItemDone(now, wakeItem.id), isTrue);
      expect(
        controller.dailyPlan(now).items
            .firstWhere((i) => i.id == wakeItem.id)
            .isCompleted,
        isTrue,
      );
    });

    test('E6. daily plan reads live planning blocks without mutating them', () async {
      AuthIsolation.instance.setAuthenticatedUser('sl_user_blocks');
      final blocks = PlanningBlockController.instance;
      await blocks.load();
      final controller = StudentLifeController.instance;
      await controller.load();

      expect(controller.dailyPlan(now).scheduledStudyMinutes, 0);

      await blocks.scheduleBlock(
        'task_1',
        DateTime(2026, 9, 30, 10),
        DateTime(2026, 9, 30, 11, 30),
      );
      await controller.load();

      final plan = controller.dailyPlan(now);
      expect(plan.scheduledStudyMinutes, 90);
      expect(blocks.blocks.length, 1);
      expect(blocks.blocks.first.startAt, DateTime(2026, 9, 30, 10));
    });

    test('E7. records naps separately from night sleep', () async {
      AuthIsolation.instance.setAuthenticatedUser('sl_user_naps');
      final controller = StudentLifeController.instance;
      await controller.load();

      final nap = await controller.logNap(
        start: DateTime(2026, 9, 30, 14),
        minutes: 20,
      );
      expect(nap, isNotNull);
      expect(nap!.type, SleepEntryType.nap);
      expect(controller.sleepSummary().hasData, isFalse);

      await controller.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );
      expect(controller.sleepSummary().hasData, isTrue);
    });

    test('E8. deleting a record removes it from storage', () async {
      AuthIsolation.instance.setAuthenticatedUser('sl_user_delete');
      final controller = StudentLifeController.instance;
      await controller.load();
      final record = await controller.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );

      await controller.deleteSleepRecord(record.id);
      await controller.load();
      expect(controller.sleepRecords, isEmpty);
    });

    test('E9. clearData resets in-memory state', () async {
      AuthIsolation.instance.setAuthenticatedUser('sl_user_clear');
      final controller = StudentLifeController.instance;
      await controller.load();
      await controller.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );

      controller.clearData();
      expect(controller.sleepRecords, isEmpty);
      expect(controller.isLoaded, isFalse);
    });
  });
}
