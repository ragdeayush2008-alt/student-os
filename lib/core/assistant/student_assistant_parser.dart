import '../../data/models/chapter.dart';
import '../../data/models/exam.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/topic.dart';
import 'student_assistant_intent.dart';

abstract class StudentIntentParser {
  StudentAssistantIntent parse(
    String input, {
    List<Subject> subjects = const [],
    List<Chapter> chapters = const [],
    List<Topic> topics = const [],
    List<StudentTask> tasks = const [],
    List<StudentExam> exams = const [],
  });
}

class DeterministicStudentIntentParser implements StudentIntentParser {
  const DeterministicStudentIntentParser();

  @override
  StudentAssistantIntent parse(
    String input, {
    List<Subject> subjects = const [],
    List<Chapter> chapters = const [],
    List<Topic> topics = const [],
    List<StudentTask> tasks = const [],
    List<StudentExam> exams = const [],
  }) {
    final raw = input.trim();
    if (raw.isEmpty) {
      return const StudentAssistantIntent(
        rawText: '',
        intentType: AssistantIntentType.unknown,
      );
    }

    final normalized = _applyHinglish(_normalize(raw));
    final parsedMinutes = _extractMinutes(normalized);

    // 1. Greetings & Help
    if (_matchesAny(normalized, ['hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.greeting,
      );
    }

    // Change Course / Switch Goal
    if (_matchesAny(normalized, [
      'change course',
      'switch course',
      'change my course',
      'switch my course',
      'change exam',
      'switch exam',
      'change my exam',
      'change goal',
      'change my goal',
      'switch goal',
      'switch my goal',
      'select course',
      'select exam',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.changeCourse,
      );
    }

    // Schedule Conflicts
    if (_matchesAny(normalized, [
      'what\'s conflicting today',
      'whats conflicting today',
      'what is conflicting today',
      'show schedule conflicts',
      'schedule conflicts',
      'conflicts today',
      'any conflicts',
      'show conflicts',
      'conflicts',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showScheduleConflicts,
      );
    }

    // Busiest Day
    if (_matchesAny(normalized, [
      'what\'s my busiest day this week',
      'whats my busiest day this week',
      'what is my busiest day this week',
      'what\'s my busiest day',
      'busiest day this week',
      'busiest day',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showBusiestDay,
      );
    }

    // Next Class / Lecture / Lab
    if (_matchesAny(normalized, [
      'when is my next class',
      'when\'s my next class',
      'next class',
      'when is class',
      'next lecture',
      'when is my next lecture',
      'next lab',
      'when is my next lab',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showNextClass,
      );
    }

    // Free Time / Availability check
    if (_matchesAny(normalized, [
      'how much free time do i have today',
      'how much free time do i have',
      'how much free time',
      'how much time do i have free',
      'free time today',
      'free time',
      'am i free at 4',
      'am i free',
      'do i have time to study tonight',
      'do i have time to study',
      'where can i fit 1 hour of study',
      'where can i fit study',
      'fit 1 hour of study',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.checkFreeTime,
      );
    }

    // Show Today's Schedule
    if (_matchesAny(normalized, [
      'what do i have today',
      'what\'s on my schedule',
      'whats on my schedule',
      'what is on my schedule',
      'what\'s my schedule today',
      'whats my schedule today',
      'what is my schedule today',
      'what do i have on my calendar',
      'show my schedule',
      'show schedule',
      'today schedule',
      'schedule today',
      'my schedule',
      'show today schedule',
      'show todays schedule',
      'show today\'s schedule',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showScheduleToday,
      );
    }

    // Show Tomorrow's Schedule
    if (_matchesAny(normalized, [
      'what do i have tomorrow',
      'what\'s on my schedule tomorrow',
      'whats on my schedule tomorrow',
      'what is on my schedule tomorrow',
      'tomorrow\'s schedule',
      'tomorrows schedule',
      'tomorrow schedule',
      'what\'s tomorrow like',
      'whats tomorrow like',
      'show tomorrow schedule',
      'show tomorrows schedule',
      'show tomorrow\'s schedule',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showScheduleTomorrow,
      );
    }

    // Show Week Schedule
    if (_matchesAny(normalized, [
      'show my week',
      'show week',
      'show week schedule',
      'show weekly schedule',
      'what\'s my week like',
      'whats my week like',
      'what is my week like',
      'my week',
      'weekly schedule',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showWeekSchedule,
      );
    }

    if (_matchesAny(normalized, ['help', 'what can you do', 'commands', 'how to use', 'options'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.help,
      );
    }

    // 2. "I have X time" -> Available Time
    if (_matchesAny(normalized, ['i have', 'i only have', 'only have', 'i got', 'available', 'free for', 'have about']) && parsedMinutes != null) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.availableTime,
        availableMinutes: parsedMinutes,
      );
    }

    // 2.5 Phase 4 — Availability, planning, scheduling, Focus stop.
    //
    // These sit before the broad "plan/schedule" rule so that specific
    // phrasings are never absorbed by it.

    // "I have time until 7 PM" / "free till 9pm"
    final untilMinutes = _extractMinutesUntil(raw.toLowerCase());
    if (untilMinutes != null &&
        _matchesAny(normalized, [
          'i have',
          'free',
          'available',
          'time',
          'meri',
          'mere',
        ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.availableTime,
        availableMinutes: untilMinutes,
      );
    }

    // "Stop focus" / "end my session"
    if (_matchesAny(normalized, [
      'stop focus',
      'stop my focus',
      'stop the focus',
      'end focus',
      'end my focus',
      'finish focus',
      'cancel focus',
      'quit focus',
      'band karo',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.stopFocus,
      );
    }

    // "Plan my day" / "Make my plan for today"
    // Sleep-qualified planning ("plan my day around my sleep") routes to
    // the sleep-aware P2 planner below instead.
    if (_matchesAny(normalized, [
      'plan my day',
      'plan today',
      'plan for today',
      'plan aaj',
      'make my plan',
      'make my plan for',
      'make a plan for',
      'make my day plan',
      'meri plan',
      'day plan',
    ]) &&
        !normalized.contains('sleep') &&
        !normalized.contains('miss')) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.startMyDay,
      );
    }

    // P2: personal backlog ("I'm behind", "couldn't finish yesterday") is a
    // catch-up proposal, distinct from missed-session recovery below.
    if (_matchesAny(normalized, [
          'im behind',
          'i am behind',
          'i fell behind',
          'couldnt finish',
          'could not finish',
          'didnt finish',
          'did not finish',
          'too much backlog',
          'huge backlog',
          'my backlog',
          'backlog',
          'catch me up',
          'help me catch up',
          'overwhelm',
          'overwhelmed',
          'overwhelming',
        ]) &&
        !normalized.contains('what am i behind on') &&
        !normalized.contains('behind on')) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.catchUp,
      );
    }

    // "Behind" / "recovery plan" — recovery must beat the broad plan rule
    // because "recovery plan" contains "plan".
    if (_matchesAny(normalized, [
      'i have fallen behind',
      'recovery plan',
      'give me a recovery',
      'recover my missed',
      'recover missed',
      'recover what i missed',
      'reschedule my missed',
      'reschedule missed',
      'my missed block',
      'missed block',
      'missed study',
      'i missed my plan',
      'missed my plan',
      'catch up',
      'pichhe',
      'peeche',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.recoverMissedSession,
        requiresConfirmation: true,
      );
    }

    // "Plan this topic" / "Schedule revision for this topic"
    if (_matchesAny(normalized, [
          'plan this topic',
          'schedule this topic',
          'schedule revision',
          'plan revision',
          'add this topic to my plan',
          'add to my plan',
          'add it to my plan',
          'plan it',
          'schedule it',
        ]) ||
        (normalized.startsWith('schedule') &&
            (normalized.contains('topic') || normalized.contains('revision')))) {
      final query = _extractEntityQuery(normalized, [
        'schedule revision for this topic',
        'schedule revision for',
        'schedule revision',
        'plan revision for this topic',
        'plan revision for',
        'plan revision',
        'schedule this topic',
        'plan this topic',
        'add this topic to my plan',
        'add to my plan',
        'add it to my plan',
        'schedule this',
        'plan this',
        'schedule it',
        'plan it',
        'this topic',
        'the topic',
        'my plan',
        'topic',
      ]);

      final resolved = _resolveEntity(query,
          subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);

      if (resolved.isAmbiguous) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.scheduleTopic,
          clarificationRequired: true,
          clarificationQuestion: resolved.question,
          clarificationChoices: resolved.choices,
          requiresConfirmation: true,
        );
      }

      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.scheduleTopic,
        subjectId: resolved.topic?.subjectId ?? resolved.chapter?.subjectId ?? resolved.subject?.id,
        subjectName: resolved.subject?.displayName,
        chapterId: resolved.chapter?.id ?? resolved.topic?.chapterId,
        topicId: resolved.topic?.id,
        topicName: resolved.topic?.title,
        durationMinutes: parsedMinutes ?? resolved.topic?.estimatedMinutes,
        requiresConfirmation: true,
      );
    }

    // P2: task & plan commands. Precedes the broad plan rule below
    // ("plan my exam" starts with "plan") and section 9 rescheduling
    // ("move X to Saturday" starts with "move").
    final p2Intent = _parseP2Command(
      normalized,
      raw,
      subjects: subjects,
      tasks: tasks,
      exams: exams,
    );
    if (p2Intent != null) return p2Intent;

    // "3. "Plan my next X" / "Plan my day"
    //
    // Phase 4: this broad rule must not swallow the specific scheduling,
    // recovery and reschedule phrasings that follow it, so guard it.
    if ((normalized.startsWith('plan') ||
            normalized.contains('make a plan') ||
            normalized.contains('schedule')) &&
        !_matchesAny(normalized, [
          'reschedule',
          'postpone',
          'move',
          'shift',
          'delay',
        ]) &&
        !normalized.contains('this topic') &&
        !normalized.contains('my missed') &&
        !normalized.contains('the topic') &&
        // P1 sleep schedule owns "sleep schedule" queries (handled below).
        !normalized.contains('sleep schedule') &&
        !normalized.contains('bedtime schedule') &&
        !_matchesAny(normalized, [
          'plan my day',
          'plan today',
          'plan for today',
          'plan aaj',
          'make my plan',
          'make a plan for',
        ])) {
      if (parsedMinutes != null) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.planTime,
          availableMinutes: parsedMinutes,
          requiresConfirmation: true,
        );
      }
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showTodayPlan,
        availableMinutes: 120,
      );
    }

    // If only duration was entered (e.g. "2 hours", "90m", "45 min")
    if (parsedMinutes != null && _isOnlyDuration(normalized)) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.availableTime,
        availableMinutes: parsedMinutes,
      );
    }

