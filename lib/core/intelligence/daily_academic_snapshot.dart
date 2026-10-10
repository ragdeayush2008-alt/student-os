import 'package:flutter/foundation.dart';

import '../intelligence/academic_context.dart';
import '../intelligence/smart_recommendation_engine.dart';
import '../intelligence/adaptive_priority_engine.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/study/study_controller.dart';
import '../../features/focus/controller/focus_controller.dart';

/// Derived daily academic execution state.
/// Uses only existing controllers; never mutates student data.
@immutable
class DailyAcademicSnapshot {
  const DailyAcademicSnapshot({
    required this.todayTaskCount,
    required this.completedToday,
    required this.overdueCount,
    required this.nowAction,
    required this.nextAction,
    required this.upcomingExamDays,
    required this.studyMinutesToday,
    required this.focusMinutesToday,
    required this.hasActiveFocus,
    required this.completionRatio,
    required this.remainingWorkLabel,
  });

  final int todayTaskCount;
  final int completedToday;
  final int overdueCount;
  final PrioritizedAction? nowAction;
  final PrioritizedAction? nextAction;
  final int? upcomingExamDays;
  final int studyMinutesToday;
  final int focusMinutesToday;
  final bool hasActiveFocus;
  final double completionRatio;
  final String remainingWorkLabel;

  /// Derived from current controller state.
  factory DailyAcademicSnapshot.fromControllers() {
    final tc = TaskController.instance;
    final sc = StudyController.instance;
    final fc = FocusController.instance;
    final ctx = AcademicContext.fromControllers();
    final engine = const SmartRecommendationEngine();

    final nowAction = engine.recommend();
    final ordered = engine.orderRecommendations();
    final next = ordered.length > 1
        ? ordered[1]
        : (ordered.isNotEmpty ? ordered[0] : null);

    final todayTasks = tc.activeTasks.where((t) {
      if (t.dueDate == null) return false;
      final d = t.dueDate!;
      final nowD = DateTime.now();
      return d.year == nowD.year &&
          d.month == nowD.month &&
          d.day == nowD.day &&
          !t.isCompleted;
    }).toList();

    final completedToday = tc.tasks.where((t) => t.isCompleted).length;
    final overdue = tc.activeTasks
        .where((t) => t.isOverdue && !t.isCompleted)
        .length;

    // Study minutes today (derived from StudyController)
    final nowDate = DateTime.now();
    final studyTodaySec = sc.sessions
        .where(
          (s) =>
              s.startedAt.year == nowDate.year &&
              s.startedAt.month == nowDate.month &&
              s.startedAt.day == nowDate.day,
        )
        .fold<int>(0, (sum, s) => sum + s.durationSec);
    final studyMins = studyTodaySec ~/ 60;

    // Focus minutes today (from completed sessions today)
    final focusTodaySec = fc.sessions
        .where(
          (s) =>
              s.isComplete &&
              s.startedAt.year == nowDate.year &&
              s.startedAt.month == nowDate.month &&
              s.startedAt.day == nowDate.day,
        )
        .fold<int>(0, (sum, s) => sum + s.effectiveElapsed.inSeconds);
    final focusMins = focusTodaySec ~/ 60;

    // Upcoming exam (closest non-completed)
    final upcoming = ctx.upcomingExams.where((e) => !e.isCompleted).toList();
    final closestExam = upcoming.isNotEmpty
        ? upcoming.reduce(
            (a, b) =>
                (a.daysUntilExam ?? 999) < (b.daysUntilExam ?? 999) ? a : b,
          )
        : null;

    // Completion ratio: completed today vs total actionable today
    final totalToday = todayTasks.length + completedToday;
    final ratio = totalToday > 0 ? completedToday / totalToday : 0.0;

    // Remaining work label (honest, not fabricated)
    final remaining = overdue > 0
        ? '$overdue overdue'
        : (todayTasks.isNotEmpty
              ? '${todayTasks.length} today'
              : 'light workload');

    return DailyAcademicSnapshot(
      todayTaskCount: todayTasks.length,
      completedToday: completedToday,
      overdueCount: overdue,
      nowAction: nowAction,
      nextAction: next,
      upcomingExamDays: closestExam?.daysUntilExam,
      studyMinutesToday: studyMins,
      focusMinutesToday: focusMins,
      hasActiveFocus: fc.hasActiveSession,
      completionRatio: ratio.clamp(0.0, 1.0),
      remainingWorkLabel: remaining,
    );
  }
}
