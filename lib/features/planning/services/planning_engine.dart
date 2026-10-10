import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/services/notification_coordinator.dart';
import '../../../core/utils/app_week_utils.dart';
import '../../../data/models/academic_calendar_event.dart';
import '../../../data/models/exam.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/task.dart';
import '../../../data/models/topic.dart';
import '../../calendar/academic_schedule_controller.dart';
import '../../knowledge/academic_knowledge_controller.dart';
import '../../../core/intelligence/academic_knowledge_engine.dart';
import '../../focus/controller/focus_controller.dart';
import '../../focus/data/models/focus_mission.dart';
import '../../subjects/subject_controller.dart';
import '../controllers/planning_block_controller.dart';
import '../models/planning_block.dart';

/// Type of primary action on the Planning workspace.
enum PlanningActionType {
  current,     // In progress right now
  next,        // Upcoming today
  recommended, // Recommended actionable task or study session
  none,
}

/// Structured state for the primary Next / Current action on the Plan workspace.
@immutable
class CurrentOrNextAction {
  const CurrentOrNextAction({
    required this.type,
    this.block,
    this.task,
    this.subject,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    this.remainingMinutes,
    this.startAt,
    this.endAt,
    this.isSubject = false,
  });

  final PlanningActionType type;
  final PlanningBlock? block;
  final StudentTask? task;
  final Subject? subject;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final int? remainingMinutes;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isSubject;

  bool get isCurrent => type == PlanningActionType.current;
  bool get isNext => type == PlanningActionType.next;
  bool get isRecommended => type == PlanningActionType.recommended;
}

/// A scheduled planning block from earlier today that ended without being completed.
@immutable
class MissedSession {
  const MissedSession({
    required this.block,
    required this.title,
    this.subject,
    this.task,
    required this.durationMinutes,
    required this.scheduledStart,
    required this.scheduledEnd,
  });

  final PlanningBlock block;
  final String title;
  final Subject? subject;
  final StudentTask? task;
  final int durationMinutes;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
}

/// A deterministic, explainable recommendation for "What should I do now?".
@immutable
class PlanningRecommendation {
  const PlanningRecommendation({
    this.task,
    this.subject,
    required this.title,
    required this.reason,
    required this.score,
    required this.estimatedMinutes,
    this.examTitle,
    this.daysUntilExam,
    this.isSubjectBlock = false,
  });

  final StudentTask? task;
  final Subject? subject;
  final String title;
  final String reason;
  final double score;
  final int estimatedMinutes;
  final String? examTitle;
  final int? daysUntilExam;
  final bool isSubjectBlock;

  @override
  String toString() =>
      'PlanningRecommendation(title: $title, reason: $reason, score: $score, isSubject: $isSubjectBlock)';
}

/// Workload metrics for a specific day.
@immutable
class DayWorkload {
  const DayWorkload({
    required this.date,
    required this.totalTasksCount,
    required this.completedTasksCount,
    required this.remainingTasksCount,
    required this.estimatedMinutesRemaining,
    required this.scheduledMinutes,
    required this.completedMinutes,
    required this.overdueEstimatedMinutes,
    required this.availableMinutes,
  });

  final DateTime date;
  final int totalTasksCount;
  final int completedTasksCount;
  final int remainingTasksCount;
  final int estimatedMinutesRemaining;
  final int scheduledMinutes;
  final int completedMinutes;
  final int overdueEstimatedMinutes;
  final int availableMinutes;

  /// Total planned workload in minutes.
  int get plannedMinutes =>
      scheduledMinutes > estimatedMinutesRemaining
          ? scheduledMinutes
          : estimatedMinutesRemaining;

  /// Remaining workload in minutes.
  int get remainingMinutes =>
      (plannedMinutes - completedMinutes).clamp(0, 99999);

  /// Whether planned workload exceeds the available time budget.
  bool get isOverloaded =>
      (estimatedMinutesRemaining > availableMinutes) ||
      (scheduledMinutes > availableMinutes);

  /// Number of minutes exceeding the available budget.
  int get overloadMinutes => isOverloaded
      ? ((plannedMinutes - availableMinutes).clamp(0, 99999))
      : 0;

  /// Task completion ratio based on task count (0.0 to 1.0).
  double get progress =>
      totalTasksCount == 0 ? 0.0 : (completedTasksCount / totalTasksCount).clamp(0.0, 1.0);

  /// Minute-based completion ratio (0.0 to 1.0).
  double get minuteCompletionRatio {
    final total = completedMinutes + estimatedMinutesRemaining;
    if (total <= 0) return completedTasksCount > 0 ? 1.0 : 0.0;
    return (completedMinutes / total).clamp(0.0, 1.0);
  }
}

/// Workload summary for a week.
@immutable
class WeekWorkload {
  const WeekWorkload({
    required this.days,
    required this.totalEstimatedMinutes,
    required this.totalCompletedMinutes,
    required this.totalScheduledMinutes,
    required this.overloadedDaysCount,
    required this.weeklyCompletionRate,
  });

  final List<DayWorkload> days;
  final int totalEstimatedMinutes;
  final int totalCompletedMinutes;
  final int totalScheduledMinutes;
  final int overloadedDaysCount;
  final double weeklyCompletionRate;
}

/// An individual suggested item in a daily plan (task or subject study).
@immutable
class DailyPlanItem {
  const DailyPlanItem({
    this.task,
    this.subject,
    required this.title,
    this.subjectId,
    this.taskId,
    this.topicId,
    this.chapterId,
    this.examId,
    required this.estimatedMinutes,
    required this.suggestedStart,
    required this.suggestedEnd,
    required this.reason,
    required this.isAlreadyScheduled,
    this.existingBlockId,
  });

  final StudentTask? task;
  final Subject? subject;
  final String title;
  final String? subjectId;
  final String? taskId;
  final String? topicId;
  final String? chapterId;
  final String? examId;
  final int estimatedMinutes;
  final DateTime suggestedStart;
  final DateTime suggestedEnd;
  final String reason;
  final bool isAlreadyScheduled;
  final String? existingBlockId;

  bool get isTask => task != null || (taskId != null && taskId!.isNotEmpty);
  bool get isSubject => !isTask && (subject != null || (subjectId != null && subjectId!.isNotEmpty));

  DailyPlanItem copyWith({
    StudentTask? task,
    Subject? subject,
    String? title,
    String? subjectId,
    String? taskId,
    String? topicId,
    String? chapterId,
    String? examId,
    int? estimatedMinutes,
    DateTime? suggestedStart,
    DateTime? suggestedEnd,
    String? reason,
    bool? isAlreadyScheduled,
    String? existingBlockId,
  }) {
    return DailyPlanItem(
      task: task ?? this.task,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      taskId: taskId ?? this.taskId,
      topicId: topicId ?? this.topicId,
      chapterId: chapterId ?? this.chapterId,
      examId: examId ?? this.examId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      suggestedStart: suggestedStart ?? this.suggestedStart,
      suggestedEnd: suggestedEnd ?? this.suggestedEnd,
      reason: reason ?? this.reason,
      isAlreadyScheduled: isAlreadyScheduled ?? this.isAlreadyScheduled,
      existingBlockId: existingBlockId ?? this.existingBlockId,
    );
  }
}

