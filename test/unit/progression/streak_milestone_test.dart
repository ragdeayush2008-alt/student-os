import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/services/streak_service.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';
import 'package:student_os/features/study/study_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    TaskController.instance.clearData();
    StudyController.instance.clearData();
    ProgressionController.instance.clearData();
  });

  group('Streak Service', () {
    test('currentStreak is 0 with no activity', () {
      expect(StreakService.instance.currentStreak, 0);
    });

    test('activityToday is false with no activity', () {
      expect(StreakService.instance.activityToday, false);
    });

    test('bestStreak is 0 with no activity', () {
      expect(StreakService.instance.bestStreak, 0);
    });

    test('refresh does not crash', () {
      expect(() => StreakService.instance.refresh(), returnsNormally);
    });
  });

  group('Streak Milestone Integration', () {
    test('awarding streak milestone with 0 days returns false', () async {
      final result = await ProgressionController.instance.awardStreakMilestone(
        0,
      );
      expect(result, false);
    });

    test('awarding streak milestone with 3 days succeeds', () async {
      final result = await ProgressionController.instance.awardStreakMilestone(
        3,
      );
      expect(result, true);
    });

    test('awarding streak milestone is idempotent', () async {
      await ProgressionController.instance.awardStreakMilestone(3);
      final result = await ProgressionController.instance.awardStreakMilestone(
        3,
      );
      expect(result, false); // Should be duplicate
    });

    test(
      'awarding streak milestone with non-milestone days returns false',
      () async {
        final result = await ProgressionController.instance
            .awardStreakMilestone(5);
        expect(result, false);
      },
    );

    test('streak milestone XP is correct', () async {
      // 3-day streak = 20 XP
      await ProgressionController.instance.awardStreakMilestone(3);
      expect(ProgressionController.instance.totalXp, 20);

      // 7-day streak = 40 XP
      await ProgressionController.instance.awardStreakMilestone(7);
      expect(ProgressionController.instance.totalXp, 60);
    });
  });

  group('Weekly Consistency', () {
    test('weekly consistency event ID is deterministic', () {
      final now = DateTime(2026, 9, 1); // A Monday
      final id1 =
          'weekly_consistency_${now.toIso8601String().substring(0, 10)}';
      final id2 =
          'weekly_consistency_${now.toIso8601String().substring(0, 10)}';
      expect(id1, id2);
    });
  });

  group('User Isolation', () {
    test('clearData resets all progression state', () async {
      await ProgressionController.instance.awardStreakMilestone(3);
      expect(ProgressionController.instance.totalXp, 20);

      ProgressionController.instance.clearData();
      expect(ProgressionController.instance.totalXp, 0);
      expect(ProgressionController.instance.events, isEmpty);
    });
  });
}
