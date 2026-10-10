/// Home 3.0 — presentation model for the Student OS Command Center.
///
/// ARCHITECTURE SAFETY
/// This file contains **no business logic**. Every value below is read from an
/// authoritative engine/controller:
///
/// - `AcademicIntelligenceController` → `studentOSAction`, `dailyStudentState`,
///   `autopilotDayState`, `rankedActions` (AdaptivePriorityEngine)
/// - `PlanningBlockController` → today's blocks
/// - `FocusController` → the single active session
/// - `TaskController` / `ExamController` / `GoalController` → counters
/// - `UserPreferencesController` → Autopilot mode
///
/// The model only *adapts* those results into a shape the Home widgets can
/// render, and picks the single strongest recommendation without re-scoring it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide PrioritizedAction;

import '../../core/intelligence/academic_intelligence_controller.dart';
import '../../core/intelligence/academic_intelligence_engine.dart';
import '../../core/intelligence/adaptive_priority_engine.dart';
import '../../core/intelligence/autopilot_engine.dart';
import '../../core/intelligence/student_os_intelligence_engine.dart';
import '../../core/time/app_clock.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/focus/data/models/focus_mission.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/planning/models/planning_block.dart';
import '../../features/preferences/user_preferences_controller.dart';
import '../../features/study/study_controller.dart';
import '../../features/tasks/task_controller.dart';

/// Which active session Home is surfacing, if any.
///
/// Home never *starts* or *stops* a session — it only reflects the one session
/// that already exists in [FocusController].
enum HomeActiveSessionKind { focus, timer, stopwatch }

/// A read-only view of the already-active Focus/Timer/Stopwatch session.
@immutable
class HomeActiveSessionView {
  const HomeActiveSessionView({
    required this.kind,
    required this.title,
    required this.remaining,
    required this.elapsed,
    required this.isPaused,
    required this.planningBlockId,
  });

  final HomeActiveSessionKind kind;

  /// Subject/objective label, already resolved by the Focus domain.
  final String title;

  /// Remaining time. Zero for an open-ended stopwatch.
  final Duration remaining;

  final Duration elapsed;
  final bool isPaused;

  /// Non-null when the session is bound to a planned block, so Home can
  /// surface "today's plan" context without creating a second session.
  final String? planningBlockId;

  /// A stopwatch has no countdown target, so elapsed time is the only measure.
  bool get isOpenEnded => kind == HomeActiveSessionKind.stopwatch;

  /// "FOCUS ACTIVE" / "TIMER ACTIVE" / "STOPWATCH ACTIVE".
  String get badgeLabel {
    switch (kind) {
      case HomeActiveSessionKind.focus:
        return 'FOCUS ACTIVE';
      case HomeActiveSessionKind.timer:
        return 'TIMER ACTIVE';
      case HomeActiveSessionKind.stopwatch:
        return 'STOPWATCH ACTIVE';
    }
  }

  /// mm:ss remaining for countdown modes, "Xm elapsed" for a stopwatch.
  String get timeLabel {
    if (isOpenEnded) return '${elapsed.inMinutes}m elapsed';
    final m = remaining.inMinutes;
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s remaining';
  }

