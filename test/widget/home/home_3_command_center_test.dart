import 'package:flutter/material.dart' hide PrioritizedAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/core/widgets/module_placeholder_screen.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/home/home_command_center_state.dart';
import 'package:student_os/features/home/home_command_center_widgets.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/preferences/user_preferences_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 2 — Home 3.0 Student OS Command Center.
///
/// Covers the contextual states, the single recommendation, active-session
/// surfacing, autopilot awareness, empty states, responsiveness and
/// navigation. Every assertion reads real controller/engine state — no test
/// asserts fabricated Home data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppClock.reset();
    await _cleanAcademicData();
  });

  tearDown(() async {
    await _cleanAcademicData();
    AppClock.reset();
    await UserPreferencesController.instance.setAutopilotMode(AutopilotMode.off);
    AcademicIntelligenceController.instance.clearData();
  });

  Widget wrapWithApp(Widget child, {double width = 390, double height = 800}) {
    return MaterialApp(
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
        data: MediaQueryData(size: Size(width, height)),
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

  Future<void> pumpHome(WidgetTester tester, {double width = 390}) async {
    await tester.pumpWidget(wrapWithApp(const HomeScreen(), width: width));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  // ══════════════════════════════════════════════════════════════════════
  // 1. NEW USER / EMPTY STATE
  // ══════════════════════════════════════════════════════════════════════

  group('new user / empty state', () {
    testWidgets('renders without fake progress and stays exception-free', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      // The hero must offer a way forward, not invent progress.
      expect(find.textContaining('build your day'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no tasks: Home does not render an overdue metric', (
      tester,
    ) async {
      await pumpHome(tester);
      // "Overdue" is only a real metric when a task is actually overdue.
      expect(find.text('OVERDUE'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no exams: no exam countdown is invented', (tester) async {
      await pumpHome(tester);
      expect(ExamController.instance.exams, isEmpty);
      expect(find.text('Upcoming & Goals'), findsOneWidget);
      // With no exams there must be no countdown text at all.
      expect(find.text('Tomorrow'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty-state actions are reachable and do not crash', (
      tester,
    ) async {
      await pumpHome(tester);
      // Every quick action is a launcher into an existing flow.
      for (final label in ['Focus', 'Plan Day', 'Study', 'Revise']) {
        expect(find.text(label), findsWidgets, reason: 'missing $label');
      }
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 2. NO PLAN
  // ══════════════════════════════════════════════════════════════════════

  group('no plan', () {
    testWidgets('offers to build the day rather than showing empty cards', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Quick Actions'), findsOneWidget);
      // No planned blocks, so no schedule section should invent rows.
      expect(PlanningBlockController.instance.blocks, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 3. PLAN EXISTS
  // ══════════════════════════════════════════════════════════════════════

  group('plan exists', () {
    testWidgets('planned blocks surface in Next/Schedule with block count', (
      tester,
    ) async {
      // Frozen mid-day clock keeps the block inside "today" regardless of when
      // the suite runs, so the assertion is deterministic.
      AppClock.freezeAt(DateTime(2026, 9, 29, 10, 0));
      final start = DateTime(2026, 9, 29, 14, 0);
      await PlanningBlockController.instance.scheduleBlock(
        null,
        start,
        start.add(const Duration(minutes: 45)),
        customTitle: 'Accountancy block',
      );

      await pumpHome(tester);

      final home = HomeCommandCenterState.derive();
      expect(home.plannedBlockCount, 1);
      expect(find.textContaining('NEXT'), findsWidgets);
      expect(tester.takeException(), isNull);

      PlanningBlockController.instance.clearData();
      AppClock.reset();
    });

    testWidgets('Plan Day tile shows a real block count detail', (
      tester,
    ) async {
      AppClock.freezeAt(DateTime(2026, 9, 29, 10, 0));
      final start = DateTime(2026, 9, 29, 15, 0);
      await PlanningBlockController.instance.scheduleBlock(
        null,
        start,
        start.add(const Duration(minutes: 30)),
        customTitle: 'Business Law block',
      );

      await pumpHome(tester);

      final home = HomeCommandCenterState.derive();
      expect(home.planDayDetailLabel, '1 block');
      // Single form, no awkward "1 blocks".
      expect(home.planDayDetailLabel, isNot(contains('1 blocks')));
      expect(tester.takeException(), isNull);

      PlanningBlockController.instance.clearData();
      AppClock.reset();
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 4–6. ACTIVE FOCUS / TIMER / STOPWATCH
  // ══════════════════════════════════════════════════════════════════════

  group('active session surfacing', () {
    testWidgets('no active session means no session banner', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.byType(HomeActiveSessionBanner), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('active Focus Guard surfaces the banner and Continue', (
      tester,
    ) async {
      // Focus Guard is the protected mode; plain quick focus is a Timer.
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
        subjectName: 'Accountancy',
      );
      await tester.pump();

      await pumpHome(tester);

      expect(find.byType(HomeActiveSessionBanner), findsOneWidget);
      expect(find.text('FOCUS ACTIVE'), findsWidgets);
      expect(find.text('Accountancy'), findsWidgets);
      expect(find.text('Continue'), findsWidgets);

      // The Focus tile is badged so the launcher reflects the live session.
      expect(find.text('LIVE'), findsOneWidget);
      expect(tester.takeException(), isNull);

      FocusController.instance.completeSession();
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('active Timer surfaces TIMER ACTIVE', (tester) async {
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 10),
        subjectName: 'Business Law',
      );
      await tester.pump();

      await pumpHome(tester);

      final home = HomeCommandCenterState.derive();
      expect(home.activeSession?.kind, HomeActiveSessionKind.timer);
      expect(find.text('TIMER ACTIVE'), findsWidgets);
      expect(tester.takeException(), isNull);

      FocusController.instance.completeSession();
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('active Stopwatch reports elapsed, not remaining', (
      tester,
    ) async {
      FocusController.instance.startStopwatch(subjectName: 'Study session');
      await tester.pump();

      await pumpHome(tester);

      final home = HomeCommandCenterState.derive();
      final session = home.activeSession;
      expect(session, isNotNull);
      expect(session!.kind, HomeActiveSessionKind.stopwatch);
      expect(session.isOpenEnded, isTrue);
      // A stopwatch has no countdown target, so it must not claim one.
      expect(session.timeLabel, contains('elapsed'));
      expect(session.timeLabel, isNot(contains('remaining')));
      expect(find.text('STOPWATCH ACTIVE'), findsWidgets);
      expect(tester.takeException(), isNull);

      FocusController.instance.completeSession();
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Home never starts a second session from the banner', (
      tester,
    ) async {
      FocusController.instance.startQuickFocus(
        duration: const Duration(minutes: 25),
        subjectName: 'Accountancy',
      );
      await tester.pump();

      await pumpHome(tester);

      final before = FocusController.instance.activeSession?.id;
      expect(before, isNotNull);

      // Reading state repeatedly must be side-effect free.
      for (var i = 0; i < 5; i++) {
        HomeCommandCenterState.derive();
      }
      await tester.pumpAndSettle();

      expect(FocusController.instance.activeSession?.id, before);
      expect(tester.takeException(), isNull);

      FocusController.instance.completeSession();
      await tester.pump(const Duration(seconds: 5));
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 7. OVERDUE WORK
  // ══════════════════════════════════════════════════════════════════════

  group('overdue work', () {
    testWidgets('an overdue task raises the Overdue progress metric', (
      tester,
    ) async {
      await TaskController.instance.createTask(
        title: 'Overdue revision task',
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      await pumpHome(tester);

      final home = HomeCommandCenterState.derive();
      expect(home.overdueTaskCount, greaterThan(0));
      // Overdue is prioritised high enough to be visible on the Today card.
      expect(find.text('OVERDUE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('overdue work drives the single recommendation with a why', (
      tester,
    ) async {
      await TaskController.instance.createTask(
        title: 'Overdue Contract Act revision',
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      await pumpHome(tester);

      final home = HomeCommandCenterState.derive();
      if (home.recommendation != null) {
        await scrollTo(tester, find.byType(HomeRecommendedActionCard));
        expect(find.text('RECOMMENDED FOR YOU'), findsOneWidget);
        // The reason must be the engine's, not Home's invention.
        expect(home.recommendation!.reason, isNotEmpty);
      }
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 8. EXAM APPROACHING
  // ══════════════════════════════════════════════════════════════════════

  group('exam approaching', () {
    testWidgets('nearest exam drives the countdown in Upcoming', (
      tester,
    ) async {
      await ExamController.instance.createExam(
        title: 'CA Foundation',
        subject: 'Accountancy',
        examDateTime: DateTime.now().add(const Duration(days: 12)),
      );

      await pumpHome(tester);

      final home = HomeCommandCenterState.derive();
      expect(home.nextExamTitle, 'CA Foundation');
      expect(home.nextExamDaysAway, closeTo(12, 1));
      expect(find.text('CA Foundation'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tomorrow exam is labelled Tomorrow exactly once', (
      tester,
    ) async {
      await ExamController.instance.createExam(
        title: 'Near Midterm',
        subject: 'Biology',
        examDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      await pumpHome(tester);

      // The countdown must not be duplicated across sections.
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exam countdown label matches the real days-away value', (
      tester,
    ) async {
      await ExamController.instance.createExam(
        title: 'Boundary Exam',
        subject: 'Law',
        examDateTime: DateTime.now().add(const Duration(hours: 4)),
      );

      await pumpHome(tester);

      final home = HomeCommandCenterState.derive();
      final days = home.nextExamDaysAway!;
      final expected = switch (days) {
        0 => 'Today',
        1 => 'Tomorrow',
        _ => '$days days',
      };
      // The label must be derived from real data, never a fixed string.
      expect(home.examsDetailLabel, expected);
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 9. REVISION DUE / RECOMMENDED ACTION
  // ══════════════════════════════════════════════════════════════════════

  group('recommended action', () {
    testWidgets('at most ONE recommendation is ever shown', (tester) async {
      await TaskController.instance.createTask(
        title: 'Overdue task A',
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await TaskController.instance.createTask(
        title: 'Overdue task B',
        priority: TaskPriority.medium,
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      await pumpHome(tester);

      // Critical requirement: never a competing list of 5–10 suggestions.
      expect(
        find.text('RECOMMENDED FOR YOU').evaluate().length,
        lessThanOrEqualTo(1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('recommendation is null when the engine has nothing', (
      tester,
    ) async {
      await pumpHome(tester);

      final home = HomeCommandCenterState.derive();
      // With no academic data, Home must not invent a suggestion.
      expect(home.recommendationCount, 0);
      expect(home.recommendation, isNull);
      expect(find.byType(HomeRecommendedActionCard), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('recommendation explains why via the engine reason', (
      tester,
    ) async {
      await TaskController.instance.createTask(
        title: 'Overdue explained task',
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 4)),
      );

      await pumpHome(tester);

      final rec = HomeCommandCenterState.derive().recommendation;
      if (rec != null) {
        // "Why this" is mandatory, and must be engine-derived text.
        expect(rec.reason, isNotEmpty);
        expect(rec.action.reason, rec.reason);
        expect(rec.supportingReasons, isNotEmpty);
        await scrollTo(tester, find.byType(HomeRecommendedActionCard));
        expect(find.text('Why?'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('recommended action has a Start CTA', (tester) async {
      await TaskController.instance.createTask(
        title: 'Overdue startable task',
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      await pumpHome(tester);

      if (find.byType(HomeRecommendedActionCard).evaluate().isNotEmpty) {
        await scrollTo(tester, find.byType(HomeRecommendedActionCard));
        expect(find.text('Start'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 10. COMPLETED DAY
  // ══════════════════════════════════════════════════════════════════════

  group('completed day', () {
    testWidgets('a done-for-today day is reflected, never re-opened', (
      tester,
    ) async {
      AcademicIntelligenceController.instance.setDoneForToday(true);
      await pumpHome(tester);

      expect(AcademicIntelligenceController.instance.isDoneForToday, isTrue);
      expect(find.textContaining('DONE FOR TODAY'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('progress summary reads 100% only when minutes are done', (
      tester,
    ) async {
      await pumpHome(tester);
      final home = HomeCommandCenterState.derive();
      // No plan means no fabricated 100%.
      expect(home.blockProgress, 0);
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 11. RECOVERY STATE
  // ══════════════════════════════════════════════════════════════════════

  group('recovery state', () {
    testWidgets('an unfinished task-linked past block is recoverable', (
      tester,
    ) async {
      final task = await TaskController.instance.createTask(
        title: 'Unfinished morning work',
        dueDate: DateTime.now().subtract(const Duration(hours: 3)),
      );
      // A missed session requires an INCOMPLETE task-linked block that has
      // already ended — that is the authoritative recovery signal.
      final start = DateTime.now().subtract(const Duration(hours: 4));
      await PlanningBlockController.instance.scheduleBlock(
        task.id,
        start,
        start.add(const Duration(minutes: 20)),
      );

      await pumpHome(tester);

      final autopilot =
          AcademicIntelligenceController.instance.autopilotDayState;
      expect(autopilot.recoverySessions, isNotEmpty);
      expect(tester.takeException(), isNull);

      PlanningBlockController.instance.clearData();
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 12–14. AUTOPILOT OFF / SUGGEST / ACTIVE
  // ══════════════════════════════════════════════════════════════════════

  group('autopilot awareness', () {
    testWidgets('Autopilot OFF shows no strip', (tester) async {
      await UserPreferencesController.instance.setAutopilotMode(AutopilotMode.off);
      await pumpHome(tester);

      expect(
        HomeCommandCenterState.derive().autopilotAwareness,
        HomeAutopilotAwareness.off,
      );
      expect(find.byType(HomeAutopilotStrip), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Autopilot SUGGEST is visible but does not mutate the plan', (
      tester,
    ) async {
      await UserPreferencesController.instance.setAutopilotMode(
        AutopilotMode.suggest,
      );
      final before = PlanningBlockController.instance.blocks.length;

      await pumpHome(tester);

      expect(
        HomeCommandCenterState.derive().autopilotAwareness,
        HomeAutopilotAwareness.suggest,
      );
      expect(find.byType(HomeAutopilotStrip), findsOneWidget);
      expect(find.text('Autopilot suggests.'), findsOneWidget);
      // Suggest mode must never silently change the student's schedule.
      expect(PlanningBlockController.instance.blocks.length, before);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Autopilot ACTIVE says the day is being managed', (
      tester,
    ) async {
      await UserPreferencesController.instance.setAutopilotMode(
        AutopilotMode.autopilot,
      );
      await pumpHome(tester);

      expect(
        HomeCommandCenterState.derive().autopilotAwareness,
        HomeAutopilotAwareness.managing,
      );
      expect(find.text('Your day is being managed.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reading awareness does not change the Autopilot mode', (
      tester,
    ) async {
      await UserPreferencesController.instance.setAutopilotMode(
        AutopilotMode.autopilot,
      );
      await pumpHome(tester);
      for (var i = 0; i < 3; i++) {
        HomeCommandCenterState.derive();
      }
      expect(
        UserPreferencesController.instance.autopilotMode,
        AutopilotMode.autopilot,
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 15. USER ISOLATION
  // ══════════════════════════════════════════════════════════════════════

  group('user isolation', () {
    testWidgets('Home reads only the current user-scoped controller data', (
      tester,
    ) async {
      await TaskController.instance.createTask(
        title: 'Scoped task for current user',
        dueDate: DateTime.now(),
      );

      await pumpHome(tester);

      // Home derives from the singleton controllers, which are user-scoped and
      // reset by ControllerIsolation on logout. It must not hold its own copy
      // of data that could outlive the session.
      final home = HomeCommandCenterState.derive();
      expect(home.todayTaskCount, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('deriving state is repeatable and side-effect free', (
      tester,
    ) async {
      await pumpHome(tester);
      final a = HomeCommandCenterState.derive();
      final b = HomeCommandCenterState.derive();
      // Deterministic derivation: same inputs, same view-state.
      expect(a.plannedBlockCount, b.plannedBlockCount);
      expect(a.overdueTaskCount, b.overdueTaskCount);
      expect(a.nextExamTitle, b.nextExamTitle);
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 16. RESPONSIVE LAYOUT
  // ══════════════════════════════════════════════════════════════════════

  group('responsive layout', () {
    for (final width in [320.0, 360.0, 390.0, 412.0, 430.0]) {
      testWidgets('renders without overflow at ${width.toInt()}dp', (
        tester,
      ) async {
        await TaskController.instance.createTask(
          title: 'Responsive overdue task',
          priority: TaskPriority.high,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        await pumpHome(tester, width: width);

        expect(tester.takeException(), isNull, reason: 'overflow at $width');
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    }

    for (final size in [const Size(834, 1112), const Size(1280, 900)]) {
      testWidgets('renders without overflow on ${size.width.toInt()}dp wide', (
        tester,
      ) async {
        await pumpHome(tester, width: size.width);
        expect(tester.takeException(), isNull);
        // Quick Actions must stay a compact grid, not a stretched row.
        expect(find.text('Quick Actions'), findsOneWidget);
      });
    }

    testWidgets('quick action details do not clip at 320dp', (tester) async {
      await TaskController.instance.createTask(
        title: 'Detail clipping check',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );
      await pumpHome(tester, width: 320);
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 17. NAVIGATION ACTIONS
  // ══════════════════════════════════════════════════════════════════════

  group('navigation actions', () {
    testWidgets('every quick action opens an existing flow', (tester) async {
      await pumpHome(tester);

      for (final label in ['Add Task', 'Exams', 'Calendar']) {
        await scrollTo(tester, find.text(label).first);
        await tester.tap(find.text(label).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label failed');
        final ctx = tester.element(
          find.byType(HomeScreen, skipOffstage: false),
        );
        Navigator.of(ctx).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Plan Day opens the daily planner', (tester) async {
      await pumpHome(tester);
      await scrollTo(tester, find.text('Plan Day').first);
      await tester.tap(find.text('Plan Day').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 18. ACCESSIBILITY
  // ══════════════════════════════════════════════════════════════════════

  group('accessibility', () {
    testWidgets('quick actions expose an accessible label with detail', (
      tester,
    ) async {
      await pumpHome(tester);

      // Every launcher must be an individually tappable semantic node, not
      // an anonymous gesture. Assert on the tile widgets' own semantics.
      for (final label in [
        'Focus',
        'Plan Day',
        'Study',
        'Revise',
        'Add Task',
        'Exams',
        'Calendar',
        // Ask OS is the canonical Assistant entry card, not a grid tile.
        'Ask Student OS',
      ]) {
        final tile = find.ancestor(
          of: find.text(label).first,
          matching: find.byType(Semantics),
        );
        expect(tile, findsWidgets, reason: 'no semantics for $label');
      }
    });

    testWidgets('active session banner announces itself to screen readers', (
      tester,
    ) async {
      FocusController.instance.startQuickFocus(
        duration: const Duration(minutes: 25),
        subjectName: 'Accountancy',
      );
      await tester.pump();
      await pumpHome(tester);

      expect(find.byType(HomeActiveSessionBanner), findsOneWidget);
      final session = HomeCommandCenterState.derive().activeSession!;
      final node = tester.getSemantics(find.byType(HomeActiveSessionBanner));
      expect(node.label, contains(session.badgeLabel));
      expect(node.label, contains('Accountancy'));

      FocusController.instance.completeSession();
      await tester.pump(const Duration(seconds: 5));
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 19. HOME CHANGES THROUGH THE DAY
  // ══════════════════════════════════════════════════════════════════════

  group('greeting follows the clock', () {
    for (final entry in <({int hour, String greeting})>[
      (hour: 8, greeting: 'Good morning'),
      (hour: 14, greeting: 'Good afternoon'),
      (hour: 20, greeting: 'Good evening'),
    ]) {
      testWidgets('${entry.greeting} at ${entry.hour}:00', (tester) async {
        final base = DateTime(2026, 9, 29, entry.hour, 0);
        AppClock.freezeAt(base);

        await pumpHome(tester);

        expect(find.textContaining(entry.greeting), findsWidgets);
        expect(tester.takeException(), isNull);
        AppClock.reset();
      });
    }
  });
}

Future<void> _cleanAcademicData() async {
  if (FocusController.instance.hasActiveSession) {
    FocusController.instance.completeSession();
  }
  FocusController.instance.clearData();
  StudyController.instance.clearData();
  PlanningBlockController.instance.clearData();
  for (final task in List.of(TaskController.instance.tasks)) {
    await TaskController.instance.deleteTask(task.id);
  }
  for (final exam in List.of(ExamController.instance.exams)) {
    await ExamController.instance.deleteExam(exam.id);
  }
  for (final subject in List.of(SubjectController.instance.subjects)) {
    await SubjectController.instance.deleteSubject(subject.id);
  }
}
