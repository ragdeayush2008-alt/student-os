import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_music_controller.dart';
import 'package:student_os/features/focus/controller/focus_screen_sleep_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/screens/focus_center_screen.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_menu_sheet.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_mode_holder.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

/// Sizes the real test viewport (a MediaQuery override alone does not move
/// the render tree, so taps would miss). Resets automatically.
void _setSurface(WidgetTester tester, double w, double h) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('sprintx_p4_test_user');
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    TaskController.instance.clearData();
    FocusModeHolder.instance.setMode(FocusMode.focusGuard);
    await FocusMusicController.instance.setTrack(-1);
    await FocusScreenSleepController.instance.setEnabled(false);
  });

  tearDown(() {
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    TaskController.instance.clearData();
    FocusModeHolder.instance.setMode(FocusMode.focusGuard);
    AuthIsolation.instance.clearSession();
  });

  group('SprintX Timer experience', () {
    testWidgets('countdown ring, context, and primary controls render',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 30),
        subjectName: 'Physics',
        objective: 'Kinematics problem set',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('TIMER'), findsOneWidget);
      expect(find.text('FOCUS MODE'), findsNothing);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Kinematics problem set'), findsOneWidget);
      // Wall-clock: allow the first seconds ticking after session start.
      expect(
        find.textContaining(RegExp(r'^(30:00|29:5\d)$')),
        findsOneWidget,
      );
      expect(find.textContaining('min left'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('assigned planning-block duration and context preserved',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 45),
        subjectName: 'Corporate Law',
        planningBlockId: 'block_plan_90',
        objective: 'Section 149 deep dive',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      final session = FocusController.instance.activeSession!;
      expect(session.planningBlockId, 'block_plan_90');
      expect(session.plannedDuration.inMinutes, 45);
      expect(find.text('Corporate Law'), findsOneWidget);
      expect(find.text('Section 149 deep dive'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'^(45:00|44:5\d)$')),
        findsOneWidget,
      );

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('pause shows PAUSED + Resume, resume restores Pause',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Flow',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.activeSession?.isPaused, isTrue);
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.activeSession?.isPaused, isFalse);
      expect(find.text('Pause'), findsOneWidget);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Stop ends recorded-partial without completing',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Homework',
      );
      final sessionId = FocusController.instance.activeSession!.id;

      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(FocusController.instance.hasActiveSession, isFalse);
      expect(find.text('No active session'), findsOneWidget);
      final ended = FocusController.instance.sessions
          .where((s) => s.id == sessionId)
          .single;
      expect(ended.outcome, SessionOutcome.partial);
      expect(
        FocusController.instance.sessions
            .where((s) => s.outcome == SessionOutcome.completed),
        isEmpty,
      );

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Reset restarts fresh without recording history',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Flow',
      );
      final historyBefore = FocusController.instance.sessions.length;
      final idBefore = FocusController.instance.activeSession!.id;

      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(FocusController.instance.hasActiveSession, isTrue);
      expect(FocusController.instance.activeSession!.id, isNot(idBefore));
      expect(
        FocusController.instance.activeSession!.mode,
        FocusMode.timer,
      );
      expect(FocusController.instance.sessions.length, historyBefore);
      expect(
        find.textContaining(RegExp(r'^(25:00|24:5\d)$')),
        findsOneWidget,
      );

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no Focus-only content on the Timer screen', (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'Biology',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Focus Guard'), findsNothing);
      expect(find.text('FOCUS MODE'), findsNothing);
      expect(find.textContaining('XP on completion'), findsNothing);
      expect(find.textContaining('streak'), findsNothing);
      expect(find.textContaining('Deep Focus'), findsNothing);
      expect(find.text('Stay Focused'), findsNothing);
      expect(find.text('Focus Analytics'), findsNothing);
      expect(find.text("You're Doing Great!"), findsNothing);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('quick tools: sleep, music, note, thought', (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Flow',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('QUICK TOOLS'), findsOneWidget);
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.text('OFF'), findsWidgets);
      expect(find.text('ON'), findsOneWidget);
      expect(find.text('Calm'), findsNothing);

      // Sleep toggles real state.
      await tester.ensureVisible(find.text('Prevent Screen Sleep'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prevent Screen Sleep'));
      await tester.pumpAndSettle();
      expect(FocusScreenSleepController.instance.isEnabled, isTrue);

      // Music ON reveals Calm/Ambient/Energy (last ON = music chip).
      await tester.ensureVisible(find.text('Background Music'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ON').last);
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.isEnabled, isTrue);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Ambient'), findsOneWidget);
      expect(find.text('Energy'), findsOneWidget);
      await tester.tap(find.text('OFF'));
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.isEnabled, isFalse);
      expect(find.text('Calm'), findsNothing);

      // Existing note/thought flows.
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

    testWidgets('Timer menu keeps only secondary options', (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Flow',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      final sheet = find.byType(FocusMenuSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('Focus Analytics')),
        findsNothing,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Pause')),
        findsNothing,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Stop')),
        findsNothing,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Reset')),
        findsNothing,
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
          matching: find.text('Background Music'),
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

  group('SprintX Stopwatch experience', () {
    testWidgets('count-up, elapsed language, and controls render',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startStopwatch(
        subjectName: 'Chemistry',
        objective: 'Track Homework',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('STOPWATCH'), findsOneWidget);
      expect(find.text('TIMER'), findsNothing);
      expect(find.text('FOCUS MODE'), findsNothing);
      expect(find.text('Chemistry'), findsOneWidget);
      expect(find.text('Track Homework'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'^00:00:0\d$')),
        findsOneWidget,
      );
      expect(find.text('Elapsed time'), findsOneWidget);
      expect(find.textContaining('left'), findsNothing);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('pause, resume, stop, reset lifecycle', (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startStopwatch(objective: 'Track Homework');
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.activeSession?.isPaused, isTrue);
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.activeSession?.isPaused, isFalse);

      final historyBefore = FocusController.instance.sessions.length;
      final idBefore = FocusController.instance.activeSession!.id;
      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.hasActiveSession, isTrue);
      expect(FocusController.instance.activeSession!.id, isNot(idBefore));
      expect(
        FocusController.instance.activeSession!.mode,
        FocusMode.stopwatch,
      );
      expect(FocusController.instance.sessions.length, historyBefore);

      final resetId = FocusController.instance.activeSession!.id;
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.hasActiveSession, isFalse);
      expect(find.text('No active session'), findsOneWidget);
      final ended = FocusController.instance.sessions
          .where((s) => s.id == resetId)
          .single;
      expect(ended.outcome, SessionOutcome.partial);
      expect(
        FocusController.instance.sessions
            .where((s) => s.outcome == SessionOutcome.completed),
        isEmpty,
      );

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no Focus-only content on the Stopwatch screen',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startStopwatch(objective: 'Track Homework');
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Focus Guard'), findsNothing);
      expect(find.textContaining('XP on completion'), findsNothing);
      expect(find.textContaining('streak'), findsNothing);
      expect(find.textContaining('Deep Focus'), findsNothing);
      expect(find.text('Stay Focused'), findsNothing);
      expect(find.text('Focus Analytics'), findsNothing);
      expect(find.text("You're Doing Great!"), findsNothing);
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.text('Add Note'), findsOneWidget);
      expect(find.text('Capture Thought'), findsOneWidget);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('SprintX mode isolation — six sequences', () {
    testWidgets('1. Timer → Back → Focus renders the full Focus UI',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Flow',
      );
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(find.text('TIMER'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Timer keeps running; landing is the full Focus UI.
      expect(FocusController.instance.hasActiveSession, isTrue);
      expect(FocusController.instance.activeSession!.mode, FocusMode.timer);
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);
      expect(find.textContaining('Focus Guard'), findsOneWidget);
      expect(find.text('TIMER'), findsNothing);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('2. Stopwatch → Back → Focus renders the full Focus UI',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startStopwatch(objective: 'Track Homework');
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(find.text('STOPWATCH'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(FocusController.instance.hasActiveSession, isTrue);
      expect(
        FocusController.instance.activeSession!.mode,
        FocusMode.stopwatch,
      );
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);
      expect(find.textContaining('Focus Guard'), findsOneWidget);
      expect(find.text('STOPWATCH'), findsNothing);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Focus → Back → Timer renders the Timer UI', (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
        subjectName: 'Accounting',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('FOCUS MODE'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.hasActiveSession, isTrue);

      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Flow',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('TIMER'), findsOneWidget);
      expect(find.text('FOCUS MODE'), findsNothing);
      expect(find.textContaining('Focus Guard'), findsNothing);
      expect(
        FocusController.instance.activeSession!.mode,
        FocusMode.timer,
      );
      expect(
        FocusController.instance.sessions.any(
          (s) =>
              s.mode == FocusMode.focusGuard &&
              s.outcome == SessionOutcome.interrupted,
        ),
        isTrue,
      );

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. Focus → Back → Stopwatch renders the Stopwatch UI',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
        subjectName: 'Accounting',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('FOCUS MODE'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(FocusController.instance.hasActiveSession, isTrue);

      FocusController.instance.startStopwatch(objective: 'Track Homework');
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('STOPWATCH'), findsOneWidget);
      expect(find.text('FOCUS MODE'), findsNothing);
      expect(find.text('Elapsed time'), findsOneWidget);
      expect(
        FocusController.instance.activeSession!.mode,
        FocusMode.stopwatch,
      );

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5. Timer → Back → Stopwatch carries no stale Timer state',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Flow',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('TIMER'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(FocusController.instance.hasActiveSession, isTrue);

      FocusController.instance.startStopwatch(objective: 'Track Homework');
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('STOPWATCH'), findsOneWidget);
      expect(find.text('TIMER'), findsNothing);
      expect(find.textContaining('min left'), findsNothing);
      expect(find.text('Elapsed time'), findsOneWidget);
      expect(
        FocusController.instance.activeSession!.mode,
        FocusMode.stopwatch,
      );

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('6. Stopwatch → Back → Timer carries no stale Stopwatch state',
        (tester) async {
      _setSurface(tester, 390, 844);
      FocusController.instance.startStopwatch(objective: 'Track Homework');
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('STOPWATCH'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(FocusController.instance.hasActiveSession, isTrue);

      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Flow',
      );
      await tester.pumpWidget(_wrap(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('TIMER'), findsOneWidget);
      expect(find.text('STOPWATCH'), findsNothing);
      expect(find.text('Elapsed time'), findsNothing);
      expect(find.textContaining('min left'), findsOneWidget);
      expect(
        FocusController.instance.activeSession!.mode,
        FocusMode.timer,
      );

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('SprintX responsive', () {
    testWidgets('Timer + Stopwatch: no overflow 320dp–430dp', (tester) async {
      void startMode(String mode) {
        FocusController.instance.clearData();
        if (mode == 'timer') {
          FocusController.instance.startTimer(
            duration: const Duration(minutes: 25),
            subjectName: 'Accounting',
            objective: 'Deep Focus Timer Work',
          );
        } else {
          FocusController.instance.startStopwatch(
            subjectName: 'Accounting',
            objective: 'Deep Focus Stopwatch Work',
          );
        }
      }

      const widths = [320.0, 360.0, 390.0, 412.0, 430.0];
      for (final mode in ['timer', 'stopwatch']) {
        for (final w in widths) {
          startMode(mode);
          tester.view.physicalSize = Size(w, 750);
          tester.view.devicePixelRatio = 1.0;
          await tester.pumpWidget(_wrap(const FocusSessionScreen()));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: '$mode @ ${w}dp');
          expect(find.text('Pause'), findsOneWidget);
          expect(find.text('Stop'), findsOneWidget);
          expect(find.text('Reset'), findsOneWidget);
          expect(find.text('QUICK TOOLS'), findsOneWidget);
          expect(find.text('Prevent Screen Sleep'), findsOneWidget);
          expect(find.text('Background Music'), findsOneWidget);
          expect(find.text('Add Note'), findsOneWidget);
          expect(find.text('Capture Thought'), findsOneWidget);
          expect(find.textContaining('Focus Guard'), findsNothing);
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
