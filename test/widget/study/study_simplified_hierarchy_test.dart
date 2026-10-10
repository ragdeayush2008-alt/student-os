import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/study/study_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_study_ui_user');
    StudyController.instance.clearData();
    TaskController.instance.clearData();
    FocusController.instance.clearData();
    ExamController.instance.clearData();
    SubjectController.instance.clearData();
  });

  tearDown(() {
    StudyController.instance.clearData();
    TaskController.instance.clearData();
    FocusController.instance.clearData();
    ExamController.instance.clearData();
    SubjectController.instance.clearData();
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

  group('Study Screen Simplified Hierarchy & UI Tests', () {
    testWidgets('renders Study tab switcher and recommendations', (tester) async {
      await tester.pumpWidget(wrapWithApp(const StudyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('What Should I Study?'), findsOneWidget);
      expect(find.text('My Subjects'), findsOneWidget);
    });

    testWidgets('Study tab builds without overflow at 320dp width', (tester) async {
      // Create a subject to ensure a study recommendation is generated
      await SubjectController.instance.createSubject(
        name: 'Audit & Assurance',
      );

      // Narrow screen width (320dp) to test responsiveness
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
                child: const Scaffold(body: StudyScreen()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
    });
  });
}
