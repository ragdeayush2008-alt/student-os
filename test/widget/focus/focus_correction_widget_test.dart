import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/screens/focus_center_screen.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ragdetechnologies.student_os/focus_guard');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.clearUser(userId: 'demo');
    FocusController.instance.clearData();
    FocusGuardController.instance.clearData();
    SubjectController.instance.clearData();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'isSupported':
          return true;
        case 'hasUsageAccess':
          return true;
        case 'hasOverlayPermission':
          return true;
        default:
          return null;
      }
    });

    FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
    FocusGuardController.instance =
        FocusGuardController(service: FocusGuardService.instance);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FocusGuardController.instance.clearData();
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: child,
    );
  }

  group('Focus Correction Pass — Widget & Render Tests', () {
    testWidgets('1. No active session renders Focus Center with momentum stats, quick start presets, and mode action buttons', (tester) async {
      await SubjectController.instance.createSubject(name: 'Audit & Assurance');

      await tester.pumpWidget(wrapWithApp(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);

      // Quick Start Presets
      expect(find.text('Sprint'), findsOneWidget);
      expect(find.text('Deep Focus'), findsOneWidget);
      expect(find.text('Deep Work'), findsOneWidget);

      // Mode Action buttons
      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Stopwatch'), findsOneWidget);

      // No active session indicators
      expect(find.text('General'), findsNothing);
      expect(find.text('Preparing...'), findsNothing);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('2. Selecting Timer opens Timer setup and starts countdown session', (tester) async {
      await tester.pumpWidget(wrapWithApp(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      // Tap Timer segmented pill
      await tester.tap(find.text('Timer').first);
      await tester.pumpAndSettle();

      expect(find.text('START TIMER'), findsOneWidget);
      expect(find.text('Set duration'), findsOneWidget);

      // Tap Start Timer
      await tester.tap(find.text('START TIMER'));
      await tester.pumpAndSettle();

      expect(FocusController.instance.hasActiveSession, true);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Selecting Stopwatch opens Stopwatch setup and starts count-up session', (tester) async {
      await tester.pumpWidget(wrapWithApp(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      // Tap Stopwatch segmented pill
      await tester.tap(find.text('Stopwatch').first);
      await tester.pumpAndSettle();

      expect(find.text('START STOPWATCH'), findsOneWidget);
      expect(find.text('Count-up timer'), findsOneWidget);

      await tester.tap(find.text('START STOPWATCH'));
      await tester.pumpAndSettle();

      expect(FocusController.instance.hasActiveSession, true);
      expect(FocusController.instance.activeSession!.mode, FocusMode.stopwatch);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
