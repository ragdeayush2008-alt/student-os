import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/presentation/screens/focus_center_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

Widget _buildTestApp(Widget child, {Size size = const Size(390, 844)}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    routes: AppRouter.routes(),
    home: MediaQuery(
      data: MediaQueryData(size: size),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_hub_user');
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
  });

  tearDown(() {
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('FocusCenterScreen (Focus Hub) Widget Tests', () {
    testWidgets('1. Renders streak and this week stat cards, quick start presets, and mode actions', (tester) async {
      await SubjectController.instance.createSubject(name: 'Audit & Assurance');

      await tester.pumpWidget(_buildTestApp(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);

      // Hero
      expect(find.text('READY TO FOCUS'), findsOneWidget);
      expect(find.text('Audit & Assurance'), findsWidgets);
      expect(find.text('Start Focus'), findsOneWidget);

      // Quick Start Presets
      expect(find.text('Sprint'), findsOneWidget);
      expect(find.text('Deep Focus'), findsOneWidget);
      expect(find.text('Deep Work'), findsOneWidget);

      // Mode Action buttons
      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Stopwatch'), findsOneWidget);
    });

    testWidgets('2. Renders clean empty state when no subjects are registered', (tester) async {
      await tester.pumpWidget(_buildTestApp(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to focus on yet.'), findsOneWidget);
      expect(find.text('Add Subject'), findsOneWidget);
    });

    testWidgets('3. Responsive layout across all device widths: 320dp, 360dp, 390dp, 412dp, 430dp', (tester) async {
      await SubjectController.instance.createSubject(
        name: 'Corporate & Economic Regulatory Law',
      );

      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final w in widths) {
        await tester.pumpWidget(
          _buildTestApp(const FocusCenterScreen(), size: Size(w, 750)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Focus'), findsWidgets);
      }
    });
  });
}
