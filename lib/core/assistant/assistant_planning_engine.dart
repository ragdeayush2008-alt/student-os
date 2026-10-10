import 'package:flutter/foundation.dart';

import '../../data/models/exam.dart';
import '../../data/models/task.dart';
import '../../features/planning/models/planning_block.dart';
import '../../features/sleep/models/sleep_schedule.dart';

/// A single proposed work session inside an [AssistantDayPlan].
@immutable
class PlannedSession {
  const PlannedSession({
    required this.id,
    required this.title,
    required this.detail,
    required this.minutes,
    required this.reason,
    this.taskId,
    this.subjectId,
    this.topicId,
    this.examId,
    this.dueDate,
  });

  final String id;
  final String title;
  final String detail;
  final int minutes;
  final String reason;
  final String? taskId;
  final String? subjectId;
  final String? topicId;
  final String? examId;
  final DateTime? dueDate;

  PlannedSession copyWith({String? title, String? detail, int? minutes}) {
    return PlannedSession(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      minutes: minutes ?? this.minutes,
      reason: reason,
      taskId: taskId,
      subjectId: subjectId,
      topicId: topicId,
      examId: examId,
      dueDate: dueDate,
    );
  }
}

/// A proposed task move (reschedule) inside an [AssistantDayPlan].
@immutable
class PlannedMove {
  const PlannedMove({
    required this.taskId,
    required this.taskTitle,
    required this.fromDate,
    required this.toDate,
    required this.reason,
  });

  final String taskId;
  final String taskTitle;
  final DateTime? fromDate;
  final DateTime toDate;
  final String reason;
}

/// A proposed task creation inside an [AssistantDayPlan] (exam prep etc.).
@immutable
class PlannedCreation {
  const PlannedCreation({
    required this.title,
    this.dueDate,
    this.subjectId,
    this.priority = TaskPriority.medium,
    this.estimatedMinutes = 30,
  });

  final String title;
  final DateTime? dueDate;
  final String? subjectId;
  final TaskPriority priority;
  final int estimatedMinutes;
}

/// What kind of proposal this is (drives apply behavior + wording).
enum AssistantProposalKind { dayPlan, fixDay, catchUp, examPrep, revision }

/// Deterministic day-plan proposal: sessions laid out from [anchorStart]
/// with breaks, clamped by budget and the sleep boundary.
///
/// Pure logic — no controllers, no storage. The caller applies it through
/// the existing controllers only after user confirmation.
@immutable
class AssistantDayPlan {
  const AssistantDayPlan({
    required this.kind,
    required this.sessions,
    this.moves = const [],
    this.creations = const [],
    this.unscheduled = const [],
    this.conflicts = const [],
    required this.budgetMinutes,
    this.sleepNote,
    this.anchoredStart,
  });

  final AssistantProposalKind kind;
  final List<PlannedSession> sessions;
  final List<PlannedMove> moves;
  final List<PlannedCreation> creations;

  /// Items that could not fit, each with an honest reason.
  final List<String> unscheduled;

  /// Detected conflicts (sleep overlap avoided, deadline pressure, …).
  final List<String> conflicts;
  final int budgetMinutes;
  final String? sleepNote;
  final DateTime? anchoredStart;

  int get totalMinutes =>
      sessions.fold<int>(0, (sum, s) => sum + s.minutes);
  int get bufferMinutes => (budgetMinutes - totalMinutes).clamp(0, 1 << 30);
  bool get isEmpty =>
      sessions.isEmpty && moves.isEmpty && creations.isEmpty;

  /// Start times for each session from [anchoredStart] with [breakMinutes]
  /// gaps. Pure derivation for preview rendering.
  List<DateTime> laidOutStarts({int breakMinutes = 10}) {
    final start = anchoredStart ?? DateTime.now();
    final out = <DateTime>[];
    var cursor = start;
    for (final s in sessions) {
      out.add(cursor);
      cursor = cursor.add(Duration(minutes: s.minutes + breakMinutes));
    }
    return out;
  }
}

/// Deterministic assistant planning (P2). No LLM, no network.
///
/// Priority order (before existing plan rules, which stay authoritative for
/// stored blocks): overdue → due today → exam-linked → high priority →
/// revision → normal → low. Sessions clamp to 25–50 min, 10-min breaks,
/// never scheduled past the sleep boundary (or an explicit evening cutoff),
/// never more than the budget, never a 12h+ marathon (hard cap 8h).
abstract final class AssistantPlanningEngine {
  static const int minSessionMinutes = 25;
  static const int maxSessionMinutes = 50;
  static const int breakMinutes = 10;
  static const int maxDayMinutes = 8 * 60;

