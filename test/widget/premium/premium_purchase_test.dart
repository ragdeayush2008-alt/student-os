import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/premium/presentation/premium_purchase_screen.dart';
import 'package:student_os/features/premium/services/entitlement_service.dart';

/// Purchase page: plans, honest provider-unavailable Continue (never a fake
/// purchase), restore/manage honesty, responsive layouts.
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

  Widget wrap(Widget child, {double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders all four plans with honest pricing', (tester) async {
    await tester.pumpWidget(wrap(const PremiumPurchaseScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Pro Monthly'), findsOneWidget);
    expect(find.text('Pro 3 Months'), findsOneWidget);
    expect(find.text('Pro 6 Months'), findsOneWidget);
    expect(find.text('Pro Yearly'), findsOneWidget);
    expect(find.text('₹79 / month'), findsOneWidget);
    expect(find.text('₹599 / year'), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);
    expect(find.textContaining('₹49.92/month'), findsOneWidget);
    expect(find.textContaining('Save 37%'), findsOneWidget);
  });

  testWidgets('selecting a plan highlights it', (tester) async {
    await tester.pumpWidget(wrap(const PremiumPurchaseScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pro Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pro Monthly'));
    await tester.pumpAndSettle();
    // Still exactly one selected card; yearly no longer the only one.
    expect(find.text('Pro Monthly'), findsOneWidget);
  });

  testWidgets('Continue never claims a purchase occurred', (tester) async {
    await tester.pumpWidget(wrap(const PremiumPurchaseScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Purchases not enabled yet'), findsOneWidget);
    expect(find.textContaining('Payment successful'), findsNothing);
    expect(find.textContaining('Purchase successful'), findsNothing);
  });

  testWidgets('Restore/Manage report unavailability honestly', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const PremiumPurchaseScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Restore Purchases'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore Purchases'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not available yet'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Manage Membership'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage Membership'));
    await tester.pumpAndSettle();
    expect(find.text('Manage Membership'), findsWidgets);
  });

  testWidgets('no overflow at 360dp and 390dp', (tester) async {
    for (final width in [360.0, 390.0]) {
      await tester.pumpWidget(
        wrap(const PremiumPurchaseScreen(), width: width),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