/// A structured daily plan generated deterministically.
@immutable
class DailyPlanResult {
  const DailyPlanResult({
    required this.targetDay,
    required this.availableBudgetMinutes,
    required this.totalPlannedMinutes,
    required this.items,
    required this.deferredTasksCount,
    required this.isOverloaded,
    required this.overloadMinutes,
    required this.summary,
  });

  final DateTime targetDay;
  final int availableBudgetMinutes;
  final int totalPlannedMinutes;
  final List<DailyPlanItem> items;
  final int deferredTasksCount;
  final bool isOverloaded;
  final int overloadMinutes;
  final String summary;

  bool get hasItems => items.isNotEmpty;

  DailyPlanResult copyWith({
    DateTime? targetDay,
    int? availableBudgetMinutes,
    int? totalPlannedMinutes,
    List<DailyPlanItem>? items,
    int? deferredTasksCount,
    bool? isOverloaded,
    int? overloadMinutes,
    String? summary,
  }) {
    return DailyPlanResult(
      targetDay: targetDay ?? this.targetDay,
      availableBudgetMinutes: availableBudgetMinutes ?? this.availableBudgetMinutes,
      totalPlannedMinutes: totalPlannedMinutes ?? this.totalPlannedMinutes,
      items: items ?? this.items,
      deferredTasksCount: deferredTasksCount ?? this.deferredTasksCount,
      isOverloaded: isOverloaded ?? this.isOverloaded,
      overloadMinutes: overloadMinutes ?? this.overloadMinutes,
      summary: summary ?? this.summary,
    );
  }
}

/// Deterministic, offline intelligence engine for student planning.
abstract final class PlanningEngine {
  static const int defaultTaskMinutes = 25;
  static const int defaultDailyBudgetMinutes = 180;

  /// Resolves the estimated minutes for a task, falling back to [defaultTaskMinutes].
  static int resolveTaskMinutes(StudentTask task) {
    return task.estimatedMinutes > 0 ? task.estimatedMinutes : defaultTaskMinutes;
  }

  /// Calculates a deterministic score for a task.
  static double scoreTask(
    StudentTask task, {
    DateTime? referenceTime,
    List<StudentExam>? exams,
    List<PlanningBlock>? blocks,
  }) {
    if (task.isCompleted) return -1.0;

    final now = referenceTime ?? DateTime.now();
    final today = AppWeekUtils.dateOnly(now);

    double score = 25.0; // Baseline for active tasks

    // 1. Due date / overdue urgency
    if (task.dueDate != null) {
      final dueDateOnly = AppWeekUtils.dateOnly(task.dueDate!);
      if (task.dueDate!.isBefore(now) && dueDateOnly.isBefore(today)) {
        final daysOverdue = today.difference(dueDateOnly).inDays;
        score = 200.0 + (daysOverdue * 10).clamp(0, 100);
      } else if (dueDateOnly == today) {
        score = 150.0;
      } else {
        final diff = dueDateOnly.difference(today).inDays;
        if (diff == 1) {
          score = 110.0;
        } else if (diff <= 3) {
          score = 95.0 - (diff * 5);
        } else if (diff <= 7) {
          score = 70.0 - (diff * 4);
        } else {
          score = 35.0;
        }
      }
    } else if (task.scheduledDate != null) {
      final schedDateOnly = AppWeekUtils.dateOnly(task.scheduledDate!);
      if (schedDateOnly == today) {
        score = 130.0;
      } else if (schedDateOnly.isBefore(today)) {
        score = 140.0;
      } else {
        final diff = schedDateOnly.difference(today).inDays;
        score = (60.0 - diff * 5).clamp(25.0, 60.0);
      }
    }

    // 2. Explicit Priority Modifiers
    switch (task.priority) {
      case TaskPriority.critical:
        score += 50.0;
      case TaskPriority.high:
        score += 30.0;
      case TaskPriority.medium:
        score += 10.0;
      case TaskPriority.low:
        score += 0.0;
    }

    // 3. Exam Proximity Modifiers
    if (task.examId != null && exams != null && exams.isNotEmpty) {
      final linkedExam = exams.where((e) => e.id == task.examId).firstOrNull;
      if (linkedExam != null && !linkedExam.isCompleted) {
        final days = linkedExam.daysUntilExam ??
            (linkedExam.examDateTime != null
                ? AppWeekUtils.dateOnly(linkedExam.examDateTime!).difference(today).inDays
                : null);

        if (days != null && days >= 0) {
          if (days <= 1) {
            score += 60.0;
          } else if (days <= 3) {
            score += 45.0;
          } else if (days <= 7) {
            score += 30.0;
          } else if (days <= 14) {
            score += 15.0;
          }
        }
      }
    }

    // 4. Subtasks Progress Modifier
    if (task.hasSubtasks && task.subtaskProgress > 0.0 && !task.allSubtasksComplete) {
      score += 15.0;
    }

    // 5. Existing PlanningBlock for today
    if (blocks != null && blocks.isNotEmpty) {
      final hasBlockToday = blocks.any((b) =>
          b.taskId == task.id && AppWeekUtils.dateOnly(b.startAt) == today);
      if (hasBlockToday) {
        score += 20.0;
      }
    }

    return score;
  }

