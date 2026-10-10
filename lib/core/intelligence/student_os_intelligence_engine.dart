import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/exam.dart';
import '../../data/models/study_session.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/academic_resource.dart';
import '../../features/goals/goal_controller.dart';
import '../../features/knowledge/academic_knowledge_controller.dart';
import '../../features/knowledge/topic_practice_controller.dart';
import '../../features/planning/models/planning_block.dart';
import '../../features/planning/services/planning_engine.dart';
import '../../features/preferences/user_preferences_controller.dart';
import '../time/app_clock.dart';
import 'academic_intelligence_engine.dart';
import 'academic_knowledge_engine.dart';

/// Type of universal Student OS action.
enum StudentOSActionType {
  focusActive('Focus Active'),
  scheduledBlock('Scheduled Block'),
  examPrep('Exam Preparation'),
  reviseTopic('Revision'),
  studySubject('Subject Study'),
  completeTask('Task Execution'),
  goalWork('Goal Progress'),
  planDay('Plan Day'),
  doneForToday('Done for Today'),
  empty('All Caught Up');

  const StudentOSActionType(this.label);
  final String label;
}

/// Workload status level for a day.
enum WorkloadState {
  balanced('Balanced', Color(0xFF6F967F)),
  busy('Busy', Color(0xFF285C4D)),
  overloaded('Overloaded', Color(0xFF1F5C44));

  const WorkloadState(this.label, this.color);
  final String label;
  final Color color;
}

/// Academic risk severity level.
enum AcademicRiskLevel {
  needsAttention('Needs Attention', Color(0xFF4F7D68)),
  highPriority('High Priority', Color(0xFF7A8450)),
  atRisk('At Risk', Color(0xFF1F5C44));

  const AcademicRiskLevel(this.label, this.color);
  final String label;
  final Color color;
}

/// A universal, explainable, actionable Student OS action item.
@immutable
class StudentOSAction {
  const StudentOSAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.bulletReasons,
    required this.type,
    required this.suggestedDurationMinutes,
    required this.urgency,
    this.subjectId,
    this.subjectName,
    this.examId,
    this.taskId,
    this.goalId,
    this.topicTitle,
    this.topicId,
    this.chapterId,
    this.isReversible = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final String reason;
  final List<String> bulletReasons;
  final StudentOSActionType type;
  final int suggestedDurationMinutes;
  final RecommendationUrgency urgency;
  final String? subjectId;
  final String? subjectName;
  final String? examId;
  final String? taskId;
  final String? goalId;
  final String? topicTitle;
  final String? topicId;
  final String? chapterId;
  final bool isReversible;

  bool get isFocusActive => type == StudentOSActionType.focusActive;
  bool get isDoneForToday => type == StudentOSActionType.doneForToday;
}

/// Daily student academic state snapshot.
@immutable
class DailyStudentState {
  const DailyStudentState({
    required this.targetDay,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.remainingMinutes,
    required this.availableMinutes,
    required this.upcomingExams,
    this.nextExam,
    required this.revisionDueCount,
    required this.tasksDueTodayCount,
    required this.overdueTasksCount,
    required this.hasActiveFocus,
    this.activeFocusObjective,
    required this.workloadState,
    required this.overloadMinutes,
    required this.isDoneForToday,
    required this.summary,
  });

  final DateTime targetDay;
  final int plannedMinutes;
  final int completedMinutes;
  final int remainingMinutes;
  final int availableMinutes;
  final List<StudentExam> upcomingExams;
  final StudentExam? nextExam;
  final int revisionDueCount;
  final int tasksDueTodayCount;
  final int overdueTasksCount;
  final bool hasActiveFocus;
  final String? activeFocusObjective;
  final WorkloadState workloadState;
  final int overloadMinutes;
  final bool isDoneForToday;
  final String summary;

  double get progressFraction =>
      (plannedMinutes + completedMinutes) <= 0
          ? (completedMinutes > 0 ? 1.0 : 0.0)
          : (completedMinutes / (plannedMinutes + completedMinutes)).clamp(0.0, 1.0);
}

/// Structured deterministic morning/daily brief.
@immutable
class DailyBriefing {
  const DailyBriefing({
    required this.greeting,
    required this.dateLabel,
    required this.todayBulletSummaries,
    required this.recommendedPriorities,
    this.primaryAction,
    required this.isDoneForToday,
  });

  final String greeting;
  final String dateLabel;
  final List<String> todayBulletSummaries;
  final List<StudentOSAction> recommendedPriorities;
  final StudentOSAction? primaryAction;
  final bool isDoneForToday;

