import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_week_utils.dart';
import '../exams/exam_controller.dart';
import '../preferences/user_preferences_controller.dart';
import '../progression/progression_controller.dart';
import '../study/study_controller.dart';
import '../tasks/task_controller.dart';
import '../../data/models/study_session.dart';
import '../../data/models/task.dart';

/// The analysis window for the Progress destination.
enum ProgressRange {
  today('Today'),
  week('Week'),
  month('Month');

  const ProgressRange(this.label);
  final String label;
}

/// A half-open [start, end) span used to bound an analysis window.
@immutable
class ProgressSpan {
  const ProgressSpan({required this.start, required this.end});

  /// Inclusive start.
  final DateTime start;

  /// Exclusive end.
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);

  int get elapsedDays =>
      end.difference(start).inDays < 1 ? 1 : end.difference(start).inDays;
}

/// A single day of activity used by the weekly visualization.
@immutable
class ProgressDay {
  const ProgressDay({
    required this.date,
    required this.tasksCompleted,
    required this.studySeconds,
    required this.isToday,
  });

  final DateTime date;
  final int tasksCompleted;

  /// Study time on this day, in whole seconds.
  final int studySeconds;
  final bool isToday;

  bool get hasActivity => tasksCompleted > 0 || studySeconds > 0;

  /// Normalized combined activity 0.0–1.0 (relative to the busiest day).
  double activityRatio(double maxScore) =>
      maxScore == 0 ? 0 : combinedScore / maxScore;

  /// Weighted combination so tasks and study both contribute.
  double get combinedScore =>
      tasksCompleted * 1.0 + (studySeconds / 60.0) * 0.4;

  Duration get studyDuration => Duration(seconds: studySeconds);
}

/// A derived, real-data milestone earned from existing activity.
@immutable
class ProgressMilestone {
  const ProgressMilestone({
    required this.id,
    required this.title,
    required this.detail,
    required this.earned,
    required this.icon,
  });

  final String id;
  final String title;
  final String detail;
  final bool earned;
  final IconData icon;
}

/// A deterministic, data-backed insight derived from persisted activity.
@immutable
class ProgressInsight {
  const ProgressInsight({
    required this.id,
    required this.icon,
    required this.title,
    required this.detail,
    this.tint,
    this.onTap,
  });

  /// Stable identifier used by the screen to wire navigation.
  final String id;
  final IconData icon;
  final String title;
  final String detail;

  /// Optional accent color; defaults to palette primary.
  final Color? tint;

  /// Optional destination (registered by the screen) when applicable.
  final VoidCallback? onTap;
}

/// The set of actionable insight kinds the screen can wire to navigation.
abstract final class ProgressInsightKind {
  static const String overdue = 'overdue';
  static const String idle = 'idle';
}

/// Aggregated analytics for a single [ProgressRange].
///
/// All values are derived from the persisted [TaskController] and
/// [StudyController]; no analytics database or duplicated storage is used.
@immutable
class ProgressSnapshot {
  const ProgressSnapshot({
    required this.range,
    required this.span,
    // task metrics
    required this.totalTasks,
    required this.completedTotal,
    required this.activeTasks,
    required this.overdueTasks,
    required this.tasksCompletedInRange,
    required this.tasksExpectedInRange,
    // study metrics
    required this.studyDuration,
    required this.studySessions,
    required this.studyDays,
    required this.consistency,
    // combined
    required this.currentStreak,
    required this.bestStreak,
    required this.strongestDay,
    required this.weakestDay,
    required this.weeklyDays,
    // previous-period trend
    required this.prevTaskCompletionRate,
    required this.prevStudyDuration,
    required this.hasHistory,
    required this.prevCompletedTasks,
  });

  final ProgressRange range;
  final ProgressSpan span;

  // ── Task metrics ────────────────────────────────────────────────────
  final int totalTasks;
  final int completedTotal;
  final int activeTasks;
  final int overdueTasks;
  final int tasksCompletedInRange;
  final int tasksExpectedInRange;

  /// Overall lifetime completion fraction (0.0–1.0).
  double get lifetimeCompletion =>
      totalTasks == 0 ? 0 : completedTotal / totalTasks;

  /// Completion rate bounded to this window: completed vs expected.
  double get rangeCompletion => tasksExpectedInRange == 0
      ? 0
      : tasksCompletedInRange / tasksExpectedInRange;

