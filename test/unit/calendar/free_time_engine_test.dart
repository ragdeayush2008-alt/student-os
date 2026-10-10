import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/features/calendar/models/schedule_models.dart';
import 'package:student_os/features/calendar/services/free_time_engine.dart';
import 'package:student_os/features/planning/models/planning_block.dart';

void main() {
  group('FreeTimeEngine Availability & Slot Calculation Tests', () {
    final testDay = DateTime(2026, 9, 22);

    test('1. Empty day produces 100% free window between 08:00 and 22:00 (14 hours)', () {
      final avail = FreeTimeEngine.calculateDayAvailability(
        testDay,
        fixedEvents: const [],
        exams: const [],
        planningBlocks: const [],
      );

      expect(avail.totalWindowMinutes, 840);
      expect(avail.committedMinutes, 0);
      expect(avail.plannedMinutes, 0);
      expect(avail.freeMinutes, 840);
      expect(avail.freeWindows.length, 1);
      expect(avail.freeWindows.first.start, DateTime(2026, 9, 22, 8, 0));
      expect(avail.freeWindows.first.end, DateTime(2026, 9, 22, 22, 0));
      expect(avail.isOverloaded, isFalse);
    });

    test('2. Single fixed class splits day into two free windows', () {
      final classEvent = AcademicCalendarEvent(
        id: 'evt_class',
        userId: 'u1',
        title: 'Math Class',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 30),
      );

      final avail = FreeTimeEngine.calculateDayAvailability(
        testDay,
        fixedEvents: [classEvent],
      );

      expect(avail.committedMinutes, 90);
      expect(avail.freeMinutes, 750);
      expect(avail.freeWindows.length, 2);

      // Window 1: 08:00 to 10:00 (120m)
      expect(avail.freeWindows[0].start, DateTime(2026, 9, 22, 8, 0));
      expect(avail.freeWindows[0].end, DateTime(2026, 9, 22, 10, 0));
      expect(avail.freeWindows[0].durationMinutes, 120);

      // Window 2: 11:30 to 22:00 (630m)
      expect(avail.freeWindows[1].start, DateTime(2026, 9, 22, 11, 30));
      expect(avail.freeWindows[1].end, DateTime(2026, 9, 22, 22, 0));
      expect(avail.freeWindows[1].durationMinutes, 630);
    });

    test('3. Multiple overlapping/adjacent fixed commitments are merged properly', () {
      final event1 = AcademicCalendarEvent(
        id: 'evt_1',
        userId: 'u1',
        title: 'Lecture 1',
        startAt: DateTime(2026, 9, 22, 9, 0),
        endAt: DateTime(2026, 9, 22, 10, 0),
      );
      final event2 = AcademicCalendarEvent(
        id: 'evt_2',
        userId: 'u1',
        title: 'Lecture 2',
        startAt: DateTime(2026, 9, 22, 9, 30),
        endAt: DateTime(2026, 9, 22, 11, 0),
      );

      final avail = FreeTimeEngine.calculateDayAvailability(
        testDay,
        fixedEvents: [event1, event2],
      );

      expect(avail.committedMinutes, 120); // 9:00 to 11:00 = 120 min
      expect(avail.freeWindows.length, 2);
      expect(avail.freeWindows[0].end, DateTime(2026, 9, 22, 9, 0));
      expect(avail.freeWindows[1].start, DateTime(2026, 9, 22, 11, 0));
    });

    test('4. All-day event blocks the entire active day window', () {
      final allDayEvent = AcademicCalendarEvent(
        id: 'evt_sports',
        userId: 'u1',
        title: 'College Sports Day',
        type: AcademicEventType.collegeEvent,
        startAt: DateTime(2026, 9, 22, 0, 0),
        endAt: DateTime(2026, 9, 22, 23, 59),
        allDay: true,
      );

      final avail = FreeTimeEngine.calculateDayAvailability(
        testDay,
        fixedEvents: [allDayEvent],
      );

      expect(avail.committedMinutes, 840);
      expect(avail.freeMinutes, 0);
      expect(avail.freeWindows, isEmpty);
    });

    test('5. Projected Exam incorporates fixed exam sitting time into availability', () {
      final exam = StudentExam(
        id: 'exam_1',
        title: 'Accounts Midterm',
        subject: 'Accountancy',
        examDateTime: DateTime(2026, 9, 22, 14, 0),
      );

      final avail = FreeTimeEngine.calculateDayAvailability(
        testDay,
        fixedEvents: const [],
        exams: [exam],
      );

      // Default 2-hour exam sitting = 120m (14:00 to 16:00)
      expect(avail.committedMinutes, 120);
      expect(avail.freeMinutes, 720);
      expect(avail.freeWindows.length, 2);
      expect(avail.freeWindows[0].end, DateTime(2026, 9, 22, 14, 0));
      expect(avail.freeWindows[1].start, DateTime(2026, 9, 22, 16, 0));
    });

    test('6. PlanningBlocks account for planned minutes separately from committed minutes', () {
      final block = PlanningBlock(
        id: 'block_1',
        userId: 'u1',
        customTitle: 'Revise Economics',
        startAt: DateTime(2026, 9, 22, 16, 0),
        endAt: DateTime(2026, 9, 22, 17, 0),
      );

      final avail = FreeTimeEngine.calculateDayAvailability(
        testDay,
        fixedEvents: const [],
        planningBlocks: [block],
      );

      expect(avail.committedMinutes, 0);
      expect(avail.plannedMinutes, 60);
      expect(avail.freeMinutes, 780);
      expect(avail.freeWindows.length, 2);
    });

    test('7. Overload is detected when commitments + planned work exceed daily window', () {
      final events = [
        AcademicCalendarEvent(
          id: 'evt_1',
          userId: 'u1',
          title: 'Class 1',
          startAt: DateTime(2026, 9, 22, 9, 0),
          endAt: DateTime(2026, 9, 22, 11, 0),
        ),
        AcademicCalendarEvent(
          id: 'evt_2',
          userId: 'u1',
          title: 'Class 2',
          startAt: DateTime(2026, 9, 22, 11, 0),
          endAt: DateTime(2026, 9, 22, 13, 0),
        ),
      ];

      final avail = FreeTimeEngine.calculateDayAvailability(
        testDay,
        fixedEvents: events,
        dailyBudgetMinutes: 180, // Budget 3 hours, commitments 4 hours
      );

      expect(avail.isOverloaded, isTrue);
      expect(avail.overloadMinutes, 60);
    });

    test('8. findNextAvailableSlot finds valid free window aligned to 5-minute boundaries', () {
      final freeWindows = [
        TimeInterval(
          start: DateTime(2026, 9, 22, 8, 0),
          end: DateTime(2026, 9, 22, 9, 0), // 60 min
        ),
        TimeInterval(
          start: DateTime(2026, 9, 22, 13, 0),
          end: DateTime(2026, 9, 22, 15, 0), // 120 min
        ),
      ];

      // 45 min duration starting at 8:00
      final slot1 = FreeTimeEngine.findNextAvailableSlot(
        fromTime: DateTime(2026, 9, 22, 8, 0),
        duration: const Duration(minutes: 45),
        freeWindows: freeWindows,
      );
      expect(slot1, DateTime(2026, 9, 22, 8, 0));

      // 90 min duration starting at 8:00 (doesn't fit in window 1, jumps to window 2 at 13:00)
      final slot2 = FreeTimeEngine.findNextAvailableSlot(
        fromTime: DateTime(2026, 9, 22, 8, 0),
        duration: const Duration(minutes: 90),
        freeWindows: freeWindows,
      );
      expect(slot2, DateTime(2026, 9, 22, 13, 0));

      // Duration larger than all windows returns null
      final slot3 = FreeTimeEngine.findNextAvailableSlot(
        fromTime: DateTime(2026, 9, 22, 8, 0),
        duration: const Duration(minutes: 180),
        freeWindows: freeWindows,
      );
      expect(slot3, isNull);
    });

    test('9. mergeIntervals accurately combines disjoint, overlapping, and contiguous intervals', () {
      final intervals = [
        TimeInterval(
          start: DateTime(2026, 9, 22, 10, 0),
          end: DateTime(2026, 9, 22, 11, 0),
        ),
        TimeInterval(
          start: DateTime(2026, 9, 22, 10, 30),
          end: DateTime(2026, 9, 22, 12, 0),
        ),
        TimeInterval(
          start: DateTime(2026, 9, 22, 14, 0),
          end: DateTime(2026, 9, 22, 15, 0),
        ),
        TimeInterval(
          start: DateTime(2026, 9, 22, 15, 0),
          end: DateTime(2026, 9, 22, 16, 0),
        ),
      ];

      final merged = FreeTimeEngine.mergeIntervals(intervals);
      expect(merged.length, 2);

      // Merged 1: 10:00 to 12:00
      expect(merged[0].start, DateTime(2026, 9, 22, 10, 0));
      expect(merged[0].end, DateTime(2026, 9, 22, 12, 0));

      // Merged 2: 14:00 to 16:00
      expect(merged[1].start, DateTime(2026, 9, 22, 14, 0));
      expect(merged[1].end, DateTime(2026, 9, 22, 16, 0));
    });
  });
}