    // 4. "Start my day" / "Continue my day"
    if (_matchesAny(normalized, ['start my day', 'start today', 'begin my day', 'kickoff my day', 'start the day'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.startMyDay,
      );
    }

    if (_matchesAny(normalized, ['continue my day', 'continue', 'resume my day', 'resume', 'whats next', 'what is next'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.continueMyDay,
      );
    }

    // 5. Revision & Weak Area Queries
    if (_matchesAny(normalized, [
      'how did i do in practice',
      'show my practice history',
      'show practice history',
      'practice history',
      'my practice',
      'practice stats',
      'practice performance',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showPracticeHistory,
      );
    }

    if (_matchesAny(normalized, [
      'practice my weakest topic',
      'practice weakest topic',
      'practice weakest',
      'what should i practice',
      'what to practice',
      'practice recommendation',
      'quiz recommendation',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.practiceWeakest,
      );
    }

    if (normalized.startsWith('practice ') ||
        normalized.startsWith('give me practice') ||
        normalized.startsWith('quiz on ') ||
        normalized.startsWith('questions on ') ||
        normalized.contains('questions on ') ||
        normalized.contains('practice for ') ||
        normalized.contains('practice before ')) {
      final qCount = _extractQuestionCount(normalized);
      final query = _extractEntityQuery(normalized, [
        'give me practice for',
        'give me practice on',
        'give me practice',
        'practice before my',
        'practice before',
        'practice for',
        'practice this',
        'practice',
        'quiz on',
        'questions on',
        'questions for',
        if (qCount != null) 'give me $qCount questions on',
        if (qCount != null) '$qCount questions on',
        if (qCount != null) '$qCount questions',
        if (qCount != null) '$qCount qs',
        'exam',
        'chapter',
        'topic',
      ]);

      final resolved = _resolveEntity(query, subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);

      if (resolved.isAmbiguous) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.practiceTopic,
          clarificationRequired: true,
          clarificationQuestion: resolved.question,
          clarificationChoices: resolved.choices,
        );
      }

      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.practiceTopic,
        subjectId: resolved.topic?.subjectId ?? resolved.chapter?.subjectId ?? resolved.subject?.id,
        subjectName: resolved.subject?.displayName,
        chapterId: resolved.chapter?.id ?? resolved.topic?.chapterId,
        topicId: resolved.topic?.id,
        topicName: resolved.topic?.title,
        durationMinutes: parsedMinutes ?? 15,
      );
    }

    if (_matchesAny(normalized, [
      'what should i revise',
      'what is due for revision',
      'what revision is due',
      'what is due',
      'what revision is overdue',
      'what needs revision',
      'what to revise',
      'what should i review',
      'revision due',
      'show topics needing revision',
      'topics due for revision',
      'which topics need revision',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.whatShouldIRevise,
      );
    }

    // Phase 4: overdue-task requests must not be absorbed by the broad
    // "overdue -> weak areas" rule below.
    if (_matchesAny(normalized, [
      'overdue task',
      'overdue tasks',
      'tasks are overdue',
      'task is overdue',
      'what tasks are overdue',
      'what are my overdue tasks',
      'my overdue tasks',
      'late task',
      'late tasks',
      'show overdue tasks',
      'overdue work',
      'work overdue',
      'overdue assignment',
      'overdue assignments',
      'overdue homework',
      'anything overdue',
      'is anything overdue',
      'show my overdue tasks',
      'which tasks are overdue',
      'do i have overdue',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showTasks,
        overdueOnly: true,
      );
    }

    // Phase 4: "show today's plan" phrasing.
    if (_matchesAny(normalized, [
      'show todays plan',
      'show my todays plan',
      'what is my plan today',
      'what is on my plan today',
      'whats on my plan',
      'my todays plan',
      'todays plan',
      'aaj ka plan kya',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showTodayPlan,
      );
    }

    // P1: Sleep schedule — open the planner, or propose explicit times.
    // Runs before the sleep-summary block: "show sleep schedule" contains
    // "show sleep" and must resolve to the schedule, not last night's log.
    if (_matchesAny(normalized, [
      'sleep schedule',
      'set sleep',
      'change sleep',
      'update sleep',
      'bedtime schedule',
      'sleep time',
      'sleep timing',
      'sleep timings',
      'set bedtime',
      'change bedtime',
      'set wake',
      'change wake',
      'wake up time',
      'wakeup time',
      'sleep at',
      'want to sleep',
      'go to sleep',
      'sleep by',
    ])) {
      final window = _extractSleepWindow(normalized);
      if (window != null) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.updateSleepSchedule,
          bedtimeMinutes: window.bed,
          wakeMinutes: window.wake,
        );
      }
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.openSleepSchedule,
      );
    }

    // Phase 5: Student Life — sleep, routine, wind-down.
    if (_matchesAny(normalized, [
      'how did i sleep',
      'how much did i sleep',
      'my sleep',
      'sleep last night',
      'sleep summary',
      'show my sleep',
      'show sleep',
      'log sleep',
      'add sleep',
      'record sleep',
      'i slept',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showSleepSummary,
      );
    }

    if (_matchesAny(normalized, [
      'my routine',
      'show my routine',
      'show routine',
      'student life',
      'open student life',
      'my daily routine',
      'todays routine',
      'my day routine',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showStudentLife,
      );
    }

    if (_matchesAny(normalized, [
      'wind down',
      'start winding down',
      'time to wind down',
      'let me wind down',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.startWindDown,
      );
    }

    if (_matchesAny(normalized, [
      'which topics are weak',
      'what topics are weak',
      'show weak topics',
      'weak topics',
      'topics needing attention',
      'what am i behind on',
      'where am i falling behind',
      'behind',
      'neglect',
      'neglecting',
      'neglected',
      'weak areas',
      'what is overdue',
      'overdue',
      'urgent',
      'most urgent',
      'what is urgent',
      'whats urgent',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showWeakAreas,
      );
    }

    // 6. Exam-targeted study query
    if (_matchesAny(normalized, [
      'what should i study for my exam',
      'what to study for exam',
      'what should i study for exam',
      'exam study',
      'exam prep recommendation',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.whatShouldIStudy,
      );
    }

    // 7. General Study Recommendation queries
    if (_matchesAny(normalized, [
      'what should i study',
      'what should i learn',
      'what to study',
      'what to learn',
      'what do i study',
      'study recommendation',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.whatShouldIStudy,
      );
    }

    if (_matchesAny(normalized, ['what should i do', 'what do i do now', 'what should i do now', 'what to do', 'what next', 'recommend', 'what should i focus on', 'what to focus on'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.whatShouldIDo,
      );
    }

    // 8. Progress / Completion queries
    if (_matchesAny(normalized, [
      'how much of this subject have i completed',
      'how much have i completed',
      'how much is completed',
      'subject progress',
      'syllabus progress',
    ])) {
      final query = _extractEntityQuery(normalized, [
        'how much of this subject have i completed',
        'how much have i completed',
        'how much is completed',
        'subject progress',
        'syllabus progress',
        'of',
        'for',
      ]);
      final resolved = _resolveEntity(query, subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);

      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showProgress,
        subjectId: resolved.subject?.id,
        subjectName: resolved.subject?.displayName,
      );
    }

    // 9. Rescheduling / Moving
    if (normalized.startsWith('move ') ||
        normalized.startsWith('reschedule') ||
        normalized.startsWith('postpone') ||
        _matchesAny(normalized, ['move this', 'reschedule', 'postpone', 'delay', 'move to tomorrow', 'shift', 'move'])) {
      final entityQuery = _extractEntityQuery(normalized, ['move', 'reschedule', 'postpone', 'to tomorrow', 'to next week', 'this', 'tomorrow']);

      if (entityQuery.isEmpty || entityQuery == 'this') {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.reschedule,
          targetDate: DateTime.now().add(const Duration(days: 1)),
          requiresConfirmation: true,
          clarificationRequired: true,
          clarificationQuestion: 'Which session or task would you like to move to tomorrow?',
          clarificationChoices: tasks.take(3).map((t) => t.title).toList(),
        );
      }

      final resolved = _resolveEntity(entityQuery, subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);
      if (resolved.isAmbiguous) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.reschedule,
          clarificationRequired: true,
          clarificationQuestion: resolved.question,
          clarificationChoices: resolved.choices,
        );
      }

      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.reschedule,
        subjectId: resolved.subject?.id,
        subjectName: resolved.subject?.displayName,
        chapterId: resolved.chapter?.id,
        topicId: resolved.topic?.id,
        topicName: resolved.topic?.title,
        taskId: resolved.task?.id,
        taskName: resolved.task?.title,
        targetDate: DateTime.now().add(const Duration(days: 1)),
        requiresConfirmation: true,
      );
    }

    // 10. Recovery & Rebalancing
    if (_matchesAny(normalized, ['recover', 'missed session', 'missed today', 'recover missed'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.recoverMissedSession,
        requiresConfirmation: true,
      );
    }

    if (_matchesAny(normalized, ['rebalance', 'rebalance day', 'fix overload', 'redistribute'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.rebalanceDay,
        requiresConfirmation: true,
      );
    }

    // 11. Revise [Topic / Subject]
    if (normalized.startsWith('revise ') || normalized.startsWith('review ')) {
      final query = _extractEntityQuery(normalized, ['revise', 'review']);
      final resolved = _resolveEntity(query, subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);

      if (resolved.isAmbiguous) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.reviseTopic,
          clarificationRequired: true,
          clarificationQuestion: resolved.question,
          clarificationChoices: resolved.choices,
        );
      }

      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.reviseTopic,
        subjectId: resolved.topic?.subjectId ?? resolved.chapter?.subjectId ?? resolved.subject?.id,
        subjectName: resolved.subject?.displayName,
        chapterId: resolved.chapter?.id ?? resolved.topic?.chapterId,
        topicId: resolved.topic?.id,
        topicName: resolved.topic?.title,
        durationMinutes: parsedMinutes ?? (resolved.topic?.estimatedMinutes ?? 20),
      );
    }

    // 11b. "Study session" requests ("give me a 30-minute study session").
    // Start/begin phrasings belong to the dedicated session-start rules.
    if (normalized.contains('study session') &&
        !normalized.startsWith('start ') &&
        !normalized.startsWith('begin ')) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.studySubject,
        durationMinutes: parsedMinutes ?? 30,
      );
    }

