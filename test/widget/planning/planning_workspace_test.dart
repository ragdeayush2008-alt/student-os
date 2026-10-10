import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/planning/planning_screen.dart';
import 'package:student_os/features/tasks/presentation/task_creation_sheet.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TaskController.instance.clearData();
    PlanController.instance.clearData();
    PlanningBlockController.instance.clearData();
    ExamController.instance.clearData();
    await TaskController.instance.load();
    await PlanningBlockController.instance.load();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
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

  group('PlanningScreen Workspace', () {
    testWidgets('renders Plan header, top switcher, and empty plan hero', (tester) async {
      await tester.pumpWidget(wrapWithApp(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('YOUR DAY IS OPEN'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('displays tasks and scheduled planning blocks in agenda', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await TaskController.instance.createTask(
        title: 'Complete Homework',
        dueDate: today,
        priority: TaskPriority.high,
      );

      final task2 = await TaskController.instance.createTask(
        title: 'Study Physics',
      );

      await PlanningBlockController.instance.scheduleBlock(
        task2.id,
        DateTime(today.year, today.month, today.day, 14, 0),
        DateTime(today.year, today.month, today.day, 15, 30),
      );

      await tester.pumpWidget(wrapWithApp(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Complete Homework'), findsWidgets);
      expect(find.text('Study Physics'), findsWidgets);
    });

    testWidgets('displays overdue tasks section only when today is selected', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 2));
      await TaskController.instance.createTask(
        title: 'Overdue Assignment',
        dueDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
      );

      await tester.pumpWidget(wrapWithApp(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Overdue Assignment'), findsWidgets);
      expect(find.text('Overdue'), findsWidgets);

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      PlanController.instance.selectDay(tomorrow);
      await tester.pumpAndSettle();

      expect(find.text('Overdue Assignment'), findsNothing);
    });

    testWidgets('tapping Add button opens TaskCreationSheet', (tester) async {
      await tester.pumpWidget(wrapWithApp(const PlanningScreen()));
      await tester.pumpAndSettle();

      // Scroll into view: canonical header + assistant entry sit above.
      await tester.ensureVisible(find.text('Add').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add').first);
      await tester.pumpAndSettle();

      expect(find.byType(TaskCreationSheet), findsOneWidget);
    });
  });
}
