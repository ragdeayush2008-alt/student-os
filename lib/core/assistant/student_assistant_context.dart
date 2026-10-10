import 'package:flutter/foundation.dart';

import '../../data/models/chapter.dart';
import '../../data/models/exam.dart';
import '../../data/models/study_session.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/topic.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/knowledge/academic_knowledge_controller.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/planning/models/planning_block.dart';
import '../../features/study/study_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/sleep/models/sleep_schedule.dart';
import '../../features/sleep/sleep_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../intelligence/academic_knowledge_engine.dart';
import '../services/course_catalog_service.dart';
import 'student_assistant_intent.dart';
import 'student_assistant_result.dart';

/// A read-only, student-friendly snapshot of the live Student OS state.
///
/// Phase 4 §4: the Assistant must answer using real context, but must never
/// expose raw controller objects or IDs. This snapshot converts authoritative
/// controller data into plain facts plus one concise [summaryLine].
@immutable
class AssistantContextSnapshot {
  const AssistantContextSnapshot({
    required this.now,
    this.courseName,
    this.hasActiveFocus = false,
    this.activeFocusObjective,
    this.activeFocusElapsedMinutes = 0,
    this.todayBlockCount = 0,
    this.todayPlannedMinutes = 0,
    this.todayCompletedCount = 0,
    this.nextBlockTitle,
    this.nextBlockMinutes,
    this.overdueTaskCount = 0,
    this.dayMinutesRemaining = 0,
    this.nearestExamTitle,
    this.daysToNearestExam,
    this.revisionDueCount = 0,
    this.weakTopicCount = 0,
    this.lastStudiedTopicTitle,
    this.lastStudiedAgoLabel,
    this.subjectCount = 0,
    this.topicCount = 0,
    this.hasSleepSchedule = false,
    this.sleepWindowLabel,
    this.sleepDurationLabel,
    this.sleepEnabled = true,
  });

  final DateTime now;
  final String? courseName;
  final bool hasActiveFocus;
  final String? activeFocusObjective;
  final int activeFocusElapsedMinutes;
  final int todayBlockCount;
  final int todayPlannedMinutes;
  final int todayCompletedCount;
  final String? nextBlockTitle;
  final int? nextBlockMinutes;
  final int overdueTaskCount;
  final int dayMinutesRemaining;
  final String? nearestExamTitle;
  final int? daysToNearestExam;
  final int revisionDueCount;
  final int weakTopicCount;
  final String? lastStudiedTopicTitle;
  final String? lastStudiedAgoLabel;
  final int subjectCount;
  final int topicCount;

  /// P1 Sleep context: the planned sleep window, when one exists and is
  /// enabled. Read from [SleepController]; never medical data.
  final bool hasSleepSchedule;
  final String? sleepWindowLabel;
  final String? sleepDurationLabel;
  final bool sleepEnabled;

  bool get hasCourse => subjectCount > 0;

  /// Builds a snapshot from the existing authoritative controllers.
  ///
  /// Every value is optional/zero-safe; a brand-new user produces a valid
  /// snapshot instead of throwing.
  factory AssistantContextSnapshot.capture({
    DateTime? referenceTime,
    List<Subject>? subjects,
    List<Chapter>? chapters,
    List<Topic>? topics,
    List<StudentTask>? tasks,
    List<StudentExam>? exams,
    List<StudySession>? sessions,
    List<PlanningBlock>? blocks,
    SleepSchedule? sleepSchedule,
  }) {
    final now = referenceTime ?? DateTime.now();
    final allSubjects = subjects ?? SubjectController.instance.activeSubjects;
    final allChapters = chapters ?? AcademicKnowledgeController.instance.chapters;
    final allTopics = topics ?? AcademicKnowledgeController.instance.topics;
    final allTasks = tasks ?? TaskController.instance.tasks;
    final allExams = exams ?? ExamController.instance.upcomingExams;
    final allSessions = sessions ?? StudyController.instance.sessions;
    final allBlocks = blocks ?? PlanningBlockController.instance.blocks;

    final fc = FocusController.instance;
    final active = fc.activeSession;

    final todayBlocks = allBlocks.where((b) => _isSameDay(b.startAt, now)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final plannedMinutes =
        todayBlocks.fold<int>(0, (sum, b) => sum + _blockMinutes(b));
    final completed = todayBlocks.where((b) {
      if (b.taskId == null) return false;
      final task = allTasks.where((t) => t.id == b.taskId).firstOrNull;
      return task?.isCompleted ?? false;
    }).length;

    final upcomingToday = todayBlocks
        .where((b) => b.startAt.isAfter(now) || _isLive(b, now))
        .toList();
    final next = upcomingToday.isNotEmpty ? upcomingToday.first : null;

    final overdue = allTasks
        .where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now))
        .length;

