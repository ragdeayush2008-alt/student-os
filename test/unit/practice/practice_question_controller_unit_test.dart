import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/practice_session.dart';
import 'package:student_os/features/knowledge/practice_question_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_test_practice_ctrl');
    PracticeQuestionController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('PracticeQuestionController Unit Tests', () {
    test('1. Adding and retrieving questions by topic, chapter, and subject', () async {
      final controller = PracticeQuestionController.instance;

      await controller.addQuestion(
        topicId: 'top_deprec',
        chapterId: 'ch_accounting',
        subjectId: 'sub_acc',
        questionText: 'What is straight-line depreciation?',
        options: ['Uniform allocation', 'Accelerated', 'Variable'],
        correctAnswer: 'Uniform allocation',
        explanation: 'Depreciates equally per period.',
      );

      await controller.addQuestion(
        topicId: 'top_deprec',
        chapterId: 'ch_accounting',
        subjectId: 'sub_acc',
        questionText: 'What is salvage value?',
        options: ['Residual value', 'Initial cost', 'Market penalty'],
        correctAnswer: 'Residual value',
      );

      await controller.addQuestion(
        topicId: 'top_inventory',
        chapterId: 'ch_accounting',
        subjectId: 'sub_acc',
        questionText: 'What is FIFO?',
        options: ['First In First Out', 'Last In First Out'],
        correctAnswer: 'First In First Out',
      );

      expect(controller.questions.length, 3);
      expect(controller.questionsForTopic('top_deprec').length, 2);
      expect(controller.questionsForTopic('top_inventory').length, 1);
      expect(controller.questionsForChapter('ch_accounting').length, 3);
      expect(controller.questionsForSubject('sub_acc').length, 3);
      expect(controller.hasQuestionsForTopic('top_deprec'), isTrue);
      expect(controller.hasQuestionsForTopic('top_unknown'), isFalse);
    });

    test('2. Updating and deleting questions', () async {
      final controller = PracticeQuestionController.instance;

      final q = await controller.addQuestion(
        topicId: 'top_calc',
        subjectId: 'sub_math',
        questionText: 'Derivative of x^2?',
        options: ['2x', 'x', 'x^3'],
        correctAnswer: '2x',
      );

      final updated = q.copyWith(
        questionText: 'Derivative of x^3?',
        correctAnswer: '3x^2',
        options: ['3x^2', '2x', 'x^4'],
      );
      await controller.updateQuestion(updated);

      final retrieved = controller.questionsForTopic('top_calc').first;
      expect(retrieved.questionText, 'Derivative of x^3?');
      expect(retrieved.correctAnswer, '3x^2');

      await controller.deleteQuestion(q.id);
      expect(controller.questionsForTopic('top_calc'), isEmpty);
    });

    test('3. Creating PracticeSet and managing question links', () async {
      final controller = PracticeQuestionController.instance;

      final q1 = await controller.addQuestion(
        topicId: 'top_tax',
        subjectId: 'sub_fin',
        questionText: 'Income tax rate?',
        options: ['Progressive', 'Flat'],
        correctAnswer: 'Progressive',
      );

      final set = await controller.createPracticeSet(
        title: 'Taxation Quick Quiz',
        topicId: 'top_tax',
        subjectId: 'sub_fin',
        questionIds: [q1.id],
        estimatedMinutes: 10,
      );

      expect(controller.practiceSets.length, 1);
      expect(controller.practiceSetsForTopic('top_tax').length, 1);
      expect(set.questionIds, [q1.id]);

      // Deleting question removes its reference in the set
      await controller.deleteQuestion(q1.id);
      expect(controller.practiceSetsForTopic('top_tax').first.questionIds, isEmpty);
    });

    test('4. createSession initializes active session with requested parameters', () async {
      final controller = PracticeQuestionController.instance;

      for (int i = 1; i <= 6; i++) {
        await controller.addQuestion(
          topicId: 'top_series',
          subjectId: 'sub_math',
          questionText: 'Question $i',
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
        );
      }

      final session = controller.createSession(
        topicId: 'top_series',
        subjectId: 'sub_math',
        title: 'Math Quiz',
        questionLimit: 5,
        feedbackMode: PracticeFeedbackMode.assessment,
      );

      expect(session.totalQuestions, 5);
      expect(session.feedbackMode, PracticeFeedbackMode.assessment);
      expect(session.title, 'Math Quiz');
      expect(session.currentQuestionIndex, 0);
    });

    test('5. User isolation: User A questions are never visible to User B', () async {
      final controller = PracticeQuestionController.instance;

      // User A adds question
      AuthIsolation.instance.setAuthenticatedUser('user_A_questions');
      await controller.addQuestion(
        topicId: 'top_secret_a',
        subjectId: 'sub_a',
        questionText: 'User A exclusive prompt',
        options: ['A', 'B'],
        correctAnswer: 'A',
      );
      expect(controller.questions.length, 1);
      expect(controller.questions.first.questionText, 'User A exclusive prompt');

      // Switch to User B
      AuthIsolation.instance.setAuthenticatedUser('user_B_questions');
      ControllerIsolation.instance.clearAllControllers();
      await controller.load();

      expect(controller.questions, isEmpty);
      expect(controller.hasQuestionsForTopic('top_secret_a'), isFalse);

      // User B adds their own question
      await controller.addQuestion(
        topicId: 'top_user_b',
        subjectId: 'sub_b',
        questionText: 'User B prompt',
        options: ['X', 'Y'],
        correctAnswer: 'X',
      );
      expect(controller.questions.length, 1);
      expect(controller.questions.first.questionText, 'User B prompt');

      // Switch back to User A
      AuthIsolation.instance.setAuthenticatedUser('user_A_questions');
      ControllerIsolation.instance.clearAllControllers();
      await controller.load();

      expect(controller.questions.length, 1);
      expect(controller.questions.first.questionText, 'User A exclusive prompt');
    });
  });
}
