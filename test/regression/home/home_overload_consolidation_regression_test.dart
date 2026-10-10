import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/today_plan_engine.dart';
import 'package:student_os/core/intelligence/daily_os_coordinator.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
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
    AuthIsolation.instance.setAuthenticatedUser('test_home_overload_user');
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    PlanningBlockController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
  });

  tearDown(() {
    AcademicIntelligenceController.instance
        .setTimeBudget(AvailableTimeBudget.oneHour);
    if (FocusController.instance.hasActiveSession) {
      FocusController.instance.cancelSession();
    }
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    PlanningBlockController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
    AuthIsolation.instance.clearSession();
  });

  group('Home Screen Overload UI Consolidation Regression Tests', () {
    testWidgets('Overloaded day renders exactly ONE overload card and exactly ONE Rebalance CTA', (tester) async {
      final sub = await SubjectController.instance.createSubject(name: 'Direct Taxation');

      // 45m planned vs 30m budget, starting imminently: overloaded with no
      // missed sessions (missed sessions take health priority instead).
      AcademicIntelligenceController.instance
          .setTimeBudget(AvailableTimeBudget.thirtyMinutes);
      final now = DateTime.now();
      final start = now.hour == 23 && now.minute >= 50
          ? DateTime(now.year, now.month, now.day, 23, 50)
          : now.add(const Duration(minutes: 2));
      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        start,
        start.add(const Duration(minutes: 45)),
      );

      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      // Check for exactly ONE OVERLOADED badge
      expect(find.text('OVERLOADED'), findsOneWidget);

      // Check for exactly ONE Rebalance button
      expect(find.text('Rebalance'), findsOneWidget);

      // Verify no duplicate "Today exceeds your time budget" card exists
      expect(find.textContaining('exceeds your time budget'), findsNothing);
    });

    testWidgets('Non-overloaded day does not display overload card or Rebalance CTA', (tester) async {
      final sub = await SubjectController.instance.createSubject(name: 'Financial Accounting');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Schedule 60 min (well within 180 min budget)
      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        DateTime(today.year, today.month, today.day, 23, 0),
        DateTime(today.year, today.month, today.day, 23, 50),
      );

      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('OVERLOADED'), findsNothing);
      expect(find.text('Rebalance'), findsNothing);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('Missed sessions on overloaded day show compact recovery without second overload card', (tester) async {
      final sub = await SubjectController.instance.createSubject(name: 'Costing');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Past block (missed session)
      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        DateTime(today.year, today.month, today.day, 6, 0),
        DateTime(today.year, today.month, today.day, 7, 0),
        customTitle: 'Morning Revision',
      );

      // Future long block (overloading the day: 240 min)
      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        DateTime(today.year, today.month, today.day, 14, 0),
        DateTime(today.year, today.month, today.day, 18, 0),
        customTitle: 'Afternoon Study',
      );

      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      // Exactly one Rebalance action
      expect(find.text('Rebalance'), findsOneWidget);
      // No duplicate overload cards
      expect(find.textContaining('exceeds your time budget'), findsNothing);
    });

    testWidgets('Start My Day CTA remains intact and functional', (tester) async {
      final sub = await SubjectController.instance.createSubject(name: 'Business Law');

      // Near-term block: UPCOMING today at (almost) any hour.
      final now = DateTime.now();
      final start = now.hour == 23 && now.minute >= 50
          ? DateTime(now.year, now.month, now.day, 23, 50)
          : now.add(const Duration(minutes: 2));
      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        start,
        start.add(const Duration(minutes: 20)),
        customTitle: 'Law Reading',
      );

      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('START MY DAY'), findsOneWidget);
      expect(find.text('Start My Day'), findsOneWidget);
    });
  });
}
