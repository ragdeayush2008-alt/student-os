import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/theme_variants.dart';
import 'package:student_os/data/models/catalog/active_course_selection.dart';
import 'package:student_os/data/models/reward.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/rewards/premium_entitlement.dart';
import 'package:student_os/features/rewards/recommendation_engine.dart';
import 'package:student_os/features/rewards/redemption_controller.dart';
import 'package:student_os/features/rewards/reward_catalog.dart';
import 'package:student_os/features/rewards/theme_manager.dart';

void main() {
  group('Rewards Marketplace 2.0 — Unit Tests', () {
    late ProgressionController progression;
    late RedemptionController redemption;
    late RewardCatalog catalog;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      catalog = RewardCatalog.instance;

      AuthIsolation.instance.setAuthenticatedUser('test_rewards_user');
      await StorageService.instance.clearUser(userId: 'test_rewards_user');

      progression = ProgressionController.instance;
      progression.clearData();

      redemption = RedemptionController.instance;
      redemption.clearData();

      await progression.load();
      await redemption.load();
    });

    tearDown(() async {
      await StorageService.instance.clearUser(userId: 'test_rewards_user');
      progression.clearData();
      redemption.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('1. Reward Model: Rarity, BenefitType, UnlockType, and Serialization', () {
      const reward = Reward(
        id: 'test_theme_1',
        title: 'Aurora Study Theme',
        subtitle: 'Emerald Night Palette',
        description: 'Serene aurora borealis inspired night palette.',
        type: 'theme',
        category: RewardCategory.cosmetic,
        xpCost: 450,
        minimumLevel: 7,
        requiredStreak: 5,
        unlockType: RewardUnlockType.xp,
        benefitType: RewardBenefitType.theme,
        rarity: RewardRarity.epic,
        collectionId: 'scholar',
        isFeatured: true,
      );

      expect(reward.isEquippable, isTrue);
      expect(reward.equipmentSlot, 'theme');
      expect(reward.rarity, RewardRarity.epic);
      expect(reward.benefitType, RewardBenefitType.theme);

      final json = reward.toJson();
      final restored = Reward.fromJson(json);

      expect(restored.id, 'test_theme_1');
      expect(restored.rarity, RewardRarity.epic);
      expect(restored.collectionId, 'scholar');
      expect(restored.requiredStreak, 5);
    });

    test('2. Reward Collections: Progress and Completion tracking', () {
      final collections = catalog.collections;
      expect(collections.length, greaterThanOrEqualTo(4));

      final focusCol = collections.firstWhere((c) => c.id == 'focus_master');
      expect(focusCol.totalItems, greaterThanOrEqualTo(3));

      final owned = {'theme_focus_dark', 'focus_timer_minimal'};
      expect(focusCol.unlockedCount(owned), 2);
      expect(focusCol.isComplete(owned), isFalse);

      final allFocus = focusCol.rewardIds.toSet();
      expect(focusCol.unlockedCount(allFocus), focusCol.totalItems);
      expect(focusCol.isComplete(allFocus), isTrue);
    });

    test('3. Fast Local Search in Catalog across titles, categories, and rarities', () {
      expect(catalog.search('Focus').length, greaterThanOrEqualTo(2));
      expect(catalog.search('Analytics').length, 1);
      expect(catalog.search('Theme').length, greaterThanOrEqualTo(4));
      expect(catalog.search('Legend').length, 1);
      expect(catalog.search('NonExistentReward123'), isEmpty);
    });

    test('4. Atomic Redemption & XP Deduction', () async {
      // Award 500 XP to reach Level 5
      await progression.recordEvent(
        XpEvent(
          id: 'xp_test_1',
          type: XpEventType.studySessionCompleted,
          amount: 500,
          reason: 'Initial XP balance',
          timestamp: DateTime.now(),
        ),
      );

      final initialTotal = progression.totalXp;
      final initialSpendable = progression.spendableXp;
      expect(initialTotal, greaterThanOrEqualTo(500));
      expect(progression.currentLevel.level, greaterThanOrEqualTo(4));

      // Redeem Focus Theme (150 XP, Level 3 required)
      final result = await redemption.redeemReward('theme_focus_dark');
      expect(result.success, isTrue);
      expect(result.transaction, isNotNull);
      expect(result.transaction!.xpSpent, 150);

      // Verify XP balances
      expect(progression.totalXp, initialTotal); // Lifetime XP unchanged
      expect(progression.spentXp, 150); // XP spent tracked
      expect(progression.spendableXp, initialSpendable - 150); // Available XP balance deducted

      // Verify ownership
      expect(redemption.ownsReward('theme_focus_dark'), isTrue);
      expect(redemption.inventory.any((r) => r.id == 'theme_focus_dark'), isTrue);
    });

    test('5. Duplicate Redemption Prevention', () async {
      await progression.recordEvent(
        XpEvent(
          id: 'xp_test_dup',
          type: XpEventType.studySessionCompleted,
          amount: 500,
          reason: 'XP balance',
          timestamp: DateTime.now(),
        ),
      );

      final initialSpendable = progression.spendableXp;

      // First redemption (First steps = 50 XP)
      final res1 = await redemption.redeemReward('badge_first_steps');
      expect(res1.success, isTrue);
      expect(progression.spendableXp, initialSpendable - 50);

      // Second redemption of same one-time reward must fail
      final res2 = await redemption.redeemReward('badge_first_steps');
      expect(res2.success, isFalse);
      expect(res2.errorMessage, contains('already own'));
      expect(progression.spendableXp, initialSpendable - 50); // No double deduction
    });

    test('6. Insufficient XP Protection', () async {
      // User has Level 1 and only 20 XP, tries to redeem First Steps (50 XP, Level 1)
      await progression.recordEvent(
        XpEvent(
          id: 'xp_test_low',
          type: XpEventType.taskCompleted,
          amount: 20,
          reason: 'Small task',
          timestamp: DateTime.now(),
        ),
      );

      final result = await redemption.redeemReward('badge_first_steps');
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Not enough XP'));
      expect(progression.spentXp, 0);
    });

    test('7. Level Requirement Validation', () async {
      // Award 300 XP but level is e.g. 3, try redeeming Level 10 reward
      await progression.recordEvent(
        XpEvent(
          id: 'xp_test_lvl',
          type: XpEventType.studySessionCompleted,
          amount: 300,
          reason: 'XP balance',
          timestamp: DateTime.now(),
        ),
      );

      // 'badge_exam_master' requires Level 10
      final result = await redemption.redeemReward('badge_exam_master');
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Requires Level 10'));
    });

    test('8. Equipment & Slot Management (Theme, Badge, Frame)', () async {
      await progression.recordEvent(
        XpEvent(
          id: 'xp_equip_test',
          type: XpEventType.studySessionCompleted,
          amount: 1000,
          reason: 'XP balance',
          timestamp: DateTime.now(),
        ),
      );

      await redemption.redeemReward('theme_focus_dark');
      expect(redemption.isEquipped('theme_focus_dark'), isTrue);
      expect(ThemeManager.instance.activeVariant.id, 'focus_dark');

      // Unequip theme resets to default
      await redemption.unequipSlot('theme');
      expect(redemption.isEquipped('theme_focus_dark'), isFalse);
      expect(ThemeManager.instance.activeVariant, ThemeVariantId.defaultTheme);
    });

    test('9. Favorites Persistence', () async {
      expect(redemption.isFavorite('theme_focus_dark'), isFalse);

      await redemption.toggleFavorite('theme_focus_dark');
      expect(redemption.isFavorite('theme_focus_dark'), isTrue);

      await redemption.toggleFavorite('theme_focus_dark');
      expect(redemption.isFavorite('theme_focus_dark'), isFalse);
    });

    test('10. Premium Trial Activation upon Redemption', () async {
      // Level up to 15
      for (int i = 0; i < 15; i++) {
        await progression.recordEvent(
          XpEvent(
            id: 'xp_prem_bulk_$i',
            type: XpEventType.studySessionCompleted,
            amount: 500,
            reason: 'Bulk study',
            timestamp: DateTime.now(),
          ),
        );
      }

      final res = await redemption.redeemReward('discount_premium_trial');
      expect(res.success, isTrue);
      expect(PremiumEntitlement.instance.isPremiumActive, isTrue);
      expect(PremiumEntitlement.instance.trialDaysRemaining, 7);
    });

    test('11. For You Personalization is Course & Habit Context Aware', () async {
      // Set active course context to CA Foundation
      await CourseCatalogService.instance.setActiveCourse(
        ActiveCourseSelection(
          userId: 'test_rewards_user',
          categoryId: 'commerce_accounting_finance',
          familyId: 'ca',
          programId: 'ca_foundation',
          programTitle: 'CA Foundation',
          levelId: 'ca_f_level',
          levelTitle: 'Foundation Level',
        ),
      );

      await progression.recordEvent(
        XpEvent(
          id: 'xp_rec_1',
          type: XpEventType.studySessionCompleted,
          amount: 200,
          reason: 'XP balance',
          timestamp: DateTime.now(),
        ),
      );

      final recs = RecommendationEngine.getRecommendations(maxRecommendations: 5);
      expect(recs.isNotEmpty, isTrue);
      expect(recs.first.explanation.isNotEmpty, isTrue);
    });

    test('12. User Isolation: Redemptions and Inventory are Isolated', () async {
      // User A redeems Focus Theme
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      await progression.load();
      await redemption.load();
      await progression.recordEvent(
        XpEvent(
          id: 'xp_user_a',
          type: XpEventType.studySessionCompleted,
          amount: 500,
          reason: 'User A XP',
          timestamp: DateTime.now(),
        ),
      );
      await redemption.redeemReward('theme_focus_dark');
      expect(redemption.ownsReward('theme_focus_dark'), isTrue);

      // Switch to User B
      AuthIsolation.instance.setAuthenticatedUser('user_B');
      progression.clearData();
      redemption.clearData();
      await progression.load();
      await redemption.load();

      expect(progression.spendableXp, 0);
      expect(redemption.ownsReward('theme_focus_dark'), isFalse);
      expect(redemption.inventory, isEmpty);

      // Switch back to User A
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      progression.clearData();
      redemption.clearData();
      await progression.load();
      await redemption.load();

      expect(redemption.ownsReward('theme_focus_dark'), isTrue);
      expect(progression.spentXp, 150);
    });
  });
}
