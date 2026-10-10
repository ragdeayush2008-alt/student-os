import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/analytics/performance_snapshot.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/core/navigation/focus_launch_context.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/data/models/topic_practice_attempt.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_academic_2_test');
    FocusController.instance.cancelSession();
    ControllerIsolation.instance.clearAllControllers();
    await ProgressionController.instance.load();
    await SubjectController.instance.load();
    await AcademicKnowledgeController.instance.load();
    await StudyController.instance.load();
    await FocusController.instance.load();
    await PlanningBlockController.instance.load();
    await TopicPracticeController.instance.load();
    await ExamController.instance.load();
    await TaskController.instance.load();
  });

  tearDown(() {
    FocusController.instance.cancelSession();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  group('Student OS 6.0 — Learning Experience 2.0 Integration Suite', () {
    // 1. Subject with zero topics
    test('1. Subject with zero topics assesses safe empty state', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Sociology');
      final progress = AcademicKnowledgeEngine.assessSubjectProgress(
        subject,
        chapters: [],
        topics: [],
        sessions: [],
      );

      expect(progress.hasSyllabus, isFalse);
      expect(progress.totalTopics, 0);
      expect(progress.studiedTopics, 0);
      expect(progress.syllabusPercentage, 0);
      expect(progress.health, SubjectHealthState.onTrack);
    });

    // 2. Subject with topics
    test('2. Subject with topics computes overall progress and learning health', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Accountancy');
      final ch = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Depreciation',
      );
      final t1 = await AcademicKnowledgeController.instance.createTopic(
        chapterId: ch.id,
        subjectId: subject.id,
        title: 'Straight Line Method',
      );
      await AcademicKnowledgeController.instance.createTopic(
        chapterId: ch.id,
        subjectId: subject.id,
        title: 'Written Down Value Method',
      );

      // Record study for t1
      await StudyController.instance.recordFocusCompletion(
        focusSessionId: 'f_test_1',
        subject: subject.name,
        subjectId: subject.id,
        topicId: t1.id,
        chapterId: ch.id,
        durationSec: 2400, // 40m
        completed: true,
      );

      final progress = AcademicKnowledgeEngine.assessSubjectProgress(
        subject,
        chapters: AcademicKnowledgeController.instance.chaptersForSubject(subject.id),
        topics: AcademicKnowledgeController.instance.topicsForSubject(subject.id),
        sessions: StudyController.instance.sessions,
      );

      expect(progress.hasSyllabus, isTrue);
      expect(progress.totalTopics, 2);
      expect(progress.studiedTopics, 1);
      expect(progress.syllabusPercentage, 50);
      expect(progress.totalStudyMinutes, 40);
    });

    // 3. Chapter progress
    test('3. Chapter progress reflects studied topics count and completion fraction', () async {
      final ch = await AcademicKnowledgeController.instance.createChapter(
        subjectId: 'sub_math',
        title: 'Calculus',
      );
      final t1 = await AcademicKnowledgeController.instance.createTopic(
        chapterId: ch.id,
        subjectId: 'sub_math',
        title: 'Limits',
      );
      final t2 = await AcademicKnowledgeController.instance.createTopic(
        chapterId: ch.id,
        subjectId: 'sub_math',
        title: 'Derivatives',
      );

      await StudyController.instance.recordFocusCompletion(
        focusSessionId: 'f_calc_1',
        subject: 'Math',
        topicId: t1.id,
        chapterId: ch.id,
        durationSec: 1800,
        completed: true,
      );
      await StudyController.instance.recordFocusCompletion(
        focusSessionId: 'f_calc_2',
        subject: 'Math',
        topicId: t2.id,
        chapterId: ch.id,
        durationSec: 1800,
        completed: true,
      );

      final chProgress = AcademicKnowledgeEngine.assessChapterProgress(
        ch,
        AcademicKnowledgeController.instance.topicsForChapter(ch.id),
        sessions: StudyController.instance.sessions,
      );

      expect(chProgress.totalTopics, 2);
      expect(chProgress.studiedTopics, 2);
      expect(chProgress.completionPercentage, 100);
      expect(chProgress.totalStudyMinutes, 60);
    });

    // 4. Topic state presentation
    test('4. Topic state derives status label and recommended action label conservatively', () async {
      final topic = Topic(
        id: 'top_eco',
        chapterId: 'ch_eco',
        subjectId: 'sub_eco',
        title: 'National Income',
        estimatedMinutes: 40,
      );

      final notStarted = AcademicKnowledgeEngine.assessTopicProgress(topic, sessions: []);
      expect(notStarted.status, TopicStatus.notStarted);
      expect(notStarted.recommendedActionLabel, 'Start Learning');

      final session = StudySession(
        id: 's_eco',
        subject: 'Economics',
        topicId: 'top_eco',
        durationSec: 2400,
        completed: true,
      );
      final studied = AcademicKnowledgeEngine.assessTopicProgress(topic, sessions: [session]);
      expect(studied.status, TopicStatus.studied);
      expect(studied.recommendedActionLabel, 'Study Topic');
    });

    // 5. Topic -> Study
    test('5. Topic study session records authoritative study session', () async {
      final sc = StudyController.instance;
      sc.startSession(
        subject: 'Accountancy',
        subjectId: 'sub_acc',
        chapterId: 'ch_1',
        topicId: 'top_dep',
      );
      expect(sc.hasActiveSession, isTrue);
      expect(sc.activeTopicId, 'top_dep');

      final ended = await sc.endSession(note: 'Finished initial reading');
      expect(ended, isNotNull);
      expect(ended!.topicId, 'top_dep');
      expect(ended.isCompleted, isTrue);
      expect(sc.sessionsForTopic('top_dep').length, 1);
    });

    // 6. Topic -> Revision
    test('6. Revision due topic produces explainable revision recommendation', () async {
      final now = DateTime(2026, 9, 15);
      final topic = Topic(
        id: 'top_law',
        chapterId: 'ch_law',
        subjectId: 'sub_law',
        title: 'Contract Act 1872',
      );

      final pastSession = StudySession(
        id: 's_law',
        subject: 'Law',
        topicId: 'top_law',
        startedAt: now.subtract(const Duration(days: 8)),
        durationSec: 1800,
        completed: true,
      );

      final revRecs = AcademicIntelligenceEngine.generateRevisionRecommendations(
        subjects: [Subject(id: 'sub_law', name: 'Law')],
        sessions: [pastSession],
        topics: [topic],
        referenceTime: now,
      );

      expect(revRecs.any((r) => r.topicId == 'top_law'), isTrue);
      final lawRec = revRecs.firstWhere((r) => r.topicId == 'top_law');
      expect(lawRec.title, 'Revise Contract Act 1872');
      expect(lawRec.isOverdue, isTrue);
      expect(lawRec.reasons.first, contains('Last studied 8 days ago'));
    });

    // 7. Topic -> Focus mode selection
    test('7. Topic Focus mode initializes with correct context and mode', () {
      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 35),
        subjectId: 'sub_acc',
        subjectName: 'Accountancy',
        chapterId: 'ch_1',
        topicId: 'top_dep',
        objective: 'Study Depreciation',
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.timer);
      expect(fc.activeSession!.topicId, 'top_dep');
      expect(fc.activeSession!.subjectId, 'sub_acc');
      expect(fc.activeSession!.chapterId, 'ch_1');
      expect(fc.activeSession!.objective, 'Study Depreciation');
      fc.cancelSession();
    });

    // 8. Topic -> Focus context preservation
    test('8. FocusLaunchContext preserves all topic, chapter, subject, and task identifiers', () {
      const context = FocusLaunchContext(
        subjectId: 's_1',
        subjectName: 'Physics',
        chapterId: 'ch_optics',
        topicId: 'top_refraction',
        topicName: 'Refraction & Snell\'s Law',
        taskId: 'task_hw_1',
        focusTitle: 'Study Refraction',
        duration: Duration(minutes: 45),
      );

      final json = context.toJson();
      final restored = FocusLaunchContext.fromJson(json);

      expect(restored.subjectId, 's_1');
      expect(restored.subjectName, 'Physics');
      expect(restored.chapterId, 'ch_optics');
      expect(restored.topicId, 'top_refraction');
      expect(restored.topicName, 'Refraction & Snell\'s Law');
      expect(restored.taskId, 'task_hw_1');
      expect(restored.duration, const Duration(minutes: 45));
    });

    // 9. Topic -> Planning
    test('9. Topic can be scheduled into PlanningBlockController cleanly', () async {
      final now = DateTime.now();
      final start = now.add(const Duration(hours: 1));
      final end = start.add(const Duration(minutes: 45));

      final block = await PlanningBlockController.instance.scheduleTopicBlock(
        'top_math_1',
        start,
        end,
        subjectId: 'sub_math',
        chapterId: 'ch_math',
        customTitle: 'Math — Integration',
      );

      expect(block.topicId, 'top_math_1');
      expect(block.subjectId, 'sub_math');
      expect(block.chapterId, 'ch_math');
      expect(block.isTopicBlock, isTrue);
      expect(block.customTitle, 'Math — Integration');
    });

    // 10. Practice creation
    test('10. Practice attempt creates with duration, questions, and scores', () async {
      final attempt = await TopicPracticeController.instance.recordAttempt(
        topicId: 'top_matrices',
        subjectId: 'sub_math',
        durationSec: 900,
        totalQuestions: 10,
        correctAnswers: 9,
        notes: 'Inverse matrices problems',
      );

      expect(attempt.id, isNotEmpty);
      expect(attempt.durationSec, 900);
      expect(attempt.totalQuestions, 10);
      expect(attempt.correctAnswers, 9);
      expect(attempt.accuracyPercentage, 90);
      expect(attempt.isCompleted, isTrue);
    });

    // 11. Practice persistence
    test('11. Practice attempts persist to local storage across controller reload', () async {
      AuthIsolation.instance.setAuthenticatedUser('user_prac_persist');
      TopicPracticeController.instance.clearData();
      await TopicPracticeController.instance.recordAttempt(
        topicId: 'top_persisted',
        durationSec: 600,
        notes: 'Persisted practice',
      );

      TopicPracticeController.instance.clearData();
      expect(TopicPracticeController.instance.attempts.isEmpty, isTrue);

      await TopicPracticeController.instance.load();
      expect(TopicPracticeController.instance.attempts.length, 1);
      expect(TopicPracticeController.instance.attempts.first.topicId, 'top_persisted');
      expect(TopicPracticeController.instance.attempts.first.notes, 'Persisted practice');
    });

    // 12. Practice user isolation
    test('12. User A practice attempts never appear for User B', () async {
      final pc = TopicPracticeController.instance;

      AuthIsolation.instance.setAuthenticatedUser('user_A_prac_iso');
      pc.clearData();
      await pc.recordAttempt(topicId: 'top_user_a', durationSec: 600);
      expect(pc.attempts.length, 1);

      pc.clearData();
      AuthIsolation.instance.setAuthenticatedUser('user_B_prac_iso');
      await pc.load();
      expect(pc.attempts.isEmpty, isTrue);
    });

    // 13. Practice offline behavior
    test('13. Practice controller works entirely offline without crashing', () async {
      final pc = TopicPracticeController.instance;
      final attempt = await pc.recordAttempt(
        topicId: 'top_offline',
        durationSec: 1200,
        totalQuestions: 5,
        correctAnswers: 5,
      );

      expect(attempt.topicId, 'top_offline');
      expect(pc.practiceMinutesForTopic('top_offline'), 20);
    });

    // 14. Practice legacy JSON compatibility
    test('14. TopicPracticeAttempt loads legacy JSON without optional fields safely', () {
      final legacy = {
        'id': 'prac_old',
        'topicId': 'top_old',
        'durationSec': 300,
      };

      final restored = TopicPracticeAttempt.fromJson(legacy);
      expect(restored.id, 'prac_old');
      expect(restored.topicId, 'top_old');
      expect(restored.durationSec, 300);
      expect(restored.totalQuestions, isNull);
      expect(restored.correctAnswers, isNull);
      expect(restored.score, isNull);
    });

    // 15. Focus completion -> Study exactly once (idempotent)
    test('15. Focus session completion bridges into StudyController exactly once', () async {
      final sc = StudyController.instance;
      final initialCount = sc.sessions.length;

      final s1 = await sc.recordFocusCompletion(
        focusSessionId: 'focus_unique_123',
        subject: 'Tax Law',
        durationSec: 1500,
        completed: true,
      );
      expect(sc.sessions.length, initialCount + 1);

      // Repeat call with same focusSessionId does not create duplicate
      final s2 = await sc.recordFocusCompletion(
        focusSessionId: 'focus_unique_123',
        subject: 'Tax Law',
        durationSec: 1500,
        completed: true,
      );
      expect(s2.id, s1.id);
      expect(sc.sessions.length, initialCount + 1);
    });

    // 16. Abandoned Focus does not create completed study
    test('16. Abandoned focus session is recorded as completed:false and ignored by study totals', () async {
      final sc = StudyController.instance;

      await sc.recordFocusCompletion(
        focusSessionId: 'focus_abandoned_999',
        subject: 'Audit',
        durationSec: 300,
        completed: false, // cancelled / abandoned
      );

      expect(sc.completedSessions.any((s) => s.focusSessionId == 'focus_abandoned_999'), isFalse);
      expect(sc.studyMinutesForSubject('Audit'), 0);
    });

    // 17. Exam -> weak topic
    test('17. Exam pressure reflects incomplete syllabus topics', () {
      final exam = StudentExam(
        id: 'exam_tax',
        title: 'Direct Tax Final',
        subject: 'Direct Tax',
        examDateTime: DateTime.now().add(const Duration(days: 3)),
        syllabusItems: List.generate(
          10,
          (i) => SyllabusItem(id: 's_$i', title: 'Topic $i', completed: i < 2),
        ),
      );

      final pressure = AcademicIntelligenceEngine.assessExamPressure(
        exam,
        sessions: [],
        tasks: [],
      );

      expect(pressure.level, ExamPressureLevel.critical);
      expect(pressure.syllabusRemainingCount, 8);
      expect(pressure.daysRemaining, 3);
    });

    // 18. Exam -> revision
    test('18. Approaching exam triggers high priority revision recommendation for its syllabus items', () {
      final now = DateTime(2026, 9, 15);
      final exam = StudentExam(
        id: 'exam_corporate',
        title: 'Corporate Law Exam',
        subject: 'Corporate Law',
        examDateTime: now.add(const Duration(days: 2)),
        syllabusItems: [
          SyllabusItem(id: 'syl_1', title: 'Board Meetings', completed: true, completedAt: now.subtract(const Duration(days: 4))),
        ],
      );

      final revs = AcademicIntelligenceEngine.generateRevisionRecommendations(
        subjects: [Subject(id: 'sub_corp', name: 'Corporate Law')],
        exams: [exam],
        referenceTime: now,
      );

      expect(revs.any((r) => r.topicTitle == 'Board Meetings'), isTrue);
      final r = revs.firstWhere((r) => r.topicTitle == 'Board Meetings');
      expect(r.urgency, RecommendationUrgency.critical);
      expect(r.isOverdue, isTrue);
    });

    // 19. Exam -> Focus context
    test('19. Focus context preserved from exam context', () {
      const ctx = FocusLaunchContext(
        examId: 'exam_fin_1',
        examTitle: 'Financial Management',
        subjectName: 'Finance',
        focusTitle: 'Prepare for Financial Management',
        duration: Duration(minutes: 50),
      );

      expect(ctx.hasExam, isTrue);
      expect(ctx.examTitle, 'Financial Management');
      expect(ctx.duration, const Duration(minutes: 50));
    });

    // 20. Assistant -> topic
    test('20. Assistant parses "study [topic name]" and resolves topic entity', () {
      FocusController.instance.cancelSession();
      const engine = StudentAssistantEngine();
      final topic = Topic(
        id: 'top_gst',
        chapterId: 'ch_tax',
        subjectId: 'sub_tax',
        title: 'Input Tax Credit',
        estimatedMinutes: 45,
      );

      final result = engine.process(
        'study Input Tax Credit',
        topics: [topic],
      );

      expect(result.success, isTrue);
      expect(result.primaryAction, isNotNull);
      expect(result.primaryAction!.topicId, 'top_gst');
      expect(result.primaryAction!.duration, const Duration(minutes: 45));
    });

    // 21. Assistant -> revision
    test('21. Assistant parses "what should I revise?" and returns prioritized revision items', () {
      FocusController.instance.cancelSession();
      const engine = StudentAssistantEngine();
      final now = DateTime(2026, 9, 15);
      final topic = Topic(
        id: 'top_costing',
        chapterId: 'ch_cost',
        subjectId: 'sub_cost',
        title: 'Marginal Costing',
      );

      final pastSession = StudySession(
        id: 's_cost',
        subject: 'Costing',
        topicId: 'top_costing',
        startedAt: now.subtract(const Duration(days: 7)),
        durationSec: 1800,
        completed: true,
      );

      final result = engine.process(
        'what should I revise?',
        subjects: [Subject(id: 'sub_cost', name: 'Costing')],
        topics: [topic],
        sessions: [pastSession],
        referenceTime: now,
      );

      expect(result.success, isTrue);
      expect(result.primaryAction, isNotNull);
      expect(result.primaryAction!.topicId, 'top_costing');
      expect(result.title, contains('Marginal Costing'));
    });

    // 22. Assistant -> study
    test('22. Assistant parses "what should I study?" and selects highest priority subject/topic', () {
      FocusController.instance.cancelSession();
      const engine = StudentAssistantEngine();
      final sub1 = Subject(id: 'sub_1', name: 'Auditing', preference: SubjectPreference.high);
      final sub2 = Subject(id: 'sub_2', name: 'Economics', preference: SubjectPreference.low);

      final result = engine.process(
        'what should I study?',
        subjects: [sub1, sub2],
      );

      expect(result.success, isTrue);
      expect(result.primaryAction, isNotNull);
      expect(result.primaryAction!.subjectId, 'sub_1');
    });

    // 23. Home learning recommendation
    test('23. Academic intelligence engine provides deterministic primary study recommendation for Home', () {
      final subjects = [
        Subject(id: 'sub_fm', name: 'Financial Management', preference: SubjectPreference.high),
      ];

      final rec = AcademicIntelligenceEngine.generateUnifiedRecommendation(
        subjects: subjects,
      );

      expect(rec.hasRecommendation, isTrue);
      expect(rec.primary!.subjectName, 'Financial Management');
      expect(rec.primary!.suggestedDurationMinutes, 35);
    });

    // 24. Analytics topic data
    test('24. PerformanceSnapshot includes topics and practice attempts truthfully', () {
      final snapshot = PerformanceSnapshot.fromControllers();
      expect(snapshot.allTopics, isNotNull);
      expect(snapshot.allPracticeAttempts, isNotNull);
    });

    // 25. User A -> logout -> User B isolation
    test('25. User A logout clears in-memory academic and practice state before User B loads', () async {
      AuthIsolation.instance.setAuthenticatedUser('user_A_iso_unique');
      AcademicKnowledgeController.instance.clearData();
      TopicPracticeController.instance.clearData();

      await AcademicKnowledgeController.instance.createChapter(subjectId: 'sub_a', title: 'Chapter A');
      await TopicPracticeController.instance.recordAttempt(topicId: 'top_a', durationSec: 600);

      expect(AcademicKnowledgeController.instance.chapters.length, 1);
      expect(TopicPracticeController.instance.attempts.length, 1);

      // Logout User A
      ControllerIsolation.instance.clearAllControllers();
      expect(AcademicKnowledgeController.instance.chapters.isEmpty, isTrue);
      expect(TopicPracticeController.instance.attempts.isEmpty, isTrue);

      // User B login
      AuthIsolation.instance.setAuthenticatedUser('user_B_iso_unique');
      await AcademicKnowledgeController.instance.load();
      await TopicPracticeController.instance.load();
      expect(AcademicKnowledgeController.instance.chapters.isEmpty, isTrue);
      expect(TopicPracticeController.instance.attempts.isEmpty, isTrue);
    });

    // 26. User B -> logout -> User A restoration
    test('26. User B logout and User A re-login restores User A persisted data safely', () async {
      AuthIsolation.instance.setAuthenticatedUser('user_A_restore_unique');
      AcademicKnowledgeController.instance.clearData();
      TopicPracticeController.instance.clearData();

      await AcademicKnowledgeController.instance.createChapter(subjectId: 'sub_a', title: 'Chapter A Persisted');
      await TopicPracticeController.instance.recordAttempt(topicId: 'top_a_persisted', durationSec: 1200);

      // Switch to User B
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.setAuthenticatedUser('user_B_restore_unique');
      await AcademicKnowledgeController.instance.load();
      await TopicPracticeController.instance.load();
      expect(AcademicKnowledgeController.instance.chapters.isEmpty, isTrue);

      // Switch back to User A
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.setAuthenticatedUser('user_A_restore_unique');
      await AcademicKnowledgeController.instance.load();
      await TopicPracticeController.instance.load();

      expect(AcademicKnowledgeController.instance.chapters.length, 1);
      expect(AcademicKnowledgeController.instance.chapters.first.title, 'Chapter A Persisted');
      expect(TopicPracticeController.instance.attempts.length, 1);
      expect(TopicPracticeController.instance.attempts.first.topicId, 'top_a_persisted');
    });

    // 27. Long topic name
    test('27. Topic with extremely long name serializes and assesses safely without error', () {
      const longName = 'Analysis and Interpretation of Consolidated Financial Statements under Indian Accounting Standards Ind AS 110 and 111 with Special Reference to Joint Ventures';
      final topic = Topic(
        id: 'top_long',
        chapterId: 'ch_long',
        subjectId: 'sub_long',
        title: longName,
      );

      final json = topic.toJson();
      final restored = Topic.fromJson(json);
      expect(restored.title, longName);

      final prog = AcademicKnowledgeEngine.assessTopicProgress(topic);
      expect(prog.topic.title, longName);
      expect(prog.status, TopicStatus.notStarted);
    });

    // 28. Many topics
    test('28. Subject with 50 topics evaluates progress efficiently without performance bottlenecks', () {
      final subject = Subject(id: 'sub_large', name: 'Comprehensive Engineering');
      final chapters = List.generate(10, (i) => Chapter(id: 'ch_$i', subjectId: 'sub_large', title: 'Chapter $i'));
      final topics = List.generate(50, (i) => Topic(
        id: 'top_$i',
        chapterId: 'ch_${i % 10}',
        subjectId: 'sub_large',
        title: 'Topic $i',
      ));

      final stopwatch = Stopwatch()..start();
      final progress = AcademicKnowledgeEngine.assessSubjectProgress(
        subject,
        chapters: chapters,
        topics: topics,
        sessions: [],
      );
      stopwatch.stop();

      expect(progress.totalTopics, 50);
      expect(progress.studiedTopics, 0);
      expect(progress.chapterProgresses.length, 10);
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    // 29. Empty subject
    test('29. Empty subject handles all operations gracefully', () {
      final subject = Subject(id: 'sub_empty', name: '');
      final progress = AcademicKnowledgeEngine.assessSubjectProgress(
        subject,
        chapters: [],
        topics: [],
        sessions: [],
      );

      expect(progress.hasSyllabus, isFalse);
      expect(progress.health, SubjectHealthState.onTrack);
    });

    // 30. Offline subject/topic experience
    test('30. Full academic hierarchy CRUD operates entirely offline locally', () async {
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(subjectId: 'sub_offline', title: 'Offline Chapter');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: 'sub_offline', title: 'Offline Topic');

      expect(kc.chaptersForSubject('sub_offline').length, 1);
      expect(kc.topicsForChapter(ch.id).length, 1);

      await kc.updateTopic(top.copyWith(description: 'Updated offline'));
      expect(kc.topicById(top.id)!.description, 'Updated offline');

      await kc.deleteTopic(top.id);
      expect(kc.topicsForChapter(ch.id).isEmpty, isTrue);

      await kc.deleteChapter(ch.id);
      expect(kc.chaptersForSubject('sub_offline').isEmpty, isTrue);
    });
  });
}
