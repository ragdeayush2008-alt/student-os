import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/premium/presentation/premium_benefits_screen.dart';
import 'package:student_os/features/premium/services/entitlement_service.dart';
import 'package:student_os/features/settings/settings_screen.dart';

/// Developer Tools (debug-only Pro preview) + benefits catalog rendering.
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
        child: AppScope(
          controller: AppShellController(),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('developer tools', () {
    testWidgets('debug build shows DEV ONLY controls', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('prem_dev_ui');
      await EntitlementService.instance.load();

      await tester.pumpWidget(wrap(const SettingsScreen()));
      await tester.pumpAndSettle();

      if (kDebugMode) {
        expect(find.text('DEVELOPER TOOLS'), findsOneWidget);
        expect(find.text('DEV ONLY — UNLOCK PRO'), findsOneWidget);
      } else {
        expect(find.text('Developer Tools'), findsNothing);
        expect(find.textContaining('DEV ONLY'), findsNothing);
      }
    });

    testWidgets('unlock toggles Pro, reset restores Free', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('prem_dev_ui');
      await EntitlementService.instance.load();

      await tester.pumpWidget(wrap(const SettingsScreen()));
      await tester.pumpAndSettle();
      if (!kDebugMode) return;

      await tester.ensureVisible(find.text('DEV ONLY — UNLOCK PRO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DEV ONLY — UNLOCK PRO'));
      await tester.pumpAndSettle();

      expect(EntitlementService.instance.isPro, isTrue);
      expect(find.text('DEV ONLY — RESET TO FREE'), findsOneWidget);

      await tester.tap(find.text('DEV ONLY — RESET TO FREE'));
      await tester.pumpAndSettle();
      expect(EntitlementService.instance.isFree, isTrue);
    });
  });

  group('benefits catalog', () {
    testWidgets('sections and comparison render', (tester) async {
      await tester.pumpWidget(wrap(const PremiumBenefitsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Why Pro'), findsWidgets);
      expect(find.text('Assistant'), findsWidgets);
      expect(find.text('Deep Focus'), findsOneWidget);
      expect(find.text('Free vs Pro'), findsOneWidget);
    });

    testWidgets('no overflow at 360dp and 390dp', (tester) async {
      for (final width in [360.0, 390.0]) {
        await tester.pumpWidget(wrap(const PremiumBenefitsScreen(), width: width));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
