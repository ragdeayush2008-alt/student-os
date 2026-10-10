import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
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

Widget _buildTestApp(Widget child, {required Size size}) {
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
    AuthIsolation.instance.setAuthenticatedUser('test_home2_responsive');
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    PlanningBlockController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
  });

  tearDown(() {
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

  group('Home 2.0 responsive layouts (CODE 5)', () {
    const sizes = [
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(412, 915),
      Size(430, 932),
    ];

    for (final size in sizes) {
      testWidgets(
          'renders without overflow at ${size.width.toInt()}dp with data',
          (tester) async {
        final sub = await SubjectController.instance.createSubject(
          name:
              'A Very Long Subject Name That Should Ellipsize Gracefully Without Overflow Issues Whatsoever',
        );
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        await PlanningBlockController.instance.scheduleSubjectBlock(
          sub.id,
          DateTime(today.year, today.month, today.day, 14, 0),
          DateTime(today.year, today.month, today.day, 15, 0),
          customTitle:
              'An Extremely Long Planning Block Title Designed To Test Ellipsization Behavior Across Widths',
        );
        await TaskController.instance.createTask(
          title:
              'An Exceptionally Long Task Title That Must Not Cause RenderFlex Overflow On Narrow Devices',
        );

        await tester.pumpWidget(
          _buildTestApp(const HomeScreen(), size: size),
        );
        await tester.pumpAndSettle();

        // No overflow errors surfaced as exceptions.
        expect(tester.takeException(), isNull);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Quick Actions'), findsOneWidget);
      });

      testWidgets('empty state renders at ${size.width.toInt()}dp', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(const HomeScreen(), size: size),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text("Let's build your day."), findsOneWidget);
      });
    }

    testWidgets('many blocks list scrolls without overflow at 320dp',
        (tester) async {
      final sub =
          await SubjectController.instance.createSubject(name: 'Maths');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (var i = 0; i < 8; i++) {
        final start = DateTime(today.year, today.month, today.day, 8 + i, 0);
        await PlanningBlockController.instance.scheduleSubjectBlock(
          sub.id,
          start,
          start.add(const Duration(minutes: 45)),
          customTitle: 'Block $i — Algebra Practice Session',
        );
      }

      await tester.pumpWidget(
        _buildTestApp(const HomeScreen(), size: const Size(320, 568)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Today's Plan"), findsOneWidget);
    });
  });
}