  bool get hasPriorities => recommendedPriorities.isNotEmpty;
}

/// A deterministic academic risk indicator.
@immutable
class AcademicRisk {
  const AcademicRisk({
    required this.id,
    required this.title,
    required this.detail,
    required this.level,
    required this.icon,
    this.actionLabel,
    this.subjectId,
    this.examId,
    this.taskId,
  });

  final String id;
  final String title;
  final String detail;
  final AcademicRiskLevel level;
  final IconData icon;
  final String? actionLabel;
  final String? subjectId;
  final String? examId;
  final String? taskId;
}

/// Goal intelligence progress and work requirement summary.
@immutable
class GoalIntelligenceSummary {
  const GoalIntelligenceSummary({
    required this.personalGoal,
    required this.weeklyStudyTargetMinutes,
    required this.weeklyStudyActualMinutes,
    required this.studyProgressFraction,
    required this.weeklyTaskTarget,
    required this.weeklyTaskActual,
    required this.taskProgressFraction,
    required this.recommendedMinutesThisWeek,
    required this.linkedTasks,
    required this.isFallingBehind,
  });

  final String personalGoal;
  final int weeklyStudyTargetMinutes;
  final int weeklyStudyActualMinutes;
  final double studyProgressFraction;
  final int weeklyTaskTarget;
  final int weeklyTaskActual;
  final double taskProgressFraction;
  final int recommendedMinutesThisWeek;
  final List<StudentTask> linkedTasks;
  final bool isFallingBehind;
}

/// Autopilot plan generation preview for safe user confirmation.
@immutable
class AutopilotPlanPreview {
  const AutopilotPlanPreview({
    required this.availableBudgetMinutes,
    required this.allocatedStudyMinutes,
    required this.items,
    required this.isOverloaded,
    required this.overloadMinutes,
    required this.summary,
    required this.mode,
    required this.canAutoApply,
  });

  final int availableBudgetMinutes;
  final int allocatedStudyMinutes;
  final List<DailyPlanItem> items;
  final bool isOverloaded;
  final int overloadMinutes;
  final String summary;
  final AutopilotMode mode;
  final bool canAutoApply;

  bool get hasItems => items.isNotEmpty;
}

/// Pure, deterministic Student OS Intelligence & Autopilot Engine.
///
/// Orchestrates Study, Exams, Revision, Tasks, Goals, Focus, and Planning
/// into unified recommendations and safe autopilot planning.
abstract final class StudentOSIntelligenceEngine {
  // ══════════════════════════════════════════════════════════════════════════
  // 1. "WHAT SHOULD I DO NOW?" CENTRAL RECOMMENDATION
  // ══════════════════════════════════════════════════════════════════════════

  /// Selects the single best next action for the student right now.
  static StudentOSAction determineWhatShouldIDoNow({
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<AcademicResource> resources = const [],
    List<PlanningBlock> blocks = const [],
    String? personalGoal,
    bool hasActiveFocus = false,
    String? activeFocusObjective,
    Duration activeFocusRemaining = Duration.zero,
    Duration activeFocusElapsed = Duration.zero,
    bool isDoneForToday = false,
    DateTime? referenceTime,
    int? maxAvailableMinutes,
  }) {
    final now = referenceTime ?? AppClock.current;
    final today = DateTime(now.year, now.month, now.day);

    // 1. Active Focus Session takes top priority
    if (hasActiveFocus) {
      final title = (activeFocusObjective != null && activeFocusObjective.isNotEmpty)
          ? activeFocusObjective
          : 'Focus Session in Progress';
      final remMins = activeFocusRemaining.inMinutes;
      final subtitle = remMins > 0 ? '$remMins min remaining' : '${activeFocusElapsed.inMinutes} min elapsed';

      return StudentOSAction(
        id: 'action_focus_active',
        title: title,
        subtitle: subtitle,
        reason: 'Currently active focus session',
        bulletReasons: [subtitle, 'Tap to return to active session'],
        type: StudentOSActionType.focusActive,
        suggestedDurationMinutes: remMins > 0 ? remMins : 25,
        urgency: RecommendationUrgency.critical,
      );
    }

    // 2. "Done for today" state
    if (isDoneForToday) {
      return const StudentOSAction(
        id: 'action_done_today',
        title: 'Done for Today',
        subtitle: 'All planned work wrapped up',
        reason: 'You marked today as complete. Rest and recharge.',
        bulletReasons: [
          'No additional work scheduled for today',
          'Review progress or preview tomorrow when ready',
        ],
        type: StudentOSActionType.doneForToday,
        suggestedDurationMinutes: 0,
        urgency: RecommendationUrgency.low,
      );
    }

    // 3. Current or Next Scheduled PlanningBlock running on today
    if (blocks.isNotEmpty) {
      final todayBlocks = blocks
          .where((b) =>
              DateTime(b.startAt.year, b.startAt.month, b.startAt.day) == today)
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));

