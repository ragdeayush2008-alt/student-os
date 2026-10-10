import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_states.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/home/home_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Home must never render blank or crash, even with empty/failed derivations:
/// logged-out + empty controllers still produce the honest empty state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    await AuthService.instance.signOut();
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
  });

  tearDown(() async {
    AuthIsolation.instance.clearSession();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: AppScope(
        controller: AppShellController(),
        child: AuthScope(
          authService: AuthService.instance,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets('logged-out empty Home renders empty state, never blank/error',
      (tester) async {
    await tester.pumpWidget(wrapWithApp(const HomeScreen()));
    await tester.pumpAndSettle();

    // Honest empty state is shown…
    expect(find.text("Let's build your day."), findsOneWidget);
    // …and never the error state, and never an empty screen.
    expect(find.byType(AppErrorState), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
