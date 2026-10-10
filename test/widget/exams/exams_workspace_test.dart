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
import 'package:student_os/features/exams/exam_screen.dart';
import 'package:student_os/features/exams/widgets/exam_creation_sheet.dart';
import 'package:student_os/features/exams/widgets/exam_detail_screen.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/subjects/subject_detail_screen.dart';
import 'package:student_os/features/tasks/presentation/task_detail_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 5 — Exams workspace widget tests.
///
/// Covers the exam list (incl. past exams + readiness), detail workspace
/// (real prep data, subject link, actions, reopen), and the creation sheet
/// (subject picker, past-date warning).
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

  group('ExamScreen', () {
    testWidgets('empty state offers exam creation', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ExamScreen()));
      await tester.pumpAndSettle();

      expect(
        find.text('All clear — no upcoming exams scheduled.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tiles show countdown, syllabus, and readiness', (
      tester,
    ) async {
      final exam = await ExamController.instance.createExam(
        title: 'List midterm',
        subject: 'Math',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
        syllabusItems: [],
      );
      await ExamController.instance.addSyllabusItem(exam.id, 'Algebra');
      await ExamController.instance.addSyllabusItem(exam.id, 'Geometry');

      await tester.pumpWidget(wrapWithApp(const ExamScreen()));
      await tester.pumpAndSettle();

      expect(find.text('List midterm'), findsWidgets);
      expect(find.text('0/2'), findsOneWidget);
      expect(
        find.textContaining(
          ExamController.instance.readinessLabel(
            ExamController.instance.exams.firstWhere((e) => e.id == exam.id),
          ),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('completed exams appear in Past exams and open detail', (
      tester,
    ) async {
      final exam = await ExamController.instance.createExam(
        title: 'Old final',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );
      await ExamController.instance.completeExam(exam.id);

      await tester.pumpWidget(wrapWithApp(const ExamScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Past exams'), findsOneWidget);
      expect(find.text('Old final'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);

      await tapVisible(tester, find.text('Old final').first);
      await tester.pumpAndSettle();
      expect(find.byType(ExamDetailScreen), findsOneWidget);
      popTop(tester, ExamScreen);
      await tester.pumpAndSettle();
    });

    testWidgets('no overflow at 320dp', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await ExamController.instance.createExam(
        title: 'A fairly long exam title for narrow screens',
        subject: 'An equally long subject name here',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );

      await tester.pumpWidget(wrapWithApp(const ExamScreen(), width: 320));
      await tester.pumpAndSettle();

      expect(find.byType(ExamScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ExamDetailScreen workspace', () {
    Future<String> createWorkspace() async {
      // Subject exists so the exam's subject card links to its workspace.
      await SubjectController.instance.createSubject(name: 'DetailSubject');
      final exam = await ExamController.instance.createExam(
        title: 'Detail midterm',
        subject: 'detailsubject',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
      );
      await ExamController.instance.addSyllabusItem(exam.id, 'Topic A');
      await TaskController.instance.createTask(
        title: 'Detail prep task',
        examId: exam.id,
      );
      return exam.id;
    }

    testWidgets('shows real prep data and linked tasks', (tester) async {
      final examId = await createWorkspace();

      await tester.pumpWidget(wrapWithApp(ExamDetailScreen(examId: examId)));
      await tester.pumpAndSettle();

      expect(find.text('Detail midterm'), findsOneWidget);
      expect(find.text('Preparation tasks (0/1)'), findsOneWidget);
      expect(find.text('Detail prep task'), findsOneWidget);
      expect(find.text('Topic A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('subject card opens the matching subject workspace', (
      tester,
    ) async {
      final examId = await createWorkspace();

      await tester.pumpWidget(wrapWithApp(ExamDetailScreen(examId: examId)));
      await tester.pumpAndSettle();

      expect(find.text('Subject workspace'), findsOneWidget);
      await tapVisible(tester, find.text('Subject workspace'));
      await tester.pumpAndSettle();

      expect(find.byType(SubjectDetailScreen), findsOneWidget);
      popTop(tester, ExamDetailScreen);
      await tester.pumpAndSettle();
    });

    testWidgets('prep task row opens task detail', (tester) async {
      final examId = await createWorkspace();

      await tester.pumpWidget(wrapWithApp(ExamDetailScreen(examId: examId)));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Detail prep task'));
      await tester.pumpAndSettle();

      expect(find.byType(TaskDetailScreen), findsOneWidget);
      popTop(tester, ExamDetailScreen);
      await tester.pumpAndSettle();
    });

    testWidgets('view-all scopes the Tasks workspace by exam', (tester) async {
      final examId = await createWorkspace();
      await TaskController.instance.createTask(title: 'Unrelated task');

      await tester.pumpWidget(wrapWithApp(ExamDetailScreen(examId: examId)));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('View all'));
      await tester.pumpAndSettle();

      expect(TaskController.instance.filter.examId, examId);
      expect(TaskController.instance.filteredTasks.length, 1);

      TaskController.instance.clearFilters();
    });

    testWidgets('completed exams can be reopened from detail', (tester) async {
      final exam = await ExamController.instance.createExam(
        title: 'Reopen me',
        examDateTime: DateTime.now().add(const Duration(days: 3)),
      );
      await ExamController.instance.completeExam(exam.id);

      await tester.pumpWidget(wrapWithApp(ExamDetailScreen(examId: exam.id)));
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsWidgets);
      await tester.tap(find.byTooltip('Reopen exam'));
      await tester.pumpAndSettle();

      expect(
        ExamController.instance.upcomingExams.any((e) => e.id == exam.id),
        isTrue,
      );
      expect(find.text('Completed'), findsNothing);
    });

    testWidgets('start focus opens mode selection sheet retaining exam context', (
      tester,
    ) async {
      final examId = await createWorkspace();

      await tester.pumpWidget(wrapWithApp(ExamDetailScreen(examId: examId)));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Start focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Mode selection sheet should be visible
      expect(find.text('What do you want to do?'), findsOneWidget);

      // Tap Focus mode
      await tester.tap(find.text('Focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Session should be active with exam context
      expect(FocusController.instance.hasActiveSession, true);
      expect(FocusController.instance.activeSession?.examId, examId);

      popTop(tester, ExamDetailScreen);
      await tester.pump();
      FocusController.instance.completeSession();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('delete dialog states links are preserved', (tester) async {
      final examId = await createWorkspace();

      await tester.pumpWidget(wrapWithApp(ExamDetailScreen(examId: examId)));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Delete exam'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('only their exam link is removed'),
        findsOneWidget,
      );

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(ExamController.instance.exams.any((e) => e.id == examId), isFalse);
      // Linked task survives, unlinked.
      final survivors = TaskController.instance.tasks
          .where((t) => t.title == 'Detail prep task')
          .toList();
      expect(survivors.length, 1);
      expect(survivors.single.examId, isNull);
    });

    testWidgets('missing exam recovers with a not-found state', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(const ExamDetailScreen(examId: 'missing-id')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exam not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ExamCreationSheet', () {
    testWidgets('subject picker fills the field from real subjects', (
      tester,
    ) async {
      await SubjectController.instance.createSubject(name: 'PickerSub');

      await tester.pumpWidget(
        wrapWithApp(const Scaffold(body: ExamCreationSheet())),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Choose from my subjects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PickerSub'));
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.any((f) => f.controller?.text == 'PickerSub'), isTrue);
      expect(find.textContaining('Linked to subject'), findsOneWidget);
    });

    testWidgets('editing a past exam shows a non-blocking warning', (
      tester,
    ) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final exam = await ExamController.instance.createExam(
        title: 'Past exam',
        examDateTime: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          9,
        ),
      );

      await tester.pumpWidget(
        wrapWithApp(Scaffold(body: ExamCreationSheet(editing: exam))),
      );
      await tester.pumpAndSettle();

      // Warning is honest but does not block saving.
      expect(find.text('This date is in the past.'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
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
