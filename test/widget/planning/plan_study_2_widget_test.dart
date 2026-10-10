import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/planning_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('plan_study_widget_user');
    ControllerIsolation.instance.clearAllControllers();
    await SubjectController.instance.load();
    await TaskController.instance.load();
    await PlanningBlockController.instance.load();
    await FocusController.instance.load();
  });

  Widget wrapWithApp(Widget child, {double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Plan & Study 2.0 — Widget Tests', () {
    testWidgets('1. Renders top switcher with PLAN selected by default', (tester) async {
      await tester.pumpWidget(wrapWithApp(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('YOUR DAY IS OPEN'), findsOneWidget);
    });

    testWidgets('2. Switches smoothly between PLAN and STUDY tabs', (tester) async {
      await tester.pumpWidget(wrapWithApp(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('YOUR DAY IS OPEN'), findsOneWidget);
      expect(find.text('What Should I Study?'), findsNothing);

      // Tap STUDY tab
      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();

      expect(find.text('What Should I Study?'), findsOneWidget);
      expect(find.text('My Subjects'), findsOneWidget);

      // Tap PLAN tab
      await tester.tap(find.text('Plan'));
      await tester.pumpAndSettle();

      expect(find.text('YOUR DAY IS OPEN'), findsOneWidget);
    });

    testWidgets('3. Empty plan state offers quick time budget options and auto-plans', (tester) async {
      await SubjectController.instance.createSubject(name: 'Accountancy');

      await tester.pumpWidget(wrapWithApp(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('30m'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
      expect(find.text('3h'), findsOneWidget);

      // Tap 1h chip (scroll into view: header + assistant entry sit above)
      await tester.ensureVisible(find.text('1h'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1h'));
      await tester.pumpAndSettle();

      expect(find.text('PLAN MY 1 HOURS'), findsOneWidget);

      // Tap Plan button
      await tester.ensureVisible(find.text('PLAN MY 1 HOURS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PLAN MY 1 HOURS'));
      await tester.pumpAndSettle();

      // Should now display existing plan hero
      expect(find.text("TODAY'S PLAN"), findsOneWidget);
      expect(find.text("Today's Schedule"), findsOneWidget);
    });

    testWidgets('4. Existing plan hero shows next activity and START action', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final s = await SubjectController.instance.createSubject(name: 'Mathematics');

      await PlanningBlockController.instance.scheduleBlock(
        null,
        DateTime(today.year, today.month, today.day, 14, 0),
        DateTime(today.year, today.month, today.day, 14, 45),
        subjectId: s.id,
        customTitle: 'Calculus Review',
      );

      await tester.pumpWidget(wrapWithApp(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S PLAN"), findsOneWidget);
      expect(find.text('NEXT ACTIVITY'), findsOneWidget);
      expect(find.text('Calculus Review'), findsWidgets);
      expect(find.text('START'), findsWidgets);
    });

    testWidgets('5. STUDY tab displays smart study recommendation and 30m burst', (tester) async {
      await SubjectController.instance.createSubject(name: 'Business Law');

      await tester.pumpWidget(wrapWithApp(const PlanningScreen(initialTab: PlanStudyTab.study)));
      await tester.pumpAndSettle();

      expect(find.text('What Should I Study?'), findsOneWidget);
      expect(find.text('30-Minute Study Burst'), findsOneWidget);
      expect(find.text('My Subjects'), findsOneWidget);
      expect(find.text('Business Law'), findsWidgets);
    });

    testWidgets('6. Plan & Study 2.0 builds cleanly without overflow at 320dp width', (tester) async {
      await tester.pumpWidget(wrapWithApp(const PlanningScreen(), width: 320));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);

      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('What Should I Study?'), findsOneWidget);
    });
  });
}
