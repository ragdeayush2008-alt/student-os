import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/achievement.dart';

void main() {
  group('Achievement Model', () {
    test('constructs with required and optional fields', () {
      const achievement = Achievement(
        id: 'test_id',
        title: 'Test Title',
        description: 'Test Description',
        iconName: 'star',
        category: AchievementCategory.focus,
        condition: 'Complete 5 sessions',
        targetValue: 5,
        unit: 'sessions',
        xpReward: 30,
      );

      expect(achievement.id, 'test_id');
      expect(achievement.title, 'Test Title');
      expect(achievement.description, 'Test Description');
      expect(achievement.iconName, 'star');
      expect(achievement.category, AchievementCategory.focus);
      expect(achievement.condition, 'Complete 5 sessions');
      expect(achievement.targetValue, 5);
      expect(achievement.unit, 'sessions');
      expect(achievement.xpReward, 30);
    });

    test('toJson and fromJson roundtrip preserves all attributes', () {
      const original = Achievement(
        id: 'academic_milestone',
        title: 'Scholar',
        description: 'Complete 25 study sessions',
        iconName: 'school',
        category: AchievementCategory.academic,
        condition: 'Complete 25 study sessions',
        targetValue: 25,
        unit: 'sessions',
        xpReward: 50,
      );

      final json = original.toJson();
      final restored = Achievement.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.iconName, original.iconName);
      expect(restored.category, original.category);
      expect(restored.condition, original.condition);
      expect(restored.targetValue, original.targetValue);
      expect(restored.unit, original.unit);
      expect(restored.xpReward, original.xpReward);
      expect(restored, equals(original));
    });

    test('fromJson gracefully falls back for unknown categories', () {
      final json = <String, dynamic>{
        'id': 'unknown_cat_achievement',
        'title': 'Mystery Title',
        'description': 'Mystery Description',
        'iconName': 'help',
        'category': 'non_existent_category',
        'condition': 'Do something mysterious',
      };

      final achievement = Achievement.fromJson(json);
      expect(achievement.category, AchievementCategory.academic);
      expect(achievement.targetValue, 1);
    });
  });

  group('AchievementEntry Presentation Model', () {
    const testAchievement = Achievement(
      id: 'task_entry_test',
      title: 'Task Pro',
      description: 'Finish 10 tasks',
      iconName: 'task_alt',
      category: AchievementCategory.academic,
      condition: 'Finish 10 tasks',
      targetValue: 10,
      unit: 'tasks',
      xpReward: 25,
    );

    test('computes progressFraction accurately', () {
      final partialEntry = AchievementEntry(
        achievement: testAchievement,
        isUnlocked: false,
        currentProgress: 4,
      );
      expect(partialEntry.progressFraction, 0.4);

      final overProgressEntry = AchievementEntry(
        achievement: testAchievement,
        isUnlocked: false,
        currentProgress: 15,
      );
      expect(overProgressEntry.progressFraction, 1.0);

      final unlockedEntry = AchievementEntry(
        achievement: testAchievement,
        isUnlocked: true,
        currentProgress: 10,
      );
      expect(unlockedEntry.progressFraction, 1.0);
    });

    test('progressSummary formats locked vs unlocked state', () {
      final locked = AchievementEntry(
        achievement: testAchievement,
        isUnlocked: false,
        currentProgress: 3,
      );
      expect(locked.progressSummary, '3 / 10 tasks');

      final unlocked = AchievementEntry(
        achievement: testAchievement,
        isUnlocked: true,
        currentProgress: 10,
      );
      expect(unlocked.progressSummary, 'Unlocked');
    });

    test('actionNeeded provides clear guidance', () {
      final locked = AchievementEntry(
        achievement: testAchievement,
        isUnlocked: false,
        currentProgress: 7,
      );
      expect(locked.actionNeeded, 'Complete 3 more tasks to unlock.');

      final unlocked = AchievementEntry(
        achievement: testAchievement,
        isUnlocked: true,
        currentProgress: 10,
        unlockedAt: DateTime(2026, 9, 10),
      );
      expect(unlocked.actionNeeded, contains('Earned on Sep 10, 2026'));
    });
  });

  group('AchievementCatalog', () {
    test('all catalog achievements have valid non-empty identifiers and descriptions', () {
      for (final a in AchievementCatalog.achievements) {
        expect(a.id.isNotEmpty, isTrue);
        expect(a.title.isNotEmpty, isTrue);
        expect(a.description.isNotEmpty, isTrue);
        expect(a.targetValue, greaterThan(0));
      }
    });

    test('covers all major Student OS domains', () {
      final categories = AchievementCatalog.achievements.map((a) => a.category).toSet();
      expect(categories.contains(AchievementCategory.academic), isTrue);
      expect(categories.contains(AchievementCategory.focus), isTrue);
      expect(categories.contains(AchievementCategory.consistency), isTrue);
      expect(categories.contains(AchievementCategory.progression), isTrue);
      expect(categories.contains(AchievementCategory.goals), isTrue);
      expect(categories.contains(AchievementCategory.exploration), isTrue);
    });
  });
}
