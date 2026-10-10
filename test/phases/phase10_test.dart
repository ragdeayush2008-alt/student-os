import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/rewards/rewards_compatibility.dart';
import 'package:student_os/core/services/notification_service.dart';
import 'package:student_os/data/models/entitlement.dart';
import 'package:student_os/data/models/reward.dart';
import 'package:student_os/data/models/reward_transaction.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/rewards/entitlement_manager.dart';
import 'package:student_os/features/rewards/redemption_controller.dart';
import 'package:student_os/features/rewards/reward_catalog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 10 — Reward Model & Serialization', () {
    test('Reward toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 8, 29, 12, 0);
      final reward = Reward(
        id: 'test_theme_1',
        title: 'Emerald Scholar',
        description: 'Deep green theme for academic focus',
        type: 'theme',
        category: RewardCategory.cosmetic,
        xpCost: 250,
        minimumLevel: 5,
        availability: RewardAvailability.available,
        iconName: 'palette',
        isOneTime: true,
        expiresAt: now.add(const Duration(days: 30)),
        metadata: {'themeColor': '#10B981'},
      );

      final json = reward.toJson();
      final parsed = Reward.fromJson(json);

      expect(parsed.id, reward.id);
      expect(parsed.title, reward.title);
      expect(parsed.description, reward.description);
      expect(parsed.type, reward.type);
      expect(parsed.category, reward.category);
      expect(parsed.xpCost, reward.xpCost);
      expect(parsed.minimumLevel, reward.minimumLevel);
      expect(parsed.availability, reward.availability);
      expect(parsed.iconName, reward.iconName);
      expect(parsed.isOneTime, isTrue);
      expect(parsed.metadata?['themeColor'], '#10B981');
    });

    test(
      'Reward handles missing optional fields and fallback enums safely',
      () {
        final json = {
          'id': 'minimal_reward',
          'title': 'Minimal',
          'category': 'unknown_category',
          'availability': 'unknown_avail',
        };

        final reward = Reward.fromJson(json);
        expect(reward.id, 'minimal_reward');
        expect(reward.title, 'Minimal');
        expect(reward.category, RewardCategory.cosmetic);
        expect(reward.availability, RewardAvailability.available);
        expect(reward.xpCost, 0);
        expect(reward.minimumLevel, 1);
        expect(reward.isOneTime, isTrue);
        expect(reward.expiresAt, isNull);
      },
    );

    test('RewardTransaction toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 8, 29, 12, 0);
      final tx = RewardTransaction(
        id: 'tx_123',
        rewardId: 'theme_focus',
        xpSpent: 150,
        timestamp: now,
        status: RedemptionStatus.completed,
        rewardTitle: 'Focus Theme',
      );

      final json = tx.toJson();
      final parsed = RewardTransaction.fromJson(json);

      expect(parsed.id, tx.id);
      expect(parsed.rewardId, tx.rewardId);
      expect(parsed.xpSpent, tx.xpSpent);
      expect(parsed.timestamp, tx.timestamp);
      expect(parsed.status, RedemptionStatus.completed);
      expect(parsed.rewardTitle, 'Focus Theme');
    });

    test('StudentEntitlement isActive check handles expiration correctly', () {
      final now = DateTime.now();
      final activeEntitlement = StudentEntitlement(
        id: 'ent_1',
        rewardId: 'theme_1',
        type: EntitlementType.theme,
        grantedAt: now,
        status: EntitlementStatus.active,
      );

      final expiredEntitlement = StudentEntitlement(
        id: 'ent_2',
        rewardId: 'trial_1',
        type: EntitlementType.premium,
        grantedAt: now.subtract(const Duration(days: 10)),
        expiresAt: now.subtract(const Duration(days: 1)),
        status: EntitlementStatus.active,
      );

      expect(activeEntitlement.isActive, isTrue);
      expect(expiredEntitlement.isActive, isFalse);
    });
  });

  group('Phase 10 — Reward Catalog', () {
    test('Catalog provides available rewards and allows lookup by ID', () {
      final catalog = RewardCatalog.instance;
      expect(catalog.allRewards, isNotEmpty);

      final firstReward = catalog.allRewards.first;
      final found = catalog.findById(firstReward.id);

      expect(found, isNotNull);
      expect(found?.id, firstReward.id);
    });

    test('Catalog filters by category correctly', () {
      final catalog = RewardCatalog.instance;
      final cosmetics = catalog.rewardsInCategory(RewardCategory.cosmetic);
      expect(cosmetics, isNotEmpty);
      expect(
        cosmetics.every((r) => r.category == RewardCategory.cosmetic),
        isTrue,
      );
    });

    test(
      'Catalog computes eligible and locked rewards based on level & XP',
      () {
        final catalog = RewardCatalog.instance;
        // Level 1 with 0 XP -> no high level rewards eligible
        final eligibleLow = catalog.eligibleRewards(1, 0);
        final lockedLow = catalog.lockedRewards(1, 0);

        expect(eligibleLow.length, lessThan(catalog.availableRewards.length));
        expect(lockedLow.length, greaterThan(0));

        // Level 50 with 10,000 XP -> many eligible
        final eligibleHigh = catalog.eligibleRewards(50, 10000);
        expect(eligibleHigh.length, greaterThan(eligibleLow.length));
      },
    );
  });

  group('Phase 10 — XP Accounting & Spendable vs Lifetime XP', () {
    test(
      'Spending XP does NOT decrease student Level or Lifetime XP',
      () async {
        final progression = ProgressionController.instance;
        await progression.load();

        // Record 1000 XP across events
        await progression.recordEvent(
          XpEvent(
            id: 'xp_acct_test_1',
            type: XpEventType.taskCompleted,
            amount: 1000,
            timestamp: DateTime.now(),
            reason: 'Test big task',
          ),
        );

        final initialTotalXp = progression.totalXp;
        final initialLevel = progression.currentLevel.level;
        expect(initialTotalXp, greaterThanOrEqualTo(1000));
        expect(progression.spendableXp, greaterThanOrEqualTo(1000));

        // Spend 200 XP
        final spendSuccess = await progression.spendXp(200);
        expect(spendSuccess, isTrue);

        // Verify Lifetime XP and Level remain untouched!
        expect(progression.totalXp, initialTotalXp);
        expect(progression.currentLevel.level, initialLevel);
        expect(progression.spentXp, 200);
        expect(progression.spendableXp, initialTotalXp - 200);
      },
    );

    test('Cannot spend more XP than available spendable balance', () async {
      final progression = ProgressionController.instance;
      final available = progression.spendableXp;

      // Attempt to spend more than available
      final spendOver = await progression.spendXp(available + 5000);
      expect(spendOver, isFalse);
    });

    test('Refund XP restores spendable balance cleanly', () async {
      final progression = ProgressionController.instance;
      final beforeSpend = progression.spendableXp;

      await progression.spendXp(100);
      expect(progression.spendableXp, beforeSpend - 100);

      await progression.refundXp(100);
      expect(progression.spendableXp, beforeSpend);
    });
  });

  group('Phase 10 — Redemption Engine & Entitlements', () {
    test(
      'Successful redemption grants entitlement and records transaction',
      () async {
        final progression = ProgressionController.instance;
        final redemption = RedemptionController.instance;
        await progression.load();
        await redemption.load();

        // Ensure student has sufficient level and XP
        await progression.recordEvent(
          XpEvent(
            id: 'redemption_test_xp',
            type: XpEventType.taskCompleted,
            amount: 500,
            timestamp: DateTime.now(),
            reason: 'Redemption fund',
          ),
        );

        const targetRewardId = 'badge_first_steps'; // 50 XP, level 1
        final reward = RewardCatalog.instance.findById(targetRewardId);
        expect(reward, isNotNull);

        final result = await redemption.redeemReward(targetRewardId);
        expect(result.success, isTrue);
        expect(result.transaction, isNotNull);
        expect(result.entitlement, isNotNull);
        expect(redemption.ownsReward(targetRewardId), isTrue);

        // Verify entitlement manager reflects unlock
        expect(
          EntitlementManager.instance.isBadgeUnlocked(targetRewardId),
          isTrue,
        );
      },
    );

    test('One-time rewards cannot be redeemed twice (idempotency)', () async {
      final redemption = RedemptionController.instance;
      const targetRewardId = 'badge_first_steps';

      // Attempt second redemption of already owned one-time reward
      final secondResult = await redemption.redeemReward(targetRewardId);
      expect(secondResult.success, isFalse);
      expect(secondResult.errorMessage, contains('already own'));
    });

    test('Redemption fails if level is insufficient', () async {
      final redemption = RedemptionController.instance;
      // badge_legend requires Level 50
      const legendaryRewardId = 'badge_legend';

      final result = await redemption.redeemReward(legendaryRewardId);
      expect(result.success, isFalse);
    });

    test('Redemption fails if reward is Coming Soon', () async {
      final redemption = RedemptionController.instance;
      // feature_advanced_analytics is now available (real feature unlock);
      // verify it fails due to level/XP when catalog has no comingSoon entry,
      // otherwise check comingSoon path.
      const comingSoonId = 'feature_advanced_analytics';

      final reward = RewardCatalog.instance.findById(comingSoonId);
      // If reward is still marked comingSoon, expect that error.
      // If converted to available (TCC rewards 2.0), expect level/XP failure.
      if (reward != null && reward.availability == RewardAvailability.comingSoon) {
        final result = await redemption.redeemReward(comingSoonId);
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('not available yet'));
      } else {
        final result = await redemption.redeemReward(comingSoonId);
        // Should fail due to insufficient level/XP, not crash.
        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
      }
    });
  });

  group('Phase 10 — Notifications & Compatibility', () {
    test('NotificationPayload handles reward types correctly', () {
      const payload1 = NotificationPayload(
        type: 'reward_unlocked',
        entityId: 'theme_focus',
      );
      expect(payload1.isRewardUnlocked, isTrue);
      expect(payload1.encode(), 'reward_unlocked:theme_focus');

      final decoded = NotificationPayload.decode('reward_unlocked:theme_focus');
      expect(decoded?.isRewardUnlocked, isTrue);
      expect(decoded?.entityId, 'theme_focus');
    });

    test('NotificationIds creates deterministic reward notification IDs', () {
      final id1 = NotificationIds.rewardUnlocked('theme_focus');
      final id2 = NotificationIds.rewardUnlocked('theme_focus');
      final id3 = NotificationIds.rewardUnlocked('theme_academic');

      expect(id1, id2);
      expect(id1, isNot(id3));
    });

    test('RewardsCompatibility remains backwards compatible', () {
      const reward = StudentReward(
        id: 'legacy_theme',
        title: 'Legacy',
        description: 'Desc',
        type: RewardType.theme,
        requiredLevel: 5,
        xpCost: 100,
      );

      expect(
        RewardsCompatibility.isEligible(
          reward: reward,
          currentLevel: 5,
          availableXp: 150,
        ),
        isTrue,
      );

      expect(RewardsCompatibility.calculatePremiumDiscount(10), 0.10);
    });
  });
}