  static AssistantDayPlan proposeDayPlan({
    required DateTime now,
    required int budgetMinutes,
    required List<StudentTask> tasks,
    List<PlanningBlock> existingBlocks = const [],
    List<StudentExam> exams = const [],
    SleepSchedule? sleep,
    int? eveningCutoffMinutes,
    int sessionCap = 6,
    AssistantProposalKind kind = AssistantProposalKind.dayPlan,
    DateTime? anchorStart,
  }) {
    final budget = budgetMinutes.clamp(15, maxDayMinutes);

    // Sleep boundary: bedtime tonight (or explicit earlier cutoff).
    final conflicts = <String>[];
    int? latestEnd;
    String? sleepNote;
    if (sleep != null && sleep.enabled) {
      final bed = SleepScheduleValidation.normaliseMinutes(
        sleep.bedtimeMinutes,
      );
      var bedtime = DateTime(now.year, now.month, now.day, bed ~/ 60, bed % 60);
      if (!bedtime.isAfter(now)) {
        bedtime = bedtime.add(const Duration(days: 1));
      }
      latestEnd = bedtime.difference(now).inMinutes;
      sleepNote =
          'Your ${sleep.windowLabel} sleep is protected — nothing scheduled past bedtime.';
    }
    if (eveningCutoffMinutes != null) {
      final c = SleepScheduleValidation.normaliseMinutes(
        eveningCutoffMinutes,
      );
      var cutoff = DateTime(now.year, now.month, now.day, c ~/ 60, c % 60);
      if (!cutoff.isAfter(now)) {
        cutoff = cutoff.add(const Duration(days: 1));
      }
      final cutoffIn = cutoff.difference(now).inMinutes;
      if (latestEnd == null || cutoffIn < latestEnd) {
        latestEnd = cutoffIn;
        conflicts.add(
          'Evening cutoff ${SleepScheduleValidation.formatClock12(c)} respected.',
        );
      }
    }

    var effective = budget;
    if (latestEnd != null && latestEnd < effective) {
      effective = latestEnd.clamp(0, budget);
      if (effective < budget) {
        conflicts.add(
          'Only ${effective}m fits before your sleep boundary.',
        );
      }
    }

    final ranked = rankTasks(tasks, now, exams);
    final sessions = <PlannedSession>[];
    final unscheduled = <String>[];
    var used = 0;
    var index = 0;

    for (final task in ranked) {
      if (sessions.length >= sessionCap) {
        unscheduled.add(
          '"${task.title}" — kept for later (session cap reached).',
        );
        continue;
      }
      final minutes = (task.estimatedMinutes > 0
              ? task.estimatedMinutes
              : 30)
          .clamp(minSessionMinutes, maxSessionMinutes);
      final gap = sessions.isEmpty ? 0 : breakMinutes;
      if (used + gap + minutes > effective) {
        unscheduled.add(
          '"${task.title}" — needs ~${minutes}m, only ${effective - used}m left.',
        );
        continue;
      }
      used += gap + minutes;
      sessions.add(
        PlannedSession(
          id: 'p$index',
          title: task.title,
          detail: _sessionDetail(task),
          minutes: minutes,
          reason: _reasonFor(task, now, exams),
          taskId: task.id,
          subjectId: task.subjectId,
          examId: task.examId,
          dueDate: task.dueDate,
        ),
      );
      index++;
    }

    // Anchor: round up to the next 5 minutes from now, unless the caller
    // pins a start (e.g. tomorrow's wake time for advance preparation).
    final anchor = anchorStart ??
        DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          ((now.minute + 4) ~/ 5) * 5,
        );

    return AssistantDayPlan(
      kind: kind,
      sessions: sessions,
      unscheduled: unscheduled,
      conflicts: conflicts,
      budgetMinutes: budget,
      sleepNote: sleepNote,
      anchoredStart:
          anchor.isAfter(now) ? anchor : now.add(const Duration(minutes: 1)),
    );
  }

  /// Deterministic ranking. Overdue first, then due today, exam-linked,
  /// high priority, revision-ish, normal, low. Stable by due date, then
  /// creation order — same input always yields the same order.
  static List<StudentTask> rankTasks(
    List<StudentTask> tasks,
    DateTime now,
    List<StudentExam> exams,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    int score(StudentTask t) {
      var s = 0;
      // Exclusive tiers: a task due earlier today is already overdue —
      // it must not double-count the due-today bonus above truer overdues.
      if (t.isOverdue) {
        s += 1000;
      } else if (t.isDueToday) {
        s += 500;
      }
      if (t.examId != null) s += 300;
      switch (t.priority) {
        case TaskPriority.critical:
          s += 200;
          break;
        case TaskPriority.high:
          s += 100;
          break;
        case TaskPriority.medium:
          s += 20;
          break;
        case TaskPriority.low:
          break;
      }
      return s;
    }

    final ranked = tasks.where((t) => !t.isCompleted).toList();
    ranked.sort((a, b) {
      final cmp = score(b).compareTo(score(a));
      if (cmp != 0) return cmp;
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad != null && bd != null) {
        final dc = ad.compareTo(bd);
        if (dc != 0) return dc;
      } else if (ad != null) {
        return -1;
      } else if (bd != null) {
        return 1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    // "Today" scoping is the caller's job; the engine ranks everything and
    // the budget/cap keeps the plan realistic.
    return ranked.where((t) {
      if (t.dueDate == null) return true;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return !due.isAfter(today.add(const Duration(days: 1)));
    }).toList();
  }

  static String _sessionDetail(StudentTask task) {
    if (task.subjectId != null) return 'Subject task';
    if (task.examId != null) return 'Exam prep';
    if (task.category.isNotEmpty) return task.category;
    return 'Task';
  }

  static String _reasonFor(
    StudentTask task,
    DateTime now,
    List<StudentExam> exams,
  ) {
    if (task.isOverdue) return 'Overdue — recover first';
    if (task.isDueToday) return 'Due today';
    if (task.examId != null) {
      final exam = exams.where((e) => e.id == task.examId).firstOrNull;
      if (exam != null && exam.daysUntilExam != null) {
        return 'Exam in ${exam.daysUntilExam}d';
      }
      return 'Exam prep';
    }
    switch (task.priority) {
      case TaskPriority.critical:
        return 'Critical priority';
      case TaskPriority.high:
        return 'High priority';
      case TaskPriority.medium:
        return 'Up next';
      case TaskPriority.low:
        return 'Fits the remaining time';
    }
  }
}
