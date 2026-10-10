import 'package:flutter/foundation.dart';

enum AssistantIntentType {
  unknown('Unknown'),
  greeting('Greeting'),
  help('Help'),
  whatShouldIDo('What Should I Do'),
  whatShouldIStudy('What Should I Study'),
  whatShouldIRevise('What Should I Revise'),
  startMyDay('Start My Day'),
  continueMyDay('Continue My Day'),
  planTime('Plan Time'),
  availableTime('Available Time'),
  startFocus('Start Focus'),
  studySubject('Study Subject'),
  studyTopic('Study Topic'),
  reviseTopic('Revise Topic'),
  focusSubject('Focus Subject'),
  focusTopic('Focus Topic'),
  showTasks('Show Tasks'),
  startTask('Start Task'),
  completeTask('Complete Task'),
  showTodayPlan('Show Today Plan'),
  showExams('Show Exams'),
  showGoals('Show Goals'),
  showProgress('Show Progress'),
  showWeakAreas('Show Weak Areas'),
  showOverdue('Show Overdue'),
  reschedule('Reschedule'),
  recoverMissedSession('Recover Missed Session'),
  rebalanceDay('Rebalance Day'),
  practiceTopic('Practice Topic'),
  practiceWeakest('Practice Weakest'),
  showPracticeHistory('Show Practice History'),
  showScheduleToday('Show Today Schedule'),
  showScheduleTomorrow('Show Tomorrow Schedule'),
  showWeekSchedule('Show Week Schedule'),
  showNextClass('Show Next Class'),
  checkFreeTime('Check Free Time'),
  showScheduleConflicts('Show Schedule Conflicts'),
  showBusiestDay('Show Busiest Day'),
  showNotes('Show Notes'),
  searchNotes('Search Notes'),
  openNote('Open Note'),
  showPinnedNotes('Show Pinned Notes'),
  showRecentNotes('Show Recent Notes'),
  createNote('Create Note'),
  changeCourse('Change Course'),
  scheduleTopic('Schedule Topic'),
  stopFocus('Stop Focus'),
  showCompleted('Show Completed'),
  showPriorities('Show Priorities'),
  changeStudyTime('Change Study Time'),
  showStudentLife('Show Student Life'),
  showSleepSummary('Show Sleep Summary'),
  startWindDown('Start Wind Down'),
  openSleepSchedule('Open Sleep Schedule'),
  updateSleepSchedule('Update Sleep Schedule'),
  createTask('Create Task'),
  prioritizeTask('Prioritize Task'),
  rescheduleTask('Reschedule Task'),
  breakTask('Break Task'),
  catchUp('Catch Up'),
  showRewards('Show Rewards'),
  examPlan('Exam Plan'),
  revisionPlan('Revision Plan'),
  refinePlan('Refine Plan'),
  morningBriefing('Morning Briefing'),
  eveningReview('Evening Review'),
  prepareTomorrow('Prepare Tomorrow'),
  updateExamDate('Update Exam Date');

  const AssistantIntentType(this.label);
  final String label;
}

@immutable
class StudentAssistantIntent {
  const StudentAssistantIntent({
    required this.rawText,
    required this.intentType,
    this.confidence = 1.0,
    this.availableMinutes,
    this.durationMinutes,
    this.subjectId,
    this.subjectName,
    this.chapterId,
    this.topicId,
    this.topicName,
    this.taskId,
    this.taskName,
    this.examId,
    this.noteId,
    this.noteTitle,
    this.searchQuery,
    this.targetDate,
    this.requestedAction,
    this.bedtimeMinutes,
    this.wakeMinutes,
    this.taskPriority,
    this.subtaskCount,
    this.eveningCutoffMinutes,
    this.refineOp,
    this.refineIndex,
    this.overdueOnly = false,
    this.refersToPendingAction = false,
    this.requiresConfirmation = false,
    this.clarificationRequired = false,
    this.clarificationQuestion,
    this.clarificationChoices = const [],
  });

