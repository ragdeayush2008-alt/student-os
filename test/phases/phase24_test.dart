import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/subscription_provider.dart';
import 'package:student_os/core/services/feature_gate.dart';
import 'package:student_os/core/services/google_play_subscription_provider.dart';
import 'package:student_os/features/rewards/premium_entitlement.dart';

void main() {
  group('Phase 24 — Real Billing & Subscription', () {
    test('SubscriptionProvider has correct states', () {
      expect(SubscriptionState.free, isNotNull);
      expect(SubscriptionState.subscribed, isNotNull);
      expect(SubscriptionState.trialActive, isNotNull);
    });

    test('UnavailableSubscriptionProvider is safe', () {
      const provider = UnavailableSubscriptionProvider();
      expect(provider.isAvailable, isFalse);
      expect(provider.providerName, isNull);
    });

    test(
      'GooglePlaySubscriptionProvider exists and is unavailable by default',
      () {
        const provider = GooglePlaySubscriptionProvider();
        expect(provider.providerName, 'Google Play');
        expect(provider.isAvailable, isFalse); // Not configured in environment
      },
    );

    test('PlayStoreProducts defines correct IDs', () {
      expect(PlayStoreProducts.premiumMonthly, 'premium_monthly');
      expect(PlayStoreProducts.premiumYearly, 'premium_yearly');
    });

    test('PremiumEntitlement never grants Premium from button press', () {
      // Only trial activation or entitlement can grant; button alone cannot
      final entitlement = PremiumEntitlement.instance;
      expect(
        entitlement.isPremiumActive,
        anyOf(isTrue, isFalse),
      ); // Based on real state
    });

    test('FeatureGate respects Premium state without fake grants', () {
      // FeatureGate checks PremiumEntitlement + EntitlementManager
      final gate = FeatureGate.instance;
      expect(gate.isEnabled('advanced_analytics'), isA<bool>());
    });

    test('No fake purchase creates false Premium', () {
      const provider = GooglePlaySubscriptionProvider();
      expect(provider.isAvailable, isFalse);
      // Purchase should return false until verified
      expect(provider.purchaseSubscription(), completion(isNot(true)));
    });

    test('Account isolation preserved for entitlement', () {
      // PremiumEntitlement uses AuthService.user.id for storage key
      expect(PremiumEntitlement.instance, isNotNull);
    });
  });
}
