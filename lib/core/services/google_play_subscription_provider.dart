import 'subscription_provider.dart';

/// Google Play Billing provider using existing architecture.
/// Requires `in_app_purchase` package and Play Store product configuration.
/// If platform services unavailable, falls back to unavailable state safely.
class GooglePlaySubscriptionProvider extends SubscriptionProvider {
  const GooglePlaySubscriptionProvider();

  @override
  bool get isAvailable => false; // Set true when Play Billing configured

  @override
  String? get providerName => 'Google Play';

  @override
  Future<void> initialize() async {
    // Real: initialize the Play Billing client.
  }

  @override
  Future<List<String>> loadProducts() async {
    // Real: query Play Console product IDs.
    return const [];
  }

  @override
  Future<bool> loadEntitlement() async {
    // Real implementation: query Google Play for active subscription
    // Requires product IDs configured in Play Console and in_app_purchase plugin
    return false; // Safe unavailable until configured
  }

  @override
  Future<bool> purchaseSubscription() async {
    // Real: start purchase flow for configured product
    return false; // Not granted without verified purchase
  }

  @override
  Future<bool> restorePurchases() async {
    // Real: restore previous purchases, reconcile entitlement
    return false;
  }

  @override
  Future<bool> manageSubscription() async {
    // Real: open Play Store subscription management
    return false;
  }
}

/// Product identifiers for Play Store — must be configured in Play Console.
class PlayStoreProducts {
  static const String premiumMonthly = 'premium_monthly';
  static const String premiumYearly = 'premium_yearly';
  static const String trialWeekly = 'trial_weekly';
}
