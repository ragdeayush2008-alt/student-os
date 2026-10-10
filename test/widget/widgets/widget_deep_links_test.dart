import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/premium/presentation/premium_purchase_screen.dart';
import 'package:student_os/features/premium/services/entitlement_service.dart';
import 'package:student_os/features/tasks/presentation/tasks_screen.dart';
import 'package:student_os/features/widgets/widget_deep_links.dart';

/// Widget deep links through the real router: known targets open, unknown
/// falls back home, logged-out taps park for post-login consumption.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    EntitlementService.instance.clearData();
    AppRouter.pendingWidgetLink = null;
  });

  tearDown(() async {
    AppRouter.pendingWidgetLink = null;
    AuthIsolation.instance.clearSession();
    EntitlementService.instance.clearData();
  });

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        controller: AppShellController(),
        child: MaterialApp(
          theme: AppTheme.dark(),
          navigatorKey: AppRouter.navigatorKey,
          routes: AppRouter.routes(),
          home: const Scaffold(body: Text('host')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('logged-out behavior (no auth bypass)', () {
    testWidgets('tasks tap parks the link and stays home', (tester) async {
      await pumpShell(tester);
      AppRouter.handleWidgetDeepLink('studentos://widget/tasks');
      await tester.pumpAndSettle();
      expect(AppRouter.pendingWidgetLink, 'studentos://widget/tasks');
      expect(find.byType(TasksScreen), findsNothing);
    });

    testWidgets('unknown tap opens home without parking', (tester) async {
      await pumpShell(tester);
      AppRouter.handleWidgetDeepLink('studentos://widget/nope');
      await tester.pumpAndSettle();
      expect(AppRouter.pendingWidgetLink, isNull);
      expect(find.text('host'), findsOneWidget);
    });

    testWidgets('premium tap preserves feature context', (tester) async {
      await pumpShell(tester);
      AppRouter.handleWidgetDeepLink(
        'studentos://widget/premium?feature=premium.focus.deep',
      );
      await tester.pumpAndSettle();
      expect(
        AppRouter.pendingWidgetLink,
        'studentos://widget/premium?feature=premium.focus.deep',
      );
      final parsed = WidgetDeepLinks.parse(AppRouter.pendingWidgetLink);
      expect(parsed.target, WidgetDeepLinkTarget.premium);
      expect(parsed.feature, 'premium.focus.deep');
    });

    testWidgets('premium route renders its contextual header', (
      tester,
    ) async {
      await pumpShell(tester);
      AppRouter.openPremiumPage(
        tester.element(find.text('host')),
        sourceFeatureId: 'premium.focus.deep',
      );
      await tester.pumpAndSettle();
      expect(find.byType(PremiumPurchaseScreen), findsOneWidget);
      expect(find.text('UNLOCK DEEP FOCUS'), findsOneWidget);
    });
  });
}
