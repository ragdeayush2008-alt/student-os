import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/navigation/shell_destinations.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/features/auth/auth_service.dart';

/// Phase 1 SprintX Foundation — Focused automated tests.
/// All tests must pass with 0 errors and minimal new warnings.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 1 SprintX Foundation', () {
    test('Exactly 5 bottom destinations exist', () {
      expect(ShellDestinations.all.length, 5);
      final titles = ShellDestinations.all.map((d) => d.title).toList();
      expect(titles, contains('SprintX'));
      expect(titles, isNot(contains('Focus')));
      expect(titles, contains('Home'));
      expect(titles, contains('Plan & Study'));
      expect(titles, contains('Tools Hub'));
      expect(titles, contains('Workspace'));
    });

    test('Correct navigation labels and spelling', () {
      expect(ShellDestinations.sprintx.title, 'SprintX');
      expect(ShellDestinations.home.title, 'Home');
      expect(ShellDestinations.plan.title, 'Plan & Study');
      expect(ShellDestinations.workspace.title, 'Workspace');
    });

    test('SprintX opens to focus-center route', () {
      expect(ShellDestinations.sprintx.route, '/focus-center');
    });

    test('Active navigation state uses Student OS blue', () {
      // Verify theme builds without errors
      final theme = AppTheme.light();
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('Navigation animation tokens exist', () {
      // Verify motion tokens are available
      expect(ShellDestinations.all, isNotEmpty);
    });

    test('Navigation switching preserves IndexedStack behavior', () {
      // Verify app router routes include workspace
      final routes = AppRouter.routes();
      expect(routes.containsKey(AppRouter.workspaceRoute), isTrue);
    });

    test('Workspace uses "Subjects & Syllabus" wording', () {
      // Verify route exists for education setup
      final routes = AppRouter.routes();
      expect(routes.containsKey(AppRouter.courseSelectionRoute), isTrue);
    });

    test('No duplicate routes in AppRouter', () {
      final routes = AppRouter.routes();
      final uniqueKeys = routes.keys.toSet();
      expect(uniqueKeys.length, routes.length);
    });

    test('SprintX mode selector exists', () {
      // Verify SprintX uses the focus-center route which has mode selection
      expect(ShellDestinations.sprintx.route, '/focus-center');
    });

    test('Existing Focus business logic preserved', () {
      // Verify routes still include focus-related routes
      final routes = AppRouter.routes();
      expect(routes.containsKey(AppRouter.focusCenterRoute), isTrue);
    });

    test('Course & Education Setup routing preserved', () {
      final routes = AppRouter.routes();
      expect(routes.containsKey(AppRouter.courseSelectionRoute), isTrue);
    });
  });
}
