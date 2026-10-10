import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/presentation/assistant_command_center_screen.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

Widget _buildTestableWidget(Widget child, {Size size = const Size(390, 844)}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() async {
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Canonical Assistant surface — Phase 4 structured cards', () {
    testWidgets('renders structured steps for a time-based plan',
        (tester) async {
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final subject = await sc.createSubject(name: 'Accountancy');
      final chapter =
          await kc.createChapter(subjectId: subject.id, title: 'Partnership');
      await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 40,
      );

      await tester.pumpWidget(_buildTestableWidget(
        const AssistantCommandCenterScreen(initialQuery: 'I have 2 hours'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Plan for 120 Minutes'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('Admission of a Partner'), findsWidgets);
    });

    testWidgets('renders one numbered row per today block', (tester) async {
      final pbc = PlanningBlockController.instance;
      await pbc.scheduleBlock(
        null,
        DateTime.now().add(const Duration(hours: 1)),
        DateTime.now().add(const Duration(hours: 2)),
        customTitle: 'Alpha Review',
      );
      await pbc.scheduleBlock(
        null,
        DateTime.now().add(const Duration(hours: 3)),
        DateTime.now().add(const Duration(hours: 4)),
        customTitle: 'Beta Practice',
      );

      await tester.pumpWidget(_buildTestableWidget(
        const AssistantCommandCenterScreen(initialQuery: "Show today's plan."),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining("Today's Planned Schedule"), findsOneWidget);
      expect(find.text('Alpha Review'), findsWidgets);
      expect(find.text('Beta Practice'), findsWidgets);
    });

    testWidgets('shows a context strip explaining what was considered',
        (tester) async {
      await tester.pumpWidget(_buildTestableWidget(
        const AssistantCommandCenterScreen(initialQuery: 'What should I do?'),
      ));
      await tester.pumpAndSettle();

      // Context strip icon is present on a populated result.
      expect(find.byIcon(Icons.insights_rounded), findsWidgets);
    });

    testWidgets('suggests prompts appropriate to the result kind',
        (tester) async {
      await SubjectController.instance.createSubject(name: 'Accountancy');

      await tester.pumpWidget(_buildTestableWidget(
        const AssistantCommandCenterScreen(initialQuery: 'What should I study?'),
      ));
      await tester.pumpAndSettle();

      // Recommendation-style cards surface topic/plan prompts.
      expect(find.text('Plan this topic'), findsOneWidget);
    });

    testWidgets('renders cleanly on a narrow 320dp screen with steps',
        (tester) async {
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final subject = await sc.createSubject(name: 'Accountancy');
      final chapter =
          await kc.createChapter(subjectId: subject.id, title: 'Partnership');
      await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 40,
      );

      await tester.pumpWidget(_buildTestableWidget(
        const AssistantCommandCenterScreen(initialQuery: 'I have 2 hours'),
        size: const Size(320, 640),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
