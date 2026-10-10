import 'package:flutter/foundation.dart';

import '../../data/models/academic_calendar_event.dart';
import '../../data/models/exam.dart';
import '../../data/models/revision_record.dart';
import '../../data/models/study_session.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/topic.dart';
import '../../features/calendar/academic_schedule_controller.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/goals/goal_controller.dart';
import '../../features/knowledge/academic_knowledge_controller.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/planning/models/planning_block.dart';
import '../../features/preferences/user_preferences_controller.dart';
import '../../features/study/study_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/revision/revision_controller.dart';
import '../../features/knowledge/topic_practice_controller.dart';
import 'academic_intelligence_engine.dart';
import 'academic_knowledge_engine.dart';
import 'autopilot_engine.dart';
import 'student_os_intelligence_engine.dart';

/// Authoritative derived Student State snapshot — not a second database.
/// Computed deterministically from raw controllers, cached in
/// [AcademicIntelligenceController], refreshed on mutations.
@immutable
class StudentStateSnapshot {
  const StudentStateSnapshot({
    required this.referenceTime,
    required this.currentDate,
    required this.availableMinutes,
    required this.remainingFreeTimeMinutes,
    required this.currentSchedulePosition,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.remainingMinutes,
    required this.missedMinutes,
    required this.overloadState,
    required this.overloadMinutes,
    required this.subjects,
    required this.incompleteSyllabusCount,
    required this.topicsNeedingStudy,
    required this.topicsNeedingRevision,
    required this.weakTopics,
    required this.recentStudyMinutes,
    required this.nearestExam,
    required this.daysUntilNearestExam,
    required this.unfinishedExamSyllabusCount,
    required this.revisionPressure,
    required this.practicePressure,
    required this.overdueTasks,
    required this.dueSoonTasks,
    required this.highPriorityTasks,
    required this.estimatedEffortMinutes,
    required this.activeGoals,
    required this.goalLinkedTasks,
    required this.activeFocus,
    required this.currentStreak,
    required this.missedSessions,
    required this.recoveryOpportunities,
    required this.recentPracticeAccuracy,
    required this.unpracticedTopicsCount,
    required this.dueRevisionCount,
    required this.failedRecallCount,
    required this.overdueRevisionCount,
    required this.preferredFocusDuration,
    required this.autopilotMode,
    required this.isWorkloadHeavy,
    required this.examSummaries,
    required this.subjectHealths,
  });

  // TIME
  final DateTime referenceTime;
  final DateTime currentDate;
  final int availableMinutes;
  final int remainingFreeTimeMinutes;
  final String currentSchedulePosition; // e.g. "Between 09:00-10:30 blocked" or "Free"

  // PLANNING
  final int plannedMinutes;
  final int completedMinutes;
  final int remainingMinutes;
  final int missedMinutes;
  final WorkloadState overloadState;
  final int overloadMinutes;

  // ACADEMIC
  final List<Subject> subjects;
  final int incompleteSyllabusCount;
  final List<TopicProgress> topicsNeedingStudy;
  final List<TopicProgress> topicsNeedingRevision;
  final List<TopicProgress> weakTopics;
  final int recentStudyMinutes;

  // EXAMS
  final StudentExam? nearestExam;
  final int? daysUntilNearestExam;
  final int unfinishedExamSyllabusCount;
  final ExamPressureLevel revisionPressure;
  final double practicePressure;

  // TASKS
  final List<StudentTask> overdueTasks;
  final List<StudentTask> dueSoonTasks;
  final List<StudentTask> highPriorityTasks;
  final int estimatedEffortMinutes;

  // GOALS
  final String activeGoals;
  final List<StudentTask> goalLinkedTasks;

  // FOCUS
  final dynamic activeFocus;
  final int currentStreak;

  // RECOVERY
  final List<dynamic> missedSessions;
  final List<dynamic> recoveryOpportunities;

  // PRACTICE
  final int? recentPracticeAccuracy;
  final int unpracticedTopicsCount;

  // REVISION
  final int dueRevisionCount;
  final int failedRecallCount;
  final int overdueRevisionCount;

  // PREFERENCES
  final Duration preferredFocusDuration;
  final AutopilotMode autopilotMode;

  final bool isWorkloadHeavy;
  final List<dynamic> examSummaries;
  final List<dynamic> subjectHealths;

