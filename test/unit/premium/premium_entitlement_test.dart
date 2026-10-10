import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/premium/models/premium_subscription.dart';
import 'package:student_os/features/premium/services/entitlement_service.dart';

/// Entitlement states: free default, active/expired/cancelled/pending/
// unknown handling, dev preview (debug), corrupt tolerance, isolation.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    EntitlementService.instance.clearData();
  });

  tearDown(() async {
    AuthIsolation.instance.clearSession();
    EntitlementService.instance.clearData();
  });

  EntitlementService entitlement() => EntitlementService.instance;

  Future<void> login(String user) async {
    AuthIsolation.instance.setAuthenticatedUser(user);
    await entitlement().load();
  }

  group('free default', () {
    test('new user is FREE with no access', () async {
      await login('prem_free_user');
      expect(entitlement().isFree, isTrue);
      expect(entitlement().isPro, isFalse);
      expect(entitlement().status, MembershipStatus.free);
      expect(
        entitlement().hasFeatureAccess('premium.focus.deep'),
        isFalse,
      );
    });

    test('unknown feature ids never open', () async {
      await login('prem_free_user');
      expect(entitlement().hasFeatureAccess('premium.nope'), isFalse);
    });

    test('coming-soon features never open, even for Pro', () async {
      await login('prem_free_user');
      await entitlement().setDevOverride(true);
      expect(entitlement().isPro, isTrue);
      expect(
        entitlement().hasFeatureAccess('premium.planning.weekly'),
        isFalse,
      );
      expect(
        entitlement().hasFeatureAccess('premium.widgets'),
        isFalse,
      );
    });
  });

  group('subscription states', () {
    Future<void> apply(PremiumSubscription sub) async {
      await login('prem_state_user');
      await entitlement().applyVerifiedSubscription(sub);
    }

    test('active grants access', () async {
      await apply(const PremiumSubscription(
        userId: 'prem_state_user',
        planId: 'student_os_pro_yearly',
        status: MembershipStatus.active,
        verificationSource: VerificationSource.verified,
      ));
      expect(entitlement().isPro, isTrue);
      expect(
        entitlement().hasFeatureAccess('premium.analytics.advanced'),
        isTrue,
      );
    });

    test('expired locks access', () async {
      await apply(PremiumSubscription(
        userId: 'prem_state_user',
        status: MembershipStatus.expired,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      ));
      expect(entitlement().isPro, isFalse);
      expect(
        entitlement().hasFeatureAccess('premium.focus.deep'),
        isFalse,
      );
    });

    test('cancelled before expiry keeps access; after expiry locks',
        () async {
      await apply(PremiumSubscription(
        userId: 'prem_state_user',
        status: MembershipStatus.cancelledPendingExpiry,
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      ));
      expect(entitlement().isPro, isTrue);

      await apply(PremiumSubscription(
        userId: 'prem_state_user',
        status: MembershipStatus.cancelledPendingExpiry,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      ));
      expect(entitlement().isPro, isFalse);
    });

    test('pending and unknown grant nothing', () async {
      await apply(const PremiumSubscription(
        userId: 'prem_state_user',
        status: MembershipStatus.pending,
      ));
      expect(entitlement().isPro, isFalse);

      await apply(const PremiumSubscription(
        userId: 'prem_state_user',
        status: MembershipStatus.unknown,
      ));
      expect(entitlement().isPro, isFalse);
    });

    test('grace period keeps access', () async {
      await apply(const PremiumSubscription(
        userId: 'prem_state_user',
        status: MembershipStatus.gracePeriod,
      ));
      expect(entitlement().isPro, isTrue);
    });

    test('corrupt stored state degrades to free', () async {
      await login('prem_state_user');
      final restored = PremiumSubscription.fromJson({
        'status': 'not_a_status',
        'provider': 'nope',
      });
      expect(restored.status, MembershipStatus.free);
      expect(restored.grantsProAccess, isFalse);
    });
  });

  group('development preview', () {
    test('debug builds allow the bypass; it is not a purchase', () async {
      expect(EntitlementService.isDevelopmentBypassAvailable, kDebugMode);
      await login('prem_dev_user');
      final ok = await entitlement().setDevOverride(true);
      expect(ok, isTrue);
      expect(entitlement().isPro, isTrue);
      expect(entitlement().isDevelopmentPreview, isTrue);
      expect(
        entitlement().hasFeatureAccess('premium.sleep.awareness'),
        isTrue,
      );
    });

    test('reset restores free', () async {
      await login('prem_dev_user');
      await entitlement().setDevOverride(true);
      expect(entitlement().isPro, isTrue);
      await entitlement().setDevOverride(false);
      expect(entitlement().isFree, isTrue);
      expect(
        entitlement().hasFeatureAccess('premium.sleep.awareness'),
        isFalse,
      );
    });
  });

  group('user isolation', () {
    test('dev preview never leaks across users', () async {
      await login('prem_iso_a');
      await entitlement().setDevOverride(true);
      expect(entitlement().isPro, isTrue);

      AuthIsolation.instance.clearSession();
      EntitlementService.instance.clearData();
      await login('prem_iso_b');
      expect(entitlement().isFree, isTrue);

      AuthIsolation.instance.clearSession();
      EntitlementService.instance.clearData();
      await login('prem_iso_a');
      expect(entitlement().isPro, isTrue);
    });
  });
}
