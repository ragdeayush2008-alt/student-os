import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/goals/goal_controller.dart';

void main() {
  group('GoalProgress', () {
    test('fraction clamps to 0 when target is 0', () {
      const p = GoalProgress(current: 5, target: 0, label: '', unit: '');
      expect(p.fraction, 0.0);
    });

    test('fraction clamps to 1.0 when current exceeds target', () {
      const p = GoalProgress(current: 150, target: 100, label: '', unit: '');
      expect(p.fraction, 1.0);
    });

    test('fraction is 0.5 at half target', () {
      const p = GoalProgress(current: 50, target: 100, label: '', unit: '');
      expect(p.fraction, 0.5);
    });

    test('remaining is 0 when complete', () {
      const p = GoalProgress(current: 100, target: 100, label: '', unit: '');
      expect(p.remaining, 0.0);
    });

    test('remaining is positive when incomplete', () {
      const p = GoalProgress(current: 30, target: 100, label: '', unit: '');
      expect(p.remaining, 70.0);
    });

    test('isComplete is true when current >= target', () {
      const p1 = GoalProgress(current: 100, target: 100, label: '', unit: '');
      const p2 = GoalProgress(current: 150, target: 100, label: '', unit: '');
      const p3 = GoalProgress(current: 50, target: 100, label: '', unit: '');
      expect(p1.isComplete, true);
      expect(p2.isComplete, true);
      expect(p3.isComplete, false);
    });

    test('isComplete is false when target is 0', () {
      const p = GoalProgress(current: 5, target: 0, label: '', unit: '');
      expect(p.isComplete, false);
    });

    test('hasData is true when current > 0', () {
      const p1 = GoalProgress(current: 1, target: 100, label: '', unit: '');
      const p2 = GoalProgress(current: 0, target: 100, label: '', unit: '');
      expect(p1.hasData, true);
      expect(p2.hasData, false);
    });

    test('hasTarget is true when target > 0', () {
      const p1 = GoalProgress(current: 0, target: 1, label: '', unit: '');
      const p2 = GoalProgress(current: 0, target: 0, label: '', unit: '');
      expect(p1.hasTarget, true);
      expect(p2.hasTarget, false);
    });

    test('summary formats minutes correctly', () {
      const p = GoalProgress(current: 90, target: 120, label: '', unit: 'm');
      expect(p.summary, '1h 30m / 2h');
    });

    test('summary formats hours correctly', () {
      const p = GoalProgress(current: 6.5, target: 10, label: '', unit: 'h');
      expect(p.summary, '6h 30m / 10h');
    });

    test('summary formats tasks correctly', () {
      const p = GoalProgress(current: 7, target: 10, label: '', unit: 'tasks');
      expect(p.summary, '7 / 10 tasks');
    });

    test('remaining with 0 current equals target', () {
      const p = GoalProgress(current: 0, target: 50, label: '', unit: '');
      expect(p.remaining, 50.0);
    });

    test('fraction is 0 when both current and target are 0', () {
      const p = GoalProgress(current: 0, target: 0, label: '', unit: '');
      expect(p.fraction, 0.0);
    });

    test('fraction handles edge case of very small values', () {
      const p = GoalProgress(current: 0.1, target: 100, label: '', unit: '');
      expect(p.fraction, closeTo(0.001, 0.001));
    });
  });

  group('GoalController defaults', () {
    test('default daily study target is 120 minutes', () {
      expect(GoalController.instance.dailyStudyTarget.inMinutes, 120);
    });

    test('default weekly study target is 10 hours', () {
      expect(GoalController.instance.weeklyStudyTarget.inHours, 10);
    });

    test('default weekly task target is 10', () {
      expect(GoalController.instance.weeklyTaskTarget, 10);
    });

    test('default personal goal is empty', () {
      expect(GoalController.instance.personalGoal, '');
    });
  });

  group('GoalController mutations', () {
    test('setWeeklyTaskTarget clamps to valid range', () async {
      await GoalController.instance.setWeeklyTaskTarget(200);
      expect(GoalController.instance.weeklyTaskTarget, 100);

      await GoalController.instance.setWeeklyTaskTarget(-5);
      expect(GoalController.instance.weeklyTaskTarget, 0);

      // Reset
      await GoalController.instance.setWeeklyTaskTarget(10);
    });

    test('setPersonalGoal trims whitespace', () async {
      await GoalController.instance.setPersonalGoal('  Focus on algebra  ');
      expect(GoalController.instance.personalGoal, 'Focus on algebra');
      // Reset
      await GoalController.instance.setPersonalGoal('');
    });
  });
}
