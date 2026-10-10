import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';

/// P1 — safe-action architecture end to end: proposing a sleep window
/// stages (never writes), Confirm applies it, Cancel leaves nothing.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  tearDown(() async {
    await SleepController.instance.clearSchedule();
    await StudentAssistantController.instance.clearConversation();
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  testWidgets('propose → confirm writes the schedule', (tester) async {
    AuthIsolation.instance.setAuthenticatedUser('p1_action_user');
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('host'))),
    );
    final context = tester.element(find.text('host'));

    final controller = StudentAssistantController.instance;
    final result = await controller.ask('set sleep 11pm to 7am');
    expect(result.requiresConfirmation, isTrue);
    expect(controller.isAwaitingConfirmation, isTrue);
    expect(SleepController.instance.hasSchedule, isFalse);

    await controller.confirmAction(context);
    expect(controller.isAwaitingConfirmation, isFalse);
    expect(SleepController.instance.hasSchedule, isTrue);
    final schedule = SleepController.instance.schedule!;
    expect(schedule.bedtimeMinutes, 1380);
    expect(schedule.wakeMinutes, 420);
    expect(schedule.plannedMinutes, 480);
  });

  testWidgets('propose → cancel writes nothing', (tester) async {
    AuthIsolation.instance.setAuthenticatedUser('p1_action_user');
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('host'))),
    );

    final controller = StudentAssistantController.instance;
    await controller.ask('set sleep 11pm to 7am');
    expect(controller.isAwaitingConfirmation, isTrue);

    controller.cancelConfirmation();
    expect(controller.isAwaitingConfirmation, isFalse);
    expect(SleepController.instance.hasSchedule, isFalse);
  });
}
