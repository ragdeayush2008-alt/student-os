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
    AuthIsolation.instance.setAuthenticatedUser('test_home2_nodup');
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
    FocusController.instance.clearData();
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    PlanningBlockController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
    AuthIsolation.instance.clearSession();
  });

  group('Home 2.0 single-surface regression (CODE 5)', () {
    testWidgets('overloaded day: exactly ONE overload badge + ONE Rebalance',
        (tester) async {
      final sub =
          await SubjectController.instance.createSubject(name: 'Taxation');
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

      expect(find.text('OVERLOADED'), findsOneWidget);
      expect(find.text('Rebalance'), findsOneWidget);
      // Authoritative Today card appears once.
      expect(find.text('Today'), findsOneWidget);
      // Single authoritative plan list.
      expect(find.text("Today's Plan"), findsOneWidget);
      // No duplicated budget-exceeded explainer cards.
      expect(find.textContaining('exceeds your time budget'), findsNothing);
    });

    testWidgets('single primary recommendation surface', (tester) async {
      final sub =
          await SubjectController.instance.createSubject(name: 'Law');
      // Near-term block: UPCOMING today at (almost) any hour.
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

      // Hero badge appears once (start or continue).
      final startBadges = find.text('START MY DAY');
      final continueBadges = find.text('CONTINUE MY DAY');
      expect(
        startBadges.evaluate().length + continueBadges.evaluate().length,
        equals(1),
      );
      // WHY affordance appears once for the single recommendation.
      expect(find.text('Why?'), findsOneWidget);
    });

    testWidgets('empty day: no overload, no plan list, guided empty state',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('OVERLOADED'), findsNothing);
      expect(find.text('Rebalance'), findsNothing);
      expect(find.text("Today's Plan"), findsNothing);
      expect(find.text("Let's build your day."), findsOneWidget);
    });
  });
}
