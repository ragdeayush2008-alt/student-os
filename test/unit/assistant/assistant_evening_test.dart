import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/daily_assistant_controller.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P3 — evening review + tomorrow preparation: real completions, honest
/// empties, wake-anchored proposals, reviewed flag.
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

  group('parser routing', () {
    test('evening + tomorrow phrasings route', () {
      expect(
        engine.process('evening review').intent.intentType,
        AssistantIntentType.eveningReview,
      );
      expect(
        engine.process('review my day').intent.intentType,
        AssistantIntentType.eveningReview,
      );
      expect(
        engine.process('prepare tomorrow').intent.intentType,
        AssistantIntentType.prepareTomorrow,
      );
      expect(
        engine.process('plan tomorrow').intent.intentType,
        AssistantIntentType.prepareTomorrow,
      );
    });
  });

  group('evening review', () {
    test('quiet day → "Nothing to review yet."', () async {
      await login('p3_eve_empty');
      final result = engine.process('evening review');
      expect(result.success, isTrue);
      expect(result.message, 'Nothing to review yet.');
    });

    test('completions + focus surface with counts', () async {
      await login('p3_eve_full');
      final done = await TaskController.instance.createTask(
        title: 'Finished essay',
      );
      await TaskController.instance.completeTask(done.id);
      await TaskController.instance.createTask(title: 'Left-over task');

      final controller = StudentAssistantController.instance;
      final result = await controller.ask('evening review');
      expect(result.title, 'Day Review');
      expect(result.message, contains('1 task completed'));
      expect(result.message, contains('Left-over task'));
      expect(
        DailyAssistantController.instance.state.reviewed,
        isTrue,
      );
    });
  });

  group('prepare tomorrow', () {
    test('unfinished work stages a wake-anchored proposal', () async {
      await login('p3_tom_work');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      await TaskController.instance.createTask(
        title: 'Unfinished chores',
        dueDate: DateTime.now(),
        estimatedMinutes: 30,
      );

      final controller = StudentAssistantController.instance;
      final result = await controller.ask('prepare tomorrow');
      expect(result.requiresConfirmation, isTrue);
      expect(controller.hasPendingProposal, isTrue);
      final plan = controller.pendingProposal!;
      expect(plan.sessions, isNotEmpty);
      // Anchored at tomorrow's 7 AM wake, never before.
      final anchor = plan.anchoredStart!;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(anchor.day, tomorrow.day);
      expect(anchor.hour, 7);
    });

    test('clear tomorrow stays honest', () async {
      await login('p3_tom_clear');
      final result = engine.process('prepare tomorrow');
      expect(result.title, 'Tomorrow Is Clear');
      expect(result.proposal, isNull);
    });
  });
}
