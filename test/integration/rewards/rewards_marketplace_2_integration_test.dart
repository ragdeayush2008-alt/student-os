import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/data/models/catalog/active_course_selection.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/rewards/redemption_controller.dart';
import 'package:student_os/features/rewards/reward_catalog.dart';
import 'package:student_os/features/rewards/theme_manager.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  group('Rewards Marketplace 2.0 — End-to-End Integration Tests', () {
    late ProgressionController progression;
    late RedemptionController redemption;
    late StudyController studyController;
    late SubjectController subjectController;
    late TaskController taskController;
    late CourseCatalogService catalog;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      catalog = CourseCatalogService.instance;
      catalog.ensureInitialized();
      catalog.loadDefaults();

      progression = ProgressionController.instance;
      progression.clearData();

      redemption = RedemptionController.instance;
      redemption.clearData();

      studyController = StudyController.instance;
      studyController.clearData();

      subjectController = SubjectController.instance;
      subjectController.clearData();

      taskController = TaskController.instance;
      taskController.clearData();

      AuthIsolation.instance.setAuthenticatedUser('integration_rewards_user');
      await StorageService.instance.clearUser(userId: 'integration_rewards_user');
      await progression.load();
      await redemption.load();
    });

    tearDown(() async {
      await StorageService.instance.clearUser(userId: 'integration_rewards_user');
      progression.clearData();
      redemption.clearData();
      studyController.clearData();
      subjectController.clearData();
      taskController.clearData();
      FocusController.instance.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('Full Loop: Study -> Earn XP -> Level Up -> Marketplace Redemption -> Equip Theme -> Course Switch Safety', () async {
      // 1. Initial State
      expect(progression.totalXp, 0);
      expect(progression.spendableXp, 0);
      expect(progression.currentLevel.level, 1);
      expect(redemption.inventory, isEmpty);

      // 2. Set Active Course: CA Foundation 2026
      await catalog.setActiveCourse(
        ActiveCourseSelection(
          userId: 'integration_rewards_user',
          categoryId: 'commerce_accounting_finance',
          familyId: 'ca',
          programId: 'ca_foundation',
          programTitle: 'CA Foundation',
          levelId: 'ca_f_level',
          levelTitle: 'Foundation Level',
          year: '2026',
        ),
      );

      // 3. User studies and completes sessions -> XP Earned
      await progression.recordEvent(
        XpEvent(
          id: 'xp_study_1',
          type: XpEventType.studySessionCompleted,
          amount: 250,
          reason: '45m study on Accounting',
          timestamp: DateTime.now(),
        ),
      );

      await progression.recordEvent(
        XpEvent(
          id: 'xp_task_1',
          type: XpEventType.taskCompleted,
          amount: 150,
          reason: 'Completed chapter 1 notes',
          timestamp: DateTime.now(),
        ),
      );

      // Total XP >= 400, Spendable XP >= 400, Level >= 3
      final earnedTotal = progression.totalXp;
      final earnedSpendable = progression.spendableXp;
      expect(earnedTotal, greaterThanOrEqualTo(400));
      expect(progression.currentLevel.level, greaterThanOrEqualTo(3));

      // 4. Next unlock recommendation is available
      final nextReward = RewardCatalog.instance.nextUnlockableReward(
        progression.currentLevel.level,
        progression.spendableXp,
      );
      expect(nextReward, isNotNull);

      // 5. Redeem Focus Theme (150 XP, Level 3)
      final redeemResult = await redemption.redeemReward('theme_focus_dark');
      expect(redeemResult.success, isTrue);

      // Verify balances
      expect(progression.spentXp, 150);
      expect(progression.spendableXp, earnedSpendable - 150);
      expect(redemption.ownsReward('theme_focus_dark'), isTrue);

      // 6. Verify Theme is equipped and active in ThemeManager
      expect(redemption.isEquipped('theme_focus_dark'), isTrue);
      expect(ThemeManager.instance.activeVariant.id, 'focus_dark');

      // 7. Verify Collection progress for Focus Master
      final focusCollection = RewardCatalog.instance.findCollectionById('focus_master');
      expect(focusCollection, isNotNull);
      expect(focusCollection!.unlockedCount(redemption.ownedRewardIds), 1);

      // 8. Favorite another reward
      await redemption.toggleFavorite('feature_advanced_analytics');
      expect(redemption.isFavorite('feature_advanced_analytics'), isTrue);

      // 9. NON-DESTRUCTIVE COURSE SWITCH: Switch to JEE Main
      await catalog.switchCourse(
        newSelection: ActiveCourseSelection(
          userId: 'integration_rewards_user',
          categoryId: 'engineering_technology',
          familyId: 'jee',
          programId: 'jee_main',
          programTitle: 'JEE Main',
          levelId: 'jee_m_p1',
          levelTitle: 'Paper 1',
          year: '2026',
        ),
      );

      // Verify course switched
      expect(catalog.getActiveCourse(), 'JEE Main');

      // CRITICAL DATA PRESERVATION: All XP, rewards, equipped items, and favorites are preserved!
      expect(progression.totalXp, earnedTotal);
      expect(progression.spentXp, 150);
      expect(progression.spendableXp, earnedSpendable - 150);
      expect(redemption.ownsReward('theme_focus_dark'), isTrue);
      expect(redemption.isEquipped('theme_focus_dark'), isTrue);
      expect(redemption.isFavorite('feature_advanced_analytics'), isTrue);

      // 10. Multi-User Isolation
      AuthIsolation.instance.setAuthenticatedUser('other_user_2');
      progression.clearData();
      redemption.clearData();
      await progression.load();
      await redemption.load();

      expect(progression.totalXp, 0);
      expect(redemption.ownsReward('theme_focus_dark'), isFalse);
      expect(redemption.inventory, isEmpty);

      // Restore User 1
      AuthIsolation.instance.setAuthenticatedUser('integration_rewards_user');
      progression.clearData();
      redemption.clearData();
      await progression.load();
      await redemption.load();

      expect(progression.totalXp, earnedTotal);
      expect(redemption.ownsReward('theme_focus_dark'), isTrue);
    });
  });
}
