import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/app/app_shell.dart';
import 'package:student_os/core/navigation/shell_destinations.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_scaffold.dart';
import 'package:student_os/core/widgets/hamburger_menu.dart';
import 'package:student_os/core/widgets/module_placeholder_screen.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/data/models/student_profile.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/progress/progress_screen.dart';
import 'package:student_os/features/subjects/subjects_screen.dart';
import 'package:student_os/features/tasks/presentation/tasks_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StudentService.instance.clearProfile();
  });

  Widget wrapWithApp(Widget child,
      {double width = 390, AppShellController? controller}) {
    // Mirror the real app: AppScope sits above MaterialApp so pushed menu
    // routes can resolve the shell controller.
    return AppScope(
      controller: controller ?? AppShellController(),
      child: MaterialApp(
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
          child: AuthScope(
            authService: AuthService.instance,
            child: child,
          ),
        ),
      ),
    );
  }

  group('UI-3 — Navigation & Workspace Consistency Tests', () {
    testWidgets('1. Bottom Navigation renders all 5 destinations with equal distribution', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            bottomNavigationBar: StudentOSBottomNavigation(
              selectedIndex: selected,
              onDestinationSelected: (idx) => selected = idx,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final dest in ShellDestinations.all) {
        expect(find.text(dest.title), findsOneWidget);
      }

      // Tap 'Plan & Study' tab
      await tester.tap(find.text('Plan & Study'));
      await tester.pumpAndSettle();
      expect(selected, equals(1));

      // Tap 'SprintX' tab
      await tester.tap(find.text('SprintX'));
      await tester.pumpAndSettle();
      expect(selected, equals(2));

      // Tap 'Tools Hub' tab
      await tester.tap(find.text('Tools Hub'));
      await tester.pumpAndSettle();
      expect(selected, equals(3));

      // Tap 'Workspace' tab
      await tester.tap(find.text('Workspace'));
      await tester.pumpAndSettle();
      expect(selected, equals(4));
    });

    testWidgets('2. AppShell switches tabs cleanly without yellow line or layout exceptions', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppShell()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final navBar = find.byType(StudentOSBottomNavigation);

      // Switch through all tabs using bottom nav
      await tester.tap(find.descendant(of: navBar, matching: find.text('Plan & Study')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.descendant(of: navBar, matching: find.text('SprintX')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.descendant(of: navBar, matching: find.text('Tools Hub')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.descendant(of: navBar, matching: find.text('Workspace')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.descendant(of: navBar, matching: find.text('Home')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Hamburger menu shows identity, primary destinations, and navigates', (tester) async {
      await StudentService.instance.updateProfile(
        StudentProfile(displayName: 'Ayush Ragde'),
      );

      await tester.pumpWidget(
        wrapWithApp(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => openHamburgerMenu(context),
                  child: const Text('Open Menu'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      // Brand header + compact user identity (greeting + name combined)
      expect(find.text('Student OS'), findsOneWidget);
      expect(find.textContaining('Ayush Ragde'), findsOneWidget);

      // Primary destinations (no internal engines)
      for (final label in [
        'Home',
        'Plan & Study',
        'SprintX',
        'Tools Hub',
        'Workspace',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      // Secondary menu
      await tester.scrollUntilVisible(find.text('Ask Student OS'), 200);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Ask Student OS'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Tapping Progress pushes the progress workspace
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgressScreen), findsOneWidget);
    });

    testWidgets('4. AppScaffold provides unified header across workspaces', (tester) async {
      var backPressed = false;
      await tester.pumpWidget(
        wrapWithApp(
          AppScaffold(
            title: 'Unified Workspace',
            onBack: () => backPressed = true,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {},
              ),
            ],
            body: const Center(child: Text('Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unified Workspace'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(backPressed, isTrue);
    });

    testWidgets('5. Workspaces (Tasks, Subjects) render with consistent AppScaffold hierarchy', (tester) async {
      await tester.pumpWidget(wrapWithApp(const SubjectsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AppScaffold), findsOneWidget);
      expect(find.text('Subjects'), findsOneWidget);

      await tester.pumpWidget(wrapWithApp(const TasksScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AppScaffold), findsOneWidget);
      expect(find.text('Tasks'), findsWidgets);
    });
  });
}