  /// Calculates a deterministic score for an academic subject.
  static double scoreSubject(
    Subject subject, {
    DateTime? referenceTime,
    List<StudentExam>? exams,
    List<StudentTask>? tasks,
    List<dynamic>? sessions,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = AppWeekUtils.dateOnly(now);

    double score = 40.0; // Base score for active subject

    // 1. Preference weight
    switch (subject.preference) {
      case SubjectPreference.high:
        score += 35.0;
      case SubjectPreference.normal:
        score += 10.0;
      case SubjectPreference.low:
        score += 0.0;
    }

    // 2. Exam proximity for subject
    if (exams != null) {
      final subjectExams = exams.where((e) =>
          !e.isCompleted &&
          (e.subject.toLowerCase() == subject.name.toLowerCase() ||
           e.subject.toLowerCase() == subject.displayName.toLowerCase()));

      for (final exam in subjectExams) {
        final days = exam.daysUntilExam ??
            (exam.examDateTime != null
                ? AppWeekUtils.dateOnly(exam.examDateTime!).difference(today).inDays
                : null);

        if (days != null && days >= 0) {
          if (days <= 1) {
            score += 55.0;
          } else if (days <= 3) {
            score += 40.0;
          } else if (days <= 7) {
            score += 25.0;
          } else if (days <= 14) {
            score += 15.0;
          }
        }
      }
    }

    // 3. Pending tasks for this subject
    if (tasks != null) {
      final pendingCount = tasks.where((t) => t.subjectId == subject.id && !t.isCompleted).length;
      score += (pendingCount * 8.0).clamp(0.0, 30.0);
    }

    return score;
  }

  /// Generates a deterministic explanation for why a task is recommended.
  static String deriveRecommendationReason(
    StudentTask task, {
    DateTime? referenceTime,
    List<StudentExam>? exams,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = AppWeekUtils.dateOnly(now);

    // 1. Overdue
    if (task.dueDate != null) {
      final dueDateOnly = AppWeekUtils.dateOnly(task.dueDate!);
      if (task.dueDate!.isBefore(now) && dueDateOnly.isBefore(today)) {
        final days = today.difference(dueDateOnly).inDays;
        final base = 'Overdue by $days ${days == 1 ? 'day' : 'days'}';
        if (task.priority == TaskPriority.critical || task.priority == TaskPriority.high) {
          return '$base • ${task.priority.label} priority';
        }
        return base;
      }
    }

    // 2. Exam Proximity
    if (task.examId != null && exams != null && exams.isNotEmpty) {
      final linkedExam = exams.where((e) => e.id == task.examId).firstOrNull;
      if (linkedExam != null && !linkedExam.isCompleted) {
        final days = linkedExam.daysUntilExam ??
            (linkedExam.examDateTime != null
                ? AppWeekUtils.dateOnly(linkedExam.examDateTime!).difference(today).inDays
                : null);

        if (days != null && days >= 0 && days <= 7) {
          final dayStr = days == 0 ? 'today' : (days == 1 ? 'tomorrow' : 'in $days days');
          return 'Exam $dayStr: ${linkedExam.title}';
        }
      }
    }

    // 3. Due today
    if (task.dueDate != null && AppWeekUtils.dateOnly(task.dueDate!) == today) {
      if (task.priority == TaskPriority.critical || task.priority == TaskPriority.high) {
        return 'Due today • ${task.priority.label} priority';
      }
      return 'Due today';
    }

    // 4. Due tomorrow
    if (task.dueDate != null) {
      final dueDateOnly = AppWeekUtils.dateOnly(task.dueDate!);
      if (dueDateOnly.difference(today).inDays == 1) {
        return 'Due tomorrow • ${task.priority.label} priority';
      }
    }

    // 5. Scheduled today
    if (task.scheduledDate != null && AppWeekUtils.dateOnly(task.scheduledDate!) == today) {
      return 'Scheduled for today';
    }

    // 6. Priority
    if (task.priority == TaskPriority.critical || task.priority == TaskPriority.high) {
      return '${task.priority.label} priority task';
    }

    // 7. Subtasks in progress
    if (task.hasSubtasks && task.subtaskProgress > 0) {
      final rem = task.subtaskCount - task.subtasksCompleted;
      return '$rem ${rem == 1 ? 'subtask' : 'subtasks'} remaining';
    }

    return 'Actionable task';
  }

  /// Evaluates current active blocks, upcoming blocks, or recommendations
  /// to produce the primary actionable state for the student.
  static CurrentOrNextAction getCurrentOrNextAction({
    required List<StudentTask> tasks,
    List<Subject>? subjects,
    List<StudentExam>? exams,
    List<PlanningBlock>? blocks,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = AppWeekUtils.dateOnly(now);
    final activeSubjects = subjects ?? SubjectController.instance.activeSubjects;

    // 1. Check if a Focus session is actively running
    if (FocusController.instance.hasActiveSession) {
      final active = FocusController.instance.activeSession!;
      final rem = active.mode != FocusMode.stopwatch
          ? FocusController.instance.activeRemaining.inMinutes
          : FocusController.instance.activeElapsed.inMinutes;

      return CurrentOrNextAction(
        type: PlanningActionType.current,
        title: active.objective.isNotEmpty ? active.objective : 'Focus Session',
        subtitle: '${active.mode.name.toUpperCase()} · $rem min ${active.mode == FocusMode.stopwatch ? "elapsed" : "remaining"}',
        durationMinutes: active.plannedDuration.inMinutes,
        remainingMinutes: rem,
        isSubject: active.subjectId != null,
      );
    }

    // 2. Check scheduled planning blocks on today / upcoming within 24h
    if (blocks != null && blocks.isNotEmpty) {
      final relevantBlocks = blocks
          .where((b) =>
              AppWeekUtils.dateOnly(b.startAt) == today ||
              (b.startAt.isAfter(now) && b.startAt.difference(now).inHours < 24) ||
              (b.startAt.isBefore(now) && b.endAt.isAfter(now)))
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));

      // 2a. Is any block running right now?
      final currentBlock = relevantBlocks
          .where((b) => b.startAt.isBefore(now) && b.endAt.isAfter(now))
          .firstOrNull;

      if (currentBlock != null) {
        final rem = currentBlock.endAt.difference(now).inMinutes;
        String title = currentBlock.customTitle ?? 'Scheduled Session';
        StudentTask? linkedTask;
        Subject? linkedSubj;

        if (currentBlock.taskId != null) {
          linkedTask = tasks.where((t) => t.id == currentBlock.taskId).firstOrNull;
          if (linkedTask != null) title = linkedTask.title;
        }
        if (currentBlock.subjectId != null) {
          linkedSubj = activeSubjects.where((s) => s.id == currentBlock.subjectId).firstOrNull;
          if (linkedSubj != null && currentBlock.taskId == null) {
            title = linkedSubj.displayName;
          }
        }

        return CurrentOrNextAction(
          type: PlanningActionType.current,
          block: currentBlock,
          task: linkedTask,
          subject: linkedSubj,
          title: title,
          subtitle: 'Scheduled right now · $rem min remaining',
          durationMinutes: currentBlock.endAt.difference(currentBlock.startAt).inMinutes,
          remainingMinutes: rem,
          startAt: currentBlock.startAt,
          endAt: currentBlock.endAt,
          isSubject: currentBlock.isSubjectBlock,
        );
      }

      // 2b. Is any block upcoming next?
      final nextBlock = relevantBlocks
          .where((b) => b.startAt.isAfter(now))
          .firstOrNull;

      if (nextBlock != null) {
        final dur = nextBlock.endAt.difference(nextBlock.startAt).inMinutes;
        final tod = '${nextBlock.startAt.hour.toString().padLeft(2, '0')}:${nextBlock.startAt.minute.toString().padLeft(2, '0')}';
        String title = nextBlock.customTitle ?? 'Next Session';
        StudentTask? linkedTask;
        Subject? linkedSubj;

        if (nextBlock.taskId != null) {
          linkedTask = tasks.where((t) => t.id == nextBlock.taskId).firstOrNull;
          if (linkedTask != null) title = linkedTask.title;
        }
        if (nextBlock.subjectId != null) {
          linkedSubj = activeSubjects.where((s) => s.id == nextBlock.subjectId).firstOrNull;
          if (linkedSubj != null && nextBlock.taskId == null) {
            title = linkedSubj.displayName;
          }
        }

        return CurrentOrNextAction(
          type: PlanningActionType.next,
          block: nextBlock,
          task: linkedTask,
          subject: linkedSubj,
          title: title,
          subtitle: 'Starts at $tod · $dur min',
          durationMinutes: dur,
          startAt: nextBlock.startAt,
          endAt: nextBlock.endAt,
          isSubject: nextBlock.isSubjectBlock,
        );
      }
    }

    // 3. Fallback to recommendation
    final rec = getWhatShouldIDoNow(
      tasks: tasks,
      subjects: activeSubjects,
      exams: exams,
      blocks: blocks,
      referenceTime: now,
    );

    if (rec != null) {
      return CurrentOrNextAction(
        type: PlanningActionType.recommended,
        task: rec.task,
        subject: rec.subject,
        title: rec.title,
        subtitle: rec.reason,
        durationMinutes: rec.estimatedMinutes,
        isSubject: rec.isSubjectBlock,
      );
    }

    return const CurrentOrNextAction(
      type: PlanningActionType.none,
      title: 'All caught up!',
      subtitle: 'No urgent tasks or sessions planned',
      durationMinutes: 0,
    );
  }

  /// Identifies uncompleted planning blocks from earlier today that have passed.
  static List<MissedSession> getMissedSessions({
    required List<PlanningBlock> blocks,
    required List<StudentTask> tasks,
    List<Subject>? subjects,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = AppWeekUtils.dateOnly(now);
    final activeSubjects = subjects ?? SubjectController.instance.activeSubjects;

    final pastTodayBlocks = blocks
        .where((b) =>
            (AppWeekUtils.dateOnly(b.startAt) == today ||
             b.startAt.isAfter(now.subtract(const Duration(hours: 24)))) &&
            b.endAt.isBefore(now))
        .toList()
      ..sort((a, b) => b.endAt.compareTo(a.endAt));

    final missed = <MissedSession>[];

    for (final block in pastTodayBlocks) {
      if (block.taskId != null) {
        final task = tasks.where((t) => t.id == block.taskId).firstOrNull;
        if (task == null || task.isCompleted) continue; // Task is done, not missed
        missed.add(
          MissedSession(
            block: block,
            title: task.title,
            task: task,
            durationMinutes: block.endAt.difference(block.startAt).inMinutes,
            scheduledStart: block.startAt,
            scheduledEnd: block.endAt,
          ),
        );
      } else if (block.subjectId != null) {
        final subject = activeSubjects.where((s) => s.id == block.subjectId).firstOrNull;
        missed.add(
          MissedSession(
            block: block,
            title: subject?.displayName ?? block.customTitle ?? 'Subject Study',
            subject: subject,
            durationMinutes: block.endAt.difference(block.startAt).inMinutes,
            scheduledStart: block.startAt,
            scheduledEnd: block.endAt,
          ),
        );
      }
    }

    return missed;
  }

  /// Finds the earliest slot on [day] that can hold [durationMinutes] without
  /// colliding with existing planning blocks or fixed calendar commitments.
  ///
  /// This is a *lookup*, not an allocation: it applies no priority scoring and
  /// decides nothing. Allocation stays in [generateDailyPlan]. Used to place a
  /// topic chosen in STUDY mode and to offer recovery destinations for a
  /// missed block, so both respect existing commitments, existing blocks and
  /// the day's available-time budget.
  ///
  /// Returns null when no gap exists within the searchable window.
  static DateTime? findNextAvailableSlot(
    DateTime day, {
    required int durationMinutes,
    int? availableMinutes,
    List<PlanningBlock>? blocks,
    List<AcademicCalendarEvent>? calendarEvents,
    DateTime? referenceTime,
    int dayStartHour = 8,
    int dayEndHour = 21,
    int granularityMinutes = 15,
  }) {
    if (durationMinutes <= 0) return null;

    final targetDate = AppWeekUtils.dateOnly(day);
    final now = referenceTime ?? DateTime.now();
    final isToday = targetDate == AppWeekUtils.dateOnly(now);

    final dayBlocks = (blocks ?? PlanningBlockController.instance.blocks)
        .where((b) => AppWeekUtils.dateOnly(b.startAt) == targetDate)
        .toList();
    final dayEvents = calendarEvents ??
        AcademicScheduleController.instance.eventsForDay(targetDate);

    // Busy intervals = existing planning blocks + fixed commitments.
    final busy = <(DateTime, DateTime)>[
      for (final b in dayBlocks) (b.startAt, b.endAt),
      for (final e in dayEvents)
        if (!e.allDay) (e.startAt, e.endAt),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final windowStart = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      dayStartHour,
    );
    var windowEnd = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      dayEndHour,
    );

    // Never exceed the day's available-time budget.
    final budget = availableMinutes ?? PlanningEngine.defaultDailyBudgetMinutes;
    final alreadyScheduled = dayBlocks.fold<int>(
      0,
      (sum, b) => sum + b.endAt.difference(b.startAt).inMinutes,
    );
    final remaining = budget - alreadyScheduled;
    if (remaining < durationMinutes) return null;
    if (remaining < budget) {
      final capped = windowStart.add(Duration(minutes: remaining));
      if (capped.isBefore(windowEnd)) windowEnd = capped;
    }

    // Never propose a slot in the past.
    var cursor = windowStart;
    if (isToday && cursor.isBefore(now)) cursor = now;

    // Snap up to the granularity grid.
    final overshoot = cursor.minute % granularityMinutes;
    if (overshoot != 0) {
      cursor = cursor.add(Duration(minutes: granularityMinutes - overshoot));
    }
    cursor = DateTime(
      cursor.year,
      cursor.month,
      cursor.day,
      cursor.hour,
      cursor.minute,
    );

    for (final interval in busy) {
      if (!interval.$1.isAfter(cursor)) {
        // Fully behind the cursor — keep scanning.
        if (interval.$2.isAfter(cursor)) cursor = interval.$2;
        continue;
      }
      final slotEnd = cursor.add(Duration(minutes: durationMinutes));
      if (!slotEnd.isAfter(interval.$1)) break; // Gap before this commitment.
      cursor = interval.$2; // Skip past the commitment.
    }

    final candidateEnd = cursor.add(Duration(minutes: durationMinutes));
    if (!candidateEnd.isBefore(windowEnd) && candidateEnd != windowEnd) {
      return null;
    }
    return cursor;
  }

  /// Candidate recovery destinations for a missed block, soonest first.
  ///
  /// Each candidate is a real free slot that respects existing blocks, fixed
  /// commitments and the available-time budget. Nothing is deleted or moved
  /// until the user confirms.
  static List<DateTime> findRecoverySlots(
    PlanningBlock missedBlock, {
    int? availableMinutes,
    int limit = 3,
    DateTime? referenceTime,
  }) {
    final duration = missedBlock.endAt.difference(missedBlock.startAt).inMinutes;
    if (duration <= 0) return const [];

    final now = referenceTime ?? DateTime.now();
    final today = AppWeekUtils.dateOnly(now);
    final slots = <DateTime>[];

    for (int dayOffset = 0; dayOffset <= 3 && slots.length < limit; dayOffset++) {
      final target = today.add(Duration(days: dayOffset));
      for (int hour = 8; hour <= 20 && slots.length < limit; hour++) {
        final probe = DateTime(target.year, target.month, target.day, hour);
        final slot = findNextAvailableSlot(
          probe,
          durationMinutes: duration,
          availableMinutes: availableMinutes,
          referenceTime: dayOffset == 0 ? now : null,
        );
        if (slot == null) continue;
        if (slots.any((s) => s.isAtSameMomentAs(slot))) continue;
        slots.add(slot);
      }
    }
    slots.sort((a, b) => a.compareTo(b));
    return slots.take(limit).toList(growable: false);
  }

  /// Reschedules a missed session to a new start time today (or next 15-minute slot).
  static Future<PlanningBlock?> rescheduleMissedSession(
    MissedSession session, {
    DateTime? newStartTime,
  }) async {
    final now = DateTime.now();
    DateTime start = newStartTime ??
        DateTime(now.year, now.month, now.day, now.hour)
            .add(Duration(minutes: ((now.minute / 15).ceil() * 15)));

    if (start.isBefore(now)) {
      start = now.add(const Duration(minutes: 5));
    }

    final end = start.add(Duration(minutes: session.durationMinutes));

    return PlanningBlockController.instance.rescheduleBlock(
      session.block.id,
      start,
      end,
    );
  }

  /// Deterministically selects the single best currently actionable task or subject.
  static PlanningRecommendation? getWhatShouldIDoNow({
    required List<StudentTask> tasks,
    List<Subject>? subjects,
    List<StudentExam>? exams,
    List<PlanningBlock>? blocks,
    DateTime? referenceTime,
    int? maxAvailableMinutes,
  }) {
    final now = referenceTime ?? DateTime.now();

    // 1. Score active tasks
    final active = tasks.where((t) => !t.isCompleted).toList();
    final scoredTasks = <({StudentTask task, double score})>[];
    for (final task in active) {
      final score = scoreTask(
        task,
        referenceTime: referenceTime,
        exams: exams,
        blocks: blocks,
      );
      if (score >= 0) {
        scoredTasks.add((task: task, score: score));
      }
    }

    if (scoredTasks.isNotEmpty) {
      scoredTasks.sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        final sortOrderCmp = a.task.sortOrder.compareTo(b.task.sortOrder);
        if (sortOrderCmp != 0) return sortOrderCmp;
        return a.task.id.compareTo(b.task.id);
      });

      StudentTask selectedTask = scoredTasks.first.task;
      double selectedScore = scoredTasks.first.score;

      if (maxAvailableMinutes != null && maxAvailableMinutes > 0) {
        for (final item in scoredTasks) {
          final est = resolveTaskMinutes(item.task);
          if (est <= maxAvailableMinutes) {
            selectedTask = item.task;
            selectedScore = item.score;
            break;
          }
        }
      }

      StudentExam? linkedExam;
      if (selectedTask.examId != null && exams != null) {
        linkedExam = exams.where((e) => e.id == selectedTask.examId).firstOrNull;
      }

      final reason = deriveRecommendationReason(
        selectedTask,
        referenceTime: referenceTime,
        exams: exams,
      );

      return PlanningRecommendation(
        task: selectedTask,
        title: selectedTask.title,
        reason: reason,
        score: selectedScore,
        estimatedMinutes: resolveTaskMinutes(selectedTask),
        examTitle: linkedExam?.title,
        daysUntilExam: linkedExam?.daysUntilExam,
        isSubjectBlock: false,
      );
    }

