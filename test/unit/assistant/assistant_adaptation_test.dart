import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/assistant_planning_engine.dart';
import 'package:student_os/core/assistant/assistant_daily_state.dart';
import 'package:student_os/core/assistant/daily_assistant_controller.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P3 — adaptation: sleep-boundary deferral, ahead/behind detection.
/// Nothing is applied silently; every path ends in a proposal or message.
void main() {
  const engine = StudentAssistantEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
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
    DailyAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  Future<void> login(String user) async {
    AuthIsolation.instance.setAuthenticatedUser(user);
    await SleepController.instance.load();
    await DailyAssistantController.instance.load();
  }

  group('sleep-boundary deferral', () {
    test('late-night planning stops at bedtime, never past it', () async {
      await login('p3_adapt_sleep');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      for (var i = 0; i < 4; i++) {
        await TaskController.instance.createTask(
          title: 'Late task $i',
          estimatedMinutes: 50,
        );
      }
      // 22:30 with an 11 PM bedtime: only ~30m fits.
      final result = engine.process(
        'I have 3 hours',
        referenceTime: DateTime(2026, 10, 5, 22, 30),
      );
      final proposal = result.proposal;
      if (proposal != null) {
        final starts = proposal.laidOutStarts();
        for (var i = 0; i < proposal.sessions.length; i++) {
          final end = starts[i].add(
            Duration(minutes: proposal.sessions[i].minutes),
          );
          final bed = DateTime(2026, 10, 5, 23, 0);
          expect(
            end.isAfter(bed),
            isFalse,
            reason: 'session ${proposal.sessions[i].title} crosses sleep',
          );
        }
      }
      // Either a trimmed proposal or an honest deferral note exists.
      final text =
          '${result.message} ${result.previewItems.join(' ')} ${result.contextLine ?? ''}';
      expect(
        text.contains('11 PM') || text.contains('sleep'),
        isTrue,
      );
    });

    test('sleep pressure surfaces a boundary trigger', () async {
      await login('p3_adapt_trig');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      await TaskController.instance.createTask(
        title: 'Due tonight',
        dueDate: DateTime.now(),
      );
      // Simulate 22:40 (20 min before bed) via explicit now.
      final triggers = DailyAssistantController.instance.buildTriggers(
        now: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          22,
          40,
        ),
      );
      final kinds = triggers.map((t) => t.kind).toSet();
      expect(
        kinds.contains(AssistantTriggerKind.sleepBoundary) ||
            kinds.contains(AssistantTriggerKind.fixDay),
        isTrue,
      );
    });
  });

  group('behind detection', () {
    test('overloaded remaining surfaces fix-day trigger', () async {
      await login('p3_adapt_behind');
      for (var i = 0; i < 5; i++) {
        await TaskController.instance.createTask(
          title: 'Heavy $i',
          dueDate: DateTime.now(),
          estimatedMinutes: 50,
        );
      }
      final triggers = DailyAssistantController.instance.buildTriggers();
      expect(
        triggers.where((t) => t.kind == AssistantTriggerKind.fixDay),
        isNotEmpty,
      );
    });
  });

  group('priority model documentation', () {
    test('ranking reasons stay human-readable', () {
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: DateTime.now(),
        budgetMinutes: 120,
        tasks: [
          StudentTask(
            id: 'x',
            title: 'Overdue essay',
            priority: TaskPriority.high,
            dueDate: DateTime.now().subtract(const Duration(days: 1)),
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      expect(plan.sessions.single.reason, contains('Overdue'));
    });
  });
}
