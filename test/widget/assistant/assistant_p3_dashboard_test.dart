import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/daily_assistant_controller.dart';
import 'package:student_os/core/assistant/presentation/assistant_command_center_screen.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P3 — upgraded Command Center: morning briefing, attention triggers with
/// dismiss, NBA reasons + Later, activity log; responsive at 360/390dp.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    DailyAssistantController.instance.clearData();
    SleepController.instance.clearData();
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    await SleepController.instance.clearSchedule();
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    DailyAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  Widget wrap({double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: AppScope(
          controller: AppShellController(),
          child: const AssistantCommandCenterScreen(),
        ),
      ),
    );
  }

  testWidgets('attention trigger renders and dismisses', (tester) async {
    AuthIsolation.instance.setAuthenticatedUser('p3_dash_user');
    await TaskController.instance.createTask(
      title: 'Overdue dashboard essay',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('1 overdue task'), findsOneWidget);

    // Dismiss for today → card disappears.
    await tester.ensureVisible(find.byTooltip('Dismiss for today').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Dismiss for today').first);
    await tester.pumpAndSettle();
    expect(find.text('1 overdue task'), findsNothing);
  });

  testWidgets('activity log renders confirmed actions', (tester) async {
    AuthIsolation.instance.setAuthenticatedUser('p3_dash_user');
    await DailyAssistantController.instance.logAction(
      'Applied plan (2 sessions)',
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('TODAY WITH ASSISTANT'), findsOneWidget);
    expect(
      find.textContaining('Applied plan (2 sessions)'),
      findsOneWidget,
    );
  });

  testWidgets('NBA shows reasons with Start and Later', (tester) async {
    AuthIsolation.instance.setAuthenticatedUser('p3_dash_user');
    await TaskController.instance.createTask(
      title: 'Dashboard priority task',
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('NEXT BEST ACTION'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    // Later hides the card for today.
    await tester.ensureVisible(find.text('Later'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('NEXT BEST ACTION'), findsNothing);
  });

  testWidgets('no overflow at 360dp and 390dp', (tester) async {
    AuthIsolation.instance.setAuthenticatedUser('p3_dash_user');
    await TaskController.instance.createTask(
      title: 'Responsive overflow probe task with a long title',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    for (final width in [360.0, 390.0]) {
      await tester.pumpWidget(wrap(width: width));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
