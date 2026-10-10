import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/achievement.dart';
import 'package:student_os/features/progression/achievement_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_achievements_reg');
    await StorageService.instance.clearUser(userId: 'test_achievements_reg');
    AchievementController.instance.clearData();
    await AchievementController.instance.load();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
  });

  group('Achievements Regression Tests', () {
    test('handles corrupt persistent JSON entries safely without throwing', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'uos_test_achievements_reg_earned_achievements_v2',
        '[{"invalid": true, "corrupt": 123}, {"id": "first_task", "unlockedAt": "not_a_valid_date"}]',
      );

      final ac = AchievementController.instance;
      await ac.load();

      expect(ac.isLoaded, isTrue);
      // first_task with fallback timestamp should be parsed safely
      expect(ac.earnedIds.contains('first_task'), isTrue);
    });

    test('clamps progress fractions to 0.0-1.0 boundary', () {
      const achievement = Achievement(
        id: 'clamp_test',
        title: 'Clamp',
        description: 'Testing clamping',
        iconName: 'star',
        category: AchievementCategory.academic,
        condition: 'Do 10 items',
        targetValue: 10,
        unit: 'items',
      );

      final negativeEntry = AchievementEntry(
        achievement: achievement,
        isUnlocked: false,
        currentProgress: -5,
      );
      expect(negativeEntry.progressFraction, 0.0);

      final overflowEntry = AchievementEntry(
        achievement: achievement,
        isUnlocked: false,
        currentProgress: 50,
      );
      expect(overflowEntry.progressFraction, 1.0);
    });
  });
}
