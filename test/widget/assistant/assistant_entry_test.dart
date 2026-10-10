import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/assistant/assistant_launch_context.dart';
import 'package:student_os/core/assistant/presentation/assistant_command_center_screen.dart';

import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';

/// Entry unification: every canonical entry opens the SAME Assistant
/// surface (command center) with the right context.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('entry_user');
    StudentAssistantController.instance.clearData();
  });

  tearDown(() async {
    await StudentAssistantController.instance.clearConversation();
    StudentAssistantController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  Widget host(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      navigatorKey: AppRouter.navigatorKey,
      routes: AppRouter.routes(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('assistant entry sets sleep context and shows the canonical surface',
      (tester) async {
    await tester.pumpWidget(host(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => AppRouter.openAssistant(
            context,
            launchContext: const AssistantLaunchContext(
              origin: AssistantOrigin.sleep,
            ),
          ),
          child: const Text('ask'),
        ),
      ),
    ));
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();

    expect(
      StudentAssistantController.instance.launchContext.origin,
      AssistantOrigin.sleep,
    );
    expect(find.byType(AssistantCommandCenterScreen), findsOneWidget);
  });

  testWidgets('command-center entry sets exam context with entity',
      (tester) async {
    await tester.pumpWidget(host(
      Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              AppRouter.openAssistantCommandCenter(
            context,
            launchContext: const AssistantLaunchContext(
              origin: AssistantOrigin.exam,
              examId: 'e1',
              examTitle: 'CA Foundation',
            ),
          ),
          child: const Text('ask'),
        ),
      ),
    ));
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();

    final ctx = StudentAssistantController.instance.launchContext;
    expect(ctx.origin, AssistantOrigin.exam);
    expect(ctx.examTitle, 'CA Foundation');
    expect(ctx.contextLine, 'Looking at CA Foundation');
    expect(find.byType(AssistantCommandCenterScreen), findsOneWidget);
  });

  testWidgets('every entry opens the same canonical surface', (tester) async {
    for (final origin in [
      AssistantOrigin.home,
      AssistantOrigin.planning,
      AssistantOrigin.tools,
      AssistantOrigin.workspace,
      AssistantOrigin.sleep,
      AssistantOrigin.sprintx,
    ]) {
      StudentAssistantController.instance.clearData();
      await tester.pumpWidget(host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppRouter.openAssistant(
              context,
              launchContext: AssistantLaunchContext(origin: origin),
            ),
            child: const Text('ask'),
          ),
        ),
      ));
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();

      expect(
        StudentAssistantController.instance.launchContext.origin,
        origin,
      );
      expect(find.byType(AssistantCommandCenterScreen), findsOneWidget,
          reason: 'origin $origin did not open the canonical surface');
      // Same header, same catalog access, same input on every entry.
      expect(find.text('Assistant'), findsWidgets);
      expect(find.text('Explore questions'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      Navigator.of(tester.element(find.byType(AssistantCommandCenterScreen)))
          .pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('global context has no context line', (tester) async {
    expect(
      AssistantLaunchContext.global.contextLine,
      isNull,
    );
    expect(
      const AssistantLaunchContext(
        origin: AssistantOrigin.subject,
        subjectName: 'Accounting',
      ).contextLine,
      'Looking at Accounting',
    );
  });

  testWidgets('context clears on logout (user isolation)', (tester) async {
    StudentAssistantController.instance.setLaunchContext(
      const AssistantLaunchContext(origin: AssistantOrigin.sleep),
    );
    expect(
      StudentAssistantController.instance.launchContext.origin,
      AssistantOrigin.sleep,
    );
    StudentAssistantController.instance.clearData();
    expect(
      StudentAssistantController.instance.launchContext.isGlobal,
      isTrue,
    );
  });
}
