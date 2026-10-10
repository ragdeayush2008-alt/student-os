import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_music_controller.dart';
import 'package:student_os/features/focus/controller/focus_screen_sleep_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/screens/focus_center_screen.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_mode_holder.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

Widget _wrapRoutes(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    routes: AppRouter.routes(),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('focus3_test_user');
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    TaskController.instance.clearData();
    FocusModeHolder.instance.setMode(FocusMode.focusGuard);
    await FocusMusicController.instance.setTrack(-1);
    await FocusScreenSleepController.instance.setEnabled(false);
    await FocusController.instance.load();
    await SubjectController.instance.load();
    await TaskController.instance.load();
  });

  tearDown(() {
    if (FocusController.instance.hasActiveSession) {
      FocusController.instance.cancelSession();
    }
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    TaskController.instance.clearData();
    FocusModeHolder.instance.setMode(FocusMode.focusGuard);
    AuthIsolation.instance.clearSession();
  });

  group('Focus 3.0 — Mode leakage & separation', () {
    testWidgets('A. An ended Stopwatch never leaks into the Focus tab',
        (tester) async {
      // Simulate using the Stopwatch "anywhere" and ending it.
      FocusController.instance.startStopwatch(objective: 'Track Homework');
      FocusController.instance.stopSession();
      expect(FocusController.instance.hasActiveSession, isFalse);

      await tester.pumpWidget(_wrapRoutes(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      // The Focus tab opens on the authoritative FOCUS landing.
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);
      expect(find.text('Count-up timer'), findsNothing);
      expect(find.text('00:00:00'), findsNothing);
      expect(find.text('START STOPWATCH'), findsNothing);
      expect(find.text('Start Focus'), findsNothing);
      expect(find.textContaining('Focus Guard'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('B. A running session is shown on Focus-tab entry (genuine), '
        'but the selected mode stays FOCUS', (tester) async {
      // A Stopwatch starts elsewhere (external flow) BEFORE the tab opens.
      FocusController.instance.startStopwatch(objective: 'Track Homework');
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);

      // Opening the tab shows the running session (mode = actually running).
      await tester.pumpWidget(_wrapRoutes(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(FocusController.instance.hasActiveSession, isTrue);
      expect(find.text('STOPWATCH'), findsOneWidget);
      // The authoritative selected mode is separate and untouched.
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);
      expect(tester.takeException(), isNull);

      FocusController.instance.stopSession();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Focus 3.0 — Selecting Focus actually starts FOCUS', () {
    testWidgets('C. Landing Start Focus creates a focusGuard session (not Timer)',
        (tester) async {
      await SubjectController.instance.createSubject(name: 'Accountancy');

      await tester.pumpWidget(_wrapRoutes(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Start Focus'), findsOneWidget);
      await tester.tap(find.text('Start Focus'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.focusGuard);
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);
      expect(find.text('FOCUS MODE'), findsOneWidget);
      expect(tester.takeException(), isNull);

      fc.cancelSession();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('C2. Quick Start presets start focusGuard sessions (not Timers)',
        (tester) async {
      await tester.pumpWidget(_wrapRoutes(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sprint'));
      await tester.tap(find.text('Sprint'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.focusGuard);
      expect(fc.activeSession!.plannedDuration.inMinutes, 15);
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);
      expect(tester.takeException(), isNull);

      fc.cancelSession();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('C3. startContextualFocus (revision/assistant/autopilot) '
        'stays a Timer launch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppRouter.startContextualFocus(
                  ctx,
                  duration: const Duration(minutes: 25),
                  subjectName: 'Revision',
                ),
                child: const Text('Quick'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Quick'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.timer);
      expect(fc.activeSession!.plannedDuration.inMinutes, 25);

      fc.cancelSession();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Focus 3.0 — REAL STOP action on Timer/Stopwatch', () {
    testWidgets('D. STOP ends the Timer session; cleared active state, '
        'recorded partial', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 25), objective: 'Homework');
      final sessionId = fc.activeSession!.id;

      await tester.pumpWidget(_wrapRoutes(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(fc.hasActiveSession, isFalse);
      expect(find.text('No active session'), findsOneWidget);
      final ended = fc.sessions.where((s) => s.id == sessionId).single;
      expect(ended.outcome, SessionOutcome.partial);
      expect(fc.sessions.where((s) => s.outcome == SessionOutcome.completed),
          isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('E. Timer HUD exposes unified Pause / Stop / Reset controls',
        (tester) async {
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 30), objective: 'Flow');

      await tester.pumpWidget(_wrapRoutes(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(tester.takeException(), isNull);

      fc.stopSession();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('F. Reset restarts fresh; STOP clears active state (distinct)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 25), objective: 'Flow');
      final historyBefore = fc.sessions.length;
      final idBeforeReset = fc.activeSession!.id;

      await tester.pumpWidget(_wrapRoutes(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      // Reset: session stays active with a fresh id, no history record.
      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.id, isNot(idBeforeReset));
      expect(fc.activeSession!.mode, FocusMode.timer);
      expect(fc.sessions.length, historyBefore);

      // Stop: active state cleared.
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(fc.hasActiveSession, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('G. A paused Timer keeps running after Stop is NOT pressed; '
        'back lands on FOCUS while the session stays active', (tester) async {
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 30), objective: 'Flow');

      await tester.pumpWidget(_wrapRoutes(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(find.text('TIMER'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();

      // Back → FOCUS landing while the session keeps running in the background.
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.timer);
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);
      expect(find.text('Set duration'), findsNothing);
      expect(find.text('Count-up timer'), findsNothing);
      expect(find.textContaining('Focus Guard'), findsOneWidget);
      expect(tester.takeException(), isNull);

      fc.stopSession();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Focus 3.0 — Mode-selection flow from Plan & Study', () {
    Future<PlanningBlock> block90({String? subjectId}) async {
      // Block starts 1 minute in the future so the total assigned duration is
      // exactly 90 minutes (the remaining-duration adjustment only applies to
      // blocks that have already started).
      final now = DateTime.now();
      final start = now.add(const Duration(minutes: 1));
      return PlanningBlock(
        id: 'block_plan_90',
        userId: 'focus3_test_user',
        startAt: start,
        endAt: start.add(const Duration(minutes: 90)),
        subjectId: subjectId,
        customTitle: 'Corporate Law',
      );
    }

    testWidgets('H. PlanningBlock 90min → mode sheet → Focus → '
        'focusGuard 90 min with context (no re-ask)', (tester) async {
      final sub = await SubjectController.instance.createSubject(
          name: 'Corporate Law');
      final block = await block90(subjectId: sub.id);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppRouter.startPlanningBlockFocus(ctx, block),
                child: const Text('Start Block'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Block'));
      await tester.pumpAndSettle();

      // Mode-selection prompt with the scheduled duration — never re-asks.
      expect(find.text('What do you want to do?'), findsOneWidget);
      expect(find.text('90 min scheduled'), findsOneWidget);
      expect(find.text('Target Duration'), findsNothing);

      await tester.tap(find.text('Focus'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.focusGuard);
      expect(fc.activeSession!.plannedDuration.inMinutes, 90);
      expect(fc.activeSession!.planningBlockId, block.id);
      expect(fc.activeSession!.subjectId, sub.id);
      expect(fc.activeSession!.objective, 'Corporate Law');
      expect(tester.takeException(), isNull);

      fc.cancelSession();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('I. PlanningBlock 90min → mode sheet → Timer → '
        '90 min Timer with context', (tester) async {
      final sub = await SubjectController.instance.createSubject(
          name: 'Corporate Law');
      final block = await block90(subjectId: sub.id);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppRouter.startPlanningBlockFocus(ctx, block),
                child: const Text('Start Block'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Block'));
      await tester.pumpAndSettle();

      expect(find.text('What do you want to do?'), findsOneWidget);
      expect(find.text('90 min'), findsOneWidget);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.timer);
      expect(fc.activeSession!.plannedDuration.inMinutes, 90);
      expect(fc.activeSession!.planningBlockId, block.id);
      expect(fc.activeSession!.subjectId, sub.id);
      expect(fc.activeSession!.objective, 'Corporate Law');
      expect(tester.takeException(), isNull);

      fc.cancelSession();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('J. PlanningBlock → mode sheet → Stopwatch → '
        'open-ended 00:00:00 count-up with context', (tester) async {
      final sub = await SubjectController.instance.createSubject(
          name: 'Corporate Law');
      final block = await block90(subjectId: sub.id);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppRouter.startPlanningBlockFocus(ctx, block),
                child: const Text('Start Block'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Block'));
      await tester.pumpAndSettle();

      expect(find.text('What do you want to do?'), findsOneWidget);

      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.stopwatch);
      expect(fc.activeSession!.plannedDuration.inSeconds, 0);
      expect(fc.activeSession!.planningBlockId, block.id);
      expect(fc.activeSession!.subjectId, sub.id);
      // Wall-clock: allow the first seconds ticking after session start.
      expect(find.textContaining(RegExp(r'^00:00:0\d$')), findsWidgets);
      expect(tester.takeException(), isNull);

      fc.stopSession();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Focus 3.0 — Mode-aware session HUD', () {
    testWidgets('K. Guard control only in FOCUS sessions; Stop present; '
        'End Focus absent', (tester) async {
      final fc = FocusController.instance;
      fc.startFocusGuard(duration: const Duration(minutes: 25),
          objective: 'Deep Work');

      await tester.pumpWidget(_wrapRoutes(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Focus Guard'), findsOneWidget);
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('End Focus'), findsNothing);
      expect(tester.takeException(), isNull);

      fc.cancelSession();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('K2. Timer session HUD: Guard absent, STOP present, '
        'Sleep + BGM present', (tester) async {
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 25), objective: 'Flow');

      await tester.pumpWidget(_wrapRoutes(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.textContaining('Focus Guard'), findsNothing);
      expect(tester.takeException(), isNull);

      fc.stopSession();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('K3. Stopwatch session HUD: Guard absent, STOP present, '
        'Sleep + BGM present', (tester) async {
      final fc = FocusController.instance;
      fc.startStopwatch(objective: 'Track Homework');

      await tester.pumpWidget(_wrapRoutes(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.textContaining('Focus Guard'), findsNothing);
      expect(tester.takeException(), isNull);

      fc.stopSession();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Focus 3.0 — Paused Timer never hijacks Start Focus', () {
    testWidgets('L. Backing out of a paused Timer → FOCUS landing; '
        'Start Focus creates a FOCUS session', (tester) async {
      await SubjectController.instance.createSubject(name: 'Accountancy');
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 25), objective: 'Paused');
      fc.pauseSession();
      expect(fc.activeSession!.isPaused, isTrue);

      await tester.pumpWidget(_wrapRoutes(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      // The paused session is genuine and visible on entry.
      expect(find.text('Resume'), findsOneWidget);

      // Back out to the Focus landing; the paused Timer stays put.
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.timer);
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);
      expect(find.text('Set duration'), findsNothing);
      expect(find.textContaining('Focus Guard'), findsOneWidget);

      // Start Focus: produces a real FOCUS session, not Timer.
      await tester.tap(find.text('Start Focus'));
      await tester.pumpAndSettle();
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.mode, FocusMode.focusGuard);
      expect(FocusModeHolder.instance.mode, FocusMode.focusGuard);
      // The old paused Timer was auto-interrupted (preserved in history).
      expect(fc.sessions.any((s) => s.objective == 'Paused' &&
          s.outcome == SessionOutcome.interrupted), isTrue);
      expect(tester.takeException(), isNull);

      fc.cancelSession();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('M. STOP on a Stopwatch clears the active session',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final fc = FocusController.instance;
      fc.startStopwatch(objective: 'Track Homework');

      await tester.pumpWidget(_wrapRoutes(const FocusSessionScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'^00:00:0\d$')), findsWidgets);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(fc.hasActiveSession, isFalse);
      expect(find.text('No active session'), findsOneWidget);
      expect(fc.sessions.last.outcome, SessionOutcome.partial);
      expect(tester.takeException(), isNull);
    });
  });
}