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
import 'package:student_os/features/exams/widgets/exam_detail_screen.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/subjects/subject_detail_screen.dart';
import 'package:student_os/features/tasks/presentation/task_detail_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 5 — Subject detail workspace widget tests.
///
/// Covers related tasks/exams, context-preserving navigation, workspace
/// actions (Task/Exam/Focus/Study), safe delete, and the empty hint.
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

  void popTop(WidgetTester tester, Type offstageType) {
    final ctx = tester.element(find.byType(offstageType, skipOffstage: false));
    Navigator.of(ctx).pop();
  }

  Future<String> createSubjectWorkspace() async {
    final subject = await SubjectController.instance.createSubject(
      name: 'Biology',
    );
    await TaskController.instance.createTask(
      title: 'Biology task',
      subjectId: subject.id,
      dueDate: DateTime.now(),
    );
    await ExamController.instance.createExam(
      title: 'Biology midterm',
      subject: 'biology',
      examDateTime: DateTime.now().add(const Duration(days: 6)),
    );
    return subject.id;
  }

  group('SubjectDetailScreen workspace', () {
    testWidgets('shows related tasks and exams', (tester) async {
      final subjectId = await createSubjectWorkspace();

      await tester.pumpWidget(
        wrapWithApp(SubjectDetailScreen(subjectId: subjectId)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming work'), findsOneWidget);
      expect(find.text('Biology task'), findsOneWidget);
      expect(find.text('Biology midterm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exam tile opens exam detail with preserved id', (
      tester,
    ) async {
      final subjectId = await createSubjectWorkspace();

      await tester.pumpWidget(
        wrapWithApp(SubjectDetailScreen(subjectId: subjectId)),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Biology midterm'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamDetailScreen), findsOneWidget);
      popTop(tester, SubjectDetailScreen);
      await tester.pumpAndSettle();
    });

    testWidgets('task tile opens task detail with preserved id', (
      tester,
    ) async {
      final subjectId = await createSubjectWorkspace();

      await tester.pumpWidget(
        wrapWithApp(SubjectDetailScreen(subjectId: subjectId)),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Biology task'));
      await tester.pumpAndSettle();

      expect(find.byType(TaskDetailScreen), findsOneWidget);
      popTop(tester, SubjectDetailScreen);
      await tester.pumpAndSettle();
    });

    testWidgets('view-all scopes the Tasks workspace by subject', (
      tester,
    ) async {
      final subjectId = await createSubjectWorkspace();

      await tester.pumpWidget(
        wrapWithApp(SubjectDetailScreen(subjectId: subjectId)),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('View all'));
      await tester.pumpAndSettle();

      // Tasks route is shell-owned in production; the test fallback proves
      // the action navigates, while the controller carries the scope.
      expect(TaskController.instance.filter.subjectId, subjectId);
      expect(TaskController.instance.filteredTasks.length, 1);

      TaskController.instance.clearFilters();
    });

    testWidgets('workspace actions create with subject context', (
      tester,
    ) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'History',
      );

      await tester.pumpWidget(
        wrapWithApp(SubjectDetailScreen(subjectId: subject.id)),
      );
      await tester.pumpAndSettle();

      // Add Task opens the creation sheet pre-scoped to the subject.
      await tapVisible(tester, find.text('Task'));
      await tester.pumpAndSettle();
      expect(find.text('New task'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      // Add Exam opens the exam sheet prefilled with the subject name.
      await tapVisible(tester, find.text('Exam'));
      await tester.pumpAndSettle();
      expect(find.text('New exam'), findsOneWidget);
      final subjectFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((f) => f.controller?.text == 'History');
      expect(subjectFields.isNotEmpty, isTrue);
    });

    testWidgets('focus action opens mode selection sheet and starts a real session with subject context', (
      tester,
    ) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Geography',
      );

      await tester.pumpWidget(
        wrapWithApp(SubjectDetailScreen(subjectId: subject.id)),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Mode selection sheet should be visible
      expect(find.text('What do you want to do?'), findsOneWidget);

      // Tap Focus mode in the sheet (last match: the sheet overlays the
      // detail screen, which also has a 'Focus' action button).
      await tester.tap(find.text('Focus').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Session should be active with subject context
      expect(FocusController.instance.activeSession?.subjectId, subject.id);

      popTop(tester, SubjectDetailScreen);
      await tester.pump();
      FocusController.instance.completeSession();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('empty workspace shows a helpful hint', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Empty subject',
      );

      await tester.pumpWidget(
        wrapWithApp(SubjectDetailScreen(subjectId: subject.id)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No work linked yet'), findsOneWidget);
    });

    testWidgets('delete preserves tasks and unlinks them', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Delete me',
      );
      final task = await TaskController.instance.createTask(
        title: 'Surviving task',
        subjectId: subject.id,
      );

      await tester.pumpWidget(
        wrapWithApp(SubjectDetailScreen(subjectId: subject.id)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.textContaining('will be kept'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(SubjectController.instance.subjectById(subject.id), isNull);
      final remaining = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .toList();
      expect(remaining.length, 1);
      expect(remaining.single.subjectId, isNull);
    });

    testWidgets('missing subject recovers with a not-found state', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithApp(const SubjectDetailScreen(subjectId: 'missing-id')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subject not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _clean() async {
  if (FocusController.instance.hasActiveSession) {
    FocusController.instance.completeSession();
  }
  FocusController.instance.clearData();
  TaskController.instance.clearFilters();
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
