import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/calendar/models/schedule_models.dart';

void main() {
  group('Schedule Models & Value Objects Unit Tests', () {
    test('1. UnifiedScheduleItem identifies types accurately', () {
      final start = DateTime(2026, 9, 22, 10, 0);
      final end = DateTime(2026, 9, 22, 11, 0);

      final fixedItem = UnifiedScheduleItem(
        id: '1',
        type: UnifiedScheduleItemType.fixedEvent,
        title: 'Class',
        startAt: start,
        endAt: end,
        color: Colors.blue,
      );
      expect(fixedItem.isFixedEvent, isTrue);
      expect(fixedItem.isExam, isFalse);
      expect(fixedItem.isPlanningBlock, isFalse);
      expect(fixedItem.isTaskDeadline, isFalse);
      expect(fixedItem.durationMinutes, 60);

      final examItem = fixedItem.copyWith(type: UnifiedScheduleItemType.exam);
      expect(examItem.isExam, isTrue);

      final planItem = fixedItem.copyWith(type: UnifiedScheduleItemType.planningBlock);
      expect(planItem.isPlanningBlock, isTrue);

      final deadlineItem = fixedItem.copyWith(type: UnifiedScheduleItemType.taskDeadline);
      expect(deadlineItem.isTaskDeadline, isTrue);
    });

    test('2. TimeInterval contains, overlapsWith, and overlap calculations', () {
      final t1 = TimeInterval(
        start: DateTime(2026, 9, 22, 10, 0),
        end: DateTime(2026, 9, 22, 12, 0),
      );

      final t2 = TimeInterval(
        start: DateTime(2026, 9, 22, 11, 0),
        end: DateTime(2026, 9, 22, 13, 0),
      );

      final t3 = TimeInterval(
        start: DateTime(2026, 9, 22, 13, 0),
        end: DateTime(2026, 9, 22, 14, 0),
      );

      expect(t1.contains(DateTime(2026, 9, 22, 11, 0)), isTrue);
      expect(t1.contains(DateTime(2026, 9, 22, 12, 30)), isFalse);

      expect(t1.overlapsWith(t2), isTrue);
      expect(t1.overlapsWith(t3), isFalse);

      final overlap = t1.overlap(t2);
      expect(overlap, isNotNull);
      expect(overlap!.start, DateTime(2026, 9, 22, 11, 0));
      expect(overlap.end, DateTime(2026, 9, 22, 12, 0));
      expect(overlap.durationMinutes, 60);

      expect(t1.overlap(t3), isNull);
    });

    test('3. DayAvailability computes remaining unallocated minutes cleanly', () {
      final avail = DayAvailability(
        date: DateTime(2026, 9, 22),
        dayWindowStart: DateTime(2026, 9, 22, 8, 0),
        dayWindowEnd: DateTime(2026, 9, 22, 22, 0),
        totalWindowMinutes: 840,
        committedMinutes: 180,
        plannedMinutes: 120,
        freeMinutes: 540,
        freeWindows: [
          TimeInterval(
            start: DateTime(2026, 9, 22, 13, 0),
            end: DateTime(2026, 9, 22, 22, 0),
          ),
        ],
        isOverloaded: false,
      );

      expect(avail.totalWindowMinutes, 840);
      expect(avail.committedMinutes, 180);
      expect(avail.plannedMinutes, 120);
      expect(avail.freeMinutes, 540);
      expect(avail.remainingUnallocatedMinutes, 540);
      expect(avail.isOverloaded, isFalse);
    });

    test('4. UnifiedDaySchedule convenience getters operate accurately', () {
      final classEvent = AcademicCalendarEvent(
        id: 'c1',
        userId: 'u1',
        title: 'Class',
        type: AcademicEventType.classSession,
        startAt: DateTime(2026, 9, 22, 9, 0),
        endAt: DateTime(2026, 9, 22, 10, 0),
      );

      final exam = StudentExam(
        id: 'e1',
        title: 'Exam',
        examDateTime: DateTime(2026, 9, 22, 14, 0),
      );

      final task = StudentTask(
        id: 't1',
        title: 'Task',
        dueDate: DateTime(2026, 9, 22),
      );

      final schedule = UnifiedDaySchedule(
        date: DateTime(2026, 9, 22),
        items: const [],
        fixedEvents: [classEvent],
        exams: [exam],
        taskDeadlines: [task],
        planningBlocks: const [],
        conflicts: const [],
        availability: DayAvailability(
          date: DateTime(2026, 9, 22),
          dayWindowStart: DateTime(2026, 9, 22, 8, 0),
          dayWindowEnd: DateTime(2026, 9, 22, 22, 0),
          totalWindowMinutes: 840,
          committedMinutes: 180,
          plannedMinutes: 0,
          freeMinutes: 660,
          freeWindows: const [],
        ),
      );

      expect(schedule.hasClasses, isTrue);
      expect(schedule.hasExams, isTrue);
      expect(schedule.hasDeadlines, isTrue);
      expect(schedule.hasConflicts, isFalse);
      expect(schedule.totalCommittedMinutes, 180);
      expect(schedule.totalFreeMinutes, 660);
    });

    test('5. MonthDaySummary encapsulates daily flags for calendar grid', () {
      final summary = MonthDaySummary(
        date: DateTime(2026, 9, 22),
        isCurrentMonth: true,
        isToday: true,
        hasExams: true,
        hasDeadlines: true,
        hasClasses: true,
        hasPlanning: true,
        hasConflicts: false,
        eventCount: 3,
        committedMinutes: 180,
      );

      expect(summary.isCurrentMonth, isTrue);
      expect(summary.isToday, isTrue);
      expect(summary.hasExams, isTrue);
      expect(summary.hasDeadlines, isTrue);
      expect(summary.hasClasses, isTrue);
      expect(summary.hasPlanning, isTrue);
      expect(summary.eventCount, 3);
    });
  });
}
