import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/premium/services/entitlement_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/data/models/focus_guard_models.dart';
import 'package:student_os/features/focus/presentation/screens/blocked_apps_picker_screen.dart';
import 'package:student_os/features/focus/presentation/screens/focus_guard_settings_screen.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ragdetechnologies.student_os/focus_guard');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.clearUser(userId: 'demo');
    FocusController.instance.clearData();
    FocusGuardController.instance.clearData();
    FocusGuardController.instance.resetForTest();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FocusGuardController.instance.stopMonitoring();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: child,
    );
  }

  group('FocusGuardSettingsScreen Widget Tests', () {
    testWidgets('renders guard toggle, blocking modes, and blocked app summary', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return true;
        if (call.method == 'hasOverlayPermission') return true;
        return null;
      });

      FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
      FocusGuardController.instance = FocusGuardController(service: FocusGuardService.instance);
      await FocusGuardController.instance.setBlockedPackages({'com.instagram.android'});

      await tester.pumpWidget(wrapWithApp(const FocusGuardSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Focus Guard Protection'), findsOneWidget);
      expect(find.text('Gentle'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Strict'), findsOneWidget);
      expect(find.text('Select Apps →'), findsOneWidget);

      // Strict is Pro: a Free tap redirects to the paywall, mode unchanged.
      await tester.tap(find.text('Strict'));
      await tester.pumpAndSettle();

      expect(FocusGuardController.instance.mode, isNot(FocusGuardMode.strict));
      expect(find.text('UNLOCK STRICT FOCUS'), findsOneWidget);
    });

    testWidgets('pro users can select Strict mode', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return true;
        if (call.method == 'hasOverlayPermission') return true;
        return null;
      });

      FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
      FocusGuardController.instance = FocusGuardController(service: FocusGuardService.instance);

      AuthIsolation.instance.setAuthenticatedUser('prem_focus_pro');
      await EntitlementService.instance.load();
      await EntitlementService.instance.setDevOverride(true);

      await tester.pumpWidget(wrapWithApp(const FocusGuardSettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Strict'));
      await tester.pumpAndSettle();

      expect(FocusGuardController.instance.mode, FocusGuardMode.strict);

      await EntitlementService.instance.setDevOverride(false);
      AuthIsolation.instance.clearSession();
      EntitlementService.instance.clearData();
    });
  });

  group('BlockedAppsPickerScreen Widget Tests', () {
    testWidgets('allows searching and toggling apps to block', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'getInstalledApps') {
          return [
            {
              'packageName': 'com.instagram.android',
              'label': 'Instagram',
              'isSystemApp': false,
            },
            {
              'packageName': 'com.google.android.youtube',
              'label': 'YouTube',
              'isSystemApp': false,
            },
          ];
        }
        return null;
      });

      FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
      FocusGuardController.instance = FocusGuardController(service: FocusGuardService.instance);
      await FocusGuardController.instance.loadInstalledApps();

      await tester.pumpWidget(wrapWithApp(const BlockedAppsPickerScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);

      // Toggle Instagram
      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();

      expect(FocusGuardController.instance.blockedPackages.contains('com.instagram.android'), true);

      // Search for YouTube
      await tester.enterText(find.byType(TextField), 'YouTube');
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((w) => w is Text && w.data == 'YouTube'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Instagram'), findsNothing);
    });
  });
}