  // ── Study metrics ───────────────────────────────────────────────────
  final Duration studyDuration;
  final int studySessions;
  final int studyDays;

  /// Fraction of elapsed days in this window with any activity.
  final double consistency;

  // ── Combined metrics ────────────────────────────────────────────────
  final int currentStreak;
  final int bestStreak;
  final DateTime? strongestDay;
  final DateTime? weakestDay;

  /// Seven normalized days for the weekly visualization (Mon–Sun of current week).
  final List<ProgressDay> weeklyDays;

  // ── Trend vs previous equivalent period ─────────────────────────────
  final double? prevTaskCompletionRate;
  final Duration prevStudyDuration;

  /// Whether there is enough history to compute a comparative trend.
  final bool hasHistory;

  // Convenience accessors ----------------------------------------------

  /// Whether the user has any real activity at all (tasks or study).
  bool get hasAnyActivity => totalTasks > 0 || studySessions > 0;

  /// Whether only study activity exists (used for onboarding copy).
  bool get hasOnlyStudy => totalTasks == 0 && studySessions > 0;

  bool get hasOnlyTasks => studySessions == 0 && totalTasks > 0;

  /// A meaningful momentum score in 0.0–100.0, or null when there is
  /// insufficient real data to justify one.
  ///
  /// Combines task completion, study consistency and streak into one number.
  /// Never shown with fake data — returns null when there is no activity.
  double? get momentumScore {
    if (!hasAnyActivity) return null;
    final completion = rangeCompletion.clamp(0.0, 1.0);
    final consistency = this.consistency.clamp(0.0, 1.0);
    final streakFactor = currentStreak == 0
        ? 0.0
        : (currentStreak / 14).clamp(0.0, 1.0);
    final score = (completion * 0.5 + consistency * 0.35 + streakFactor * 0.15);
    return (score * 100).clamp(0.0, 100.0);
  }

  /// Task delta vs the previous equivalent period (positive = improvement).
  int get taskDelta => tasksCompletedInRange - prevCompletedTasks;

  final int prevCompletedTasks;

  /// Study delta (positive = more study time) vs previous period.
  Duration get studyDelta => studyDuration - prevStudyDuration;
}

/// The intelligence and reflection layer of the Student OS ecosystem.
///
/// A thin [ChangeNotifier] singleton that derives analytics from the existing
/// [TaskController] and [StudyController] — it holds no data of its own and
/// introduces no new persistence. The screen listens to this controller for
/// range changes while also listening to the source controllers for live data.
class ProgressController extends ChangeNotifier {
  ProgressController._();

  static final ProgressController instance = ProgressController._();

  ProgressRange _range = ProgressRange.week;

  bool get _startsMonday =>
      UserPreferencesController.instance.weekStartDay == WeekStartDay.monday;

  /// The currently selected analysis range.
  ProgressRange get range => _range;

  /// Selects a new analysis [range]; no-op when unchanged.
  void selectRange(ProgressRange range) {
    if (range == _range) return;
    _range = range;
    notifyListeners();
  }

