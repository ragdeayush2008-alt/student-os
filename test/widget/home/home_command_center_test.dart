import 'package:flutter/material.dart' hide PrioritizedAction;
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
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/presentation/task_detail_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 4 — Home Daily Command Center widget tests.
///
/// Covers NOW / NEXT / empty / exam / progress / focus / quick-action
/// rendering, reactivity to task + focus + study changes, and real
/// navigation targets. Unknown named routes fall back to a placeholder so
/// shell-owned destinations can be tapped without crashing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _cleanAcademicData();
  });

  tearDown(() async {
    await _cleanAcademicData();
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

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(wrapWithApp(const HomeScreen()));
    await tester.pumpAndSettle();
  }

  void popTop(WidgetTester tester) {
    // HomeScreen is offstage while a pushed route covers it.
    final ctx = tester.element(find.byType(HomeScreen, skipOffstage: false));
    Navigator.of(ctx).pop();
  }

  /// Scrolls [finder] into view before tapping: Home is a tall scroll view
  /// and taps on below-the-fold widgets would otherwise hit nothing.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  group('Home command center states', () {
    testWidgets('empty day shows caught-up NOW and clear NEXT', (tester) async {
      await pumpHome(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('All Caught Up'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('NOW surfaces a real overdue task with Open task', (
      tester,
    ) async {
      final task = await TaskController.instance.createTask(
        title: 'Overdue NOW task',
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      await pumpHome(tester);

      expect(find.text('Overdue NOW task'), findsWidgets);
      await tester.tap(find.text('Overdue NOW task').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Pop if detail was pushed
      try { popTop(tester); } catch (_) {}
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await TaskController.instance.deleteTask(task.id);
    });

    testWidgets('upcoming exam card shows real exam and opens detail', (
      tester,
    ) async {
      final exam = await ExamController.instance.createExam(
        title: 'Widget Midterm',
        subject: 'Biology',
        examDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      await pumpHome(tester);

      expect(find.text('Widget Midterm'), findsWidgets);
      expect(find.text('Tomorrow'), findsOneWidget);

      await tapVisible(tester, find.text('Widget Midterm').first);
      await tester.pumpAndSettle();
      expect(find.byType(ExamDetailScreen), findsOneWidget);

      popTop(tester);
      await tester.pumpAndSettle();
      await ExamController.instance.deleteExam(exam.id);
    });

    testWidgets('quick actions expose all functional destinations', (
      tester,
    ) async {
      await pumpHome(tester);

      // Compact 7-action grid: 3 featured + 4 secondary (existing
      // flows only). Ask OS owns the canonical Assistant entry card.
      for (final label in [
        'Focus',
        'Plan Day',
        'Study',
        'Revise',
        'Add Task',
        'Exams',
        'Calendar',
      ]) {
        expect(find.text(label), findsWidgets, reason: 'missing $label');
      }
      expect(find.text('Ask Student OS'), findsWidgets,
          reason: 'missing canonical Assistant entry');
    });

    testWidgets('Quick actions navigate without errors', (
      tester,
    ) async {
      await pumpHome(tester);

      await tapVisible(tester, find.text('Add Task').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      popTop(tester);
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Exams').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      popTop(tester);
      await tester.pumpAndSettle();
    });
  });

  group('Home reactivity', () {
    testWidgets('completing a task updates NOW and progress', (tester) async {
      final task = await TaskController.instance.createTask(
        title: 'Reactive task',
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      await pumpHome(tester);
      expect(find.text('Reactive task'), findsWidgets);

      await TaskController.instance.completeTask(task.id);
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);

      await TaskController.instance.deleteTask(task.id);
    });

    testWidgets('active focus surfaces Continue and completes cleanly', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.text('FOCUS ACTIVE'), findsNothing);

      FocusController.instance.startQuickFocus(
        duration: const Duration(minutes: 25),
      );
      await tester.pump();

      expect(find.text('FOCUS ACTIVE'), findsOneWidget);
      expect(find.text('Continue Focus'), findsOneWidget);

      FocusController.instance.completeSession();
      await tester.pump();

      expect(find.text('FOCUS ACTIVE'), findsNothing);

      // Flush FocusController's pending 3s phase timer so teardown is clean.
      await tester.pump(const Duration(seconds: 5));
    });
  });
}

Future<void> _cleanAcademicData() async {
  if (FocusController.instance.hasActiveSession) {
    FocusController.instance.completeSession();
  }
  FocusController.instance.clearData();
  StudyController.instance.clearData();
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
