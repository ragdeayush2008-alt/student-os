import 'package:flutter/material.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/app_week_utils.dart';
import '../../data/models/academic_calendar_event.dart';
import '../../data/models/exam.dart';
import '../../data/models/task.dart';
import '../auth/auth_service.dart';
import '../exams/exam_controller.dart';
import '../planning/controllers/planning_block_controller.dart';
import '../planning/models/planning_block.dart';
import '../subjects/subject_controller.dart';
import '../tasks/task_controller.dart';
import 'models/schedule_models.dart';
import 'services/free_time_engine.dart';
import 'services/schedule_conflict_detector.dart';

/// The authoritative controller for academic calendar events and unified academic scheduling.
///
/// Owns fixed commitments (classes, labs, lectures, college events, blocked time, appointments)
/// and projects exams, task deadlines, and planning blocks into a unified time layer.
class AcademicScheduleController extends ChangeNotifier {
  AcademicScheduleController._();

  static final AcademicScheduleController instance =
      AcademicScheduleController._();

  static const String storageKey = 'academic_calendar_events';

  final List<AcademicCalendarEvent> _events = [];
  bool _isLoaded = false;

  List<AcademicCalendarEvent> get events => List.unmodifiable(_events);
  bool get isLoaded => _isLoaded;

  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Lifecycle & Isolation ──────────────────────────────────────────

  /// Clears in-memory events without touching persistent storage.
  void clearData() {
    _events.clear();
    _isLoaded = false;
    notifyListeners();
  }

