import '../../data/models/xp_event.dart';
import '../../data/models/task.dart';

/// Centralized XP calculation engine with deterministic, configurable rules.
///
/// All XP amounts are defined here rather than scattered throughout controllers.
/// This makes the progression system transparent, testable, and easy to balance.
///
/// Design principles:
/// - XP represents meaningful productivity, not arbitrary interaction
/// - Amounts scale with effort/priority but avoid massive inflation
/// - Rules are simple and explainable to students
abstract final class XpEngine {
  // ─── Task completion XP ──────────────────────────────────────────────

  /// Base XP for completing a normal task.
  static const int taskBaseXp = 10;

  /// Additional XP for high-priority tasks.
  static const int taskHighPriorityBonus = 10;

  /// Additional XP for critical-priority tasks.
  static const int taskCriticalPriorityBonus = 20;

  /// Calculates XP for completing a task.
  static int xpForTaskCompletion(StudentTask task) {
    int xp = taskBaseXp;

    // Priority bonus
    if (task.priority == TaskPriority.high) {
      xp += taskHighPriorityBonus;
    } else if (task.priority == TaskPriority.critical) {
      xp += taskCriticalPriorityBonus;
    }

    return xp;
  }

  /// Creates a deterministic event ID for a task completion.
  ///
  /// Uses task ID + completion timestamp to ensure uniqueness while
  /// preventing duplicate rewards for the same completion event.
  static String taskCompletionEventId(String taskId, DateTime? completedAt) {
    final timestamp = completedAt?.millisecondsSinceEpoch ?? 0;
    return 'task_complete_${taskId}_$timestamp';
  }

  /// Creates an XP event for completing a task.
  static XpEvent createTaskCompletionEvent(StudentTask task) {
    final xp = xpForTaskCompletion(task);
    final priorityLabel =
        task.priority == TaskPriority.medium ||
            task.priority == TaskPriority.low
        ? ''
        : ' (${task.priority.label} priority)';

    return XpEvent(
      id: taskCompletionEventId(task.id, task.completedAt),
      type: XpEventType.taskCompleted,
      amount: xp,
      timestamp: task.completedAt ?? DateTime.now(),
      reason: 'Completed task: ${task.title}$priorityLabel',
      taskId: task.id,
      subjectId: task.subjectId,
    );
  }

  // ─── Study session XP ────────────────────────────────────────────────

  /// Minimum study duration (in seconds) to qualify for XP.
  static const int minStudyDurationSeconds = 300; // 5 minutes

  /// Base XP for a meaningful study session.
  static const int studySessionBaseXp = 15;

  /// Additional XP per 30 minutes of focused study.
  static const int studyXpPer30Min = 5;

  /// Maximum XP from a single study session (prevents farming).
  static const int studySessionMaxXp = 50;

  /// Calculates XP for completing a study session.
  static int xpForStudySession(int durationSeconds) {
    if (durationSeconds < minStudyDurationSeconds) return 0;

    int xp = studySessionBaseXp;

    // Bonus for longer sessions (per 30-minute block)
    final halfHours = durationSeconds ~/ 1800;
    xp += halfHours * studyXpPer30Min;

    return xp.clamp(0, studySessionMaxXp);
  }

  /// Creates a deterministic event ID for a study session.
  static String studySessionEventId(String sessionId, DateTime startedAt) {
    final timestamp = startedAt.millisecondsSinceEpoch;
    return 'study_complete_${sessionId}_$timestamp';
  }

  /// Creates an XP event for completing a study session.
  static XpEvent createStudySessionEvent({
    required String sessionId,
    required int durationSeconds,
    required DateTime startedAt,
    String? subjectId,
  }) {
    final xp = xpForStudySession(durationSeconds);
    if (xp == 0) {
      throw ArgumentError('Study session too short for XP');
    }

    final minutes = (durationSeconds / 60).round();
    return XpEvent(
      id: studySessionEventId(sessionId, startedAt),
      type: XpEventType.studySessionCompleted,
      amount: xp,
      timestamp: startedAt.add(Duration(seconds: durationSeconds)),
      reason: 'Completed ${minutes}min study session',
      subjectId: subjectId,
      metadata: {'durationSeconds': durationSeconds},
    );
  }

