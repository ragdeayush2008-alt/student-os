import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/intelligence/autopilot_engine.dart';
import 'package:student_os/core/navigation/universal_action_executor.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Planning & Autopilot Calendar Integration Tests', () {
    final targetDay = DateTime(2026, 9, 22);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_user_planning_cal');
      AcademicScheduleController.instance.clearData();
      PlanningBlockController.instance.clearData();
      TaskController.instance.clearData();
      SubjectController.instance.clearData();
    });

    tearDown(() {
      AcademicScheduleController.instance.clearData();
      PlanningBlockController.instance.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('1. PlanningEngine.generateDailyPlan places flexible study sessions around fixed calendar commitments', () {
      // Fixed Class: 09:00 to 10:30
      final classEvent = AcademicCalendarEvent(
        id: 'evt_class',
        userId: 'u1',
        title: 'Morning Class',
        startAt: DateTime(2026, 9, 22, 9, 0),
        endAt: DateTime(2026, 9, 22, 10, 30),
      );

      final task = StudentTask(
        id: 'task_homework',
        title: 'Math Assignment',
        estimatedMinutes: 45,
        dueDate: targetDay,
      );

      final plan = PlanningEngine.generateDailyPlan(
        targetDay,
        tasks: [task],
        calendarEvents: [classEvent],
        baseStartTime: DateTime(2026, 9, 22, 9, 0),
      );

      expect(plan.items.length, 1);
      final plannedItem = plan.items.first;

      // Because class is 09:00 to 10:30, the task must start AT or AFTER 10:30 (e.g. 10:35)
      expect(
        plannedItem.suggestedStart.isAfter(DateTime(2026, 9, 22, 10, 29)),
        isTrue,
      );
      expect(plannedItem.estimatedMinutes, 45);
    });

    test('2. Multiple fixed events create discrete available windows for study planning', () {
      final class1 = AcademicCalendarEvent(
        id: 'evt_1',
        userId: 'u1',
        title: 'Class 1',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
      );
      final lunch = AcademicCalendarEvent(
        id: 'evt_lunch',
        userId: 'u1',
        title: 'Lunch',
        type: AcademicEventType.blockedTime,
        startAt: DateTime(2026, 9, 22, 13, 0),
        endAt: DateTime(2026, 9, 22, 14, 0),
      );

      final subject = Subject(
        id: 'sub_acc',
        name: 'Accountancy',
        color: 0xFF2EC4B6,
      );

      final task1 = StudentTask(
        id: 't1',
        title: 'Task in morning gap',
        estimatedMinutes: 60,
        dueDate: targetDay,
      );

      final plan = PlanningEngine.generateDailyPlan(
        targetDay,
        tasks: [task1],
        subjects: [subject],
        calendarEvents: [class1, lunch],
        availableBudgetMinutes: 180,
        baseStartTime: DateTime(2026, 9, 22, 9, 0),
      );

      expect(plan.items.isNotEmpty, isTrue);
      // Verify no item overlaps 10:00-11:00 or 13:00-14:00
      for (final item in plan.items) {
        if (!item.isAlreadyScheduled) {
          final overlapsClass1 = item.suggestedStart.isBefore(class1.endAt) &&
              item.suggestedEnd.isAfter(class1.startAt);
          final overlapsLunch = item.suggestedStart.isBefore(lunch.endAt) &&
              item.suggestedEnd.isAfter(lunch.startAt);
          expect(overlapsClass1, isFalse);
          expect(overlapsLunch, isFalse);
        }
      }
    });

    test('3. Planning blocks remain PlanningBlock instances and are never turned into CalendarEvent entities', () async {
      final block = await PlanningBlockController.instance.scheduleBlock(
        null,
        DateTime(2026, 9, 22, 14, 0),
        DateTime(2026, 9, 22, 14, 45),
        customTitle: 'Economics Revision',
      );

      expect(block, isA<PlanningBlock>());
      expect(PlanningBlockController.instance.blocks.length, 1);
      // Calendar events list must remain 0 — no automatic pollution of calendar storage
      expect(AcademicScheduleController.instance.events, isEmpty);
    });

    test('4. AutopilotDayState derives accurate workload and health state', () {
      final subject = Subject(
        id: 'sub_math',
        name: 'Mathematics',
        color: 0xFF3B82D8,
      );

      final block1 = PlanningBlock(
        id: 'b1',
        userId: 'u1',
        customTitle: 'Calculus Session 1',
        startAt: DateTime(2026, 9, 22, 9, 0),
        endAt: DateTime(2026, 9, 22, 10, 0),
      );
      final block2 = PlanningBlock(
        id: 'b2',
        userId: 'u1',
        customTitle: 'Calculus Session 2',
        startAt: DateTime(2026, 9, 22, 10, 30),
        endAt: DateTime(2026, 9, 22, 11, 30),
      );

      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: targetDay,
        subjects: [subject],
        blocks: [block1, block2],
        availableBudgetMinutes: 180,
      );

      expect(state.plannedMinutes, 120);
      expect(state.healthState, DayHealthState.onTrack);
      expect(state.isOverloaded, isFalse);
    });

    test('5. UniversalActionExecutor provides comprehensive calendar event action descriptors', () {
      final actionsFixed =
          UniversalActionExecutor.calendarEventActions(isFixed: true);
      final actionsFlexible =
          UniversalActionExecutor.calendarEventActions(isFixed: false);

      expect(actionsFixed.any((a) => a.id == UniversalCalendarEventAction.view), isTrue);
      expect(actionsFixed.any((a) => a.id == UniversalCalendarEventAction.edit), isTrue);
      expect(actionsFixed.any((a) => a.id == UniversalCalendarEventAction.planAround), isTrue);
      expect(actionsFixed.any((a) => a.id == UniversalCalendarEventAction.viewDay), isTrue);
      expect(actionsFixed.any((a) => a.id == UniversalCalendarEventAction.delete), isTrue);

      expect(actionsFlexible.length, actionsFixed.length);
    });
  });
}