    // 2. If no active tasks exist, recommend top Subject study session (topic-aware)
    final activeSubjects = subjects ?? SubjectController.instance.activeSubjects;
    if (activeSubjects.isNotEmpty) {
      final scoredSubjects = <({Subject subject, double score})>[];
      for (final s in activeSubjects) {
        scoredSubjects.add((
          subject: s,
          score: scoreSubject(s, referenceTime: now, exams: exams, tasks: tasks),
        ));
      }
      scoredSubjects.sort((a, b) => b.score.compareTo(a.score));

      final topSubject = scoredSubjects.first.subject;
      StudentExam? linkedExam;
      if (exams != null) {
        linkedExam = exams.where((e) =>
            !e.isCompleted &&
            (e.subject.toLowerCase() == topSubject.name.toLowerCase() ||
             e.subject.toLowerCase() == topSubject.displayName.toLowerCase())).firstOrNull;
      }

      String reason = 'Study session · ${topSubject.preference.label} priority';
      if (linkedExam != null && linkedExam.daysUntilExam != null && linkedExam.daysUntilExam! <= 7) {
        final days = linkedExam.daysUntilExam!;
        final dayStr = days == 0 ? 'today' : (days == 1 ? 'tomorrow' : 'in $days days');
        reason = 'Exam $dayStr: ${linkedExam.title}';
      }

      // Topic-aware: prefer most relevant topic when available (fallback gracefully if none)
      final subjectTopics = AcademicKnowledgeController.instance.topicsForSubject(topSubject.id);
      Topic? topTopic;
      int estimatedMins = 35;
      if (subjectTopics.isNotEmpty) {
        final assessments = subjectTopics
            .map((t) => AcademicKnowledgeEngine.assessTopicPriority(
                  t,
                  exams: exams ?? const [],
                  preference: topSubject.preference,
                  referenceTime: now,
                ))
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
        topTopic = assessments.firstOrNull?.topic;
        if (topTopic != null) {
          if (topTopic.estimatedMinutes > 0) {
            estimatedMins = topTopic.estimatedMinutes;
          }
          // Use topic-specific reason when it outranks generic subject reason
          final topicReason = assessments.firstOrNull?.primaryReason;
          if (topicReason != null && topicReason.isNotEmpty) {
            reason = topicReason;
          }
        }
      }

      final displayTitle = topTopic != null
          ? '${topSubject.displayName} — ${topTopic.title}'
          : topSubject.displayName;

      return PlanningRecommendation(
        subject: topSubject,
        title: displayTitle,
        reason: reason,
        score: scoredSubjects.first.score,
        estimatedMinutes: estimatedMins,
        examTitle: linkedExam?.title,
        daysUntilExam: linkedExam?.daysUntilExam,
        isSubjectBlock: true,
      );
    }

