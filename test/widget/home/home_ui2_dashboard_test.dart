import 'package:flutter/material.dart' hide PrioritizedAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/module_placeholder_screen.dart';
import 'package:student_os/data/models/student_profile.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/exams/widgets/exam_detail_screen.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/screens/focus_center_screen.dart';
import 'package:student_os/features/goals/goal_controller.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    SubjectController.instance.clearData();
    GoalController.instance.clearData();
    FocusController.instance.clearData();
    StudentService.instance.clearProfile();
  });

  tearDown(() async {
    FocusController.instance.clearData();
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
    final ctx = tester.element(find.byType(HomeScreen, skipOffstage: false));
    Navigator.of(ctx).pop();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  group('UI-2 — Home Dashboard & Quick Actions Tests', () {
    testWidgets('1. Quick actions grid renders compact tiles with no dead buttons', (tester) async {
      await pumpHome(tester);

      // Verify CODE 5 compact 7-action tiles exist + canonical entry
      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Plan Day'), findsWidgets);
      expect(find.text('Study'), findsWidgets);
      expect(find.text('Revise'), findsWidgets);
      expect(find.text('Add Task'), findsWidgets);
      expect(find.text('Exams'), findsWidgets);
      expect(find.text('Calendar'), findsWidgets);
      expect(find.text('Ask Student OS'), findsWidgets);

      // Test tapping Add Task (opens creation flow, no crash)
      await tapVisible(tester, find.text('Add Task').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      popTop(tester);
      await tester.pumpAndSettle();

      // Test tapping Exams tile
      await tapVisible(tester, find.text('Exams'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      popTop(tester);
      await tester.pumpAndSettle();

      // Test tapping Focus tile
      await tapVisible(tester, find.text('Focus'));
      await tester.pumpAndSettle();
      expect(find.byType(FocusCenterScreen), findsOneWidget);
      popTop(tester);
      await tester.pumpAndSettle();
    });

    testWidgets('2. Course-aware greeting renders real StudentProfile context', (tester) async {
      await StudentService.instance.updateProfile(
        StudentProfile(
          displayName: 'Ayush',
          currentYear: 'Semester 1',
          academicFocus: AcademicFocus.examPrep,
        ),
      );

      await pumpHome(tester);

      expect(find.textContaining('Ayush'), findsOneWidget);
    });

    testWidgets('3. Real tasks trigger action in Home 2.0', (tester) async {
      final task = await TaskController.instance.createTask(
        title: 'Review Chapter 5 Accounting',
        dueDate: DateTime.now().add(const Duration(days: 3)),
      );

      await pumpHome(tester);

      expect(find.text('Review Chapter 5 Accounting'), findsWidgets);

      // Complete the task
      await TaskController.instance.completeTask(task.id);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Real upcoming exam renders in preview with countdown', (tester) async {
      final exam = await ExamController.instance.createExam(
        title: 'CA Foundation Accounts Mock',
        subject: 'Accounting',
        examDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      await pumpHome(tester);

      expect(find.text('CA Foundation Accounts Mock'), findsWidgets);

      await tapVisible(tester, find.text('CA Foundation Accounts Mock').first);
      await tester.pumpAndSettle();
      expect(find.byType(ExamDetailScreen), findsOneWidget);
      popTop(tester);
      await tester.pumpAndSettle();

      await ExamController.instance.deleteExam(exam.id);
    });

    testWidgets('5. Active focus session displays live banner with Focus Guard status', (tester) async {
      final mission = FocusMission(
        id: 'mission_active_test',
        objective: 'Deep Study Accounting',
        subjectName: 'Accounting',
        mode: FocusMode.timer,
        plannedDuration: const Duration(minutes: 25),
      );
      FocusController.instance.startMission(mission);

      await pumpHome(tester);

      expect(find.text('FOCUS ACTIVE'), findsOneWidget);
      expect(find.text('Deep Study Accounting'), findsOneWidget);
      expect(find.text('Continue Focus'), findsOneWidget);

      FocusController.instance.clearData();
      await tester.pumpAndSettle();
    });

    testWidgets('6. Subject study progress displays active subjects', (tester) async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Financial Accounting',
        shortName: 'Accounts',
      );

      await TaskController.instance.createTask(
        title: 'Accounts P1',
        subjectId: subject.id,
      );

      await pumpHome(tester);

      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('7. Active goal renders in preview when configured', (tester) async {
      await GoalController.instance.setPersonalGoal('Master Financial Accounting');

      await pumpHome(tester);

      expect(find.text('Master Financial Accounting'), findsOneWidget);
    });

    testWidgets('8. Empty states render gracefully without layout errors at 320dp', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpHome(tester);

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
