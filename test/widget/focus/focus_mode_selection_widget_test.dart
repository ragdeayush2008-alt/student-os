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
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_mode_selection_sheet.dart';

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
    AuthIsolation.instance.setAuthenticatedUser('test_mode_sheet_user');
    FocusController.instance.clearData();
  });

  tearDown(() {
    FocusController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('FocusModeSelectionSheet Widget Tests', () {
    testWidgets('1. Renders context header, mode options (Focus, Timer, Stopwatch), and duration pills', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const FocusModeSelectionSheet(
            subjectName: 'Audit & Assurance',
            topicName: 'Vouching & Verification',
            suggestedDuration: Duration(minutes: 35),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Audit & Assurance'), findsWidgets);
      expect(find.text('What do you want to do?'), findsOneWidget);

      // Modes
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('35m suggested'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Stopwatch'), findsOneWidget);

      // Duration pills
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);
      expect(find.text('35 min'), findsWidgets);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
    });

    testWidgets('2. Selecting Focus mode starts session and preserves topic/subject context', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const FocusModeSelectionSheet(
            subjectId: 'sub_audit',
            subjectName: 'Audit & Assurance',
            topicId: 'top_vouching',
            topicName: 'Vouching & Verification',
            suggestedDuration: Duration(minutes: 35),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Focus option card
      await tester.tap(find.text('Focus'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.subjectId, 'sub_audit');
      expect(fc.activeSession!.topicId, 'top_vouching');
      expect(fc.activeSession!.plannedDuration, const Duration(minutes: 35));

      fc.clearData();
      await tester.pumpAndSettle();
    });

    testWidgets('3. Selecting Stopwatch mode starts open-ended session', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const FocusModeSelectionSheet(
            subjectName: 'Financial Management',
            focusTitle: 'Working Capital Study',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure visible & Tap Stopwatch
      await tester.ensureVisible(find.text('Stopwatch'));
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.stopwatch);
      expect(fc.activeSession!.plannedDuration, Duration.zero);

      fc.clearData();
      await tester.pumpAndSettle();
    });

    testWidgets('4. If Focus is already active, displays Continue Focus warning card and protects session', (tester) async {
      // Start an active session first
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 45),
        subjectName: 'Direct Tax',
        objective: 'Capital Gains Masterclass',
      );

      await tester.pumpWidget(
        _buildTestApp(
          const FocusModeSelectionSheet(
            subjectName: 'Company Law',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Focus is already active.'), findsOneWidget);
      expect(find.text('Continue Focus'), findsOneWidget);
      // New mode buttons are hidden to prevent accidental clobbering
      expect(find.text('What do you want to do?'), findsNothing);

      FocusController.instance.clearData();
      await tester.pumpAndSettle();
    });

    testWidgets('5. Responsive layout across 320dp, 360dp, 390dp, 412dp, 430dp widths', (tester) async {
      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];

      for (final w in widths) {
        await tester.pumpWidget(
          _buildTestApp(
            const FocusModeSelectionSheet(
              subjectName: 'Strategic Financial Management & Corporate Restructuring',
              taskTitle: 'Complete Advanced Valuation Problem Set 4',
              suggestedDuration: Duration(minutes: 45),
            ),
            size: Size(w, 800),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('What do you want to do?'), findsOneWidget);
        expect(find.text('Timer'), findsOneWidget);
      }
    });
  });
}
