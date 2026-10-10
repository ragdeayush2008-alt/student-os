import 'package:flutter/material.dart';

import '../../../data/models/academic_calendar_event.dart';
import '../../../data/models/exam.dart';
import '../../../data/models/task.dart';
import '../../planning/models/planning_block.dart';

/// The category of a unified schedule item on the academic calendar.
enum UnifiedScheduleItemType {
  fixedEvent,
  exam,
  taskDeadline,
  planningBlock,
  freeSlot,
}

/// A unified projection of any academic commitment, planned work, exam, or deadline.
@immutable
class UnifiedScheduleItem {
  const UnifiedScheduleItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle = '',
    required this.startAt,
    required this.endAt,
    this.allDay = false,
    this.isFixed = true,
    required this.color,
    this.subjectId,
    this.subjectName,
    this.location,
    this.rawEvent,
    this.rawExam,
    this.rawTask,
    this.rawPlanningBlock,
    this.statusLabel,
    this.hasConflict = false,
  });

  final String id;
  final UnifiedScheduleItemType type;
  final String title;
  final String subtitle;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;
  final bool isFixed;
  final Color color;
  final String? subjectId;
  final String? subjectName;
  final String? location;
  final AcademicCalendarEvent? rawEvent;
  final StudentExam? rawExam;
  final StudentTask? rawTask;
  final PlanningBlock? rawPlanningBlock;
  final String? statusLabel;
  final bool hasConflict;

  Duration get duration => endAt.difference(startAt);
  int get durationMinutes => duration.inMinutes;

  bool get isExam => type == UnifiedScheduleItemType.exam;
  bool get isFixedEvent => type == UnifiedScheduleItemType.fixedEvent;
  bool get isPlanningBlock => type == UnifiedScheduleItemType.planningBlock;
  bool get isTaskDeadline => type == UnifiedScheduleItemType.taskDeadline;
  bool get isFreeSlot => type == UnifiedScheduleItemType.freeSlot;

  UnifiedScheduleItem copyWith({
    String? id,
    UnifiedScheduleItemType? type,
    String? title,
    String? subtitle,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    bool? isFixed,
    Color? color,
    String? subjectId,
    String? subjectName,
    String? location,
    AcademicCalendarEvent? rawEvent,
    StudentExam? rawExam,
    StudentTask? rawTask,
    PlanningBlock? rawPlanningBlock,
    String? statusLabel,
    bool? hasConflict,
  }) {
    return UnifiedScheduleItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      allDay: allDay ?? this.allDay,
      isFixed: isFixed ?? this.isFixed,
      color: color ?? this.color,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      location: location ?? this.location,
      rawEvent: rawEvent ?? this.rawEvent,
      rawExam: rawExam ?? this.rawExam,
      rawTask: rawTask ?? this.rawTask,
      rawPlanningBlock: rawPlanningBlock ?? this.rawPlanningBlock,
      statusLabel: statusLabel ?? this.statusLabel,
      hasConflict: hasConflict ?? this.hasConflict,
    );
  }
}

/// A contiguous time window.
@immutable
class TimeInterval {
  TimeInterval({
    required this.start,
    required this.end,
  }) : assert(!end.isBefore(start), 'TimeInterval end cannot be before start');

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);
  int get durationMinutes => duration.inMinutes;

  bool contains(DateTime time) =>
      (time.isAfter(start) || time.isAtSameMomentAs(start)) &&
      (time.isBefore(end) || time.isAtSameMomentAs(end));

  bool overlapsWith(TimeInterval other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  TimeInterval? overlap(TimeInterval other) {
    if (!overlapsWith(other)) return null;
    final maxStart = start.isAfter(other.start) ? start : other.start;
    final minEnd = end.isBefore(other.end) ? end : other.end;
    if (minEnd.isBefore(maxStart)) return null;
    return TimeInterval(start: maxStart, end: minEnd);
  }
}

/// Severity classification for schedule conflicts.
enum ConflictSeverity {
  conflict('Conflict', Icons.error_outline_rounded, Color(0xFFE53935)),
  warning('Warning', Icons.warning_amber_rounded, Color(0xFFFFA000)),
  info('Notice', Icons.info_outline_rounded, Color(0xFF29B6F6));

