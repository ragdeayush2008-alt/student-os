import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/knowledge/practice_question_controller.dart';
import 'package:student_os/features/resources/resource_controller.dart';
import 'package:student_os/features/revision/revision_controller.dart';
import 'package:student_os/features/revision/revision_screen.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_rev_screen_test');
    AcademicKnowledgeController.instance.clearData();
    RevisionController.instance.clearData();
    SubjectController.instance.clearData();
    StudyController.instance.clearData();
    ResourceController.instance.clearData();
    ExamController.instance.clearData();
    PracticeQuestionController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  Widget createRevisionWidget({Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: const MaterialApp(
        home: RevisionScreen(),
      ),
    );
  }

  group('RevisionScreen (Revision Center 2.0) Widget Tests', () {
    testWidgets('1. Displays momentum bar, header, and empty state when no revisions exist', (tester) async {
      await tester.pumpWidget(createRevisionWidget());
      await tester.pumpAndSettle();

      expect(find.text('Revision & Spaced Learning'), findsOneWidget);
      expect(find.text('REVISION'), findsOneWidget);
      expect(find.text('Your memory queue, simplified.'), findsOneWidget);
      expect(find.text('Due Today'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('You\'re caught up on revision!'), findsOneWidget);
    });

    testWidgets('2. Displays hero recommendation and queue tile when topics are due for revision', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Economics');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Microeconomics',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Elasticity of Demand',
      );

      // Record study session 5 days ago -> due for revision
      final now = DateTime.now();
      await StudyController.instance.recordFocusCompletion(
        focusSessionId: 'sess_econ_1',
        topicId: topic.id,
        subjectId: subject.id,
        subject: 'Economics',
        startedAt: now.subtract(const Duration(days: 5)),
        completed: true,
        durationSec: 1800,
      );

      await tester.pumpWidget(createRevisionWidget());
      await tester.pumpAndSettle();

      expect(find.text('Elasticity of Demand'), findsWidgets);
      expect(find.text('OVERDUE REVISION'), findsOneWidget);
      expect(find.text('Why?'), findsOneWidget);
      expect(find.textContaining('Due & Overdue'), findsOneWidget);
    });

    testWidgets('3. Responsive widths render without overflow (320dp, 360dp, 390dp, 412dp, 430dp)', (tester) async {
      final widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final w in widths) {
        await tester.pumpWidget(createRevisionWidget(size: Size(w, 800)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Your memory queue, simplified.'), findsOneWidget);
      }
    });
  });
}