  /// Computes a snapshot for [range] from real persisted data.
  ///
  /// The result is derived fresh each call from the source controllers so the
  /// screen always reflects the latest task/study state without caching stale
  /// analytics. The weekly day series is always anchored to the current week.
  ProgressSnapshot snapshotFor(ProgressRange range) {
    final now = DateTime.now();
    final today = AppWeekUtils.dateOnly(now);
    final span = _spanFor(range, now);
    final prevSpan = _previousSpan(range, now);

    final tasks = TaskController.instance.tasks;
    final sessions = StudyController.instance.sessions;

    final completedAll = tasks.where((t) => t.isCompleted).toList();

    final tasksCompletedInRange = completedAll
        .where((t) => span.contains(t.completedAt!))
        .length;

    // "Expected" in this window: completed here, created here, or due here but
    // still active. This is an explainable denominator for the range rate.
    final createdInRange = tasks
        .where((t) => span.contains(t.createdAt))
        .length;
    final expectedFromDue = tasks.where((t) {
      if (t.dueDate == null) return false;
      if (!span.contains(t.dueDate!)) return false;
      return !t.isCompleted || span.contains(t.completedAt!);
    }).length;
    final tasksExpectedInRange =
        tasksCompletedInRange + createdInRange + expectedFromDue;

    final activeTasks = tasks.where((t) => !t.isCompleted).length;
    final overdueTasks = tasks.where((t) => t.isOverdue).length;

    // Study metrics within the window.
    final rangesSessions = sessions.where(
      (s) => s.isCompleted && span.contains(s.startedAt),
    );
    final studyDuration = Duration(
      seconds: rangesSessions.fold<int>(0, (sum, s) => sum + s.durationSec),
    );
    final studyDays = rangesSessions.map((s) => s.date).toSet().length;
    final consistency = _consistencyFor(span, sessions, tasks);

    // Combined streaks computed over all history.
    final currentStreak = _combinedStreak(sessions, tasks, today);
    final bestStreak = _bestStreak(sessions, tasks);

    // Strongest / weakest activity day within the window.
    final dayActivity = <DateTime, double>{};
    for (var t in completedAll) {
      if (span.contains(t.completedAt!)) {
        final d = AppWeekUtils.dateOnly(t.completedAt!);
        dayActivity[d] = (dayActivity[d] ?? 0) + 1;
      }
    }
    for (var s in sessions) {
      if (s.isCompleted && span.contains(s.startedAt)) {
        final d = s.date;
        dayActivity[d] = (dayActivity[d] ?? 0) + s.durationSec / 3600.0;
      }
    }
    DateTime? strongestDay;
    DateTime? weakestDay;
    if (dayActivity.isNotEmpty) {
      final sorted = dayActivity.keys.toList()..sort();
      var bestKey = sorted.first;
      var bestVal = dayActivity[bestKey]!;
      var worstKey = sorted.first;
      var worstVal = dayActivity[bestKey]!;
      for (final e in dayActivity.entries) {
        if (e.value > bestVal) {
          bestVal = e.value;
          bestKey = e.key;
        }
        if (e.value < worstVal) {
          worstVal = e.value;
          worstKey = e.key;
        }
      }
      strongestDay = bestKey;
      weakestDay = worstKey;
    }

    final weeklyDays = _weeklyDays(sessions, tasks, today);

    // Previous period trend.
    final prevCompletedInPrev = completedAll
        .where((t) => prevSpan.contains(t.completedAt!))
        .length;
    final prevCreated = tasks
        .where((t) => prevSpan.contains(t.createdAt))
        .length;
    final prevDue = tasks.where((t) {
      if (t.dueDate == null) return false;
      if (!prevSpan.contains(t.dueDate!)) return false;
      return !t.isCompleted || prevSpan.contains(t.completedAt!);
    }).length;
    final prevExpected = prevCompletedInPrev + prevCreated + prevDue;
    final prevTaskCompletionRate = prevExpected == 0
        ? null
        : prevCompletedInPrev / prevExpected;
    final prevStudyDuration = Duration(
      seconds: sessions
          .where((s) => s.isCompleted && prevSpan.contains(s.startedAt))
          .fold<int>(0, (sum, s) => sum + s.durationSec),
    );

    return ProgressSnapshot(
      range: range,
      span: span,
      totalTasks: tasks.length,
      completedTotal: completedAll.length,
      activeTasks: activeTasks,
      overdueTasks: overdueTasks,
      tasksCompletedInRange: tasksCompletedInRange,
      tasksExpectedInRange: tasksExpectedInRange,
      studyDuration: studyDuration,
      studySessions: rangesSessions.length,
      studyDays: studyDays,
      consistency: consistency,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      strongestDay: strongestDay,
      weakestDay: weakestDay,
      weeklyDays: weeklyDays,
      prevTaskCompletionRate: prevTaskCompletionRate,
      prevStudyDuration: prevStudyDuration,
      hasHistory: tasks.isNotEmpty || sessions.isNotEmpty,
      prevCompletedTasks: prevCompletedInPrev,
    );
  }

