import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/module_placeholder_screen.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/subjects/subject_detail_screen.dart';
import 'package:student_os/features/subjects/subjects_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 5 — Subjects list workspace widget tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _clean();
  });

  tearDown(() async {
    await _clean();
  });

  Widget wrapWithApp(Widget child, {double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      onUnknownRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const ModulePlaceholderScreen(
          title: 'Fallback',
          icon: Icons.circle_outlined,
          description: 'Test fallback route.',
        ),
      ),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  group('SubjectsScreen', () {
    testWidgets('empty state offers Add subject', (tester) async {
      await tester.pumpWidget(wrapWithApp(const SubjectsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No subjects yet'), findsOneWidget);
      expect(find.text('Add subject'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lists subjects with derived workload', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Physics',
      );
      await TaskController.instance.createTask(
        title: 'Physics task',
        subjectId: subject.id,
      );
      await ExamController.instance.createExam(
        title: 'Physics midterm',
        subject: 'Physics',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
      );

      await tester.pumpWidget(wrapWithApp(const SubjectsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Physics'), findsOneWidget);
      expect(find.textContaining('1 task'), findsOneWidget);
      expect(find.textContaining('1 exam'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a subject opens its detail with preserved id', (
      tester,
    ) async {
      await SubjectController.instance.createSubject(name: 'Chemistry');

      await tester.pumpWidget(wrapWithApp(const SubjectsScreen()));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Chemistry'));
      await tester.pumpAndSettle();

      expect(find.byType(SubjectDetailScreen), findsOneWidget);
      expect(find.text('Chemistry'), findsWidgets);
    });

    testWidgets('add button opens the creation sheet', (tester) async {
      await tester.pumpWidget(wrapWithApp(const SubjectsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add subject'));
      await tester.pumpAndSettle();

      expect(find.text('New subject'), findsOneWidget);
    });

    testWidgets('archived subjects appear in their own section', (
      tester,
    ) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Old subject',
      );
      await SubjectController.instance.archiveSubject(subject.id);

      await tester.pumpWidget(wrapWithApp(const SubjectsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Archived'), findsWidgets);
      expect(find.text('Old subject'), findsOneWidget);
    });

    testWidgets('no overflow at 320dp', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await SubjectController.instance.createSubject(
        name: 'A very long subject name for narrow screens',
      );

      await tester.pumpWidget(wrapWithApp(const SubjectsScreen(), width: 320));
      await tester.pumpAndSettle();

      expect(find.byType(SubjectsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _clean() async {
  for (final task in List.of(TaskController.instance.tasks)) {
    await TaskController.instance.deleteTask(task.id);
  }
  for (final exam in List.of(ExamController.instance.exams)) {
    await ExamController.instance.deleteExam(exam.id);
  }
  for (final subject in List.of(SubjectController.instance.subjects)) {
    await SubjectController.instance.deleteSubject(subject.id);
  }
}