      final currentBlock = todayBlocks
          .where((b) => b.startAt.isBefore(now) && b.endAt.isAfter(now))
          .firstOrNull;

      final nextBlock = todayBlocks
          .where((b) =>
              b.startAt.isAfter(now) ||
              (b.startAt.isBefore(now) && b.endAt.isAfter(now)))
          .firstOrNull;

      final activeBlock = currentBlock ?? nextBlock;

      if (activeBlock != null) {
        final isRunning =
            activeBlock.startAt.isBefore(now) && activeBlock.endAt.isAfter(now);
        final remMins = isRunning
            ? activeBlock.endAt.difference(now).inMinutes
            : activeBlock.endAt.difference(activeBlock.startAt).inMinutes;

        String blockTitle = activeBlock.customTitle ?? 'Scheduled Session';
        StudentTask? linkedTask;
        if (activeBlock.taskId != null) {
          linkedTask =
              tasks.where((t) => t.id == activeBlock.taskId).firstOrNull;
          if (linkedTask != null) blockTitle = linkedTask.title;
        } else if (activeBlock.subjectId != null) {
          final s =
              subjects.where((sub) => sub.id == activeBlock.subjectId).firstOrNull;
          if (s != null && activeBlock.customTitle == null) {
            blockTitle = s.displayName;
          }
        }

        final subtitle = isRunning
            ? 'Scheduled right now · $remMins min remaining'
            : 'Starts at ${_formatTime(activeBlock.startAt)} · $remMins min';

        final hasOverdue = tasks.any((t) => t.isOverdue && !t.isCompleted);
        if (isRunning || !hasOverdue) {
          return StudentOSAction(
            id: 'action_block_${activeBlock.id}',
            title: blockTitle,
            subtitle: subtitle,
            reason: isRunning
                ? 'Currently scheduled block in your plan'
                : 'Next scheduled block in today\'s plan',
            bulletReasons: [
              'Starts at ${_formatTime(activeBlock.startAt)}',
              'Ends at ${_formatTime(activeBlock.endAt)}',
            ],
            type: StudentOSActionType.scheduledBlock,
            suggestedDurationMinutes: remMins > 0
                ? remMins
                : activeBlock.endAt
                    .difference(activeBlock.startAt)
                    .inMinutes,
            urgency: RecommendationUrgency.high,
            subjectId: activeBlock.subjectId,
            taskId: activeBlock.taskId,
            examId: linkedTask?.examId,
            topicId: activeBlock.topicId,
            chapterId: activeBlock.chapterId,
          );
        }
      }
    }

    // 4. Overdue Tasks take high priority
    final overdueTasks = tasks.where((t) {
      if (t.isCompleted) return false;
      if (t.dueDate != null) {
        return t.dueDate!.isBefore(now);
      }
      return false;
    }).toList()
      ..sort((a, b) {
        if (a.priority == TaskPriority.critical) return -1;
        if (b.priority == TaskPriority.critical) return 1;
        return (a.dueDate ?? now).compareTo(b.dueDate ?? now);
      });

    if (overdueTasks.isNotEmpty) {
      final topTask = overdueTasks.first;
      final daysOverdue = topTask.dueDate != null
          ? math.max(1, today.difference(DateTime(topTask.dueDate!.year, topTask.dueDate!.month, topTask.dueDate!.day)).inDays)
          : 1;

      final matchedSubj = topTask.subjectId != null
          ? AcademicIntelligenceEngine.findSubjectMatch(topTask.subjectId!, subjects)
          : null;

      return StudentOSAction(
        id: 'action_task_overdue_${topTask.id}',
        title: topTask.title,
        subtitle: 'Overdue by $daysOverdue ${daysOverdue == 1 ? "day" : "days"} · ${topTask.priority.label} priority',
        reason: 'Overdue task requiring immediate completion',
        bulletReasons: [
          'Overdue by $daysOverdue ${daysOverdue == 1 ? "day" : "days"}',
          '${topTask.priority.label} academic priority',
          if (matchedSubj != null) 'Subject: ${matchedSubj.displayName}',
        ],
        type: StudentOSActionType.completeTask,
        suggestedDurationMinutes: topTask.estimatedMinutes > 0 ? topTask.estimatedMinutes : 25,
        urgency: RecommendationUrgency.critical,
        subjectId: topTask.subjectId,
        subjectName: matchedSubj?.displayName,
        taskId: topTask.id,
        examId: topTask.examId,
      );
    }

    // 5. Critical Exam Pressure / Urgent Upcoming Exams with incomplete topics
    final upcomingExams = exams.where((e) => e.isUpcoming).toList();
    if (upcomingExams.isNotEmpty) {
      final examPressures = upcomingExams.map((e) => AcademicIntelligenceEngine.assessExamPressure(
            e,
            sessions: sessions,
            tasks: tasks,
            subjects: subjects,
            referenceTime: now,
          )).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      final topExamPressure = examPressures.first;
      if (topExamPressure.level == ExamPressureLevel.critical ||
          (topExamPressure.level == ExamPressureLevel.high && topExamPressure.syllabusRemainingCount > 0) ||
          topExamPressure.daysRemaining <= 1) {
        final exam = topExamPressure.exam;
        final nextTopic = exam.syllabusItems.where((s) => !s.completed).firstOrNull?.title;
        final actionTitle = nextTopic != null ? 'Revise $nextTopic' : 'Prepare for ${exam.title}';

        final matchedSubj = AcademicIntelligenceEngine.findSubjectMatch(exam.subject, subjects);

        return StudentOSAction(
          id: 'action_exam_${exam.id}',
          title: actionTitle,
          subtitle: '${topExamPressure.level.label} · ${exam.subject}',
          reason: topExamPressure.primaryReason,
          bulletReasons: topExamPressure.reasons,
          type: StudentOSActionType.examPrep,
          suggestedDurationMinutes: 45,
          urgency: topExamPressure.level == ExamPressureLevel.critical
              ? RecommendationUrgency.critical
              : RecommendationUrgency.high,
          subjectId: matchedSubj?.id,
          subjectName: exam.subject,
          examId: exam.id,
          topicTitle: nextTopic,
        );
      }
    }

    // 6. Overdue / Urgent Revision items
    final revisionRecs = AcademicIntelligenceEngine.generateRevisionRecommendations(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      resources: resources,
      referenceTime: now,
    );

    final overdueRevision = revisionRecs.where((r) => r.isOverdue || r.urgency == RecommendationUrgency.critical).firstOrNull;
    if (overdueRevision != null) {
      return StudentOSAction(
        id: overdueRevision.id,
        title: overdueRevision.title,
        subtitle: '${overdueRevision.subjectName} · Revision Due',
        reason: overdueRevision.primaryReason,
        bulletReasons: overdueRevision.reasons,
        type: StudentOSActionType.reviseTopic,
        suggestedDurationMinutes: 30,
        urgency: overdueRevision.urgency,
        subjectId: overdueRevision.subjectId,
        subjectName: overdueRevision.subjectName,
        examId: overdueRevision.examId,
        topicTitle: overdueRevision.topicTitle,
        topicId: overdueRevision.topicId,
        chapterId: overdueRevision.chapterId,
      );
    }

    // 6b. Weak Topic — practice accuracy / repeated failures / study gap
    final weakCandidates = AcademicKnowledgeEngine.getWeakTopics(
      topics: AcademicKnowledgeController.instance.topics,
      sessions: sessions,
      practiceAttempts: TopicPracticeController.instance.attempts,
      referenceTime: now,
    );
    if (weakCandidates.isNotEmpty) {
      // Prefer weak topic that is not already overdue revision (avoid duplicate)
      final topWeak = weakCandidates.firstWhere(
        (w) => !revisionRecs.any((r) => r.topicId == w.topic.id),
        orElse: () => weakCandidates.first,
      );
      final subj = AcademicIntelligenceEngine.findSubjectMatch(topWeak.topic.subjectId, subjects);
      return StudentOSAction(
        id: 'action_weak_${topWeak.topic.id}',
        title: 'Practice ${topWeak.topic.title}',
        subtitle: '${subj?.displayName ?? 'Practice'} · Weak area',
        reason: topWeak.weakTopicReason ?? 'Practice accuracy ${topWeak.practiceAccuracyPercentage ?? 0}% — needs reinforcement',
        bulletReasons: [
          topWeak.weakTopicReason ?? 'Identified as weak topic needing practice',
          if (topWeak.practiceAccuracyPercentage != null) 'Accuracy ${topWeak.practiceAccuracyPercentage}% (target 70%+)',
          if (topWeak.practiceAttemptsCount > 0) '${topWeak.practiceAttemptsCount} practice attempt(s) recorded',
        ],
        type: StudentOSActionType.studySubject,
        suggestedDurationMinutes: 25,
        urgency: RecommendationUrgency.high,
        subjectId: topWeak.topic.subjectId,
        subjectName: subj?.displayName,
        topicId: topWeak.topic.id,
        chapterId: topWeak.topic.chapterId,
        topicTitle: topWeak.topic.title,
      );
    }

    // 7. Today's Due / High Priority / Active Tasks
    final activeTasks = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) {
        if (a.priority == TaskPriority.critical) return -1;
        if (b.priority == TaskPriority.critical) return 1;
        if (a.priority == TaskPriority.high && b.priority != TaskPriority.high) return -1;
        if (b.priority == TaskPriority.high && a.priority != TaskPriority.high) return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    if (activeTasks.isNotEmpty) {
      final task = activeTasks.first;
      final isDueToday = task.dueDate != null && DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day) == today;
      final matchedSubj = task.subjectId != null
          ? AcademicIntelligenceEngine.findSubjectMatch(task.subjectId!, subjects)
          : null;

      final subtitle = isDueToday
          ? 'Due today · ${task.priority.label} priority'
          : '${task.priority.label} priority task';

      return StudentOSAction(
        id: 'action_task_today_${task.id}',
        title: task.title,
        subtitle: subtitle,
        reason: isDueToday ? 'Scheduled due today in your academic task list' : 'Priority task to complete',
        bulletReasons: [
          if (isDueToday) 'Due today',
          '${task.priority.label} priority',
          if (matchedSubj != null) 'Subject: ${matchedSubj.displayName}',
        ],
        type: StudentOSActionType.completeTask,
        suggestedDurationMinutes: task.estimatedMinutes > 0 ? task.estimatedMinutes : 25,
        urgency: task.priority == TaskPriority.critical
            ? RecommendationUrgency.high
            : RecommendationUrgency.medium,
        subjectId: task.subjectId,
        subjectName: matchedSubj?.displayName,
        taskId: task.id,
        examId: task.examId,
        goalId: task.goalId,
      );
    }

    // 8. Academic Unified Subject Study Recommendation
    final unified = AcademicIntelligenceEngine.generateUnifiedRecommendation(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      resources: resources,
      referenceTime: now,
    );

    if (unified.hasRecommendation) {
      final rec = unified.primary!;
      return StudentOSAction(
        id: rec.id,
        title: rec.title,
        subtitle: '${rec.suggestedDurationMinutes} min · ${rec.subjectName}',
        reason: rec.primaryReason,
        bulletReasons: rec.reasons,
        type: rec.type == AcademicRecommendationType.reviseTopic
            ? StudentOSActionType.reviseTopic
            : rec.type == AcademicRecommendationType.examPrep
                ? StudentOSActionType.examPrep
                : StudentOSActionType.studySubject,
        suggestedDurationMinutes: rec.suggestedDurationMinutes,
        urgency: rec.urgency,
        subjectId: rec.subjectId,
        subjectName: rec.subjectName,
        examId: rec.exam?.id,
        taskId: rec.task?.id,
        topicTitle: rec.topicTitle,
        topicId: rec.topicId,
        chapterId: rec.chapterId,
      );
    }

    // 9. Default Empty State
    return const StudentOSAction(
      id: 'action_all_clear',
      title: 'All Caught Up',
      subtitle: 'No urgent tasks or study sessions',
      reason: 'Your academic schedule is clear. Plan your next goals or take a rest.',
      bulletReasons: [
        'No overdue tasks or exams',
        'Use "Plan My Day" to schedule optional study',
      ],
      type: StudentOSActionType.empty,
      suggestedDurationMinutes: 0,
      urgency: RecommendationUrgency.low,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. DAILY STUDENT STATE & BRIEFING
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates the compact, real-time daily academic state.
  static DailyStudentState computeDailyStudentState({
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<PlanningBlock> blocks = const [],
    List<AcademicResource> resources = const [],
    int availableBudgetMinutes = 180,
    bool hasActiveFocus = false,
    String? activeFocusObjective,
    bool isDoneForToday = false,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? AppClock.current;
    final today = DateTime(now.year, now.month, now.day);

    // Filter today's blocks & completed study
    final todayBlocks = blocks.where((b) =>
        DateTime(b.startAt.year, b.startAt.month, b.startAt.day) == today).toList();

    int scheduledMins = 0;
    for (final b in todayBlocks) {
      scheduledMins += b.endAt.difference(b.startAt).inMinutes;
    }

    final todaySessions = sessions.where((s) =>
        s.isCompleted &&
        DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day) == today).toList();

    int completedMins = 0;
    for (final s in todaySessions) {
      completedMins += s.durationSec ~/ 60;
    }

    final remainingMins = math.max(0, scheduledMins - completedMins);

    final upcomingExams = exams.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => (a.daysUntilExam ?? 999).compareTo(b.daysUntilExam ?? 999));

    final nextExam = upcomingExams.firstOrNull;

    final overdueTasksCount = tasks.where((t) => t.isOverdue && !t.isCompleted).length;
    final todayTasksCount = tasks.where((t) {
      if (t.isCompleted) return false;
      if (t.dueDate != null) {
        return DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day) == today;
      }
      return false;
    }).length;

    final revisionRecs = AcademicIntelligenceEngine.generateRevisionRecommendations(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      resources: resources,
      referenceTime: now,
    );

    // Workload determination
    final isOverloaded = scheduledMins > availableBudgetMinutes;
    final overloadMins = isOverloaded ? (scheduledMins - availableBudgetMinutes) : 0;
    final workloadState = isOverloaded
        ? WorkloadState.overloaded
        : (scheduledMins > availableBudgetMinutes * 0.75 ? WorkloadState.busy : WorkloadState.balanced);

    String summary;
    if (isDoneForToday) {
      summary = 'Done for today: ${completedMins}m studied across ${todaySessions.length} sessions.';
    } else if (isOverloaded) {
      summary = 'Today is overloaded by ${overloadMins}m ($scheduledMins m planned vs $availableBudgetMinutes m budget).';
    } else if (remainingMins > 0) {
      summary = '${remainingMins}m remaining of ${scheduledMins}m planned today.';
    } else if (completedMins > 0) {
      summary = 'All ${completedMins}m planned study completed for today!';
    } else {
      summary = 'No planned blocks today. Select "Plan My Day" to get started.';
    }

    return DailyStudentState(
      targetDay: today,
      plannedMinutes: scheduledMins,
      completedMinutes: completedMins,
      remainingMinutes: remainingMins,
      availableMinutes: availableBudgetMinutes,
      upcomingExams: upcomingExams,
      nextExam: nextExam,
      revisionDueCount: revisionRecs.length,
      tasksDueTodayCount: todayTasksCount,
      overdueTasksCount: overdueTasksCount,
      hasActiveFocus: hasActiveFocus,
      activeFocusObjective: activeFocusObjective,
      workloadState: workloadState,
      overloadMinutes: overloadMins,
      isDoneForToday: isDoneForToday,
      summary: summary,
    );
  }

  /// Generates a deterministic daily briefing.
  static DailyBriefing generateDailyBriefing({
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<PlanningBlock> blocks = const [],
    List<AcademicResource> resources = const [],
    bool isDoneForToday = false,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateLabel = '${months[now.month - 1]} ${now.day}';

    final state = computeDailyStudentState(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      blocks: blocks,
      resources: resources,
      isDoneForToday: isDoneForToday,
      referenceTime: now,
    );

    final summaries = <String>[];
    if (state.plannedMinutes > 0) {
      summaries.add('• ${state.plannedMinutes}m planned (${state.remainingMinutes}m remaining)');
    }
    if (state.revisionDueCount > 0) {
      summaries.add('• ${state.revisionDueCount} revision ${state.revisionDueCount == 1 ? "item" : "items"} due');
    }
    if (state.tasksDueTodayCount > 0) {
      summaries.add('• ${state.tasksDueTodayCount} task${state.tasksDueTodayCount == 1 ? "" : "s"} due today');
    }
    if (state.overdueTasksCount > 0) {
      summaries.add('• ${state.overdueTasksCount} overdue task${state.overdueTasksCount == 1 ? "" : "s"}');
    }
    if (state.nextExam != null) {
      final days = state.nextExam!.daysUntilExam;
      final dayStr = days == null ? 'soon' : (days == 0 ? 'today' : (days == 1 ? 'tomorrow' : 'in $days days'));
      summaries.add('• ${state.nextExam!.title} exam $dayStr');
    }

    if (summaries.isEmpty) {
      summaries.add('• All clear for today — no urgent tasks or exams.');
    }

    // Top 3 Recommended priorities
    final primaryAction = determineWhatShouldIDoNow(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      resources: resources,
      blocks: blocks,
      isDoneForToday: isDoneForToday,
      referenceTime: now,
    );

    final priorities = <StudentOSAction>[];
    if (primaryAction.type != StudentOSActionType.empty && primaryAction.type != StudentOSActionType.doneForToday) {
      priorities.add(primaryAction);
    }

    // Add remaining tasks or revision items
    for (final task in tasks.where((t) => !t.isCompleted && t.id != primaryAction.taskId).take(2)) {
      priorities.add(
        StudentOSAction(
          id: 'brief_task_${task.id}',
          title: task.title,
          subtitle: task.dueDate != null ? 'Due soon' : '${task.priority.label} priority',
          reason: 'Active task in priority backlog',
          bulletReasons: ['Task priority: ${task.priority.label}'],
          type: StudentOSActionType.completeTask,
          suggestedDurationMinutes: task.estimatedMinutes > 0 ? task.estimatedMinutes : 25,
          urgency: task.priority == TaskPriority.critical ? RecommendationUrgency.high : RecommendationUrgency.medium,
          taskId: task.id,
          subjectId: task.subjectId,
          examId: task.examId,
        ),
      );
    }

    return DailyBriefing(
      greeting: greeting,
      dateLabel: dateLabel,
      todayBulletSummaries: summaries,
      recommendedPriorities: priorities.take(3).toList(),
      primaryAction: primaryAction,
      isDoneForToday: isDoneForToday,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. ACADEMIC RISK DETECTION
  // ══════════════════════════════════════════════════════════════════════════

  /// Detects deterministic academic risks using constructive, non-fearful language.
  static List<AcademicRisk> detectAcademicRisks({
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<PlanningBlock> blocks = const [],
    List<AcademicResource> resources = const [],
    int availableBudgetMinutes = 180,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final risks = <AcademicRisk>[];

    // 1. Exam Approaching with Insufficient Preparation
    final upcomingExams = exams.where((e) => e.isUpcoming).toList();
    for (final exam in upcomingExams) {
      final pressure = AcademicIntelligenceEngine.assessExamPressure(
        exam,
        sessions: sessions,
        tasks: tasks,
        subjects: subjects,
        referenceTime: now,
      );

      if (pressure.level == ExamPressureLevel.critical) {
        risks.add(
          AcademicRisk(
            id: 'risk_exam_crit_${exam.id}',
            title: '${exam.title} needs immediate attention',
            detail: '${pressure.daysRemaining} days left with ${pressure.syllabusRemainingCount} syllabus topics incomplete.',
            level: AcademicRiskLevel.atRisk,
            icon: Icons.school_rounded,
            actionLabel: 'Study Now',
            examId: exam.id,
          ),
        );
      } else if (pressure.level == ExamPressureLevel.high && pressure.recentStudyMinutes < 30) {
        risks.add(
          AcademicRisk(
            id: 'risk_exam_study_${exam.id}',
            title: 'Study time needed for ${exam.title}',
            detail: 'Only ${pressure.recentStudyMinutes}m studied this week with exam in ${pressure.daysRemaining} days.',
            level: AcademicRiskLevel.highPriority,
            icon: Icons.timer_outlined,
            actionLabel: 'Plan Study',
            examId: exam.id,
          ),
        );
      }
    }

    // 2. Overdue Tasks Accumulating
    final overdueCount = tasks.where((t) => t.isOverdue && !t.isCompleted).length;
    if (overdueCount >= 3) {
      risks.add(
        AcademicRisk(
          id: 'risk_overdue_tasks',
          title: '$overdueCount overdue tasks accumulating',
          detail: 'Take a focused 30-minute burst to clear pending deadlines.',
          level: AcademicRiskLevel.highPriority,
          icon: Icons.warning_amber_rounded,
          actionLabel: 'View Tasks',
        ),
      );
    }

    // 3. Neglected Subjects (>7 days without study while active)
    if (subjects.length > 1) {
      for (final s in subjects.where((s) => s.isActive)) {
        final days = AcademicIntelligenceEngine.daysSinceLastStudied(s.name, sessions, referenceTime: now);
        if (days >= 7 && days < 900) {
          risks.add(
            AcademicRisk(
              id: 'risk_neglected_${s.id}',
              title: '${s.displayName} has not been studied recently',
              detail: 'Last studied $days days ago. Add a short study block to keep knowledge fresh.',
              level: AcademicRiskLevel.needsAttention,
              icon: Icons.book_outlined,
              actionLabel: 'Study Subject',
              subjectId: s.id,
            ),
          );
        }
      }
    }

    return risks;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. GOAL INTELLIGENCE
  // ══════════════════════════════════════════════════════════════════════════

  /// Assesses user goal progress and calculates recommended workload.
  static GoalIntelligenceSummary? assessGoalIntelligence({
    required GoalController goalController,
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
    DateTime? referenceTime,
  }) {
    final personalGoal = goalController.personalGoal;
    final weeklyStudyTarget = goalController.weeklyStudyTarget;
    final weeklyTaskTarget = goalController.weeklyTaskTarget;

    if (personalGoal.isEmpty && weeklyStudyTarget.inMinutes == 0 && weeklyTaskTarget == 0) {
      return null;
    }

    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    // Calculate weekly study minutes
    final weekSessions = sessions.where((s) =>
        s.isCompleted &&
        !DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day).isBefore(weekStart)).toList();

    int studyMins = 0;
    for (final s in weekSessions) {
      studyMins += s.durationSec ~/ 60;
    }

    // Calculate completed tasks this week
    final completedTasksThisWeek = tasks.where((t) =>
        t.isCompleted &&
        t.completedAt != null &&
        !DateTime(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day).isBefore(weekStart)).length;

    final targetStudyMins = weeklyStudyTarget.inMinutes > 0 ? weeklyStudyTarget.inMinutes : 600;
    final targetTaskCount = weeklyTaskTarget > 0 ? weeklyTaskTarget : 10;

    final studyFraction = (studyMins / targetStudyMins).clamp(0.0, 1.0);
    final taskFraction = (completedTasksThisWeek / targetTaskCount).clamp(0.0, 1.0);

    final remainingStudyMins = math.max(0, targetStudyMins - studyMins);
    final daysRemainingInWeek = math.max(1, 8 - today.weekday);
    final recommendedDailyMinutes = (remainingStudyMins / daysRemainingInWeek).round();

    final expectedFractionByDay = today.weekday / 7.0;
    final isFallingBehind = studyFraction < (expectedFractionByDay - 0.20);

    final linkedTasks = tasks.where((t) => t.goalId != null).toList();

    return GoalIntelligenceSummary(
      personalGoal: personalGoal,
      weeklyStudyTargetMinutes: targetStudyMins,
      weeklyStudyActualMinutes: studyMins,
      studyProgressFraction: studyFraction,
      weeklyTaskTarget: targetTaskCount,
      weeklyTaskActual: completedTasksThisWeek,
      taskProgressFraction: taskFraction,
      recommendedMinutesThisWeek: recommendedDailyMinutes,
      linkedTasks: linkedTasks,
      isFallingBehind: isFallingBehind,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. AUTOPILOT PLAN GENERATION & SAFETY
  // ══════════════════════════════════════════════════════════════════════════

  /// Generates a safe autopilot plan preview for a given budget.
  static AutopilotPlanPreview generateAutopilotPlan({
    required DateTime targetDay,
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<PlanningBlock> blocks = const [],
    int availableBudgetMinutes = 180,
    AutopilotMode mode = AutopilotMode.suggest,
    DateTime? baseStartTime,
  }) {
    final planResult = PlanningEngine.generateDailyPlan(
      targetDay,
      tasks: tasks,
      subjects: subjects,
      exams: exams,
      blocks: blocks,
      availableBudgetMinutes: availableBudgetMinutes,
      baseStartTime: baseStartTime,
    );

    // Auto-apply is only permitted when in full AUTOPILOT mode and the plan does not exceed the budget
    final canAutoApply = (mode == AutopilotMode.autopilot) && !planResult.isOverloaded;

    String summary;
    if (planResult.items.isEmpty) {
      summary = 'All caught up! No sessions needed for ${targetDay.day}/${targetDay.month}.';
    } else {
      summary = 'Autopilot prepared ${planResult.items.length} sessions totaling ${planResult.totalPlannedMinutes}m in your ${availableBudgetMinutes}m budget.';
    }

    return AutopilotPlanPreview(
      availableBudgetMinutes: availableBudgetMinutes,
      allocatedStudyMinutes: planResult.totalPlannedMinutes,
      items: planResult.items,
      isOverloaded: planResult.isOverloaded,
      overloadMinutes: planResult.overloadMinutes,
      summary: summary,
      mode: mode,
      canAutoApply: canAutoApply,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. "I HAVE 30 MINUTES" FAST BURST
  // ══════════════════════════════════════════════════════════════════════════

  /// Selects the single best 30-minute academic action.
  static StudentOSAction generateThirtyMinuteBurst({
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<AcademicResource> resources = const [],
    DateTime? referenceTime,
  }) {
    return determineWhatShouldIDoNow(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      resources: resources,
      maxAvailableMinutes: 30,
      referenceTime: referenceTime,
    );
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