  final String rawText;
  final AssistantIntentType intentType;
  final double confidence;
  final int? availableMinutes;
  final int? durationMinutes;
  final String? subjectId;
  final String? subjectName;
  final String? chapterId;
  final String? topicId;
  final String? topicName;
  final String? taskId;
  final String? taskName;
  final String? examId;
  final String? noteId;
  final String? noteTitle;
  final String? searchQuery;
  final DateTime? targetDate;
  final String? requestedAction;

  /// Proposed bedtime / wake time in minutes-since-midnight for
  /// [AssistantIntentType.updateSleepSchedule]. Parsed from phrases like
  /// "set sleep 11pm to 7am".
  final int? bedtimeMinutes;
  final int? wakeMinutes;

  /// Requested priority name for [AssistantIntentType.prioritizeTask]
  /// ('low', 'medium', 'high', 'critical').
  final String? taskPriority;

  /// Requested part count for [AssistantIntentType.breakTask].
  final int? subtaskCount;

  /// "Don't schedule after X" cutoff, minutes-since-midnight.
  final int? eveningCutoffMinutes;

  /// Proposal refinement op ('remove' | 'moveFirst') with item index.
  final String? refineOp;
  final int? refineIndex;

  /// True when the user asked specifically for overdue work only.
  final bool overdueOnly;

  /// True when the user replied to a pending action with a bare reference
  /// such as "the first one" or "45 minutes". Resolved by the controller
  /// against ephemeral conversation context.
  final bool refersToPendingAction;
  final bool requiresConfirmation;
  final bool clarificationRequired;
  final String? clarificationQuestion;
  final List<String> clarificationChoices;

  bool get isAmbiguous => clarificationRequired;
  bool get isKnown => intentType != AssistantIntentType.unknown;

  StudentAssistantIntent copyWith({
    String? rawText,
    AssistantIntentType? intentType,
    double? confidence,
    int? availableMinutes,
    int? durationMinutes,
    String? subjectId,
    String? subjectName,
    String? chapterId,
    String? topicId,
    String? topicName,
    String? taskId,
    String? taskName,
    String? examId,
    String? noteId,
    String? noteTitle,
    String? searchQuery,
    DateTime? targetDate,
    String? requestedAction,
    int? bedtimeMinutes,
    int? wakeMinutes,
    String? taskPriority,
    int? subtaskCount,
    int? eveningCutoffMinutes,
    String? refineOp,
    int? refineIndex,
    bool? overdueOnly,
    bool? refersToPendingAction,
    bool? requiresConfirmation,
    bool? clarificationRequired,
    String? clarificationQuestion,
    List<String>? clarificationChoices,
  }) {
    return StudentAssistantIntent(
      rawText: rawText ?? this.rawText,
      intentType: intentType ?? this.intentType,
      confidence: confidence ?? this.confidence,
      availableMinutes: availableMinutes ?? this.availableMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      chapterId: chapterId ?? this.chapterId,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      examId: examId ?? this.examId,
      noteId: noteId ?? this.noteId,
      noteTitle: noteTitle ?? this.noteTitle,
      searchQuery: searchQuery ?? this.searchQuery,
      targetDate: targetDate ?? this.targetDate,
      requestedAction: requestedAction ?? this.requestedAction,
      bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      taskPriority: taskPriority ?? this.taskPriority,
      subtaskCount: subtaskCount ?? this.subtaskCount,
      eveningCutoffMinutes:
          eveningCutoffMinutes ?? this.eveningCutoffMinutes,
      refineOp: refineOp ?? this.refineOp,
      refineIndex: refineIndex ?? this.refineIndex,
      overdueOnly: overdueOnly ?? this.overdueOnly,
      refersToPendingAction:
          refersToPendingAction ?? this.refersToPendingAction,
      requiresConfirmation:
          requiresConfirmation ?? this.requiresConfirmation,
      clarificationRequired:
          clarificationRequired ?? this.clarificationRequired,
      clarificationQuestion:
          clarificationQuestion ?? this.clarificationQuestion,
      clarificationChoices:
          clarificationChoices ?? this.clarificationChoices,
    );
  }

  @override
  String toString() =>
      'StudentAssistantIntent(type: ${intentType.name}, availableMins: $availableMinutes, subject: $subjectName, topic: $topicName, clarify: $clarificationRequired)';
}
