import '../../features/rewards/entitlement_manager.dart';

import 'package:meta/meta.dart';

import '../../features/rewards/premium_entitlement.dart';

/// Feature flag keys for gatable capabilities.
abstract final class FeatureFlags {
  /// Advanced analytics and performance trends.
  static const String advancedAnalytics = 'advanced_analytics';

  /// AI study scheduling and time optimization.
  static const String smartScheduling = 'smart_scheduling';

  /// Premium themes unlock bundle.
  static const String premiumThemes = 'premium_themes';

  /// Unlimited custom tags and organization.
  static const String unlimitedCustomization = 'unlimited_customization';
}

/// Source that granted a feature access.
enum FeatureAccessSource {
  /// Unlocked directly via reward redemption.
  rewardEntitlement('Reward'),

  /// Accessible through active Premium trial or subscription.
  premiumSubscription('Premium'),

  /// Default baseline feature available to all students.
  baseline('Free');

  const FeatureAccessSource(this.label);
  final String label;
}

/// Result of evaluating a feature gate check.
@immutable
class FeatureGateResult {
  const FeatureGateResult({
    required this.isAccessible,
    required this.source,
    this.reason,
  });

  final bool isAccessible;
  final FeatureAccessSource source;
  final String? reason;

  static const FeatureGateResult open = FeatureGateResult(
    isAccessible: true,
    source: FeatureAccessSource.baseline,
  );
}

/// Central feature gate controller for Student OS.
///
/// Decouples feature availability checks across screens from specific entitlement
/// storage mechanisms. Checks both individual reward feature entitlements and
/// active Premium trial/subscription status.
class FeatureGate {
  FeatureGate._();

  static final FeatureGate instance = FeatureGate._();

  /// Checks if a feature flag is accessible for the current student.
  bool isEnabled(String featureFlag) {
    return checkAccess(featureFlag).isAccessible;
  }

  /// Evaluates full access context for a feature flag.
  FeatureGateResult checkAccess(String featureFlag) {
    // 1. Check if user has active Premium access (trial or subscription)
    if (PremiumEntitlement.instance.isPremiumActive ||
        EntitlementManager.instance.hasActivePremium) {
      return const FeatureGateResult(
        isAccessible: true,
        source: FeatureAccessSource.premiumSubscription,
        reason: 'Unlocked with Student OS Premium',
      );
    }

    // 2. Check if student redeemed a specific feature entitlement
    if (EntitlementManager.instance.isFeatureUnlocked(featureFlag)) {
      return const FeatureGateResult(
        isAccessible: true,
        source: FeatureAccessSource.rewardEntitlement,
        reason: 'Unlocked with XP Reward',
      );
    }

    // 3. Feature is currently locked
    return FeatureGateResult(
      isAccessible: false,
      source: FeatureAccessSource.baseline,
      reason: 'Requires Student OS Premium or XP Reward unlock',
    );
  }
}
