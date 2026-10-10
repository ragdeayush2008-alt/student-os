import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/app/app_shell.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/planning/planning_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    await SubjectController.instance.load();
    await TaskController.instance.load();
    await PlanningBlockController.instance.load();
    await FocusController.instance.load();
  });

  tearDown(() {
    FocusController.instance.cancelSession();
    FocusController.instance.clearData();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  Widget wrapWithApp(Widget child, {AppShellController? controller, double width = 600}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: AppScope(
          controller: controller ?? AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Plan & Study 2.0 — Integration Tests', () {
    testWidgets('1. Bottom-nav switches to Plan & Study tab as 2nd destination', (tester) async {
      final shellCtrl = AppShellController();
      await tester.pumpWidget(wrapWithApp(const AppShell(), controller: shellCtrl));
      await tester.pumpAndSettle();

      expect(shellCtrl.selectedIndex, 0);

      // Tap Plan & Study tab
      final navBar = find.byType(StudentOSBottomNavigation);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Plan & Study')));
      await tester.pumpAndSettle();

      expect(shellCtrl.selectedIndex, 1);
      expect(find.byType(PlanningScreen), findsOneWidget);
    });

    testWidgets('2. Pressing START on planned block launches Focus session with context', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('focus_plan_user');
      final s = await SubjectController.instance.createSubject(name: 'Economics');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await PlanningBlockController.instance.scheduleBlock(
        null,
        DateTime(today.year, today.month, today.day, 10, 0),
        DateTime(today.year, today.month, today.day, 10, 45),
        subjectId: s.id,
        customTitle: 'Macroeconomics',
      );

      await tester.pumpWidget(wrapWithApp(const PlanningScreen(), width: 1200));
      await tester.pumpAndSettle();

      // Tap START button
      final startBtn = find.byKey(const Key('start_planning_block_button'));
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // 2.0: START opens the mode-selection prompt carrying the block's
      // assigned duration (45 min), replacing the direct Timer launch.
      expect(find.text('What do you want to do?'), findsOneWidget);
      expect(find.text('45 min scheduled'), findsOneWidget);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      expect(find.byType(FocusSessionScreen), findsOneWidget);
      expect(FocusController.instance.hasActiveSession, isTrue);
      expect(FocusController.instance.activeSession?.subjectId, s.id);
      FocusController.instance.cancelSession();
    });

    testWidgets('3. Active focus session is protected and displays CONTINUE button', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('active_focus_user');
      FocusController.instance.startQuickFocus(subjectName: 'Live Session');

      await tester.pumpWidget(wrapWithApp(const PlanningScreen(), width: 1200));
      await tester.pumpAndSettle();

      expect(find.text('FOCUS SESSION IN PROGRESS'), findsOneWidget);
      expect(find.text('CONTINUE FOCUS'), findsOneWidget);

      await tester.tap(find.text('CONTINUE FOCUS'));
      await tester.pumpAndSettle();

      expect(find.byType(FocusSessionScreen), findsOneWidget);
      FocusController.instance.cancelSession();
    });

    testWidgets('4. User isolation A -> B -> A for planning blocks and study plans', (tester) async {
      // User A creates plan
      AuthIsolation.instance.setAuthenticatedUser('user_A_plan');
      final sA = await SubjectController.instance.createSubject(name: 'User A Subject');
      final targetDay = DateTime(2026, 11, 20);
      await PlanningBlockController.instance.scheduleBlock(
        null,
        DateTime(targetDay.year, targetDay.month, targetDay.day, 9, 0),
        DateTime(targetDay.year, targetDay.month, targetDay.day, 10, 0),
        subjectId: sA.id,
        customTitle: 'User A Block',
      );
      expect(PlanningBlockController.instance.blocksForDay(targetDay).length, 1);

      // Switch to User B
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();
      expect(PlanningBlockController.instance.blocksForDay(targetDay).isEmpty, isTrue);

      AuthIsolation.instance.setAuthenticatedUser('user_B_plan');
      await PlanningBlockController.instance.load();
      expect(PlanningBlockController.instance.blocksForDay(targetDay).isEmpty, isTrue);

      // Switch back to User A
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.setAuthenticatedUser('user_A_plan');
      await PlanningBlockController.instance.load();
      await SubjectController.instance.load();

      expect(PlanningBlockController.instance.blocksForDay(targetDay).length, 1);
      expect(PlanningBlockController.instance.blocksForDay(targetDay).first.customTitle, 'User A Block');
    });
  });
}
