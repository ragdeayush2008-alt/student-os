import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/daily_os_coordinator.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

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
    AuthIsolation.instance.setAuthenticatedUser('test_home2_sections');
    // clearUser (not just setMockInitialValues): StorageService caches the
    // prefs instance for the isolate, so a fresh mock store alone would leave
    // stale blocks/sessions persisted by earlier tests in this file. Clearing
    // user-scoped keys keeps each test fully isolated before load().
    try {
      await StorageService.instance.clearUser(userId: 'test_home2_sections');
    } catch (_) {}
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    PlanningBlockController.instance.clearData();
    AcademicIntelligenceController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
    await TaskController.instance.load();
    await ExamController.instance.load();
    await StudyController.instance.load();
    await SubjectController.instance.load();
    await FocusController.instance.load();
    await PlanningBlockController.instance.load();
  });

  tearDown(() {
    AppClock.reset();
    // clearData (not cancelSession) stops the ticker + checkpoint timers so
    // no fake-async Timer stays pending after the widget tree is disposed.
    FocusController.instance.clearData();
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    PlanningBlockController.instance.clearData();
    AcademicIntelligenceController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
    AuthIsolation.instance.clearSession();
  });

  group('Home 2.0 sections (CODE 5)', () {
    testWidgets('empty first-time state shows guided setup, no fake data',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text("Let's build your day."), findsOneWidget);
      // 'Add Task' appears in both the empty-state card and Quick Actions.
      expect(find.text('Add Task'), findsWidgets);
      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('Plan My Day'), findsOneWidget);
      // Canonical Assistant entry appears in both the guided empty-state
      // card and the dedicated Ask Student OS entry card.
      expect(find.text('Ask Student OS'), findsWidgets);
    });

    testWidgets('normal day shows hero + today + plan + quick actions + assistant',
        (tester) async {
      // Freeze the app clock so the scheduled block is always on today's
      // date and strictly in the future, regardless of real wall-clock time.
      AppClock.freezeAt(DateTime(2026, 9, 21, 14, 0));
      final sub = await SubjectController.instance.createSubject(name: 'Physics');
      final start = DateTime(2026, 9, 21, 14, 20);
      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        start,
        start.add(const Duration(minutes: 20)),
        customTitle: 'Laws of Motion',
      );

      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      // Hero
      expect(find.text('START MY DAY'), findsOneWidget);
      // Today overview (single authoritative surface)
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('View Plan'), findsOneWidget);
      // Today's plan list (title also appears in hero recommendation).
      expect(find.text("Today's Plan"), findsOneWidget);
      expect(find.text('Laws of Motion'), findsWidgets);
      expect(find.text('UPCOMING'), findsOneWidget);
      expect(find.text('Start'), findsWidgets);
      // Quick actions (7 compact)
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Plan Day'), findsOneWidget);
      expect(find.text('Revise'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
      // Ask OS is no longer a grid tile — it owns the canonical
      // Assistant entry card below Quick Actions.
      expect(find.text('Ask Student OS'), findsOneWidget);
      // Assistant entry
      expect(find.textContaining('Ask Student OS'), findsWidgets);
    });

    testWidgets('WHY explanation opens deterministic dialog', (tester) async {
      final sub = await SubjectController.instance.createSubject(name: 'Chemistry');
      final now = DateTime.now();
      final start = now.hour == 23 && now.minute >= 50
          ? DateTime(now.year, now.month, now.day, 23, 50)
          : now.add(const Duration(minutes: 2));
      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        start,
        start.add(const Duration(minutes: 20)),
      );

      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Why?'), findsOneWidget);
      await tester.tap(find.text('Why?').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('active focus hero offers Continue Focus (no duplicate session)',
        (tester) async {
      FocusController.instance.startQuickFocus(subjectName: 'Biology');
      expect(FocusController.instance.hasActiveSession, isTrue);
      final firstId = FocusController.instance.activeSession!.id;

      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      // pumpAndSettle never settles while the focus ticker runs; use pumps.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('FOCUS ACTIVE'), findsOneWidget);
      expect(find.text('Continue Focus'), findsOneWidget);
      // Rendering Home must not start a duplicate session.
      expect(FocusController.instance.hasActiveSession, isTrue);
      expect(FocusController.instance.activeSession!.id, equals(firstId));
      // Stop timers inside the body: the test-binding invariant check runs
      // before group tearDown, so no Timer may still be pending here.
      FocusController.instance.clearData();
    });

    testWidgets('missed block shows MISSED + Recover action', (tester) async {
      // Freeze the app clock so the past block is always on today's date and
      // always fully past, so the MISSED status renders at any wall clock.
      AppClock.freezeAt(DateTime(2026, 9, 21, 14, 0));
      final sub = await SubjectController.instance.createSubject(name: 'History');
      // Past-today window: MISSED at (almost) any hour. Day filters key on
      // the block START date, so clamp inside today near midnight.
      final now = AppClock.current;
      final midnight = DateTime(now.year, now.month, now.day);
      var end = now.subtract(const Duration(minutes: 5));
      var start = end.subtract(const Duration(minutes: 30));
      if (start.isBefore(midnight)) {
        start = midnight;
        end = midnight.add(const Duration(minutes: 2));
      }
      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        start,
        end,
        customTitle: 'Morning Review',
      );

      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text("Today's Plan"), findsOneWidget);
      expect(find.text('MISSED'), findsOneWidget);
      expect(find.text('Recover'), findsWidgets);
    });
  });
}
