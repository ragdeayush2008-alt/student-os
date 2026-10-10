import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/practice_session.dart';
import 'package:student_os/data/models/question.dart';
import 'package:student_os/features/knowledge/presentation/practice_session_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_practice_widget_test');
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  Widget createTestWidget(PracticeSession session, {Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: PracticeSessionScreen(session: session),
      ),
    );
  }

  group('PracticeSessionScreen Widget Tests', () {
    testWidgets('1. Displays question text, options, and progress header', (tester) async {
      final q1 = Question(
        id: 'q_1',
        topicId: 'top_1',
        subjectId: 'sub_1',
        questionText: 'What is the primary function of working capital in business?',
        options: [
          'Option A: Daily operations funding',
          'Option B: Long term fixed assets',
          'Option C: Government taxation',
        ],
        correctAnswer: 'Option A: Daily operations funding',
        explanation: 'Working capital funds short-term day-to-day operations.',
      );

      final session = PracticeSession(
        id: 'sess_1',
        title: 'Working Capital Quiz',
        questions: [q1],
        feedbackMode: PracticeFeedbackMode.learning,
      );

      await tester.pumpWidget(createTestWidget(session));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 1 OF 1'), findsOneWidget);
      expect(find.text('What is the primary function of working capital in business?'), findsOneWidget);
      expect(find.text('Option A: Daily operations funding'), findsOneWidget);
      expect(find.text('Option B: Long term fixed assets'), findsOneWidget);
    });

    testWidgets('2. Learning mode shows instant feedback and explanation upon answering', (tester) async {
      final q1 = Question(
        id: 'q_1',
        topicId: 'top_1',
        subjectId: 'sub_1',
        questionText: 'Sample question?',
        options: ['Correct Answer', 'Wrong Answer'],
        correctAnswer: 'Correct Answer',
        explanation: 'Because it is correct.',
      );

      final session = PracticeSession(
        id: 'sess_1',
        title: 'Instant Feedback Test',
        questions: [q1],
        feedbackMode: PracticeFeedbackMode.learning,
      );

      await tester.pumpWidget(createTestWidget(session));
      await tester.pumpAndSettle();

      // Tap Correct Answer
      await tester.tap(find.text('Correct Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Correct! Nicely done.'), findsOneWidget);
      expect(find.text('Because it is correct.'), findsOneWidget);
      expect(session.isAnswered('q_1'), isTrue);
    });

    testWidgets('3. Exit confirmation dialog prevents accidental loss', (tester) async {
      final q1 = Question(
        id: 'q_1',
        topicId: 'top_1',
        subjectId: 'sub_1',
        questionText: 'Exit test question?',
        options: ['A', 'B'],
        correctAnswer: 'A',
      );

      final session = PracticeSession(
        id: 'sess_exit',
        title: 'Exit Test',
        questions: [q1],
      );

      await tester.pumpWidget(createTestWidget(session));
      await tester.pumpAndSettle();

      // Tap Close (X) icon in AppBar
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Exit practice?'), findsOneWidget);
      expect(find.text('Keep Practicing'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);

      // Keep practicing dismisses dialog
      await tester.tap(find.text('Keep Practicing'));
      await tester.pumpAndSettle();

      expect(find.text('Exit practice?'), findsNothing);
      expect(session.isCompleted, isFalse);
    });

    testWidgets('4. Responsive widths render without overflow (320dp, 360dp, 390dp, 412dp, 430dp)', (tester) async {
      final qLong = Question(
        id: 'q_long',
        topicId: 'top_long',
        subjectId: 'sub_long',
        questionText:
            'A very long and descriptive examination question testing multi-step principles of accounting and depreciation calculation across several operational cycles for manufacturing businesses?',
        options: [
          'Option A: A very long comprehensive answer description that extends onto multiple lines cleanly',
          'Option B: Another long alternative answer description with detailed phrasing',
          'Option C: Third long answer option',
          'Option D: Fourth long answer option',
        ],
        correctAnswer:
            'Option A: A very long comprehensive answer description that extends onto multiple lines cleanly',
        explanation: 'Detailed explanation regarding multi-step accounting.',
      );

      final session = PracticeSession(
        id: 'sess_responsive',
        title: 'Responsive Test',
        questions: [qLong],
      );

      final widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final w in widths) {
        await tester.pumpWidget(createTestWidget(session, size: Size(w, 800)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('QUESTION 1 OF 1'), findsOneWidget);
      }
    });
  });
}
