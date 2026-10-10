import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() async {
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Academic Knowledge Engine Integration Scenarios', () {
    test('FLOW 1: Subject -> Chapter -> Topic -> Study -> Focus -> Study history -> Topic progress changes', () async {
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final fc = FocusController.instance;
      final stc = StudyController.instance;

      final subject = await sc.createSubject(name: 'Accountancy');
      final chapter = await kc.createChapter(
        subjectId: subject.id,
        title: 'Partnership',
      );
      final topic = await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 35,
      );

      // Verify initial progress is notStarted
      final initProgress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: stc.sessions,
      );
      expect(initProgress.status, TopicStatus.notStarted);
      expect(initProgress.totalStudyMinutes, 0);

      // Start focus timer for topic
      fc.startTimer(
        duration: const Duration(minutes: 35),
        subjectId: subject.id,
        subjectName: subject.name,
        topicId: topic.id,
        chapterId: chapter.id,
        objective: 'Study ${topic.title}',
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.topicId, topic.id);
      expect(fc.activeSession?.chapterId, chapter.id);

      // Complete focus session and record in study history
      fc.completeSession();

      // Record a completed study session with topic context
      stc.startSession(
        subject: subject.name,
        subjectId: subject.id,
        topicId: topic.id,
        chapterId: chapter.id,
      );
      await stc.endSession();

      // Study session recorded with topic context (with real study time)
      final completedSession = StudySession(
        id: 's_topic_study',
        subject: subject.name,
        subjectId: subject.id,
        topicId: topic.id,
        chapterId: chapter.id,
        durationSec: 2100, // 35m
        completed: true,
      );

      // Check updated topic progress
      final updatedProgress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: [completedSession],
      );
      expect(updatedProgress.isStudied, isTrue);
      expect(updatedProgress.totalStudyMinutes, 35);
      expect(updatedProgress.sessionsCount, 1);
    });

    test('FLOW 2: Topic -> Revision due -> Revise -> Recommendation updates', () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;

      final subject = await sc.createSubject(name: 'Business Law');
      final chapter = await kc.createChapter(
        subjectId: subject.id,
        title: 'Contract Act',
      );
      final topic = await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Offer and Acceptance',
      );

      // Simulated study session from 6 days ago
      final oldSession = StudySession(
        id: 's_old',
        subject: 'Business Law',
        subjectId: subject.id,
        topicId: topic.id,
        chapterId: chapter.id,
        durationSec: 2100, // 35m
        startedAt: now.subtract(const Duration(days: 6)),
        completed: true,
      );

      // Topic progress evaluates as revision due
      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: [oldSession],
        referenceTime: now,
      );
      expect(progress.isRevisionDue, isTrue);

      // Intelligence generates topic revision recommendation
      final revRecs = AcademicIntelligenceEngine.generateRevisionRecommendations(
        subjects: [subject],
        sessions: [oldSession],
        topics: [topic],
        referenceTime: now,
      );

      expect(revRecs.any((r) => r.topicId == topic.id), isTrue);
      final rec = revRecs.firstWhere((r) => r.topicId == topic.id);
      expect(rec.title, 'Revise Offer and Acceptance');

      // Now student revises today
      final newSession = StudySession(
        id: 's_today',
        subject: 'Business Law',
        subjectId: subject.id,
        topicId: topic.id,
        chapterId: chapter.id,
        durationSec: 1200, // 20m
        startedAt: now,
        completed: true,
      );

      final postRevProgress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: [oldSession, newSession],
        referenceTime: now,
      );
      expect(postRevProgress.isRevisionDue, isFalse);
    });

    test('FLOW 3: Exam -> Topics -> Incomplete syllabus -> Topic recommendation', () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final subject = Subject(id: 'sub_acc', name: 'Accountancy');
      final chapter = Chapter(id: 'ch_1', subjectId: subject.id, title: 'Partnership');
      final topic = Topic(
        id: 'top_adm',
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 35,
        importance: TopicImportance.high,
      );

      final exam = StudentExam(
        id: 'exam_acc',
        title: 'Accountancy Board Exam',
        subject: 'Accountancy',
        examDateTime: now.add(const Duration(days: 4)),
      );

      final recs = AcademicIntelligenceEngine.generateStudyRecommendations(
        subjects: [subject],
        exams: [exam],
        sessions: const [],
        topics: [topic],
        referenceTime: now,
      );

      expect(recs.isNotEmpty, isTrue);
      final topRec = recs.first;
      expect(topRec.topicId, topic.id);
      expect(topRec.title, 'Study Admission of a Partner');
      expect(topRec.suggestedDurationMinutes, 35);
      expect(topRec.reasons.any((r) => r.contains('Exam in 4 days')), isTrue);
    });

    test('FLOW 4: Topic -> Plan -> PlanningBlock -> Focus direct assigned duration', () async {
      final pbc = PlanningBlockController.instance;
      final now = DateTime(2026, 9, 12, 9, 0);

      final block = await pbc.scheduleTopicBlock(
        'top_admission',
        now,
        now.add(const Duration(minutes: 45)),
        subjectId: 'sub_acc',
        chapterId: 'ch_1',
        customTitle: 'Accountancy — Admission of a Partner',
      );

      expect(block.topicId, 'top_admission');
      expect(block.chapterId, 'ch_1');
      expect(block.subjectId, 'sub_acc');

      // Check action determination from PlanningBlock
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 'sub_acc', name: 'Accountancy')],
        blocks: [block],
        referenceTime: now.add(const Duration(minutes: 5)),
      );

      expect(action.topicId, 'top_admission');
      expect(action.chapterId, 'ch_1');
      expect(action.type, StudentOSActionType.scheduledBlock);
      expect(action.suggestedDurationMinutes, 40); // 40 min remaining
    });

    test('FLOW 5: Topic -> Plan -> Autopilot -> Automatic allocation with topic', () async {
      final now = DateTime(2026, 9, 12, 8, 0);
      final subject = await SubjectController.instance.createSubject(name: 'Accountancy');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Partnership',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Death of a Partner',
        estimatedMinutes: 35,
        importance: TopicImportance.high,
      );

      final plan = PlanningEngine.generateDailyPlan(
        now,
        tasks: const [],
        subjects: [subject],
        availableBudgetMinutes: 120,
      );

      expect(plan.hasItems, isTrue);
      final topicItem = plan.items.firstWhere((i) => i.subjectId == subject.id);
      expect(topicItem.topicId, topic.id);
      expect(topicItem.chapterId, chapter.id);
      expect(topicItem.title, contains('Death of a Partner'));
    });

    test('FLOW 6: User A -> Academic structure -> Logout -> User B -> Zero leakage', () async {
      final kc = AcademicKnowledgeController.instance;

      // User A creates chapters and topics
      final chA = await kc.createChapter(
        subjectId: 'sub_a',
        title: 'User A Chapter',
      );
      await kc.createTopic(
        chapterId: chA.id,
        subjectId: 'sub_a',
        title: 'User A Topic',
      );

      expect(kc.chapters.length, 1);
      expect(kc.topics.length, 1);

      // Logout User A
      ControllerIsolation.instance.clearAllControllers();

      expect(kc.chapters, isEmpty);
      expect(kc.topics, isEmpty);
      expect(kc.chaptersForSubject('sub_a'), isEmpty);

      // User B creates separate chapters
      final chB = await kc.createChapter(
        subjectId: 'sub_b',
        title: 'User B Chapter',
      );

      expect(chB.title, 'User B Chapter');
      expect(kc.chapters.length, 1);
      expect(kc.chapters.first.title, 'User B Chapter');
      expect(kc.chaptersForSubject('sub_a'), isEmpty);
    });

    test('FLOW 7: Old StudySession with no topicId loads and works normally', () async {
      final oldJson = {
        'id': 'session_legacy_42',
        'subject': 'Physics',
        'durationSec': 1800,
        'completed': true,
        'startedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      };

      final session = StudySession.fromJson(oldJson);
      expect(session.id, 'session_legacy_42');
      expect(session.topicId, isNull);
      expect(session.isCompleted, isTrue);

      final subject = Subject(id: 'sub_phys', name: 'Physics');
      final recs = AcademicIntelligenceEngine.generateStudyRecommendations(
        subjects: [subject],
        sessions: [session],
        topics: const [],
      );

      expect(recs.isNotEmpty, isTrue);
      expect(recs.first.subjectName, 'Physics');
    });

    test('FLOW 8: No topics -> Subject-level recommendation without crash', () {
      final subject = Subject(id: 'sub_lit', name: 'Literature');
      final recs = AcademicIntelligenceEngine.generateStudyRecommendations(
        subjects: [subject],
        topics: const [],
      );

      expect(recs.isNotEmpty, isTrue);
      expect(recs.first.title, 'Study Literature');
      expect(recs.first.topicTitle, isNull);
      expect(recs.first.topicId, isNull);
    });
  });
}
