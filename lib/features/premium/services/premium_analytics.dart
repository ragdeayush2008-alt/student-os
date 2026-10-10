import 'package:flutter/foundation.dart';

/// Premium product analytics foundation (no network, no SDK).
///
/// Event names are centralized so future provider integration only needs to
/// attach a sink here. Until then every call is a debug log — and
/// purchase-verified events must never fire without real verification.
abstract final class PremiumAnalytics {
  static const String catalogViewed = 'premium_catalog_viewed';
  static const String featureViewed = 'premium_feature_viewed';
  static const String paywallViewed = 'premium_paywall_viewed';
  static const String planSelected = 'premium_plan_selected';
  static const String checkoutStarted = 'premium_checkout_started';
  static const String purchaseVerified = 'premium_purchase_verified';
  static const String purchaseFailed = 'premium_purchase_failed';
  static const String restoreStarted = 'premium_restore_started';
  static const String restoreCompleted = 'premium_restore_completed';
  static const String subscriptionExpired = 'premium_subscription_expired';

  static void log(String event, {Map<String, String>? params}) {
    if (kDebugMode) {
      debugPrint('[PremiumAnalytics] $event ${params ?? const {}}');
    }
  }

  /// Guarded: only a verified provider integration may record this.
  /// Asserts in debug to catch accidental misuse during development.
  static void logVerifiedPurchase({required String planId}) {
    assert(
      false,
      'premium_purchase_verified must never fire without a real provider. '
      'No provider is connected.',
    );
    if (kDebugMode) {
      debugPrint(
        '[PremiumAnalytics] BLOCKED $purchaseVerified (no provider) plan=$planId',
      );
    }
  }
}
