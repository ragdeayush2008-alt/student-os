import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/exam.dart';
import '../../data/models/study_session.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/academic_resource.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/focus/data/models/focus_mission.dart';
import '../../features/planning/models/planning_block.dart';
import '../../features/planning/services/planning_engine.dart';
import '../../features/preferences/user_preferences_controller.dart';
import 'academic_intelligence_engine.dart';
import 'student_os_intelligence_engine.dart';

/// Mutation safety category for autopilot actions (P3).
enum AutopilotMutationCategory {
  safeAutomatic('Safe Automatic'),
  requiresConfirmation('Requires Confirmation'),
  neverAutomatic('Never Automatic');

  const AutopilotMutationCategory(this.label);
  final String label;
}

/// Health and momentum classification for the student's day.
enum DayHealthState {
  clear('All Clear', Color(0xFF6F967F)),
  onTrack('On Track', Color(0xFF4F7D68)),
  busy('Busy', Color(0xFF285C4D)),
  overloaded('Overloaded', Color(0xFF1F5C44)),
  recoveryNeeded('Recovery Needed', Color(0xFF7A8450));

  const DayHealthState(this.label, this.color);
  final String label;
  final Color color;
}

/// A freed-up time window detected when a session finishes earlier than planned.
@immutable
class EarlyCompletionOpportunity {
  const EarlyCompletionOpportunity({
    required this.freedMinutes,
    required this.originalPlannedMinutes,
    required this.actualMinutes,
    required this.completedSubjectName,
    required this.suggestion,
    this.recommendedAction,
  });

  final int freedMinutes;
  final int originalPlannedMinutes;
  final int actualMinutes;
  final String completedSubjectName;
  final String suggestion;
  final StudentOSAction? recommendedAction;
}

/// A preview of proposed non-destructive schedule adjustments.
@immutable
class AutopilotChangePreview {
  const AutopilotChangePreview({
    required this.id,
    required this.title,
    required this.reason,
    required this.movedBlockCount,
    required this.addedBlockCount,
    required this.freedMinutes,
    required this.canAutoApply,
    this.proposedPlan,
  });

  final String id;
  final String title;
  final String reason;
  final int movedBlockCount;
  final int addedBlockCount;
  final int freedMinutes;
  final bool canAutoApply;
  final DailyPlanResult? proposedPlan;
}

/// A compact end-of-day summary.
@immutable
class EndOfDaySummary {
  const EndOfDaySummary({
    required this.date,
    required this.studiedMinutes,
    required this.tasksCompletedCount,
    required this.blocksCompletedCount,
    required this.totalBlocksCount,
    required this.completionPercentage,
    required this.tomorrowTopPriority,
    required this.headline,
    required this.encouragingMessage,
  });

  final DateTime date;
  final int studiedMinutes;
  final int tasksCompletedCount;
  final int blocksCompletedCount;
  final int totalBlocksCount;
  final int completionPercentage;
  final String tomorrowTopPriority;
  final String headline;
  final String encouragingMessage;
}

/// The comprehensive, real-time Autopilot 2.0 Day State.
@immutable
class AutopilotDayState {
  const AutopilotDayState({
    required this.targetDay,
    required this.availableMinutes,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.remainingMinutes,
    required this.overdueMinutes,
    required this.healthState,
    required this.healthMessage,
    required this.nextAction,
    required this.startMyDayAction,
    this.continueMyDayAction,
    required this.activeFocus,
    required this.isDoneForToday,
    required this.isOverloaded,
    required this.overloadMinutes,
    required this.recoverySessions,
    this.earlyCompletion,
    required this.briefing,
    this.endOfDaySummary,
    required this.mode,
  });

  final DateTime targetDay;
  final int availableMinutes;
  final int plannedMinutes;
  final int completedMinutes;
  final int remainingMinutes;
  final int overdueMinutes;
  final DayHealthState healthState;
  final String healthMessage;
  final StudentOSAction nextAction;
  final StudentOSAction startMyDayAction;
  final StudentOSAction? continueMyDayAction;
  final FocusSession? activeFocus;
  final bool isDoneForToday;
  final bool isOverloaded;
  final int overloadMinutes;
  final List<MissedSession> recoverySessions;
  final EarlyCompletionOpportunity? earlyCompletion;
  final DailyBriefing briefing;
  final EndOfDaySummary? endOfDaySummary;
  final AutopilotMode mode;

