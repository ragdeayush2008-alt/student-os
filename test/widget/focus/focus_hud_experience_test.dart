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
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';

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
    AuthIsolation.instance.setAuthenticatedUser('test_hud_user');
    FocusController.instance.clearData();
  });

  tearDown(() {
    FocusController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('FocusSessionScreen (Active HUD) Widget Tests', () {
    testWidgets('1. Renders branded logo mark, context, timer, progress, and action controls', (tester) async {
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 30),
        subjectName: 'Audit & Assurance',
        objective: 'Standards on Auditing (SA 200)',
      );

      await tester.pumpWidget(_buildTestApp(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      // Brand mark and badge
      expect(find.text('Audit & Assurance'), findsOneWidget);
      expect(find.text('Standards on Auditing (SA 200)'), findsOneWidget);
      expect(find.text('FOCUS MODE'), findsOneWidget);

      // Timer and subtitle (wall-clock: allow the first seconds ticking).
      expect(
        find.textContaining(RegExp(r'^(30:00|29:5\d)$')),
        findsOneWidget,
      );
      expect(find.textContaining('min left'), findsOneWidget);
      expect(find.textContaining('XP on completion'), findsOneWidget);

      // Primary controls
      expect(find.text('PAUSE'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);

      // Secondary controls
      expect(find.text('Add Note'), findsOneWidget);
      expect(find.text('Capture Thought'), findsOneWidget);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('2. Tapping Pause transitions to PAUSED state and changes CTA to Resume', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'Company Law',
      );

      await tester.pumpWidget(_buildTestApp(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      // Tap Pause
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.text('TIMER'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Responsive layout safety across 320dp, 360dp, 390dp, 412dp, 430dp widths', (tester) async {
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 45),
        subjectName: 'Strategic Management & Business Policy Analysis',
        objective: 'Michael Porter Five Forces Model Detailed Study',
      );

      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final w in widths) {
        await tester.pumpWidget(
          _buildTestApp(const FocusSessionScreen(), size: Size(w, 750)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('PAUSE'), findsOneWidget);
        expect(find.text('Stop'), findsOneWidget);
      }

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
