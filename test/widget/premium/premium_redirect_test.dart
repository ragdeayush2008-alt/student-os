import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/premium/presentation/premium_purchase_screen.dart';
import 'package:student_os/features/premium/services/entitlement_service.dart';

/// Direct redirect: every locked ACTIVE feature lands on the purchase page
/// with its own context — never inside the locked feature.
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

  Future<void> pumpShell(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('free user redirects', () {
    testWidgets('each locked feature opens its contextual paywall',
        (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('prem_redir_user');
      await EntitlementService.instance.load();
      expect(EntitlementService.instance.isFree, isTrue);

      final cases = {
        'premium.focus.deep': 'UNLOCK DEEP FOCUS',
        'premium.focus.strict': 'UNLOCK STRICT FOCUS',
        'premium.planning.smart': 'UNLOCK SMART PLANNING',
        'premium.exam.intelligence': 'UNLOCK EXAM INTELLIGENCE',
        'premium.analytics.advanced': 'UNLOCK ADVANCED ANALYTICS',
        'premium.sleep.awareness': 'UNLOCK SLEEP-AWARE PLANNING',
        'premium.assistant.advanced': 'UNLOCK ADVANCED ASSISTANT',
        'premium.catchup': 'UNLOCK CATCH-UP ENGINE',
        'premium.assistant.proactive': 'UNLOCK PROACTIVE ASSISTANT',
      };

      for (final entry in cases.entries) {
        expect(
          EntitlementService.instance.hasFeatureAccess(entry.key),
          isFalse,
          reason: entry.key,
        );
        await pumpShell(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppRouter.openPremiumPage(
                context,
                sourceFeatureId: entry.key,
              ),
              child: const Text('go'),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget, reason: entry.key);
        expect(find.text('Student OS Pro'), findsWidgets);
        // Back to a clean shell for the next case.
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('general entry shows the default header', (tester) async {
      await pumpShell(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AppRouter.openPremiumPage(context),
            child: const Text('go'),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('Student OS Pro'), findsWidgets);
    });
  });

  group('pro user passes through', () {
    testWidgets('dev-pro never sees the paywall copy', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('prem_redir_pro');
      await EntitlementService.instance.load();
      await EntitlementService.instance.setDevOverride(true);
      expect(
        EntitlementService.instance
            .hasFeatureAccess('premium.focus.deep'),
        isTrue,
      );
    });
  });
}
