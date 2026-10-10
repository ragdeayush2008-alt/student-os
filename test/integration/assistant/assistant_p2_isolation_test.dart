import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P2 isolation — User A acts through the Assistant (task + sleep + applied
/// plan); User B sees and touches nothing of A's; A's data restores fully.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final b in List.of(PlanningBlockController.instance.blocks)) {
      await PlanningBlockController.instance.unscheduleBlock(b.id);
    }
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final b in List.of(PlanningBlockController.instance.blocks)) {
      await PlanningBlockController.instance.unscheduleBlock(b.id);
    }
    await SleepController.instance.clearSchedule();
    await StudentAssistantController.instance.clearConversation();
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  test('assistant actions stay inside the acting user', () async {
    final controller = StudentAssistantController.instance;

    // User A: sleep window + assistant-created task + chat history.
    AuthIsolation.instance.setAuthenticatedUser('p2_iso_a');
    await SleepController.instance.load();
    await SleepController.instance.saveSchedule(
      const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
    );
    await TaskController.instance.load();
    await controller.ask('Create a task to finish Accounts Chapter 3');
    await controller.confirmAction(_NoContext());
    await controller.ask('What should I do now?');

    expect(
      TaskController.instance.tasks
          .where((t) => t.title.contains('Accounts')),
      isNotEmpty,
    );
    expect(SleepController.instance.hasSchedule, isTrue);
    expect(controller.messages, isNotEmpty);

    // Logout through the real session-change path: memory drops everywhere.
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();

    // User B: nothing of A's is visible or reachable.
    AuthIsolation.instance.setAuthenticatedUser('p2_iso_b');
    ControllerIsolation.instance.reloadAllControllers('p2_iso_b');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(SleepController.instance.hasSchedule, isFalse);
    expect(
      TaskController.instance.tasks
          .where((t) => t.title.contains('Accounts')),
      isEmpty,
    );
    expect(controller.messages, isEmpty);

    // B creates their own data.
    await TaskController.instance.createTask(title: 'B task');

    // Back to A: only A's world restores.
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.setAuthenticatedUser('p2_iso_a');
    ControllerIsolation.instance.reloadAllControllers('p2_iso_a');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(SleepController.instance.hasSchedule, isTrue);
    expect(
      SleepController.instance.schedule!.bedtimeMinutes,
      1380,
    );
    expect(
      TaskController.instance.tasks
          .where((t) => t.title.contains('Accounts')),
      isNotEmpty,
    );
    expect(
      TaskController.instance.tasks.where((t) => t.title == 'B task'),
      isEmpty,
    );
    expect(controller.messages, isNotEmpty);
  });
}

// confirmAction for task creation does not navigate (no context use beyond
// a mounted check), so a Fake satisfies the signature.
class _NoContext extends Fake implements BuildContext {
  @override
  bool get mounted => true;
}