    return null;
  }

  /// Calculates workload metrics for a specific [day].
  static DayWorkload calculateDayWorkload(
    DateTime day, {
    required List<StudentTask> tasks,
    required List<PlanningBlock> blocks,
    int availableMinutes = defaultDailyBudgetMinutes,
  }) {
    final date = AppWeekUtils.dateOnly(day);
    final now = DateTime.now();
    final today = AppWeekUtils.dateOnly(now);
    final isToday = (date == today);

    // Get blocks on this day
    final dayBlocks = blocks
        .where((b) => AppWeekUtils.dateOnly(b.startAt) == date)
        .toList();
    final scheduledTaskIds = dayBlocks.where((b) => b.taskId != null).map((b) => b.taskId!).toSet();

    // Scheduled minutes from actual PlanningBlocks
    int scheduledMinutes = 0;
    for (final block in dayBlocks) {
      scheduledMinutes += block.endAt.difference(block.startAt).inMinutes;
    }

    // Filter relevant tasks for this day
    final dayTasks = tasks.where((t) {
      if (scheduledTaskIds.contains(t.id)) return true;
      final sched = AppWeekUtils.dateOnlyOrNull(t.scheduledDate);
      if (sched == date) return true;
      final due = AppWeekUtils.dateOnlyOrNull(t.dueDate);
      return due == date;
    }).toList();

    final completedTasks = dayTasks.where((t) => t.isCompleted).toList();
    final activeTasks = dayTasks.where((t) => !t.isCompleted).toList();

    int completedMinutes = 0;
    for (final t in completedTasks) {
      completedMinutes += resolveTaskMinutes(t);
    }

    int estimatedMinutesRemaining = 0;
    for (final t in activeTasks) {
      estimatedMinutesRemaining += resolveTaskMinutes(t);
    }
    // Account for scheduled blocks (e.g. subject study blocks) that are remaining
    final scheduledRemaining = (scheduledMinutes - completedMinutes).clamp(0, 99999);
    if (scheduledRemaining > estimatedMinutesRemaining) {
      estimatedMinutesRemaining = scheduledRemaining;
    }

    int overdueEstimatedMinutes = 0;
    if (isToday) {
      final overdueTasks = tasks.where((t) => t.isOverdue).toList();
      for (final t in overdueTasks) {
        overdueEstimatedMinutes += resolveTaskMinutes(t);
      }
    }

    return DayWorkload(
      date: date,
      totalTasksCount: dayTasks.length + dayBlocks.where((b) => b.isSubjectBlock).length,
      completedTasksCount: completedTasks.length,
      remainingTasksCount: activeTasks.length + dayBlocks.where((b) => b.isSubjectBlock).length,
      estimatedMinutesRemaining: estimatedMinutesRemaining,
      scheduledMinutes: scheduledMinutes,
      completedMinutes: completedMinutes,
      overdueEstimatedMinutes: overdueEstimatedMinutes,
      availableMinutes: availableMinutes,
    );
  }

  /// Calculates weekly aggregated workload for the given 7 days.
  static WeekWorkload calculateWeekWorkload(
    List<DateTime> weekDates, {
    required List<StudentTask> tasks,
    required List<PlanningBlock> blocks,
    int availableMinutes = defaultDailyBudgetMinutes,
  }) {
    final dayWorkloads = <DayWorkload>[];
    int totalEstimated = 0;
    int totalCompleted = 0;
    int totalScheduled = 0;
    int overloadedCount = 0;
    int totalTasks = 0;
    int totalDone = 0;

    for (final date in weekDates) {
      final dw = calculateDayWorkload(
        date,
        tasks: tasks,
        blocks: blocks,
        availableMinutes: availableMinutes,
      );
      dayWorkloads.add(dw);
      totalEstimated += dw.estimatedMinutesRemaining;
      totalCompleted += dw.completedMinutes;
      totalScheduled += dw.scheduledMinutes;
      totalTasks += dw.totalTasksCount;
      totalDone += dw.completedTasksCount;
      if (dw.isOverloaded) {
        overloadedCount++;
      }
    }

    final completionRate = totalTasks == 0 ? 0.0 : (totalDone / totalTasks).clamp(0.0, 1.0);

    return WeekWorkload(
      days: dayWorkloads,
      totalEstimatedMinutes: totalEstimated,
      totalCompletedMinutes: totalCompleted,
      totalScheduledMinutes: totalScheduled,
      overloadedDaysCount: overloadedCount,
      weeklyCompletionRate: completionRate,
    );
  }

  /// Generates a deterministic "Plan My Day" schedule distributing time across
  /// tasks, subjects, and exam revision according to student available budget.
  static DailyPlanResult generateDailyPlan(
    DateTime day, {
    required List<StudentTask> tasks,
    List<Subject>? subjects,
    List<StudentExam>? exams,
    List<PlanningBlock>? blocks,
    List<AcademicCalendarEvent>? calendarEvents,
    int availableBudgetMinutes = defaultDailyBudgetMinutes,
    DateTime? baseStartTime,
  }) {
    final targetDate = AppWeekUtils.dateOnly(day);
    final now = DateTime.now();
    final isToday = (targetDate == AppWeekUtils.dateOnly(now));

    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final activeSubjects = (subjects ?? SubjectController.instance.activeSubjects).toList();
    final existingBlocks = (blocks ?? [])
        .where((b) => AppWeekUtils.dateOnly(b.startAt) == targetDate)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final dayEvents = calendarEvents ??
        AcademicScheduleController.instance.eventsForDay(targetDate);

    final existingScheduledTaskIds = existingBlocks
        .where((b) => b.taskId != null)
        .map((b) => b.taskId!)
        .toSet();
    final existingScheduledSubjectIds = existingBlocks
        .where((b) => b.subjectId != null && b.taskId == null)
        .map((b) => b.subjectId!)
        .toSet();

    final items = <DailyPlanItem>[];
    int currentAllocatedMinutes = 0;

    // Determine initial cursor start time
    DateTime cursorTime;
    if (baseStartTime != null) {
      cursorTime = baseStartTime;
    } else if (isToday && now.hour >= 8 && now.hour < 21) {
      final nextMin = ((now.minute / 15).ceil() * 15);
      cursorTime = DateTime(targetDate.year, targetDate.month, targetDate.day, now.hour)
          .add(Duration(minutes: nextMin));
    } else {
      cursorTime = DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 0);
    }

    // 1. Include existing PlanningBlocks as scheduled items
    for (final block in existingBlocks) {
      final blockDur = block.endAt.difference(block.startAt).inMinutes;
      String blockTitle = block.customTitle ?? 'Scheduled Session';
      StudentTask? linkedTask;
      Subject? linkedSubject;

      if (block.taskId != null) {
        linkedTask = tasks.where((t) => t.id == block.taskId).firstOrNull;
        if (linkedTask != null) blockTitle = linkedTask.title;
      }
      if (block.subjectId != null) {
        linkedSubject = activeSubjects.where((s) => s.id == block.subjectId).firstOrNull;
        if (linkedSubject != null && block.taskId == null) {
          blockTitle = linkedSubject.displayName;
        }
      }

      items.add(
        DailyPlanItem(
          task: linkedTask,
          subject: linkedSubject,
          title: blockTitle,
          taskId: block.taskId,
          subjectId: block.subjectId,
          topicId: block.topicId,
          chapterId: block.chapterId,
          examId: block.examId ?? linkedTask?.examId,
          estimatedMinutes: blockDur,
          suggestedStart: block.startAt,
          suggestedEnd: block.endAt,
          reason: 'Already scheduled',
          isAlreadyScheduled: true,
          existingBlockId: block.id,
        ),
      );
      currentAllocatedMinutes += blockDur;
      if (block.endAt.isAfter(cursorTime)) {
        cursorTime = block.endAt;
      }
    }

    // 2. Gather candidate tasks for the day
    final candidateTasks = <StudentTask>[];
    final addedTaskIds = Set<String>.from(existingScheduledTaskIds);

    for (final task in activeTasks) {
      if (addedTaskIds.contains(task.id)) continue;

      final isScheduled = task.scheduledDate != null &&
          AppWeekUtils.dateOnly(task.scheduledDate!) == targetDate;
      final isDue = task.dueDate != null &&
          AppWeekUtils.dateOnly(task.dueDate!) == targetDate;
      final isOverdue = isToday && task.isOverdue;

      if (isScheduled || isDue || isOverdue) {
        candidateTasks.add(task);
        addedTaskIds.add(task.id);
      }
    }

    // If no explicit due/scheduled tasks found, include top active tasks
    if (candidateTasks.isEmpty) {
      final remainingActive = activeTasks.where((t) => !addedTaskIds.contains(t.id)).toList()
        ..sort((a, b) {
          final aScore = scoreTask(a, referenceTime: now, exams: exams, blocks: blocks);
          final bScore = scoreTask(b, referenceTime: now, exams: exams, blocks: blocks);
          return bScore.compareTo(aScore);
        });

      for (final t in remainingActive) {
        candidateTasks.add(t);
        addedTaskIds.add(t.id);
      }
    }

    candidateTasks.sort((a, b) {
      final aScore = scoreTask(a, referenceTime: now, exams: exams, blocks: blocks);
      final bScore = scoreTask(b, referenceTime: now, exams: exams, blocks: blocks);
      return bScore.compareTo(aScore);
    });

    DateTime advancePastCommitments(DateTime cur, int durMins) {
      bool adjusted = true;
      DateTime c = cur;
      while (adjusted) {
        adjusted = false;
        final cEnd = c.add(Duration(minutes: durMins));
        for (final b in existingBlocks) {
          if (c.isBefore(b.endAt) && cEnd.isAfter(b.startAt)) {
            c = b.endAt.add(const Duration(minutes: 5));
            adjusted = true;
          }
        }
        for (final e in dayEvents) {
          if (!e.allDay && c.isBefore(e.endAt) && cEnd.isAfter(e.startAt)) {
            c = e.endAt.add(const Duration(minutes: 5));
            adjusted = true;
          }
        }
      }
      return c;
    }

    // Schedule urgent candidate tasks into remaining capacity
    for (final task in candidateTasks) {
      final estMinutes = resolveTaskMinutes(task);
      final reason = deriveRecommendationReason(task, referenceTime: now, exams: exams);

      // Advance past existing blocks and fixed calendar commitments
      cursorTime = advancePastCommitments(cursorTime, estMinutes);

      final start = cursorTime;
      final end = start.add(Duration(minutes: estMinutes));

      Subject? taskSubj;
      if (task.subjectId != null) {
        taskSubj = activeSubjects.where((s) => s.id == task.subjectId).firstOrNull;
      }

      items.add(
        DailyPlanItem(
          task: task,
          subject: taskSubj,
          title: task.title,
          taskId: task.id,
          subjectId: task.subjectId,
          examId: task.examId,
          estimatedMinutes: estMinutes,
          suggestedStart: start,
          suggestedEnd: end,
          reason: reason,
          isAlreadyScheduled: false,
        ),
      );

      currentAllocatedMinutes += estMinutes;
      cursorTime = end.add(const Duration(minutes: 5));
    }

    // 3. Distribute remaining available budget across active subjects
    int remainingBudget = max(0, availableBudgetMinutes - currentAllocatedMinutes);

    if (remainingBudget >= 15 && activeSubjects.isNotEmpty) {
      final availableSubjects = activeSubjects
          .where((s) => !existingScheduledSubjectIds.contains(s.id))
          .toList();

      if (availableSubjects.isNotEmpty) {
        final scoredSubjects = availableSubjects.map((s) {
          final sc = scoreSubject(s, referenceTime: now, exams: exams, tasks: tasks);
          return (subject: s, score: sc);
        }).toList()
          ..sort((a, b) => b.score.compareTo(a.score));

        final maxSubjectsToFit = (remainingBudget / 25).floor().clamp(1, min(4, scoredSubjects.length)).toInt();
        final selectedSubjectEntries = scoredSubjects.take(maxSubjectsToFit).toList();

        final totalScore = selectedSubjectEntries.fold<double>(0.0, (sum, e) => sum + e.score);

        int allocatedToSubjects = 0;
        for (int i = 0; i < selectedSubjectEntries.length; i++) {
          final entry = selectedSubjectEntries[i];
          final proportion = totalScore > 0 ? (entry.score / totalScore) : (1.0 / selectedSubjectEntries.length);
          var subMinutes = ((remainingBudget * proportion) / 5).round() * 5;
          subMinutes = subMinutes.clamp(15, 90);

          if (i == selectedSubjectEntries.length - 1 && selectedSubjectEntries.length > 1) {
            final diff = (remainingBudget - allocatedToSubjects);
            if (diff >= 15) {
              subMinutes = diff;
            }
          }

          allocatedToSubjects += subMinutes;

          cursorTime = advancePastCommitments(cursorTime, subMinutes);

          StudentExam? linkedExam;
          if (exams != null) {
            linkedExam = exams.where((e) =>
                !e.isCompleted &&
                (e.subject.toLowerCase() == entry.subject.name.toLowerCase() ||
                 e.subject.toLowerCase() == entry.subject.displayName.toLowerCase())).firstOrNull;
          }

          String subjectReason = 'Subject study · ${entry.subject.preference.label} priority';
          if (linkedExam != null && linkedExam.daysUntilExam != null && linkedExam.daysUntilExam! <= 7) {
            final days = linkedExam.daysUntilExam!;
            final dayStr = days == 0 ? 'today' : (days == 1 ? 'tomorrow' : 'in $days days');
            subjectReason = 'Exam $dayStr: ${linkedExam.title}';
          }

          final subjectTopics = AcademicKnowledgeController.instance.topicsForSubject(entry.subject.id);
          Topic? topTopic;
          if (subjectTopics.isNotEmpty) {
            final assessments = subjectTopics.map((t) => AcademicKnowledgeEngine.assessTopicPriority(
              t,
              exams: exams ?? const [],
              preference: entry.subject.preference,
              referenceTime: now,
            )).toList()..sort((a, b) => b.score.compareTo(a.score));
            topTopic = assessments.firstOrNull?.topic;
          }

          String planItemTitle = entry.subject.displayName;
          String? topicId;
          String? chapterId;
          String? examId = linkedExam?.id;
          int itemMinutes = subMinutes;
          if (topTopic != null) {
            planItemTitle = '${entry.subject.displayName} — ${topTopic.title}';
            topicId = topTopic.id;
            chapterId = topTopic.chapterId;
            if (topTopic.estimatedMinutes > 0 && topTopic.estimatedMinutes <= subMinutes) {
              itemMinutes = topTopic.estimatedMinutes;
            }
          }

          final start = cursorTime;
          final end = start.add(Duration(minutes: itemMinutes));

          items.add(
            DailyPlanItem(
              subject: entry.subject,
              title: planItemTitle,
              subjectId: entry.subject.id,
              topicId: topicId,
              chapterId: chapterId,
              examId: examId,
              estimatedMinutes: itemMinutes,
              suggestedStart: start,
              suggestedEnd: end,
              reason: subjectReason,
              isAlreadyScheduled: false,
            ),
          );

          currentAllocatedMinutes += itemMinutes;
          cursorTime = end.add(const Duration(minutes: 5));
        }
      }
    }

    final isOverloaded = currentAllocatedMinutes > availableBudgetMinutes;
    final overloadMinutes = isOverloaded ? (currentAllocatedMinutes - availableBudgetMinutes) : 0;
    final deferredCount = (activeTasks.length - candidateTasks.length).clamp(0, 99999);

    String summary;
    if (items.isEmpty) {
      summary = 'All caught up! No tasks or subjects selected for planning.';
    } else if (isOverloaded) {
      summary = 'Plan contains ${items.length} sessions ($currentAllocatedMinutes min), exceeding your $availableBudgetMinutes min budget by $overloadMinutes min.';
    } else {
      summary = 'Plan contains ${items.length} sessions totaling $currentAllocatedMinutes min within your $availableBudgetMinutes min budget.';
    }

    return DailyPlanResult(
      targetDay: targetDate,
      availableBudgetMinutes: availableBudgetMinutes,
      totalPlannedMinutes: currentAllocatedMinutes,
      items: items,
      deferredTasksCount: deferredCount,
      isOverloaded: isOverloaded,
      overloadMinutes: overloadMinutes,
      summary: summary,
    );
  }

  /// Updates the duration of an individual plan item and shifts subsequent item times sequentially.
  static DailyPlanResult updatePlanItemDuration(
    DailyPlanResult currentPlan,
    int itemIndex,
    int newDurationMinutes,
  ) {
    if (itemIndex < 0 || itemIndex >= currentPlan.items.length || newDurationMinutes <= 0) {
      return currentPlan;
    }

    final updatedItems = List<DailyPlanItem>.from(currentPlan.items);
    final targetItem = updatedItems[itemIndex];

    final updatedTarget = targetItem.copyWith(
      estimatedMinutes: newDurationMinutes,
      suggestedEnd: targetItem.suggestedStart.add(Duration(minutes: newDurationMinutes)),
    );
    updatedItems[itemIndex] = updatedTarget;

    DateTime cursor = updatedTarget.suggestedEnd.add(const Duration(minutes: 5));
    for (int i = itemIndex + 1; i < updatedItems.length; i++) {
      final item = updatedItems[i];
      if (!item.isAlreadyScheduled) {
        final start = cursor;
        final end = start.add(Duration(minutes: item.estimatedMinutes));
        updatedItems[i] = item.copyWith(suggestedStart: start, suggestedEnd: end);
        cursor = end.add(const Duration(minutes: 5));
      } else {
        if (item.suggestedEnd.isAfter(cursor)) {
          cursor = item.suggestedEnd.add(const Duration(minutes: 5));
        }
      }
    }

    int totalMins = 0;
    for (final item in updatedItems) {
      totalMins += item.estimatedMinutes;
    }

    final isOverloaded = totalMins > currentPlan.availableBudgetMinutes;
    final overloadMins = isOverloaded ? (totalMins - currentPlan.availableBudgetMinutes) : 0;

    return currentPlan.copyWith(
      items: updatedItems,
      totalPlannedMinutes: totalMins,
      isOverloaded: isOverloaded,
      overloadMinutes: overloadMins,
    );
  }

  /// Removes an item from the plan and shifts subsequent item times sequentially.
  static DailyPlanResult removePlanItem(
    DailyPlanResult currentPlan,
    int itemIndex,
  ) {
    if (itemIndex < 0 || itemIndex >= currentPlan.items.length) {
      return currentPlan;
    }

    final updatedItems = List<DailyPlanItem>.from(currentPlan.items)..removeAt(itemIndex);

    if (updatedItems.isNotEmpty) {
      DateTime cursor = updatedItems.first.suggestedStart;
      for (int i = 0; i < updatedItems.length; i++) {
        final item = updatedItems[i];
        if (!item.isAlreadyScheduled) {
          final start = cursor;
          final end = start.add(Duration(minutes: item.estimatedMinutes));
          updatedItems[i] = item.copyWith(suggestedStart: start, suggestedEnd: end);
          cursor = end.add(const Duration(minutes: 5));
        } else {
          cursor = item.suggestedEnd.add(const Duration(minutes: 5));
        }
      }
    }

    int totalMins = 0;
    for (final item in updatedItems) {
      totalMins += item.estimatedMinutes;
    }

    final isOverloaded = totalMins > currentPlan.availableBudgetMinutes;
    final overloadMins = isOverloaded ? (totalMins - currentPlan.availableBudgetMinutes) : 0;

    return currentPlan.copyWith(
      items: updatedItems,
      totalPlannedMinutes: totalMins,
      isOverloaded: isOverloaded,
      overloadMinutes: overloadMins,
    );
  }

  /// Safely applies a [DailyPlanResult] by scheduling missing PlanningBlocks
  /// and reconciling session transition notifications.
  static Future<List<PlanningBlock>> applyDailyPlan(DailyPlanResult plan) async {
    final controller = PlanningBlockController.instance;
    final createdOrFound = <PlanningBlock>[];
    final blockTitles = <String, String>{};

    for (final item in plan.items) {
      if (item.isAlreadyScheduled && item.existingBlockId != null) {
        final existing = controller.blocks
            .where((b) => b.id == item.existingBlockId)
            .firstOrNull;
        if (existing != null) {
          createdOrFound.add(existing);
          blockTitles[existing.id] = item.title;
          continue;
        }
      }

      final block = await controller.scheduleBlock(
        item.taskId,
        item.suggestedStart,
        item.suggestedEnd,
        subjectId: item.subjectId,
        topicId: item.topicId,
        chapterId: item.chapterId,
        examId: item.examId ?? item.task?.examId,
        customTitle: item.title,
      );
      createdOrFound.add(block);
      blockTitles[block.id] = item.title;
    }

    // Schedule local transition notifications for today's plan
    await NotificationCoordinator.instance.reconcilePlanningNotifications(
      createdOrFound,
      blockTitles: blockTitles,
    );

    return createdOrFound;
  }

  /// Safe, deterministic rescheduling of overloaded blocks on [day].
  /// Respects fixed commitments (AcademicScheduleController) and never moves
  /// completed, past, fixed, or active focus blocks.
  static Future<int> rebalanceOverloadedDay(
    DateTime day, {
    required List<StudentTask> tasks,
    int availableMinutes = defaultDailyBudgetMinutes,
    int daysToLookAhead = 6,
    DateTime? referenceTime,
  }) async {
    final controller = PlanningBlockController.instance;
    final targetDate = AppWeekUtils.dateOnly(day);
    final now = referenceTime ?? DateTime.now();

    final dayBlocks = controller.blocksForDay(targetDate);
    if (dayBlocks.isEmpty) return 0;

    int currentDayMinutes = 0;
    for (final b in dayBlocks) {
      currentDayMinutes += b.endAt.difference(b.startAt).inMinutes;
    }

    if (currentDayMinutes <= availableMinutes) return 0;

    final eligibleBlocks = dayBlocks.where((b) => b.startAt.isAfter(now)).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));

    int rescheduledCount = 0;

    for (final block in eligibleBlocks) {
      if (currentDayMinutes <= availableMinutes) break;

      final blockDuration = block.endAt.difference(block.startAt);

      DateTime? candidateDay;
      for (int i = 1; i <= daysToLookAhead; i++) {
        final nextDay = targetDate.add(Duration(days: i));
        final nextDayBlocks = controller.blocksForDay(nextDay);
        int nextDayMinutes = 0;
        for (final b in nextDayBlocks) {
          nextDayMinutes += b.endAt.difference(b.startAt).inMinutes;
        }

        // Respect fixed calendar commitments when evaluating capacity
        int committedMinutes = 0;
        try {
          final fixedEvents = AcademicScheduleController.instance.eventsForDay(nextDay);
          // Approximate committed minutes from fixed events (clamped to day window)
          for (final e in fixedEvents) {
            if (e.allDay) {
              committedMinutes += availableMinutes;
            } else {
              final dur = e.endAt.difference(e.startAt).inMinutes.clamp(0, availableMinutes);
              committedMinutes += dur;
            }
          }
        } catch (_) {}
        final totalNextDayNeeded = nextDayMinutes + committedMinutes + blockDuration.inMinutes;

        if (totalNextDayNeeded <= availableMinutes && nextDayMinutes + blockDuration.inMinutes <= availableMinutes) {
          candidateDay = nextDay;
          break;
        }
      }

      if (candidateDay != null) {
        final newStart = DateTime(
          candidateDay.year,
          candidateDay.month,
          candidateDay.day,
          block.startAt.hour,
          block.startAt.minute,
        );
        final newEnd = newStart.add(blockDuration);

        await controller.rescheduleBlock(block.id, newStart, newEnd);
        currentDayMinutes -= blockDuration.inMinutes;
        rescheduledCount++;
      }
    }

    return rescheduledCount;
  }
}
