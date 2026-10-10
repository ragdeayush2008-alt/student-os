import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/data/models/practice_session.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/knowledge/practice_question_controller.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_practice_integration');
    AcademicKnowledgeController.instance.clearData();
    PracticeQuestionController.instance.clearData();
    TopicPracticeController.instance.clearData();
    PlanningBlockController.instance.clearData();
    SubjectController.instance.clearData();
    ProgressionController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Practice Experience 2.0 Integration Tests', () {
    test('1. End-to-end question session flow records attempt, awards XP, and updates intelligence', () async {
      final topic = Topic(
        id: 'top_deprec_integ',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Depreciation Integ',
      );

      // 1. Add fixture questions
      await PracticeQuestionController.instance.addQuestion(
        topicId: topic.id,
        subjectId: topic.subjectId,
        questionText: 'SLM method spreads cost equally?',
        options: ['True', 'False'],
        correctAnswer: 'True',
        explanation: 'Equal depreciation per period.',
      );
      await PracticeQuestionController.instance.addQuestion(
        topicId: topic.id,
        subjectId: topic.subjectId,
        questionText: 'WDV method decreases depreciation each year?',
        options: ['True', 'False'],
        correctAnswer: 'True',
      );

      // 2. Start session
      final session = PracticeQuestionController.instance.createSession(
        topicId: topic.id,
        subjectId: topic.subjectId,
        title: topic.title,
        feedbackMode: PracticeFeedbackMode.learning,
      );

      expect(session.totalQuestions, 2);

      // 3. Answer questions
      session.selectAnswer('True');
      session.next();
      session.selectAnswer('True');

      // 4. Complete session and record attempt
      final result = session.complete();
      expect(result.accuracyPercentage, 100);
      expect(result.isPerfectScore, isTrue);

      final attempt = await TopicPracticeController.instance.recordAttempt(
        topicId: topic.id,
        subjectId: topic.subjectId,
        durationSec: result.durationSec,
        totalQuestions: result.totalQuestions,
        correctAnswers: result.correctCount,
        incorrectAnswers: result.incorrectCount,
        score: 100.0,
      );

      // 5. Verify authoritative attempt record
      expect(TopicPracticeController.instance.attempts.length, 1);
      expect(TopicPracticeController.instance.attempts.first.id, attempt.id);
      expect(TopicPracticeController.instance.practiceMinutesForTopic(topic.id), greaterThanOrEqualTo(0));

      // 6. Verify XP awarded idempotently
      final ledger = ProgressionController.instance.events;
      final practiceEvents = ledger.where((e) => e.id == 'xp_practice_${attempt.id}');
      expect(practiceEvents.length, 1);

      // 7. Verify Academic Knowledge Engine progress reflection
      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        practiceAttempts: TopicPracticeController.instance.attempts,
      );
      expect(progress.practiceAttemptsCount, 1);
      expect(progress.practiceAccuracyPercentage, 100);
      expect(progress.isWeakTopic, isFalse);
    });

    test('2. Plan Practice schedules planning block in calendar', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 16, 0);
      final end = start.add(const Duration(minutes: 20));

      final block = await PlanningBlockController.instance.scheduleTopicBlock(
        'top_math_plan',
        start,
        end,
        subjectId: 'sub_math',
        customTitle: 'Practice — Derivatives',
      );

      expect(block.topicId, 'top_math_plan');
      expect(block.subjectId, 'sub_math');
      expect(block.customTitle, 'Practice — Derivatives');
      expect(PlanningBlockController.instance.blocks.length, 1);
    });

    test('3. User isolation: User A practice data never leaks to User B', () async {
      final pc = TopicPracticeController.instance;
      final qc = PracticeQuestionController.instance;

      // User A records practice and creates question
      AuthIsolation.instance.setAuthenticatedUser('user_A_iso');
      await qc.addQuestion(
        topicId: 'top_iso_test',
        subjectId: 'sub_a',
        questionText: 'User A Question',
        options: ['Yes', 'No'],
        correctAnswer: 'Yes',
      );
      await pc.recordAttempt(
        topicId: 'top_iso_test',
        subjectId: 'sub_a',
        durationSec: 300,
        totalQuestions: 5,
        correctAnswers: 5,
      );

      expect(pc.attempts.length, 1);
      expect(qc.questions.length, 1);

      // Logout and login as User B
      AuthIsolation.instance.setAuthenticatedUser('user_B_iso');
      ControllerIsolation.instance.clearAllControllers();
      await pc.load();
      await qc.load();

      expect(pc.attempts, isEmpty);
      expect(qc.questions, isEmpty);

      // Switch back to User A
      AuthIsolation.instance.setAuthenticatedUser('user_A_iso');
      ControllerIsolation.instance.clearAllControllers();
      await pc.load();
      await qc.load();

      expect(pc.attempts.length, 1);
      expect(qc.questions.length, 1);
    });
  });
}
