import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/knowledge/practice_question_controller.dart';
import 'package:student_os/features/knowledge/presentation/practice_center_screen.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_practice_center_test');
    AcademicKnowledgeController.instance.clearData();
    PracticeQuestionController.instance.clearData();
    TopicPracticeController.instance.clearData();
    SubjectController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  Widget createCenterWidget({Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: const MaterialApp(
        home: PracticeCenterScreen(),
      ),
    );
  }

  group('PracticeCenterScreen Widget Tests', () {
    testWidgets('1. Displays header, stats, and empty recent attempts state when no data exists', (tester) async {
      await tester.pumpWidget(createCenterWidget());
      await tester.pumpAndSettle();

      expect(find.text('Practice & Quiz Center'), findsOneWidget);
      expect(find.text('PRACTICE'), findsOneWidget);
      expect(find.text('Sharpen what you know.'), findsOneWidget);
      expect(find.text('Attempts'), findsOneWidget);
      expect(find.text('0'), findsWidgets); // 0 attempts, 0 questions
      expect(find.text('No practice attempts yet.'), findsOneWidget);
    });

    testWidgets('2. Displays stats and attempts when practice history exists', (tester) async {
      final subject = Subject(id: 'sub_acc', name: 'Accounting');
      final topic = Topic(
        id: 'top_deprec',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Depreciation Practice',
      );

      await SubjectController.instance.createSubject(name: 'Accounting');
      await TopicPracticeController.instance.recordAttempt(
        topicId: topic.id,
        subjectId: subject.id,
        durationSec: 600,
        totalQuestions: 10,
        correctAnswers: 8, // 80%
      );

      await tester.pumpWidget(createCenterWidget());
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets); // 1 attempt
      expect(find.text('10'), findsOneWidget); // 10 questions
      expect(find.text('80%'), findsWidgets); // 80% accuracy
      expect(find.text('10m'), findsOneWidget); // 10m practice time
    });

    testWidgets('3. Responsive rendering on 320dp, 360dp, 390dp, 412dp, 430dp without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final w in widths) {
        await tester.pumpWidget(createCenterWidget(size: Size(w, 800)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Sharpen what you know.'), findsOneWidget);
      }
    });
  });
}
