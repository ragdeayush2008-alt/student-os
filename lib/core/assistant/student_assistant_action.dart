import 'package:flutter/foundation.dart';

enum AssistantActionType {
  none('None'),
  openHome('Open Home'),
  openPlan('Open Plan'),
  openStudy('Open Study'),
  openFocus('Open Focus'),
  openTasks('Open Tasks'),
  openExams('Open Exams'),
  openGoals('Open Goals'),
  openProgress('Open Progress'),
  openRevision('Open Revision'),
  startFocus('Start Focus'),
  startPlanningBlock('Start Block'),
  startTopic('Start Topic'),
  startTask('Start Task'),
  startRevision('Start Revision'),
  startPlan('Start Plan'),
  applyPlan('Apply Plan'),
  reschedule('Reschedule'),
  recover('Recover'),
  rebalance('Rebalance'),
  completeTask('Complete Task'),
  openPractice('Open Practice'),
  openRewards('Open Rewards'),
  startPractice('Start Practice'),
  openCalendar('Open Calendar'),
  resolveConflict('Resolve Conflict'),
  openKnowledge('Open Knowledge'),
  openNote('Open Note'),
  createNote('Create Note'),
  searchNotes('Search Notes'),
  openCourseSelection('Open Course Selection'),
  scheduleTopic('Schedule Topic'),
  stopFocus('Stop Focus'),
  openStudentLife('Open Student Life'),
  startWindDown('Start Wind Down'),
  openSleepSchedule('Open Sleep Schedule'),
  updateSleepSchedule('Update Sleep Schedule'),
  createTask('Create Task'),
  rescheduleTask('Reschedule Task'),
  prioritizeTask('Prioritize Task'),
  breakTask('Break Task'),
  updateExamDate('Update Exam Date');

  const AssistantActionType(this.label);
  final String label;

  /// Mutation risk classification for the confirmation system (Phase 4 §19).
  AssistantActionClass get actionClass {
    switch (this) {
      // Pure reads / navigation — no persistent state changes.
      case AssistantActionType.none:
      case AssistantActionType.openHome:
      case AssistantActionType.openPlan:
      case AssistantActionType.openStudy:
      case AssistantActionType.openFocus:
      case AssistantActionType.openTasks:
      case AssistantActionType.openExams:
      case AssistantActionType.openGoals:
      case AssistantActionType.openProgress:
      case AssistantActionType.openRevision:
      case AssistantActionType.openPractice:
      case AssistantActionType.openRewards:
      case AssistantActionType.openCalendar:
      case AssistantActionType.openKnowledge:
      case AssistantActionType.openNote:
      case AssistantActionType.searchNotes:
      case AssistantActionType.openCourseSelection:
      case AssistantActionType.openStudentLife:
      case AssistantActionType.openSleepSchedule:
        return AssistantActionClass.read;

      // Session starts are reversible navigation into an existing flow.
      case AssistantActionType.startFocus:
      case AssistantActionType.startPlanningBlock:
      case AssistantActionType.startTopic:
      case AssistantActionType.startTask:
      case AssistantActionType.startRevision:
      case AssistantActionType.startPractice:
      case AssistantActionType.startWindDown:
        return AssistantActionClass.safeNavigation;

      case AssistantActionType.stopFocus:
        return AssistantActionClass.mutating;

      // Changes that write planning/task/academic state.
      case AssistantActionType.scheduleTopic:
      case AssistantActionType.startPlan:
      case AssistantActionType.applyPlan:
      case AssistantActionType.reschedule:
      case AssistantActionType.recover:
      case AssistantActionType.rebalance:
      case AssistantActionType.completeTask:
      case AssistantActionType.resolveConflict:
      case AssistantActionType.createNote:
      case AssistantActionType.updateSleepSchedule:
      case AssistantActionType.createTask:
      case AssistantActionType.rescheduleTask:
      case AssistantActionType.prioritizeTask:
      case AssistantActionType.breakTask:
      case AssistantActionType.updateExamDate:
        return AssistantActionClass.mutating;
    }
  }

  bool get isReadOnly => actionClass == AssistantActionClass.read;
  bool get isSafeNavigation => actionClass == AssistantActionClass.safeNavigation;
  bool get requiresPreview => actionClass == AssistantActionClass.mutating ||
      actionClass == AssistantActionClass.highImpact;
}

/// Confirmation tier for an Assistant action (Phase 4 §19).
enum AssistantActionClass {
  read('Read'),
  safeNavigation('Safe Navigation'),
  mutating('Mutating'),
  highImpact('High Impact');

  const AssistantActionClass(this.label);
  final String label;