  bool get hasActiveFocus => activeFocus != null;
  bool get isOverloaded => overloadState == WorkloadState.overloaded;
  bool get hasMissedWork => missedSessions.isNotEmpty;
  bool get needsRecovery => missedSessions.isNotEmpty;
  bool get hasWeakTopics => weakTopics.isNotEmpty;
  bool get hasDueRevision => dueRevisionCount > 0;

  /// Factory deriving snapshot from current controllers — pure, deterministic.
  factory StudentStateSnapshot.fromControllers({
    DateTime? referenceTime,
    int? availableMinutes,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final avail = availableMinutes ?? 180;

    // Planning derived
    final blocks = PlanningBlockController.instance.blocks;
    final dayBlocks = blocks.where((b) => DateTime(b.startAt.year, b.startAt.month, b.startAt.day) == today).toList();
    int plannedMins = 0;
    for (final b in dayBlocks) plannedMins += b.endAt.difference(b.startAt).inMinutes;

    final sessions = StudyController.instance.sessions;
    final todaySessions = sessions.where((s) => s.isCompleted && DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day) == today).toList();
    int completedMins = 0;
    for (final s in todaySessions) completedMins += s.durationSec ~/ 60;

    final remainingMins = (plannedMins - completedMins).clamp(0, 9999);
    final dailyState = StudentOSIntelligenceEngine.computeDailyStudentState(
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: sessions,
      tasks: TaskController.instance.tasks,
      blocks: blocks,
      availableBudgetMinutes: avail,
      hasActiveFocus: FocusController.instance.hasActiveSession,
    );
    final autopilotState = StudentOSAutopilotEngine.computeAutopilotDayState(
      targetDay: now,
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.upcomingExams,
      sessions: sessions,
      tasks: TaskController.instance.tasks,
      blocks: blocks,
      availableBudgetMinutes: avail,
      mode: UserPreferencesController.instance.autopilotMode,
      referenceTime: now,
    );

    final missed = autopilotState.recoverySessions;
    int missedMins = 0;
    for (final m in missed) missedMins += m.durationMinutes;

    // Fixed commitments remaining free time via AcademicScheduleController
    int remainingFree = 0;
    String schedulePos = 'Free';
    try {
      final availCalc = AcademicScheduleController.instance.calculateAvailability(today);
      remainingFree = availCalc.freeMinutes;
      final nowMinutes = now.hour * 60 + now.minute;
      final dayEvents = AcademicScheduleController.instance.eventsForDay(today);
      for (final e in dayEvents) {
        final startM = e.startAt.hour * 60 + e.startAt.minute;
        final endM = e.endAt.hour * 60 + e.endAt.minute;
        if (nowMinutes >= startM && nowMinutes < endM) {
          schedulePos = 'In ${e.title} until ${e.endAt.hour}:${e.endAt.minute.toString().padLeft(2,'0')}';
          break;
        }
      }
      if (FocusController.instance.hasActiveSession) {
        schedulePos = 'Focus active: ${FocusController.instance.activeSession?.objective ?? 'Focus'}';
      } else if (dayBlocks.any((b) => now.isAfter(b.startAt) && now.isBefore(b.endAt))) {
        final cur = dayBlocks.firstWhere((b) => now.isAfter(b.startAt) && now.isBefore(b.endAt));
        schedulePos = 'Planned block: ${cur.customTitle ?? 'Session'}';
      }
    } catch (_) {}

    // Academic
    final subjects = SubjectController.instance.activeSubjects;
    final kc = AcademicKnowledgeController.instance;
    final topics = kc.topics;
    final allTopProgs = topics.map((t) => AcademicKnowledgeEngine.assessTopicProgress(t, sessions: sessions, practiceAttempts: TopicPracticeController.instance.attempts, revisionRecords: RevisionController.instance.records, revisionSchedules: RevisionController.instance.schedules, referenceTime: now)).toList();
    final needingStudy = allTopProgs.where((p) => p.status == TopicStatus.notStarted || p.status == TopicStatus.inProgress).toList();
    final needingRevision = allTopProgs.where((p) => p.isRevisionDue).toList();
    final weak = AcademicKnowledgeEngine.getWeakTopics(topics: topics, sessions: sessions, practiceAttempts: TopicPracticeController.instance.attempts, referenceTime: now);
    final incompleteSyllabus = needingStudy.length + needingRevision.length;

    int recentMins = 0;
    final cutoff = now.subtract(const Duration(days: 7));
    for (final s in sessions.where((s) => s.isCompleted && s.startedAt.isAfter(cutoff))) {
      recentMins += s.durationSec ~/ 60;
    }

    // Exams
    final upcomingExams = ExamController.instance.upcomingExams;
    upcomingExams.sort((a,b) => (a.daysUntilExam ?? 999).compareTo(b.daysUntilExam ?? 999));
    final nearest = upcomingExams.firstOrNull;
    final daysNearest = nearest?.daysUntilExam;
    int unfinishedSyll = 0;
    for (final e in upcomingExams) unfinishedSyll += e.syllabusTotal - e.syllabusCompleted;
    ExamPressureLevel revPressure = ExamPressureLevel.low;
    double pracPressure = 0;
    if (nearest != null) {
      final pressure = AcademicIntelligenceEngine.assessExamPressure(nearest, sessions: sessions, tasks: TaskController.instance.tasks, subjects: subjects, referenceTime: now);
      revPressure = pressure.level;
      pracPressure = pressure.score;
    }

    // Tasks
    final tasks = TaskController.instance.tasks;
    final overdue = tasks.where((t) => t.isOverdue && !t.isCompleted).toList();
    final dueSoon = tasks.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.difference(now).inDays >=0 && t.dueDate!.difference(now).inDays <=2).toList();
    final highPrio = tasks.where((t) => !t.isCompleted && (t.priority == TaskPriority.critical || t.priority == TaskPriority.high)).toList();
    int estEffort = 0;
    for (final t in tasks.where((t) => !t.isCompleted)) estEffort += t.estimatedMinutes >0 ? t.estimatedMinutes : 25;

