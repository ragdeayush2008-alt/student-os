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
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_home_ui_user');
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
  });

  tearDown(() {
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    DailyOsCoordinator.instance.clearOnLogout();
    AuthIsolation.instance.clearSession();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
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

  group('Home Screen Simplified Hierarchy & UI Tests', () {
    testWidgets('renders primary Student OS action card, compact Today card with View Plan, and Quick Actions', (tester) async {
      await tester.pumpWidget(wrapWithApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('WHAT SHOULD I DO NOW?'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('View Plan'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Add Task'), findsWidgets);
      expect(find.text('Study'), findsWidgets);
      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Exams'), findsWidgets);
      expect(find.text('Plan Day'), findsWidgets);
      expect(find.text('Revise'), findsWidgets);
      expect(find.text('Ask Student OS'), findsWidgets);
    });

    testWidgets('Home screen renders without RenderFlex overflow in narrow 320dp width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          routes: AppRouter.routes(),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 700)),
            child: AppScope(
              controller: AppShellController(),
              child: AuthScope(
                authService: AuthService.instance,
                child: const Scaffold(body: HomeScreen()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('WHAT SHOULD I DO NOW?'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });
  });
}
