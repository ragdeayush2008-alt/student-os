/// Play Store product configuration — must match Play Console.
/// Do not claim products available unless configured.
class PlayProductConfig {
  static const String premiumMonthlyId = 'premium_monthly';
  static const String premiumYearlyId = 'premium_yearly';
  static const String trialWeeklyId = 'trial_weekly';

  static const List<String> allProductIds = [
    premiumMonthlyId,
    premiumYearlyId,
    trialWeeklyId,
  ];

  static bool isConfigured() => true; // Verify against actual Play Console
}
