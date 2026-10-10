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
import 'package:student_os/features/calendar/presentation/calendar_screen.dart';
import 'package:student_os/features/notifications/presentation/notification_center_screen.dart';
import 'package:student_os/features/tasks/presentation/tasks_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';
import 'package:student_os/features/tools/presentation/tools_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
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

  group('Tools Hub — Integration Tests', () {
    testWidgets('1. Bottom-nav switches to Tools tab (index 3) and renders ToolsHubScreen', (tester) async {
      final shellCtrl = AppShellController();
      await tester.pumpWidget(wrapWithApp(const AppShell(), controller: shellCtrl));
      await tester.pumpAndSettle();

      expect(shellCtrl.selectedIndex, 0);

      // Tap Tools Hub tab in bottom nav
      final navBar = find.byType(StudentOSBottomNavigation);
      await tester.tap(find.descendant(of: navBar, matching: find.text('Tools Hub')));
      await tester.pumpAndSettle();

      expect(shellCtrl.selectedIndex, 3);
      expect(find.byType(ToolsHubScreen), findsOneWidget);
    });

    testWidgets('2. AppRouter.openTools switches directly to Tools tab', (tester) async {
      final shellCtrl = AppShellController();
      await tester.pumpWidget(
        wrapWithApp(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppRouter.openTools(context),
                child: const Text('Go Tools'),
              ),
            ),
          ),
          controller: shellCtrl,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go Tools'));
      await tester.pumpAndSettle();

      expect(shellCtrl.selectedIndex, 3);
    });

    testWidgets('3. Navigates to Calendar from Tools Hub and handles back navigation', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      // Filter to Schedule & Tasks to bring Calendar to top
      final chipFinder = find.text('Schedule & Tasks').first;
      await tester.ensureVisible(chipFinder);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Tap Academic Calendar tool
      final calendarFinder = find.text('Academic Calendar');
      expect(calendarFinder, findsOneWidget);
      await tester.tap(calendarFinder);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarScreen), findsOneWidget);

      // Back navigation returns to ToolsHubScreen
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(ToolsHubScreen), findsOneWidget);
    });

    testWidgets('4. Navigates to Tasks from Tools Hub and handles back navigation', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      // Filter to Schedule & Tasks
      final chipFinder = find.text('Schedule & Tasks').first;
      await tester.ensureVisible(chipFinder);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Tap Academic Tasks & Deliverables tool
      final taskFinder = find.text('Academic Tasks & Deliverables');
      expect(taskFinder, findsOneWidget);
      await tester.tap(taskFinder);
      await tester.pumpAndSettle();

      expect(find.byType(TasksScreen), findsOneWidget);

      // Back navigation
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(ToolsHubScreen), findsOneWidget);
    });

    testWidgets('5. Navigates to Notification Center from Tools Hub and returns cleanly', (tester) async {
      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      // Filter to Schedule & Tasks
      final chipFinder = find.text('Schedule & Tasks').first;
      await tester.ensureVisible(chipFinder);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Tap Activity & Notifications tool
      final notifFinder = find.text('Activity & Notifications');
      expect(notifFinder, findsOneWidget);
      await tester.tap(notifFinder);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCenterScreen), findsOneWidget);

      // Back navigation
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(ToolsHubScreen), findsOneWidget);
    });

    testWidgets('6. Tools Hub operates completely offline without network dependencies', (tester) async {
      // Local tasks in TaskController
      AuthIsolation.instance.setAuthenticatedUser('offline_user');
      await TaskController.instance.createTask(title: 'Offline Tool Task');

      await tester.pumpWidget(wrapWithApp(const ToolsHubScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ToolsHubScreen), findsOneWidget);
      expect(find.text('Quick Notes'), findsOneWidget);
    });

    testWidgets('7. A -> B -> A user isolation test for Tools Hub data badges', (tester) async {
      // User A setup
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      await TaskController.instance.createTask(title: 'User A Task');
      expect(TaskController.instance.tasks.length, 1);

      // User switch to User B
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();
      expect(TaskController.instance.tasks.isEmpty, isTrue);

      AuthIsolation.instance.setAuthenticatedUser('user_B');
      await TaskController.instance.createTask(title: 'User B Task 1');
      await TaskController.instance.createTask(title: 'User B Task 2');
      expect(TaskController.instance.tasks.length, 2);

      // Switch back to User A
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      await TaskController.instance.load();

      expect(TaskController.instance.tasks.length, 1);
      expect(TaskController.instance.tasks.first.title, 'User A Task');
    });
  });
}
