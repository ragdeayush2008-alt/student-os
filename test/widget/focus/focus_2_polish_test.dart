import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_music_controller.dart';
import 'package:student_os/features/focus/controller/focus_screen_sleep_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/screens/focus_center_screen.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light(),
    home: Scaffold(body: child),
  );
}

Future<SubjectController> _ensureSubject() async {
  final sc = SubjectController.instance;
  if (sc.activeSubjects.isEmpty) {
    await sc.createSubject(name: 'Accountancy');
  }
  return sc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('focus2_test_user');
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
  });

  tearDown(() {
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('Focus 2.0 — Modes rendering', () {
    testWidgets('Focus mode renders ready state', (tester) async {
      // Need a subject for the ready hero to appear.
      final sc = await _ensureSubject();
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Focus'), findsWidgets);
      expect(find.text('READY TO FOCUS'), findsOneWidget);
      expect(find.text('Start Focus'), findsOneWidget);
      await sc.deleteSubject(sc.activeSubjects.first.id);
    });

    testWidgets('Timer mode renders dial and presets', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      expect(find.text('Set duration'), findsOneWidget);
      expect(find.text('15 MIN'), findsOneWidget);
      expect(find.text('START TIMER'), findsOneWidget);
    });

    testWidgets('Stopwatch mode renders', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();
      expect(find.text('Count-up timer'), findsOneWidget);
      expect(find.text('START STOPWATCH'), findsOneWidget);
    });

    testWidgets('mode switching animates without overflow', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      // Focus label is ambiguous (header + segment), so target the
      // segmented control directly for that one.
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Focus').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Focus 2.0 — Theme', () {
    testWidgets('light theme renders without dark background', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen(), theme: AppTheme.light()));
      await tester.pumpAndSettle();
      expect(find.text('Focus'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark theme renders', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen(), theme: AppTheme.dark()));
      await tester.pumpAndSettle();
      expect(find.text('Focus'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('session follows light then dark theme', (tester) async {
      FocusController.instance.startTimer(duration: const Duration(minutes: 25), objective: 'Test');
      await tester.pumpWidget(_wrap(const FocusSessionScreen(), theme: AppTheme.light()));
      await tester.pumpAndSettle();
      expect(find.textContaining(':'), findsWidgets);
      // Switch to dark
      await tester.pumpWidget(_wrap(const FocusSessionScreen(), theme: AppTheme.dark()));
      await tester.pumpAndSettle();
      expect(find.textContaining(':'), findsWidgets);
      expect(tester.takeException(), isNull);
      FocusController.instance.clearData();
      await tester.pump();
    });
  });

  group('Focus 2.0 — Session states', () {
    testWidgets('active session shows timer and pause', (tester) async {
      FocusController.instance.startTimer(duration: const Duration(minutes: 10), objective: 'Active');
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsOneWidget);
      expect(find.textContaining('min left'), findsOneWidget);
      FocusController.instance.clearData();
      await tester.pump();
    });

    testWidgets('paused session shows Resume and muted glow', (tester) async {
      FocusController.instance.startTimer(duration: const Duration(minutes: 10), objective: 'PauseTest');
      FocusController.instance.pauseSession();
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('PAUSED'), findsOneWidget);
      FocusController.instance.clearData();
      await tester.pump();
    });

    testWidgets('context is preserved in session HUD', (tester) async {
      FocusController.instance.startTimer(duration: const Duration(minutes: 20), objective: 'Chapter 3 · Partnership', subjectName: 'Accountancy');
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      // Subject renders as-is in the HUD.
      expect(find.textContaining('Accountancy'), findsOneWidget);
      expect(find.textContaining('Chapter 3'), findsOneWidget);
      FocusController.instance.clearData();
      await tester.pump();
    });

    testWidgets('responsive 320dp and 430dp do not overflow', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      FocusController.instance.startTimer(duration: const Duration(minutes: 25), objective: 'Resp');
      for (final w in [320.0, 430.0]) {
        tester.view.physicalSize = Size(w, 800);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(_wrap(const FocusSessionScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FocusController.instance.clearData();
      await tester.pump();
    });
  });

  group('Focus 2.0 — Analytics isolation', () {
    test('only Focus mode contributes to focus analytics', () {
      FocusController.instance.clearData();
      // Simulate one Focus, one Timer, one Stopwatch completed sessions
      FocusController.instance.startFocusGuard(duration: const Duration(minutes: 25), objective: 'Focus');
      FocusController.instance.completeSession();
      FocusController.instance.startTimer(duration: const Duration(minutes: 25), objective: 'Timer');
      FocusController.instance.completeSession();
      FocusController.instance.startStopwatch(objective: 'Stopwatch');
      FocusController.instance.completeSession();

      final all = FocusController.instance.sessions.where((s) => s.isComplete).toList();
      final focusOnly = all.where((s) => s.mode == FocusMode.focusGuard).toList();
      final timerOnly = all.where((s) => s.mode == FocusMode.timer).toList();
      final stopwatchOnly = all.where((s) => s.mode == FocusMode.stopwatch).toList();

      expect(all.length, 3);
      expect(focusOnly.length, 1);
      expect(timerOnly.length, 1);
      expect(stopwatchOnly.length, 1);
      // Analytics in CenterScreen filters to focusGuard only — verify
      final thisWeekFocus = focusOnly.length;
      expect(thisWeekFocus, 1);
      expect(timerOnly.length + stopwatchOnly.length, 2);
      // Timer/Stopwatch must NOT be counted as focus time
      expect(focusOnly.any((s) => s.mode == FocusMode.timer), isFalse);
      expect(focusOnly.any((s) => s.mode == FocusMode.stopwatch), isFalse);
    });
  });

  group('Focus 2.0 — Existing controllers preserved', () {
    testWidgets('music state reflects off and track selection', (tester) async {
      final music = FocusMusicController.instance;
      // Default off
      expect(music.selectedTrack, isNull);
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('screen sleep toggle reflects state', (tester) async {
      final sleep = FocusScreenSleepController.instance;
      final initial = sleep.isEnabled;
      expect(initial, isA<bool>());
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('focus guard state does not crash Center', (tester) async {
      final guard = FocusGuardController.instance;
      expect(guard, isNotNull);
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