  /// Life-time milestones derived from real existing activity.
  ///
  /// No persistence is added — every milestone is recomputed from history so it
  /// reflects the true earned state.
  List<ProgressMilestone> milestones() {
    final sessions = StudyController.instance.sessions;
    final tasks = TaskController.instance.tasks;
    final completedTotal = tasks.where((t) => t.isCompleted).length;
    final totalStudySec = sessions.fold<int>(0, (s, x) => s + x.durationSec);
    final bestStudyStreak = _bestStudyStreak(sessions);

    return [
      ProgressMilestone(
        id: 'first_task',
        title: 'First task completed',
        detail: 'Break the ice with your first finished task',
        earned: completedTotal >= 1,
        icon: Icons.flag_rounded,
      ),
      ProgressMilestone(
        id: 'first_session',
        title: 'First study session',
        detail: 'Start a focus session to begin building rhythm',
        earned: sessions.any((s) => s.isCompleted),
        icon: Icons.menu_book_rounded,
      ),
      ProgressMilestone(
        id: 'tasks_10',
        title: 'Ten tasks done',
        detail: '$completedTotal of 10 tasks completed',
        earned: completedTotal >= 10,
        icon: Icons.task_alt_rounded,
      ),
      ProgressMilestone(
        id: 'study_streak_3',
        title: '3-day study streak',
        detail: 'Study three days in a row',
        earned: bestStudyStreak >= 3,
        icon: Icons.local_fire_department_rounded,
      ),
      ProgressMilestone(
        id: 'study_10h',
        title: '10 hours studied',
        detail:
            '${(totalStudySec / 3600).toStringAsFixed(0)} hours logged so far',
        earned: totalStudySec >= 10 * 3600,
        icon: Icons.timer_rounded,
      ),
      ..._xpMilestones(),
      ProgressMilestone(
        id: 'consistency',
        title: 'Weekly consistency',
        detail: 'Study on at least three days in one week',
        earned: _bestWeeklyConsistency(sessions) >= 3,
        icon: Icons.auto_graph_rounded,
      ),
      ..._examMilestones(),
    ];
  }

  /// Academic milestones derived from real exam and syllabus activity.
  ///
  /// Only surfaced when the student has actual exam data.
  List<ProgressMilestone> _examMilestones() {
    final exams = ExamController.instance.exams;
    if (exams.isEmpty) return const [];

    final syllabusCompleted = exams.fold<int>(
      0,
      (a, e) => a + e.syllabusCompleted,
    );
    final examCount = exams.length;
    final completedExams = exams.where((e) => e.isCompleted).length;

    return [
      ProgressMilestone(
        id: 'first_syllabus',
        title: 'First topic completed',
        detail: syllabusCompleted >= 1
            ? '$syllabusCompleted topic${syllabusCompleted == 1 ? '' : 's'} completed across exams'
            : 'Complete a syllabus topic to start',
        earned: syllabusCompleted >= 1,
        icon: Icons.menu_book_rounded,
      ),
      ProgressMilestone(
        id: 'first_exam_completed',
        title: 'First exam completed',
        detail: completedExams >= 1
            ? '$completedExams exam${completedExams == 1 ? '' : 's'} completed'
            : 'Complete an exam to earn this',
        earned: completedExams >= 1,
        icon: Icons.school_rounded,
      ),
      if (examCount >= 5)
        ProgressMilestone(
          id: 'exams_5',
          title: '5 exams tracked',
          detail: '$examCount exams tracked',
          earned: true,
          icon: Icons.event_available_rounded,
        ),
    ];
  }

  /// XP and progression milestones derived from ProgressionController.
  List<ProgressMilestone> _xpMilestones() {
    final totalXp = ProgressionController.instance.totalXp;
    final level = ProgressionController.instance.currentLevel.level;

    return [
      ProgressMilestone(
        id: 'xp_100',
        title: 'Century Club',
        detail: '$totalXp of 100 XP earned',
        earned: totalXp >= 100,
        icon: Icons.military_tech_rounded,
      ),
      ProgressMilestone(
        id: 'xp_500',
        title: '500 XP Milestone',
        detail: '$totalXp of 500 XP earned',
        earned: totalXp >= 500,
        icon: Icons.stars_rounded,
      ),
      ProgressMilestone(
        id: 'level_5',
        title: 'Focused Learner',
        detail: 'Reach Level 5 (currently Level $level)',
        earned: level >= 5,
        icon: Icons.workspace_premium_rounded,
      ),
      ProgressMilestone(
        id: 'level_10',
        title: 'Consistent Student',
        detail: 'Reach Level 10 (currently Level $level)',
        earned: level >= 10,
        icon: Icons.diamond_rounded,
      ),
    ];
  }

