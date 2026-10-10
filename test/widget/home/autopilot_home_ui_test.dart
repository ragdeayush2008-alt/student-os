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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_autopilot_home_user');
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

  Widget wrapWithApp(Widget child, {Size size = const Size(390, 844)}) {
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

  group('Autopilot 2.0 Home UI & Responsiveness Tests', () {
    testWidgets('1. Renders START MY DAY on fresh day with planned block', (tester) async {
      final sub = await SubjectController.instance.createSubject(name: 'Audit & Assurance');
      // Near-term block: UPCOMING today at (almost) any hour.
      final now = DateTime.now();
      final start = now.hour == 23 && now.minute >= 50
          ? DateTime(now.year, now.month, now.day, 23, 50)
          : now.add(const Duration(minutes: 2));

      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        start,
        start.add(const Duration(minutes: 45)),
        customTitle: 'Audit & Assurance',
      );

      await tester.pumpWidget(wrapWithApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('START MY DAY'), findsOneWidget);
      expect(find.text('Start My Day'), findsOneWidget);
      expect(find.text('ON TRACK'), findsOneWidget);
    });

    testWidgets('2. Renders FOCUS ACTIVE when a focus session is in progress', (tester) async {
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 30),
        objective: 'Active Study Session',
      );

      await tester.pumpWidget(wrapWithApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('FOCUS ACTIVE'), findsOneWidget);
      expect(find.text('Continue Focus'), findsOneWidget);

      FocusController.instance.cancelSession();
      FocusController.instance.clearData();
    });

    testWidgets('3. Renders OVERLOADED badge and Rebalance CTA when planned minutes exceed budget', (tester) async {
      final sub = await SubjectController.instance.createSubject(name: 'Direct Tax');

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

      await tester.pumpWidget(wrapWithApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('OVERLOADED'), findsOneWidget);
      expect(find.text('Rebalance'), findsWidgets);
    });

    testWidgets('4. Responsive layout safety across 320dp, 360dp, 390dp, 412dp, 430dp widths', (tester) async {
      const testWidths = [320.0, 360.0, 390.0, 412.0, 430.0];

      for (final width in testWidths) {
        await tester.pumpWidget(wrapWithApp(const HomeScreen(), size: Size(width, 750)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Quick Actions'), findsOneWidget);
      }
    });
  });
}
