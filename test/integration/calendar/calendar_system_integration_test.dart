import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Calendar & Academic Schedule System Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_user_integration');
      AcademicScheduleController.instance.clearData();
      ExamController.instance.clearData();
      TaskController.instance.clearData();
      PlanningBlockController.instance.clearData();
      SubjectController.instance.clearData();
    });

    tearDown(() {
      AcademicScheduleController.instance.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('1. Complete End-to-End lifecycle: Subject -> Class -> Exam -> Task -> Schedule -> Conflict Resolution', () async {
      final targetDay = DateTime(2026, 9, 22);

      // 1. Add Subject
      final subject = await SubjectController.instance.createSubject(
        name: 'Accountancy',
        color: 0xFF2EC4B6,
      );

      // 2. Add Fixed Class for Subject
      await AcademicScheduleController.instance.createEvent(
        title: 'Accountancy Lecture',
        type: AcademicEventType.lecture,
        subjectId: subject.id,
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 30),
      );

      // 3. Add Exam
      await ExamController.instance.createExam(
        title: 'Accounts Midterm',
        subject: subject.displayName,
        examDateTime: DateTime(2026, 9, 22, 14, 0),
      );

      // 4. Add Task
      final task = await TaskController.instance.createTask(
        title: 'Review Chapter 3 Exercises',
        subjectId: subject.id,
        dueDate: targetDay,
      );

      // 5. Add conflicting study block at 10:30 (during class)
      await PlanningBlockController.instance.scheduleBlock(
        task.id,
        DateTime(2026, 9, 22, 10, 30),
        DateTime(2026, 9, 22, 11, 15),
        subjectId: subject.id,
        customTitle: 'Study Chapter 3',
      );

      // 6. Verify Day Schedule reflects all layers
      final scheduleBefore =
          AcademicScheduleController.instance.getScheduleForDay(targetDay);
      expect(scheduleBefore.items.length, 4);
      expect(scheduleBefore.hasConflicts, isTrue);

      // 7. Resolve conflict automatically
      final conflict = scheduleBefore.conflicts.first;
      final resolved = await AcademicScheduleController.instance
          .reschedulePlanningConflict(conflict);
      expect(resolved, isTrue);

      // 8. Verify post-resolution schedule has zero conflicts
      final scheduleAfter =
          AcademicScheduleController.instance.getScheduleForDay(targetDay);
      expect(scheduleAfter.hasConflicts, isFalse);
      expect(scheduleAfter.availability.committedMinutes, 210); // 90m class + 120m exam
      expect(scheduleAfter.availability.plannedMinutes, 45);
    });

    test('2. User Isolation: User A events are completely segregated from User B', () async {
      // User A creates events
      AuthIsolation.instance.setAuthenticatedUser('user_A_calendar');
      await AcademicScheduleController.instance.createEvent(
        title: 'User A Class',
        startAt: DateTime(2026, 9, 22, 9, 0),
        endAt: DateTime(2026, 9, 22, 10, 0),
      );

      expect(AcademicScheduleController.instance.events.length, 1);
      expect(AcademicScheduleController.instance.events.first.title, 'User A Class');

      // Logout / User Switch
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();

      // User B logs in
      AuthIsolation.instance.setAuthenticatedUser('user_B_calendar');
      await AcademicScheduleController.instance.load();

      // User B must see 0 events from User A
      expect(AcademicScheduleController.instance.events, isEmpty);

      // User B creates their own event
      await AcademicScheduleController.instance.createEvent(
        title: 'User B Workshop',
        startAt: DateTime(2026, 9, 22, 13, 0),
        endAt: DateTime(2026, 9, 22, 14, 0),
      );

      expect(AcademicScheduleController.instance.events.length, 1);
      expect(AcademicScheduleController.instance.events.first.title, 'User B Workshop');

      // Switch back to User A
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();

      AuthIsolation.instance.setAuthenticatedUser('user_A_calendar');
      await AcademicScheduleController.instance.load();

      // User A sees only their original event
      expect(AcademicScheduleController.instance.events.length, 1);
      expect(AcademicScheduleController.instance.events.first.title, 'User A Class');
    });

    test('3. Offline Persistence: Events and Recurrences survive controller reload', () async {
      AuthIsolation.instance.setAuthenticatedUser('user_persistence_cal');
      await AcademicScheduleController.instance.createEvent(
        title: 'Recurring Friday Lab',
        type: AcademicEventType.lab,
        startAt: DateTime(2026, 9, 25, 14, 0),
        endAt: DateTime(2026, 9, 25, 16, 0),
        location: 'Lab 4B',
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.weekly,
          daysOfWeek: [5],
        ),
      );

      // Clear in-memory
      AcademicScheduleController.instance.clearData();
      expect(AcademicScheduleController.instance.events, isEmpty);

      // Reload from storage
      await AcademicScheduleController.instance.load();
      expect(AcademicScheduleController.instance.events.length, 1);

      final event = AcademicScheduleController.instance.events.first;
      expect(event.title, 'Recurring Friday Lab');
      expect(event.type, AcademicEventType.lab);
      expect(event.location, 'Lab 4B');
      expect(event.recurrence?.frequency, AcademicRecurrenceFrequency.weekly);
      expect(event.recurrence?.daysOfWeek, [5]);
    });
  });
}
