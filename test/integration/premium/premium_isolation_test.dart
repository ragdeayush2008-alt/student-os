import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/premium/services/entitlement_service.dart';

/// Premium isolation through the real session-change path: dev preview and
/// subscription state never cross users; each login restores its own.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() async {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  EntitlementService entitlement() => EntitlementService.instance;

  Future<void> login(String user) async {
    AuthIsolation.instance.setAuthenticatedUser(user);
    ControllerIsolation.instance.reloadAllControllers(user);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  Future<void> logout() async {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  }

  test('dev preview round-trips per user without leaking', () async {
    await login('prem_p3_a');
    await entitlement().setDevOverride(true);
    expect(entitlement().isPro, isTrue);
    expect(
      entitlement().hasFeatureAccess('premium.focus.strict'),
      isTrue,
    );

    await logout();
    expect(entitlement().isFree, isTrue);

    await login('prem_p3_b');
    expect(entitlement().isFree, isTrue);
    expect(
      entitlement().hasFeatureAccess('premium.focus.strict'),
      isFalse,
    );

    await logout();
    await login('prem_p3_a');
    expect(entitlement().isPro, isTrue);
    expect(
      entitlement().hasFeatureAccess('premium.analytics.advanced'),
      isTrue,
    );
  });

  test('logout clears runtime entitlement immediately', () async {
    await login('prem_p3_a');
    await entitlement().setDevOverride(true);
    expect(entitlement().isPro, isTrue);

    await logout();
    expect(entitlement().isFree, isTrue);
    expect(entitlement().status.name, 'free');
  });
}