  const ConflictSeverity(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// A detected overlap between two schedule items.
@immutable
class ScheduleConflict {
  const ScheduleConflict({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    required this.itemA,
    required this.itemB,
    required this.overlapInterval,
    this.canAutoReschedule = false,
  });

  final String id;
  final ConflictSeverity severity;
  final String title;
  final String description;
  final UnifiedScheduleItem itemA;
  final UnifiedScheduleItem itemB;
  final TimeInterval overlapInterval;
  final bool canAutoReschedule;

  Duration get overlapDuration => overlapInterval.duration;
  int get overlapMinutes => overlapDuration.inMinutes;
}

/// Deterministic calculation of available and committed time for a day.
@immutable
class DayAvailability {
  const DayAvailability({
    required this.date,
    required this.dayWindowStart,
    required this.dayWindowEnd,
    required this.totalWindowMinutes,
    required this.committedMinutes,
    required this.plannedMinutes,
    required this.freeMinutes,
    required this.freeWindows,
    this.isOverloaded = false,
    this.overloadMinutes = 0,
  });

  final DateTime date;
  final DateTime dayWindowStart;
  final DateTime dayWindowEnd;
  final int totalWindowMinutes;
  final int committedMinutes;
  final int plannedMinutes;
  final int freeMinutes;
  final List<TimeInterval> freeWindows;
  final bool isOverloaded;
  final int overloadMinutes;

  int get remainingUnallocatedMinutes =>
      (totalWindowMinutes - committedMinutes - plannedMinutes).clamp(0, 99999);
}

/// Full unified day schedule combining all time layers for a given day.
@immutable
class UnifiedDaySchedule {
  const UnifiedDaySchedule({
    required this.date,
    required this.items,
    required this.fixedEvents,
    required this.exams,
    required this.taskDeadlines,
    required this.planningBlocks,
    required this.conflicts,
    required this.availability,
  });

  final DateTime date;
  final List<UnifiedScheduleItem> items;
  final List<AcademicCalendarEvent> fixedEvents;
  final List<StudentExam> exams;
  final List<StudentTask> taskDeadlines;
  final List<PlanningBlock> planningBlocks;
  final List<ScheduleConflict> conflicts;
  final DayAvailability availability;

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get hasExams => exams.isNotEmpty;
  bool get hasDeadlines => taskDeadlines.isNotEmpty;
  bool get hasClasses => fixedEvents.any((e) =>
      e.type == AcademicEventType.classSession ||
      e.type == AcademicEventType.lecture ||
      e.type == AcademicEventType.lab);

  int get totalCommittedMinutes => availability.committedMinutes;
  int get totalPlannedMinutes => availability.plannedMinutes;
  int get totalFreeMinutes => availability.freeMinutes;
}

/// Full unified week schedule combining all days of the selected week.
@immutable
class UnifiedWeekSchedule {
  const UnifiedWeekSchedule({
    required this.startOfWeek,
    required this.endOfWeek,
    required this.daySchedules,
    required this.totalCommittedMinutes,
    required this.totalPlannedMinutes,
    required this.totalFreeMinutes,
    required this.deadlinesCount,
    required this.examsCount,
    required this.conflictsCount,
  });

  final DateTime startOfWeek;
  final DateTime endOfWeek;
  final List<UnifiedDaySchedule> daySchedules;
  final int totalCommittedMinutes;
  final int totalPlannedMinutes;
  final int totalFreeMinutes;
  final int deadlinesCount;
  final int examsCount;
  final int conflictsCount;
}

/// Month day summary for compact month view.
@immutable
class MonthDaySummary {
  const MonthDaySummary({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.hasExams,
    required this.hasDeadlines,
    required this.hasClasses,
    required this.hasPlanning,
    required this.hasConflicts,
    required this.eventCount,
    required this.committedMinutes,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool hasExams;
  final bool hasDeadlines;
  final bool hasClasses;
  final bool hasPlanning;
  final bool hasConflicts;
  final int eventCount;
  final int committedMinutes;
}