    // Goals
    final goalText = GoalController.instance.personalGoal;
    final goalTasks = tasks.where((t) => t.goalId != null && !t.isCompleted).toList();

    // Practice
    final attempts = TopicPracticeController.instance.attempts;
    int? recentAcc;
    if (attempts.isNotEmpty) {
      final totalQ = attempts.take(5).fold<int>(0, (sum, a) => sum + (a.totalQuestions ?? 0));
      final correct = attempts.take(5).fold<int>(0, (sum, a) => sum + (a.correctAnswers ?? 0));
      if (totalQ >0) recentAcc = ((correct / totalQ)*100).round();
    }
    final unpracticed = allTopProgs.where((p) => p.isStudied && p.practiceAttemptsCount==0).length;

    // Revision
    final schedules = RevisionController.instance.schedules;
    final records = RevisionController.instance.records;
    int dueRev = schedules.where((s) => s.isDue).length;
    int overdueRev = schedules.where((s) => s.isOverdue).length;
    int failedRecall = records.where((r) => r.recallOutcome == RevisionRecallOutcome.forgot).length;

    return StudentStateSnapshot(
      referenceTime: now,
      currentDate: today,
      availableMinutes: avail,
      remainingFreeTimeMinutes: remainingFree,
      currentSchedulePosition: schedulePos,
      plannedMinutes: plannedMins,
      completedMinutes: completedMins,
      remainingMinutes: remainingMins,
      missedMinutes: missedMins,
      overloadState: dailyState.workloadState,
      overloadMinutes: dailyState.overloadMinutes,
      subjects: subjects,
      incompleteSyllabusCount: incompleteSyllabus,
      topicsNeedingStudy: needingStudy,
      topicsNeedingRevision: needingRevision,
      weakTopics: weak,
      recentStudyMinutes: recentMins,
      nearestExam: nearest,
      daysUntilNearestExam: daysNearest,
      unfinishedExamSyllabusCount: unfinishedSyll,
      revisionPressure: revPressure,
      practicePressure: pracPressure,
      overdueTasks: overdue,
      dueSoonTasks: dueSoon,
      highPriorityTasks: highPrio,
      estimatedEffortMinutes: estEffort,
      activeGoals: goalText,
      goalLinkedTasks: goalTasks,
      activeFocus: FocusController.instance.activeSession,
      currentStreak: StudyController.instance.studyStreakDays,
      missedSessions: missed,
      recoveryOpportunities: missed,
      recentPracticeAccuracy: recentAcc,
      unpracticedTopicsCount: unpracticed,
      dueRevisionCount: dueRev,
      failedRecallCount: failedRecall,
      overdueRevisionCount: overdueRev,
      preferredFocusDuration: UserPreferencesController.instance.defaultFocusDuration,
      autopilotMode: UserPreferencesController.instance.autopilotMode,
      isWorkloadHeavy: dailyState.workloadState == WorkloadState.overloaded || overdue.length >=3,
      examSummaries: [],
      subjectHealths: [],
    );
  }
}
