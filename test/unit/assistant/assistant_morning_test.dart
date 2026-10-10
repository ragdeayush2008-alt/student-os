import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/daily_assistant_controller.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P3 — morning briefing: honest empty state, one staged proposal per day,
/// sleep shown, prepared flag recorded.
void main() {
  const engine = StudentAssistantEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    DailyAssistantController.instance.clearData();
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
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    DailyAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  Future<void> login(String user) async {
    AuthIsolation.instance.setAuthenticatedUser(user);
    await SleepController.instance.load();
    await DailyAssistantController.instance.load();
  }

  group('morning context', () {
    test('parser routes briefing phrasings', () {
      for (final q in [
        'morning briefing',
        'brief me',
        'prepare my day',
        'daily briefing',
      ]) {
        expect(
          engine.process(q).intent.intentType,
          AssistantIntentType.morningBriefing,
          reason: q,
        );
      }
    });
  });

  group('morning briefing', () {
    test('no work → honest empty, never invented', () async {
      await login('p3_morn_empty');
      final result = engine.process('morning briefing');
      expect(result.success, isTrue);
      expect(result.proposal, isNull);
      expect(result.message, contains("isn't planned yet"));
    });

    test('work → proposal staged once, prepared recorded', () async {
      await login('p3_morn_work');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      await TaskController.instance.createTask(
        title: 'Accounts Chapter 3',
        priority: TaskPriority.high,
        estimatedMinutes: 40,
      );

      final controller = StudentAssistantController.instance;
      final result = await controller.ask('prepare my day');
      expect(result.requiresConfirmation, isTrue);
      expect(controller.hasPendingProposal, isTrue);
      expect(DailyAssistantController.instance.state.prepared, isTrue);
      expect(
        DailyAssistantController.instance.state.sleepFingerprint,
        '11 PM → 7 AM',
      );

      // A repeat briefing reports status instead of stacking proposals.
      final again = await controller.ask('morning briefing');
      expect(again.title, 'Day Already Prepared');
      expect(again.proposal, isNull);
      expect(
        DailyAssistantController.instance.state.planVersion,
        1,
      );
    });

    test('briefing mentions sleep window when set', () async {
      await login('p3_morn_sleep');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      await TaskController.instance.createTask(title: 'Solo task');
      final result = engine.process('morning briefing');
      expect(
        result.contextLine ?? '',
        contains('11 PM'),
      );
    });
  });
}
