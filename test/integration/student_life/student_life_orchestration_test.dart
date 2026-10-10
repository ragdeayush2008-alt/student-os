import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/notification_coordinator.dart';
import 'package:student_os/core/services/notification_service.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/student_life/models/life_routine_item.dart';
import 'package:student_os/features/student_life/models/student_life_preferences.dart';
import 'package:student_os/features/student_life/student_life_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 30, 9);
  final day = DateTime(2026, 9, 30);

  Future<void> signIn(String userId) async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    AppClock.freezeAt(now);
    AuthIsolation.instance.setAuthenticatedUser(userId);
    await PlanningBlockController.instance.load();
    await AcademicScheduleController.instance.load();
    await StudentLifeController.instance.load();
  }

  tearDown(() {
    AppClock.reset();
  });

  group('Student Life orchestration — planning + calendar + controller', () {
    test('K1. combines live planning blocks and fixed commitments', () async {
      await signIn('sl_integration_1');
      await AcademicScheduleController.instance.createEvent(
        title: 'Linear Algebra lecture',
        startAt: DateTime(2026, 9, 30, 9),
        endAt: DateTime(2026, 9, 30, 10),
      );
      final block = await PlanningBlockController.instance.scheduleBlock(
        'task_matrices',
        DateTime(2026, 9, 30, 11),
        DateTime(2026, 9, 30, 13),
      );

      final plan = StudentLifeController.instance.dailyPlan(day);

      expect(plan.scheduledStudyMinutes, 120);
      expect(plan.fixedCommitmentCount, 1);
      expect(plan.fixedCommitmentTitles, ['Linear Algebra lecture']);
      expect(plan.sleepWindowStart, DateTime(2026, 9, 30, 23));
      expect(
        PlanningBlockController.instance.blocksForDay(day).single.id,
        block.id,
      );
      expect(block.startAt, DateTime(2026, 9, 30, 11));
    });

    test('K2. reflows a routine item around a lecture', () async {
      await signIn('sl_integration_2');
      await StudentLifeController.instance.updatePreferences(
        const StudentLifePreferences(mealRemindersEnabled: true),
      );
      await AcademicScheduleController.instance.createEvent(
        title: 'Physics lab',
        startAt: DateTime(2026, 9, 30, 12, 30),
        endAt: DateTime(2026, 9, 30, 14),
      );

      final plan = StudentLifeController.instance.dailyPlan(day);
      final lunch = plan.items.firstWhere((i) => i.title == 'Lunch');

      expect(lunch.startAt, DateTime(2026, 9, 30, 14));
    });

    test('K3. keeps completion state when the plan is re-derived', () async {
      await signIn('sl_integration_3');
      final plan = StudentLifeController.instance.dailyPlan(day);
      final wake = plan.items.firstWhere((i) => i.kind == LifeRoutineKind.wake);

      await StudentLifeController.instance.toggleRoutineItemDone(day, wake.id);
      await PlanningBlockController.instance.scheduleBlock(
        'task_new',
        DateTime(2026, 9, 30, 16),
        DateTime(2026, 9, 30, 17),
      );

      final rederived = StudentLifeController.instance.dailyPlan(day);

      expect(
        rederived.items.firstWhere((i) => i.id == wake.id).isCompleted,
        isTrue,
      );
      expect(rederived.scheduledStudyMinutes, 60);
      expect(rederived.completedRoutineCount, 1);
    });

    test('K4. never fabricates sleep when nothing is logged', () async {
      await signIn('sl_integration_4');
      await AcademicScheduleController.instance.createEvent(
        title: 'Study group',
        startAt: DateTime(2026, 9, 30, 18),
        endAt: DateTime(2026, 9, 30, 19),
      );

      final plan = StudentLifeController.instance.dailyPlan(day);
      final summary = StudentLifeController.instance.sleepSummary();

      expect(summary.hasData, isFalse);
      expect(plan.items.any((i) => i.kind == LifeRoutineKind.wake), isTrue);
      expect(StudentLifeController.instance.lastNightBedtimeLabel, isNull);
    });

    test('K5. reflects a logged night in the summary and the plan', () async {
      await signIn('sl_integration_5');
      await StudentLifeController.instance.logSleep(
        bedtime: DateTime(2026, 9, 29, 23, 30),
        wakeTime: DateTime(2026, 9, 30, 6, 30),
      );

      final summary = StudentLifeController.instance.sleepSummary();
      final plan = StudentLifeController.instance.dailyPlan(day);

      expect(summary.lastNightMinutes, 420);
      expect(summary.nightsLogged, 1);
      expect(StudentLifeController.instance.lastNightBedtimeLabel, '23:30');
      expect(
        plan.warnings.any((w) => w.contains('shorter than your')),
        isFalse,
      );
    });

    test('K6. re-derives when a calendar event changes', () async {
      await signIn('sl_integration_6');
      expect(StudentLifeController.instance.dailyPlan(day).fixedCommitmentCount, 0);

      final event = await AcademicScheduleController.instance.createEvent(
        title: 'Seminar',
        startAt: DateTime(2026, 9, 30, 10),
        endAt: DateTime(2026, 9, 30, 11),
      );
      expect(StudentLifeController.instance.dailyPlan(day).fixedCommitmentCount, 1);

      await AcademicScheduleController.instance.deleteEvent(event.id);
      expect(StudentLifeController.instance.dailyPlan(day).fixedCommitmentCount, 0);
    });

    test('K7. sign-out clears memory but the same user keeps their data',
        () async {
      await signIn('sl_integration_7');
      await StudentLifeController.instance.logSleep(
        bedtime: DateTime(2026, 9, 29, 22),
        wakeTime: DateTime(2026, 9, 30, 6),
      );
      await AcademicScheduleController.instance.createEvent(
        title: 'Class',
        startAt: DateTime(2026, 9, 30, 9),
        endAt: DateTime(2026, 9, 30, 10),
      );
      final block = await PlanningBlockController.instance.scheduleBlock(
        'task_keep',
        DateTime(2026, 9, 30, 11),
        DateTime(2026, 9, 30, 12),
      );

      ControllerIsolation.instance.clearAllControllers();

      expect(StudentLifeController.instance.sleepRecords, isEmpty);
      expect(StudentLifeController.instance.preferences.enabled, isTrue);

      AuthIsolation.instance.setAuthenticatedUser('sl_integration_7');
      await PlanningBlockController.instance.load();
      await AcademicScheduleController.instance.load();
      await StudentLifeController.instance.load();

      expect(StudentLifeController.instance.sleepRecords, hasLength(1));
      expect(StudentLifeController.instance.dailyPlan(day).fixedCommitmentCount, 1);
      expect(PlanningBlockController.instance.blocksForDay(day).single.id, block.id);

      AuthIsolation.instance.setAuthenticatedUser('sl_integration_other');
      await AcademicScheduleController.instance.load();
      await StudentLifeController.instance.load();

      expect(StudentLifeController.instance.sleepRecords, isEmpty);
      expect(StudentLifeController.instance.dailyPlan(day).fixedCommitmentCount, 0);
    });

    test('K8. disabled Student Life cancels its reminders', () async {
      await signIn('sl_integration_8');
      await StudentLifeController.instance.updatePreferences(
        const StudentLifePreferences(notificationsEnabled: true),
      );
      await StudentLifeController.instance.updatePreferences(
        const StudentLifePreferences(notificationsEnabled: false),
      );

      expect(NotificationService.instance.hasPermission, isFalse);
      await NotificationCoordinator.instance.reconcileStudentLifeNotifications(
        preferences: StudentLifeController.instance.preferences,
      );
    });
  });
}
