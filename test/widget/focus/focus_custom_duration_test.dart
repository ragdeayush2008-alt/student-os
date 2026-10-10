import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';

/// Custom Focus duration: presets, validation errors, cancel, and the
/// engine actually running the chosen duration. Custom stays FREE.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ragdetechnologies.student_os/focus_guard');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.clearUser(userId: 'demo');
    FocusController.instance.clearData();
    FocusGuardController.instance.clearData();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      return null;
    });
    FocusGuardService.instance = FocusGuardService(isAndroidOverride: false);
    FocusGuardController.instance =
        FocusGuardController(service: FocusGuardService.instance);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FocusGuardController.instance.clearData();
    FocusController.instance.clearData();
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        routes: AppRouter.routes(),
        home: const Scaffold(body: Text('host')),
      ),
    );
    await tester.pumpAndSettle();
    AppRouter.openFocusModeSelection(tester.element(find.text('host')));
    await tester.pumpAndSettle();
  }

  Future<void> openCustomDialog(WidgetTester tester) async {
    await openSheet(tester);
    expect(find.text('Custom'), findsOneWidget);
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Custom Duration'), findsOneWidget);
  }

  testWidgets('preset durations are offered', (tester) async {
    await openSheet(tester);
    for (final label in ['15 min', '25 min', '45 min', '60 min', 'Custom']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
  });

  testWidgets('invalid input shows an explicit error, not silence', (
    tester,
  ) async {
    await openCustomDialog(tester);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();
    expect(find.textContaining('between 1 and'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();
    expect(find.textContaining('between 1 and'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();
    expect(find.textContaining('between 1 and'), findsOneWidget);
    // Dialog stays open on invalid input.
    expect(find.text('Custom Duration'), findsOneWidget);
  });

  testWidgets('cancel closes without changing duration', (tester) async {
    await openCustomDialog(tester);
    await tester.enterText(find.byType(TextField), '37');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Custom Duration'), findsNothing);
    expect(find.text('37 min'), findsNothing);
  });

  testWidgets('valid custom duration applies and engine runs it', (
    tester,
  ) async {
    await openCustomDialog(tester);
    await tester.enterText(find.byType(TextField), '37');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();
    expect(find.text('37 min'), findsWidgets);

    // Start a timer session with the custom duration.
    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();
    // Session screen opens; engine holds the 37-minute plan.
    final session = FocusController.instance.activeSession;
    expect(session, isNotNull);
    expect(session!.plannedDuration.inMinutes, 37);
    FocusController.instance.stopSession();
  });

  testWidgets('custom focus is not gated behind premium', (tester) async {
    await openSheet(tester);
    // No PRO badge/paywall on the basic custom-duration path.
    expect(find.text('Custom'), findsOneWidget);
  });
}