    // 12. Study / Learn [Subject / Chapter / Topic]
    if (normalized.startsWith('study ') ||
        normalized.startsWith('focus on ') ||
        normalized.startsWith('learn ')) {
      final isFocusRequest = normalized.startsWith('focus on ');
      final query = _extractEntityQuery(normalized, ['study', 'focus on', 'learn', 'chapter', 'topic', 'for $parsedMinutes min', 'for $parsedMinutes minutes', 'for $parsedMinutes mins', 'for $parsedMinutes hours', 'for $parsedMinutes hr', 'for $parsedMinutes hrs', 'for $parsedMinutes h']);
      final resolved = _resolveEntity(query, subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);

      if (resolved.isAmbiguous) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: isFocusRequest
              ? AssistantIntentType.focusSubject
              : AssistantIntentType.studySubject,
          clarificationRequired: true,
          clarificationQuestion: resolved.question,
          clarificationChoices: resolved.choices,
        );
      }

      final isTopic = resolved.topic != null;
      return StudentAssistantIntent(
        rawText: raw,
        intentType: isTopic
            ? (isFocusRequest
                ? AssistantIntentType.focusTopic
                : AssistantIntentType.studyTopic)
            : (isFocusRequest
                ? AssistantIntentType.focusSubject
                : AssistantIntentType.studySubject),
        subjectId: resolved.topic?.subjectId ?? resolved.chapter?.subjectId ?? resolved.subject?.id,
        subjectName: resolved.subject?.displayName,
        chapterId: resolved.chapter?.id ?? resolved.topic?.chapterId,
        topicId: resolved.topic?.id,
        topicName: resolved.topic?.title,
        taskId: resolved.task?.id,
        taskName: resolved.task?.title,
        durationMinutes: parsedMinutes ?? (resolved.topic?.estimatedMinutes ?? 35),
      );
    }

    // 13. Start Focus
    if (_matchesAny(normalized, ['start focus', 'start a focus', 'start focus session', 'focus session', 'begin focus', 'focus timer', 'deep focus', 'focus mode'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.startFocus,
        durationMinutes: parsedMinutes ?? 25,
      );
    }

    // 14. Informational queries
    if (_matchesAny(normalized, ['show my exams', 'what exams', 'exams list', 'exam schedule', 'my exams', 'upcoming exams'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showExams,
      );
    }

    if (_matchesAny(normalized, ['show my tasks', 'what are my tasks', 'tasks list', 'my tasks', 'pending tasks', 'homework'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showTasks,
      );
    }

    if (_matchesAny(normalized, ['show my goals', 'my goals', 'goals', 'target'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showGoals,
      );
    }

    if (_matchesAny(normalized, [
      'how does xp work',
      'how do i earn xp',
      'how do you earn xp',
      'what is xp',
      'whats xp',
      'my xp',
      'xp balance',
      'what can i unlock',
      'unlock rewards',
      'show rewards',
      'rewards work',
      'how do rewards work',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showRewards,
      );
    }

    if (_matchesAny(normalized, ['how is my progress', 'how am i doing', 'progress', 'analytics', 'stats', 'improv', 'improved', 'improvement', 'improving'])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showProgress,
      );
    }

    // 14.5. Notes Queries
    if (_matchesAny(normalized, [
      'show pinned notes',
      'show my pinned notes',
      'pinned notes',
      'my pinned notes',
      'pinned note',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showPinnedNotes,
      );
    }

    if (_matchesAny(normalized, [
      'open my latest note',
      'open latest note',
      'open last note',
      'show latest note',
      'latest note',
      'last note',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.openNote,
      );
    }

    if (_matchesAny(normalized, [
      'show recent notes',
      'show my recent notes',
      'recent notes',
      'my recent notes',
      'recently updated notes',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showRecentNotes,
      );
    }

    if (normalized.startsWith('create note') ||
        normalized.startsWith('create a note') ||
        normalized.startsWith('add note') ||
        normalized.startsWith('add a note') ||
        normalized.startsWith('new note') ||
        normalized.startsWith('write note') ||
        normalized.startsWith('write notes') ||
        normalized.startsWith('take notes')) {
      final query = _extractEntityQuery(normalized, [
        'create note for',
        'create a note for',
        'create note on',
        'create a note on',
        'create note',
        'create a note',
        'add note for',
        'add a note for',
        'add note on',
        'add a note on',
        'add note',
        'add a note',
        'new note on',
        'new note for',
        'new note',
        'write notes for',
        'write note for',
        'write notes on',
        'write note on',
        'write notes',
        'write note',
        'take notes for',
        'take notes on',
        'take notes',
        'this topic',
        'this subject',
      ]);

      final resolved = _resolveEntity(query, subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.createNote,
        subjectId: resolved.subject?.id ?? resolved.topic?.subjectId,
        subjectName: resolved.subject?.displayName,
        chapterId: resolved.chapter?.id ?? resolved.topic?.chapterId,
        topicId: resolved.topic?.id,
        topicName: resolved.topic?.title,
        noteTitle: query.isNotEmpty ? query : null,
      );
    }

    if (_matchesAny(normalized, [
          'show my notes',
          'show notes',
          'my notes',
          'all notes',
          'open notes',
          'view notes',
          'knowledge',
          'knowledge base',
        ]) &&
        !normalized.contains(' on ') &&
        !normalized.contains(' for ') &&
        !normalized.contains(' about ')) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showNotes,
      );
    }

    if (normalized.contains('note') || normalized.contains('notes')) {
      final query = _extractEntityQuery(normalized, [
        'show my notes on',
        'show notes on',
        'show my notes for',
        'show notes for',
        'show my notes about',
        'show notes about',
        'find my notes about',
        'find my notes on',
        'find notes on',
        'find notes about',
        'search notes for',
        'search my notes for',
        'search notes on',
        'notes on',
        'notes for',
        'notes about',
        'notes',
        'note',
      ]);

      final resolved = _resolveEntity(query, subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);

      if (resolved.hasMatch && !resolved.isAmbiguous) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.showNotes,
          subjectId: resolved.subject?.id ?? resolved.topic?.subjectId,
          subjectName: resolved.subject?.displayName,
          chapterId: resolved.chapter?.id ?? resolved.topic?.chapterId,
          topicId: resolved.topic?.id,
          topicName: resolved.topic?.title,
          searchQuery: query.isNotEmpty ? query : null,
        );
      } else if (resolved.isAmbiguous) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.showNotes,
          clarificationRequired: true,
          clarificationQuestion: resolved.question,
          clarificationChoices: resolved.choices,
        );
      } else {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.searchNotes,
          searchQuery: query.isNotEmpty ? query : null,
        );
      }
    }

    // 14.6 Phase 4 — Priorities, completion, overdue, weak areas, exams,
    // next-session, study-time changes and "<Subject> revise" phrasing.
    //
    // Placed after the existing revise/study/task rules so nothing above is
    // shadowed.
    if (_matchesAny(normalized, [
      'what should i prioritize',
      'what do i prioritize',
      'what to prioritize',
      'what should i prioritise',
      'what to prioritise',
      'what is my priority',
      'what are my priorities',
      'prioritize me',
      'kya karu pehle',
      'kya sabse pehle',
      'pehle kya',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showPriorities,
      );
    }

    if (_matchesAny(normalized, [
      'what have i completed',
      'what did i complete',
      'what have i finished',
      'what did i finish',
      'completed today',
      'what is completed today',
      'finished today',
      'kya complete kiya',
      'kya kiya aaj',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showCompleted,
      );
    }

    if (_matchesAny(normalized, [
      'what am i weak at',
      'where am i weak',
      'what are my weak areas',
      'what is my weakness',
      'my weak topics',
      'weak areas',
      'weakness',
      'kahan weak',
      'kamzori',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showWeakAreas,
      );
    }

    // "I finished this" / "Mark this complete" — a bare reference resolved
    // against ephemeral conversation context by the controller.
    if (_matchesAny(normalized, [
      'i finished this',
      'i finished it',
      'i completed this',
      'i completed it',
      'i am done with this',
      'im done with this',
      'i did this',
      'finish this',
      'complete this',
      'mark this complete',
      'mark this done',
      'mark it complete',
      'mark it done',
      'done with this',
      'this is done',
      'this is complete',
      'its done',
      'it is done',
      'ho gaya',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.completeTask,
        refersToPendingAction: true,
        requiresConfirmation: true,
      );
    }

    if (_matchesAny(normalized, [
      'what exam is closest',
      'which exam is closest',
      'closest exam',
      'nearest exam',
      'my next exam',
      'when is my next exam',
      'when is my exam',
      'how many days are left',
      'how many days until',
      'how long until',
      'days until my',
      'days left for',
      'days left for my exam',
      'kab exam',
      'exam kab hai',
      'agla exam',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showExams,
      );
    }

    if (_matchesAny(normalized, [
      'overdue task',
      'overdue tasks',
      'tasks are overdue',
      'task is overdue',
      'what is overdue',
      'whats overdue',
      'what are overdue',
      'overdue work',
      'work overdue',
      'overdue assignment',
      'overdue assignments',
      'overdue homework',
      'anything overdue',
      'is anything overdue',
      'late task',
      'late tasks',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.showTasks,
        overdueOnly: true,
      );
    }

    if (_matchesAny(normalized, [
      'start my next task',
      'next task',
      'start next task',
      'start this task',
      'start the task',
      'begin this task',
      'run this task',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.startTask,
      );
    }

    if (_matchesAny(normalized, [
      'start my next study',
      'start my next session',
      'start my next study session',
      'next study session',
      'my next study',
      'meri next study',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.startFocus,
        durationMinutes: parsedMinutes,
      );
    }

    if (_matchesAny(normalized, [
      'change my study time',
      'change study time',
      'change my timing',
      'change my schedule time',
      'change my routine',
      'change time',
      'schedule change',
      'time badlo',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.changeStudyTime,
        requiresConfirmation: true,
      );
    }

    // "Accounts revise karna hai" / "Business Law revision"
    final trailingRevise = RegExp(r'^(.+?)\s+(revise|revision)\s*$').firstMatch(normalized);
    if (trailingRevise != null && !normalized.startsWith('what')) {
      final resolved = _resolveEntity(trailingRevise.group(1)!,
          subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);
      if (resolved.hasMatch && !resolved.isAmbiguous) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.reviseTopic,
          subjectId: resolved.topic?.subjectId ?? resolved.chapter?.subjectId ?? resolved.subject?.id,
          subjectName: resolved.subject?.displayName,
          chapterId: resolved.chapter?.id ?? resolved.topic?.chapterId,
          topicId: resolved.topic?.id,
          topicName: resolved.topic?.title,
          durationMinutes: parsedMinutes ?? (resolved.topic?.estimatedMinutes ?? 20),
        );
      }
    }

    // 15. Fallback Entity Search (if user typed subject, chapter, or topic name directly)
    final fallbackResolved = _resolveEntity(normalized, subjects: subjects, chapters: chapters, topics: topics, tasks: tasks);
    if (fallbackResolved.hasMatch && !fallbackResolved.isAmbiguous) {
      if (fallbackResolved.topic != null) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.studyTopic,
          subjectId: fallbackResolved.topic!.subjectId,
          chapterId: fallbackResolved.topic!.chapterId,
          topicId: fallbackResolved.topic!.id,
          topicName: fallbackResolved.topic!.title,
          durationMinutes: fallbackResolved.topic!.estimatedMinutes,
        );
      } else if (fallbackResolved.chapter != null) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.studySubject,
          subjectId: fallbackResolved.chapter!.subjectId,
          chapterId: fallbackResolved.chapter!.id,
          durationMinutes: 35,
        );
      } else if (fallbackResolved.subject != null) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.studySubject,
          subjectId: fallbackResolved.subject!.id,
          subjectName: fallbackResolved.subject!.displayName,
          durationMinutes: 35,
        );
      }
    } else if (fallbackResolved.isAmbiguous) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.whatShouldIStudy,
        clarificationRequired: true,
        clarificationQuestion: fallbackResolved.question,
        clarificationChoices: fallbackResolved.choices,
      );
    }

    return StudentAssistantIntent(
      rawText: raw,
      intentType: AssistantIntentType.unknown,
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  /// Deterministic Hinglish / Hindi-English transliteration.
  ///
  /// Maps common student shorthand onto the existing English phrasings so
  /// the rest of the parser can stay purely English and deterministic. No
  /// model, no network, no fuzzy matching.
  static const Map<String, String> _hinglishPhrases = <String, String>{
    // Longest / most specific first.
    'meri next study kya hai': 'what is next',
    'kya padhna chahiye': 'what should i study',
    'kya revise karna hai': 'what should i revise',
    'kya karu abhi': 'what should i do',
    'kya karun abhi': 'what should i do',
    'abhi kya karu': 'what should i do',
    'kya sabse pehle': 'what should i prioritize',
    'kya karu pehle': 'what should i prioritize',
    'kitna time bacha hai': 'free time',
    'kitna time hai': 'free time',
    'plan banao': 'plan my day',
    'meri plan banao': 'plan my day',
    'aaj ka plan': 'plan my day',
    'mere paas': 'i have',
    'focus start': 'start focus',
    'padhna chahiye': 'what should i study',
    'start karo': 'start',
    'karna hai': '',
    'karna h': '',
    'kya hai': 'what is',
  };

  /// Single-token substitutions, applied after the multi-word phrases so a
  /// phrase can never be broken apart by a token rule.
  static const Map<String, String> _hinglishTokens = <String, String>{
    'ghantey': 'hours',
    'ghante': 'hours',
    'ghanta': 'hours',
    'minut': 'minutes',
    'minute': 'minutes',
    'padhun': 'study',
    'padhna': 'study',
    'batao': 'show me',
    'dikhao': 'show me',
    'karo': 'do',
    'karna': '',
    'hain': '',
    'hai': '',
    'meri': 'my',
    'mere': 'my',
    'main': 'i',
    'mujhe': 'i',
    'aaj': 'today',
    'abhi': 'now',
    'pichhe': 'behind',
    'peeche': 'behind',
    'kya': 'what',
  };

  static String _applyHinglish(String input) {
    var result = input;
    for (final entry in _hinglishPhrases.entries) {
      result = result.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false),
        entry.value,
      );
    }
    for (final entry in _hinglishTokens.entries) {
      result = result.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false),
        entry.value,
      );
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Converts "until 7 pm" / "till 18:30" into available minutes.
  static int? _extractMinutesUntil(String rawLower) {
    final match = RegExp(
      r'\b(until|till|upto|up to|before|by)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
    ).firstMatch(rawLower);
    if (match == null) return null;

    var hour = int.tryParse(match.group(2)!) ?? 0;
    final minute = int.tryParse(match.group(3) ?? '0') ?? 0;
    final meridiem = match.group(4);
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    if (hour == 0 && meridiem == null) return null;

    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    final diff = target.difference(now).inMinutes;
    if (diff <= 0 || diff > 24 * 60) return null;
    return diff;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s\.]"), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extracts an explicit sleep window ("set sleep 11pm to 7am") as
  /// (bed, wake) minutes-since-midnight, or null when fewer than two
  /// unambiguous clock times are present. Note: [normalized] input has
  /// colons stripped ("11:30 pm" → "1130 pm"), so HHMM runs are parsed.
  /// Bare numbers without am/pm are ignored (they read as durations).
  static ({int bed, int wake})? _extractSleepWindow(String normalized) {
    final found = <int>[];
    final used = <String>{};

    int? toMinutes(int hour, int minute, String? marker) {
      if (minute < 0 || minute > 59) return null;
      var h = hour;
      if (marker == 'am' || marker == 'pm') {
        if (h < 1 || h > 12) return null;
        if (marker == 'am') {
          h = h == 12 ? 0 : h;
        } else {
          h = h == 12 ? 12 : h + 12;
        }
      } else {
        if (h < 0 || h > 23) return null;
      }
      return h * 60 + minute;
    }

    // Dot form first: "11.30 pm".
    for (final m
        in RegExp(r'(\d{1,2})\.(\d{2})\s*(am|pm)?\b')
            .allMatches(normalized)) {
      final minutes = toMinutes(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        m.group(3),
      );
      if (minutes != null) {
        found.add(minutes);
        used.add(m.group(0)!);
      }
    }
    var remaining = normalized;
    for (final u in used) {
      remaining = remaining.replaceFirst(u, ' ');
    }

    // Marker form: "11pm", "7 am", "1130pm".
    for (final m
        in RegExp(r'(\d{3,4}|\d{1,2})\s*(am|pm)\b').allMatches(remaining)) {
      final digits = m.group(1)!;
      int hour;
      int minute = 0;
      if (digits.length > 2) {
        hour = int.parse(digits.substring(0, digits.length - 2));
        minute = int.parse(digits.substring(digits.length - 2));
      } else {
        hour = int.parse(digits);
      }
      final minutes = toMinutes(hour, minute, m.group(2));
      if (minutes != null) {
        found.add(minutes);
        used.add(m.group(0)!);
      }
    }
    remaining = normalized;
    for (final u in used) {
      remaining = remaining.replaceFirst(u, ' ');
    }

    // Bare HHMM runs ("2300", "0700"). Single/double digits are durations.
    for (final m in RegExp(r'\b(\d{3,4})\b').allMatches(remaining)) {
      final digits = m.group(1)!;
      final hour = int.parse(digits.substring(0, digits.length - 2));
      final minute = int.parse(digits.substring(digits.length - 2));
      final minutes = toMinutes(hour, minute, null);
      if (minutes != null) found.add(minutes);
    }

    if (found.length < 2) return null;
    return (bed: found[0], wake: found[1]);
  }

  // ─── P2 task & plan commands ─────────────────────────────────────────
  //
  // Practical student requests routed before broader rules. Every branch
  // either resolves to a concrete intent with extracted slots or returns
  // null so existing handlers (or the honest unknown fallback) take over.

  static StudentAssistantIntent? _parseP2Command(
    String normalized,
    String raw, {
    required List<Subject> subjects,
    required List<StudentTask> tasks,
    required List<StudentExam> exams,
  }) {
    // — P3 daily loop: morning briefing, evening review, tomorrow prep —
    if (_matchesAny(normalized, [
      'morning briefing',
      'my briefing',
      'brief me',
      'daily briefing',
      'briefing',
      'prepare my day',
      'start the day',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.morningBriefing,
      );
    }

    if (_matchesAny(normalized, [
      'evening review',
      'review my day',
      'day review',
      'how did today go',
      'how was today',
      'summarize my day',
      'summarise my day',
      'today summary',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.eveningReview,
      );
    }

    if (_matchesAny(normalized, [
      'prepare tomorrow',
      "prepare for tomorrow",
      'plan tomorrow',
      'tomorrow plan',
      'tomorrows plan',
      'get tomorrow ready',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.prepareTomorrow,
      );
    }

    // — Exam plan —
    if (_matchesAny(normalized, [
          'plan my exam',
          'exam plan',
          'prepare for my exam',
          'prepare me for',
          'prepare for the exam',
          'my exam is in',
          'exam preparation plan',
        ]) ||
        (normalized.contains('exam') &&
            (normalized.contains('plan') ||
                normalized.contains('prepar')))) {
      final q = _extractEntityQuery(normalized, [
        'plan my exam',
        'exam plan',
        'prepare for my exam',
        'prepare me for',
        'prepare for the exam',
        'my exam is in',
        'exam preparation plan',
        'prepare for',
        'prepare',
        'plan',
        'my',
        'exam',
      ]);
      final resolved = _resolveEntity(
        q,
        subjects: subjects,
        chapters: const [],
        topics: const [],
        tasks: tasks,
      );
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.examPlan,
        subjectId: resolved.subject?.id,
        subjectName:
            resolved.subject?.displayName ?? _titleCase(q.isEmpty ? '' : q),
      );
    }

    // — Revision plan —
    if (_matchesAny(normalized, [
      'revision plan',
      'give me a revision plan',
      'plan my revision',
      'revise everything',
      'revise it all',
    ])) {
      final q = _extractEntityQuery(normalized, [
        'give me a revision plan',
        'revision plan',
        'plan my revision',
        'revise everything',
        'revise it all',
        'revision',
        'plan',
      ]);
      final resolved = _resolveEntity(
        q,
        subjects: subjects,
        chapters: const [],
        topics: const [],
        tasks: tasks,
      );
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.revisionPlan,
        subjectId: resolved.subject?.id,
        subjectName:
            resolved.subject?.displayName ?? _titleCase(q.isEmpty ? '' : q),
      );
    }

    // — Fix my day —
    if (_matchesAny(normalized, [
      'fix my day',
      'fix today',
      'fix todays day',
      'reorganize today',
      'replan today',
      'sort out today',
      'fix my schedule',
      'organize today',
      'organise today',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.rebalanceDay,
        requiresConfirmation: true,
      );
    }

    // — Evening cutoff ("don't schedule anything after 10pm") —
    final cutoff = _extractEveningCutoff(normalized);
    if (cutoff != null) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.planTime,
        availableMinutes:
            _extractMinutes(normalized) ?? 120,
        eveningCutoffMinutes: cutoff,
      );
    }

    // — Plan around sleep —
    if (_matchesAny(normalized, [
      'plan around my sleep',
      'plan my day around',
      'around my sleep',
      'protect my sleep',
    ])) {
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.planTime,
        availableMinutes: _extractMinutes(normalized) ?? 120,
      );
    }

    // — Exam date change ("move my Accounts exam to 12 October") —
    if ((normalized.contains('exam') &&
            (normalized.contains('move') ||
                normalized.contains('reschedule') ||
                normalized.contains('postpone') ||
                normalized.contains('changed') ||
                normalized.contains('shift'))) ||
        _matchesAny(normalized, [
          'move my exam',
          'change my exam date',
          'exam date change',
        ])) {
      final date = _extractMonthDay(normalized, DateTime.now()) ??
          _extractDayDate(normalized, DateTime.now());
      final q = _extractEntityQuery(normalized, [
        'move',
        'my',
        'exam',
        'changed',
        'change',
        'reschedule',
        'postpone',
        'shift',
        'to',
        'date',
        'tomorrow',
        'today',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
        'january',
        'february',
        'march',
        'april',
        'may',
        'june',
        'july',
        'august',
        'september',
        'october',
        'november',
        'december',
      ]);
      final matches = _matchExams(q.isEmpty ? normalized : q, exams);
      // No silent fallback to block rescheduling: an exam-flavored request
      // without a match becomes an honest "not found" in the handler.
      if (matches.isEmpty) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.updateExamDate,
          targetDate: date,
          requiresConfirmation: true,
        );
      }
      if (date == null) {
        final single = matches.length == 1 ? matches.single : null;
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.updateExamDate,
          examId: single?.id,
          subjectName: single?.subject,
          requiresConfirmation: true,
          clarificationRequired: true,
          clarificationQuestion: single == null
              ? 'Which exam, and which date should I move it to?'
              : 'Which date should I move "${single.title}" to?',
          clarificationChoices: const ['Tomorrow', 'Next Monday'],
        );
      }
      if (matches.length > 1) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.updateExamDate,
          targetDate: date,
          requiresConfirmation: true,
          clarificationRequired: true,
          clarificationQuestion: 'Which exam should I move?',
          clarificationChoices:
              matches.take(3).map((e) => e.title).toList(),
        );
      }
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.updateExamDate,
        examId: matches.single.id,
        subjectName: matches.single.subject,
        targetDate: date,
        requiresConfirmation: true,
      );
    }

    // — Create task —
    if (_matchesAny(normalized, [
          'create a task',
          'create task',
          'add a task',
          'add task',
          'new task',
          'make a task',
          'remind me to',
        ]) ||
        normalized.startsWith('create ') ||
        normalized.startsWith('add ')) {
      // Notebook notes belong to the note flow, not tasks.
      if (RegExp(r'\bnote\b').hasMatch(normalized) &&
          !RegExp(r'\btask\b').hasMatch(normalized)) {
        return null;
      }
      return _parseCreateTask(normalized, raw, subjects, tasks);
    }

    // — Complete <title> (bare "this/it" falls through to existing flow) —
    if (normalized.startsWith('complete ') ||
        normalized.startsWith('finish ') ||
        normalized.startsWith('mark ') ||
        _matchesAny(normalized, ['complete my', 'finish my'])) {
      final q = _extractEntityQuery(normalized, [
        'complete',
        'finish',
        'mark',
        'done',
        'my',
        'this',
        'that',
        'it',
      ]);
      if (q.isEmpty ||
          q == 'this' ||
          q == 'that' ||
          q == 'it' ||
          q == 'them') {
        return null;
      }
      final matches = _matchTasks(q, tasks);
      if (matches.isEmpty) {
        return null;
      }
      if (matches.length > 1) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.completeTask,
          requiresConfirmation: true,
          clarificationRequired: true,
          clarificationQuestion:
              'I found ${matches.length} matching tasks. Which one should I complete?',
          clarificationChoices: matches.take(3).map((t) => t.title).toList(),
        );
      }
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.completeTask,
        taskId: matches.single.id,
        taskName: matches.single.title,
        requiresConfirmation: true,
      );
    }

    // — Prioritize ("make X high priority") —
    final priorityName = _extractPriorityName(normalized);
    if (priorityName != null &&
        (normalized.contains('priority') ||
            normalized.contains('priorit') ||
            normalized.contains('urgent'))) {
      final q = _extractEntityQuery(normalized, [
        'make',
        'mark',
        'set',
        'change',
        'as',
        'to',
        'priority',
        'prioritize',
        'high',
        'medium',
        'normal',
        'low',
        'critical',
        'top',
        'urgent',
        'my',
        'this',
        'that',
        'it',
        'task',
      ]);
      if (q.isNotEmpty && q != 'this' && q != 'that' && q != 'it') {
        final matches = _matchTasks(q, tasks);
        if (matches.isEmpty) return null;
        if (matches.length > 1) {
          return StudentAssistantIntent(
            rawText: raw,
            intentType: AssistantIntentType.prioritizeTask,
            taskPriority: priorityName,
            requiresConfirmation: true,
            clarificationRequired: true,
            clarificationQuestion:
                'I found ${matches.length} matching tasks. Which one should I set to $priorityName priority?',
            clarificationChoices:
                matches.take(3).map((t) => t.title).toList(),
          );
        }
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.prioritizeTask,
          taskId: matches.single.id,
          taskName: matches.single.title,
          taskPriority: priorityName,
          requiresConfirmation: true,
        );
      }
      return null;
    }

    // — Move <task> to <day> ("Move my Economics task to Saturday") —
    if (normalized.startsWith('move ') ||
        normalized.startsWith('shift ') ||
        normalized.startsWith('push ')) {
      final date = _extractDayDate(normalized, DateTime.now());
      final q = _extractEntityQuery(normalized, [
        'move',
        'shift',
        'push',
        'reschedule',
        'postpone',
        'to',
        'tomorrow',
        'today',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
        'mon',
        'tue',
        'wed',
        'thu',
        'fri',
        'sat',
        'sun',
        'my',
        'this',
        'that',
        'it',
        'task',
      ]);
      if (q.isEmpty || q == 'this' || q == 'that' || q == 'it') {
        return null;
      }
      final matches = _matchTasks(q, tasks);
      if (matches.isEmpty) return null;
      if (date == null) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.rescheduleTask,
          taskId: matches.length == 1 ? matches.single.id : null,
          taskName:
              matches.length == 1 ? matches.single.title : null,
          requiresConfirmation: true,
          clarificationRequired: true,
          clarificationQuestion:
              'Which day should I move "${matches.first.title}" to?',
          clarificationChoices: const [
            'Tomorrow',
            'Saturday',
            'Sunday',
          ],
        );
      }
      if (matches.length > 1) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.rescheduleTask,
          requiresConfirmation: true,
          clarificationRequired: true,
          clarificationQuestion:
              'I found ${matches.length} matching tasks. Which one should I move to ${_fmtDay(date)}?',
          clarificationChoices:
              matches.take(3).map((t) => t.title).toList(),
        );
      }
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.rescheduleTask,
        taskId: matches.single.id,
        taskName: matches.single.title,
        targetDate: date,
        requiresConfirmation: true,
      );
    }

    // — Break <task> into N —
    if (normalized.contains('break ') ||
        normalized.contains('split ') ||
        normalized.contains('divide ')) {
      final count = _extractSubtaskCount(normalized) ?? 3;
      final q = _extractEntityQuery(normalized, [
        'break',
        'split',
        'divide',
        'down',
        'into',
        'tasks',
        'task',
        'parts',
        'part',
        'pieces',
        'steps',
        'subtasks',
        'smaller',
        'my',
        'this',
        'that',
        'it',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
      ]);
      if (q.isEmpty || q == 'this' || q == 'that' || q == 'it') {
        return null;
      }
      final matches = _matchTasks(q, tasks);
      if (matches.isEmpty) return null;
      if (matches.length > 1) {
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.breakTask,
          subtaskCount: count,
          requiresConfirmation: true,
          clarificationRequired: true,
          clarificationQuestion:
              'I found ${matches.length} matching tasks. Which one should I break into $count parts?',
          clarificationChoices:
              matches.take(3).map((t) => t.title).toList(),
        );
      }
      return StudentAssistantIntent(
        rawText: raw,
        intentType: AssistantIntentType.breakTask,
        taskId: matches.single.id,
        taskName: matches.single.title,
        subtaskCount: count,
        requiresConfirmation: true,
      );
    }

    // — P2 sleep refinements (bare "sleep schedule" stays on the P1 path) —
    if (!normalized.contains('sleep schedule')) {
      // Bedtime-only / wake-only updates. A marker-less bedtime hour
      // ("bedtime at 11") reads as PM — nobody schedules an 11 AM bedtime.
      if (normalized.contains('bedtime') || normalized.contains('go to bed')) {
        final clock = _extractClockMinutes(normalized);
        final hasMarker = RegExp(r'\b(am|pm)\b').hasMatch(normalized);
        final bed = (clock != null && !hasMarker && clock < 12 * 60)
            ? clock + 12 * 60
            : clock;
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.updateSleepSchedule,
          bedtimeMinutes: bed,
        );
      }
      if (normalized.contains('wake up') ||
          normalized.contains('wake me') ||
          normalized.contains('wakeup') ||
          normalized.contains('wake at')) {
        final clock = _extractClockMinutes(normalized);
        return StudentAssistantIntent(
          rawText: raw,
          intentType: AssistantIntentType.updateSleepSchedule,
          wakeMinutes: clock,
        );
      }
      // "I want 8 hours of sleep" → duration held, wake time clarified.
      final sleepHours =
          RegExp(r'(\d{1,2})\s*(hours|hour|hrs|hr)\s*(of\s*)?sleep')
              .firstMatch(normalized);
      if (sleepHours != null) {
        final h = int.tryParse(sleepHours.group(1)!);
        if (h != null && h >= 3 && h <= 12) {
          return StudentAssistantIntent(
            rawText: raw,
            intentType: AssistantIntentType.updateSleepSchedule,
            durationMinutes: h * 60,
          );
        }
      }
    }

    return null;
  }

  static StudentAssistantIntent _parseCreateTask(
    String normalized,
    String raw,
    List<Subject> subjects,
    List<StudentTask> tasks,
  ) {
    var remainder = normalized;
    for (final verb in [
      'create a task to',
      'create a task',
      'create task to',
      'create task',
      'add a task to',
      'add a task',
      'add task to',
      'add task',
      'make a task to',
      'make a task',
      'new task to',
      'new task',
      'remind me to',
      'create',
      'add',
    ]) {
      if (remainder.startsWith(verb)) {
        remainder = remainder.substring(verb.length).trim();
        break;
      }
    }

    DateTime? date;
    final dayDate = _extractDayDate(remainder, DateTime.now());
    if (dayDate != null) {
      date = dayDate;
      remainder = _stripWords(remainder, [
        'tomorrow',
        'today',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
        'mon',
        'tue',
        'wed',
        'thu',
        'fri',
        'sat',
        'sun',
        'on',
      ]).trim();
    }

    String? priority;
    final priorityName = _extractPriorityName(remainder);
    if (priorityName != null) {
      priority = priorityName;
      remainder = _stripWords(remainder, [
        'high',
        'medium',
        'normal',
        'low',
        'critical',
        'top',
        'urgent',
        'priority',
      ]).trim();
    }

    String? subjectId;
    String? subjectName;
    if (remainder.isNotEmpty) {
      final resolved = _resolveEntity(
        remainder,
        subjects: subjects,
        chapters: const [],
        topics: const [],
        tasks: const [],
      );
      if (resolved.subject != null && !resolved.isAmbiguous) {
        subjectId = resolved.subject!.id;
        subjectName = resolved.subject!.displayName;
        remainder = _stripWords(
          remainder,
          subjectName.toLowerCase().split(' '),
        ).trim();
      }
    }
    remainder = remainder
        .replaceAll(RegExp(r'^(to|for|called|named)\s+'), '')
        .trim();

    return StudentAssistantIntent(
      rawText: raw,
      intentType: AssistantIntentType.createTask,
      taskName: _titleCase(remainder),
      targetDate: date,
      taskPriority: priority,
      subjectId: subjectId,
      subjectName: subjectName,
      requiresConfirmation: true,
    );
  }

  /// Public exam matcher for the engine: best-first title matches.
  static List<StudentExam> matchExams(
    String query,
    List<StudentExam> exams,
  ) =>
      _matchExams(query, exams);

  /// Matches upcoming exams by title/subject words. Best-first ties only.
  static List<StudentExam> _matchExams(
    String query,
    List<StudentExam> exams,
  ) {
    const stop = {
      'the', 'a', 'an', 'to', 'for', 'my', 'on', 'in', 'of', 'and', 'exam',
      'exams', 'test', 'final', 'please',
    };
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !stop.contains(t))
        .toSet()
        .toList();
    if (tokens.isEmpty) return [];
    final scored = <StudentExam, int>{};
    for (final exam in exams) {
      if (exam.isCompleted || exam.isCancelled) continue;
      final haystack = '${exam.title} ${exam.subject}'.toLowerCase();
      var hits = 0;
      for (final token in tokens) {
        if (haystack.contains(token)) hits++;
      }
      if (hits > 0) scored[exam] = hits;
    }
    final matched = scored.keys.toList()
      ..sort((a, b) => scored[b]!.compareTo(scored[a]!));
    if (matched.isEmpty) return [];
    final top = scored[matched.first]!;
    return matched.where((e) => scored[e] == top).toList();
  }

  /// Absolute calendar date: "12 October", "12th Oct", "October 12 2026".
  /// Rolls to next year when the date already passed this year.
  static DateTime? _extractMonthDay(String text, DateTime now) {
    const months = {
      'january': 1, 'jan': 1, 'february': 2, 'feb': 2, 'march': 3, 'mar': 3,
      'april': 4, 'apr': 4, 'may': 5, 'june': 6, 'jun': 6, 'july': 7,
      'jul': 7, 'august': 8, 'aug': 8, 'september': 9, 'sep': 9, 'sept': 9,
      'october': 10, 'oct': 10, 'november': 11, 'nov': 11, 'december': 12,
      'dec': 12,
    };
    for (final entry in months.entries) {
      final dayFirst = RegExp(
        '\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+${entry.key}\\b(?:\\s+(\\d{4}))?',
      ).firstMatch(text);
      final monthFirst = dayFirst ??
          RegExp(
            '\\b${entry.key}\\s+(\\d{1,2})(?:st|nd|rd|th)?\\b(?:\\s*,?\\s*(\\d{4}))?',
          ).firstMatch(text);
      final m = monthFirst;
      if (m == null) continue;
      int day;
      int? year;
      if (m.groupCount >= 2 && dayFirst != null) {
        day = int.parse(m.group(1)!);
        year = m.group(2) == null ? null : int.tryParse(m.group(2)!);
      } else if (dayFirst == null) {
        day = int.parse(m.group(1)!);
        year = m.group(2) == null ? null : int.tryParse(m.group(2)!);
      } else {
        continue;
      }
      if (day < 1 || day > 31) continue;
      var y = year ?? now.year;
      var candidate = DateTime(y, entry.value, day);
      if (year == null &&
          candidate.isBefore(
            DateTime(now.year, now.month, now.day),
          )) {
        candidate = DateTime(y + 1, entry.value, day);
      }
      if (candidate.month != entry.value) continue;
      return candidate;
    }
    return null;
  }

  static String _stripWords(String text, List<String> words) {
    var out = ' $text ';
    for (final w in words) {
      out = out.replaceAll(
        RegExp('\\b${RegExp.escape(w)}\\b'),
        ' ',
      );
    }
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Public task matcher for the engine: best-first title matches.
  static List<StudentTask> matchTasks(
    String query,
    List<StudentTask> tasks,
  ) =>
      _matchTasks(query, tasks);

  /// Public day-date parser for follow-up resolution: absolute month-day
  /// first ("12 October"), then weekday/today/tomorrow.
  static DateTime? parseDayDate(String query, DateTime now) {
    return _extractMonthDay(query, now) ?? _extractDayDate(query, now);
  }

  /// Matches active tasks whose titles contain the significant query words.
  /// Returns best-first; empty when nothing meaningful matches.
  static List<StudentTask> _matchTasks(
    String query,
    List<StudentTask> tasks,
  ) {    const stop = {
      'the', 'a', 'an', 'to', 'for', 'my', 'on', 'in', 'of', 'and', 'please',
      'task', 'tasks', 'this', 'that', 'it', 'them', 'me',
    };
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !stop.contains(t))
        .toSet()
        .toList();
    if (tokens.isEmpty) return [];
    final scored = <StudentTask, int>{};
    for (final task in tasks) {
      if (task.isCompleted) continue;
      final title = task.title.toLowerCase();
      var hits = 0;
      for (final token in tokens) {
        if (title.contains(token)) hits++;
      }
      if (hits > 0) scored[task] = hits;
    }
    final matched = scored.keys.toList()
      ..sort((a, b) => scored[b]!.compareTo(scored[a]!));
    if (matched.isEmpty) return [];
    // Keep only top-score ties: a clear winner proceeds without asking.
    final top = scored[matched.first]!;
    return matched.where((t) => scored[t] == top).toList();
  }

  /// today / tomorrow / weekday name → date (next occurrence, today incl.).
  static DateTime? _extractDayDate(String text, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (RegExp(r'\btomorrow\b').hasMatch(text)) {
      return today.add(const Duration(days: 1));
    }
    const days = {
      'monday': DateTime.monday,
      'mon': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'tue': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'wed': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'thu': DateTime.thursday,
      'friday': DateTime.friday,
      'fri': DateTime.friday,
      'saturday': DateTime.saturday,
      'sat': DateTime.saturday,
      'sunday': DateTime.sunday,
      'sun': DateTime.sunday,
    };
    for (final entry in days.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(text)) {
        var delta = (entry.value - today.weekday) % 7;
        return today.add(Duration(days: delta));
      }
    }
    if (RegExp(r'\btoday\b').hasMatch(text)) return today;
    return null;
  }

  static String _fmtDay(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[date.weekday - 1]} ${date.day}/${date.month}';
  }

  /// 'high' | 'medium' | 'low' | 'critical', or null.
  static String? _extractPriorityName(String text) {
    if (RegExp(r'\bcritical\b').hasMatch(text)) return 'critical';
    if (RegExp(r'\b(high|top|urgent)\b').hasMatch(text)) return 'high';
    if (RegExp(r'\b(medium|normal)\b').hasMatch(text)) return 'medium';
    if (RegExp(r'\blow\b').hasMatch(text)) return 'low';
    return null;
  }

  /// "into N tasks/parts/steps" → N clamped to 2..7, else null.
  static int? _extractSubtaskCount(String text) {
    final m = RegExp(
      r'into\s+(\d{1,2})\s*(tasks|task|parts|part|pieces|steps|subtasks)?\b',
    ).firstMatch(text);
    if (m == null) return null;
    final n = int.tryParse(m.group(1)!);
    if (n == null) return null;
    return n.clamp(2, 7);
  }

  /// First explicit clock time in minutes-since-midnight (marker/colon/HHMM).
  static int? _extractClockMinutes(String normalized) {
    int? convert(int hour, int minute, String? marker) {
      if (minute < 0 || minute > 59) return null;
      var h = hour;
      if (marker == 'am' || marker == 'pm') {
        if (h < 1 || h > 12) return null;
        h = marker == 'am' ? (h == 12 ? 0 : h) : (h == 12 ? 12 : h + 12);
      } else if (h < 0 || h > 23) {
        return null;
      }
      return h * 60 + minute;
    }

    final dot =
        RegExp(r'(\d{1,2})\.(\d{2})\s*(am|pm)?\b').firstMatch(normalized);
    if (dot != null) {
      final v = convert(
        int.parse(dot.group(1)!),
        int.parse(dot.group(2)!),
        dot.group(3),
      );
      if (v != null) return v;
    }
    final marked =
        RegExp(r'(\d{3,4}|\d{1,2})\s*(am|pm)\b').firstMatch(normalized);
    if (marked != null) {
      final digits = marked.group(1)!;
      final int h;
      var min = 0;
      if (digits.length > 2) {
        h = int.parse(digits.substring(0, digits.length - 2));
        min = int.parse(digits.substring(digits.length - 2));
      } else {
        h = int.parse(digits);
      }
      final v = convert(h, min, marked.group(2));
      if (v != null) return v;
    }
    for (final m in RegExp(r'\b(\d{3,4})\b').allMatches(normalized)) {
      final digits = m.group(1)!;
      final v = convert(
        int.parse(digits.substring(0, digits.length - 2)),
        int.parse(digits.substring(digits.length - 2)),
        null,
      );
      if (v != null) return v;
    }
    return null;
  }

  /// "don't schedule anything after 10pm" → evening cutoff minutes.
  /// Note: normalization strips apostrophes ("don't" → "dont").
  static int? _extractEveningCutoff(String normalized) {
    if (!normalized.contains('after')) return null;
    if (!RegExp(r'dont schedule|do not schedule|no study|nothing after|'
            r'no work after|dont study|stop scheduling')
        .hasMatch(normalized)) {
      return null;
    }
    final after = normalized.split('after').last;
    return _extractClockMinutes(after);
  }

  static String _titleCase(String text) {
    if (text.isEmpty) return '';
    return text
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static int? _extractQuestionCount(String text) {
    final match = RegExp(r'(\d+)\s*(questions|qs|problems)\b').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  static bool _matchesAny(String input, List<String> patterns) {
    for (final p in patterns) {
      if (input == p) return true;
      if (p.contains(' ')) {
        if (input.contains(p)) return true;
      } else {
        final regex = RegExp('\\b${RegExp.escape(p)}\\b');
        if (regex.hasMatch(input)) return true;
      }
    }
    return false;
  }

  static bool _isOnlyDuration(String text) {
    if (text == 'half hour' || text == 'half an hour') return true;
    final clean = text
        .replaceAll(RegExp(r'^(i have|available|got|plan|plan my|next|for)\s+'), '')
        .trim();
    if (clean == 'half hour' || clean == 'half an hour') return true;
    return RegExp(r'^(\d+(\.\d+)?)\s*(h|hr|hrs|hour|hours|m|min|mins|minute|minutes)$').hasMatch(clean);
  }

  static int? _extractMinutes(String text) {
    final decimalHourMatch = RegExp(r'(\d+\.\d+)\s*(h|hr|hrs|hour|hours)\b').firstMatch(text);
    if (decimalHourMatch != null) {
      final hours = double.tryParse(decimalHourMatch.group(1)!);
      if (hours != null) return (hours * 60).round();
    }

    final wholeHourMatch = RegExp(r'(\d+)\s*(h|hr|hrs|hour|hours)\b').firstMatch(text);
    if (wholeHourMatch != null) {
      final hours = int.tryParse(wholeHourMatch.group(1)!);
      if (hours != null) return hours * 60;
    }

    if (text.contains('half hour') || text.contains('half an hour')) {
      return 30;
    }

    final minMatch = RegExp(r'(\d+)\s*(m|min|mins|minute|minutes)\b').firstMatch(text);
    if (minMatch != null) {
      return int.tryParse(minMatch.group(1)!);
    }

    return null;
  }

  static String _extractEntityQuery(String text, List<String> prefixesToRemove) {
    var result = text;
    for (final p in prefixesToRemove) {
      result = result.replaceAll(RegExp('\\b$p\\b'), ' ');
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static _EntityResolutionResult _resolveEntity(
    String query, {
    required List<Subject> subjects,
    List<Chapter> chapters = const [],
    required List<Topic> topics,
    required List<StudentTask> tasks,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return const _EntityResolutionResult();
    }

    // 1. Check topics first (most granular)
    final exactTopics = topics.where((t) => t.title.toLowerCase() == q).toList();
    if (exactTopics.length == 1) {
      final top = exactTopics.first;
      final matchedSubj = subjects.where((s) => s.id == top.subjectId).firstOrNull;
      return _EntityResolutionResult(topic: top, subject: matchedSubj);
    } else if (exactTopics.length > 1) {
      return _EntityResolutionResult(
        isAmbiguous: true,
        question: 'Which topic did you mean?',
        choices: exactTopics.map((t) => t.title).toList(),
      );
    }

    final matchingTopics = topics.where((t) {
      final title = t.title.toLowerCase();
      return title.contains(q) || q.contains(title);
    }).toList();

    if (matchingTopics.length == 1) {
      final top = matchingTopics.first;
      final matchedSubj = subjects.where((s) => s.id == top.subjectId).firstOrNull;
      return _EntityResolutionResult(topic: top, subject: matchedSubj);
    } else if (matchingTopics.length > 1) {
      return _EntityResolutionResult(
        isAmbiguous: true,
        question: 'I found multiple topics matching "$query". Which one did you mean?',
        choices: matchingTopics.map((t) => t.title).take(4).toList(),
      );
    }

    // 2. Check chapters
    final exactChapters = chapters.where((c) => c.title.toLowerCase() == q).toList();
    if (exactChapters.length == 1) {
      final ch = exactChapters.first;
      final matchedSubj = subjects.where((s) => s.id == ch.subjectId).firstOrNull;
      return _EntityResolutionResult(chapter: ch, subject: matchedSubj);
    } else if (exactChapters.length > 1) {
      return _EntityResolutionResult(
        isAmbiguous: true,
        question: 'Which chapter did you mean?',
        choices: exactChapters.map((c) => c.title).toList(),
      );
    }

    final matchingChapters = chapters.where((c) {
      final title = c.title.toLowerCase();
      return title.contains(q) || q.contains(title);
    }).toList();

    if (matchingChapters.length == 1) {
      final ch = matchingChapters.first;
      final matchedSubj = subjects.where((s) => s.id == ch.subjectId).firstOrNull;
      return _EntityResolutionResult(chapter: ch, subject: matchedSubj);
    } else if (matchingChapters.length > 1) {
      return _EntityResolutionResult(
        isAmbiguous: true,
        question: 'I found multiple chapters matching "$query". Which one did you mean?',
        choices: matchingChapters.map((c) => c.title).take(4).toList(),
      );
    }

    // 3. Check subjects
    final exactSubjects = subjects.where((s) =>
        s.name.toLowerCase() == q || s.displayName.toLowerCase() == q || (s.shortName.isNotEmpty && s.shortName.toLowerCase() == q)).toList();

    if (exactSubjects.length == 1) {
      return _EntityResolutionResult(subject: exactSubjects.first);
    } else if (exactSubjects.length > 1) {
      return _EntityResolutionResult(
        isAmbiguous: true,
        question: 'Which subject did you mean?',
        choices: exactSubjects.map((s) => s.displayName).toList(),
      );
    }

    final matchingSubjects = subjects.where((s) {
      final name = s.name.toLowerCase();
      final display = s.displayName.toLowerCase();
      return name.contains(q) || q.contains(name) || display.contains(q) || q.contains(display);
    }).toList();

    if (matchingSubjects.length == 1) {
      return _EntityResolutionResult(subject: matchingSubjects.first);
    } else if (matchingSubjects.length > 1) {
      return _EntityResolutionResult(
        isAmbiguous: true,
        question: 'I found multiple subjects matching "$query". Which one did you mean?',
        choices: matchingSubjects.map((s) => s.displayName).take(4).toList(),
      );
    }

    // 4. Check tasks
    final matchingTasks = tasks.where((t) => !t.isCompleted && t.title.toLowerCase().contains(q)).toList();
    if (matchingTasks.length == 1) {
      final t = matchingTasks.first;
      final matchedSubj = t.subjectId != null ? subjects.where((s) => s.id == t.subjectId).firstOrNull : null;
      return _EntityResolutionResult(task: t, subject: matchedSubj);
    } else if (matchingTasks.length > 1) {
      return _EntityResolutionResult(
        isAmbiguous: true,
        question: 'Which task did you mean?',
        choices: matchingTasks.map((t) => t.title).take(4).toList(),
      );
    }

    return const _EntityResolutionResult();
  }
}

class _EntityResolutionResult {
  const _EntityResolutionResult({
    this.subject,
    this.chapter,
    this.topic,
    this.task,
    this.isAmbiguous = false,
    this.question,
    this.choices = const [],
  });

  final Subject? subject;
  final Chapter? chapter;
  final Topic? topic;
  final StudentTask? task;
  final bool isAmbiguous;
  final String? question;
  final List<String> choices;

  bool get hasMatch =>
      subject != null || chapter != null || topic != null || task != null;
}
