/// Provider-independent billing/subscription interface.
/// Ready for real provider integration. Never grants Premium on button press.
abstract class SubscriptionProvider {
  const SubscriptionProvider();

  /// Prepares the provider SDK. No-op until a real provider connects.
  Future<void> initialize();

  /// Loads available product IDs from the provider. Empty until configured.
  Future<List<String>> loadProducts();

  Future<bool> loadEntitlement();
  Future<bool> purchaseSubscription();
  Future<bool> restorePurchases();
  Future<bool> manageSubscription();
  bool get isAvailable;
  String? get providerName;
}

/// Safe unavailable fallback when no billing provider is configured.
class UnavailableSubscriptionProvider extends SubscriptionProvider {
  const UnavailableSubscriptionProvider();

  @override
  bool get isAvailable => false;

  @override
  String? get providerName => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<String>> loadProducts() async => const [];

  @override
  Future<bool> loadEntitlement() async => false;

  @override
  Future<bool> purchaseSubscription() async => false;

  @override
  Future<bool> restorePurchases() async => false;

  @override
  Future<bool> manageSubscription() async => false;
}

/// Enum for subscription state derived from authoritative data.
enum SubscriptionState {
  free,
  trialActive,
  trialExpired,
  subscribed,
  cancelled,
  unknown,
}