  /// Deterministic insights derived from a [snapshot].
  List<ProgressInsight> insightsFor(ProgressSnapshot s) {
    final List<ProgressInsight> out = [];

    if (!s.hasAnyActivity) return out;

    // Overdue workload warning (task related → navigate to tasks).
    if (s.overdueTasks > 0 && s.range == ProgressRange.week) {
      out.add(
        ProgressInsight(
          id: ProgressInsightKind.overdue,
          icon: Icons.warning_amber_rounded,
          title: 'Overdue workload',
          detail:
              '${s.overdueTasks} active '
              '${s.overdueTasks == 1 ? 'task is' : 'tasks are'} overdue — '
              'clear them to protect your momentum.',
          tint: AppColors.error,
        ),
      );
    }

    // Study consistency.
    if (s.range == ProgressRange.week && s.consistency > 0) {
      final days = (s.consistency * 7).round();
      out.add(
        ProgressInsight(
          id: ProgressInsightKind.idle,
          icon: Icons.restart_alt_rounded,
          title: 'Active study days',
          detail:
              'You studied on $days ${days == 1 ? 'day' : 'days'} this week.',
        ),
      );
    }

    // Strongest study day (week only, uses study data).
    if (s.range == ProgressRange.week) {
      final strongestWeek = _strongestStudyDay(s.span);
      if (strongestWeek != null) {
        out.add(
          ProgressInsight(
            id: ProgressInsightKind.idle,
            icon: Icons.wb_sunny_outlined,
            title: 'Strongest study day',
            detail:
                '${_dayName(strongestWeek.weekday)} carries your study rhythm this week.',
          ),
        );
      }
    }

    // Strongest overall activity day within range.
    if (s.strongestDay != null) {
      out.add(
        ProgressInsight(
          id: ProgressInsightKind.idle,
          icon: Icons.bolt_rounded,
          title: 'Most productive day',
          detail:
              '${_dayName(s.strongestDay!.weekday)} was your busiest day in this period.',
        ),
      );
    }

    // Improvement vs previous equivalent period (tasks), only when real.
    if (s.hasHistory && s.range != ProgressRange.today && s.taskDelta > 0) {
      out.add(
        ProgressInsight(
          id: ProgressInsightKind.idle,
          icon: Icons.trending_up_rounded,
          title: 'Stronger than before',
          detail:
              '${s.taskDelta} more ${s.taskDelta == 1 ? 'task' : 'tasks'} completed than the previous '
              'equivalent period.',
          tint: AppColors.success,
        ),
      );
    }

    // Improvement vs previous equivalent period (study).
    if (s.hasHistory &&
        s.range != ProgressRange.today &&
        s.studyDelta.inMinutes >= 10) {
      out.add(
        ProgressInsight(
          id: ProgressInsightKind.idle,
          icon: Icons.timer_outlined,
          title: 'More study time',
          detail:
              '${s.studyDelta.inMinutes} extra minutes of study versus the previous equivalent period.',
          tint: AppColors.success,
        ),
      );
    }

    return out;
  }

  // ── Range helpers ───────────────────────────────────────────────────

  ProgressSpan _spanFor(ProgressRange range, DateTime now) {
    final today = AppWeekUtils.dateOnly(now);
    return switch (range) {
      ProgressRange.today => ProgressSpan(
        start: today,
        end: today.add(const Duration(days: 1)),
      ),
      ProgressRange.week => () {
        final start = AppWeekUtils.startOfWeek(
          today,
          startsMonday: _startsMonday,
        );
        return ProgressSpan(
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      }(),
      ProgressRange.month => ProgressSpan(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 1),
      ),
    };
  }

