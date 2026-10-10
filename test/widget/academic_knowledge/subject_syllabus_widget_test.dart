import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/knowledge/presentation/widgets/subject_syllabus_section.dart';
import 'package:student_os/features/knowledge/presentation/topic_detail_sheet.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

Widget _buildTestableWidget(Widget child, {Size size = const Size(390, 844)}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AcademicKnowledgeController.instance.clearData();
    SubjectController.instance.clearData();
  });

  tearDown(() async {
    AcademicKnowledgeController.instance.clearData();
    SubjectController.instance.clearData();
  });

  group('Subject Syllabus Widget Tests', () {
    testWidgets('renders empty syllabus state with add chapter prompt', (tester) async {
      final subject = Subject(id: 'sub_acc', name: 'Accountancy');

      await tester.pumpWidget(_buildTestableWidget(
        SubjectSyllabusSection(subject: subject),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Syllabus & Chapters'), findsOneWidget);
      expect(find.text('No chapters added yet'), findsOneWidget);
      expect(find.text('Add First Chapter'), findsOneWidget);
    });

    testWidgets('renders chapters and topics inside ChapterCard', (tester) async {
      final subject = Subject(id: 'sub_acc', name: 'Accountancy');
      final kc = AcademicKnowledgeController.instance;

      final ch = await kc.createChapter(
        subjectId: subject.id,
        title: 'Partnership Accounts',
      );
      await kc.createTopic(
        chapterId: ch.id,
        subjectId: subject.id,
        title: 'Admission of Partner',
        estimatedMinutes: 35,
      );

      await tester.pumpWidget(_buildTestableWidget(
        SubjectSyllabusSection(subject: subject),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Partnership Accounts'), findsOneWidget);
      expect(find.text('Academic Progress'), findsOneWidget);

      // Expand chapter
      await tester.tap(find.text('Partnership Accounts'));
      await tester.pumpAndSettle();

      expect(find.text('Admission of Partner'), findsOneWidget);
      expect(find.text('35m'), findsOneWidget);
    });

    testWidgets('TopicDetailSheet renders all metrics and actions', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Law',
      );
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(
        subjectId: subject.id,
        title: 'Contract Act',
      );
      final top = await kc.createTopic(
        chapterId: ch.id,
        subjectId: subject.id,
        title: 'Offer & Acceptance',
        estimatedMinutes: 30,
        importance: TopicImportance.high,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: TopicDetailSheet(topicId: top.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offer & Acceptance'), findsOneWidget);
      expect(find.text('High Importance'), findsOneWidget);
      expect(find.text('Study (30m)'), findsOneWidget);
      expect(find.text('Revise (15m)'), findsOneWidget);
      expect(find.text('Schedule into Plan'), findsOneWidget);
    });

    testWidgets('renders cleanly on narrow screen (320dp) without overflow', (tester) async {
      final subject = Subject(id: 'sub_math', name: 'Mathematics');
      final kc = AcademicKnowledgeController.instance;
      final ch = await kc.createChapter(
        subjectId: subject.id,
        title: 'Differential Calculus & Integration of Complex Functions',
      );
      await kc.createTopic(
        chapterId: ch.id,
        subjectId: subject.id,
        title: 'Integration by Partial Fractions and Substitution Methods',
        estimatedMinutes: 45,
      );

      await tester.pumpWidget(_buildTestableWidget(
        SubjectSyllabusSection(subject: subject),
        size: const Size(320, 640),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
