import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/module_placeholder_screen.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/exams/widgets/exam_detail_screen.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/presentation/task_creation_sheet.dart';
import 'package:student_os/features/tasks/presentation/task_detail_screen.dart';
import 'package:student_os/features/tasks/presentation/tasks_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 5 — Tasks workspace widget tests.
///
/// Covers view organization (incl. Overdue), search-everywhere filtering,
/// scoped deep-links, card context, and detail actions.
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

  Future<void> pumpTasks(WidgetTester tester) async {
    await tester.pumpWidget(wrapWithApp(const TasksScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  group('TasksScreen organization', () {
    testWidgets('shows Today/Overdue/Upcoming/Inbox/All/Done views', (
      tester,
    ) async {
      await pumpTasks(tester);

      for (final label in [
        'Today',
        'Overdue',
        'Upcoming',
        'Inbox',
        'All',
        'Done',
      ]) {
        expect(find.text(label), findsWidgets, reason: 'missing $label');
      }
    });

    testWidgets('overdue view isolates overdue tasks', (tester) async {
      await TaskController.instance.createTask(
        title: 'Overdue one',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await TaskController.instance.createTask(
        title: 'Future one',
        dueDate: DateTime.now().add(const Duration(days: 3)),
      );

      await pumpTasks(tester);
      await tapVisible(tester, find.text('Overdue').first);
      await tester.pumpAndSettle();

      // 'Overdue one' appears in recommendations AND the overdue list, while
      // 'Future one' appears only in recommendations — proving the list
      // itself is isolated to overdue tasks.
      expect(find.text('Overdue one'), findsNWidgets(2));
      expect(find.text('Future one'), findsOneWidget);
    });

    testWidgets('overdue view is empty when nothing is overdue', (
      tester,
    ) async {
      await TaskController.instance.createTask(
        title: 'Future only',
        dueDate: DateTime.now().add(const Duration(days: 3)),
      );

      await pumpTasks(tester);
      await tapVisible(tester, find.text('Overdue').first);
      await tester.pumpAndSettle();

      expect(find.text('Nothing overdue'), findsOneWidget);
    });

    testWidgets('search filters the current view, not just All', (
      tester,
    ) async {
      await TaskController.instance.createTask(
        title: 'Algebra homework',
        dueDate: DateTime.now(),
      );
      await TaskController.instance.createTask(
        title: 'Biology reading',
        dueDate: DateTime.now(),
      );

      await pumpTasks(tester);

      await tester.tap(find.byIcon(Icons.search_rounded).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'algebra');
      await tester.pumpAndSettle();

      expect(find.text('Algebra homework'), findsWidgets);
      expect(find.text('Biology reading'), findsNothing);
    });

    testWidgets('scoped filter lands on All with a scope chip', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'ScopedSub',
      );
      await TaskController.instance.createTask(
        title: 'Scoped task',
        subjectId: subject.id,
      );
      await TaskController.instance.createTask(title: 'Other task');
      TaskController.instance.setFilter(TaskFilter(subjectId: subject.id));

      await pumpTasks(tester);

      expect(find.textContaining('Subject: ScopedSub'), findsOneWidget);
      expect(find.text('Scoped task'), findsWidgets);
      expect(find.text('Other task'), findsNothing);
    });

    testWidgets('task cards show subject and exam context', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'CtxSub',
      );
      final exam = await ExamController.instance.createExam(title: 'Ctx exam');
      await TaskController.instance.createTask(
        title: 'Context task',
        subjectId: subject.id,
        examId: exam.id,
      );

      await pumpTasks(tester);
      await tapVisible(tester, find.text('All').first);
      await tester.pumpAndSettle();

      expect(find.text('CtxSub'), findsWidgets);
      expect(find.text('Ctx exam'), findsWidgets);
    });

    testWidgets('no overflow at 320dp', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await TaskController.instance.createTask(
        title: 'A fairly long task title for narrow screens',
        description: 'With a description attached',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        priority: TaskPriority.critical,
      );

      await tester.pumpWidget(wrapWithApp(const TasksScreen(), width: 320));
      await tester.pumpAndSettle();

      expect(find.byType(TasksScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TaskDetailScreen workspace', () {
    Future<String> createLinkedTask() async {
      final subject = await SubjectController.instance.createSubject(
        name: 'DetailSub',
      );
      final exam = await ExamController.instance.createExam(
        title: 'Detail exam',
        examDateTime: DateTime.now().add(const Duration(days: 4)),
      );
      final task = await TaskController.instance.createTask(
        title: 'Detail task',
        description: 'Detail description',
        subjectId: subject.id,
        examId: exam.id,
        subtasks: [StudentSubtask(id: 'st1', title: 'First step')],
      );
      return task.id;
    }

    testWidgets('shows metadata, links, and subtasks', (tester) async {
      final taskId = await createLinkedTask();

      await tester.pumpWidget(wrapWithApp(TaskDetailScreen(taskId: taskId)));
      await tester.pumpAndSettle();

      expect(find.text('Detail task'), findsOneWidget);
      expect(find.text('Detail description'), findsOneWidget);
      expect(find.text('DetailSub'), findsOneWidget);
      expect(find.text('Detail exam'), findsOneWidget);
      expect(find.text('First step'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exam row opens exam detail', (tester) async {
      final taskId = await createLinkedTask();

      await tester.pumpWidget(wrapWithApp(TaskDetailScreen(taskId: taskId)));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Detail exam'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamDetailScreen), findsOneWidget);
    });

    testWidgets('subtasks toggle and add from detail', (tester) async {
      final taskId = await createLinkedTask();

      await tester.pumpWidget(wrapWithApp(TaskDetailScreen(taskId: taskId)));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('First step'));
      await tester.pumpAndSettle();
      var task = TaskController.instance.tasks.firstWhere(
        (t) => t.id == taskId,
      );
      expect(task.subtasksCompleted, 1);

      await tester.enterText(find.byType(TextField).first, 'Second step');
      await tester.tap(find.byIcon(Icons.add_circle_rounded));
      await tester.pumpAndSettle();
      task = TaskController.instance.tasks.firstWhere((t) => t.id == taskId);
      expect(task.subtaskCount, 2);
      expect(find.text('Second step'), findsOneWidget);
    });

    testWidgets('start focus opens a session retaining task context', (
      tester,
    ) async {
      final taskId = await createLinkedTask();
      final task = TaskController.instance.tasks.firstWhere(
        (t) => t.id == taskId,
      );

      await tester.pumpWidget(wrapWithApp(TaskDetailScreen(taskId: taskId)));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Start focus session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      // Focus 3.0 P2: Task entry shows FOCUS / TIMER / STOPWATCH selection.
      expect(find.text('What do you want to do?'), findsOneWidget);
      // Choose Focus in the sheet (last match overlays the detail screen).
      await tester.tap(find.text('Focus').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FocusSessionScreen), findsOneWidget);
      expect(FocusController.instance.activeSession?.taskId, task.id);
      expect(FocusController.instance.activeSession?.subjectId, task.subjectId);
      expect(FocusController.instance.activeSession?.examId, task.examId);

      final ctx = tester.element(
        find.byType(TaskDetailScreen, skipOffstage: false),
      );
      Navigator.of(ctx).pop();
      await tester.pump();
      FocusController.instance.completeSession();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('completed tasks can be deleted from detail', (tester) async {
      final task = await TaskController.instance.createTask(title: 'Done task');
      await TaskController.instance.completeTask(task.id);

      await tester.pumpWidget(wrapWithApp(TaskDetailScreen(taskId: task.id)));
      await tester.pumpAndSettle();

      expect(find.text('Delete task'), findsOneWidget);
      await tapVisible(tester, find.text('Delete task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(
        TaskController.instance.tasks.any((t) => t.id == task.id),
        isFalse,
      );
    });

    testWidgets('missing task recovers with a not-found state', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(const TaskDetailScreen(taskId: 'missing-id')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TaskCreationSheet', () {
    testWidgets('reminder switch reveals a time picker affordance', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithApp(const Scaffold(body: TaskCreationSheet())),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('More options'));
      await tester.pumpAndSettle();

      // Enable the reminder: a first-set affordance must appear even though
      // no time was ever picked.
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);
      await tapVisible(tester, switches.first);
      await tester.pumpAndSettle();
      expect(find.text('Pick reminder time'), findsOneWidget);

      // Tapping it opens the date picker.
      await tester.tap(find.text('Pick reminder time'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      final dialogCtx = tester.element(find.byType(CalendarDatePicker));
      Navigator.of(dialogCtx).pop();
      await tester.pumpAndSettle();

      // Saving without picking a time still stores a valid default.
      await tester.enterText(
        find.byType(TextField).first,
        'Reminder default task',
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Create task'));
      await tester.pumpAndSettle();

      final saved = TaskController.instance.tasks
          .where((t) => t.title == 'Reminder default task')
          .toList();
      expect(saved.length, 1);
      expect(saved.single.reminderEnabled, isTrue);
      expect(saved.single.reminderDateTime, isNotNull);
    });

    testWidgets('stale subject reference is cleared on save', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Vanishing',
      );
      final task = await TaskController.instance.createTask(
        title: 'Stale ref task',
        subjectId: subject.id,
      );

      await tester.pumpWidget(
        wrapWithApp(Scaffold(body: TaskCreationSheet(editing: task))),
      );
      await tester.pumpAndSettle();

      // Delete the subject while the edit sheet is open.
      await SubjectController.instance.deleteSubject(subject.id);
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Save changes'));
      await tester.pumpAndSettle();

      final updated = TaskController.instance.tasks.firstWhere(
        (t) => t.id == task.id,
      );
      expect(updated.subjectId, isNull);
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