  /// Loads calendar events from local storage for the authenticated user.
  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      clearData();
      return;
    }

    try {
      final jsonList = await StorageService.instance.loadJsonList(
        userId: uid,
        key: storageKey,
      );

      _events.clear();
      if (jsonList != null) {
        for (final item in jsonList) {
          try {
            _events.add(AcademicCalendarEvent.fromJson(item));
          } catch (e) {
            debugPrint('[AcademicScheduleController] Error parsing event: $e');
          }
        }
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AcademicScheduleController] Error loading events: $e');
    }
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final jsonList = _events.map((e) => e.toJson()).toList();
      await StorageService.instance.saveJsonList(
        userId: uid,
        key: storageKey,
        list: jsonList,
      );
    } catch (e) {
      debugPrint('[AcademicScheduleController] Error saving events: $e');
    }
  }

  // ─── CRUD Operations ────────────────────────────────────────────────

  /// Creates and persists a new academic calendar event.
  Future<AcademicCalendarEvent> createEvent({
    required String title,
    String description = '',
    AcademicEventType type = AcademicEventType.classSession,
    required DateTime startAt,
    required DateTime endAt,
    bool allDay = false,
    String? location,
    String? subjectId,
    String? examId,
    String? taskId,
    bool isFixed = true,
    int? colorValue,
    AcademicRecurrenceRule? recurrence,
    int? reminderMinutesBefore,
  }) async {
    final uid = _userId ?? 'anonymous';
    final now = DateTime.now();
    final event = AcademicCalendarEvent(
      id: 'event_${now.microsecondsSinceEpoch}',
      userId: uid,
      title: title.trim(),
      description: description.trim(),
      type: type,
      startAt: startAt,
      endAt: endAt,
      allDay: allDay,
      location: location?.trim().isEmpty ?? true ? null : location!.trim(),
      subjectId: subjectId,
      examId: examId,
      taskId: taskId,
      isFixed: isFixed,
      colorValue: colorValue,
      recurrence: recurrence,
      reminderMinutesBefore: reminderMinutesBefore,
      createdAt: now,
      updatedAt: now,
    );

    _events.add(event);
    await _save();
    notifyListeners();
    return event;
  }

  /// Updates an existing calendar event.
  Future<AcademicCalendarEvent?> updateEvent(
    String id, {
    String? title,
    String? description,
    AcademicEventType? type,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    String? location,
    String? subjectId,
    String? examId,
    String? taskId,
    bool? isFixed,
    int? colorValue,
    AcademicRecurrenceRule? recurrence,
    int? reminderMinutesBefore,
    bool clearLocation = false,
    bool clearSubjectId = false,
    bool clearExamId = false,
    bool clearTaskId = false,
    bool clearColorValue = false,
    bool clearRecurrence = false,
    bool clearReminder = false,
  }) async {
    final index = _events.indexWhere((e) => e.id == id);
    if (index < 0) return null;

    final existing = _events[index];
    final updated = existing.copyWith(
      title: title?.trim(),
      description: description?.trim(),
      type: type,
      startAt: startAt,
      endAt: endAt,
      allDay: allDay,
      location: location?.trim(),
      subjectId: subjectId,
      examId: examId,
      taskId: taskId,
      isFixed: isFixed,
      colorValue: colorValue,
      recurrence: recurrence,
      reminderMinutesBefore: reminderMinutesBefore,
      updatedAt: DateTime.now(),
      clearLocation: clearLocation,
      clearSubjectId: clearSubjectId,
      clearExamId: clearExamId,
      clearTaskId: clearTaskId,
      clearColorValue: clearColorValue,
      clearRecurrence: clearRecurrence,
      clearReminder: clearReminder,
    );

    _events[index] = updated;
    await _save();
    notifyListeners();
    return updated;
  }

  /// Deletes a calendar event by ID.
  Future<bool> deleteEvent(String id) async {
    final countBefore = _events.length;
    _events.removeWhere((e) => e.id == id || e.baseEventId == id);
    if (_events.length != countBefore) {
      await _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Query & Recurrence Expansion ───────────────────────────────────

  /// Returns all events active on [day], including recurring virtual occurrences.
  List<AcademicCalendarEvent> eventsForDay(DateTime day) {
    final targetDate = AppWeekUtils.dateOnly(day);
    final results = <AcademicCalendarEvent>[];

    for (final event in _events) {
      if (event.recurrence == null || !event.recurrence!.isActive) {
        final eventStartDate = AppWeekUtils.dateOnly(event.startAt);
        final eventEndDate = AppWeekUtils.dateOnly(event.endAt);
        if (targetDate.isAtSameMomentAs(eventStartDate) ||
            (targetDate.isAfter(eventStartDate) &&
                (targetDate.isBefore(eventEndDate) ||
                    targetDate.isAtSameMomentAs(eventEndDate)))) {
          results.add(event);
        }
      } else {
        // Expand virtual occurrences for the single target day
        final occurrences = _generateOccurrencesForRange(
          event,
          targetDate,
          targetDate.add(const Duration(days: 1)),
        );
        results.addAll(occurrences);
      }
    }

    results.sort((a, b) => a.startAt.compareTo(b.startAt));
    return results;
  }

  /// Returns all events in the range [start, end], expanding recurring events.
  List<AcademicCalendarEvent> eventsForRange(DateTime start, DateTime end) {
    final startDay = AppWeekUtils.dateOnly(start);
    final endDay = AppWeekUtils.dateOnly(end);
    final results = <AcademicCalendarEvent>[];

    for (final event in _events) {
      if (event.recurrence == null || !event.recurrence!.isActive) {
        final eventStartDate = AppWeekUtils.dateOnly(event.startAt);
        if (!eventStartDate.isBefore(startDay) &&
            !eventStartDate.isAfter(endDay)) {
          results.add(event);
        }
      } else {
        final occurrences = _generateOccurrencesForRange(
          event,
          startDay,
          endDay.add(const Duration(days: 1)),
        );
        results.addAll(occurrences);
      }
    }

    results.sort((a, b) => a.startAt.compareTo(b.startAt));
    return results;
  }

  List<AcademicCalendarEvent> _generateOccurrencesForRange(
    AcademicCalendarEvent baseEvent,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final occurrences = <AcademicCalendarEvent>[];
    final rule = baseEvent.recurrence;
    if (rule == null || !rule.isActive) return occurrences;

    final baseStart = baseEvent.startAt;
    final baseDate = AppWeekUtils.dateOnly(baseStart);
    final duration = baseEvent.endAt.difference(baseStart);

    if (baseDate.isAfter(rangeEnd)) return occurrences;

    DateTime cursor = baseDate;
    int countGenerated = 0;
    int maxLookaheadDays = 365; // Safe bounded virtual search window

    while (cursor.isBefore(rangeEnd) && maxLookaheadDays > 0) {
      maxLookaheadDays--;

      if (rule.until != null && cursor.isAfter(rule.until!)) break;
      if (rule.count != null && countGenerated >= rule.count!) break;

      bool matches = false;
      switch (rule.frequency) {
        case AcademicRecurrenceFrequency.daily:
          final diffDays = cursor.difference(baseDate).inDays;
          matches = diffDays >= 0 && (diffDays % rule.interval == 0);
          break;
        case AcademicRecurrenceFrequency.weekdays:
          matches = cursor.weekday >= 1 &&
              cursor.weekday <= 5 &&
              !cursor.isBefore(baseDate);
          break;
        case AcademicRecurrenceFrequency.weekly:
          final targetDays = rule.daysOfWeek.isNotEmpty
              ? rule.daysOfWeek
              : [baseStart.weekday];
          final weeksDiff =
              (cursor.difference(baseDate).inDays / 7).floor();
          matches = weeksDiff >= 0 &&
              (weeksDiff % rule.interval == 0) &&
              targetDays.contains(cursor.weekday) &&
              !cursor.isBefore(baseDate);
          break;
        case AcademicRecurrenceFrequency.biweekly:
          final targetDays = rule.daysOfWeek.isNotEmpty
              ? rule.daysOfWeek
              : [baseStart.weekday];
          final weeksDiff =
              (cursor.difference(baseDate).inDays / 7).floor();
          matches = weeksDiff >= 0 &&
              (weeksDiff % (rule.interval * 2) == 0) &&
              targetDays.contains(cursor.weekday) &&
              !cursor.isBefore(baseDate);
          break;
        case AcademicRecurrenceFrequency.monthly:
          matches = cursor.day == baseStart.day && !cursor.isBefore(baseDate);
          break;
        case AcademicRecurrenceFrequency.none:
          matches = false;
          break;
      }

      if (matches) {
        countGenerated++;
        if (!cursor.isBefore(rangeStart) && cursor.isBefore(rangeEnd)) {
          final occStart = DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            baseStart.hour,
            baseStart.minute,
          );
          final occEnd = occStart.add(duration);

          final dateStr =
              '${cursor.year}_${cursor.month.toString().padLeft(2, '0')}_${cursor.day.toString().padLeft(2, '0')}';

          occurrences.add(
            baseEvent.copyWith(
              id: '${baseEvent.id}_occ_$dateStr',
              startAt: occStart,
              endAt: occEnd,
              baseEventId: baseEvent.id,
            ),
          );
        }
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    return occurrences;
  }

  // ─── Unified Academic Time Projections ──────────────────────────────

  /// Builds a [UnifiedDaySchedule] projecting fixed commitments, exams, task deadlines,
  /// planning blocks, free-time calculations, and schedule conflicts.
  UnifiedDaySchedule getScheduleForDay(
    DateTime day, {
    List<StudentExam>? examsOverride,
    List<StudentTask>? tasksOverride,
    List<PlanningBlock>? blocksOverride,
  }) {
    final targetDate = AppWeekUtils.dateOnly(day);
    final dayEvents = eventsForDay(targetDate);

    // Project Exams
    final allExams = examsOverride ?? ExamController.instance.exams;
    final dayExams = allExams.where((e) {
      if (e.examDateTime == null) return false;
      return AppWeekUtils.dateOnly(e.examDateTime!) == targetDate;
    }).toList();

    // Project Task Deadlines
    final allTasks = tasksOverride ?? TaskController.instance.tasks;
    final dayDeadlines = allTasks.where((t) {
      if (t.isCompleted) return false;
      if (t.dueDate == null) return false;
      return AppWeekUtils.dateOnly(t.dueDate!) == targetDate;
    }).toList();

    // Project Planning Blocks
    final dayBlocks = blocksOverride ??
        PlanningBlockController.instance.blocksForDay(targetDate);

    // Build Unified Schedule Items
    final items = <UnifiedScheduleItem>[];

    // 1. Fixed Calendar Events
    for (final event in dayEvents) {
      String? subjectName;
      if (event.subjectId != null) {
        subjectName =
            SubjectController.instance.subjectById(event.subjectId!)?.displayName;
      }
      items.add(
        UnifiedScheduleItem(
          id: event.id,
          type: UnifiedScheduleItemType.fixedEvent,
          title: event.title,
          subtitle: subjectName ?? event.description,
          startAt: event.startAt,
          endAt: event.endAt,
          allDay: event.allDay,
          isFixed: event.isFixed,
          color: event.displayColor,
          subjectId: event.subjectId,
          subjectName: subjectName,
          location: event.location,
          rawEvent: event,
          statusLabel: event.type.label,
        ),
      );
    }

    // 2. Exams
    for (final exam in dayExams) {
      final examStart = exam.examDateTime!;
      final examEnd = examStart.add(const Duration(hours: 2));
      items.add(
        UnifiedScheduleItem(
          id: 'exam_proj_${exam.id}',
          type: UnifiedScheduleItemType.exam,
          title: exam.title,
          subtitle: exam.subject.isNotEmpty ? exam.subject : 'Exam',
          startAt: examStart,
          endAt: examEnd,
          allDay: false,
          isFixed: true,
          color: const Color(0xFFE53935),
          subjectName: exam.subject,
          rawExam: exam,
          statusLabel: 'EXAM',
        ),
      );
    }

    // 3. Task Deadlines (Agenda layer, not block)
    for (final task in dayDeadlines) {
      final dueTime = task.dueDate!;
      items.add(
        UnifiedScheduleItem(
          id: 'task_deadline_${task.id}',
          type: UnifiedScheduleItemType.taskDeadline,
          title: task.title,
          subtitle: 'Due today · ${task.priority.label}',
          startAt: dueTime,
          endAt: dueTime,
          allDay: true,
          isFixed: false,
          color: task.priority.color,
          subjectId: task.subjectId,
          rawTask: task,
          statusLabel: 'DUE',
        ),
      );
    }

    // 4. Planning Blocks (Flexible planned work)
    for (final block in dayBlocks) {
      String title = block.customTitle ?? 'Planned Session';
      String? subjectName;
      if (block.subjectId != null) {
        final subj = SubjectController.instance.subjectById(block.subjectId!);
        subjectName = subj?.displayName;
        if (block.customTitle == null && subj != null) {
          title = subj.displayName;
        }
      }
      if (block.taskId != null) {
        final task = allTasks.where((t) => t.id == block.taskId).firstOrNull;
        if (task != null) {
          title = task.title;
        }
      }

      items.add(
        UnifiedScheduleItem(
          id: 'block_proj_${block.id}',
          type: UnifiedScheduleItemType.planningBlock,
          title: title,
          subtitle: subjectName ?? 'Planned Work',
          startAt: block.startAt,
          endAt: block.endAt,
          allDay: false,
          isFixed: false,
          color: const Color(0xFF3B82F6),
          subjectId: block.subjectId,
          subjectName: subjectName,
          rawPlanningBlock: block,
          statusLabel: 'PLAN',
        ),
      );
    }

    // Calculate Availability
    final availability = FreeTimeEngine.calculateDayAvailability(
      targetDate,
      fixedEvents: dayEvents,
      exams: dayExams,
      planningBlocks: dayBlocks,
    );

    // Detect Conflicts
    final conflicts = ScheduleConflictDetector.detectConflictsForDay(
      targetDate,
      items: items,
    );

    // Mark items that have conflicts
    if (conflicts.isNotEmpty) {
      final conflictingIds = <String>{};
      for (final c in conflicts) {
        conflictingIds.add(c.itemA.id);
        conflictingIds.add(c.itemB.id);
      }
      for (int i = 0; i < items.length; i++) {
        if (conflictingIds.contains(items[i].id)) {
          items[i] = items[i].copyWith(hasConflict: true);
        }
      }
    }

    items.sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      return a.startAt.compareTo(b.startAt);
    });

    return UnifiedDaySchedule(
      date: targetDate,
      items: items,
      fixedEvents: dayEvents,
      exams: dayExams,
      taskDeadlines: dayDeadlines,
      planningBlocks: dayBlocks,
      conflicts: conflicts,
      availability: availability,
    );
  }

  /// Builds a [UnifiedWeekSchedule] for the 7-day week starting at [weekDay].
  UnifiedWeekSchedule getScheduleForWeek(DateTime weekDay) {
    final startOfWeek = AppWeekUtils.startOfWeek(weekDay);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final daySchedules = <UnifiedDaySchedule>[];

    int totalCommitted = 0;
    int totalPlanned = 0;
    int totalFree = 0;
    int deadlinesCount = 0;
    int examsCount = 0;
    int conflictsCount = 0;

    for (int i = 0; i < 7; i++) {
      final currentDay = startOfWeek.add(Duration(days: i));
      final daySched = getScheduleForDay(currentDay);
      daySchedules.add(daySched);

      totalCommitted += daySched.totalCommittedMinutes;
      totalPlanned += daySched.totalPlannedMinutes;
      totalFree += daySched.totalFreeMinutes;
      deadlinesCount += daySched.taskDeadlines.length;
      examsCount += daySched.exams.length;
      conflictsCount += daySched.conflicts.length;
    }

    return UnifiedWeekSchedule(
      startOfWeek: startOfWeek,
      endOfWeek: endOfWeek,
      daySchedules: daySchedules,
      totalCommittedMinutes: totalCommitted,
      totalPlannedMinutes: totalPlanned,
      totalFreeMinutes: totalFree,
      deadlinesCount: deadlinesCount,
      examsCount: examsCount,
      conflictsCount: conflictsCount,
    );
  }

  /// Builds a list of [MonthDaySummary] entries for the calendar month of [month].
  List<MonthDaySummary> getScheduleForMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final today = AppWeekUtils.dateOnly(DateTime.now());

    final firstDisplayDay = AppWeekUtils.startOfWeek(firstDayOfMonth);
    final lastDisplayDay = AppWeekUtils.startOfWeek(lastDayOfMonth).add(const Duration(days: 6));

    final summaries = <MonthDaySummary>[];
    DateTime cursor = firstDisplayDay;

    while (!cursor.isAfter(lastDisplayDay)) {
      final daySched = getScheduleForDay(cursor);
      final isCurrentMonth = cursor.month == month.month;
      final isToday = cursor == today;

      summaries.add(
        MonthDaySummary(
          date: cursor,
          isCurrentMonth: isCurrentMonth,
          isToday: isToday,
          hasExams: daySched.hasExams,
          hasDeadlines: daySched.hasDeadlines,
          hasClasses: daySched.hasClasses,
          hasPlanning: daySched.planningBlocks.isNotEmpty,
          hasConflicts: daySched.hasConflicts,
          eventCount: daySched.fixedEvents.length,
          committedMinutes: daySched.totalCommittedMinutes,
        ),
      );

      cursor = cursor.add(const Duration(days: 1));
    }

    return summaries;
  }

  /// Calculates available free time for [day].
  DayAvailability calculateAvailability(DateTime day) {
    final targetDate = AppWeekUtils.dateOnly(day);
    final dayEvents = eventsForDay(targetDate);
    final dayExams = ExamController.instance.exams.where((e) {
      if (e.examDateTime == null) return false;
      return AppWeekUtils.dateOnly(e.examDateTime!) == targetDate;
    }).toList();
    final dayBlocks = PlanningBlockController.instance.blocksForDay(targetDate);

    return FreeTimeEngine.calculateDayAvailability(
      targetDate,
      fixedEvents: dayEvents,
      exams: dayExams,
      planningBlocks: dayBlocks,
    );
  }

  /// Detects all schedule conflicts for [day].
  List<ScheduleConflict> detectConflicts(DateTime day) {
    return getScheduleForDay(day).conflicts;
  }

  /// Finds the next available free time slot on [day] starting from [fromTime].
  DateTime? findNextAvailableSlot(
    DateTime fromTime,
    Duration duration, {
    DateTime? maxTime,
  }) {
    final avail = calculateAvailability(fromTime);
    return FreeTimeEngine.findNextAvailableSlot(
      fromTime: fromTime,
      duration: duration,
      freeWindows: avail.freeWindows,
      maxTime: maxTime,
    );
  }

  /// Automatically reschedules a conflicting flexible planning block to the next available free window.
  ///
  /// Never moves fixed commitments (classes, exams, appointments).
  Future<bool> reschedulePlanningConflict(ScheduleConflict conflict) async {
    if (!conflict.canAutoReschedule) return false;

    // Identify which item is the flexible planning block
    PlanningBlock? blockToMove;
    if (conflict.itemA.rawPlanningBlock != null) {
      blockToMove = conflict.itemA.rawPlanningBlock;
    } else if (conflict.itemB.rawPlanningBlock != null) {
      blockToMove = conflict.itemB.rawPlanningBlock;
    }

    if (blockToMove == null) return false;

    final blockDuration = blockToMove.endAt.difference(blockToMove.startAt);
    final day = AppWeekUtils.dateOnly(blockToMove.startAt);

    // Look for next free slot on the same day after the overlap
    final searchStart = conflict.overlapInterval.end.add(const Duration(minutes: 5));
    DateTime? newStart = findNextAvailableSlot(searchStart, blockDuration);

    // If no slot fits today after overlap, check earlier today or next day
    newStart ??= findNextAvailableSlot(
      DateTime(day.year, day.month, day.day, 8, 0),
      blockDuration,
    );

    if (newStart != null) {
      final newEnd = newStart.add(blockDuration);
      await PlanningBlockController.instance.rescheduleBlock(
        blockToMove.id,
        newStart,
        newEnd,
      );
      notifyListeners();
      return true;
    }

    return false;
  }
}
