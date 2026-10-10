import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/features/calendar/models/schedule_models.dart';
import 'package:student_os/features/calendar/services/schedule_conflict_detector.dart';
import 'package:student_os/features/planning/models/planning_block.dart';

void main() {
  group('ScheduleConflictDetector Overlap & Severity Tests', () {
    final testDay = DateTime(2026, 9, 22);

    test('1. Overlap between two fixed events is classified as CONFLICT (cannot auto-reschedule)', () {
      final itemA = UnifiedScheduleItem(
        id: 'evt_1',
        type: UnifiedScheduleItemType.fixedEvent,
        title: 'Accountancy Lecture',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 30),
        isFixed: true,
        color: Colors.blue,
      );

      final itemB = UnifiedScheduleItem(
        id: 'evt_2',
        type: UnifiedScheduleItemType.fixedEvent,
        title: 'Business Studies Class',
        startAt: DateTime(2026, 9, 22, 11, 0),
        endAt: DateTime(2026, 9, 22, 12, 0),
        isFixed: true,
        color: Colors.green,
      );

      final conflicts = ScheduleConflictDetector.detectConflictsForDay(
        testDay,
        items: [itemA, itemB],
      );

      expect(conflicts.length, 1);
      final c = conflicts.first;
      expect(c.severity, ConflictSeverity.conflict);
      expect(c.overlapDuration.inMinutes, 30);
      expect(c.canAutoReschedule, isFalse);
    });

    test('2. Overlap between fixed event and flexible planning block is classified as WARNING with canAutoReschedule = true', () {
      final fixedClass = UnifiedScheduleItem(
        id: 'evt_class',
        type: UnifiedScheduleItemType.fixedEvent,
        title: 'Physics Lab',
        startAt: DateTime(2026, 9, 22, 14, 0),
        endAt: DateTime(2026, 9, 22, 16, 0),
        isFixed: true,
        color: Colors.blue,
      );

      final block = PlanningBlock(
        id: 'blk_study',
        userId: 'u1',
        customTitle: 'Revise Mechanics',
        startAt: DateTime(2026, 9, 22, 15, 0),
        endAt: DateTime(2026, 9, 22, 16, 0),
      );

      final planItem = UnifiedScheduleItem(
        id: 'blk_study_proj',
        type: UnifiedScheduleItemType.planningBlock,
        title: 'Revise Mechanics',
        startAt: block.startAt,
        endAt: block.endAt,
        isFixed: false,
        color: Colors.indigo,
        rawPlanningBlock: block,
      );

      final conflicts = ScheduleConflictDetector.detectConflictsForDay(
        testDay,
        items: [fixedClass, planItem],
      );

      expect(conflicts.length, 1);
      final c = conflicts.first;
      expect(c.severity, ConflictSeverity.warning);
      expect(c.overlapDuration.inMinutes, 60);
      expect(c.canAutoReschedule, isTrue);
    });

    test('3. Overlap between fixed exam and flexible planning block allows auto-reschedule of planning block', () {
      final exam = StudentExam(
        id: 'exam_1',
        title: 'Economics Final',
        subject: 'Economics',
        examDateTime: DateTime(2026, 9, 22, 9, 0),
      );

      final examItem = UnifiedScheduleItem(
        id: 'exam_proj_1',
        type: UnifiedScheduleItemType.exam,
        title: exam.title,
        startAt: DateTime(2026, 9, 22, 9, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
        isFixed: true,
        color: Colors.red,
        rawExam: exam,
      );

      final block = PlanningBlock(
        id: 'blk_1',
        userId: 'u1',
        customTitle: 'Practice Accounts',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 10, 45),
      );

      final planItem = UnifiedScheduleItem(
        id: 'blk_1_proj',
        type: UnifiedScheduleItemType.planningBlock,
        title: 'Practice Accounts',
        startAt: block.startAt,
        endAt: block.endAt,
        isFixed: false,
        color: Colors.indigo,
        rawPlanningBlock: block,
      );

      final conflicts = ScheduleConflictDetector.detectConflictsForDay(
        testDay,
        items: [examItem, planItem],
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.canAutoReschedule, isTrue);
    });

    test('4. Boundary-touching events do NOT trigger a conflict', () {
      final event1 = UnifiedScheduleItem(
        id: 'evt_1',
        type: UnifiedScheduleItemType.fixedEvent,
        title: 'Session 1',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
        isFixed: true,
        color: Colors.blue,
      );

      final event2 = UnifiedScheduleItem(
        id: 'evt_2',
        type: UnifiedScheduleItemType.fixedEvent,
        title: 'Session 2',
        startAt: DateTime(2026, 9, 22, 11, 0),
        endAt: DateTime(2026, 9, 22, 12, 0),
        isFixed: true,
        color: Colors.blue,
      );

      final conflicts = ScheduleConflictDetector.detectConflictsForDay(
        testDay,
        items: [event1, event2],
      );

      expect(conflicts, isEmpty);
    });

    test('5. All-day events and task deadlines with no duration are excluded from time-overlap conflicts', () {
      final allDayEvent = UnifiedScheduleItem(
        id: 'evt_allday',
        type: UnifiedScheduleItemType.fixedEvent,
        title: 'College Fest',
        startAt: DateTime(2026, 9, 22, 0, 0),
        endAt: DateTime(2026, 9, 22, 23, 59),
        allDay: true,
        isFixed: true,
        color: Colors.purple,
      );

      final deadline = UnifiedScheduleItem(
        id: 'task_deadline',
        type: UnifiedScheduleItemType.taskDeadline,
        title: 'Assignment Due',
        startAt: DateTime(2026, 9, 22, 17, 0),
        endAt: DateTime(2026, 9, 22, 17, 0),
        allDay: true,
        isFixed: false,
        color: Colors.orange,
      );

      final regularClass = UnifiedScheduleItem(
        id: 'evt_class',
        type: UnifiedScheduleItemType.fixedEvent,
        title: 'Math Class',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
        isFixed: true,
        color: Colors.blue,
      );

      final conflicts = ScheduleConflictDetector.detectConflictsForDay(
        testDay,
        items: [allDayEvent, deadline, regularClass],
      );

      expect(conflicts, isEmpty);
    });
  });
}