  ProgressSpan _previousSpan(ProgressRange range, DateTime now) {
    final today = AppWeekUtils.dateOnly(now);
    return switch (range) {
      ProgressRange.today => ProgressSpan(
        start: today.subtract(const Duration(days: 1)),
        end: today,
      ),
      ProgressRange.week => () {
        final start = AppWeekUtils.startOfWeek(
          today,
          startsMonday: _startsMonday,
        ).subtract(const Duration(days: 7));
        return ProgressSpan(
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      }(),
      ProgressRange.month => () {
        final monthStart = DateTime(now.year, now.month, 1);
        final prev = DateTime(now.year, now.month - 1, 1);
        return ProgressSpan(start: prev, end: monthStart);
      }(),
    };
  }

  double _consistencyFor(
    ProgressSpan span,
    List<StudySession> sessions,
    List<StudentTask> tasks,
  ) {
    var activeDays = 0;
    // Only count days that have actually elapsed in the window.
    final now = DateTime.now();
    for (
      var d = span.start;
      !d.isAfter(span.end) && !d.isAfter(AppWeekUtils.dateOnly(now));
      d = d.add(const Duration(days: 1))
    ) {
      final date = d;
      final hasTask = tasks.any(
        (t) =>
            t.isCompleted &&
            t.completedAt != null &&
            AppWeekUtils.dateOnly(t.completedAt!) == date,
      );
      final hasStudy = sessions.any((s) => s.isCompleted && s.date == date);
      if (hasTask || hasStudy) activeDays++;
    }

    // Denominators: days elapsed in this window.
    var elapsed = 0;
    for (
      var d = span.start;
      !d.isAfter(span.end) && !d.isAfter(AppWeekUtils.dateOnly(now));
      d = d.add(const Duration(days: 1))
    ) {
      elapsed++;
    }
    if (elapsed == 0 && now.isAfter(span.start)) elapsed = 1;
    return elapsed == 0 ? 0 : activeDays / elapsed;
  }

  /// Consecutive days (ending today) with task completion OR study session.
  int _combinedStreak(
    List<StudySession> sessions,
    List<StudentTask> tasks,
    DateTime today,
  ) {
    var streak = 0;
    for (var offset = 0; offset < 365; offset++) {
      final day = today.subtract(Duration(days: offset));
      final hasTask = tasks.any(
        (t) =>
            t.isCompleted &&
            t.completedAt != null &&
            AppWeekUtils.dateOnly(t.completedAt!) == day,
      );
      final hasStudy = sessions.any((s) => s.isCompleted && s.date == day);
      if (hasTask || hasStudy) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _bestStreak(List<StudySession> sessions, List<StudentTask> tasks) {
    final activeDates = <DateTime>{};
    for (final t in tasks) {
      if (t.isCompleted && t.completedAt != null) {
        activeDates.add(AppWeekUtils.dateOnly(t.completedAt!));
      }
    }
    for (final s in sessions) {
      if (s.isCompleted) activeDates.add(s.date);
    }
    if (activeDates.isEmpty) return 0;
    final dates = activeDates.toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  int _bestStudyStreak(List<StudySession> sessions) {
    final activeDates =
        sessions.where((s) => s.isCompleted).map((s) => s.date).toSet().toList()
          ..sort();
    if (activeDates.isEmpty) return 0;
    var best = 1;
    var run = 1;
    for (var i = 1; i < activeDates.length; i++) {
      if (activeDates[i].difference(activeDates[i - 1]).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  int _bestWeeklyConsistency(List<StudySession> sessions) {
    // For each Monday anchor, count distinct study days in that week.
    final byWeek = <DateTime, Set<DateTime>>{};
    for (final s in sessions) {
      if (!s.isCompleted) continue;
      final start = AppWeekUtils.startOfWeek(
        s.date,
        startsMonday: _startsMonday,
      );
      byWeek.putIfAbsent(start, () => <DateTime>{}).add(s.date);
    }
    var best = 0;
    for (final days in byWeek.values) {
      if (days.length > best) best = days.length;
    }
    return best;
  }

  DateTime? _strongestStudyDay(ProgressSpan span) {
    final byDay = <DateTime, int>{};
    for (final s in StudyController.instance.sessions) {
      if (s.isCompleted && span.contains(s.startedAt)) {
        byDay[s.date] = (byDay[s.date] ?? 0) + s.durationSec;
      }
    }
    if (byDay.isEmpty) return null;
    DateTime? best;
    var bestSecs = -1;
    byDay.forEach((day, secs) {
      if (secs > bestSecs) {
        bestSecs = secs;
        best = day;
      }
    });
    return best;
  }

  /// Seven normalized days for the weekly visualization (Mon–Sun).
  List<ProgressDay> _weeklyDays(
    List<StudySession> sessions,
    List<StudentTask> tasks,
    DateTime today,
  ) {
    final start = AppWeekUtils.startOfWeek(today, startsMonday: _startsMonday);
    final out = <ProgressDay>[];
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final done = tasks
          .where(
            (t) =>
                t.isCompleted &&
                t.completedAt != null &&
                AppWeekUtils.dateOnly(t.completedAt!) == day,
          )
          .length;
      final secs = sessions
          .where((s) => s.isCompleted && s.date == day)
          .fold<int>(0, (sum, s) => sum + s.durationSec);
      out.add(
        ProgressDay(
          date: day,
          tasksCompleted: done,
          studySeconds: secs,
          isToday: day == AppWeekUtils.dateOnly(today),
        ),
      );
    }
    return out;
  }

  static String _dayName(int weekday) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday - 1];
}