  /// P3 automation level: what the Assistant may do unprompted.
  /// L1 informs, L2 prepares (surfaced), L3 always needs confirmation.
  /// Proactive triggers only ever lead to L1/L2 outcomes.
  AssistantAutomationLevel get automationLevel => switch (this) {
        AssistantActionClass.read => AssistantAutomationLevel.information,
        AssistantActionClass.safeNavigation =>
          AssistantAutomationLevel.preparation,
        AssistantActionClass.mutating ||
        AssistantActionClass.highImpact =>
          AssistantAutomationLevel.consequential,
      };
}

/// P3 automation safety levels (§22).
enum AssistantAutomationLevel {
  information('Information — automatic summaries and recommendations'),
  preparation(
      'Preparation — drafts surfaced for review, never applied silently'),
  consequential('Consequential — requires explicit confirmation');

  const AssistantAutomationLevel(this.label);
  final String label;
}

@immutable
class StudentAssistantAction {
  const StudentAssistantAction({
    required this.id,
    required this.type,
    required this.label,
    this.isPrimary = true,
    this.subjectId,
    this.subjectName,
    this.chapterId,
    this.topicId,
    this.topicTitle,
    this.taskId,
    this.taskTitle,
    this.examId,
    this.examTitle,
    this.planningBlockId,
    this.noteId,
    this.noteTitle,
    this.searchQuery,
    this.duration,
    this.targetDate,
    this.requiresConfirmation = false,
    this.sleepBedtimeMinutes,
    this.sleepWakeMinutes,
    this.taskPriority,
    this.subtaskCount,
  });

  final String id;
  final AssistantActionType type;
  final String label;
  final bool isPrimary;
  final String? subjectId;
  final String? subjectName;
  final String? chapterId;
  final String? topicId;
  final String? topicTitle;
  final String? taskId;
  final String? taskTitle;
  final String? examId;
  final String? examTitle;
  final String? planningBlockId;
  final String? noteId;
  final String? noteTitle;
  final String? searchQuery;
  final Duration? duration;
  final DateTime? targetDate;
  final bool requiresConfirmation;

  /// Proposed sleep window for [AssistantActionType.updateSleepSchedule],
  /// in minutes-since-midnight. Applied only after explicit confirmation.
  final int? sleepBedtimeMinutes;
  final int? sleepWakeMinutes;

  /// Requested priority name for [AssistantActionType.prioritizeTask].
  final String? taskPriority;

  /// Requested part count for [AssistantActionType.breakTask].
  final int? subtaskCount;

  bool get isMutating =>
      type.actionClass == AssistantActionClass.mutating ||
      type.actionClass == AssistantActionClass.highImpact;

  AssistantActionClass get actionClass => type.actionClass;
  bool get isReadOnly => type.isReadOnly;
  bool get isSafeNavigation => type.isSafeNavigation;

  StudentAssistantAction copyWith({
    String? id,
    AssistantActionType? type,
    String? label,
    bool? isPrimary,
    String? subjectId,
    String? subjectName,
    String? chapterId,
    String? topicId,
    String? topicTitle,
    String? taskId,
    String? taskTitle,
    String? examId,
    String? examTitle,
    String? planningBlockId,
    String? noteId,
    String? noteTitle,
    String? searchQuery,
    Duration? duration,
    DateTime? targetDate,
    bool? requiresConfirmation,
    int? sleepBedtimeMinutes,
    int? sleepWakeMinutes,
    String? taskPriority,
    int? subtaskCount,
  }) {
    return StudentAssistantAction(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      isPrimary: isPrimary ?? this.isPrimary,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      chapterId: chapterId ?? this.chapterId,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      examId: examId ?? this.examId,
      examTitle: examTitle ?? this.examTitle,
      planningBlockId: planningBlockId ?? this.planningBlockId,
      noteId: noteId ?? this.noteId,
      noteTitle: noteTitle ?? this.noteTitle,
      searchQuery: searchQuery ?? this.searchQuery,
      duration: duration ?? this.duration,
      targetDate: targetDate ?? this.targetDate,
      requiresConfirmation:
          requiresConfirmation ?? this.requiresConfirmation,
      sleepBedtimeMinutes: sleepBedtimeMinutes ?? this.sleepBedtimeMinutes,
      sleepWakeMinutes: sleepWakeMinutes ?? this.sleepWakeMinutes,
      taskPriority: taskPriority ?? this.taskPriority,
      subtaskCount: subtaskCount ?? this.subtaskCount,
    );
  }

  @override
  String toString() =>
      'StudentAssistantAction(type: ${type.name}, label: $label, duration: $duration)';
}
