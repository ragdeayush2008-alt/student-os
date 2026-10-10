import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/presentation/screens/focus_guard_settings_screen.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';

/// Focus Guard permission setup: the settings screen must offer a real path
/// to grant usage access + overlay (system settings deep-links), instead of
/// leaving "Setup Needed" permanently stuck.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ragdetechnologies.student_os/focus_guard');

  var usageGranted = true;
  var overlayGranted = true;
  final opened = <String>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    usageGranted = true;
    overlayGranted = true;
    opened.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'isSupported':
          return true;
        case 'hasUsageAccess':
          return usageGranted;
        case 'hasOverlayPermission':
          return overlayGranted;
        case 'openUsageAccessSettings':
          opened.add('usage');
          return true;
        case 'openOverlaySettings':
          opened.add('overlay');
          return true;
      }
      return null;
    });
    FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
    FocusGuardController.instance =
        FocusGuardController(service: FocusGuardService.instance);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FocusGuardController.instance.stopMonitoring();
  });

  Widget wrap() {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: const FocusGuardSettingsScreen(),
    );
  }

  testWidgets('all granted shows confirmation, no setup buttons', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Permissions granted'), findsOneWidget);
    expect(find.text('Setup needed'), findsNothing);
  });

  testWidgets('missing usage access offers the settings deep-link', (
    tester,
  ) async {
    usageGranted = false;
    overlayGranted = false;

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Setup needed'), findsOneWidget);
    expect(find.text('App usage access'), findsOneWidget);
    expect(find.text('Display over other apps'), findsOneWidget);

    // Tapping opens the system usage-access screen.
    await tester.tap(find.text('Open Settings').first);
    await tester.pumpAndSettle();
    expect(opened, contains('usage'));
  });

  testWidgets('granting in settings clears setup after recheck', (
    tester,
  ) async {
    usageGranted = false;
    overlayGranted = false;

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('Setup needed'), findsOneWidget);

    // User grants both in system settings, then taps Recheck.
    usageGranted = true;
    overlayGranted = true;
    await tester.tap(find.text('Recheck'));
    await tester.pumpAndSettle();

    expect(find.text('Permissions granted'), findsOneWidget);
    expect(find.text('Setup needed'), findsNothing);
  });

  testWidgets('overlay-only missing keeps usage step done', (tester) async {
    usageGranted = true;
    overlayGranted = false;

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Setup needed'), findsOneWidget);
    // Two "Open Settings" buttons would mean usage regressed; only the
    // overlay step should offer one.
    expect(find.text('Open Settings'), findsOneWidget);
  });
}
