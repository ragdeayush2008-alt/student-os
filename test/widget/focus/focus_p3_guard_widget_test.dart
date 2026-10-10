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
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';
import 'package:student_os/features/home/home_screen.dart';

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
      switch (call.method) {
        case 'isSupported':
          return true;
        case 'hasUsageAccess':
          return true;
        case 'hasOverlayPermission':
          return true;
        case 'showFloatingTimer':
          return true;
        case 'hideFloatingTimer':
          return true;
        case 'showFocusOverlay':
          return true;
        case 'hideFocusOverlay':
          return true;
        default:
          return null;
      }
    });

    FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
    FocusGuardController.instance = FocusGuardController(service: FocusGuardService.instance);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FocusGuardController.instance.clearData();
    FocusController.instance.clearData();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: child,
    );
  }

  group('Focus P3 — Home Quick Actions & Guard Polish', () {
    testWidgets('1. Home screen displays the compact CODE 5 Quick Actions', (tester) async {
      await tester.pumpWidget(wrapWithApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Plan Day'), findsWidgets);
      expect(find.text('Study'), findsWidgets);
      expect(find.text('Revise'), findsWidgets);
      expect(find.text('Add Task'), findsWidgets);
      expect(find.text('Exams'), findsWidgets);
      expect(find.text('Ask Student OS'), findsWidgets);
    });

    testWidgets('2. Active Focus Guard UI shows apps protected count and handles pause/resume', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
        blockedPackages: {'com.instagram.android', 'com.google.android.youtube'},
        subjectName: 'Organic Chemistry',
      );
      FocusController.instance.setPhase(FocusPhase.focusing);

      await tester.pumpWidget(wrapWithApp(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Organic Chemistry'), findsOneWidget);
      expect(find.text('PAUSE'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);

      await tester.tap(find.text('PAUSE'));
      await tester.pumpAndSettle();

      expect(FocusController.instance.activeSession?.isPaused, isTrue);
      expect(find.text('RESUME'), findsOneWidget);

      FocusController.instance.endSessionEarly();
      await tester.pumpAndSettle();
    });

    testWidgets('3. Focus Center screen renders 3 modes and navigates to session', (tester) async {
      await tester.pumpWidget(wrapWithApp(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Stopwatch'), findsOneWidget);
    });
  });
}
