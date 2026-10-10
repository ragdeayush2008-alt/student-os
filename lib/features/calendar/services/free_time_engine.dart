import '../../../core/utils/app_week_utils.dart';
import '../../../data/models/academic_calendar_event.dart';
import '../../../data/models/exam.dart';
import '../../planning/models/planning_block.dart';
import '../models/schedule_models.dart';

/// Deterministic calculation engine for student availability and free time windows.
abstract final class FreeTimeEngine {
  /// Default student daily active window: 08:00 to 22:00 (14 hours = 840 minutes).
  static const int defaultDayStartHour = 8;
  static const int defaultDayEndHour = 22;

  /// Calculates the day availability taking into account fixed commitments and planning blocks.
  static DayAvailability calculateDayAvailability(
    DateTime day, {
    required List<AcademicCalendarEvent> fixedEvents,
    List<StudentExam> exams = const [],
    List<PlanningBlock> planningBlocks = const [],
    int startHour = defaultDayStartHour,
    int endHour = defaultDayEndHour,
    int dailyBudgetMinutes = 840,
  }) {
    final dateOnly = AppWeekUtils.dateOnly(day);
    final dayWindowStart = DateTime(
      dateOnly.year,
      dateOnly.month,
      dateOnly.day,
      startHour,
      0,
    );
    final dayWindowEnd = DateTime(
      dateOnly.year,
      dateOnly.month,
      dateOnly.day,
      endHour,
      0,
    );
    final totalWindowMinutes =
        dayWindowEnd.difference(dayWindowStart).inMinutes.clamp(0, 1440);

    // Collect all busy intervals within the window
    final fixedBusyIntervals = <TimeInterval>[];
    final planningBusyIntervals = <TimeInterval>[];

    // 1. Fixed Academic Calendar Events
    for (final event in fixedEvents) {
      if (event.allDay) {
        fixedBusyIntervals.add(
            TimeInterval(start: dayWindowStart, end: dayWindowEnd));
        continue;
      }
      final clampedStart = event.startAt.isBefore(dayWindowStart)
          ? dayWindowStart
          : (event.startAt.isAfter(dayWindowEnd) ? dayWindowEnd : event.startAt);
      final clampedEnd = event.endAt.isAfter(dayWindowEnd)
          ? dayWindowEnd
          : (event.endAt.isBefore(dayWindowStart) ? dayWindowStart : event.endAt);

      if (clampedEnd.isAfter(clampedStart)) {
        fixedBusyIntervals.add(
            TimeInterval(start: clampedStart, end: clampedEnd));
      }
    }

    // 2. Exams with time
    for (final exam in exams) {
      if (exam.examDateTime != null) {
        final examDate = AppWeekUtils.dateOnly(exam.examDateTime!);
        if (examDate == dateOnly) {
          final examStart = exam.examDateTime!;
          final examEnd = examStart.add(const Duration(hours: 2)); // Default 2h exam sitting
          final clampedStart = examStart.isBefore(dayWindowStart)
              ? dayWindowStart
              : (examStart.isAfter(dayWindowEnd) ? dayWindowEnd : examStart);
          final clampedEnd = examEnd.isAfter(dayWindowEnd)
              ? dayWindowEnd
              : (examEnd.isBefore(dayWindowStart) ? dayWindowStart : examEnd);

          if (clampedEnd.isAfter(clampedStart)) {
            fixedBusyIntervals.add(
                TimeInterval(start: clampedStart, end: clampedEnd));
          }
        }
      }
    }

    // 3. Planning Blocks (Flexible planned work)
    for (final block in planningBlocks) {
      final blockDate = AppWeekUtils.dateOnly(block.startAt);
      if (blockDate == dateOnly) {
        final clampedStart = block.startAt.isBefore(dayWindowStart)
            ? dayWindowStart
            : (block.startAt.isAfter(dayWindowEnd) ? dayWindowEnd : block.startAt);
        final clampedEnd = block.endAt.isAfter(dayWindowEnd)
            ? dayWindowEnd
            : (block.endAt.isBefore(dayWindowStart) ? dayWindowStart : block.endAt);

        if (clampedEnd.isAfter(clampedStart)) {
          planningBusyIntervals.add(
              TimeInterval(start: clampedStart, end: clampedEnd));
        }
      }
    }

    // Merged intervals
    final mergedFixed = mergeIntervals(fixedBusyIntervals);
    int committedMinutes = 0;
    for (final i in mergedFixed) {
      committedMinutes += i.durationMinutes;
    }

    final mergedPlanned = mergeIntervals(planningBusyIntervals);
    int plannedMinutes = 0;
    for (final i in mergedPlanned) {
      plannedMinutes += i.durationMinutes;
    }

    final allBusy = mergeIntervals([...fixedBusyIntervals, ...planningBusyIntervals]);
    final freeWindows = <TimeInterval>[];

    DateTime cursor = dayWindowStart;
    for (final interval in allBusy) {
      if (interval.start.isAfter(cursor)) {
        freeWindows.add(TimeInterval(start: cursor, end: interval.start));
      }
      if (interval.end.isAfter(cursor)) {
        cursor = interval.end;
      }
    }
    if (cursor.isBefore(dayWindowEnd)) {
      freeWindows.add(TimeInterval(start: cursor, end: dayWindowEnd));
    }

    int freeMinutes = 0;
    for (final fw in freeWindows) {
      freeMinutes += fw.durationMinutes;
    }

    // Overload is present if total planned + committed exceeds dailyBudgetMinutes or active window
    final totalAllocated = committedMinutes + plannedMinutes;
    final isOverloaded = totalAllocated > dailyBudgetMinutes || (totalAllocated >= totalWindowMinutes && freeMinutes == 0);
    final overloadMinutes = isOverloaded ? (totalAllocated - dailyBudgetMinutes).clamp(0, 99999) : 0;

    return DayAvailability(
      date: dateOnly,
      dayWindowStart: dayWindowStart,
      dayWindowEnd: dayWindowEnd,
      totalWindowMinutes: totalWindowMinutes,
      committedMinutes: committedMinutes,
      plannedMinutes: plannedMinutes,
      freeMinutes: freeMinutes,
      freeWindows: freeWindows,
      isOverloaded: isOverloaded,
      overloadMinutes: overloadMinutes,
    );
  }

