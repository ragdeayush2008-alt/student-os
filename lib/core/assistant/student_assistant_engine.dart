import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../data/models/chapter.dart';
import '../../data/models/exam.dart';
import '../../data/models/study_session.dart';
import '../../data/models/student_note.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/topic.dart';
import '../../data/models/academic_calendar_event.dart';
import '../../features/calendar/academic_schedule_controller.dart';
import '../../features/calendar/models/schedule_models.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/goals/goal_controller.dart';
import '../../features/knowledge/academic_knowledge_controller.dart';
import '../../features/knowledge/practice_question_controller.dart';
import '../../features/knowledge/presentation/practice_mode_selection_sheet.dart';
import '../../features/knowledge/topic_practice_controller.dart';
import '../../features/notes/student_note_controller.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/planning/models/planning_block.dart';
import '../../features/planning/services/planning_engine.dart';
import '../../features/preferences/user_preferences_controller.dart';
import '../../features/progression/progression_controller.dart';
import '../../features/revision/presentation/revision_session_screen.dart';
import '../../features/study/study_controller.dart';
import '../../features/student_life/models/student_life_preferences.dart';
import '../../features/student_life/student_life_controller.dart';
import '../../features/sleep/models/sleep_schedule.dart';
import '../../features/sleep/sleep_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../intelligence/academic_intelligence_engine.dart';
import '../intelligence/academic_knowledge_engine.dart';
import '../intelligence/autopilot_engine.dart';
import '../intelligence/student_os_intelligence_engine.dart';
import '../navigation/universal_action_executor.dart';
import '../services/course_catalog_service.dart';
import 'assistant_planning_engine.dart';
import 'daily_assistant_controller.dart';
import 'student_assistant_action.dart';
import 'student_assistant_context.dart';
import 'student_assistant_intent.dart';
import 'student_assistant_parser.dart';
import 'student_assistant_result.dart';

class StudentAssistantEngine {
  const StudentAssistantEngine({
    this.parser = const DeterministicStudentIntentParser(),
  });

  final StudentIntentParser parser;

  /// Processes user input text and produces a structured, actionable result.
  StudentAssistantResult process(
    String input, {
    StudentAssistantIntent? explicitIntent,
    List<Subject>? subjects,
    List<Chapter>? chapters,
    List<Topic>? topics,
    List<StudentTask>? tasks,
    List<StudentExam>? exams,
    List<StudySession>? sessions,
    List<PlanningBlock>? blocks,
    DateTime? referenceTime,
    AssistantContextSnapshot? context,
    AssistantDayPlan? proposal,
  }) {
    final now = referenceTime ?? DateTime.now();

    final activeSubjects = subjects ?? SubjectController.instance.activeSubjects;
    final allChapters = chapters ?? AcademicKnowledgeController.instance.chapters;
    final allTopics = topics ?? AcademicKnowledgeController.instance.topics;
    final allTasks = tasks ?? TaskController.instance.tasks;
    final upcomingExams = exams ?? ExamController.instance.upcomingExams;
    final allSessions = sessions ?? StudyController.instance.sessions;
    final allBlocks = blocks ?? PlanningBlockController.instance.blocks;

    final snapshot = context ??
        AssistantContextSnapshot.capture(
          referenceTime: now,
          subjects: activeSubjects,
          chapters: allChapters,
          topics: allTopics,
          tasks: allTasks,
          exams: upcomingExams,
          sessions: allSessions,
          blocks: allBlocks,
        );

    final intent = explicitIntent ??
        parser.parse(
          input,
          subjects: activeSubjects,
          chapters: allChapters,
          topics: allTopics,
          tasks: allTasks,
          exams: upcomingExams,
        );

    // 1. Clarification Required
    if (intent.clarificationRequired && intent.clarificationQuestion != null) {
      return StudentAssistantResult.clarification(
        intent: intent,
        question: intent.clarificationQuestion!,
        choices: intent.clarificationChoices,
      );
    }

    // 2. Active Focus Session Check
    final fc = FocusController.instance;
    final isFocusRunning = fc.hasActiveSession;

    switch (intent.intentType) {
      case AssistantIntentType.greeting:
        return _handleGreeting(isFocusRunning);

      case AssistantIntentType.help:
        return _handleHelp();

      case AssistantIntentType.whatShouldIDo:
        return _handleWhatShouldIDo(
          intent,
          subjects: activeSubjects,
          exams: upcomingExams,
          sessions: allSessions,
          tasks: allTasks,
          blocks: allBlocks,
          now: now,
          isFocusRunning: isFocusRunning,
          context: snapshot,
        );

      case AssistantIntentType.whatShouldIStudy:
        return _handleWhatShouldIStudy(
          intent,
          subjects: activeSubjects,
          exams: upcomingExams,
          sessions: allSessions,
          tasks: allTasks,
          topics: allTopics,
          now: now,
          isFocusRunning: isFocusRunning,
          context: snapshot,
        );

      case AssistantIntentType.whatShouldIRevise:
        return _handleWhatShouldIRevise(
          intent,
          subjects: activeSubjects,
          exams: upcomingExams,
          sessions: allSessions,
          topics: allTopics,
          now: now,
          isFocusRunning: isFocusRunning,
        );

      case AssistantIntentType.availableTime:
      case AssistantIntentType.planTime:
        return _handleAvailableTime(
          intent,
          availableMinutes: intent.availableMinutes ?? 120,
          subjects: activeSubjects,
          exams: upcomingExams,
          sessions: allSessions,
          tasks: allTasks,
          blocks: allBlocks,
          now: now,
          isFocusRunning: isFocusRunning,
          context: snapshot,
        );

      case AssistantIntentType.startMyDay:
        return _handleStartMyDay(
          intent,
          subjects: activeSubjects,
          exams: upcomingExams,
          sessions: allSessions,
          tasks: allTasks,
          blocks: allBlocks,
          now: now,
          isFocusRunning: isFocusRunning,
          context: snapshot,
        );

      case AssistantIntentType.continueMyDay:
        return _handleContinueMyDay(
          intent,
          subjects: activeSubjects,
          exams: upcomingExams,
          sessions: allSessions,
          tasks: allTasks,
          blocks: allBlocks,
          now: now,
          isFocusRunning: isFocusRunning,
        );

      case AssistantIntentType.studySubject:
      case AssistantIntentType.studyTopic:
      case AssistantIntentType.focusSubject:
      case AssistantIntentType.focusTopic:
        return _handleStudyOrFocusEntity(
          intent,
          subjects: activeSubjects,
          topics: allTopics,
          isFocusRunning: isFocusRunning,
        );

      case AssistantIntentType.reviseTopic:
        return _handleReviseTopic(
          intent,
          subjects: activeSubjects,
          topics: allTopics,
          isFocusRunning: isFocusRunning,
        );

      case AssistantIntentType.startFocus:
        return _handleStartFocus(
          intent,
          isFocusRunning: isFocusRunning,
        );

      case AssistantIntentType.showExams:
        return _handleShowExams(intent,
            exams: upcomingExams, sessions: allSessions, context: snapshot);

      case AssistantIntentType.showTasks:
        return _handleShowTasks(intent, tasks: allTasks, now: now);

      case AssistantIntentType.showCompleted:
        return _handleShowCompleted(
          intent,
          tasks: allTasks,
          sessions: allSessions,
          now: now,
        );

      case AssistantIntentType.showPriorities:
        return _handleShowPriorities(
          intent,
          subjects: activeSubjects,
          exams: upcomingExams,
          sessions: allSessions,
          tasks: allTasks,
          topics: allTopics,
          blocks: allBlocks,
          now: now,
        );

      case AssistantIntentType.scheduleTopic:
        return _handleScheduleTopic(
          intent,
          subjects: activeSubjects,
          chapters: allChapters,
          topics: allTopics,
          now: now,
        );

      case AssistantIntentType.stopFocus:
        return _handleStopFocus(intent);

      case AssistantIntentType.changeStudyTime:
        return _handleReschedule(intent,
            blocks: allBlocks, tasks: allTasks, now: now);

      case AssistantIntentType.showStudentLife:
        return _handleShowStudentLife(intent, now: now);

      case AssistantIntentType.showSleepSummary:
        return _handleShowSleepSummary(intent, now: now);

      case AssistantIntentType.openSleepSchedule:
        return _handleOpenSleepSchedule(intent);

      case AssistantIntentType.updateSleepSchedule:
        return _handleUpdateSleepSchedule(intent);

      case AssistantIntentType.createTask:
        return _handleCreateTask(intent, subjects: activeSubjects);

      case AssistantIntentType.prioritizeTask:
        return _handlePrioritizeTask(intent, tasks: allTasks);

      case AssistantIntentType.rescheduleTask:
        return _handleRescheduleTask(intent, tasks: allTasks, now: now);

      case AssistantIntentType.breakTask:
        return _handleBreakTask(intent, tasks: allTasks);

      case AssistantIntentType.catchUp:
        return _handleCatchUp(
          intent,
          tasks: allTasks,
          exams: upcomingExams,
          now: now,
          context: snapshot,
        );

      case AssistantIntentType.examPlan:
        return _handleExamPlan(
          intent,
          exams: upcomingExams,
          sessions: allSessions,
          topics: allTopics,
          subjects: activeSubjects,
          now: now,
          context: snapshot,
        );

      case AssistantIntentType.revisionPlan:
        return _handleRevisionPlan(
          intent,
          topics: allTopics,
          subjects: activeSubjects,
          sessions: allSessions,
          now: now,
          context: snapshot,
        );

      case AssistantIntentType.refinePlan:
        return _handleRefinePlan(intent, proposal: proposal);

      case AssistantIntentType.updateExamDate:
        return _handleUpdateExamDate(
          intent,
          exams: upcomingExams,
          now: now,
          context: snapshot,
        );

      case AssistantIntentType.morningBriefing:
        return _handleMorningBriefing(
          intent,
          tasks: allTasks,
          exams: upcomingExams,
          sessions: allSessions,
          blocks: allBlocks,
          now: now,
          context: snapshot,
        );

      case AssistantIntentType.eveningReview:
        return _handleEveningReview(
          intent,
          tasks: allTasks,
          exams: upcomingExams,
          now: now,
          context: snapshot,
        );

      case AssistantIntentType.prepareTomorrow:
        return _handlePrepareTomorrow(
          intent,
          tasks: allTasks,
          now: now,
          context: snapshot,
        );

      case AssistantIntentType.startWindDown:
        return _handleStartWindDown(intent, now: now);

      case AssistantIntentType.showWeakAreas:
      case AssistantIntentType.showOverdue:
        return _handleShowWeakAreas(
          intent,
          subjects: activeSubjects,
          exams: upcomingExams,
          sessions: allSessions,
          tasks: allTasks,
          topics: allTopics,
          blocks: allBlocks,
          now: now,
          context: snapshot,
        );

      case AssistantIntentType.showGoals:
        return _handleShowGoals(intent, sessions: allSessions, tasks: allTasks);

      case AssistantIntentType.showProgress:
        return _handleShowProgress(intent, subjects: activeSubjects, sessions: allSessions, tasks: allTasks);

      case AssistantIntentType.showRewards:
        return _handleShowRewards(intent);

      case AssistantIntentType.showTodayPlan:
        return _handleShowTodayPlan(intent,
            blocks: allBlocks, now: now, context: snapshot);

      case AssistantIntentType.reschedule:
        return _handleReschedule(intent, blocks: allBlocks, tasks: allTasks, now: now);

      case AssistantIntentType.recoverMissedSession:
        return _handleRecoverMissedSession(intent,
            blocks: allBlocks,
            tasks: allTasks,
            now: now,
            context: snapshot);

      case AssistantIntentType.rebalanceDay:
        return _handleRebalanceDay(
          intent,
          blocks: allBlocks,
          tasks: allTasks,
          now: now,
          context: snapshot,
        );

      case AssistantIntentType.startTask:
      case AssistantIntentType.completeTask:
        return _handleTaskAction(intent, tasks: allTasks);

      case AssistantIntentType.practiceTopic:
        return _handlePracticeTopic(
          intent,
          topics: allTopics,
          subjects: activeSubjects,
        );

      case AssistantIntentType.practiceWeakest:
        return _handlePracticeWeakest(
          intent,
          topics: allTopics,
          subjects: activeSubjects,
          sessions: allSessions,
          now: now,
        );

      case AssistantIntentType.showPracticeHistory:
        return _handleShowPracticeHistory(intent);

      case AssistantIntentType.showScheduleToday:
        return _handleScheduleToday(intent, now: now);

      case AssistantIntentType.showScheduleTomorrow:
        return _handleScheduleTomorrow(intent, now: now);

      case AssistantIntentType.showWeekSchedule:
        return _handleWeekSchedule(intent, now: now);

      case AssistantIntentType.showNextClass:
        return _handleNextClass(intent, now: now);

      case AssistantIntentType.checkFreeTime:
        return _handleCheckFreeTime(intent, now: now);

      case AssistantIntentType.showScheduleConflicts:
        return _handleScheduleConflicts(intent, now: now);

      case AssistantIntentType.showBusiestDay:
        return _handleBusiestDay(intent, now: now);

      case AssistantIntentType.showNotes:
        return _handleShowNotes(intent);

      case AssistantIntentType.searchNotes:
        return _handleSearchNotes(intent);

      case AssistantIntentType.openNote:
        return _handleOpenNote(intent);

      case AssistantIntentType.showPinnedNotes:
        return _handleShowPinnedNotes(intent);

      case AssistantIntentType.showRecentNotes:
        return _handleShowRecentNotes(intent);

      case AssistantIntentType.createNote:
        return _handleCreateNote(intent);

      case AssistantIntentType.changeCourse:
        return _handleChangeCourse(intent);

      case AssistantIntentType.unknown:
        return _handleUnknown(intent, subjects: activeSubjects);
    }
  }

  // ─── Intent Handlers ────────────────────────────────────────────────

  StudentAssistantResult _handleGreeting(bool isFocusRunning) {
    if (isFocusRunning) {
      final active = FocusController.instance.activeSession;
      return StudentAssistantResult(
        success: true,
        intent: const StudentAssistantIntent(rawText: 'hi', intentType: AssistantIntentType.greeting),
        title: 'Focus is active',
        message: 'You have a focus session in progress: "${active?.objective ?? "Focus"}".',
        primaryAction: const StudentAssistantAction(
          id: 'action_continue_active',
          type: AssistantActionType.startFocus,
          label: 'Continue Focus Session',
        ),
        suggestedPrompts: const [
          'What should I do after this?',
          'Show my exams',
          'Show today\'s plan',
        ],
      );
    }

    return StudentAssistantResult.empty(
      title: 'Hi! What would you like to do?',
      message: 'I can help you plan your available time, pick the best topic to study, or check revision.',
    );
  }

  StudentAssistantResult _handleHelp() {
    return const StudentAssistantResult(
      success: true,
      intent: StudentAssistantIntent(rawText: 'help', intentType: AssistantIntentType.help),
      title: 'Student OS Assistant Commands',
      message: 'You can ask questions or state your time and goals directly:',
      previewItems: [
        '• "I have 2 hours" — Auto-generates a structured study & break plan',
        '• "What should I study?" — Finds your highest priority topic or subject',
        '• "What should I revise?" — Shows topics due for spaced repetition review',
        '• "Start my day" — Begins your morning academic schedule',
        '• "Study [subject/topic]" — Launches a direct focus session',
        '• "Move this to tomorrow" — Reschedules pending work safely',
        '• "Show my exams" — Lists upcoming exams and pressure levels',
      ],
      suggestedPrompts: [
        'What should I do?',
        'I have 90 minutes',
        'What should I revise?',
        'Show my exams',
      ],
    );
  }

