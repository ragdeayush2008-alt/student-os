import '../../../core/services/subscription_provider.dart';

/// Razorpay provider stub (P-premium foundation).
///
/// No Razorpay SDK, checkout, or secret is integrated — and none belongs in
/// the Flutter client. Server-side verification must remain outside the
/// mobile trust boundary. Every method reports unavailable until the real
/// integration lands, without touching UI or entitlements.
class RazorpayProvider extends SubscriptionProvider {
  const RazorpayProvider();

  @override
  bool get isAvailable => false;

  @override
  String? get providerName => 'Razorpay';

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

/// Future Razorpay plan mappings (server-created plan IDs go here later).
/// Internal logic must keep depending on [PremiumPlan.id].
abstract final class RazorpayPlans {
  static const String proMonthly = 'student_os_pro_monthly';
  static const String pro3Month = 'student_os_pro_3_month';
  static const String pro6Month = 'student_os_pro_6_month';
  static const String proYearly = 'student_os_pro_yearly';
}
