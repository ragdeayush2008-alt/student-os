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
import 'package:student_os/features/exams/widgets/exam_creation_sheet.dart';
import 'package:student_os/features/exams/widgets/exam_detail_screen.dart';
import 'package:student_os/features/home/home_screen.dart';

/// Home exam integration: upcoming tile with countdown, empty-state
/// add-exam entry opening the real creation sheet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp() {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: const Scaffold(body: HomeScreen()),
          ),
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
  });

  tearDown(() async {
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
    AuthIsolation.instance.clearSession();
  });

  testWidgets('no exams shows add-exam entry opening the sheet', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Add your next exam'), findsOneWidget);

    await tester.ensureVisible(find.text('Add your next exam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add your next exam'));
    await tester.pumpAndSettle();

    expect(find.byType(ExamCreationSheet), findsOneWidget);
  });

  testWidgets('upcoming exam shows countdown and opens detail', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exam = await ExamController.instance.createExam(
      title: 'Accounts Final',
      subject: 'Accounts',
      examDateTime: today.add(const Duration(days: 9)),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Accounts Final'), findsOneWidget);
    expect(find.text('Add your next exam'), findsNothing);

    await tester.ensureVisible(find.text('Accounts Final'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accounts Final'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (w) => w is ExamDetailScreen && w.examId == exam.id,
      ),
      findsOneWidget,
    );
  });
}