  /// Merges overlapping or adjacent time intervals.
  static List<TimeInterval> mergeIntervals(List<TimeInterval> intervals) {
    if (intervals.isEmpty) return const [];
    final sorted = List<TimeInterval>.from(intervals)
      ..sort((a, b) => a.start.compareTo(b.start));

    final merged = <TimeInterval>[];
    TimeInterval current = sorted.first;

    for (int i = 1; i < sorted.length; i++) {
      final next = sorted[i];
      if (next.start.isBefore(current.end) || next.start.isAtSameMomentAs(current.end)) {
        final maxEnd = next.end.isAfter(current.end) ? next.end : current.end;
        current = TimeInterval(start: current.start, end: maxEnd);
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }

  /// Finds the next available free slot for [duration] starting from or after [fromTime].
  ///
  /// Searches within [freeWindows] on the target day. If not found and [allowSubsequentDays]
  /// is true, can evaluate multiple days.
  static DateTime? findNextAvailableSlot({
    required DateTime fromTime,
    required Duration duration,
    required List<TimeInterval> freeWindows,
    DateTime? maxTime,
  }) {
    final durMinutes = duration.inMinutes;
    if (durMinutes <= 0) return fromTime;

    for (final window in freeWindows) {
      // Start at max(window.start, fromTime)
      DateTime candidateStart =
          window.start.isAfter(fromTime) ? window.start : fromTime;

      // Align to next 5 or 15 minute boundary if strictly after window.start
      if (candidateStart.isAfter(window.start)) {
        final rem = candidateStart.minute % 5;
        if (rem != 0) {
          candidateStart = candidateStart.add(Duration(minutes: 5 - rem));
        }
      }

      final candidateEnd = candidateStart.add(duration);

      if ((candidateEnd.isBefore(window.end) ||
              candidateEnd.isAtSameMomentAs(window.end)) &&
          (maxTime == null || candidateEnd.isBefore(maxTime) || candidateEnd.isAtSameMomentAs(maxTime))) {
        return candidateStart;
      }
    }

    return null;
  }
}
