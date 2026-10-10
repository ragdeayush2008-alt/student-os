import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/premium/presentation/membership_screen.dart';
import 'package:student_os/features/premium/services/entitlement_service.dart';

/// Membership screen: FREE explores, PRO (dev preview) shows status with
/// no fabricated payment data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    EntitlementService.instance.clearData();
  });

  tearDown(() async {
    AuthIsolation.instance.clearSession();
    EntitlementService.instance.clearData();
  });

  Widget wrap({double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: const Scaffold(body: MembershipScreen()),
      ),
    );
  }

  testWidgets('free user sees explore entry', (tester) async {
    AuthIsolation.instance.setAuthenticatedUser('prem_mem_free');
    await EntitlementService.instance.load();

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('STUDENT OS FREE'), findsOneWidget);
    expect(find.text('Explore Student OS Pro'), findsOneWidget);
  });

  testWidgets('dev-pro shows status without fake payment data', (
    tester,
  ) async {
    AuthIsolation.instance.setAuthenticatedUser('prem_mem_pro');
    await EntitlementService.instance.load();
    await EntitlementService.instance.setDevOverride(true);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('STUDENT OS PRO'), findsOneWidget);
    expect(find.text('Development preview'), findsOneWidget);
    expect(
      find.text('Local preview for development — not a purchase.'),
      findsOneWidget,
    );
    expect(find.text('View Benefits'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);
    expect(find.text('Manage Membership'), findsOneWidget);
    // No renewal/payment fiction anywhere.
    expect(find.textContaining('renews'), findsNothing);
    expect(find.textContaining('charged'), findsNothing);
  });

  testWidgets('no overflow at 360dp and 390dp', (tester) async {
    AuthIsolation.instance.setAuthenticatedUser('prem_mem_free');
    await EntitlementService.instance.load();
    for (final width in [360.0, 390.0]) {
      await tester.pumpWidget(wrap(width: width));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
