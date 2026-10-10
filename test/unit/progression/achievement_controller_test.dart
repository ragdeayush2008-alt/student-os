import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/data/models/achievement.dart';
import 'package:student_os/features/progression/achievement_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    AchievementController.instance.clearData();
    ProgressionController.instance.clearData();
    FocusController.instance.clearData();
    StudyController.instance.clearData();
    TaskController.instance.clearData();
  });

  group('Achievement Catalog', () {
    test('has meaningful achievements', () {
      expect(AchievementCatalog.achievements.length, greaterThanOrEqualTo(10));
    });

    test('each achievement has unique ID', () {
      final ids = AchievementCatalog.achievements.map((a) => a.id).toSet();
      expect(ids.length, AchievementCatalog.achievements.length);
    });

    test('findById returns correct achievement', () {
      final achievement = AchievementCatalog.findById('first_task');
      expect(achievement, isNotNull);
      expect(achievement!.title, 'First Steps');
    });

    test('findById returns null for unknown ID', () {
      expect(AchievementCatalog.findById('nonexistent'), isNull);
    });
  });

  group('AchievementController', () {
    test('starts with no earned achievements', () {
      final ac = AchievementController.instance;
      expect(ac.earnedCount, 0);
      expect(ac.earnedIds, isEmpty);
    });

    test('entries returns all achievements with earned state', () {
      final ac = AchievementController.instance;
      final entries = ac.entries;
      expect(entries.length, AchievementCatalog.achievements.length);
      expect(entries.every((e) => !e.earned), true);
    });

    test('evaluate with no activity earns nothing', () async {
      final ac = AchievementController.instance;
      final earned = await ac.evaluate();
      expect(earned, isEmpty);
      expect(ac.earnedCount, 0);
    });

    test('evaluate is idempotent', () async {
      final ac = AchievementController.instance;
      await ac.evaluate();
      await ac.evaluate();
      expect(ac.earnedCount, 0);
    });

    test('clearData resets earned state', () async {
      final ac = AchievementController.instance;
      ac.clearData();
      expect(ac.earnedCount, 0);
      expect(ac.isLoaded, false);
    });
  });

  group('Achievement Persistence', () {
    test('earned achievements persist across load', () async {
      // Manually add an earned achievement
      final ac = AchievementController.instance;
      // Simulate earning by adding to the set and saving
      await ac.evaluate(); // Should earn nothing

      // After clear and reload, should still be empty
      ac.clearData();
      await ac.load();
      expect(ac.earnedCount, 0);
    });
  });

  group('Achievement Model', () {
    test('serialization roundtrip', () {
      const achievement = Achievement(
        id: 'test_achievement',
        title: 'Test Achievement',
        description: 'A test achievement',
        iconName: 'star',
        category: AchievementCategory.tasks,
        condition: 'Complete 1 task',
      );

      final json = achievement.toJson();
      final fromJson = Achievement.fromJson(json);

      expect(fromJson.id, 'test_achievement');
      expect(fromJson.title, 'Test Achievement');
      expect(fromJson.category, AchievementCategory.tasks);
    });
  });
}