  static String formatClock(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// The ONE recommendation Home is allowed to show.
///
/// The score and the "why" both come from
/// [AdaptivePriorityEngine] via [AcademicIntelligenceController.rankedActions].
/// Home never re-ranks or invents a competing engine; it only picks the best
/// item that is not already being presented by the hero.
@immutable
class HomeRecommendationView {
  const HomeRecommendationView({
    required this.title,
    required this.reason,
    required this.supportingReasons,
    required this.estimatedMinutes,
    required this.action,
  });

  final String title;

  /// The engine's explanation, shown directly so Home never asserts anything
  /// the intelligence layer did not derive.
  final String reason;

  final List<String> supportingReasons;
  final int estimatedMinutes;

  /// A `StudentOSAction` assembled from the engine's ranked action so the
  /// existing [UniversalActionExecutor] can execute it. No new execution path.
  final StudentOSAction action;

  /// e.g. "25 min · Revision due today"
  String get metaLabel =>
      estimatedMinutes > 0 ? '$estimatedMinutes min' : 'Quick';
}

/// Autopilot awareness for Home. Reads the existing preference only —
/// Home does not implement any Autopilot behaviour.
enum HomeAutopilotAwareness { off, suggest, managing }

/// Small contextual labels for a Quick Action tile, e.g. "25 min" / "2 due".
@immutable
class HomeQuickActionDetail {
  const HomeQuickActionDetail({this.badge, this.detail});

  /// Short uppercase pill, e.g. "LIVE".
  final String? badge;

  /// One-line detail, e.g. "2 due".
  final String? detail;

  bool get hasDetail => (badge != null && badge!.isNotEmpty) ||
      (detail != null && detail!.isNotEmpty);
}

/// The complete derived view-state for the Home Command Center.
///
/// Built once per Home rebuild in [HomeCommandCenterState.derive] and passed
/// down to the section widgets, so widgets stay pure and do no calculations.
@immutable
class HomeCommandCenterState {
  const HomeCommandCenterState({
    required this.now,
    required this.plannedBlocks,
    required this.activeSession,
    required this.recommendation,
    required this.autopilotAwareness,
    required this.autopilotNextActionTitle,
    required this.recommendationCount,
    required this.plannedBlockCount,
    required this.plannedMinutes,
    required this.completedBlockCount,
    required this.overdueTaskCount,
    required this.todayTaskCount,
    required this.completedTaskCount,
    required this.revisionDueCount,
    required this.nextExamTitle,
    required this.nextExamDaysAway,
    required this.focusMinutesToday,
  });

  final DateTime now;
  final List<PlanningBlock> plannedBlocks;
  final HomeActiveSessionView? activeSession;

  /// The single strongest recommendation, or null when the hero already
  /// covers it (or there is genuinely nothing to suggest).
  final HomeRecommendationView? recommendation;

  final HomeAutopilotAwareness autopilotAwareness;
  final String? autopilotNextActionTitle;

  // ── Quick Action detail counters ──────────────────────────────────────
  final int recommendationCount;
  final int plannedBlockCount;
  final int plannedMinutes;
  final int completedBlockCount;

  // ── Progress counters ─────────────────────────────────────────────────
  final int overdueTaskCount;
  final int todayTaskCount;
  final int completedTaskCount;
  final int revisionDueCount;
  final int focusMinutesToday;

  // ── Exam awareness ────────────────────────────────────────────────────
  final String? nextExamTitle;
  final int? nextExamDaysAway;

  bool get hasActiveSession => activeSession != null;

  /// A block is "done" when its window has fully elapsed. Home does not invent
  /// a completion flag: [PlanningBlock] has no status field by design.
  int get completedBlocks {
    if (plannedBlocks.isEmpty) return completedBlockCount;
    var done = 0;
    for (final b in plannedBlocks) {
      if (!now.isBefore(b.endAt)) done++;
    }
    return done;
  }

  /// 0..1 completion of planned block count, not minutes.
  double get blockProgress {
    if (plannedBlocks.isEmpty) return 0;
    return (completedBlocks / plannedBlocks.length).clamp(0.0, 1.0);
  }

  /// ─────────────────────────────────────────────────────────────────────
  /// Derivation. Reads authoritative sources only.
  /// ─────────────────────────────────────────────────────────────────────
  static HomeCommandCenterState derive() {
    final aic = AcademicIntelligenceController.instance;
    final now = AppClock.current;

    // Today's planned blocks — authoritative planning source.
    List<PlanningBlock> blocks = const [];
    try {
      blocks = PlanningBlockController.instance.blocksForDay(
        DateTime(now.year, now.month, now.day),
      );
    } catch (_) {
      blocks = const [];
    }

    final daily = aic.dailyStudentState;
    final autopilot = aic.autopilotDayState;
    final heroAction = aic.studentOSAction;

    return HomeCommandCenterState(
      now: now,
      plannedBlocks: blocks,
      activeSession: _deriveActiveSession(),
      recommendation: _deriveRecommendation(heroAction: heroAction, aic: aic),
      autopilotAwareness: _deriveAutopilotAwareness(
        mode: UserPreferencesController.instance.autopilotMode,
      ),
      autopilotNextActionTitle: _deriveAutopilotNextTitle(autopilot),
      recommendationCount: _safeInt(() => aic.rankedActions.length),
      plannedBlockCount: blocks.length,
      plannedMinutes: daily.plannedMinutes,
      completedBlockCount: 0,
      overdueTaskCount: _safeInt(() => TaskController.instance.overdueTasks.length),
      todayTaskCount: _safeInt(() => TaskController.instance.todayTasks.length),
      completedTaskCount: _safeInt(
        () => TaskController.instance.todayCompletedCount,
      ),
      revisionDueCount: _safeInt(() => daily.revisionDueCount),
      nextExamTitle: _deriveNextExamTitle(),
      nextExamDaysAway: _deriveExamDaysAway(now),
      focusMinutesToday: _deriveFocusMinutesToday(now),
    );
  }

  /// Reflects the *existing* FocusController session. Home never creates one.
  static HomeActiveSessionView? _deriveActiveSession() {
    try {
      final session = FocusController.instance.activeSession;
      if (session == null) return null;
      final fc = FocusController.instance;
      final title = (session.subjectName != null && session.subjectName!.isNotEmpty)
          ? session.subjectName!
          : (session.objective.isNotEmpty ? session.objective : 'Study session');
      return HomeActiveSessionView(
        kind: switch (session.mode) {
          FocusMode.focusGuard => HomeActiveSessionKind.focus,
          FocusMode.timer => HomeActiveSessionKind.timer,
          FocusMode.stopwatch => HomeActiveSessionKind.stopwatch,
        },
        title: title,
        remaining: session.mode == FocusMode.stopwatch
            ? Duration.zero
            : fc.activeRemaining,
        elapsed: fc.activeElapsed,
        isPaused: session.isPaused,
        planningBlockId: session.planningBlockId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Picks exactly ONE recommendation: the top item from
  /// [AdaptivePriorityEngine] that the hero is not already showing.
  ///
  /// Returning null is a valid, honest outcome — Home must not invent a
  /// suggestion when the intelligence layer has none.
  static HomeRecommendationView? _deriveRecommendation({
    required StudentOSAction heroAction,
    required AcademicIntelligenceController aic,
  }) {
    try {
      for (final ranked in aic.rankedActions) {
        if (_sameTarget(ranked, heroAction)) continue;
        return HomeRecommendationView(
          title: ranked.title,
          reason: ranked.reason,
          supportingReasons: const [],
          estimatedMinutes: ranked.estimatedMinutes,
          action: _toStudentOSAction(ranked),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Guards against Home repeating what the hero already shows.
  static bool _sameTarget(PrioritizedAction ranked, StudentOSAction hero) {
    if (ranked.id == hero.id) return true;
    if (ranked.taskId != null && ranked.taskId == hero.taskId) return true;
    if (ranked.examId != null && ranked.examId == hero.examId) return true;
    // A scheduled-block hero already tells the student what to do next.
    if (hero.type == StudentOSActionType.scheduledBlock) return true;
    if (hero.isFocusActive) return true;
    return false;
  }

  /// Adapts a ranked action into the existing `StudentOSAction` shape so
  /// `UniversalActionExecutor.executeAction` handles it. No new executor.
  static StudentOSAction _toStudentOSAction(PrioritizedAction ranked) {
    final type = switch (ranked.type) {
      AcademicActionType.completeTask => StudentOSActionType.completeTask,
      AcademicActionType.examPreparation => StudentOSActionType.examPrep,
      AcademicActionType.studySession => StudentOSActionType.studySubject,
      AcademicActionType.syllabusRevision => StudentOSActionType.reviseTopic,
      AcademicActionType.backlogRecovery => StudentOSActionType.completeTask,
    };
    return StudentOSAction(
      id: ranked.id,
      title: ranked.title,
      subtitle: ranked.subjectName ?? ranked.topicTitle ?? 'Recommended',
      reason: ranked.reason,
      bulletReasons: [ranked.reason],
      type: type,
      suggestedDurationMinutes: ranked.estimatedMinutes,
      urgency: _urgencyFor(ranked.priorityScore),
      subjectId: ranked.subjectId,
      subjectName: ranked.subjectName,
      taskId: ranked.taskId,
      examId: ranked.examId,
      topicId: null,
      chapterId: null,
    );
  }

  /// Maps the engine's numeric priority onto the existing urgency enum so Home
  /// does not invent a competing severity scale.
  static RecommendationUrgency _urgencyFor(double score) {
    if (score >= 90) return RecommendationUrgency.critical;
    if (score >= 70) return RecommendationUrgency.high;
    if (score >= 40) return RecommendationUrgency.medium;
    return RecommendationUrgency.low;
  }

  static HomeAutopilotAwareness _deriveAutopilotAwareness({
    required AutopilotMode mode,
  }) {
    switch (mode) {
      case AutopilotMode.off:
        return HomeAutopilotAwareness.off;
      case AutopilotMode.suggest:
        return HomeAutopilotAwareness.suggest;
      case AutopilotMode.autopilot:
        return HomeAutopilotAwareness.managing;
    }
  }

  static String? _deriveAutopilotNextTitle(AutopilotDayState state) {
    try {
      final next = state.nextAction;
      if (next.id.isEmpty) return null;
      return next.title;
    } catch (_) {
      return null;
    }
  }

  static String? _deriveNextExamTitle() {
    try {
      final exam = ExamController.instance.nextExam;
      if (exam == null) return null;
      return exam.title.isNotEmpty ? exam.title : null;
    } catch (_) {
      return null;
    }
  }

  static int? _deriveExamDaysAway(DateTime now) {
    try {
      final exam = ExamController.instance.nextExam;
      final date = exam?.examDateTime;
      if (date == null) return null;
      final target = DateTime(date.year, date.month, date.day);
      final today = DateTime(now.year, now.month, now.day);
      return target.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  /// Focus Guard minutes completed today. Timer/Stopwatch are open-ended and
  /// are not counted as planned study time.
  static int _deriveFocusMinutesToday(DateTime now) {
    try {
      final today = DateTime(now.year, now.month, now.day);
      var minutes = 0;
      for (final s in FocusController.instance.sessions) {
        if (s.mode != FocusMode.focusGuard) continue;
        final end = s.endedAt;
        if (end == null) continue;
        if (DateTime(end.year, end.month, end.day) != today) continue;
        if (s.outcome == null) continue;
        minutes += s.plannedDuration.inMinutes;
      }
      final active = FocusController.instance.activeSession;
      if (active != null && active.mode == FocusMode.focusGuard) {
        minutes += FocusController.instance.activeElapsed.inMinutes;
      }
      return minutes;
    } catch (_) {
      return 0;
    }
  }

  /// Controller access must never take Home down; a failed read degrades to 0.
  static int _safeInt(int Function() read) {
    try {
      return read();
    } catch (_) {
      return 0;
    }
  }

  // ── Quick Action contextual details ────────────────────────────────────
  //
  // Every label below is a real counter from an existing controller. Home
  // shows nothing (empty string) when the counter is zero rather than
  // fabricating "0 items".
  String get focusDetailLabel =>
      hasActiveSession ? HomeActiveSessionView.formatClock(activeSession!.remaining) : '';

  String get planDayDetailLabel =>
      plannedBlockCount > 0 ? '$plannedBlockCount block${plannedBlockCount == 1 ? '' : 's'}' : '';

  String get studyDetailLabel {
    final c = _safeInt(() => StudyController.instance.todaySessions.length);
    if (c > 0) return 'Continue';
    return '';
  }

  String get reviseDetailLabel =>
      revisionDueCount > 0 ? '$revisionDueCount due' : '';

  String get examsDetailLabel {
    final d = nextExamDaysAway;
    if (d == null) return '';
    if (d == 0) return 'Today';
    if (d == 1) return 'Tomorrow';
    return '$d days';
  }

  String get tasksDetailLabel {
    if (overdueTaskCount > 0) return '$overdueTaskCount overdue';
    if (todayTaskCount > 0) return '$todayTaskCount today';
    return '';
  }
}

/// Shared formatting helper for the compact Home strings.
String formatHomeMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}
