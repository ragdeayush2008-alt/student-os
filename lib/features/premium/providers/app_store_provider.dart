import '../../../core/services/subscription_provider.dart';

/// Apple StoreKit provider stub (P-premium foundation).
///
/// No StoreKit SDK is integrated and no purchase code exists yet. Every
/// method reports unavailable so the entitlement system degrades honestly.
/// Future integration fills these in without touching UI or entitlements.
class AppleStoreKitProvider extends SubscriptionProvider {
  const AppleStoreKitProvider();

  @override
  bool get isAvailable => false;

  @override
  String? get providerName => 'App Store';

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

/// Future Apple product mappings. Internal logic must keep depending on
/// [PremiumPlan.id]; these are filled when App Store Connect products exist.
abstract final class AppStoreProducts {
  static const String proMonthly = 'student_os_pro_monthly';
  static const String pro3Month = 'student_os_pro_3_month';
  static const String pro6Month = 'student_os_pro_6_month';
  static const String proYearly = 'student_os_pro_yearly';
}
