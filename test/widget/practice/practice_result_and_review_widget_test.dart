import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/practice_session_result.dart';
import 'package:student_os/data/models/question.dart';
import 'package:student_os/features/knowledge/presentation/practice_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_results_widget_test');
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  final q1 = Question(
    id: 'q_1',
    topicId: 'top_1',
    subjectId: 'sub_1',
    questionText: 'What is asset depreciation?',
    options: ['Cost allocation over useful life', 'Market sale penalty'],
    correctAnswer: 'Cost allocation over useful life',
    explanation: 'Systematic allocation of depreciable amount.',
  );

  final q2 = Question(
    id: 'q_2',
    topicId: 'top_1',
    subjectId: 'sub_1',
    questionText: 'What is salvage value?',
    options: ['Residual value at end of life', 'Initial acquisition cost'],
    correctAnswer: 'Residual value at end of life',
  );

  final sampleResult = PracticeSessionResult(
    sessionId: 'sess_sample',
    title: 'Depreciation Practice',
    totalQuestions: 2,
    answeredCount: 2,
    correctCount: 1,
    incorrectCount: 1,
    skippedCount: 0,
    accuracyPercentage: 50,
    durationSec: 180,
    completedAt: DateTime(2026, 3, 15, 15, 0),
    details: [
      QuestionResultDetail(
        question: q1,
        studentAnswer: 'Cost allocation over useful life',
        isAnswered: true,
        isSkipped: false,
        isCorrect: true,
        correctAnswer: 'Cost allocation over useful life',
        explanation: 'Systematic allocation of depreciable amount.',
      ),
      QuestionResultDetail(
        question: q2,
        studentAnswer: 'Initial acquisition cost',
        isAnswered: true,
        isSkipped: false,
        isCorrect: false,
        correctAnswer: 'Residual value at end of life',
      ),
    ],
    whatWentWell: ['1 question answered correctly.'],
    needsAttention: ['1 question missed.'],
    recommendedNextStep: 'Review mistakes and reinforce weaker concepts with a short revision.',
  );

  Widget createResultWidget(PracticeSessionResult result, {Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: PracticeResultScreen(result: result),
      ),
    );
  }

  group('Practice Result and Review Widget Tests', () {
    testWidgets('1. Displays score hero, metric cards, what went well, and recommendations', (tester) async {
      await tester.pumpWidget(createResultWidget(sampleResult));
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('PRACTICE RECORDED'), findsOneWidget);
      expect(find.text('Depreciation Practice'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget); // Correct count
      expect(find.text('3m 0s'), findsOneWidget); // Duration
      expect(find.text('WHAT WENT WELL'), findsOneWidget);
      expect(find.text('NEEDS ATTENTION'), findsOneWidget);
      expect(find.text('RECOMMENDED NEXT STEP'), findsOneWidget);
      expect(find.text('Review Mistakes & Answers'), findsOneWidget);
    });

    testWidgets('2. Tapping Review Mistakes opens PracticeReviewMistakesSheet', (tester) async {
      await tester.pumpWidget(createResultWidget(sampleResult));
      await tester.pumpAndSettle();

      final reviewButton = find.text('Review Mistakes & Answers');
      await tester.ensureVisible(reviewButton);
      await tester.pumpAndSettle();

      await tester.tap(reviewButton);
      await tester.pumpAndSettle();

      expect(find.text('Review Questions'), findsOneWidget);
      expect(find.text('Your answer: '), findsOneWidget);
      expect(find.text('Initial acquisition cost'), findsOneWidget);
      expect(find.text('Correct answer: '), findsOneWidget);
      expect(find.text('Residual value at end of life'), findsOneWidget);
    });

    testWidgets('3. Responsive rendering on 320dp, 360dp, 390dp, 412dp, 430dp without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final w in widths) {
        await tester.pumpWidget(createResultWidget(sampleResult, size: Size(w, 800)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('50%'), findsOneWidget);
      }
    });
  });
}