  StudentAssistantResult _handleChangeCourse(StudentAssistantIntent intent) {
    final current = CourseCatalogService.instance.getActiveCourse() ?? 'None';
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Change Academic Goal / Course',
      message:
          'Your current active course is "$current". Which course or exam would you like to switch to?',
      primaryAction: const StudentAssistantAction(
        id: 'action_open_course_selection',
        type: AssistantActionType.openCourseSelection,
        label: 'Select Course or Exam',
      ),
      suggestedPrompts: const [
        'CA Foundation 2026',
        'JEE Main 2026',
        'NEET UG 2026',
        'UPSC Civil Services',
      ],
    );
  }

  StudentAssistantResult _handleWhatShouldIDo(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
    required List<PlanningBlock> blocks,
    required DateTime now,
    required bool isFocusRunning,
    AssistantContextSnapshot? context,
  }) {
    if (isFocusRunning) {
      final active = FocusController.instance.activeSession;
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.confirmation,
        title: 'Focus in Progress',
        message:
            'You have an active session for "${active?.objective ?? "Focus"}".',
        contextLine: context?.summaryLine,
        primaryAction: const StudentAssistantAction(
          id: 'act_continue_focus',
          type: AssistantActionType.startFocus,
          label: 'Return to Focus',
        ),
      );
    }

    final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      blocks: blocks,
      referenceTime: now,
    );

    if (action.type == StudentOSActionType.empty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'All Caught Up',
        message: 'You have no urgent tasks or upcoming deadlines. Plan your day or start optional study.',
        contextLine: context?.summaryLine,
        suggestedPrompts: const ['I have 2 hours', 'What should I revise?', 'Show my exams'],
        primaryAction: const StudentAssistantAction(
          id: 'act_plan',
          type: AssistantActionType.openPlan,
          label: 'Plan My Day',
        ),
      );
    }

    final duration = Duration(
      minutes: action.suggestedDurationMinutes > 0 ? action.suggestedDurationMinutes : 35,
    );

    AssistantActionType actType;
    if (action.topicId != null) {
      actType = AssistantActionType.startTopic;
    } else if (action.taskId != null) {
      actType = AssistantActionType.startTask;
    } else {
      actType = AssistantActionType.startFocus;
    }

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.recommendation,
      title: action.title,
      message: action.subtitle,
      explanation: action.reason,
      contextLine: context?.summaryLine,
      previewItems: action.bulletReasons.map((r) => '• $r').toList(),
      primaryAction: StudentAssistantAction(
        id: 'act_do_now',
        type: actType,
        label: 'Start Now (${duration.inMinutes}m)',
        subjectId: action.subjectId,
        subjectName: action.subjectName,
        topicId: action.topicId,
        topicTitle: action.topicTitle,
        taskId: action.taskId,
        examId: action.examId,
        duration: duration,
      ),
      suggestedPrompts: const ['I have 2 hours', 'What should I revise?', 'Show today\'s plan'],
    );
  }

  StudentAssistantResult _handleWhatShouldIStudy(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
    required List<Topic> topics,
    required DateTime now,
    required bool isFocusRunning,
    AssistantContextSnapshot? context,
  }) {
    if (subjects.isEmpty) {
      return StudentAssistantResult.error(
        intent: intent,
        title: 'No Subjects Added',
        message: 'Add your subjects or courses first to get personalized study recommendations.',
      );
    }

    final recs = AcademicIntelligenceEngine.generateStudyRecommendations(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      topics: topics,
      referenceTime: now,
    );

    if (recs.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Study Schedule Clear',
        message: 'No immediate study requirements found.',
        primaryAction: const StudentAssistantAction(
          id: 'act_study_open',
          type: AssistantActionType.openStudy,
          label: 'Explore Subjects',
        ),
      );
    }

    final top = recs.first;
    final duration = Duration(minutes: top.suggestedDurationMinutes);

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.recommendation,
      title: top.title,
      message: '${top.suggestedDurationMinutes} min · ${top.subjectName}',
      explanation: top.primaryReason,
      contextLine: context?.summaryLine,
      previewItems: top.reasons.map((r) => '• $r').toList(),
      primaryAction: StudentAssistantAction(
        id: 'act_study_top',
        type: top.topicId != null ? AssistantActionType.startTopic : AssistantActionType.startFocus,
        label: 'Study (${duration.inMinutes}m)',
        subjectId: top.subjectId,
        subjectName: top.subjectName,
        topicId: top.topicId,
        chapterId: top.chapterId,
        topicTitle: top.topicTitle,
        examId: top.exam?.id,
        duration: duration,
      ),
      secondaryActions: recs.skip(1).take(2).map((r) {
        return StudentAssistantAction(
          id: 'act_alt_${r.id}',
          type: r.topicId != null ? AssistantActionType.startTopic : AssistantActionType.startFocus,
          label: r.title,
          isPrimary: false,
          subjectId: r.subjectId,
          subjectName: r.subjectName,
          topicId: r.topicId,
          chapterId: r.chapterId,
          topicTitle: r.topicTitle,
          duration: Duration(minutes: r.suggestedDurationMinutes),
        );
      }).toList(),
    );
  }

  StudentAssistantResult _handleWhatShouldIRevise(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<Topic> topics,
    required DateTime now,
    required bool isFocusRunning,
  }) {
    final revRecs = AcademicIntelligenceEngine.generateRevisionRecommendations(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      topics: topics,
      referenceTime: now,
    );

    if (revRecs.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Up to Date on Revision',
        message: 'No topics or resources currently require urgent recall revision.',
        suggestedPrompts: const ['What should I study?', 'I have 2 hours', 'Show my exams'],
      );
    }

    final top = revRecs.first;
    final duration = const Duration(minutes: 20);

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: top.title,
      message: '${top.subjectName} · Revision Due',
      explanation: top.primaryReason,
      previewItems: top.reasons.map((r) => '• $r').toList(),
      primaryAction: StudentAssistantAction(
        id: 'act_revise_top',
        type: AssistantActionType.startRevision,
        label: 'Revise (${duration.inMinutes}m)',
        subjectId: top.subjectId,
        subjectName: top.subjectName,
        topicId: top.topicId,
        chapterId: top.chapterId,
        topicTitle: top.topicTitle,
        examId: top.examId,
        duration: duration,
      ),
      secondaryActions: revRecs.skip(1).take(2).map((r) {
        return StudentAssistantAction(
          id: 'act_alt_rev_${r.id}',
          type: AssistantActionType.startRevision,
          label: r.title,
          isPrimary: false,
          subjectId: r.subjectId,
          subjectName: r.subjectName,
          topicId: r.topicId,
          chapterId: r.chapterId,
          topicTitle: r.topicTitle,
          duration: const Duration(minutes: 20),
        );
      }).toList(),
    );
  }

    StudentAssistantResult _handleAvailableTime(
    StudentAssistantIntent intent, {
    required int availableMinutes,
    required List<Subject> subjects,
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
    required List<PlanningBlock> blocks,
    required DateTime now,
    required bool isFocusRunning,
    AssistantContextSnapshot? context,
  }) {
    // P2: clamp the authoritative plan by the sleep boundary (or an
    // explicit evening cutoff) so proposals never cross bedtime.
    final sleep = _readSleep();
    var effective = availableMinutes;
    if (sleep != null) {
      final bed = SleepScheduleValidation.normaliseMinutes(
        sleep.bedtimeMinutes,
      );
      var bedtime = DateTime(now.year, now.month, now.day, bed ~/ 60, bed % 60);
      if (!bedtime.isAfter(now)) {
        bedtime = bedtime.add(const Duration(days: 1));
      }
      effective = effective.clamp(
        15,
        bedtime.difference(now).inMinutes.clamp(
              0,
              AssistantPlanningEngine.maxDayMinutes,
            ),
      );
    }
    final cutoff = intent.eveningCutoffMinutes;
    if (cutoff != null) {
      final c = SleepScheduleValidation.normaliseMinutes(cutoff);
      var end = DateTime(now.year, now.month, now.day, c ~/ 60, c % 60);
      if (!end.isAfter(now)) end = end.add(const Duration(days: 1));
      effective = effective.clamp(
        0,
        end.difference(now).inMinutes.clamp(
              0,
              AssistantPlanningEngine.maxDayMinutes,
            ),
      );
    }

    final plan = PlanningEngine.generateDailyPlan(
      now,
      tasks: tasks,
      subjects: subjects,
      exams: exams,
      blocks: blocks,
      availableBudgetMinutes: effective,
    );

    if (plan.items.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'All Caught Up',
        message:
            'You have no pending tasks or exams to schedule in your $availableMinutes min budget.',
        contextLine: context?.summaryLine,
      );
    }

    final previewLines = plan.items.map((i) {
      return '• ${i.estimatedMinutes}m — ${i.title} (${i.reason})';
    }).toList();

    final firstItem = plan.items.first;
    final firstDur = Duration(minutes: firstItem.estimatedMinutes);

    // P2: stage the same authoritative items as an appliable proposal with
    // the sleep boundary recorded. Order and minutes stay exactly as the
    // planning engine produced them. Already-scheduled items are never
    // re-created — applying must not duplicate today's plan. Items that
    // would cross the sleep boundary stay out with an honest reason.
    final freshItems =
        plan.items.where((i) => !i.isAlreadyScheduled).toList();
    final alreadyCount = plan.items.length - freshItems.length;
    if (freshItems.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Already Planned',
        message: alreadyCount > 0
            ? 'Everything in your $effective-minute budget is already on today\'s plan. Nothing new to apply.'
            : 'You have no pending tasks or exams to schedule in your $effective min budget.',
        cardKind: AssistantCardKind.success,
        contextLine: [
          if (sleep != null) 'Sleep ${sleep.windowLabel}',
          if (context?.summaryLine != null) context?.summaryLine ?? '',
        ].join(' · '),
      );
    }
    final proposalSessions = <PlannedSession>[];
    final pastBoundary = <String>[];
    var laidOut = 0;
    for (var idx = 0; idx < freshItems.length; idx++) {
      final i = freshItems[idx];
      final gap = proposalSessions.isEmpty
          ? 0
          : AssistantPlanningEngine.breakMinutes;
      if (laidOut + gap + i.estimatedMinutes > effective) {
        pastBoundary.add(
          '"${i.title}" — would cross the evening boundary, kept for tomorrow.',
        );
        continue;
      }
      laidOut += gap + i.estimatedMinutes;
      proposalSessions.add(
        PlannedSession(
          id: 'p$idx',
          title: i.title,
          detail: i.reason,
          minutes: i.estimatedMinutes,
          reason: i.reason,
          taskId: i.taskId,
          subjectId: i.subjectId,
          topicId: i.topicId,
        ),
      );
    }
    final proposal = AssistantDayPlan(
      kind: AssistantProposalKind.dayPlan,
      sessions: proposalSessions,
      unscheduled: [
        if (alreadyCount > 0)
          '$alreadyCount already-scheduled item${alreadyCount == 1 ? '' : 's'} kept (not duplicated).',
        ...pastBoundary,
        if (plan.deferredTasksCount > 0)
          '${plan.deferredTasksCount} task${plan.deferredTasksCount == 1 ? '' : 's'} deferred (over budget).',
      ],
      conflicts: [
        if (effective < availableMinutes)
          'Trimmed to ${effective}m to protect your evening boundary.',
      ],
      budgetMinutes: effective,
      sleepNote: sleep != null
          ? 'Your ${sleep.windowLabel} sleep is protected.'
          : null,
      anchoredStart: now,
    );
    if (proposalSessions.isEmpty && pastBoundary.isNotEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Evening Protected',
        message:
            'Fitting work would cross your evening boundary, so I kept the night clear. ${pastBoundary.join(' ')}',
        cardKind: AssistantCardKind.recommendation,
        contextLine: [
          if (sleep != null) 'Sleep ${sleep.windowLabel}',
          if (context?.summaryLine != null) context?.summaryLine ?? '',
        ].join(' · '),
        suggestedPrompts: const ['Prepare tomorrow', 'Fix my day'],
      );
    }

    final steps = plan.items
        .map((i) => AssistantResultStep(
              label: i.title,
              detail: i.reason,
              minutes: i.estimatedMinutes,
              kind: i.topicId != null
                  ? 'topic'
                  : i.taskId != null
                      ? 'task'
                      : 'subject',
              subjectId: i.subjectId,
              topicId: i.topicId,
              chapterId: i.chapterId,
              taskId: i.taskId,
            ))
        .toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.todayPlan,
      title: 'Plan for $effective Minutes',
      message: plan.summary,
      previewItems: previewLines,
      steps: steps,
      planResult: plan,
      proposal: proposal,
      requiresConfirmation: proposal.sessions.isNotEmpty,
      contextLine: [
        if (sleep != null) 'Sleep ${sleep.windowLabel}',
        if (context?.summaryLine != null) context?.summaryLine ?? '',
      ].join(' · '),
      primaryAction: proposal.sessions.isNotEmpty
          ? const StudentAssistantAction(
              id: 'act_apply_proposal',
              type: AssistantActionType.applyPlan,
              label: 'Apply Plan',
              requiresConfirmation: true,
            )
          : StudentAssistantAction(
              id: 'act_start_plan',
              type: AssistantActionType.startPlan,
              label: 'Start Plan (${firstItem.title})',
              subjectId: firstItem.subjectId,
              subjectName: firstItem.subject?.displayName,
              topicId: firstItem.topicId,
              chapterId: firstItem.chapterId,
              topicTitle: firstItem.title,
              taskId: firstItem.taskId,
              duration: firstDur,
            ),
      secondaryActions: [
        if (proposal.sessions.isNotEmpty)
          StudentAssistantAction(
            id: 'act_start_plan',
            type: AssistantActionType.startPlan,
            label: 'Start (${firstItem.title})',
            isPrimary: false,
            subjectId: firstItem.subjectId,
            subjectName: firstItem.subject?.displayName,
            topicId: firstItem.topicId,
            chapterId: firstItem.chapterId,
            topicTitle: firstItem.title,
            taskId: firstItem.taskId,
            duration: firstDur,
          ),
      ],
      suggestedPrompts: const [
        'What should I do now?',
        'Show today plan',
      ],
    );
  }

  StudentAssistantResult _handleStartMyDay(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
    required List<PlanningBlock> blocks,
    required DateTime now,
    required bool isFocusRunning,
    AssistantContextSnapshot? context,
  }) {
    final mode = UserPreferencesController.instance.autopilotMode;
    final dayState = StudentOSAutopilotEngine.computeAutopilotDayState(
      targetDay: now,
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      blocks: blocks,
      mode: mode,
    );

    final action = dayState.startMyDayAction;
    final dur = Duration(
      minutes: action.suggestedDurationMinutes > 0 ? action.suggestedDurationMinutes : 35,
    );

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.nextAction,
      title: 'Ready to start today',
      message: 'First priority: ${action.title}',
      explanation: action.reason,
      previewItems: action.bulletReasons.map((r) => '• $r').toList(),
      primaryAction: StudentAssistantAction(
        id: 'act_start_my_day',
        type: AssistantActionType.startFocus,
        label: 'Start ${action.title} (${dur.inMinutes}m)',
        subjectId: action.subjectId,
        subjectName: action.subjectName,
        topicId: action.topicId,
        chapterId: action.chapterId,
        topicTitle: action.topicTitle,
        taskId: action.taskId,
        examId: action.examId,
        duration: dur,
      ),
    );
  }

  StudentAssistantResult _handleContinueMyDay(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
    required List<PlanningBlock> blocks,
    required DateTime now,
    required bool isFocusRunning,
  }) {
    if (isFocusRunning) {
      final active = FocusController.instance.activeSession;
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Focus Active',
        message: 'Currently running: "${active?.objective ?? "Focus Session"}".',
        primaryAction: const StudentAssistantAction(
          id: 'act_cont_focus',
          type: AssistantActionType.startFocus,
          label: 'Return to Focus',
        ),
      );
    }

    final mode = UserPreferencesController.instance.autopilotMode;
    final dayState = StudentOSAutopilotEngine.computeAutopilotDayState(
      targetDay: now,
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      blocks: blocks,
      mode: mode,
    );

    final action = dayState.continueMyDayAction ?? dayState.nextAction;
    final dur = Duration(
      minutes: action.suggestedDurationMinutes > 0 ? action.suggestedDurationMinutes : 30,
    );

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: action.title,
      message: action.subtitle,
      explanation: action.reason,
      previewItems: action.bulletReasons.map((r) => '• $r').toList(),
      primaryAction: StudentAssistantAction(
        id: 'act_cont_day',
        type: AssistantActionType.startFocus,
        label: 'Continue (${dur.inMinutes}m)',
        subjectId: action.subjectId,
        subjectName: action.subjectName,
        topicId: action.topicId,
        chapterId: action.chapterId,
        topicTitle: action.topicTitle,
        taskId: action.taskId,
        examId: action.examId,
        duration: dur,
      ),
    );
  }

  StudentAssistantResult _handleStudyOrFocusEntity(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<Topic> topics,
    required bool isFocusRunning,
  }) {
    if (isFocusRunning) {
      return const StudentAssistantResult(
        success: true,
        intent: StudentAssistantIntent(rawText: '', intentType: AssistantIntentType.startFocus),
        title: 'Focus in Progress',
        message: 'A focus timer is already running. Finish or pause your active session first.',
        primaryAction: StudentAssistantAction(
          id: 'act_focus_active',
          type: AssistantActionType.startFocus,
          label: 'Return to Active Focus',
        ),
      );
    }

    final duration = Duration(minutes: intent.durationMinutes ?? 35);
    final isTopic = intent.topicId != null;

    final title = isTopic
        ? 'Study ${intent.topicName ?? "Topic"}'
        : 'Study ${intent.subjectName ?? "Subject"}';

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: title,
      message: 'Ready for a ${duration.inMinutes} min focused study session.',
      primaryAction: StudentAssistantAction(
        id: 'act_direct_study',
        type: isTopic ? AssistantActionType.startTopic : AssistantActionType.startFocus,
        label: 'Start Session (${duration.inMinutes}m)',
        subjectId: intent.subjectId,
        subjectName: intent.subjectName,
        topicId: intent.topicId,
        chapterId: intent.chapterId,
        topicTitle: intent.topicName,
        duration: duration,
      ),
    );
  }

  StudentAssistantResult _handleReviseTopic(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<Topic> topics,
    required bool isFocusRunning,
  }) {
    if (isFocusRunning) {
      return const StudentAssistantResult(
        success: true,
        intent: StudentAssistantIntent(rawText: '', intentType: AssistantIntentType.reviseTopic),
        title: 'Focus in Progress',
        message: 'A focus timer is already running.',
        primaryAction: StudentAssistantAction(
          id: 'act_focus_active',
          type: AssistantActionType.startFocus,
          label: 'Return to Active Focus',
        ),
      );
    }

    final duration = Duration(minutes: intent.durationMinutes ?? 20);
    final title = 'Revise ${intent.topicName ?? intent.subjectName ?? "Topic"}';

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: title,
      message: 'Ready for a ${duration.inMinutes} min recall & revision session.',
      primaryAction: StudentAssistantAction(
        id: 'act_direct_revise',
        type: AssistantActionType.startRevision,
        label: 'Start Revision (${duration.inMinutes}m)',
        subjectId: intent.subjectId,
        subjectName: intent.subjectName,
        topicId: intent.topicId,
        chapterId: intent.chapterId,
        topicTitle: intent.topicName,
        duration: duration,
      ),
    );
  }

  StudentAssistantResult _handleStartFocus(
    StudentAssistantIntent intent, {
    required bool isFocusRunning,
  }) {
    if (isFocusRunning) {
      return const StudentAssistantResult(
        success: true,
        intent: StudentAssistantIntent(rawText: '', intentType: AssistantIntentType.startFocus),
        title: 'Focus Active',
        message: 'A focus session is already active.',
        primaryAction: StudentAssistantAction(
          id: 'act_focus_active',
          type: AssistantActionType.startFocus,
          label: 'Return to Active Focus',
        ),
      );
    }

    final duration = Duration(minutes: intent.durationMinutes ?? 25);
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Start Focus Session',
      message: 'Timer set for ${duration.inMinutes} minutes.',
      primaryAction: StudentAssistantAction(
        id: 'act_start_focus',
        type: AssistantActionType.startFocus,
        label: 'Start (${duration.inMinutes}m)',
        duration: duration,
      ),
    );
  }

  StudentAssistantResult _handleShowExams(
    StudentAssistantIntent intent, {
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    AssistantContextSnapshot? context,
  }) {
    if (exams.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'No Upcoming Exams',
        message: 'You have no exams tracked in your academic calendar.',
        primaryAction: const StudentAssistantAction(
          id: 'act_open_exams',
          type: AssistantActionType.openExams,
          label: 'Add an Exam',
        ),
      );
    }

    final sorted = [...exams]..sort((a, b) {
        final ad = a.examDateTime ?? DateTime(2100);
        final bd = b.examDateTime ?? DateTime(2100);
        return ad.compareTo(bd);
      });

    final previewLines = sorted.map((e) {
      final days = e.daysUntilExam;
      final countdown = days == null
          ? 'No date'
          : (days == 0
              ? 'Today'
              : (days == 1 ? 'Tomorrow' : 'in $days days'));
      return '• ${e.title} (${e.subject.isNotEmpty ? e.subject : "Exam"}) — $countdown';
    }).toList();

    final steps = sorted.map((e) {
      final days = e.daysUntilExam;
      return AssistantResultStep(
        label: e.title,
        detail: e.subject.isNotEmpty ? e.subject : null,
        id: e.id,
        kind: 'exam',
        examId: e.id,
        minutes: days,
      );
    }).toList();

    final nearest = sorted.first;
    final nearestDays = nearest.daysUntilExam;

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.exam,
      title: nearestDays != null
          ? '${nearest.title} — ${nearestDays}d'
          : 'Upcoming Exams (${exams.length})',
      message: nearestDays != null && nearestDays <= 7
          ? 'Your closest exam is coming up. Prioritise its subject.'
          : 'Here is your active exam schedule:',
      contextLine: context?.summaryLine,
      previewItems: previewLines,
      steps: steps,
      primaryAction: const StudentAssistantAction(
        id: 'act_open_exams',
        type: AssistantActionType.openExams,
        label: 'Open Exams Workspace',
      ),
    );
  }

  StudentAssistantResult _handleShowTasks(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final overdueOnly = intent.overdueOnly;
    final active = tasks.where((t) {
      if (t.isCompleted) return false;
      if (!overdueOnly) return true;
      return t.dueDate != null && t.dueDate!.isBefore(reference);
    }).toList();

    if (active.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: overdueOnly ? 'Nothing Overdue' : 'Task List Clear',
        message: overdueOnly
            ? 'You have no overdue tasks right now.'
            : 'All tasks are completed. You have no pending homework or assignments.',
        primaryAction: const StudentAssistantAction(
          id: 'act_open_tasks',
          type: AssistantActionType.openTasks,
          label: 'Add a Task',
        ),
      );
    }

    final previewLines = active.take(5).map((t) {
      final prio = t.priority.label;
      return '• ${t.title} ($prio priority)';
    }).toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: overdueOnly
          ? AssistantCardKind.nextAction
          : AssistantCardKind.studyTopic,
      title: overdueOnly
          ? 'Overdue Tasks (${active.length})'
          : 'Active Tasks (${active.length})',
      message: overdueOnly
          ? 'These tasks are past their due date:'
          : 'Here are your pending tasks:',
      previewItems: previewLines,
      primaryAction: const StudentAssistantAction(
        id: 'act_open_tasks',
        type: AssistantActionType.openTasks,
        label: 'Open Task Workspace',
      ),
    );
  }

  /// "What have I completed today?" — read-only, from authoritative data.
  StudentAssistantResult _handleShowCompleted(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
    required List<StudySession> sessions,
    required DateTime now,
  }) {
    final completedTasks = tasks.where((t) {
      if (!t.isCompleted) return false;
      final stamp = t.completedAt ?? t.createdAt;
      return _isSameDay(stamp, now);
    }).toList();

    final todayMinutes = sessions
        .where((s) => s.isCompleted && _isSameDay(s.startedAt, now))
        .fold<int>(0, (sum, s) => sum + s.durationSec) ~/
        60;

    if (completedTasks.isEmpty && todayMinutes == 0) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'Nothing Completed Yet',
        message: 'You have not completed any tasks or logged study time today.',
        suggestedPrompts: const [
          'What should I do now?',
          'I have 2 hours',
          'Show today\'s plan',
        ],
      );
    }

    final preview = <String>[
      if (completedTasks.isNotEmpty)
        ...completedTasks.take(5).map((t) => '• ${t.title}'),
      if (todayMinutes > 0) '• $todayMinutes min of study logged',
    ];

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.success,
      title: 'Completed Today',
      message: completedTasks.isEmpty
          ? 'You logged $todayMinutes min of study today.'
          : 'You finished ${completedTasks.length} task${completedTasks.length == 1 ? "" : "s"}'
              '${todayMinutes > 0 ? " and $todayMinutes min of study" : ""} today.',
      previewItems: preview,
    );
  }

  /// "What should I prioritize?" — delegates to the authoritative intelligence.
  StudentAssistantResult _handleShowPriorities(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
    required List<Topic> topics,
    required List<PlanningBlock> blocks,
    required DateTime now,
  }) {
    final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      blocks: blocks,
      referenceTime: now,
    );

    if (action.type == StudentOSActionType.empty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'Nothing Urgent',
        message: 'Nothing is competing for priority right now. A good time to get ahead.',
        suggestedPrompts: const ['What should I study?', 'I have 2 hours'],
      );
    }

    final risks = StudentOSIntelligenceEngine.detectAcademicRisks(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      blocks: blocks,
      referenceTime: now,
    );

    final duration = Duration(
      minutes: action.suggestedDurationMinutes > 0
          ? action.suggestedDurationMinutes
          : 35,
    );

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.recommendation,
      title: 'Top Priority',
      message: '${action.title}${action.subjectName != null ? " · ${action.subjectName}" : ""}',
      explanation: action.reason,
      previewItems: action.bulletReasons.map((r) => '• $r').toList(),
      contextLine: risks.isEmpty
          ? null
          : '${risks.length} priority signal${risks.length == 1 ? "" : "s"} found',
      primaryAction: StudentAssistantAction(
        id: 'act_priority_start',
        type: action.topicId != null
            ? AssistantActionType.startTopic
            : action.taskId != null
                ? AssistantActionType.startTask
                : AssistantActionType.startFocus,
        label: 'Start Now (${duration.inMinutes}m)',
        subjectId: action.subjectId,
        subjectName: action.subjectName,
        topicId: action.topicId,
        topicTitle: action.topicTitle,
        taskId: action.taskId,
        examId: action.examId,
        duration: duration,
      ),
    );
  }

  /// "Plan this topic" / "Schedule revision for this topic".
  StudentAssistantResult _handleScheduleTopic(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<Chapter> chapters,
    required List<Topic> topics,
    required DateTime now,
  }) {
    Topic? topic;
    if (intent.topicId != null) {
      topic = topics.where((t) => t.id == intent.topicId).firstOrNull;
    }
    if (topic == null && intent.topicName != null) {
      topic = topics
          .where((t) => t.title.toLowerCase() == intent.topicName!.toLowerCase())
          .firstOrNull;
    }

    if (topic == null) {
      // Without a resolvable topic, fall back to the planning surface rather
      // than inventing one.
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'Pick a Topic First',
        message:
            'Open a subject and choose a topic, or tell me the topic name to schedule it.',
        primaryAction: const StudentAssistantAction(
          id: 'act_open_study_pick',
          type: AssistantActionType.openStudy,
          label: 'Browse Subjects',
        ),
      );
    }

    final subject = subjects.where((s) => s.id == topic!.subjectId).firstOrNull;
    final minutes = intent.durationMinutes ??
        (topic.estimatedMinutes > 0 ? topic.estimatedMinutes : 45);

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.schedulePreview,
      title: 'Schedule ${topic.title}',
      message:
          'Add ${topic.title}${subject != null ? " (${subject.displayName})" : ""} to your plan as a $minutes min block?',
      explanation: 'You will confirm the exact slot before anything is written.',
      contextLine: 'Scheduling into today\'s plan',
      requiresConfirmation: true,
      primaryAction: StudentAssistantAction(
        id: 'act_schedule_topic',
        type: AssistantActionType.scheduleTopic,
        label: 'Choose a Slot',
        subjectId: topic.subjectId,
        subjectName: subject?.displayName,
        chapterId: topic.chapterId,
        topicId: topic.id,
        topicTitle: topic.title,
        duration: Duration(minutes: minutes),
        requiresConfirmation: true,
      ),
    );
  }

  /// "Stop focus" — ends the active session through FocusController.
  StudentAssistantResult _handleStopFocus(StudentAssistantIntent intent) {
    final fc = FocusController.instance;
    if (!fc.hasActiveSession) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'No Active Focus',
        message: 'You do not have a running focus session to stop.',
      );
    }

    final active = fc.activeSession;
    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.confirmation,
      title: 'Stop Focus Session',
      message:
          'End your current focus session${active?.objective != null ? " on ${active!.objective}" : ""}?',
      requiresConfirmation: true,
      primaryAction: const StudentAssistantAction(
        id: 'act_stop_focus',
        type: AssistantActionType.stopFocus,
        label: 'End Session',
        requiresConfirmation: true,
      ),
    );
  }

  /// "Change my study time" — safe clarification, never a silent rewrite.

  StudentAssistantResult _handleShowWeakAreas(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
    required List<Topic> topics,
    required List<PlanningBlock> blocks,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    final risks = StudentOSIntelligenceEngine.detectAcademicRisks(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      blocks: blocks,
      referenceTime: now,
    );

    // Authoritative weak-topic list (with IDs) so follow-ups such as
    // "plan the first one" can be resolved.
    final weak = AcademicKnowledgeEngine.getWeakTopics(
      topics: topics,
      sessions: sessions,
      referenceTime: now,
    );

    if (risks.isEmpty && weak.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: "You Don't Currently Have a Strong Weak-Topic Signal",
        message:
            'No severe academic risks, overdue tasks, or weak topics found. Keep your current rhythm.',
        contextLine: context?.summaryLine,
      );
    }

    final steps = weak
        .take(5)
        .map((p) {
          final subject = subjects
              .where((s) => s.id == p.topic.subjectId)
              .firstOrNull;
          final acc = p.practiceAccuracyPercentage;
          return AssistantResultStep(
            label: p.topic.title,
            detail: subject?.displayName ??
                (acc != null ? '$acc% accuracy' : 'Needs attention'),
            id: p.topic.id,
            kind: 'topic',
            subjectId: p.topic.subjectId,
            chapterId: p.topic.chapterId,
            topicId: p.topic.id,
          );
        })
        .toList();

    final previewLines = <String>[
      ...weak.take(5).map((p) => '• ${p.topic.title}'),
      ...risks.take(3).map((r) => '• ${r.title}: ${r.detail}'),
    ];

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.nextAction,
      title: 'Areas Needing Attention',
      message: weak.isNotEmpty
          ? 'Found ${weak.length} weak topic${weak.length == 1 ? "" : "s"} to work on.'
          : 'Found ${risks.length} academic priority signal${risks.length == 1 ? "" : "s"}:',
      contextLine: context?.summaryLine,
      previewItems: previewLines,
      steps: steps,
      primaryAction: const StudentAssistantAction(
        id: 'act_view_risks',
        type: AssistantActionType.openProgress,
        label: 'View Progress Insights',
      ),
    );
  }

  StudentAssistantResult _handleShowGoals(
    StudentAssistantIntent intent, {
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
  }) {
    final summary = StudentOSIntelligenceEngine.assessGoalIntelligence(
      goalController: GoalController.instance,
      sessions: sessions,
      tasks: tasks,
    );

    if (summary == null) {
      return const StudentAssistantResult(
        success: true,
        intent: StudentAssistantIntent(rawText: '', intentType: AssistantIntentType.showGoals),
        title: 'No Goals Set',
        message: 'Set a weekly study hour or task completion goal to track progress.',
        primaryAction: StudentAssistantAction(
          id: 'act_open_goals',
          type: AssistantActionType.openGoals,
          label: 'Set Goals',
        ),
      );
    }

    final studyProgressPct = (summary.studyProgressFraction * 100).round();
    final taskProgressPct = (summary.taskProgressFraction * 100).round();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: summary.personalGoal.isNotEmpty ? summary.personalGoal : 'Weekly Academic Goal',
      message: 'Study target: ${summary.weeklyStudyActualMinutes}m of ${summary.weeklyStudyTargetMinutes}m ($studyProgressPct%)\nTasks target: ${summary.weeklyTaskActual} of ${summary.weeklyTaskTarget} ($taskProgressPct%)',
      primaryAction: const StudentAssistantAction(
        id: 'act_open_goals',
        type: AssistantActionType.openGoals,
        label: 'Open Goals Workspace',
      ),
    );
  }

  StudentAssistantResult _handleShowProgress(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
    required List<StudySession> sessions,
    required List<StudentTask> tasks,
  }) {
    if (intent.subjectId != null || intent.subjectName != null) {
      final matchedSubject = subjects.where((s) =>
          s.id == intent.subjectId ||
          (intent.subjectName != null &&
              (s.name.toLowerCase() == intent.subjectName!.toLowerCase() ||
                  s.displayName.toLowerCase() == intent.subjectName!.toLowerCase()))).firstOrNull;

      if (matchedSubject != null) {
        final chapters = AcademicKnowledgeController.instance.chaptersForSubject(matchedSubject.id);
        final topics = AcademicKnowledgeController.instance.topicsForSubject(matchedSubject.id);
        final prog = AcademicKnowledgeEngine.assessSubjectProgress(
          matchedSubject,
          chapters: chapters,
          topics: topics,
          sessions: sessions,
        );

        return StudentAssistantResult(
          success: true,
          intent: intent,
          title: '${matchedSubject.displayName} Progress',
          message: prog.hasSyllabus
              ? 'You have completed ${prog.syllabusPercentage}% (${prog.studiedTopics}/${prog.totalTopics} topics studied).\nRecorded study time: ${prog.totalStudyMinutes}m.'
              : 'Recorded study time: ${prog.totalStudyMinutes}m.',
          primaryAction: StudentAssistantAction(
            id: 'act_open_subj_${matchedSubject.id}',
            type: AssistantActionType.openStudy,
            label: 'View ${matchedSubject.displayName}',
            subjectId: matchedSubject.id,
            subjectName: matchedSubject.displayName,
          ),
        );
      }
    }

    final completedCount = tasks.where((t) => t.isCompleted).length;
    int totalMins = 0;
    for (final s in sessions.where((s) => s.isCompleted)) {
      totalMins += s.durationSec ~/ 60;
    }

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Academic Analytics',
      message: 'Total study time: ${totalMins}m across ${sessions.length} sessions.\nTasks completed: $completedCount.',
      primaryAction: const StudentAssistantAction(
        id: 'act_open_progress',
        type: AssistantActionType.openProgress,
        label: 'View Detailed Analytics',
      ),
    );
  }

  /// Rewards/XP explainer from REAL progression state. No fake numbers:
  /// level, lifetime XP and spendable XP come from [ProgressionController].
  StudentAssistantResult _handleShowRewards(StudentAssistantIntent intent) {
    final progression = ProgressionController.instance;
    final level = progression.currentLevel.level;
    final total = progression.totalXp;
    final spendable = progression.spendableXp;
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Level $level · $spendable XP to spend',
      message:
          'You earn XP by finishing real work — tasks, focus sessions, study. '
          'You have earned $total XP total, with $spendable XP available to unlock cosmetics and themes in the Marketplace. '
          'Levels never drop when you spend.',
      primaryAction: const StudentAssistantAction(
        id: 'act_open_rewards',
        type: AssistantActionType.openRewards,
        label: 'Open Reward Centre',
      ),
    );
  }

  StudentAssistantResult _handleShowTodayPlan(
    StudentAssistantIntent intent, {
    required List<PlanningBlock> blocks,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    final todayBlocks = blocks
        .where((b) =>
            b.startAt.year == now.year &&
            b.startAt.month == now.month &&
            b.startAt.day == now.day)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    if (todayBlocks.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'Today\'s Schedule is Empty',
        message: 'No planning blocks scheduled for today yet.',
        primaryAction: const StudentAssistantAction(
          id: 'act_plan_day',
          type: AssistantActionType.openPlan,
          label: 'Plan My Day',
        ),
      );
    }

    final previewLines = todayBlocks.map((b) {
      final dur = b.endAt.difference(b.startAt).inMinutes;
      final start = '${b.startAt.hour.toString().padLeft(2, "0")}:${b.startAt.minute.toString().padLeft(2, "0")}';
      return '• $start ($dur min) — ${b.customTitle ?? "Scheduled Session"}';
    }).toList();

    final steps = todayBlocks.map((b) {
      final start =
          '${b.startAt.hour.toString().padLeft(2, "0")}:${b.startAt.minute.toString().padLeft(2, "0")}';
      return AssistantResultStep(
        label: _blockTitle(b),
        detail: start,
        minutes: b.endAt.difference(b.startAt).inMinutes,
        id: b.id,
        kind: 'block',
        subjectId: b.subjectId,
        topicId: b.topicId,
        chapterId: b.chapterId,
        taskId: b.taskId,
      );
    }).toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.todayPlan,
      title: 'Today\'s Planned Schedule (${todayBlocks.length} blocks)',
      message: 'Here are your scheduled blocks for today:',
      previewItems: previewLines,
      steps: steps,
      contextLine: context?.summaryLine,
      primaryAction: const StudentAssistantAction(
        id: 'act_open_plan',
        type: AssistantActionType.openPlan,
        label: 'Open Plan Workspace',
      ),
    );
  }

  StudentAssistantResult _handleReschedule(
    StudentAssistantIntent intent, {
    required List<PlanningBlock> blocks,
    required List<StudentTask> tasks,
    required DateTime now,
  }) {
    PlanningBlock? targetBlock;
    if (intent.topicId != null) {
      targetBlock = blocks.where((b) => b.topicId == intent.topicId).firstOrNull;
    } else if (intent.subjectId != null) {
      targetBlock = blocks.where((b) => b.subjectId == intent.subjectId).firstOrNull;
    } else if (intent.taskId != null) {
      targetBlock = blocks.where((b) => b.taskId == intent.taskId).firstOrNull;
    }

    if (targetBlock == null) {
      final todayBlocks = blocks
          .where((b) =>
              b.startAt.year == now.year &&
              b.startAt.month == now.month &&
              b.startAt.day == now.day &&
              b.startAt.isAfter(now))
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));

      targetBlock = todayBlocks.firstOrNull;
    }

    if (targetBlock == null) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Nothing to Reschedule',
        message: 'No upcoming scheduled session found to move to tomorrow.',
      );
    }

    final targetDate = intent.targetDate ?? now.add(const Duration(days: 1));
    final duration = targetBlock.endAt.difference(targetBlock.startAt);
    final title = targetBlock.customTitle ?? 'Scheduled Session';

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Move Session to Tomorrow',
      message: 'Move "$title" (${duration.inMinutes}m) from today to tomorrow?',
      requiresConfirmation: true,
      primaryAction: StudentAssistantAction(
        id: 'act_confirm_reschedule',
        type: AssistantActionType.reschedule,
        label: 'Confirm Reschedule',
        planningBlockId: targetBlock.id,
        targetDate: targetDate,
        duration: duration,
        requiresConfirmation: true,
      ),
    );
  }

  StudentAssistantResult _handleRecoverMissedSession(
    StudentAssistantIntent intent, {
    required List<PlanningBlock> blocks,
    required List<StudentTask> tasks,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    final missed = PlanningEngine.getMissedSessions(
      blocks: blocks,
      tasks: tasks,
      referenceTime: now,
    );

    if (missed.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'Nothing to Recover',
        message:
            'You have no uncompleted blocks from earlier today. You are on track.',
        contextLine: context?.summaryLine,
      );
    }

    final topMissed = missed.first;

    // Authoritative recovery slots from the existing planning engine.
    final slots = PlanningEngine.findRecoverySlots(
      topMissed.block,
      referenceTime: now,
      limit: 3,
    );

    if (slots.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        cardKind: AssistantCardKind.empty,
        title: 'No Recovery Slot Found',
        message:
            'There is no free slot long enough for "${topMissed.title}" in the next few days. Free some time or shorten the block.',
        contextLine: context?.summaryLine,
        primaryAction: const StudentAssistantAction(
          id: 'act_open_plan_recover',
          type: AssistantActionType.openPlan,
          label: 'Open Plan',
        ),
      );
    }

    String clock(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    String dayLabel(DateTime d) {
      final tomorrow = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1));
      if (_isSameDay(d, now)) return 'today';
      if (_isSameDay(d, tomorrow)) return 'tomorrow';
      return 'in ${d.difference(now).inDays} days';
    }

    final steps = slots
        .map((s) {
          final end = s.add(Duration(minutes: topMissed.durationMinutes));
          return AssistantResultStep(
            label: '${clock(s)}\u2013${clock(end)}',
            detail: dayLabel(s),
            minutes: topMissed.durationMinutes,
            id: s.toIso8601String(),
            kind: 'block',
          );
        })
        .toList();

    final optionLines = steps
        .map((s) => '• ${s.label} ${s.detail != null ? "(${s.detail})" : ""}')
        .toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      cardKind: AssistantCardKind.schedulePreview,
      title: 'Recover Missed Session',
      message:
          'You missed "${topMissed.title}" (${topMissed.durationMinutes}m). I found ${slots.length} free slot${slots.length == 1 ? "" : "s"}:',
      previewItems: optionLines,
      steps: steps,
      contextLine: context?.summaryLine,
      requiresConfirmation: true,
      primaryAction: StudentAssistantAction(
        id: 'act_recover_session',
        type: AssistantActionType.recover,
        label: 'Reschedule "${topMissed.title}"',
        planningBlockId: topMissed.block.id,
        duration: Duration(minutes: topMissed.durationMinutes),
        requiresConfirmation: true,
      ),
    );
  }

  StudentAssistantResult _handleRebalanceDay(
    StudentAssistantIntent intent, {
    required List<PlanningBlock> blocks,
    required List<StudentTask> tasks,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    // Fix My Day (P2): compare remaining planned work against time left
    // before the sleep boundary. Keep what fits, move the rest to
    // tomorrow — only with confirmation.
    final sleep = _readSleep();
    var available = 180;
    if (sleep != null) {
      final bed = SleepScheduleValidation.normaliseMinutes(
        sleep.bedtimeMinutes,
      );
      var bedtime = DateTime(now.year, now.month, now.day, bed ~/ 60, bed % 60);
      if (!bedtime.isAfter(now)) {
        bedtime = bedtime.add(const Duration(days: 1));
      }
      available = bedtime.difference(now).inMinutes.clamp(0, 720);
    }

    final today = DateTime(now.year, now.month, now.day);
    final dueToday = tasks.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return !due.isAfter(today);
    }).toList();
    final remaining = dueToday.fold<int>(
      0,
      (sum, t) => sum + (t.estimatedMinutes > 0 ? t.estimatedMinutes : 30),
    );

    if (remaining <= available || dueToday.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Day Looks Fixable',
        message: dueToday.isEmpty
            ? 'Nothing is due today. Your day is clear.'
            : 'Your ${remaining}m of due work fits in the ~${available}m left today. No changes needed.',
        cardKind: AssistantCardKind.success,
        contextLine: _sleepContextLine(sleep, context),
      );
    }

    final ranked = AssistantPlanningEngine.rankTasks(dueToday, now, const []);
    final keep = <StudentTask>[];
    final move = <StudentTask>[];
    var kept = 0;
    for (final t in ranked) {
      final minutes = t.estimatedMinutes > 0 ? t.estimatedMinutes : 30;
      if (kept + minutes <= available) {
        keep.add(t);
        kept += minutes;
      } else {
        move.add(t);
      }
    }
    final tomorrow = today.add(const Duration(days: 1));
    final moves = move.take(6).map((t) {
      return PlannedMove(
        taskId: t.id,
        taskTitle: t.title,
        fromDate: t.dueDate,
        toDate: tomorrow,
        reason: 'Lowest priority — freed today',
      );
    }).toList();
    final plan = AssistantDayPlan(
      kind: AssistantProposalKind.fixDay,
      sessions: const [],
      moves: moves,
      unscheduled: [
        if (move.length > moves.length)
          '${move.length - moves.length} more item(s) left for manual planning.',
      ],
      budgetMinutes: available,
      sleepNote: sleep != null
          ? 'Your ${sleep.windowLabel} sleep is protected.'
          : null,
      anchoredStart: now,
    );
    return _previewProposal(
      intent: intent,
      plan: plan,
      title: 'Fix My Day',
      message:
          '${remaining}m remaining but ~${available}m available. Keeping ${keep.length} item${keep.length == 1 ? '' : 's'}, moving ${moves.length}.',
      contextLine: _sleepContextLine(sleep, context),
      applyLabel: 'Apply Changes',
    );
  }

  String? _sleepContextLine(
    SleepSchedule? sleep,
    AssistantContextSnapshot? context,
  ) {
    final parts = <String>[
      if (sleep != null) 'Sleep ${sleep.windowLabel}',
      if (context?.summaryLine != null) context?.summaryLine ?? '',
    ];
    final line = parts.join(' · ');
    return line.isEmpty ? null : line;
  }

  StudentAssistantResult _handleTaskAction(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
  }) {
    if (intent.taskId != null) {
      final task = tasks.where((t) => t.id == intent.taskId).firstOrNull;
      if (task != null) {
        if (intent.intentType == AssistantIntentType.completeTask) {
          return StudentAssistantResult(
            success: true,
            intent: intent,
            title: 'Complete Task',
            message: 'Mark "${task.title}" as completed?',
            requiresConfirmation: true,
            primaryAction: StudentAssistantAction(
              id: 'act_complete_task',
              type: AssistantActionType.completeTask,
              label: 'Mark Complete',
              taskId: task.id,
              requiresConfirmation: true,
            ),
          );
        } else {
          final dur = Duration(minutes: task.estimatedMinutes > 0 ? task.estimatedMinutes : 25);
          return StudentAssistantResult(
            success: true,
            intent: intent,
            title: 'Start Task: ${task.title}',
            message: 'Ready for a ${dur.inMinutes} min focused work session.',
            primaryAction: StudentAssistantAction(
              id: 'act_start_task',
              type: AssistantActionType.startTask,
              label: 'Start Task (${dur.inMinutes}m)',
              taskId: task.id,
              taskTitle: task.title,
              subjectId: task.subjectId,
              examId: task.examId,
              duration: dur,
            ),
          );
        }
      }
    }

    final nextTask = tasks.where((t) => !t.isCompleted).firstOrNull;
    if (nextTask != null) {
      final dur = Duration(minutes: nextTask.estimatedMinutes > 0 ? nextTask.estimatedMinutes : 25);
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Next Task: ${nextTask.title}',
        message: 'Highest priority active task.',
        primaryAction: StudentAssistantAction(
          id: 'act_start_task',
          type: AssistantActionType.startTask,
          label: 'Start (${dur.inMinutes}m)',
          taskId: nextTask.id,
          taskTitle: nextTask.title,
          subjectId: nextTask.subjectId,
          examId: nextTask.examId,
          duration: dur,
        ),
      );
    }

    return const StudentAssistantResult(
      success: true,
      intent: StudentAssistantIntent(rawText: '', intentType: AssistantIntentType.showTasks),
      title: 'No Pending Tasks',
      message: 'All tasks completed.',
    );
  }

  StudentAssistantResult _handlePracticeTopic(
    StudentAssistantIntent intent, {
    required List<Topic> topics,
    required List<Subject> subjects,
  }) {
    Topic? targetTopic;
    if (intent.topicId != null) {
      targetTopic = topics.where((t) => t.id == intent.topicId).firstOrNull;
    } else if (intent.topicName != null && intent.topicName!.isNotEmpty) {
      final name = intent.topicName!.toLowerCase();
      targetTopic = topics
          .where((t) => t.title.toLowerCase().contains(name))
          .firstOrNull;
    }

    if (targetTopic == null && intent.subjectId != null) {
      final subjectTopics =
          topics.where((t) => t.subjectId == intent.subjectId).toList();
      targetTopic = subjectTopics.firstOrNull;
    }

    if (targetTopic == null) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Practice Center',
        message: 'Explore practice questions and quiz sets across your curriculum.',
        primaryAction: const StudentAssistantAction(
          id: 'act_open_practice',
          type: AssistantActionType.openPractice,
          label: 'Open Practice Center',
        ),
      );
    }

    final questions =
        PracticeQuestionController.instance.questionsForTopic(targetTopic.id);
    final subject =
        subjects.where((s) => s.id == targetTopic!.subjectId).firstOrNull;

    if (questions.isNotEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Practice ${targetTopic.title}',
        message:
            '${questions.length} question(s) available for ${subject?.displayName ?? "Curriculum"}.',
        primaryAction: StudentAssistantAction(
          id: 'act_start_practice_${targetTopic.id}',
          type: AssistantActionType.startPractice,
          label: 'Start Practice (${questions.length} Qs)',
          topicId: targetTopic.id,
          chapterId: targetTopic.chapterId,
          subjectId: targetTopic.subjectId,
          topicTitle: targetTopic.title,
        ),
      );
    } else {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Practice for ${targetTopic.title}',
        message:
            'No interactive questions are available for "${targetTopic.title}" yet. You can record a practice attempt or add questions in the Practice Center.',
        primaryAction: StudentAssistantAction(
          id: 'act_practice_center',
          type: AssistantActionType.openPractice,
          label: 'Open Practice Center',
          topicId: targetTopic.id,
          chapterId: targetTopic.chapterId,
          subjectId: targetTopic.subjectId,
          topicTitle: targetTopic.title,
        ),
      );
    }
  }

  StudentAssistantResult _handlePracticeWeakest(
    StudentAssistantIntent intent, {
    required List<Topic> topics,
    required List<Subject> subjects,
    required List<StudySession> sessions,
    required DateTime now,
  }) {
    final attempts = TopicPracticeController.instance.attempts;
    final weakTopics = AcademicKnowledgeEngine.getWeakTopics(
      topics: topics,
      sessions: sessions,
      practiceAttempts: attempts,
      referenceTime: now,
    );

    if (weakTopics.isNotEmpty) {
      final topWeak = weakTopics.first;
      final acc = topWeak.practiceAccuracyPercentage;
      final accText = acc != null ? '$acc% accuracy' : 'Needs practice';

      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Weak Topic: ${topWeak.topic.title}',
        message: '${topWeak.weakTopicReason ?? "Identified as needing practice"} ($accText).',
        primaryAction: StudentAssistantAction(
          id: 'act_practice_weak_${topWeak.topic.id}',
          type: AssistantActionType.startPractice,
          label: 'Practice ${topWeak.topic.title}',
          topicId: topWeak.topic.id,
          chapterId: topWeak.topic.chapterId,
          subjectId: topWeak.topic.subjectId,
          topicTitle: topWeak.topic.title,
        ),
      );
    }

    final recommended = AcademicKnowledgeEngine.getRecommendedPracticeTopics(
      topics: topics,
      sessions: sessions,
      practiceAttempts: attempts,
      referenceTime: now,
    );

    if (recommended.isNotEmpty) {
      final topRec = recommended.first;
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Recommended: ${topRec.topic.title}',
        message: topRec.recommendationReason ?? 'Great opportunity for practice.',
        primaryAction: StudentAssistantAction(
          id: 'act_practice_rec_${topRec.topic.id}',
          type: AssistantActionType.startPractice,
          label: 'Practice ${topRec.topic.title}',
          topicId: topRec.topic.id,
          chapterId: topRec.topic.chapterId,
          subjectId: topRec.topic.subjectId,
          topicTitle: topRec.topic.title,
        ),
      );
    }

    return const StudentAssistantResult(
      success: true,
      intent: StudentAssistantIntent(rawText: '', intentType: AssistantIntentType.practiceWeakest),
      title: 'Practice Up to Date',
      message: 'You have no weak topics flagged for urgent practice. Explore topics in the Practice Center.',
      primaryAction: StudentAssistantAction(
        id: 'act_open_practice',
        type: AssistantActionType.openPractice,
        label: 'Open Practice Center',
      ),
    );
  }

  StudentAssistantResult _handleShowPracticeHistory(
    StudentAssistantIntent intent,
  ) {
    final attempts = TopicPracticeController.instance.attempts;
    if (attempts.isEmpty) {
      return const StudentAssistantResult(
        success: true,
        intent: StudentAssistantIntent(rawText: '', intentType: AssistantIntentType.showPracticeHistory),
        title: 'No Practice Attempts',
        message: 'Complete a quiz or problem solving session to build your practice history.',
        primaryAction: StudentAssistantAction(
          id: 'act_open_practice',
          type: AssistantActionType.openPractice,
          label: 'Open Practice Center',
        ),
      );
    }

    final totalAttempts = attempts.length;
    int totalQ = 0;
    int totalC = 0;
    for (final a in attempts) {
      if (a.totalQuestions != null && a.totalQuestions! > 0) {
        totalQ += a.totalQuestions!;
        totalC += (a.correctAnswers ?? 0);
      }
    }
    final int? avgAcc = totalQ > 0 ? ((totalC / totalQ) * 100).round() : null;

    final previewLines = attempts.take(5).map((a) {
      final top = AcademicKnowledgeController.instance.topicById(a.topicId);
      final acc = a.accuracyPercentage;
      final accStr = acc != null ? '$acc% accuracy' : '${a.durationSec ~/ 60}m';
      return '• ${top?.title ?? "Practice"}: $accStr (${a.totalQuestions ?? 0} questions)';
    }).toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Practice History ($totalAttempts attempts)',
      message: avgAcc != null
          ? 'Average accuracy: $avgAcc% across $totalQ questions attempted.'
          : 'Total sessions completed: $totalAttempts.',
      previewItems: previewLines,
      primaryAction: const StudentAssistantAction(
        id: 'act_open_practice',
        type: AssistantActionType.openPractice,
        label: 'View Practice Center',
      ),
    );
  }

  StudentAssistantResult _handleUnknown(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
  }) {
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'I\'m not sure about that',
      message: 'Try asking "What should I study?", "I have 2 hours", or "What should I revise?".',
      suggestedPrompts: const [
        'What should I do?',
        'I have 2 hours',
        'What should I revise?',
        'Show my exams',
      ],
    );
  }

  // ─── Execution ──────────────────────────────────────────────────────

  /// Executes an assistant action through authoritative controllers.
  Future<void> executeAction(
    BuildContext context,
    StudentAssistantAction action,
  ) async {
    final fc = FocusController.instance;

    switch (action.type) {
      case AssistantActionType.none:
        break;

      case AssistantActionType.openHome:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;

      case AssistantActionType.openPlan:
        AppRouter.openPlan(context);
        break;

      case AssistantActionType.openStudy:
        AppRouter.openStudy(context);
        break;

      case AssistantActionType.openFocus:
        AppRouter.openFocusCenter(context);
        break;

      case AssistantActionType.openTasks:
        AppRouter.openTasks(context);
        break;

      case AssistantActionType.openExams:
        AppRouter.openExams(context);
        break;

      case AssistantActionType.openGoals:
        AppRouter.openGoals(context);
        break;

      case AssistantActionType.openProgress:
        AppRouter.openProgress(context);
        break;

      case AssistantActionType.openRevision:
        AppRouter.openRevision(context);
        break;

      case AssistantActionType.startFocus:
        if (fc.hasActiveSession) {
          AppRouter.openActiveFocusSession(context);
        } else {
          AppRouter.startContextualFocus(
            context,
            duration: action.duration ?? const Duration(minutes: 25),
            subjectId: action.subjectId,
            subjectName: action.subjectName,
            taskId: action.taskId,
            examId: action.examId,
            topicId: action.topicId,
            chapterId: action.chapterId,
            focusTitle: action.topicTitle ?? action.label,
          );
        }
        break;

      case AssistantActionType.startTopic:
      case AssistantActionType.startPlan:
        if (fc.hasActiveSession) {
          AppRouter.openActiveFocusSession(context);
        } else {
          AppRouter.startContextualFocus(
            context,
            duration: action.duration ?? const Duration(minutes: 35),
            subjectId: action.subjectId,
            subjectName: action.subjectName,
            topicId: action.topicId,
            chapterId: action.chapterId,
            taskId: action.taskId,
            examId: action.examId,
            focusTitle: action.topicTitle ?? action.label,
          );
        }
        break;

      case AssistantActionType.startRevision:
        if (action.topicId != null) {
          final topic = AcademicKnowledgeController.instance.topicById(action.topicId!);
          if (topic != null) {
            RevisionSessionScreen.open(
              context,
              topic: topic,
              suggestedDurationMinutes: action.duration?.inMinutes ?? 20,
            );
            break;
          }
        }
        if (fc.hasActiveSession) {
          AppRouter.openActiveFocusSession(context);
        } else {
          AppRouter.startContextualFocus(
            context,
            duration: action.duration ?? const Duration(minutes: 20),
            subjectId: action.subjectId,
            subjectName: action.subjectName,
            topicId: action.topicId,
            chapterId: action.chapterId,
            taskId: action.taskId,
            examId: action.examId,
            focusTitle: action.topicTitle ?? action.label,
          );
        }
        break;

      case AssistantActionType.startTask:
        if (fc.hasActiveSession) {
          AppRouter.openActiveFocusSession(context);
        } else {
          AppRouter.startContextualFocus(
            context,
            duration: action.duration ?? const Duration(minutes: 25),
            taskId: action.taskId,
            subjectId: action.subjectId,
            examId: action.examId,
            focusTitle: action.taskTitle ?? action.label,
          );
        }
        break;

      case AssistantActionType.startPlanningBlock:
        if (action.planningBlockId != null) {
          final block = PlanningBlockController.instance.blocks
              .where((b) => b.id == action.planningBlockId)
              .firstOrNull;
          if (block != null) {
            AppRouter.startPlanningBlockFocus(context, block);
          }
        }
        break;

      case AssistantActionType.applyPlan:
        UniversalActionExecutor.openPlanMyDay(context);
        break;

      case AssistantActionType.reschedule:
        if (action.planningBlockId != null && action.targetDate != null) {
          final block = PlanningBlockController.instance.blocks
              .where((b) => b.id == action.planningBlockId)
              .firstOrNull;
          if (block != null) {
            final newStart = DateTime(
              action.targetDate!.year,
              action.targetDate!.month,
              action.targetDate!.day,
              block.startAt.hour,
              block.startAt.minute,
            );
            final newEnd = newStart.add(block.endAt.difference(block.startAt));
            await PlanningBlockController.instance.rescheduleBlock(
              block.id,
              newStart,
              newEnd,
            );
          }
        }
        break;

      case AssistantActionType.recover:
        if (action.planningBlockId != null) {
          final block = PlanningBlockController.instance.blocks
              .where((b) => b.id == action.planningBlockId)
              .firstOrNull;
          if (block != null) {
            final dur = block.endAt.difference(block.startAt).inMinutes;
            final missed = MissedSession(
              block: block,
              title: block.customTitle ?? 'Missed Session',
              durationMinutes: dur,
              scheduledStart: block.startAt,
              scheduledEnd: block.endAt,
            );
            await PlanningEngine.rescheduleMissedSession(missed);
          }
        }
        break;

      case AssistantActionType.rebalance:
        await PlanningEngine.rebalanceOverloadedDay(
          DateTime.now(),
          tasks: TaskController.instance.tasks,
        );
        break;

      case AssistantActionType.completeTask:
        if (action.taskId != null) {
          await TaskController.instance.completeTask(action.taskId!);
        }
        break;

      case AssistantActionType.createTask:
        if (action.taskTitle != null && action.taskTitle!.trim().isNotEmpty) {
          await TaskController.instance.createTask(
            title: action.taskTitle!,
            dueDate: action.targetDate,
            priority: _parsePriority(action.taskPriority),
            subjectId: action.subjectId,
            estimatedMinutes: action.duration?.inMinutes ?? 30,
          );
        }
        break;

      case AssistantActionType.rescheduleTask:
        if (action.taskId != null && action.targetDate != null) {
          final task = TaskController.instance.tasks
              .where((t) => t.id == action.taskId)
              .firstOrNull;
          if (task != null) {
            await TaskController.instance.updateTask(
              task.copyWith(dueDate: action.targetDate),
            );
          }
        }
        break;

      case AssistantActionType.prioritizeTask:
        if (action.taskId != null) {
          await TaskController.instance.changePriority(
            action.taskId!,
            _parsePriority(action.taskPriority),
          );
        }
        break;

      case AssistantActionType.breakTask:
        if (action.taskId != null) {
          final count = (action.subtaskCount ?? 3).clamp(2, 7);
          final task = TaskController.instance.tasks
              .where((t) => t.id == action.taskId)
              .firstOrNull;
          if (task != null) {
            for (var i = 1; i <= count; i++) {
              await TaskController.instance.addSubtask(
                task.id,
                '${task.title} · Part $i of $count',
              );
            }
          }
        }
        break;

      case AssistantActionType.updateExamDate:
        if (action.examId != null && action.targetDate != null) {
          final exam = ExamController.instance.exams
              .where((e) => e.id == action.examId)
              .firstOrNull;
          if (exam != null) {
            final day = action.targetDate!;
            final previous = exam.examDateTime;
            await ExamController.instance.updateExam(
              exam.copyWith(
                examDateTime: DateTime(
                  day.year,
                  day.month,
                  day.day,
                  previous?.hour ?? 9,
                  previous?.minute ?? 0,
                ),
              ),
            );
          }
        }
        break;

      case AssistantActionType.openPractice:
        AppRouter.openPracticeCenter(context);
        break;

      case AssistantActionType.openRewards:
        AppRouter.openRewards(context);
        break;

      case AssistantActionType.startPractice:
        if (action.topicId != null) {
          final topic = AcademicKnowledgeController.instance.topicById(action.topicId!);
          if (topic != null) {
            PracticeModeSelectionSheet.show(context, topic: topic);
          } else {
            AppRouter.openPracticeCenter(context);
          }
        } else {
          AppRouter.openPracticeCenter(context);
        }
        break;

      case AssistantActionType.openCalendar:
        AppRouter.openCalendar(context, initialDate: action.targetDate);
        break;

      case AssistantActionType.resolveConflict:
        final conflicts = AcademicScheduleController.instance
            .detectConflicts(action.targetDate ?? DateTime.now());
        if (conflicts.isNotEmpty) {
          await AcademicScheduleController.instance
              .reschedulePlanningConflict(conflicts.first);
        }
        break;

      case AssistantActionType.openKnowledge:
        AppRouter.openKnowledgeCenter(context, initialSubjectId: action.subjectId);
        break;

      case AssistantActionType.openNote:
        if (action.noteId != null) {
          AppRouter.openNoteDetail(context, action.noteId!);
        } else {
          AppRouter.openKnowledgeCenter(context, initialSubjectId: action.subjectId);
        }
        break;

      case AssistantActionType.createNote:
        AppRouter.openNoteEditor(
          context,
          subjectId: action.subjectId,
          chapterId: action.chapterId,
          topicId: action.topicId,
          initialTitle: action.noteTitle,
        );
        break;

      case AssistantActionType.searchNotes:
        AppRouter.openKnowledgeCenter(context, initialSubjectId: action.subjectId);
        break;

      case AssistantActionType.openCourseSelection:
        AppRouter.openCourseSelection(context);
        break;

      case AssistantActionType.scheduleTopic:
        // Route into the shared TopicPlanSheet so scheduling always goes
        // through PlanningBlockController — never a second store.
        final topicId = action.topicId;
        if (topicId != null) {
          final topic = AcademicKnowledgeController.instance.topicById(topicId);
          if (topic != null) {
            AppRouter.openTopicPlan(context, topic);
          } else {
            AppRouter.openPlan(context);
          }
        } else {
          AppRouter.openPlan(context);
        }
        break;

      case AssistantActionType.stopFocus:
        FocusController.instance.stopSession();
        break;

      case AssistantActionType.openStudentLife:
        AppRouter.openStudentLife(context);
        break;

      case AssistantActionType.openSleepSchedule:
        AppRouter.openSleepSchedule(context);
        break;

      case AssistantActionType.updateSleepSchedule:
        final bed = action.sleepBedtimeMinutes;
        final wake = action.sleepWakeMinutes;
        if (bed != null && wake != null) {
          await SleepController.instance.saveSchedule(
            (SleepController.instance.schedule ??
                    const SleepSchedule())
                .copyWith(
              bedtimeMinutes: bed,
              wakeMinutes: wake,
              enabled: true,
            ),
          );
        }
        break;

      case AssistantActionType.startWindDown:
        AppRouter.openStudentLife(context);
        break;
    }
  }

  // ─── Student Life Handlers (Phase 5) ─────────────────────────────────

  StudentAssistantResult _handleShowStudentLife(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final controller = StudentLifeController.instance;
    final plan = controller.dailyPlan(now);
    final items = plan.routineItems;

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: "Today's Routine",
      message: items.isEmpty
          ? 'No routine items yet. Open Student Life to set your sleep and routine preferences.'
          : 'Your routine has ${items.length} item${items.length == 1 ? '' : 's'}, with bedtime at '
              '${StudentLifePreferences.formatClock(plan.sleepWindowStart.hour * 60 + plan.sleepWindowStart.minute)}.',
      cardKind: items.isEmpty
          ? AssistantCardKind.empty
          : AssistantCardKind.recommendation,
      contextLine: 'Bedtime ${StudentLifePreferences.formatClock(plan.sleepWindowStart.hour * 60 + plan.sleepWindowStart.minute)}'
          ' · ${plan.sleepWindowMinutes}m window',
      steps: items
          .take(6)
          .map(
            (i) => AssistantResultStep(
              id: i.id,
              kind: 'routine',
              label: i.title,
              detail: i.detail,
              minutes: i.durationMinutes,
            ),
          )
          .toList(),
      primaryAction: const StudentAssistantAction(
        id: 'act_open_student_life',
        type: AssistantActionType.openStudentLife,
        label: 'Open Student Life',
      ),
      suggestedPrompts: const [
        'How did I sleep?',
        'Start winding down',
        'What should I do?',
      ],
    );
  }

  StudentAssistantResult _handleShowSleepSummary(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final controller = StudentLifeController.instance;
    final summary = controller.sleepSummary();

    if (!summary.hasData) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Sleep Logged Yet',
        message:
            'Sleep is logged manually, so nothing is recorded yet. Add last night\'s sleep to see your summary.',
        cardKind: AssistantCardKind.empty,
        primaryAction: const StudentAssistantAction(
          id: 'act_open_student_life',
          type: AssistantActionType.openStudentLife,
          label: 'Log Sleep',
        ),
        suggestedPrompts: const [
          'Show my routine',
          'What should I do?',
        ],
      );
    }

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Sleep Summary',
      message:
          'Last night ${summary.lastNightLabel}. Your ${summary.nightsLogged}-night average is ${summary.averageLabel}.',
      cardKind: AssistantCardKind.recommendation,
      contextLine: summary.lastNightBedtime != null
          ? 'Bed ${StudentLifePreferences.formatClock(summary.lastNightBedtime!.hour * 60 + summary.lastNightBedtime!.minute)}'
              ' · Wake ${StudentLifePreferences.formatClock(summary.lastNightWake!.hour * 60 + summary.lastNightWake!.minute)}'
          : null,
      steps: [
        AssistantResultStep(
          id: 'sleep_last',
          kind: 'sleep',
          label: 'Last night',
          detail: summary.lastNightLabel,
          minutes: summary.lastNightMinutes,
        ),
        AssistantResultStep(
          id: 'sleep_average',
          kind: 'sleep',
          label: 'Average',
          detail: summary.averageLabel,
          minutes: summary.averageNightMinutes,
        ),
        AssistantResultStep(
          id: 'sleep_consistency',
          kind: 'sleep',
          label: 'Nights near target bedtime',
          detail: '${summary.consistencyDays} of ${summary.nightsLogged}',
        ),
      ],
      primaryAction: const StudentAssistantAction(
        id: 'act_open_student_life',
        type: AssistantActionType.openStudentLife,
        label: 'Open Student Life',
      ),
      suggestedPrompts: const [
        'Show my routine',
        'What should I do?',
      ],
    );
  }

  StudentAssistantResult _handleStartWindDown(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final controller = StudentLifeController.instance;
    final plan = controller.dailyPlan(now);
    final bedtime = StudentLifePreferences.formatClock(
      plan.sleepWindowStart.hour * 60 + plan.sleepWindowStart.minute,
    );
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Start Winding Down',
      message:
          'Your wind-down runs ${controller.preferences.windDownMinutes} minutes before your $bedtime bedtime. Optional tasks after that time are reduced to protect your sleep.',
      cardKind: AssistantCardKind.nextAction,
      contextLine: 'Bedtime $bedtime'
          '${plan.warnings.isEmpty ? '' : ' · ${plan.warnings.length} note${plan.warnings.length == 1 ? '' : 's'}'}',
      primaryAction: const StudentAssistantAction(
        id: 'act_wind_down',
        type: AssistantActionType.startWindDown,
        label: 'Open Student Life',
      ),
      suggestedPrompts: const [
        'Show my routine',
        'What should I do?',
      ],
    );
  }

  // ─── P1 Sleep Schedule Handlers ────────────────────────────────────
  //
  // The planned sleep window (bedtime/wake/days), distinct from logged sleep
  // in Student Life. Proposals always go through the confirmation gate;
  // nothing is written without the student tapping Confirm.

  StudentAssistantResult _handleOpenSleepSchedule(
    StudentAssistantIntent intent,
  ) {
    final schedule = SleepController.instance.schedule;
    if (schedule == null) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Sleep Schedule Yet',
        message:
            'Set your sleep schedule so Student OS can plan your day around it.',
        cardKind: AssistantCardKind.empty,
        primaryAction: const StudentAssistantAction(
          id: 'act_open_sleep_schedule',
          type: AssistantActionType.openSleepSchedule,
          label: 'Set Sleep Schedule',
        ),
        suggestedPrompts: const [
          'What should I do now?',
          'Plan my day',
        ],
      );
    }
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Sleep Schedule',
      message:
          'Planned sleep ${schedule.windowLabel} (${schedule.durationLabel})'
          '${schedule.enabled ? '' : ' — currently paused'}.',
      cardKind: AssistantCardKind.recommendation,
      contextLine: 'Sleep ${schedule.windowLabel} · ${schedule.durationLabel}',
      primaryAction: const StudentAssistantAction(
        id: 'act_open_sleep_schedule',
        type: AssistantActionType.openSleepSchedule,
        label: 'Edit Schedule',
      ),
      suggestedPrompts: const [
        'Plan my day',
        'What should I do now?',
      ],
    );
  }

  StudentAssistantResult _handleUpdateSleepSchedule(
    StudentAssistantIntent intent,
  ) {
    final bed = intent.bedtimeMinutes;
    final wake = intent.wakeMinutes;
    final current = _readSleep();

    // Single-field updates keep the other end of the existing window.
    if ((bed == null) != (wake == null) && current != null) {
      final newBed = bed ?? current.bedtimeMinutes;
      final newWake = wake ?? current.wakeMinutes;
      final error = SleepScheduleValidation.validate(
        bedtimeMinutes: newBed,
        wakeMinutes: newWake,
      );
      if (error != null) {
        return StudentAssistantResult(
          success: false,
          intent: intent,
          title: 'Can\'t Use That Time',
          message: error,
          cardKind: AssistantCardKind.error,
        );
      }
      final window =
          '${SleepScheduleValidation.formatClock12(newBed)} → ${SleepScheduleValidation.formatClock12(newWake)}';
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Update Sleep Schedule?',
        message: 'I can change your sleep schedule to $window.',
        cardKind: AssistantCardKind.confirmation,
        contextLine: 'Sleep $window',
        requiresConfirmation: true,
        primaryAction: StudentAssistantAction(
          id: 'act_update_sleep_schedule',
          type: AssistantActionType.updateSleepSchedule,
          label: 'Confirm',
          requiresConfirmation: true,
          sleepBedtimeMinutes: newBed,
          sleepWakeMinutes: newWake,
        ),
      );
    }

    // "I want 8 hours of sleep" → need a wake time first.
    if (bed == null && wake == null) {
      final duration = intent.durationMinutes;
      if (duration != null && duration > 0 && current != null) {
        final h = duration ~/ 60;
        final m = duration % 60;
        final durLabel = m == 0 ? '${h}h' : '${h}h ${m}m';
        final currentWake = SleepScheduleValidation.formatClock12(
          current.wakeMinutes,
        );
        return StudentAssistantResult(
          success: true,
          intent: intent,
          title: 'What Wake Time?',
          message:
              'I can suggest a $durLabel window based on your preferred wake time. What time do you want to wake up?',
          cardKind: AssistantCardKind.clarification,
          clarificationRequired: true,
          clarificationQuestion:
              'What time do you want to wake up for $durLabel of sleep?',
          clarificationChoices: [
            'Wake at $currentWake',
            'Wake at 6 AM',
            'Wake at 7 AM',
          ],
        );
      }
      return _handleOpenSleepSchedule(intent);
    }

    if (bed == null || wake == null) {
      return _handleOpenSleepSchedule(intent);
    }
    final error = SleepScheduleValidation.validate(
      bedtimeMinutes: bed,
      wakeMinutes: wake,
    );
    if (error != null) {
      return StudentAssistantResult(
        success: false,
        intent: intent,
        title: 'Can\'t Use Those Times',
        message: '$error Tell me a different window, or set it on the schedule screen.',
        cardKind: AssistantCardKind.error,
        primaryAction: const StudentAssistantAction(
          id: 'act_open_sleep_schedule',
          type: AssistantActionType.openSleepSchedule,
          label: 'Open Schedule',
        ),
      );
    }
    final window =
        '${SleepScheduleValidation.formatClock12(bed)} → ${SleepScheduleValidation.formatClock12(wake)}';
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Set Sleep Schedule?',
      message: 'I can set your sleep schedule to $window.',
      cardKind: AssistantCardKind.confirmation,
      contextLine: 'Sleep $window',
      requiresConfirmation: true,
      primaryAction: StudentAssistantAction(
        id: 'act_update_sleep_schedule',
        type: AssistantActionType.updateSleepSchedule,
        label: 'Confirm',
        requiresConfirmation: true,
        sleepBedtimeMinutes: bed,
        sleepWakeMinutes: wake,
      ),
      suggestedPrompts: const [
        'Open sleep schedule',
        'What should I do now?',
      ],
    );
  }

  // ─── P2 Proposal & Task Handlers ───────────────────────────────────
  //
  // Deterministic propose → preview → confirm → execute. The engine never
  // writes: previews carry an AssistantDayPlan proposal; the controller
  // stages it and applies it through existing controllers on Confirm.

  /// Renders a proposal preview card. Shared by every P2 proposer so plan,
  /// fix-day, catch-up, and exam previews look and behave identically.
  StudentAssistantResult _previewProposal({
    required StudentAssistantIntent intent,
    required AssistantDayPlan plan,
    required String title,
    required String message,
    String? contextLine,
    required String applyLabel,
    List<StudentAssistantAction> secondary = const [],
    List<String> prompts = const [
      'What should I do now?',
      'Show today plan',
    ],
  }) {
    final starts = plan.laidOutStarts();
    final steps = <AssistantResultStep>[];
    for (var i = 0; i < plan.sessions.length; i++) {
      final s = plan.sessions[i];
      final start = starts[i];
      steps.add(
        AssistantResultStep(
          id: s.id,
          kind: 'session',
          label: s.title,
          detail:
              '${_fmtRange(start, s.minutes)} · ${s.reason}',
          minutes: s.minutes,
          taskId: s.taskId,
          subjectId: s.subjectId,
          topicId: s.topicId,
          examId: s.examId,
        ),
      );
    }
    for (final m in plan.moves) {
      steps.add(
        AssistantResultStep(
          id: 'move_${m.taskId}',
          kind: 'move',
          label: '→ ${_fmtDay(m.toDate)}: ${m.taskTitle}',
          detail: m.reason,
          taskId: m.taskId,
        ),
      );
    }
    for (var i = 0; i < plan.creations.length; i++) {
      final c = plan.creations[i];
      steps.add(
        AssistantResultStep(
          id: 'create_$i',
          kind: 'create',
          label: c.title,
          detail: [
            if (c.dueDate != null) 'Due ${_fmtDay(c.dueDate!)}',
            '${c.estimatedMinutes} min',
          ].join(' · '),
          minutes: c.estimatedMinutes,
          subjectId: c.subjectId,
        ),
      );
    }

    final footnotes = <String>[
      if (plan.sleepNote != null) plan.sleepNote!,
      ...plan.conflicts,
      ...plan.unscheduled,
      'Reply "remove X" or "make Y first" to adjust before applying.',
    ];

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: title,
      message: message,
      cardKind: AssistantCardKind.schedulePreview,
      contextLine: contextLine,
      steps: steps,
      previewItems: footnotes,
      proposal: plan.isEmpty ? null : plan,
      requiresConfirmation: !plan.isEmpty,
      primaryAction: plan.isEmpty
          ? null
          : StudentAssistantAction(
              id: 'act_apply_proposal',
              type: AssistantActionType.applyPlan,
              label: applyLabel,
              requiresConfirmation: true,
            ),
      secondaryActions: secondary,
      suggestedPrompts: prompts,
    );
  }

  static String _fmtRange(DateTime start, int minutes) {
    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)}–${fmt(start.add(Duration(minutes: minutes)))}';
  }

  static String _fmtDay(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    return names[day.weekday - 1];
  }

  SleepSchedule? _readSleep() {
    try {
      // Preference-gated: sleep-aware planning off means no boundary.
      return DailyAssistantController.effectiveSleepSchedule();
    } catch (_) {
      return null;
    }
  }

  // ─── P2 Task & Proposal Handlers ───────────────────────────────────
  //
  // Single-task commands resolve against live tasks (exact id first, then
  // title match); ambiguity always clarifies with real titles, never a
  // silent guess. Multi-item flows build an AssistantDayPlan proposal that
  // the controller stages until Confirm.

  StudentAssistantResult _handleCreateTask(
    StudentAssistantIntent intent, {
    required List<Subject> subjects,
  }) {
    final title = (intent.taskName ?? '').trim();
    if (title.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'What should the task be called?',
        message:
            'Tell me the task title${intent.targetDate != null ? ' — I\'ll keep ${_fmtDay(intent.targetDate!)} as the date' : ''}.',
        cardKind: AssistantCardKind.clarification,
        clarificationRequired: true,
        clarificationQuestion: 'What should the task be called?',
        clarificationChoices: const [],
      );
    }
    final priority = _parsePriority(intent.taskPriority);
    final lines = [
      title,
      if (intent.targetDate != null) 'Due ${_fmtDay(intent.targetDate!)}',
      if (intent.targetDate == null) 'No date (inbox)',
      'Priority: ${priority.name[0].toUpperCase()}${priority.name.substring(1)}',
      if (intent.subjectName != null && intent.subjectName!.isNotEmpty)
        'Subject: ${intent.subjectName}',
    ];
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Create Task',
      message: lines.join('\n'),
      cardKind: AssistantCardKind.confirmation,
      requiresConfirmation: true,
      primaryAction: StudentAssistantAction(
        id: 'act_create_task',
        type: AssistantActionType.createTask,
        label: 'Create Task',
        taskTitle: title,
        targetDate: intent.targetDate,
        taskPriority: priority.name,
        subjectId: intent.subjectId,
        requiresConfirmation: true,
      ),
      suggestedPrompts: const ['Show my tasks', 'What should I do now?'],
    );
  }

  StudentAssistantResult _handlePrioritizeTask(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
  }) {
    final task = _resolveTask(intent, tasks);
    if (task == null) {
      return _taskNotFound(intent, intent.taskName ?? 'that task');
    }
    final priority = _parsePriority(intent.taskPriority);
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Set Priority',
      message:
          'Set "${task.title}" to ${priority.name.toUpperCase()} priority?',
      cardKind: AssistantCardKind.confirmation,
      requiresConfirmation: true,
      primaryAction: StudentAssistantAction(
        id: 'act_prioritize_task',
        type: AssistantActionType.prioritizeTask,
        label: 'Set ${priority.name.toUpperCase()}',
        taskId: task.id,
        taskTitle: task.title,
        taskPriority: priority.name,
        requiresConfirmation: true,
      ),
    );
  }

  StudentAssistantResult _handleRescheduleTask(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
    required DateTime now,
  }) {
    final task = _resolveTask(intent, tasks);
    if (task == null) {
      return _taskNotFound(intent, intent.taskName ?? 'that task');
    }
    final date = intent.targetDate;
    if (date == null) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Move To When?',
        message: 'Which day should I move "${task.title}" to?',
        cardKind: AssistantCardKind.clarification,
        clarificationRequired: true,
        clarificationQuestion:
            'Which day should I move "${task.title}" to?',
        clarificationChoices: const ['Tomorrow', 'Saturday', 'Sunday'],
      );
    }
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Move Task',
      message: 'Move "${task.title}" to ${_fmtDay(date)}?',
      cardKind: AssistantCardKind.confirmation,
      requiresConfirmation: true,
      primaryAction: StudentAssistantAction(
        id: 'act_reschedule_task',
        type: AssistantActionType.rescheduleTask,
        label: 'Move to ${_fmtDay(date)}',
        taskId: task.id,
        taskTitle: task.title,
        targetDate: date,
        requiresConfirmation: true,
      ),
    );
  }

  StudentAssistantResult _handleBreakTask(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
  }) {
    final task = _resolveTask(intent, tasks);
    if (task == null) {
      return _taskNotFound(intent, intent.taskName ?? 'that task');
    }
    final count = (intent.subtaskCount ?? 3).clamp(2, 7);
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Break Into $count Parts',
      message:
          'Split "${task.title}" into $count smaller subtasks? They stay on the same task.',
      cardKind: AssistantCardKind.confirmation,
      requiresConfirmation: true,
      steps: [
        for (var i = 1; i <= count; i++)
          AssistantResultStep(
            id: 'part_$i',
            kind: 'subtask',
            label: '${task.title} · Part $i of $count',
          ),
      ],
      primaryAction: StudentAssistantAction(
        id: 'act_break_task',
        type: AssistantActionType.breakTask,
        label: 'Create $count Parts',
        taskId: task.id,
        taskTitle: task.title,
        subtaskCount: count,
        requiresConfirmation: true,
      ),
    );
  }

  StudentAssistantResult _handleCatchUp(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
    required List<StudentExam> exams,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final backlog = tasks.where((t) {
      if (t.isCompleted) return false;
      if (t.isOverdue) return true;
      if (t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return !due.isAfter(today.add(const Duration(days: 1)));
    }).toList();
    if (backlog.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Nothing To Catch Up On',
        message: 'No overdue or due-soon tasks. You are clear.',
        cardKind: AssistantCardKind.empty,
        contextLine: context?.summaryLine,
      );
    }
    final ranked = AssistantPlanningEngine.rankTasks(backlog, now, exams);
    final urgent = <StudentTask>[];
    final later = <StudentTask>[];
    for (final t in ranked) {
      if (t.isOverdue ||
          t.priority == TaskPriority.high ||
          t.priority == TaskPriority.critical) {
        urgent.add(t);
      } else {
        later.add(t);
      }
    }
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));
    final moves = <PlannedMove>[];
    for (final t in urgent.take(4)) {
      moves.add(
        PlannedMove(
          taskId: t.id,
          taskTitle: t.title,
          fromDate: t.dueDate,
          toDate: tomorrow,
          reason: t.isOverdue ? 'Overdue — recover first' : 'High priority',
        ),
      );
    }
    for (final t in later.take(4)) {
      moves.add(
        PlannedMove(
          taskId: t.id,
          taskTitle: t.title,
          fromDate: t.dueDate,
          toDate: dayAfter,
          reason: 'Deferred to free today',
        ),
      );
    }
    final leftover = ranked.length - moves.length;
    final plan = AssistantDayPlan(
      kind: AssistantProposalKind.catchUp,
      sessions: const [],
      moves: moves,
      unscheduled: [
        if (leftover > 0)
          '$leftover lower-priority item${leftover == 1 ? '' : 's'} left untouched.',
      ],
      budgetMinutes: 0,
      sleepNote: _sleepNoteOrNull(),
      anchoredStart: now,
    );
    return _previewProposal(
      intent: intent,
      plan: plan,
      title: 'Catch-Up Plan',
      message:
          'Backlog: ${ranked.length} tasks. ${urgent.length} urgent → tomorrow, ${later.take(4).length} → ${_fmtDay(dayAfter)}.',
      contextLine: context?.summaryLine,
      applyLabel: 'Apply Catch-Up Plan',
    );
  }

  StudentAssistantResult _handleExamPlan(
    StudentAssistantIntent intent, {
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<Topic> topics,
    required List<Subject> subjects,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    final match = _matchExam(intent, exams, subjects);
    if (match == null) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Upcoming Exams',
        message:
            'I don\'t see an upcoming exam to plan for. Add your exam first, then ask me again.',
        cardKind: AssistantCardKind.empty,
        contextLine: context?.summaryLine,
      );
    }
    final days = match.daysUntilExam;
    if (days == null) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Exam Has No Date',
        message:
            '“${match.title}” has no date set, so I can\'t spread a plan across days. Set its date first.',
        cardKind: AssistantCardKind.empty,
      );
    }
    if (days <= 0) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Exam Is Here',
        message:
            '“${match.title}” is ${days == 0 ? 'today' : 'already past'} — do a light review of your weakest topics instead of a multi-day plan.',
        cardKind: AssistantCardKind.recommendation,
      );
    }

    final subjectTopics = topics
        .where((t) => _topicMatchesSubject(t, match, subjects))
        .toList();
    final phases = _examPhases(match.title, days, subjectTopics);
    final creations = <PlannedCreation>[];
    var cursor = DateTime(now.year, now.month, now.day);
    for (final phase in phases) {
      cursor = cursor.add(Duration(days: phase.days));
      creations.add(
        PlannedCreation(
          title: '${match.title}: ${phase.label}',
          dueDate: cursor,
          priority: days <= 7 ? TaskPriority.high : TaskPriority.medium,
          estimatedMinutes: 45,
        ),
      );
      if (creations.length >= 6) break;
    }
    final plan = AssistantDayPlan(
      kind: AssistantProposalKind.examPrep,
      sessions: const [],
      creations: creations,
      unscheduled: [
        if (subjectTopics.isEmpty)
          'No topics found for this subject — add topics for a detailed plan.',
      ],
      budgetMinutes: 0,
      anchoredStart: now,
    );
    return _previewProposal(
      intent: intent,
      plan: plan,
      title: 'Exam Plan',
      message:
          '${match.title}\n$days day${days == 1 ? '' : 's'} remaining — ${phases.length} phases.',
      contextLine: context?.summaryLine,
      applyLabel: 'Create ${creations.length} Prep Tasks',
    );
  }

  StudentAssistantResult _handleRevisionPlan(
    StudentAssistantIntent intent, {
    required List<Topic> topics,
    required List<Subject> subjects,
    required List<StudySession> sessions,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    final due = <Topic>[];
    for (final t in topics) {
      try {
        final prog = AcademicKnowledgeEngine.assessTopicProgress(
          t,
          sessions: sessions,
          referenceTime: now,
        );
        if (prog.isRevisionDue) due.add(t);
      } catch (_) {}
    }
    if (due.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Revision Due',
        message:
            'Nothing is flagged for revision right now. Study new topics and I\'ll schedule their revision.',
        cardKind: AssistantCardKind.empty,
        contextLine: context?.summaryLine,
      );
    }
    final picked = due.take(6).toList();
    final today = DateTime(now.year, now.month, now.day);
    final creations = <PlannedCreation>[];
    for (var i = 0; i < picked.length; i++) {
      final topic = picked[i];
      creations.add(
        PlannedCreation(
          title: 'Revise ${topic.title}',
          dueDate: today.add(Duration(days: i ~/ 2)),
          subjectId: topic.subjectId,
          priority: TaskPriority.medium,
          estimatedMinutes: 30,
        ),
      );
    }
    final plan = AssistantDayPlan(
      kind: AssistantProposalKind.revision,
      sessions: const [],
      creations: creations,
      budgetMinutes: 0,
      anchoredStart: now,
    );
    return _previewProposal(
      intent: intent,
      plan: plan,
      title: 'Revision Plan',
      message:
          '${due.length} topic${due.length == 1 ? '' : 's'} due — scheduled ${picked.length} revision sessions across 3 days.',
      contextLine: context?.summaryLine,
      applyLabel: 'Create ${creations.length} Revision Tasks',
    );
  }

  StudentAssistantResult _handleRefinePlan(
    StudentAssistantIntent intent, {
    required AssistantDayPlan? proposal,
  }) {
    if (proposal == null || proposal.isEmpty) {
      return const StudentAssistantResult(
        success: true,
        intent: StudentAssistantIntent(
          rawText: '',
          intentType: AssistantIntentType.planTime,
        ),
        title: 'No Active Proposal',
        message: 'Ask me to plan your day first, then adjust it.',
        cardKind: AssistantCardKind.empty,
      );
    }
    final index = intent.refineIndex ?? -1;
    final op = intent.refineOp;
    final allItems = [
      ...proposal.sessions.map((s) => s.title),
      ...proposal.moves.map((m) => m.taskTitle),
      ...proposal.creations.map((c) => c.title),
    ];
    if (op == null || index < 0 || index >= allItems.length) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Which Item?',
        message: 'Tell me which plan item to change.',
        cardKind: AssistantCardKind.clarification,
        clarificationRequired: true,
        clarificationQuestion: 'Which plan item?',
        clarificationChoices: allItems.take(5).toList(),
      );
    }
    var sessions = List<PlannedSession>.from(proposal.sessions);
    var moves = List<PlannedMove>.from(proposal.moves);
    var creations = List<PlannedCreation>.from(proposal.creations);
    if (op == 'remove') {
      if (index < sessions.length) {
        sessions.removeAt(index);
      } else if (index < sessions.length + moves.length) {
        moves.removeAt(index - sessions.length);
      } else {
        creations.removeAt(index - sessions.length - moves.length);
      }
    } else if (op == 'moveFirst') {
      if (index >= sessions.length) {
        return StudentAssistantResult(
          success: false,
          intent: intent,
          title: 'Can\'t Reorder That',
          message: 'Only planned sessions can be moved first.',
          cardKind: AssistantCardKind.error,
        );
      }
      final item = sessions.removeAt(index);
      sessions = [item, ...sessions];
    }
    final updated = AssistantDayPlan(
      kind: proposal.kind,
      sessions: sessions,
      moves: moves,
      creations: creations,
      unscheduled: proposal.unscheduled,
      conflicts: proposal.conflicts,
      budgetMinutes: proposal.budgetMinutes,
      sleepNote: proposal.sleepNote,
      anchoredStart: proposal.anchoredStart,
    );
    return _previewProposal(
      intent: intent,
      plan: updated,
      title: 'Updated Plan',
      message: 'Adjusted. Review and apply when ready.',
      applyLabel: _applyLabelFor(proposal.kind, updated),
    );
  }

  /// Moves an exam to a new date through the existing Exam system.
  /// Missing exam or date clarifies with real choices; confirmation
  /// carries the change, and the result offers preparation recalculation
  /// without touching existing prep work.
  StudentAssistantResult _handleUpdateExamDate(
    StudentAssistantIntent intent, {
    required List<StudentExam> exams,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    StudentExam? match;
    if (intent.examId != null) {
      match = exams.where((e) => e.id == intent.examId).firstOrNull;
    }
    match ??= _matchExamForUpdate(intent, exams);
    if (match == null) {
      return StudentAssistantResult(
        success: false,
        intent: intent,
        title: 'Exam Not Found',
        message:
            'I couldn\'t find that exam among your upcoming exams.',
        cardKind: AssistantCardKind.error,
      );
    }
    final date = intent.targetDate;
    if (date == null) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Move To When?',
        message: 'Which date should I move "${match.title}" to?',
        cardKind: AssistantCardKind.clarification,
        clarificationRequired: true,
        clarificationQuestion:
            'Which date should I move "${match.title}" to?',
        clarificationChoices: const ['Tomorrow', 'Next Monday'],
      );
    }
    final day = DateTime(date.year, date.month, date.day);
    final exam = match;
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Move Exam',
      message:
          'Move "${exam.title}" to ${_fmtDay(day)}? Existing preparation work stays untouched.',
      cardKind: AssistantCardKind.confirmation,
      requiresConfirmation: true,
      primaryAction: StudentAssistantAction(
        id: 'act_update_exam_date',
        type: AssistantActionType.updateExamDate,
        label: 'Move to ${_fmtDay(day)}',
        examId: exam.id,
        targetDate: day,
        requiresConfirmation: true,
      ),
      suggestedPrompts: ['Plan my ${exam.subject} exam'],
    );
  }

  /// Matches an exam for date updates: exact id first, then title/subject
  /// words (single best-score winner only — ties clarify upstream).
  StudentExam? _matchExamForUpdate(
    StudentAssistantIntent intent,
    List<StudentExam> exams,
  ) {
    final upcoming =
        exams.where((e) => !e.isCompleted && !e.isCancelled).toList();
    if (upcoming.isEmpty) return null;
    final name = (intent.subjectName ?? '').trim().toLowerCase();
    if (name.isEmpty) {
      return upcoming.length == 1 ? upcoming.single : null;
    }
    final matches =
        DeterministicStudentIntentParser.matchExams(name, upcoming);
    return matches.length == 1 ? matches.single : null;
  }

  // ─── P2 small helpers ────────────────────────────────────────────
  StudentTask? _resolveTask(
    StudentAssistantIntent intent,
    List<StudentTask> tasks,
  ) {
    if (intent.taskId != null) {
      final byId = tasks.where((t) => t.id == intent.taskId).firstOrNull;
      if (byId != null) return byId;
    }
    final name = (intent.taskName ?? '').trim();
    if (name.isEmpty) return null;
    final exact = tasks
        .where((t) => !t.isCompleted && t.title.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (exact != null) return exact;
    final matches = DeterministicStudentIntentParser.matchTasks(
      name,
      tasks,
    );
    return matches.length == 1 ? matches.single : null;
  }

  StudentAssistantResult _taskNotFound(
    StudentAssistantIntent intent,
    String title,
  ) {
    return StudentAssistantResult(
      success: false,
      intent: intent,
      title: 'Task Not Found',
      message:
          'I couldn\'t find "$title" among your active tasks. Check the title and try again.',
      cardKind: AssistantCardKind.error,
    );
  }

  TaskPriority _parsePriority(String? name) {
    switch (name) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'critical':
        return TaskPriority.critical;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }

  String? _sleepNoteOrNull() {
    final sleep = _readSleep();
    if (sleep == null) return null;
    return 'Sleep ${sleep.windowLabel} protected.';
  }

  String _applyLabelFor(AssistantProposalKind kind, AssistantDayPlan plan) {
    switch (kind) {
      case AssistantProposalKind.dayPlan:
        return 'Apply Plan';
      case AssistantProposalKind.fixDay:
        return 'Apply Changes';
      case AssistantProposalKind.catchUp:
        return 'Apply Catch-Up Plan';
      case AssistantProposalKind.examPrep:
        return 'Create ${plan.creations.length} Prep Tasks';
      case AssistantProposalKind.revision:
        return 'Create ${plan.creations.length} Revision Tasks';
    }
  }

  StudentExam? _matchExam(
    StudentAssistantIntent intent,
    List<StudentExam> exams,
    List<Subject> subjects,
  ) {
    final upcoming = exams.where((e) => !e.isCompleted).toList();
    if (upcoming.isEmpty) return null;
    final subjectName = intent.subjectName?.trim().toLowerCase();
    if (subjectName != null && subjectName.isNotEmpty) {
      final named = upcoming
          .where((e) => e.subject.toLowerCase().contains(subjectName))
          .toList();
      if (named.isNotEmpty) {
        named.sort((a, b) => (a.daysUntilExam ?? 1 << 30)
            .compareTo(b.daysUntilExam ?? 1 << 30));
        return named.first;
      }
    }
    upcoming.sort((a, b) => (a.daysUntilExam ?? 1 << 30)
        .compareTo(b.daysUntilExam ?? 1 << 30));
    return upcoming.first;
  }

  bool _topicMatchesSubject(
    Topic topic,
    StudentExam exam,
    List<Subject> subjects,
  ) {
    final examSubject = exam.subject.trim().toLowerCase();
    if (examSubject.isEmpty) return false;
    for (final s in subjects) {
      if (s.displayName.trim().toLowerCase() == examSubject &&
          topic.subjectId == s.id) {
        return true;
      }
    }
    return false;
  }

  List<_ExamPhase> _examPhases(
    String examTitle,
    int days,
    List<Topic> subjectTopics,
  ) {
    final topicNames = subjectTopics.take(6).map((t) => t.title).toList();
    String withTopics(String label) {
      if (topicNames.isEmpty) return label;
      return '$label: ${topicNames.take(3).join(', ')}';
    }

    if (days <= 2) {
      return [
        _ExamPhase(
          label: withTopics('Final review'),
          days: days,
        ),
      ];
    }
    final core = (days * 0.35).round().clamp(1, days - 2);
    final practice = (days * 0.30).round().clamp(1, days - core - 1);
    final revision = (days * 0.20).round().clamp(1, days - core - practice);
    final rest = (days - core - practice - revision).clamp(0, days);
    final phases = [
      _ExamPhase(label: withTopics('Core concepts'), days: core),
      _ExamPhase(label: withTopics('Practice'), days: practice),
      _ExamPhase(label: 'Revision', days: revision),
    ];
    if (rest > 0) phases.add(_ExamPhase(label: 'Final revision', days: rest));
    return phases;
  }

  // ─── P3 Daily Loop Handlers ──────────────────────────────────────
  //
  // Morning briefing, evening review, tomorrow preparation. All read live
  // controllers; proposals stay confirm-gated; empty states stay honest.

  StudentAssistantResult _handleMorningBriefing(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
    required List<StudentExam> exams,
    required List<StudySession> sessions,
    required List<PlanningBlock> blocks,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    final active = tasks.where((t) => !t.isCompleted).toList();
    final overdue =
        active.where((t) => t.isOverdue).toList();
    final upcoming = exams.where((e) => !e.isCompleted).toList();
    final sleep = _readSleep();

    if (active.isEmpty && upcoming.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Good Morning',
        message: 'Your day isn\'t planned yet. Tell me what you have, '
            'and I\'ll organize it around your priorities.',
        cardKind: AssistantCardKind.empty,
        contextLine: context?.summaryLine,
        primaryAction: const StudentAssistantAction(
          id: 'act_plan_my_day',
          type: AssistantActionType.openPlan,
          label: 'Plan My Day',
        ),
        suggestedPrompts: const [
          'I have 2 hours',
          'What should I study?',
          'Set sleep schedule',
        ],
      );
    }

    final plan = AssistantPlanningEngine.proposeDayPlan(
      now: now,
      budgetMinutes: intent.availableMinutes ?? 150,
      tasks: active,
      existingBlocks: blocks,
      exams: upcoming,
      sleep: sleep,
    );
    // Controlled preparation (§3): one staged proposal per day. A repeat
    // briefing reports status instead of stacking duplicate proposals.
    final alreadyPrepared =
        DailyAssistantController.instance.state.prepared;
    if (alreadyPrepared) {
      final top = plan.sessions.isNotEmpty ? plan.sessions.first : null;
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Day Already Prepared',
        message: top == null
            ? 'Today\'s plan is ready (v${DailyAssistantController.instance.state.planVersion}). Ask for a fresh plan any time.'
            : 'Today\'s plan is ready (v${DailyAssistantController.instance.state.planVersion}). Top priority is still: ${top.title}.',
        cardKind: AssistantCardKind.recommendation,
        contextLine: [
          if (sleep != null) 'Sleep ${sleep.windowLabel}',
          if (context?.summaryLine != null) context?.summaryLine ?? '',
        ].join(' · '),
        primaryAction: const StudentAssistantAction(
          id: 'act_review_day',
          type: AssistantActionType.openPlan,
          label: 'Review My Day',
        ),
        suggestedPrompts: const ['What should I do now?', 'Fix my day'],
      );
    }
    final top = plan.sessions.isNotEmpty ? plan.sessions.first : null;
    final nearest = upcoming.isEmpty
        ? null
        : (upcoming.toList()
          ..sort((a, b) => (a.daysUntilExam ?? 1 << 30)
              .compareTo(b.daysUntilExam ?? 1 << 30))).first;

    final lines = <String>[
      if (top != null)
        'Top priority: ${top.title} (${top.minutes} min)',
      '${plan.totalMinutes}m planned study',
      if (nearest != null && nearest.daysUntilExam != null)
        '${nearest.title} exam in ${nearest.daysUntilExam}d',
      '${active.length} task${active.length == 1 ? '' : 's'} open'
      '${overdue.isEmpty ? '' : ' (${overdue.length} overdue)'}',
    ];
    return _previewProposal(
      intent: intent,
      plan: plan,
      title: 'Good Morning — Day Ready',
      message: '${lines.join('\n')}\n\nReview and apply when ready.',
      contextLine: [
        if (sleep != null) 'Sleep ${sleep.windowLabel}',
        if (context?.summaryLine != null) context?.summaryLine ?? '',
      ].join(' · '),
      applyLabel: 'Apply Plan',
      secondary: [
        const StudentAssistantAction(
          id: 'act_review_day',
          type: AssistantActionType.openPlan,
          label: 'Review My Day',
          isPrimary: false,
        ),
      ],
    );
  }

  StudentAssistantResult _handleEveningReview(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
    required List<StudentExam> exams,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    final day = DateTime(now.year, now.month, now.day);
    final completed = tasks.where((t) {
      final c = t.completedAt;
      return c != null &&
          c.year == day.year &&
          c.month == day.month &&
          c.day == day.day;
    }).toList();
    var focusMinutes = 0;
    try {
      for (final s in FocusController.instance.sessions) {
        final end = s.endedAt;
        if (end == null ||
            end.year != day.year ||
            end.month != day.month ||
            end.day != day.day) {
          continue;
        }
        if (s.outcome == null) continue;
        focusMinutes +=
            (s.actualDuration ?? s.plannedDuration).inMinutes;
      }
    } catch (_) {}
    final unfinished =
        tasks.where((t) => !t.isCompleted).toList();
    final daily = DailyAssistantController.instance.state;
    final sleep = _readSleep();

    if (completed.isEmpty &&
        focusMinutes == 0 &&
        daily.appliedSessions + daily.appliedMoves + daily.appliedCreations == 0 &&
        unfinished.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Day Review',
        message: 'Nothing to review yet.',
        cardKind: AssistantCardKind.empty,
        contextLine: context?.summaryLine,
      );
    }

    final ranked = AssistantPlanningEngine.rankTasks(
      unfinished,
      now,
      exams,
    );
    final lines = <String>[
      if (completed.isNotEmpty)
        '✓ ${completed.length} task${completed.length == 1 ? '' : 's'} completed',
      if (focusMinutes > 0) '✓ ${focusMinutes}m focus',
      if (daily.appliedMoves > 0)
        '↻ ${daily.appliedMoves} task${daily.appliedMoves == 1 ? '' : 's'} moved',
      if (daily.appliedSessions > 0)
        '✓ ${daily.appliedSessions} planned session${daily.appliedSessions == 1 ? '' : 's'}',
      if (ranked.isNotEmpty)
        'Tomorrow\'s priority: ${ranked.first.title}',
    ];
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Day Review',
      message: lines.join('\n'),
      cardKind: AssistantCardKind.recommendation,
      contextLine: [
        if (sleep != null) 'Sleep ${sleep.windowLabel}',
        if (context?.summaryLine != null) context?.summaryLine ?? '',
      ].join(' · '),
      primaryAction: const StudentAssistantAction(
        id: 'act_view_tomorrow',
        type: AssistantActionType.openPlan,
        label: 'View Tomorrow',
      ),
      suggestedPrompts: const ['Prepare tomorrow', 'What should I do now?'],
    );
  }

  StudentAssistantResult _handlePrepareTomorrow(
    StudentAssistantIntent intent, {
    required List<StudentTask> tasks,
    required DateTime now,
    AssistantContextSnapshot? context,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final sleep = _readSleep();

    DateTime anchor = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
    if (sleep != null && sleep.enabled) {
      final wake = SleepScheduleValidation.normaliseMinutes(
        sleep.wakeMinutes,
      );
      anchor = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        wake ~/ 60,
        wake % 60,
      );
    }

    final plan = AssistantPlanningEngine.proposeDayPlan(
      now: anchor,
      budgetMinutes: intent.availableMinutes ?? 150,
      tasks: tasks.where((t) => !t.isCompleted).toList(),
      exams: const [],
      sleep: sleep,
      anchorStart: anchor,
    );
    if (plan.sessions.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Tomorrow Is Clear',
        message: 'Nothing unfinished carries into tomorrow. Enjoy the clear day.',
        cardKind: AssistantCardKind.success,
        contextLine: context?.summaryLine,
      );
    }
    // Unfinished work due today moves with its sessions.
    final moves = <PlannedMove>[];
    for (final s in plan.sessions) {
      if (s.taskId == null) continue;
      final task = tasks.where((t) => t.id == s.taskId).firstOrNull;
      if (task?.dueDate == null) continue;
      final due = DateTime(
        task!.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      if (!due.isAfter(today)) {
        moves.add(
          PlannedMove(
            taskId: task.id,
            taskTitle: task.title,
            fromDate: task.dueDate,
            toDate: tomorrow,
            reason: 'Carried into tomorrow',
          ),
        );
      }
    }
    final withMoves = AssistantDayPlan(
      kind: AssistantProposalKind.dayPlan,
      sessions: plan.sessions,
      moves: moves,
      unscheduled: plan.unscheduled,
      conflicts: plan.conflicts,
      budgetMinutes: plan.budgetMinutes,
      sleepNote: plan.sleepNote,
      anchoredStart: anchor,
    );
    return _previewProposal(
      intent: intent,
      plan: withMoves,
      title: 'Tomorrow, Prepared',
      message:
          '${withMoves.sessions.length} sessions from ${_fmtClock(anchor)}${moves.isEmpty ? '' : ' · ${moves.length} carried over'}.',
      contextLine: [
        if (sleep != null) 'Sleep ${sleep.windowLabel}',
        if (context?.summaryLine != null) context?.summaryLine ?? '',
      ].join(' · '),
      applyLabel: 'Apply Tomorrow\'s Plan',
    );
  }

  static String _fmtClock(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // ─── Academic Schedule & Calendar Handlers ──────────────────────────

  StudentAssistantResult _handleScheduleToday(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final schedule = AcademicScheduleController.instance.getScheduleForDay(now);
    final isClear = schedule.items.isEmpty;

    if (isClear) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: "Today's Schedule is Clear",
        message: 'You have no classes, exams, or study blocks scheduled for today.',
        primaryAction: const StudentAssistantAction(
          id: 'act_open_calendar',
          type: AssistantActionType.openCalendar,
          label: 'Open Schedule',
        ),
        suggestedPrompts: const [
          'Plan my day',
          'I have 2 hours',
          'What should I revise?',
        ],
      );
    }

    final classCount = schedule.fixedEvents
        .where((e) =>
            e.type == AcademicEventType.classSession ||
            e.type == AcademicEventType.lecture ||
            e.type == AcademicEventType.lab)
        .length;
    final examCount = schedule.exams.length;
    final blockCount = schedule.planningBlocks.length;
    final freeHours = schedule.availability.freeMinutes ~/ 60;
    final freeMins = schedule.availability.freeMinutes % 60;

    final previews = schedule.items.take(5).map((it) {
      final timeStr = it.allDay
          ? 'All Day'
          : '${it.startAt.hour.toString().padLeft(2, '0')}:${it.startAt.minute.toString().padLeft(2, '0')}';
      return '$timeStr — ${it.title} (${it.statusLabel ?? "Event"})';
    }).toList();

    final parts = <String>[];
    if (classCount > 0) parts.add('$classCount ${classCount == 1 ? "class" : "classes"}');
    if (examCount > 0) parts.add('$examCount ${examCount == 1 ? "exam" : "exams"}');
    if (blockCount > 0) parts.add('$blockCount planned ${blockCount == 1 ? "session" : "sessions"}');

    final summary = parts.isNotEmpty ? parts.join(', ') : '${schedule.items.length} items';
    final freeStr = freeHours > 0 ? '${freeHours}h ${freeMins}m' : '${freeMins}m';

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: "Today's Schedule",
      message: 'You have $summary today with $freeStr of free time available.',
      previewItems: previews,
      primaryAction: const StudentAssistantAction(
        id: 'act_open_calendar',
        type: AssistantActionType.openCalendar,
        label: 'View Schedule',
      ),
      suggestedPrompts: const [
        'How much free time do I have today?',
        'When is my next class?',
        'Plan my day',
      ],
    );
  }

  StudentAssistantResult _handleScheduleTomorrow(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final tomorrow = now.add(const Duration(days: 1));
    final schedule = AcademicScheduleController.instance.getScheduleForDay(tomorrow);

    if (schedule.items.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: "Tomorrow's Schedule is Clear",
        message: 'You have no classes, exams, or study blocks scheduled for tomorrow.',
        primaryAction: StudentAssistantAction(
          id: 'act_open_calendar_tomorrow',
          type: AssistantActionType.openCalendar,
          label: 'View Tomorrow',
          targetDate: tomorrow,
        ),
        suggestedPrompts: const [
          'Show my week',
          'When is my next exam?',
          'What should I study?',
        ],
      );
    }

    final previews = schedule.items.take(5).map((it) {
      final timeStr = it.allDay
          ? 'All Day'
          : '${it.startAt.hour.toString().padLeft(2, '0')}:${it.startAt.minute.toString().padLeft(2, '0')}';
      return '$timeStr — ${it.title}';
    }).toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: "Tomorrow's Schedule",
      message: 'You have ${schedule.items.length} scheduled ${schedule.items.length == 1 ? "item" : "items"} tomorrow.',
      previewItems: previews,
      primaryAction: StudentAssistantAction(
        id: 'act_open_calendar_tomorrow',
        type: AssistantActionType.openCalendar,
        label: 'Open Schedule',
        targetDate: tomorrow,
      ),
      suggestedPrompts: const [
        'Show my week',
        'When is my next class?',
      ],
    );
  }

  StudentAssistantResult _handleWeekSchedule(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final weekSchedule = AcademicScheduleController.instance.getScheduleForWeek(now);
    final committedHours = weekSchedule.totalCommittedMinutes ~/ 60;
    final plannedHours = weekSchedule.totalPlannedMinutes ~/ 60;
    final freeHours = weekSchedule.totalFreeMinutes ~/ 60;

    final previews = weekSchedule.daySchedules.map((d) {
      final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.date.weekday - 1];
      return '$dayName ${d.date.day}: ${d.items.length} items (${d.availability.committedMinutes ~/ 60}h committed, ${d.availability.freeMinutes ~/ 60}h free)';
    }).toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'This Week Overview',
      message: '${committedHours}h committed, ${plannedHours}h planned, and ${freeHours}h free time across this week.',
      previewItems: previews,
      primaryAction: const StudentAssistantAction(
        id: 'act_open_calendar_week',
        type: AssistantActionType.openCalendar,
        label: 'Open Week View',
      ),
      suggestedPrompts: const [
        "What's my busiest day this week?",
        'When is my next exam?',
        'How much free time do I have today?',
      ],
    );
  }

  StudentAssistantResult _handleNextClass(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final upcomingWeekEvents = AcademicScheduleController.instance
        .eventsForRange(now, now.add(const Duration(days: 7)));
    final classes = upcomingWeekEvents.where((e) =>
        (e.type == AcademicEventType.classSession ||
            e.type == AcademicEventType.lecture ||
            e.type == AcademicEventType.lab) &&
        e.endAt.isAfter(now)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    if (classes.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Upcoming Classes',
        message: 'You have no classes, lectures, or labs scheduled for the next 7 days.',
        primaryAction: const StudentAssistantAction(
          id: 'act_open_calendar',
          type: AssistantActionType.openCalendar,
          label: 'Open Schedule',
        ),
      );
    }

    final next = classes.first;
    final isToday = next.startAt.day == now.day && next.startAt.month == now.month;
    final dayStr = isToday
        ? 'today'
        : (next.startAt.difference(now).inDays == 1 ? 'tomorrow' : 'on ${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][next.startAt.weekday - 1]}');
    final timeStr = '${next.startAt.hour.toString().padLeft(2, '0')}:${next.startAt.minute.toString().padLeft(2, '0')}';
    final locStr = next.location != null && next.location!.isNotEmpty ? ' in ${next.location}' : '';

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Next Class: ${next.title}',
      message: '${next.title} starts $dayStr at $timeStr$locStr (${next.durationMinutes} min).',
      primaryAction: StudentAssistantAction(
        id: 'act_open_calendar_class',
        type: AssistantActionType.openCalendar,
        label: 'View in Schedule',
        targetDate: next.startAt,
      ),
      suggestedPrompts: const [
        'How much free time do I have today?',
        "What's on my schedule?",
      ],
    );
  }

  StudentAssistantResult _handleCheckFreeTime(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final avail = AcademicScheduleController.instance.calculateAvailability(now);
    final freeHours = avail.freeMinutes ~/ 60;
    final freeMins = avail.freeMinutes % 60;
    final freeStr = freeHours > 0 ? '${freeHours}h ${freeMins}m' : '${freeMins}m';

    final windowPreviews = avail.freeWindows
        .where((w) => w.end.isAfter(now))
        .map((w) {
          final s = '${w.start.hour.toString().padLeft(2, '0')}:${w.start.minute.toString().padLeft(2, '0')}';
          final e = '${w.end.hour.toString().padLeft(2, '0')}:${w.end.minute.toString().padLeft(2, '0')}';
          return '$s – $e (${w.durationMinutes} min free)';
        }).toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Free Time Availability',
      message: 'You have $freeStr of free time remaining today outside your fixed commitments and planned sessions.',
      previewItems: windowPreviews,
      primaryAction: const StudentAssistantAction(
        id: 'act_open_calendar_free',
        type: AssistantActionType.openCalendar,
        label: 'View Schedule',
      ),
      suggestedPrompts: const [
        'Plan my day',
        'What should I revise?',
        'What should I study?',
      ],
    );
  }

  StudentAssistantResult _handleScheduleConflicts(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final conflicts = AcademicScheduleController.instance.detectConflicts(now);

    if (conflicts.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Schedule Conflicts',
        message: 'All your commitments and study sessions fit cleanly without any overlaps today.',
        suggestedPrompts: const [
          'What do I have today?',
          'How much free time do I have today?',
        ],
      );
    }

    final conflictDescriptions = conflicts.map((c) => '${c.title}: ${c.description}').toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: '${conflicts.length} Schedule ${conflicts.length == 1 ? "Conflict" : "Conflicts"} Detected',
      message: conflicts.first.description,
      previewItems: conflictDescriptions,
      primaryAction: conflicts.any((c) => c.canAutoReschedule)
          ? const StudentAssistantAction(
              id: 'act_resolve_conflict',
              type: AssistantActionType.resolveConflict,
              label: 'Reschedule Study Block',
              requiresConfirmation: true,
            )
          : const StudentAssistantAction(
              id: 'act_open_calendar_conflicts',
              type: AssistantActionType.openCalendar,
              label: 'View in Calendar',
            ),
      suggestedPrompts: const [
        'Move my revision to the next available slot',
        'Show my schedule',
      ],
    );
  }

  StudentAssistantResult _handleBusiestDay(
    StudentAssistantIntent intent, {
    required DateTime now,
  }) {
    final weekSchedule = AcademicScheduleController.instance.getScheduleForWeek(now);
    UnifiedDaySchedule? busiest;
    int maxCommitted = -1;

    for (final day in weekSchedule.daySchedules) {
      final total = day.availability.committedMinutes + day.availability.plannedMinutes;
      if (total > maxCommitted) {
        maxCommitted = total;
        busiest = day;
      }
    }

    if (busiest == null || maxCommitted == 0) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'Balanced Schedule',
        message: 'You have a light week with no heavily committed days.',
        primaryAction: const StudentAssistantAction(
          id: 'act_open_calendar',
          type: AssistantActionType.openCalendar,
          label: 'View Schedule',
        ),
      );
    }

    final dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][busiest.date.weekday - 1];
    final hours = maxCommitted ~/ 60;
    final mins = maxCommitted % 60;

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Busiest Day: $dayName',
      message: '$dayName (${busiest.date.day}/${busiest.date.month}) is your busiest day with ${hours}h ${mins}m committed & planned across ${busiest.items.length} items.',
      primaryAction: StudentAssistantAction(
        id: 'act_view_busiest_day',
        type: AssistantActionType.openCalendar,
        label: 'View $dayName',
        targetDate: busiest.date,
      ),
      suggestedPrompts: const [
        'Show my week',
        'How much free time do I have today?',
      ],
    );
  }

  // ─── Knowledge & Notes Handlers ──────────────────────────────────────

  StudentAssistantResult _handleShowNotes(StudentAssistantIntent intent) {
    final nc = StudentNoteController.instance;
    List<StudentNote> notes;

    String scopeTitle = 'Your Notes';
    if (intent.topicId != null) {
      notes = nc.notesForTopic(intent.topicId!);
      scopeTitle = 'Notes for ${intent.topicName ?? "Topic"}';
    } else if (intent.subjectId != null) {
      notes = nc.notesForSubject(intent.subjectId!);
      scopeTitle = 'Notes for ${intent.subjectName ?? "Subject"}';
    } else {
      notes = nc.allActiveNotes;
    }

    if (notes.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Notes Found',
        message: intent.subjectName != null || intent.topicName != null
            ? 'You haven\'t created any notes for this topic or subject yet.'
            : 'Your knowledge base is empty. Start taking notes to reinforce your retention.',
        primaryAction: StudentAssistantAction(
          id: 'act_create_note_prompt',
          type: AssistantActionType.createNote,
          label: 'Create Note',
          subjectId: intent.subjectId,
          subjectName: intent.subjectName,
          chapterId: intent.chapterId,
          topicId: intent.topicId,
          topicTitle: intent.topicName,
          noteTitle: intent.noteTitle,
        ),
        suggestedPrompts: const [
          'Show pinned notes',
          'What should I study?',
        ],
      );
    }

    final previews = notes.take(4).map((n) => '${n.title} (${n.wordCount} words)').toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: scopeTitle,
      message: 'Found ${notes.length} ${notes.length == 1 ? "note" : "notes"}.',
      previewItems: previews,
      primaryAction: StudentAssistantAction(
        id: 'act_open_first_note',
        type: AssistantActionType.openNote,
        label: 'Open "${notes.first.title}"',
        noteId: notes.first.id,
        noteTitle: notes.first.title,
      ),
      secondaryActions: [
        StudentAssistantAction(
          id: 'act_open_knowledge_center',
          type: AssistantActionType.openKnowledge,
          label: 'View Knowledge Base',
          subjectId: intent.subjectId,
        ),
      ],
      suggestedPrompts: const [
        'Show pinned notes',
        'Show recent notes',
        'Create a note',
      ],
    );
  }

  StudentAssistantResult _handleSearchNotes(StudentAssistantIntent intent) {
    final nc = StudentNoteController.instance;
    final query = intent.searchQuery ?? intent.rawText;
    final results = nc.searchNotes(query, subjectId: intent.subjectId, topicId: intent.topicId);

    if (results.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Notes Found',
        message: 'No notes matched "$query".',
        primaryAction: StudentAssistantAction(
          id: 'act_create_note_searched',
          type: AssistantActionType.createNote,
          label: 'Create Note for "$query"',
          noteTitle: query,
        ),
        suggestedPrompts: const [
          'Show all notes',
          'Show pinned notes',
        ],
      );
    }

    final previews = results.take(4).map((n) => '${n.title} — ${n.snippet}').toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Notes matching "$query"',
      message: 'Found ${results.length} matching ${results.length == 1 ? "note" : "notes"}.',
      previewItems: previews,
      primaryAction: StudentAssistantAction(
        id: 'act_open_search_note',
        type: AssistantActionType.openNote,
        label: 'Open "${results.first.title}"',
        noteId: results.first.id,
        noteTitle: results.first.title,
      ),
      secondaryActions: const [
        StudentAssistantAction(
          id: 'act_open_knowledge_search',
          type: AssistantActionType.openKnowledge,
          label: 'Knowledge Center',
        ),
      ],
    );
  }

  StudentAssistantResult _handleOpenNote(StudentAssistantIntent intent) {
    final nc = StudentNoteController.instance;
    StudentNote? target;

    if (intent.noteId != null) {
      target = nc.noteById(intent.noteId!);
    } else {
      target = nc.allActiveNotes.firstOrNull;
    }

    if (target == null) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Notes Found',
        message: 'You haven\'t created any notes yet.',
        primaryAction: const StudentAssistantAction(
          id: 'act_create_note_first',
          type: AssistantActionType.createNote,
          label: 'Create Note',
        ),
      );
    }

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: target.title.isEmpty ? 'Untitled Note' : target.title,
      message: 'Latest note (${target.wordCount} words, updated ${_formatRelative(target.updatedAt)}).',
      primaryAction: StudentAssistantAction(
        id: 'act_open_target_note',
        type: AssistantActionType.openNote,
        label: 'Open Note',
        noteId: target.id,
        noteTitle: target.title,
      ),
    );
  }

  StudentAssistantResult _handleShowPinnedNotes(StudentAssistantIntent intent) {
    final nc = StudentNoteController.instance;
    final pinned = nc.pinnedNotes;

    if (pinned.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Pinned Notes',
        message: 'You haven\'t pinned any notes yet. Pin important notes for fast access.',
        primaryAction: const StudentAssistantAction(
          id: 'act_open_knowledge_pinned',
          type: AssistantActionType.openKnowledge,
          label: 'Open Knowledge Base',
        ),
      );
    }

    final previews = pinned.take(4).map((n) => '📌 ${n.title}').toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Pinned Notes (${pinned.length})',
      message: 'Here are your pinned reference notes:',
      previewItems: previews,
      primaryAction: StudentAssistantAction(
        id: 'act_open_pinned_note',
        type: AssistantActionType.openNote,
        label: 'Open "${pinned.first.title}"',
        noteId: pinned.first.id,
      ),
      secondaryActions: const [
        StudentAssistantAction(
          id: 'act_open_knowledge_all',
          type: AssistantActionType.openKnowledge,
          label: 'All Notes',
        ),
      ],
    );
  }

  StudentAssistantResult _handleShowRecentNotes(StudentAssistantIntent intent) {
    final nc = StudentNoteController.instance;
    final recent = nc.recentNotes;

    if (recent.isEmpty) {
      return StudentAssistantResult(
        success: true,
        intent: intent,
        title: 'No Recent Notes',
        message: 'You haven\'t created or edited any notes recently.',
        primaryAction: const StudentAssistantAction(
          id: 'act_create_first_note',
          type: AssistantActionType.createNote,
          label: 'Create Note',
        ),
      );
    }

    final previews = recent.take(4).map((n) => '${n.title} (edited ${_formatRelative(n.updatedAt)})').toList();

    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Recent Notes',
      message: 'Here are your most recently updated notes:',
      previewItems: previews,
      primaryAction: StudentAssistantAction(
        id: 'act_open_recent_note',
        type: AssistantActionType.openNote,
        label: 'Open "${recent.first.title}"',
        noteId: recent.first.id,
      ),
    );
  }

  StudentAssistantResult _handleCreateNote(StudentAssistantIntent intent) {
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: 'Create Note',
      message: intent.topicName != null
          ? 'Ready to create a new note for "${intent.topicName}".'
          : (intent.subjectName != null
              ? 'Ready to create a new note for "${intent.subjectName}".'
              : 'Ready to write a new note.'),
      primaryAction: StudentAssistantAction(
        id: 'act_open_note_editor',
        type: AssistantActionType.createNote,
        label: 'Open Note Editor',
        subjectId: intent.subjectId,
        subjectName: intent.subjectName,
        chapterId: intent.chapterId,
        topicId: intent.topicId,
        topicTitle: intent.topicName,
        noteTitle: intent.noteTitle,
      ),
    );
  }

  static String _formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${dt.day}/${dt.month}';
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _blockTitle(PlanningBlock b) {
    if (b.customTitle != null && b.customTitle!.isNotEmpty) {
      return b.customTitle!;
    }
    if (b.isTaskBlock) return 'Task block';
    if (b.isTopicBlock || b.isSubjectBlock) return 'Study block';
    return 'Scheduled session';
  }
}

/// One exam-preparation phase (label + day span).
@immutable
class _ExamPhase {
  const _ExamPhase({required this.label, required this.days});

  final String label;
  final int days;
}
