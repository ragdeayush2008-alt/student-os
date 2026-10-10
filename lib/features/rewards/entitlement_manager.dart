import '../../data/models/entitlement.dart';
import 'redemption_controller.dart';

/// Manages and queries active student entitlements.
///
/// Provides convenient helper methods to check feature flags, unlocked themes,
/// and premium status across the app.
class EntitlementManager {
  EntitlementManager._();

  static final EntitlementManager instance = EntitlementManager._();

  /// Checks if a feature entitlement is currently active.
  bool isFeatureUnlocked(String featureFlag) {
    final entitlements = RedemptionController.instance.activeEntitlements;
    return entitlements.any(
      (e) =>
          e.type == EntitlementType.feature &&
          e.metadata?['featureFlag'] == featureFlag,
    );
  }

  /// Checks if a theme is unlocked by the student.
  bool isThemeUnlocked(String themeId) {
    final entitlements = RedemptionController.instance.activeEntitlements;
    return entitlements.any(
      (e) =>
          e.type == EntitlementType.theme && e.metadata?['themeId'] == themeId,
    );
  }

  /// Checks if a badge is owned by the student.
  bool isBadgeUnlocked(String rewardId) {
    return RedemptionController.instance.ownsReward(rewardId);
  }

  /// Gets all active unlocked themes.
  List<String> get unlockedThemes {
    final entitlements = RedemptionController.instance.activeEntitlements;
    return entitlements
        .where(
          (e) =>
              e.type == EntitlementType.theme && e.metadata?['themeId'] != null,
        )
        .map((e) => e.metadata!['themeId'] as String)
        .toList();
  }

  /// Gets all unlocked badges.
  List<StudentEntitlement> get unlockedBadges {
    final entitlements = RedemptionController.instance.activeEntitlements;
    return entitlements.where((e) => e.type == EntitlementType.badge).toList();
  }

  /// Checks if the student has any active premium entitlement.
  bool get hasActivePremium {
    final entitlements = RedemptionController.instance.activeEntitlements;
    return entitlements.any((e) => e.type == EntitlementType.premium);
  }

  /// Gets the highest available premium discount percentage for the student.
  double get premiumDiscountPercent {
    final entitlements = RedemptionController.instance.activeEntitlements;
    final discountEntitlements = entitlements.where(
      (e) => e.type == EntitlementType.discount,
    );

    double maxDiscount = 0.0;
    for (final e in discountEntitlements) {
      final percent =
          (e.metadata?['discountPercent'] as num?)?.toDouble() ?? 0.0;
      if (percent > maxDiscount) {
        maxDiscount = percent;
      }
    }
    return maxDiscount;
  }
}
