import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/daily_assistant_controller.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P3 isolation — daily state, preferences, triggers, and activity log are
/// strictly per-user through the real session-change path.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
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
    ControllerIsolation.instance.clearAllControllers();
  });

  test('daily loop state never leaks across users', () async {
    final daily = DailyAssistantController.instance;
    final assistant = StudentAssistantController.instance;

    // User A: briefing prepared, trigger dismissed, activity logged.
    AuthIsolation.instance.setAuthenticatedUser('p3_iso_a');
    ControllerIsolation.instance.reloadAllControllers('p3_iso_a');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await SleepController.instance.saveSchedule(
      const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
    );
    await TaskController.instance.createTask(
      title: 'A task',
      priority: TaskPriority.high,
    );
    await assistant.ask('prepare my day');
    expect(daily.state.prepared, isTrue);
    await daily.dismissTrigger('2099-01-01:fixDay');
    await daily.logAction('Confirmed test action');
    expect(daily.state.actionLog, isNotEmpty);

    // Logout → B: defaults everywhere, nothing of A's.
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.setAuthenticatedUser('p3_iso_b');
    ControllerIsolation.instance.reloadAllControllers('p3_iso_b');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(daily.state.prepared, isFalse);
    expect(daily.state.actionLog, isEmpty);
    expect(daily.state.dismissedTriggerIds, isEmpty);
    expect(daily.preferences.proactiveEnabled, isTrue);
    expect(daily.buildTriggers(), isEmpty);
    expect(SleepController.instance.hasSchedule, isFalse);
    expect(
      TaskController.instance.tasks.where((t) => t.title == 'A task'),
      isEmpty,
    );

    // B changes a preference: A's defaults must survive.
    await daily.updatePreferences(
      daily.preferences.copyWith(proactiveEnabled: false),
    );

    // Back to A: preparation, log, and sleep all restore.
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.setAuthenticatedUser('p3_iso_a');
    ControllerIsolation.instance.reloadAllControllers('p3_iso_a');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(daily.state.prepared, isTrue);
    expect(daily.state.actionLog, isNotEmpty);
    expect(daily.preferences.proactiveEnabled, isTrue);
    expect(SleepController.instance.hasSchedule, isTrue);
    expect(
      TaskController.instance.tasks.where((t) => t.title == 'A task'),
      isNotEmpty,
    );
  });
}
