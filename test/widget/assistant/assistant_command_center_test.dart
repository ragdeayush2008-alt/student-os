import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/presentation/assistant_command_center_screen.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';

/// P1 — Assistant Command Center: header, quick actions, sleep context,
/// conversation empty state, input; responsive at 360/390dp.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  tearDown(() async {
    await StudentAssistantController.instance.clearConversation();
    await SleepController.instance.clearSchedule();
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
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

  testWidgets('renders header, actions, sleep, conversation, input', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Assistant'), findsWidgets);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Plan my day'), findsOneWidget);
    expect(find.text('What should I study?'), findsOneWidget);
    expect(find.text("What's urgent?"), findsOneWidget);
    expect(find.text("I'm behind"), findsOneWidget);
    expect(find.text('Fix my day'), findsOneWidget);
    expect(find.text('Prepare for exam'), findsOneWidget);
    expect(find.text('Set sleep schedule'), findsOneWidget);
    expect(find.text('What should I do now?'), findsOneWidget);
    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('Sleep Schedule'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('no overflow at 360dp and 390dp', (tester) async {
    for (final width in [360.0, 390.0]) {
      await tester.pumpWidget(wrap(width: width));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('flagship hero renders orb, greeting and prompt', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('How can Student OS\nhelp you today?'), findsOneWidget);
    expect(
      find.text('Plans, study, exams, sleep — ask anything.'),
      findsOneWidget,
    );
    // Orb icon at the hero focal point.
    expect(find.byIcon(Icons.auto_awesome_rounded), findsWidgets);
    // No legacy flat header.
    expect(find.textContaining('👋'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