  // ─── Syllabus completion XP ──────────────────────────────────────────

  /// XP for completing a syllabus topic.
  static const int syllabusTopicXp = 25;

  /// Creates a deterministic event ID for syllabus completion.
  static String syllabusCompletionEventId(String examId, int topicIndex) {
    return 'syllabus_${examId}_topic_$topicIndex';
  }

  /// Creates an XP event for completing a syllabus topic.
  static XpEvent createSyllabusCompletionEvent({
    required String examId,
    required int topicIndex,
    required String topicTitle,
    required String examTitle,
  }) {
    return XpEvent(
      id: syllabusCompletionEventId(examId, topicIndex),
      type: XpEventType.syllabusTopicCompleted,
      amount: syllabusTopicXp,
      timestamp: DateTime.now(),
      reason: 'Completed topic: $topicTitle',
      examId: examId,
      metadata: {'examTitle': examTitle, 'topicIndex': topicIndex},
    );
  }

  // ─── Exam completion XP ──────────────────────────────────────────────

  /// XP for completing an exam.
  static const int examCompletionXp = 50;

  /// Creates a deterministic event ID for exam completion.
  static String examCompletionEventId(String examId) {
    return 'exam_complete_$examId';
  }

  /// Creates an XP event for completing an exam.
  static XpEvent createExamCompletionEvent({
    required String examId,
    required String examTitle,
  }) {
    return XpEvent(
      id: examCompletionEventId(examId),
      type: XpEventType.examCompleted,
      amount: examCompletionXp,
      timestamp: DateTime.now(),
      reason: 'Completed exam: $examTitle',
      examId: examId,
    );
  }

  // ─── Milestone XP ────────────────────────────────────────────────────

  /// XP for achieving weekly consistency milestone.
  static const int weeklyConsistencyXp = 30;

  /// XP for streak milestones (scales with streak length).
  static int streakMilestoneXp(int streakDays) {
    if (streakDays < 3) return 0;
    if (streakDays == 3) return 20;
    if (streakDays == 7) return 40;
    if (streakDays == 14) return 60;
    if (streakDays == 30) return 100;
    return 0; // Only award at specific milestones
  }

  /// Creates a deterministic event ID for a streak milestone.
  static String streakMilestoneEventId(int streakDays) {
    return 'streak_milestone_${streakDays}days';
  }

  /// Creates an XP event for a streak milestone.
  static XpEvent createStreakMilestoneEvent(int streakDays) {
    final xp = streakMilestoneXp(streakDays);
    if (xp == 0) {
      throw ArgumentError('No XP for streak of $streakDays days');
    }

    return XpEvent(
      id: streakMilestoneEventId(streakDays),
      type: XpEventType.streakMilestone,
      amount: xp,
      timestamp: DateTime.now(),
      reason: '$streakDays-day streak milestone reached',
      metadata: {'streakDays': streakDays},
    );
  }

  /// Creates a deterministic event ID for weekly consistency.
  static String weeklyConsistencyEventId(DateTime weekStart) {
    final key = weekStart.toIso8601String().substring(0, 10);
    return 'weekly_consistency_$key';
  }

  /// Creates an XP event for weekly consistency milestone.
  static XpEvent createWeeklyConsistencyEvent(DateTime weekStart) {
    return XpEvent(
      id: weeklyConsistencyEventId(weekStart),
      type: XpEventType.weeklyConsistency,
      amount: weeklyConsistencyXp,
      timestamp: DateTime.now(),
      reason: 'Consistent activity this week',
      metadata: {'weekStart': weekStart.toIso8601String()},
    );
  }
}