  bool get hasActiveFocus => activeFocus != null && activeFocus!.isActive;
  bool get hasMissedWork => recoverySessions.isNotEmpty;
  bool get hasEarlyCompletion => earlyCompletion != null;
  double get progressRatio =>
      (plannedMinutes + completedMinutes) <= 0
          ? (completedMinutes > 0 ? 1.0 : 0.0)
          : (completedMinutes / (plannedMinutes + completedMinutes)).clamp(0.0, 1.0);
}

/// Pure, deterministic Autopilot 2.0 Orchestration Engine.
abstract final class StudentOSAutopilotEngine {
  /// Computes the complete Autopilot 2.0 daily state from underlying sources of truth.
  static AutopilotDayState computeAutopilotDayState({
    required DateTime targetDay,
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<PlanningBlock> blocks = const [],
    List<AcademicResource> resources = const [],
    int availableBudgetMinutes = 180,
    bool isDoneForToday = false,
    AutopilotMode mode = AutopilotMode.suggest,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = (DateTime(targetDay.year, targetDay.month, targetDay.day) == today);

    // 1. Focus state from source of truth
    final fc = FocusController.instance;
    final hasActiveFocus = fc.hasActiveSession;
    final activeFocus = fc.activeSession;

    // 2. Filter blocks for target day
    final dayBlocks = blocks.where((b) =>
        DateTime(b.startAt.year, b.startAt.month, b.startAt.day) ==
        DateTime(targetDay.year, targetDay.month, targetDay.day)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    int plannedMinutes = 0;
    for (final b in dayBlocks) {
      plannedMinutes += b.endAt.difference(b.startAt).inMinutes;
    }

    // 3. Completed study on target day
    final daySessions = sessions.where((s) =>
        s.isCompleted &&
        DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day) ==
        DateTime(targetDay.year, targetDay.month, targetDay.day)).toList();

    int completedMinutes = 0;
    for (final s in daySessions) {
      completedMinutes += s.durationSec ~/ 60;
    }

    // 4. Overdue calculations
    int overdueMinutes = 0;
    if (isToday) {
      final overdueTasks = tasks.where((t) => t.isOverdue && !t.isCompleted);
      for (final t in overdueTasks) {
        overdueMinutes += t.estimatedMinutes > 0 ? t.estimatedMinutes : 25;
      }
    }

    final remainingMinutes = math.max(0, plannedMinutes - completedMinutes);

    // 5. Missed sessions recovery identification
    final recoverySessions = isToday
        ? PlanningEngine.getMissedSessions(
            blocks: blocks,
            tasks: tasks,
            subjects: subjects,
            referenceTime: now,
          )
        : const <MissedSession>[];

    // 6. Early completion detection
    EarlyCompletionOpportunity? earlyCompletion;
    if (isToday && daySessions.isNotEmpty && !hasActiveFocus) {
      final latest = daySessions.first; // sorted newest first
      // If session had planned duration and ended significantly earlier (>=5 min)
      final plannedDur = latest.durationSec ~/ 60;
      final targetDur = 35; // benchmark
      if (plannedDur > 0 && plannedDur <= 25 && targetDur - plannedDur >= 10) {
        final freed = targetDur - plannedDur;
        earlyCompletion = EarlyCompletionOpportunity(
          freedMinutes: freed,
          originalPlannedMinutes: targetDur,
          actualMinutes: plannedDur,
          completedSubjectName: latest.subject,
          suggestion: 'You finished early! $freed minutes freed up for a quick revision.',
        );
      }
    }

    // 7. Overload calculations
    final isOverloaded = plannedMinutes > availableBudgetMinutes;
    final overloadMinutes = isOverloaded ? (plannedMinutes - availableBudgetMinutes) : 0;

    // 8. Day Health Determination
    final DayHealthState healthState;
    final String healthMessage;

    if (isDoneForToday) {
      healthState = DayHealthState.clear;
      healthMessage = "You're done for today. Great work!";
    } else if (recoverySessions.isNotEmpty) {
      healthState = DayHealthState.recoveryNeeded;
      healthMessage = "You have ${recoverySessions.length} session${recoverySessions.length == 1 ? '' : 's'} to recover.";
    } else if (isOverloaded) {
      healthState = DayHealthState.overloaded;
      healthMessage = "Today is overloaded by ${overloadMinutes}m.";
    } else if (plannedMinutes > availableBudgetMinutes * 0.75) {
      healthState = DayHealthState.busy;
      healthMessage = "Today is busy (${plannedMinutes}m planned).";
    } else if (plannedMinutes > 0 || completedMinutes > 0) {
      healthState = DayHealthState.onTrack;
      healthMessage = "You're on track.";
    } else {
      healthState = DayHealthState.clear;
      healthMessage = "Your schedule is clear.";
    }

    // 9. Central Next Action
    final nextAction = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      resources: resources,
      blocks: blocks,
      hasActiveFocus: hasActiveFocus,
      activeFocusObjective: activeFocus?.objective,
      activeFocusRemaining: fc.activeRemaining,
      activeFocusElapsed: fc.activeElapsed,
      isDoneForToday: isDoneForToday,
      referenceTime: now,
    );

    // 10. "Start My Day" Action derivation
    final StudentOSAction startMyDayAction;
    if (hasActiveFocus) {
      startMyDayAction = nextAction;
    } else if (isDoneForToday) {
      startMyDayAction = nextAction;
    } else if (dayBlocks.isNotEmpty) {
      // Find first uncompleted planned block
      final firstUncompletedBlock = dayBlocks
          .where((b) => b.endAt.isAfter(now) || (b.startAt.isBefore(now) && b.endAt.isAfter(now)))
          .firstOrNull ?? dayBlocks.first;

      final blockDuration = firstUncompletedBlock.endAt.difference(firstUncompletedBlock.startAt).inMinutes;
      final subject = firstUncompletedBlock.subjectId != null
          ? subjects.where((s) => s.id == firstUncompletedBlock.subjectId).firstOrNull
          : null;
      final task = firstUncompletedBlock.taskId != null
          ? tasks.where((t) => t.id == firstUncompletedBlock.taskId).firstOrNull
          : null;

      final title = firstUncompletedBlock.customTitle ??
          task?.title ??
          subject?.displayName ??
          'Start Planned Study';

      startMyDayAction = StudentOSAction(
        id: 'action_block_${firstUncompletedBlock.id}',
        title: title,
        subtitle: '${firstUncompletedBlock.startAt.hour.toString().padLeft(2, '0')}:${firstUncompletedBlock.startAt.minute.toString().padLeft(2, '0')} · $blockDuration min',
        reason: 'First planned block for today',
        bulletReasons: [
          'Assigned duration: $blockDuration min',
          subject != null ? 'Subject: ${subject.displayName}' : 'Planned session',
        ],
        type: StudentOSActionType.scheduledBlock,
        suggestedDurationMinutes: blockDuration,
        urgency: RecommendationUrgency.high,
        subjectId: firstUncompletedBlock.subjectId,
        subjectName: subject?.displayName,
        taskId: firstUncompletedBlock.taskId,
        examId: task?.examId,
      );
    } else {
      // No plan yet -> use primary academic recommendation
      startMyDayAction = nextAction;
    }

    // 11. "Continue My Day" Action derivation
    StudentOSAction? continueMyDayAction;
    if (!hasActiveFocus && !isDoneForToday && dayBlocks.isNotEmpty) {
      final uncompletedUpcomingBlocks = dayBlocks.where((b) {
        if (b.taskId != null) {
          final t = tasks.where((task) => task.id == b.taskId).firstOrNull;
          if (t != null && t.isCompleted) return false;
        }
        return b.startAt.isAfter(now) || (b.startAt.isBefore(now) && b.endAt.isAfter(now));
      }).toList();

      if (uncompletedUpcomingBlocks.isNotEmpty) {
        final nextBlock = uncompletedUpcomingBlocks.first;
        final dur = nextBlock.endAt.difference(nextBlock.startAt).inMinutes;
        final subject = nextBlock.subjectId != null
            ? subjects.where((s) => s.id == nextBlock.subjectId).firstOrNull
            : null;
        final task = nextBlock.taskId != null
            ? tasks.where((t) => t.id == nextBlock.taskId).firstOrNull
            : null;

        final title = nextBlock.customTitle ??
            task?.title ??
            subject?.displayName ??
            'Next Session';

        continueMyDayAction = StudentOSAction(
          id: 'action_block_${nextBlock.id}',
          title: title,
          subtitle: 'Next: ${_formatTime(nextBlock.startAt)} · $dur min',
          reason: 'Next scheduled block in your plan',
          bulletReasons: ['Assigned duration: $dur min'],
          type: StudentOSActionType.scheduledBlock,
          suggestedDurationMinutes: dur,
          urgency: RecommendationUrgency.high,
          subjectId: nextBlock.subjectId,
          subjectName: subject?.displayName,
          taskId: nextBlock.taskId,
          examId: task?.examId,
        );
      }
    }

    // 12. Daily Briefing
    final briefing = StudentOSIntelligenceEngine.generateDailyBriefing(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      blocks: blocks,
      resources: resources,
      isDoneForToday: isDoneForToday,
      referenceTime: now,
    );

    // 13. End of Day Summary (if past 6 PM or completed significant work)
    EndOfDaySummary? endOfDaySummary;
    final totalBlocksCount = dayBlocks.length;
    final completedBlocksCount = daySessions.length;
    final completionPct = totalBlocksCount > 0
        ? ((completedBlocksCount / totalBlocksCount) * 100).round().clamp(0, 100)
        : (completedMinutes > 0 ? 100 : 0);

    final tomorrowPriority = exams.where((e) => e.isUpcoming).firstOrNull?.title ??
        (subjects.isNotEmpty ? subjects.first.displayName : 'Academic Routine');

    if (now.hour >= 18 || isDoneForToday || (totalBlocksCount > 0 && completedBlocksCount >= totalBlocksCount)) {
      endOfDaySummary = EndOfDaySummary(
        date: today,
        studiedMinutes: completedMinutes,
        tasksCompletedCount: tasks.where((t) => t.isCompleted).length,
        blocksCompletedCount: completedBlocksCount,
        totalBlocksCount: totalBlocksCount,
        completionPercentage: completionPct,
        tomorrowTopPriority: tomorrowPriority,
        headline: completionPct >= 70 ? 'Great progress today!' : 'Today in Review',
        encouragingMessage: completedMinutes > 0
            ? 'You studied ${completedMinutes}m today ($completionPct% of plan).'
            : 'Rest and prepare for tomorrow.',
      );
    }

    return AutopilotDayState(
      targetDay: today,
      availableMinutes: availableBudgetMinutes,
      plannedMinutes: plannedMinutes,
      completedMinutes: completedMinutes,
      remainingMinutes: remainingMinutes,
      overdueMinutes: overdueMinutes,
      healthState: healthState,
      healthMessage: healthMessage,
      nextAction: nextAction,
      startMyDayAction: startMyDayAction,
      continueMyDayAction: continueMyDayAction,
      activeFocus: activeFocus,
      isDoneForToday: isDoneForToday,
      isOverloaded: isOverloaded,
      overloadMinutes: overloadMinutes,
      recoverySessions: recoverySessions,
      earlyCompletion: earlyCompletion,
      briefing: briefing,
      endOfDaySummary: endOfDaySummary,
      mode: mode,
    );
  }

