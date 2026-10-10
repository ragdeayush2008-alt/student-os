import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/data/models/task.dart';

void main() {
  group('Planning Workload & Remaining Duration Calculation Tests', () {
    test('180m planned with 0m completed results in 180m remaining', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 4 blocks totaling 180 minutes
      final blocks = [
        PlanningBlock(
          id: 'b1',
          userId: 'user_test',
          startAt: DateTime(today.year, today.month, today.day, 9, 0),
          endAt: DateTime(today.year, today.month, today.day, 9, 45),
          customTitle: 'Block 1',
        ),
        PlanningBlock(
          id: 'b2',
          userId: 'user_test',
          startAt: DateTime(today.year, today.month, today.day, 10, 0),
          endAt: DateTime(today.year, today.month, today.day, 10, 45),
          customTitle: 'Block 2',
        ),
        PlanningBlock(
          id: 'b3',
          userId: 'user_test',
          startAt: DateTime(today.year, today.month, today.day, 11, 0),
          endAt: DateTime(today.year, today.month, today.day, 11, 45),
          customTitle: 'Block 3',
        ),
        PlanningBlock(
          id: 'b4',
          userId: 'user_test',
          startAt: DateTime(today.year, today.month, today.day, 12, 0),
          endAt: DateTime(today.year, today.month, today.day, 12, 45),
          customTitle: 'Block 4',
        ),
      ];

      final workload = PlanningEngine.calculateDayWorkload(
        today,
        tasks: const [],
        blocks: blocks,
      );

      expect(workload.plannedMinutes, 180);
      expect(workload.completedMinutes, 0);
      expect(workload.remainingMinutes, 180);
      expect(workload.estimatedMinutesRemaining, 180);
    });

    test('180m planned with 45m completed results in 135m remaining', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final task1 = StudentTask(
        id: 't1',
        title: 'Task 1',
        status: TaskStatus.completed,
        estimatedMinutes: 45,
        scheduledDate: today,
      );

      final blocks = [
        PlanningBlock(
          id: 'b1',
          userId: 'user_test',
          startAt: DateTime(today.year, today.month, today.day, 9, 0),
          endAt: DateTime(today.year, today.month, today.day, 12, 0), // 180 min
          customTitle: 'Long Study Block',
        ),
      ];

      final workload = PlanningEngine.calculateDayWorkload(
        today,
        tasks: [task1],
        blocks: blocks,
      );

      expect(workload.plannedMinutes, 180);
      expect(workload.completedMinutes, 45);
      expect(workload.remainingMinutes, 135);
    });
  });
}
