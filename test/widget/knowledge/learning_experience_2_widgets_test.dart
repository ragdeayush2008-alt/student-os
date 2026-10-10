import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/knowledge/presentation/practice_record_sheet.dart';
import 'package:student_os/features/knowledge/presentation/topic_detail_sheet.dart';
import 'package:student_os/features/knowledge/presentation/widgets/chapter_card.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/subjects/subject_detail_screen.dart';

Widget _buildTestWidget(Widget child, {double width = 390, double height = 844}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        padding: const EdgeInsets.only(top: 44, bottom: 34),
      ),
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_widget_test');
    ControllerIsolation.instance.clearAllControllers();
    await SubjectController.instance.load();
    await AcademicKnowledgeController.instance.load();
    await TopicPracticeController.instance.load();
  });

  tearDown(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  group('Learning Experience 2.0 Widget & Responsive Tests', () {
    testWidgets('1. SubjectDetailScreen renders cleanly across 320dp, 360dp, 390dp, 412dp, 430dp without overflow', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Financial Accounting & Reporting Standards',
        shortName: 'FAR',
        description: 'Comprehensive financial accounting and IFRS reporting principles.',
      );

      final ch = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Chapter 1: Depreciation & Asset Valuations',
      );

      await AcademicKnowledgeController.instance.createTopic(
        chapterId: ch.id,
        subjectId: subject.id,
        title: 'Straight Line vs Written Down Value Method with Multi-Asset Accounting',
      );

      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];

      for (final w in widths) {
        await tester.pumpWidget(_buildTestWidget(
          SubjectDetailScreen(subjectId: subject.id),
          width: w,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Financial Accounting & Reporting Standards'), findsAtLeastNWidgets(1));
        expect(find.text('FAR'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('2. SubjectDetailScreen renders honest empty state when subject has zero chapters/topics', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Empty Subject',
      );

      await tester.pumpWidget(_buildTestWidget(
        SubjectDetailScreen(subjectId: subject.id),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No chapters added yet'), findsOneWidget);
      expect(find.text('Add First Chapter'), findsOneWidget);
      expect(find.text('0/0 topics studied'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. ChapterCard expands and renders topics with action buttons', (tester) async {
      final chapter = Chapter(
        id: 'ch_test_card',
        subjectId: 'sub_test',
        title: 'Company Accounts',
        description: 'Shares, debentures and underwriting.',
      );

      await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: 'sub_test',
        title: 'Issue of Shares at Premium',
      );

      await tester.pumpWidget(_buildTestWidget(
        Scaffold(
          body: ChapterCard(
            chapter: chapter,
            subjectId: 'sub_test',
            initiallyExpanded: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Company Accounts'), findsOneWidget);
      expect(find.text('Issue of Shares at Premium'), findsOneWidget);
      expect(find.text('Add Topic to Chapter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. TopicDetailSheet renders 4 Pillars: LEARN, PRACTICE, REVISE, MASTERY BREAKDOWN', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Auditing');
      final ch = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Audit Planning',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: ch.id,
        subjectId: subject.id,
        title: 'Materiality & Audit Risk',
        description: 'Determining performance materiality in financial audit.',
      );

      await tester.pumpWidget(_buildTestWidget(
        Scaffold(
          body: TopicDetailSheet(topicId: topic.id),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Materiality & Audit Risk'), findsOneWidget);
      expect(find.text('WHAT NEXT?'), findsOneWidget);
      expect(find.text('LEARN'), findsOneWidget);
      expect(find.text('PRACTICE'), findsOneWidget);
      expect(find.text('REVISE'), findsOneWidget);
      expect(find.text('MASTERY BREAKDOWN'), findsOneWidget);
      expect(find.text('Study (35m)'), findsOneWidget);
      expect(find.text('Schedule into Plan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. PracticeRecordSheet validates duration and records practice attempt', (tester) async {
      final topic = Topic(
        id: 'top_practice_test',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        title: 'Cost Accounting Numericals',
      );

      await tester.pumpWidget(_buildTestWidget(
        Scaffold(
          body: PracticeRecordSheet(topic: topic),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Record Practice Attempt'), findsOneWidget);
      expect(find.text('Cost Accounting Numericals'), findsOneWidget);

      // Enter questions and correct count
      await tester.enterText(find.widgetWithText(TextFormField, '20'), '25');
      await tester.tap(find.text('Save Practice Attempt'));
      await tester.pumpAndSettle();

      expect(TopicPracticeController.instance.attemptsForTopic('top_practice_test').length, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
