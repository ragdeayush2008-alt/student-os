import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/assistant/assistant_planning_engine.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';

/// P2 — deterministic planning engine: budget, priority, sleep boundary,
/// buffers, conflicts, empty input. Same input → same plan, always.
void main() {
  StudentTask task({
    required String id,
    required String title,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    int estimatedMinutes = 30,
    String? examId,
    bool completed = false,
  }) {
    return StudentTask(
      id: id,
      title: title,
      priority: priority,
      dueDate: dueDate,
      estimatedMinutes: estimatedMinutes,
      examId: examId,
      status: completed ? TaskStatus.completed : TaskStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  DateTime morning() => DateTime(2026, 10, 5, 9, 0);

  group('budget + session shape', () {
    test('total never exceeds budget, sessions clamp to 25–50m', () {
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: morning(),
        budgetMinutes: 120,
        tasks: [
          task(id: 'a', title: 'A', estimatedMinutes: 180),
          task(id: 'b', title: 'B', estimatedMinutes: 5),
          task(id: 'c', title: 'C'),
        ],
      );
      expect(plan.totalMinutes, lessThanOrEqualTo(120));
      for (final s in plan.sessions) {
        expect(s.minutes, inInclusiveRange(25, 50));
      }
    });

    test('insufficient time leaves honest unscheduled reasons', () {
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: morning(),
        budgetMinutes: 60,
        tasks: [
          task(id: 'a', title: 'Big one', estimatedMinutes: 50),
          task(id: 'b', title: 'Second', estimatedMinutes: 50),
        ],
      );
      expect(plan.sessions.length, 1);
      expect(plan.unscheduled, isNotEmpty);
      expect(plan.unscheduled.join(' '), contains('Second'));
    });

    test('empty tasks yield an empty plan', () {
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: morning(),
        budgetMinutes: 120,
        tasks: const [],
      );
      expect(plan.isEmpty, isTrue);
      expect(plan.sessions, isEmpty);
    });

    test('budget clamps to the 8h ceiling', () {
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: morning(),
        budgetMinutes: 9999,
        tasks: [task(id: 'a', title: 'A')],
      );
      expect(plan.budgetMinutes, AssistantPlanningEngine.maxDayMinutes);
    });
  });

  group('priority order', () {
    test('overdue → due today → high → normal → low', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: now,
        budgetMinutes: 480,
        tasks: [
          task(id: 'low', title: 'Low', priority: TaskPriority.low),
          task(
            id: 'over',
            title: 'Overdue',
            dueDate: today.subtract(const Duration(days: 1)),
          ),
          task(
            id: 'high',
            title: 'High',
            priority: TaskPriority.high,
            dueDate: today.add(const Duration(days: 1)),
          ),
          task(id: 'today', title: 'Today', dueDate: today),
        ],
        sessionCap: 10,
      );
      final titles = plan.sessions.map((s) => s.title).toList();
      expect(
        titles,
        ['Overdue', 'Today', 'High', 'Low'],
      );
    });

    test('completed tasks never appear', () {
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: morning(),
        budgetMinutes: 120,
        tasks: [task(id: 'd', title: 'Done', completed: true)],
      );
      expect(plan.sessions, isEmpty);
    });

    test('far-future tasks are out of scope', () {
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: morning(),
        budgetMinutes: 120,
        tasks: [
          task(
            id: 'f',
            title: 'Future',
            dueDate: DateTime(2026, 10, 5).add(const Duration(days: 9)),
          ),
        ],
      );
      expect(plan.sessions, isEmpty);
    });
  });

  group('sleep boundary', () {
    test('plan stops before bedtime with a recorded conflict', () {
      // 21:30 with an 8h budget and 23:00 bedtime → only ~90m fits.
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: DateTime(2026, 10, 5, 21, 30),
        budgetMinutes: 480,
        tasks: [
          task(id: 'a', title: 'A', estimatedMinutes: 50),
          task(id: 'b', title: 'B', estimatedMinutes: 50),
          task(id: 'c', title: 'C', estimatedMinutes: 50),
        ],
        sleep: const SleepSchedule(bedtimeMinutes: 1380),
      );
      expect(plan.totalMinutes, lessThanOrEqualTo(90));
      expect(plan.conflicts, isNotEmpty);
      expect(plan.sleepNote, contains('11 PM'));
    });

    test('explicit evening cutoff respected', () {
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: DateTime(2026, 10, 5, 20, 0),
        budgetMinutes: 480,
        tasks: [
          task(id: 'a', title: 'A', estimatedMinutes: 50),
          task(id: 'b', title: 'B', estimatedMinutes: 50),
          task(id: 'c', title: 'C', estimatedMinutes: 50),
        ],
        eveningCutoffMinutes: 22 * 60,
      );
      expect(plan.totalMinutes, lessThanOrEqualTo(120));
    });
  });

  group('layout', () {
    test('laidOutStarts spaces sessions with breaks', () {
      final plan = AssistantPlanningEngine.proposeDayPlan(
        now: morning(),
        budgetMinutes: 120,
        tasks: [
          task(id: 'a', title: 'A', estimatedMinutes: 30),
          task(id: 'b', title: 'B', estimatedMinutes: 30),
        ],
      );
      final starts = plan.laidOutStarts();
      expect(starts.length, 2);
      final gap = starts[1].difference(starts[0]).inMinutes;
      expect(gap, 30 + AssistantPlanningEngine.breakMinutes);
    });

    test('deterministic: same input, same order', () {
      AssistantDayPlan build() => AssistantPlanningEngine.proposeDayPlan(
            now: morning(),
            budgetMinutes: 200,
            tasks: [
              task(id: 'a', title: 'Alpha'),
              task(id: 'b', title: 'Beta', priority: TaskPriority.high),
            ],
          );
      expect(
        build().sessions.map((s) => s.id).toList(),
        build().sessions.map((s) => s.id).toList(),
      );
    });
  });
}