    final sortedExams = [...allExams]..sort((a, b) {
        final ad = a.examDateTime;
        final bd = b.examDateTime;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    final nearest = sortedExams.isNotEmpty ? sortedExams.first : null;

    int revisionDue = 0;
    int weak = 0;
    if (allTopics.isNotEmpty) {
      for (final t in allTopics) {
        final prog = AcademicKnowledgeEngine.assessTopicProgress(
          t,
          sessions: allSessions,
          referenceTime: now,
        );
        if (prog.isRevisionDue) revisionDue++;
        if (prog.status == TopicStatus.needsRevision) weak++;
      }
    }

    final completedSessions = allSessions
        .where((s) => s.isCompleted && s.topicId != null)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final lastSession = completedSessions.isNotEmpty ? completedSessions.first : null;
    String? lastTopicTitle;
    String? lastAgo;
    if (lastSession != null) {
      lastTopicTitle = allTopics
          .where((t) => t.id == lastSession.topicId)
          .firstOrNull
          ?.title;
      lastAgo = _relativeLabel(lastSession.startedAt, now);
    }

    final remaining = _minutesUntilDayEnd(now);

    final sleep = sleepSchedule ?? _readSleepSchedule();

    return AssistantContextSnapshot(
      now: now,
      courseName: _courseName(allSubjects),
      hasActiveFocus: fc.hasActiveSession,
      activeFocusObjective: active?.objective,
      activeFocusElapsedMinutes: active?.isActive == true
          ? now.difference(active!.startedAt).inMinutes.clamp(0, 24 * 60)
          : 0,
      todayBlockCount: todayBlocks.length,
      todayPlannedMinutes: plannedMinutes,
      todayCompletedCount: completed,
      nextBlockTitle: next == null ? null : _blockTitle(next),
      nextBlockMinutes: next == null ? null : _blockMinutes(next),
      overdueTaskCount: overdue,
      dayMinutesRemaining: remaining,
      nearestExamTitle: nearest?.title,
      daysToNearestExam: nearest?.daysUntilExam,
      revisionDueCount: revisionDue,
      weakTopicCount: weak,
      lastStudiedTopicTitle: lastTopicTitle,
      lastStudiedAgoLabel: lastAgo,
      subjectCount: allSubjects.isNotEmpty
          ? allSubjects.length
          : allChapters.map((c) => c.subjectId).toSet().length,
      topicCount: allTopics.length,
      hasSleepSchedule: sleep != null && sleep.enabled,
      sleepWindowLabel: sleep != null && sleep.enabled
          ? sleep.windowLabel
          : null,
      sleepDurationLabel: sleep != null && sleep.enabled
          ? sleep.durationLabel
          : null,
      sleepEnabled: sleep?.enabled ?? false,
    );
  }

  /// Reads the planned sleep window without ever failing capture: an
  /// unloaded controller, a missing schedule, or corrupt data all degrade
  /// to null (no schedule) instead of throwing.
  static SleepSchedule? _readSleepSchedule() {
    try {
      final schedule = SleepController.instance.schedule;
      if (schedule == null || !schedule.enabled) return null;
      return schedule;
    } catch (_) {
      return null;
    }
  }

  /// One concise, non-technical line describing what the Assistant looked at.
  String get summaryLine {
    final parts = <String>[];
    if (hasActiveFocus) {
      parts.add('Focusing on ${activeFocusObjective ?? 'a session'}');
    } else if (todayBlockCount > 0) {
      parts.add(
          "Today: $todayBlockCount block${todayBlockCount == 1 ? '' : 's'} · ${_fmt(todayPlannedMinutes)}");
    } else {
      parts.add('No plan yet today');
    }
    if (overdueTaskCount > 0) parts.add('$overdueTaskCount overdue');
    if (hasSleepSchedule && sleepWindowLabel != null) {
      parts.add('Sleep $sleepWindowLabel');
    }
    if (nearestExamTitle != null && daysToNearestExam != null) {
      parts.add('$nearestExamTitle in ${daysToNearestExam}d');
    }
    if (revisionDueCount > 0) parts.add('$revisionDueCount to revise');
    return parts.join(' · ');
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isLive(PlanningBlock b, DateTime now) =>
      !b.startAt.isAfter(now) && b.endAt.isAfter(now);

  static int _blockMinutes(PlanningBlock b) {
    final diff = b.endAt.difference(b.startAt).inMinutes;
    return diff > 0 ? diff : 0;
  }

  static String _blockTitle(PlanningBlock b) {
    if (b.customTitle != null && b.customTitle!.isNotEmpty) {
      return b.customTitle!;
    }
    if (b.isTaskBlock) return 'Task block';
    if (b.isTopicBlock) return 'Study block';
    if (b.isSubjectBlock) return 'Study block';
    return 'Scheduled session';
  }

  static int _minutesUntilDayEnd(DateTime now) {
    final end = DateTime(now.year, now.month, now.day, 21);
    final diff = end.difference(now).inMinutes;
    return diff > 0 ? diff : 0;
  }

  static String? _courseName(List<Subject> subjects) {
    if (subjects.isEmpty) return null;
    try {
      final title = CourseCatalogService.instance.activeCourseSelection?.programTitle;
      if (title != null && title.isNotEmpty) return title;
    } catch (_) {
      // Course catalog unavailable (e.g. unit test without profile).
    }
    return null;
  }

  static String _relativeLabel(DateTime then, DateTime now) {
    final diff = now.difference(then);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  static String _fmt(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

/// Ephemeral, user-scoped conversation memory for the current Assistant
/// interaction only (Phase 4 §18).
///
/// It is never persisted as academic data. [StudentAssistantController]
/// clears it on logout/user switch and after a confirmed mutation.
@immutable
class AssistantConversationContext {
  const AssistantConversationContext({
    this.turn = 0,
    this.lastQuery,
    this.lastSteps = const [],
    this.pendingIntent,
    this.pendingStep,
  });

  final int turn;
  final String? lastQuery;

  /// The structured rows shown in the previous card, in display order, so
  /// "the first one" / "the second one" can be resolved.
  final List<AssistantResultStep> lastSteps;

  /// An intent that is awaiting a clarifying duration ("…45 minutes").
  final StudentAssistantIntent? pendingIntent;

  /// A single step awaiting a follow-up action ("Plan it" → duration).
  final AssistantResultStep? pendingStep;

  bool get isEmpty => lastQuery == null && lastSteps.isEmpty;

  AssistantConversationContext nextTurn({
    required String query,
    required List<AssistantResultStep> steps,
  }) {
    return AssistantConversationContext(
      turn: turn + 1,
      lastQuery: query,
      lastSteps: steps,
      pendingIntent: null,
      pendingStep: null,
    );
  }

  AssistantConversationContext withPendingDuration(StudentAssistantIntent intent) {
    return AssistantConversationContext(
      turn: turn + 1,
      lastQuery: lastQuery,
      lastSteps: lastSteps,
      pendingIntent: intent,
      pendingStep: pendingStep,
    );
  }

  static const empty = AssistantConversationContext();
}