  /// Categorize a mutation for safety boundary (P3).
  static AutopilotMutationCategory categorizeMutation(String action) {
    switch (action) {
      case 'derive_recommendation':
      case 'update_cached_state':
      case 'prepare_notification':
      case 'allocate_available_time_plan':
        return AutopilotMutationCategory.safeAutomatic;
      case 'move_block':
      case 'reschedule_task':
      case 'major_rebalance':
      case 'delete_planning_block':
        return AutopilotMutationCategory.requiresConfirmation;
      case 'delete_academic_record':
      case 'alter_exam_date':
      case 'alter_fixed_commitment':
      case 'mark_complete_without_evidence':
      case 'cancel_active_focus':
      case 'change_user_data':
        return AutopilotMutationCategory.neverAutomatic;
      default:
        return AutopilotMutationCategory.requiresConfirmation;
    }
  }

  /// Check if an action is safe to auto-execute in current mode.
  static bool isSafeToAutoExecute(String action, AutopilotMode mode) {
    final cat = categorizeMutation(action);
    if (cat == AutopilotMutationCategory.neverAutomatic) return false;
    if (cat == AutopilotMutationCategory.safeAutomatic) return true;
    // requiresConfirmation only auto in AUTOPILOT mode for safe flexible moves
    return mode == AutopilotMode.autopilot && (action == 'move_block' || action == 'allocate_available_time_plan');
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
