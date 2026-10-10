import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/services/feature_gate.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/theme/theme_variants.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/rewards/premium_entitlement.dart';
import 'package:student_os/features/rewards/recommendation_engine.dart';
import 'package:student_os/features/rewards/redemption_controller.dart';
import 'package:student_os/features/rewards/reward_catalog.dart';
import 'package:student_os/features/rewards/theme_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressionController.instance.load();
    await RedemptionController.instance.load();
    await PremiumEntitlement.instance.load();
    await ThemeManager.instance.load();
  });

  group('Phase 10B — Reward Economy Hardening', () {
    test('RewardTier constants are structured and balanced', () {
      expect(RewardTier.starter, 50);
      expect(RewardTier.starterMax, 250);
      expect(RewardTier.progress, 300);
      expect(RewardTier.progressMax, 600);
      expect(RewardTier.advanced, 700);
      expect(RewardTier.advancedMax, 1000);
      expect(RewardTier.premium, 1100);
      expect(RewardTier.premiumMax, 2000);
      expect(RewardTier.elite, 2500);
      expect(RewardTier.eliteMax, 4000);
    });

    test('Legend badge price has been reduced from 5000 to 3500 XP', () {
      final legend = RewardCatalog.instance.findById('badge_legend');
      expect(legend, isNotNull);
      expect(legend!.xpCost, 3500);
      expect(legend.minimumLevel, 50);
    });

    test('nextUnlockableReward calculates closest goal accurately', () {
      // Level 1, 0 XP -> Should recommend first steps badge (50 XP, level 1)
      final next = RewardCatalog.instance.nextUnlockableReward(1, 0);
      expect(next, isNotNull);
      expect(next!.id, 'badge_first_steps');
    });

    test('rewardsInTier filters rewards by price boundaries', () {
      final starterRewards = RewardCatalog.instance.rewardsInTier(
        minXp: RewardTier.starter,
        maxXp: RewardTier.starterMax,
      );
      expect(starterRewards.isNotEmpty, isTrue);
      for (final r in starterRewards) {
        expect(r.xpCost >= RewardTier.starter, isTrue);
        expect(r.xpCost <= RewardTier.starterMax, isTrue);
      }
    });
  });

  group('Phase 10B — Cosmetic Theme Variants & Entitlement Management', () {
    test('ThemeVariants builds distinct accessible ColorSchemes', () {
      final defaultDark = ThemeVariants.buildColorScheme(
        variant: ThemeVariantId.defaultTheme,
        brightness: Brightness.dark,
      );
      final focusDark = ThemeVariants.buildColorScheme(
        variant: ThemeVariantId.focusDark,
        brightness: Brightness.dark,
      );
      final academicLight = ThemeVariants.buildColorScheme(
        variant: ThemeVariantId.academicLight,
        brightness: Brightness.light,
      );
      final midnightScholar = ThemeVariants.buildColorScheme(
        variant: ThemeVariantId.midnightScholar,
        brightness: Brightness.dark,
      );

      expect(defaultDark.brightness, Brightness.dark);
      expect(focusDark.brightness, Brightness.dark);
      expect(focusDark.primary, const Color(0xFFF59E0B)); // Warm amber
      expect(academicLight.brightness, Brightness.light);
      expect(academicLight.primary, const Color(0xFF1E40AF)); // Oxford blue
      expect(midnightScholar.primary, const Color(0xFF38BDF8)); // Cyan glow
    });

    test('AppTheme.forVariant generates functional ThemeData', () {
      final theme = AppTheme.forVariant(
        Brightness.dark,
        ThemeVariantId.focusDark,
      );
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFF59E0B));
      expect(theme.useMaterial3, isTrue);
    });

    test(
      'ThemeManager denies locked theme and allows unlocked/default',
      () async {
        final tm = ThemeManager.instance;
        // Default theme is always unlocked
        expect(tm.isThemeUnlocked(ThemeVariantId.defaultTheme), isTrue);

        // Focus dark is locked initially
        final focusUnlockedInitial = tm.isThemeUnlocked(
          ThemeVariantId.focusDark,
        );
        expect(focusUnlockedInitial, isFalse);

        // Attempting to set locked theme returns false and keeps default
        final success = await tm.setThemeVariant(ThemeVariantId.focusDark);
        expect(success, isFalse);
        expect(tm.activeVariant, ThemeVariantId.defaultTheme);
      },
    );
  });

  group('Phase 10B — Feature Gates & Premium Entitlements', () {
    test('FeatureGate checks evaluate correctly for baseline and premium', () {
      final gate = FeatureGate.instance;

      // Smart scheduling is locked by default
      final check = gate.checkAccess(FeatureFlags.smartScheduling);
      expect(check.isAccessible, isFalse);
      expect(check.source, FeatureAccessSource.baseline);
    });

    test(
      'Premium trial activates and calculates expiration and days remaining',
      () async {
        final premium = PremiumEntitlement.instance;
        expect(premium.isPremiumActive, isFalse);
        expect(premium.status, PremiumStatus.free);

        // Activate 7-day trial
        final activated = await premium.activateTrial(durationDays: 7);
        expect(activated, isTrue);
        expect(premium.isPremiumActive, isTrue);
        expect(premium.status, PremiumStatus.activeTrial);
        expect(premium.trialDaysRemaining, inInclusiveRange(6, 7));

        // With premium active, FeatureGate now permits access
        final gateCheck = FeatureGate.instance.checkAccess(
          FeatureFlags.advancedAnalytics,
        );
        expect(gateCheck.isAccessible, isTrue);
        expect(gateCheck.source, FeatureAccessSource.premiumSubscription);
      },
    );

    test('Discount calculation scales with level and caps safely', () {
      final premium = PremiumEntitlement.instance;
      expect(premium.computeDiscount(level: 1), 0.0);
      expect(premium.computeDiscount(level: 5), 0.05);
      expect(premium.computeDiscount(level: 10), 0.10);
      expect(premium.computeDiscount(level: 20), 0.15);
      expect(premium.computeDiscount(level: 50), 0.20);
    });
  });

  group('Phase 10B — Recommendation Engine & Personalization', () {
    test('RecommendationEngine delivers contextual recommendations', () {
      final recs = RecommendationEngine.getRecommendations();
      expect(recs.isNotEmpty, isTrue);
      expect(recs.length, lessThanOrEqualTo(4));
    });

    test('Affordable rewards list reflects current spendable XP balance', () {
      final affordable = RecommendationEngine.getAffordableRewards();
      // At 0 XP, affordable should be empty
      expect(affordable, isEmpty);
    });
  });
}
