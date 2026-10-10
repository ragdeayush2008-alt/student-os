import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/practice_session.dart';
import 'package:student_os/data/models/practice_session_result.dart';
import 'package:student_os/data/models/practice_set.dart';
import 'package:student_os/data/models/question.dart';

void main() {
  group('Question Model Unit Tests', () {
    test('1. Question serialization and deserialization preserves all fields', () {
      final now = DateTime(2026, 3, 15, 10, 30);
      final question = Question(
        id: 'q_1',
        topicId: 'top_deprec',
        chapterId: 'ch_accounting',
        subjectId: 'sub_acc',
        questionText: 'What is the straight-line depreciation method?',
        type: QuestionType.multipleChoice,
        options: ['Method A', 'Method B', 'Method C', 'Method D'],
        correctAnswer: 'Method A',
        explanation: 'Straight-line evenly spreads depreciation over asset life.',
        difficulty: QuestionDifficulty.medium,
        userId: 'user_123',
        createdAt: now,
        updatedAt: now,
      );

      final json = question.toJson();
      final restored = Question.fromJson(json);

      expect(restored.id, question.id);
      expect(restored.topicId, question.topicId);
      expect(restored.chapterId, question.chapterId);
      expect(restored.subjectId, question.subjectId);
      expect(restored.questionText, question.questionText);
      expect(restored.type, QuestionType.multipleChoice);
      expect(restored.options, question.options);
      expect(restored.correctAnswer, question.correctAnswer);
      expect(restored.explanation, question.explanation);
      expect(restored.difficulty, QuestionDifficulty.medium);
      expect(restored.userId, question.userId);
      expect(restored, question);
    });

    test('2. Question handles missing and malformed optional fields gracefully', () {
      final json = <String, dynamic>{
        'id': 'q_sparse',
        'topicId': 'top_1',
        'subjectId': 'sub_1',
        'questionText': 'Sample?',
        'correctAnswer': 'True',
      };

      final question = Question.fromJson(json);
      expect(question.id, 'q_sparse');
      expect(question.chapterId, isNull);
      expect(question.explanation, isNull);
      expect(question.difficulty, QuestionDifficulty.medium);
      expect(question.type, QuestionType.multipleChoice);
      expect(question.options, isEmpty);
      expect(question.isOptionCorrect('True'), isTrue);
      expect(question.isOptionCorrect('true '), isTrue);
      expect(question.isOptionCorrect('False'), isFalse);
    });

    test('3. Question copyWith updates specified fields', () {
      final question = Question(
        id: 'q_orig',
        topicId: 'top_orig',
        subjectId: 'sub_orig',
        questionText: 'Original text',
        correctAnswer: 'A',
      );

      final updated = question.copyWith(
        questionText: 'Updated text',
        correctAnswer: 'B',
        difficulty: QuestionDifficulty.hard,
      );

      expect(updated.id, 'q_orig');
      expect(updated.questionText, 'Updated text');
      expect(updated.correctAnswer, 'B');
      expect(updated.difficulty, QuestionDifficulty.hard);
    });

    test('4. PracticeSet serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 3, 15, 12, 0);
      final set = PracticeSet(
        id: 'set_101',
        title: 'Depreciation Basics',
        topicId: 'top_deprec',
        chapterId: 'ch_accounting',
        subjectId: 'sub_acc',
        questionIds: ['q_1', 'q_2', 'q_3'],
        estimatedMinutes: 15,
        difficulty: QuestionDifficulty.medium,
        userId: 'user_123',
        createdAt: now,
        updatedAt: now,
      );

      final json = set.toJson();
      final restored = PracticeSet.fromJson(json);

      expect(restored.id, set.id);
      expect(restored.title, set.title);
      expect(restored.topicId, set.topicId);
      expect(restored.chapterId, set.chapterId);
      expect(restored.subjectId, set.subjectId);
      expect(restored.questionIds, ['q_1', 'q_2', 'q_3']);
      expect(restored.questionCount, 3);
      expect(restored.estimatedMinutes, 15);
      expect(restored.difficulty, QuestionDifficulty.medium);
      expect(restored, set);
    });

    test('5. PracticeSession lifecycle: answer, skip, previous, next, and complete', () {
      final q1 = Question(
        id: 'q_1',
        topicId: 'top_1',
        subjectId: 'sub_1',
        questionText: 'Question 1',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
      );
      final q2 = Question(
        id: 'q_2',
        topicId: 'top_1',
        subjectId: 'sub_1',
        questionText: 'Question 2',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'B',
      );
      final q3 = Question(
        id: 'q_3',
        topicId: 'top_1',
        subjectId: 'sub_1',
        questionText: 'Question 3',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'C',
      );

      final session = PracticeSession(
        id: 'sess_1',
        topicId: 'top_1',
        subjectId: 'sub_1',
        title: 'Quiz 1',
        questions: [q1, q2, q3],
        feedbackMode: PracticeFeedbackMode.learning,
      );

      expect(session.totalQuestions, 3);
      expect(session.currentQuestionIndex, 0);
      expect(session.hasPrevious, isFalse);
      expect(session.hasNext, isTrue);
      expect(session.isAnswered('q_1'), isFalse);

      // Answer Q1
      session.selectAnswer('A');
      expect(session.isAnswered('q_1'), isTrue);
      expect(session.selectedAnswerFor('q_1'), 'A');

      // Next to Q2 and skip Q2
      session.next();
      expect(session.currentQuestionIndex, 1);
      expect(session.hasPrevious, isTrue);
      session.skipCurrent(); // marks skipped and advances to Q3
      expect(session.isSkipped('q_2'), isTrue);
      expect(session.currentQuestionIndex, 2);

      // Answer Q3 incorrectly
      session.selectAnswer('D');
      expect(session.selectedAnswerFor('q_3'), 'D');

      // Navigate back to Q2 and answer it
      session.previous();
      expect(session.currentQuestionIndex, 1);
      session.selectAnswer('B');
      expect(session.isSkipped('q_2'), isFalse);
      expect(session.isAnswered('q_2'), isTrue);

      // Complete session
      final result = session.complete();
      expect(session.isCompleted, isTrue);
      expect(result.totalQuestions, 3);
      expect(result.answeredCount, 3);
      expect(result.correctCount, 2);
      expect(result.incorrectCount, 1);
      expect(result.skippedCount, 0);
      expect(result.accuracyPercentage, 67);
      expect(result.isPerfectScore, isFalse);
    });

    test('6. PracticeSessionResult creates authoritative TopicPracticeAttempt', () {
      final now = DateTime(2026, 3, 15, 14, 0);
      final q1 = Question(
        id: 'q_1',
        topicId: 'top_taxes',
        subjectId: 'sub_econ',
        questionText: 'What is GST?',
        options: ['Tax A', 'Tax B'],
        correctAnswer: 'Tax A',
      );

      final result = PracticeSessionResult(
        sessionId: 'sess_tax',
        userId: 'user_123',
        topicId: 'top_taxes',
        chapterId: 'ch_fiscal',
        subjectId: 'sub_econ',
        title: 'GST Practice',
        totalQuestions: 1,
        answeredCount: 1,
        correctCount: 1,
        incorrectCount: 0,
        skippedCount: 0,
        accuracyPercentage: 100,
        durationSec: 120,
        completedAt: now,
        details: [
          QuestionResultDetail(
            question: q1,
            studentAnswer: 'Tax A',
            isAnswered: true,
            isSkipped: false,
            isCorrect: true,
            correctAnswer: 'Tax A',
          ),
        ],
        whatWentWell: ['Perfect accuracy!'],
        needsAttention: [],
        recommendedNextStep: 'Ready to advance.',
      );

      final attempt = result.toTopicPracticeAttempt();
      expect(attempt.topicId, 'top_taxes');
      expect(attempt.subjectId, 'sub_econ');
      expect(attempt.chapterId, 'ch_fiscal');
      expect(attempt.userId, 'user_123');
      expect(attempt.totalQuestions, 1);
      expect(attempt.correctAnswers, 1);
      expect(attempt.incorrectAnswers, 0);
      expect(attempt.durationSec, 120);
      expect(attempt.score, 100.0);
      expect(attempt.accuracyPercentage, 100);
      expect(attempt.isCompleted, isTrue);
    });

    test('7. Empty session safety calculations', () {
      final session = PracticeSession(
        id: 'sess_empty',
        title: 'Empty',
        questions: [],
      );

      expect(session.isEmpty, isTrue);
      expect(session.totalQuestions, 0);
      expect(session.currentQuestion, isNull);
      expect(session.hasPrevious, isFalse);
      expect(session.hasNext, isFalse);

      final result = session.computeResult();
      expect(result.totalQuestions, 0);
      expect(result.accuracyPercentage, 0);
      expect(result.correctCount, 0);
      expect(result.details, isEmpty);
    });
  });
}
