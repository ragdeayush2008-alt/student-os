import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_guard_card.dart';
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
      home: Scaffold(body: child),
    );
  }

  group('FocusGuardCard Widget Tests', () {
    testWidgets('shows setup card with grant buttons when permissions are missing', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return false;
        if (call.method == 'hasOverlayPermission') return false;
        return null;
      });

      FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
      FocusGuardController.instance = FocusGuardController(service: FocusGuardService.instance);
      await FocusGuardController.instance.refreshPermissions();

      await tester.pumpWidget(wrapWithApp(const FocusGuardCard()));
      await tester.pumpAndSettle();

      expect(find.text('Focus Guard'), findsOneWidget);
      expect(find.text('To protect your focus, Android permissions are required.'), findsOneWidget);
      expect(find.text('Grant Usage Access'), findsOneWidget);
      expect(find.text('Grant Overlay Permission'), findsOneWidget);
    });

    testWidgets('tapping Grant Usage Access shows explanation dialog', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return false;
        if (call.method == 'hasOverlayPermission') return false;
        return null;
      });

      FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
      FocusGuardController.instance = FocusGuardController(service: FocusGuardService.instance);
      await FocusGuardController.instance.refreshPermissions();

      await tester.pumpWidget(wrapWithApp(const FocusGuardCard()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grant Usage Access'));
      await tester.pumpAndSettle();

      expect(find.text('Usage Access Permission'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Usage Access Permission'), findsNothing);
    });

    testWidgets('tapping Grant Overlay Permission shows explanation dialog', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return true;
        if (call.method == 'hasOverlayPermission') return false;
        return null;
      });

      FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
      FocusGuardController.instance = FocusGuardController(service: FocusGuardService.instance);
      await FocusGuardController.instance.refreshPermissions();

      await tester.pumpWidget(wrapWithApp(const FocusGuardCard()));
      await tester.pumpAndSettle();

      expect(find.text('Grant Overlay Permission'), findsOneWidget);

      await tester.tap(find.text('Grant Overlay Permission'));
      await tester.pumpAndSettle();

      expect(find.text('Display Over Other Apps'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('shows Focus Guard Ready when all permissions are granted', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return true;
        if (call.method == 'hasOverlayPermission') return true;
        return null;
      });

      FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
      FocusGuardController.instance = FocusGuardController(service: FocusGuardService.instance);
      await FocusGuardController.instance.refreshPermissions();

      await tester.pumpWidget(wrapWithApp(const FocusGuardCard()));
      await tester.pumpAndSettle();

      expect(find.text('Focus Guard Ready'), findsOneWidget);
      expect(find.textContaining('apps blocked'), findsOneWidget);
    });
  });
}
