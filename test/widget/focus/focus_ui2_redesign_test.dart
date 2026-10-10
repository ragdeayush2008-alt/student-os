import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_music_controller.dart';
import 'package:student_os/features/focus/controller/focus_screen_sleep_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_menu_sheet.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

/// Sizes the real test viewport (MediaQuery override alone does not move the
/// render tree, so taps would miss). Resets automatically after the test.
void _setSurface(WidgetTester tester, double w, double h) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void _startFocus() {
  FocusController.instance.startFocusGuard(
    duration: const Duration(minutes: 25),
    subjectName: 'Accounting',
    objective: 'Deep Focus',
  );
  FocusController.instance.setPhase(FocusPhase.focusing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('focus_ui2_test_user');
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    TaskController.instance.clearData();
    await FocusMusicController.instance.setTrack(-1);
    await FocusScreenSleepController.instance.setEnabled(false);
  });

  tearDown(() {
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    TaskController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('Focus UI 2.0 — reference hierarchy', () {
    testWidgets('renders badge, subject, timer, XP/streak and controls',
        (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('FOCUS MODE'), findsOneWidget);
      expect(find.text('Accounting'), findsOneWidget);
      expect(find.text('Deep Focus'), findsOneWidget);
      // Wall-clock: allow the first seconds ticking after session start.
      expect(
        find.textContaining(RegExp(r'^(25:00|24:5\d)$')),
        findsOneWidget,
      );
      expect(find.textContaining('min left'), findsOneWidget);
      expect(find.text('Stay Focused'), findsOneWidget);
      expect(find.textContaining('XP on completion'), findsOneWidget);
      expect(find.textContaining('streak'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('PAUSE'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('End Focus'), findsNothing);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('all five quick tools render with motivational card',
        (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUICK TOOLS'), findsOneWidget);
      expect(find.text('Add Note'), findsOneWidget);
      expect(find.text('Capture Thought'), findsOneWidget);
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.text('Focus Guard'), findsOneWidget);
      expect(find.text("You're Doing Great!"), findsOneWidget);
      expect(find.textContaining('Small steps'), findsOneWidget);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Focus Guard renders even when Setup Needed', (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      // Default test platform has no Guard support → must still render.
      expect(find.text('Focus Guard'), findsOneWidget);
      expect(find.text('Setup Needed'), findsOneWidget);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Focus UI 2.0 — state', () {
    testWidgets('pause shows RESUME/PAUSED, resume restores PAUSE',
        (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PAUSE'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.activeSession?.isPaused, isTrue);
      expect(find.text('RESUME'), findsOneWidget);
      expect(find.text('PAUSED'), findsOneWidget);
      // Structure persists while paused.
      expect(find.text('Focus Guard'), findsOneWidget);
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);

      await tester.tap(find.text('RESUME'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.activeSession?.isPaused, isFalse);
      expect(find.text('PAUSE'), findsOneWidget);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Stop ends the session via the existing lifecycle',
        (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.hasActiveSession, isFalse);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Back preserves the running session', (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.hasActiveSession, isTrue);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Focus UI 2.0 — quick tools behavior', () {
    testWidgets('screen sleep card toggles real state', (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('OFF'), findsWidgets);
      await tester.ensureVisible(find.text('Prevent Screen Sleep'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prevent Screen Sleep'));
      await tester.pumpAndSettle();
      expect(FocusScreenSleepController.instance.isEnabled, isTrue);
      expect(find.text('ON'), findsWidgets);

      await tester.tap(find.text('Prevent Screen Sleep'));
      await tester.pumpAndSettle();
      expect(FocusScreenSleepController.instance.isEnabled, isFalse);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('music card toggles and reveals track selector',
        (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Calm'), findsNothing);
      await tester.ensureVisible(find.text('Background Music'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Background Music'));
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.isEnabled, isTrue);
      // Card helper shows the active track AND the selector chip shows it.
      expect(find.text('Calm'), findsWidgets);
      expect(find.text('Ambient'), findsOneWidget);
      expect(find.text('Energy'), findsOneWidget);

      await tester.ensureVisible(find.text('Ambient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ambient'));
      await tester.pumpAndSettle();
      expect(
        FocusMusicController.instance.selectedTrack?.title,
        'Ambient',
      );

      await FocusMusicController.instance.setTrack(-1);
      await tester.pumpAndSettle();
      expect(find.text('Calm'), findsNothing);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Add Note and Capture Thought open existing sheets',
        (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Add Note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Note'));
      await tester.pumpAndSettle();
      expect(find.text('Session Note'), findsOneWidget);
      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Capture Thought'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capture Thought'));
      await tester.pumpAndSettle();
      expect(find.text('Capture Distraction'), findsOneWidget);
      await tester.tap(find.text('Save to Distraction Inbox'));
      await tester.pumpAndSettle();

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('three-dot menu keeps only secondary options',
        (tester) async {
      _setSurface(tester, 390, 844);
      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      final sheet = find.byType(FocusMenuSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('Focus Analytics')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Focus History')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Prevent Screen Sleep'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.textContaining('Focus Guard'),
        ),
        findsNothing,
      );

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Focus UI 2.0 — mode isolation', () {
    testWidgets('Timer then Focus renders the full Focus UI', (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Flow',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('TIMER'), findsOneWidget);
      FocusController.instance.stopSession();
      await tester.pumpWidget(const SizedBox());

      _startFocus();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('FOCUS MODE'), findsOneWidget);
      expect(find.text('Focus Guard'), findsOneWidget);
      expect(find.text('PAUSE'), findsOneWidget);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Focus UI 2.0 — responsive', () {
    testWidgets('no overflow from 320dp to 430dp in all three modes',
        (tester) async {
      void startMode(String mode) {
        FocusController.instance.clearData();
        switch (mode) {
          case 'timer':
            FocusController.instance.startTimer(
              duration: const Duration(minutes: 25),
              subjectName: 'Accounting',
              objective: 'Deep Focus',
            );
          case 'stopwatch':
            FocusController.instance.startStopwatch(
              subjectName: 'Accounting',
              objective: 'Deep Focus',
            );
          default:
            _startFocus();
        }
      }

      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final mode in ['focus', 'timer', 'stopwatch']) {
        for (final w in widths) {
          startMode(mode);
          tester.view.physicalSize = Size(w, 750);
          tester.view.devicePixelRatio = 1.0;
          await tester.pumpWidget(_wrap(const FocusSessionScreen()));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: '$mode @ ${w}dp');
          expect(
            find.text(mode == 'focus' ? 'PAUSE' : 'Pause'),
            findsOneWidget,
          );
          expect(find.text('Stop'), findsOneWidget);
          expect(find.text('Add Note'), findsOneWidget);
          expect(find.text('Capture Thought'), findsOneWidget);
          expect(find.text('Prevent Screen Sleep'), findsOneWidget);
          expect(find.text('Background Music'), findsOneWidget);
          if (mode == 'focus') {
            expect(find.text('FOCUS MODE'), findsOneWidget);
            expect(find.text('Focus Guard'), findsOneWidget);
          } else {
            expect(find.textContaining('Focus Guard'), findsNothing);
          }
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
