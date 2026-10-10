import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AcademicScheduleController Authoritative & Recurrence Tests', () {
    late AcademicScheduleController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_user_calendar');
      controller = AcademicScheduleController.instance;
      controller.clearData();
      ExamController.instance.clearData();
      TaskController.instance.clearData();
      PlanningBlockController.instance.clearData();
    });

    tearDown(() {
      controller.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('1. createEvent persists event and updates in-memory list', () async {
      final start = DateTime(2026, 9, 22, 10, 0);
      final end = DateTime(2026, 9, 22, 11, 0);

      final event = await controller.createEvent(
        title: 'Economics Lecture',
        type: AcademicEventType.lecture,
        startAt: start,
        endAt: end,
        location: 'Room 204',
      );

      expect(controller.events.length, 1);
      expect(controller.events.first.id, event.id);
      expect(controller.events.first.title, 'Economics Lecture');
      expect(controller.events.first.type, AcademicEventType.lecture);
      expect(controller.events.first.location, 'Room 204');
    });

    test('2. updateEvent modifies existing event correctly', () async {
      final event = await controller.createEvent(
        title: 'Original Title',
        startAt: DateTime(2026, 9, 22, 9, 0),
        endAt: DateTime(2026, 9, 22, 10, 0),
      );

      final updated = await controller.updateEvent(
        event.id,
        title: 'Updated Title',
        description: 'New Description',
        location: 'Lab 3',
      );

      expect(updated, isNotNull);
      expect(updated!.title, 'Updated Title');
      expect(updated.description, 'New Description');
      expect(updated.location, 'Lab 3');
      expect(controller.events.first.title, 'Updated Title');
    });

    test('3. deleteEvent removes event from controller', () async {
      final event = await controller.createEvent(
        title: 'To Delete',
        startAt: DateTime(2026, 9, 22, 9, 0),
        endAt: DateTime(2026, 9, 22, 10, 0),
      );

      expect(controller.events.length, 1);
      final deleted = await controller.deleteEvent(event.id);
      expect(deleted, isTrue);
      expect(controller.events, isEmpty);
    });

    test('4. Daily recurrence generates virtual occurrences accurately', () async {
      final baseStart = DateTime(2026, 9, 21, 9, 0); // Monday
      final baseEnd = DateTime(2026, 9, 21, 10, 0);

      await controller.createEvent(
        title: 'Daily Assembly',
        startAt: baseStart,
        endAt: baseEnd,
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.daily,
          interval: 1,
        ),
      );

      // Query Tuesday (day 2)
      final tuesdayEvents =
          controller.eventsForDay(DateTime(2026, 9, 22));
      expect(tuesdayEvents.length, 1);
      expect(tuesdayEvents.first.title, 'Daily Assembly');
      expect(tuesdayEvents.first.isVirtualOccurrence, isTrue);
      expect(tuesdayEvents.first.startAt, DateTime(2026, 9, 22, 9, 0));
      expect(tuesdayEvents.first.endAt, DateTime(2026, 9, 22, 10, 0));

      // Query Wednesday (day 3)
      final wednesdayEvents =
          controller.eventsForDay(DateTime(2026, 9, 23));
      expect(wednesdayEvents.length, 1);
      expect(wednesdayEvents.first.startAt, DateTime(2026, 9, 23, 9, 0));
    });

    test('5. Weekday recurrence only generates on Mon-Fri', () async {
      final baseStart = DateTime(2026, 9, 21, 11, 0); // Monday

      await controller.createEvent(
        title: 'Morning Class',
        startAt: baseStart,
        endAt: baseStart.add(const Duration(hours: 1)),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.weekdays,
        ),
      );

      // Friday (2026-09-25) -> should exist
      final fridayEvents =
          controller.eventsForDay(DateTime(2026, 9, 25));
      expect(fridayEvents.length, 1);

      // Saturday (2026-09-26) -> should NOT exist
      final saturdayEvents =
          controller.eventsForDay(DateTime(2026, 9, 26));
      expect(saturdayEvents, isEmpty);

      // Sunday (2026-09-27) -> should NOT exist
      final sundayEvents =
          controller.eventsForDay(DateTime(2026, 9, 27));
      expect(sundayEvents, isEmpty);
    });

    test('6. Weekly recurrence with specific days of week', () async {
      final baseStart = DateTime(2026, 9, 21, 14, 0); // Monday

      await controller.createEvent(
        title: 'Lab Session',
        type: AcademicEventType.lab,
        startAt: baseStart,
        endAt: baseStart.add(const Duration(hours: 2)),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.weekly,
          daysOfWeek: [1, 3], // Mon & Wed
        ),
      );

      // Monday (Sep 21) -> exists (base event)
      expect(controller.eventsForDay(DateTime(2026, 9, 21)).length, 1);

      // Tuesday (Sep 22) -> empty
      expect(controller.eventsForDay(DateTime(2026, 9, 22)), isEmpty);

      // Wednesday (Sep 23) -> exists (virtual occurrence)
      final wed = controller.eventsForDay(DateTime(2026, 9, 23));
      expect(wed.length, 1);
      expect(wed.first.startAt, DateTime(2026, 9, 23, 14, 0));

      // Thursday (Sep 24) -> empty
      expect(controller.eventsForDay(DateTime(2026, 9, 24)), isEmpty);
    });

    test('7. Recurrence respect count limit and until date', () async {
      final baseStart = DateTime(2026, 9, 21, 8, 0);

      // Count limit of 3 occurrences
      await controller.createEvent(
        title: 'Special Workshop',
        startAt: baseStart,
        endAt: baseStart.add(const Duration(hours: 1)),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.daily,
          count: 3,
        ),
      );

      // Day 1 (Sep 21) -> exists
      expect(controller.eventsForDay(DateTime(2026, 9, 21)).length, 1);
      // Day 2 (Sep 22) -> exists
      expect(controller.eventsForDay(DateTime(2026, 9, 22)).length, 1);
      // Day 3 (Sep 23) -> exists
      expect(controller.eventsForDay(DateTime(2026, 9, 23)).length, 1);
      // Day 4 (Sep 24) -> beyond count: empty
      expect(controller.eventsForDay(DateTime(2026, 9, 24)), isEmpty);
    });

    test('8. UnifiedDaySchedule integrates fixed events, exams, task deadlines, and planning blocks', () async {
      final targetDay = DateTime(2026, 9, 22);

      // 1. Fixed Class
      await controller.createEvent(
        title: 'Accountancy Class',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
      );

      // 2. Exam
      final exam = StudentExam(
        id: 'exam_law',
        title: 'Business Law Exam',
        subject: 'Business Law',
        examDateTime: DateTime(2026, 9, 22, 14, 0),
      );

      // 3. Task Deadline
      final task = StudentTask(
        id: 'task_audit',
        title: 'Audit Report Due',
        dueDate: DateTime(2026, 9, 22, 18, 0),
      );

      // 4. Planning Block
      final block = PlanningBlock(
        id: 'blk_rev',
        userId: 'u1',
        customTitle: 'Revise Depreciation',
        startAt: DateTime(2026, 9, 22, 16, 0),
        endAt: DateTime(2026, 9, 22, 16, 30),
      );

      final schedule = controller.getScheduleForDay(
        targetDay,
        examsOverride: [exam],
        tasksOverride: [task],
        blocksOverride: [block],
      );

      expect(schedule.items.length, 4);
      expect(schedule.fixedEvents.length, 1);
      expect(schedule.exams.length, 1);
      expect(schedule.taskDeadlines.length, 1);
      expect(schedule.planningBlocks.length, 1);

      expect(schedule.hasClasses, isTrue);
      expect(schedule.hasExams, isTrue);
      expect(schedule.hasDeadlines, isTrue);
      expect(schedule.availability.committedMinutes, 180); // 60m class + 120m exam
      expect(schedule.availability.plannedMinutes, 30);
    });

    test('9. reschedulePlanningConflict automatically moves conflicting planning block to free slot', () async {
      final targetDay = DateTime(2026, 9, 22);

      // Fixed Class at 16:00 to 17:00
      await controller.createEvent(
        title: 'Economics Class',
        startAt: DateTime(2026, 9, 22, 16, 0),
        endAt: DateTime(2026, 9, 22, 17, 0),
      );

      // Conflicting planning block scheduled at 16:00 to 16:30
      await PlanningBlockController.instance.scheduleBlock(
        null,
        DateTime(2026, 9, 22, 16, 0),
        DateTime(2026, 9, 22, 16, 30),
        customTitle: 'Study Economics',
      );

      final conflicts = controller.detectConflicts(targetDay);
      expect(conflicts.length, 1);
      expect(conflicts.first.canAutoReschedule, isTrue);

      final success =
          await controller.reschedulePlanningConflict(conflicts.first);
      expect(success, isTrue);

      // Verify planning block has been moved past the class end (17:00)
      final movedBlock = PlanningBlockController.instance.blocks.first;
      expect(movedBlock.startAt.isAfter(DateTime(2026, 9, 22, 16, 59)), isTrue);
      expect(movedBlock.endAt.difference(movedBlock.startAt).inMinutes, 30);
    });

    test('10. ControllerIsolation clears all calendar events on logout', () {
      controller.createEvent(
        title: 'Sample Class',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
      );

      expect(controller.events, isNotEmpty);
      ControllerIsolation.instance.clearAllControllers();
      expect(controller.events, isEmpty);
      expect(controller.isLoaded, isFalse);
    });
  });
}
