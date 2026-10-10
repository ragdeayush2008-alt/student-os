import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/hamburger_menu.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/auth_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapWithApp(Widget child, {AppShellController? controller}) {
    // Mirror the real app: AppScope sits above MaterialApp so pushed menu
    // routes can resolve the shell controller.
    return AppScope(
      controller: controller ?? AppShellController(),
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 800)),
          child: AuthScope(
            authService: AuthService.instance,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester,
      {AppShellController? controller}) async {
    await tester.pumpWidget(
      wrapWithApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openHamburgerMenu(context),
            child: const Text('Open'),
          ),
        ),
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('HamburgerMenu (Command Center)', () {
    testWidgets('opens when openHamburgerMenu is called', (tester) async {
      await openMenu(tester);

      expect(find.text('Student OS'), findsOneWidget);
    });

    testWidgets('shows primary destinations, never internal engines',
        (tester) async {
      await openMenu(tester);

      for (final label in [
        'Home',
        'Plan & Study',
        'SprintX',
        'Tools Hub',
        'Workspace',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      for (final hidden in [
        'Revision Engine',
        'Planning Engine',
        'Autopilot',
        'Conflict Engine',
      ]) {
        expect(find.text(hidden), findsNothing);
      }
    });

    testWidgets('shows secondary menu and logout', (tester) async {
      await openMenu(tester);

      await tester.scrollUntilVisible(find.text('Ask Student OS'), 200);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Ask Student OS'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Logout'), 200);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('selecting a destination switches tab and closes menu',
        (tester) async {
      final controller = AppShellController();
      await openMenu(tester, controller: controller);

      await tester.tap(find.text('SprintX'));
      await tester.pumpAndSettle();

      expect(controller.selectedIndex, 2);
      expect(find.text('Student OS'), findsNothing);
    });

    testWidgets('closes when close button is tapped', (tester) async {
      await openMenu(tester);
      expect(find.text('Student OS'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Student OS'), findsNothing);
    });

    testWidgets('closes when backdrop is tapped', (tester) async {
      await openMenu(tester);
      expect(find.text('Student OS'), findsOneWidget);

      // Tap the backdrop (right side of screen)
      await tester.tapAt(const Offset(350, 400));
      await tester.pumpAndSettle();

      expect(find.text('Student OS'), findsNothing);
    });

    testWidgets('no overflow at 320dp', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openMenu(tester);

      // Scroll through all items so every row is laid out.
      await tester.scrollUntilVisible(find.text('Logout'), 200);
      await tester.scrollUntilVisible(find.text('Home'), -200);

      expect(tester.takeException(), isNull);
    });
  });
}
