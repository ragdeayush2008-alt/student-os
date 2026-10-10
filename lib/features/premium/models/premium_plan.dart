import 'package:flutter/foundation.dart';

/// Billing periods in the Student OS plan catalog.
enum BillingPeriod {
  monthly('Monthly', 1),
  quarterly('3 months', 3),
  halfYearly('6 months', 6),
  yearly('Yearly', 12);

  const BillingPeriod(this.label, this.months);
  final String label;
  final int months;
}

/// Future provider product mappings. Internal logic depends ONLY on
/// [PremiumPlan.id]; these mappings are filled when providers connect.
@immutable
class ProviderProductMappings {
  const ProviderProductMappings({
    this.googlePlayProductId,
    this.appStoreProductId,
    this.razorpayPlanId,
  });

  final String? googlePlayProductId;
  final String? appStoreProductId;
  final String? razorpayPlanId;

  Map<String, dynamic> toJson() => {
        'googlePlayProductId': googlePlayProductId,
        'appStoreProductId': appStoreProductId,
        'razorpayPlanId': razorpayPlanId,
      };

  factory ProviderProductMappings.fromJson(Map<String, dynamic> json) {
    return ProviderProductMappings(
      googlePlayProductId: json['googlePlayProductId'] as String?,
      appStoreProductId: json['appStoreProductId'] as String?,
      razorpayPlanId: json['razorpayPlanId'] as String?,
    );
  }
}

/// One Student OS Pro plan. Prices are integer paise (exact math, honest
/// rounding); display strings and savings derive programmatically.
@immutable
class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.name,
    required this.period,
    required this.pricePaise,
    this.currency = 'INR',
    required this.displayPrice,
    required this.periodLabel,
    this.isRecommended = false,
    this.isActive = true,
    this.providerMappings = const ProviderProductMappings(),
  });

  final String id;
  final String name;
  final BillingPeriod period;
  final int pricePaise;
  final String currency;

  /// Exact display price, e.g. `₹79/month`.
  final String displayPrice;

  /// Billing-period label, e.g. `₹199 / 3 months`.
  final String periodLabel;
  final bool isRecommended;
  final bool isActive;
  final ProviderProductMappings providerMappings;

  double get priceRupees => pricePaise / 100.0;

  /// Effective monthly price, e.g. 199/3 = 66.33.
  double get effectiveMonthlyPrice =>
      priceRupees / period.months;

  /// e.g. `₹66.33/month`.
  String get effectiveMonthlyLabel =>
      '₹${effectiveMonthlyPrice.toStringAsFixed(2)}/month';

  /// Savings vs the monthly baseline, or null when not cheaper.
  double? savingsVs(PremiumPlan baseline) {
    if (baseline.pricePaise <= 0) return null;
    final baselineMonthly = baseline.effectiveMonthlyPrice;
    if (baselineMonthly <= 0) return null;
    final ratio =
        (baselineMonthly - effectiveMonthlyPrice) / baselineMonthly;
    if (ratio <= 0) return null;
    return ratio;
  }

  /// e.g. `Save 37%`. Null when there are no real savings to advertise.
  String? savingsLabelVs(PremiumPlan baseline) {
    final ratio = savingsVs(baseline);
    if (ratio == null) return null;
    return 'Save ${(ratio * 100).round()}%';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'period': period.name,
        'pricePaise': pricePaise,
        'currency': currency,
        'displayPrice': displayPrice,
        'periodLabel': periodLabel,
        'isRecommended': isRecommended,
        'isActive': isActive,
        'providerMappings': providerMappings.toJson(),
      };
}

/// Central plan catalog: the ONLY place prices live in the app.
abstract final class PremiumPlanCatalog {
  static const PremiumPlan monthly = PremiumPlan(
    id: 'student_os_pro_monthly',
    name: 'Pro Monthly',
    period: BillingPeriod.monthly,
    pricePaise: 7900,
    displayPrice: '₹79/month',
    periodLabel: '₹79 / month',
  );

  static const PremiumPlan threeMonth = PremiumPlan(
    id: 'student_os_pro_3_month',
    name: 'Pro 3 Months',
    period: BillingPeriod.quarterly,
    pricePaise: 19900,
    displayPrice: '₹199 / 3 months',
    periodLabel: '₹199 / 3 months',
  );

  static const PremiumPlan sixMonth = PremiumPlan(
    id: 'student_os_pro_6_month',
    name: 'Pro 6 Months',
    period: BillingPeriod.halfYearly,
    pricePaise: 34900,
    displayPrice: '₹349 / 6 months',
    periodLabel: '₹349 / 6 months',
  );

  static const PremiumPlan yearly = PremiumPlan(
    id: 'student_os_pro_yearly',
    name: 'Pro Yearly',
    period: BillingPeriod.yearly,
    pricePaise: 59900,
    displayPrice: '₹599/year',
    periodLabel: '₹599 / year',
    isRecommended: true,
  );

  static const List<PremiumPlan> plans = [
    monthly,
    threeMonth,
    sixMonth,
    yearly,
  ];

  static PremiumPlan? byId(String id) =>
      plans.where((p) => p.id == id).firstOrNull;

  /// Monthly baseline for savings math.
  static PremiumPlan get baseline => monthly;
}
