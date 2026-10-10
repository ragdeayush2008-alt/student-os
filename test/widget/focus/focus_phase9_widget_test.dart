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
import 'package:student_os/features/focus/presentation/screens/focus_history_screen.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
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

  group('FocusCenterScreen Phase 9 Dashboard Widget Tests', () {
    testWidgets('renders Focus Hub with momentum stats, quick start presets, and mode action buttons', (tester) async {
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
    });

    testWidgets('tapping Stopwatch mode action button opens stopwatch setup sheet', (tester) async {
      await tester.pumpWidget(wrapWithApp(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stopwatch').first);
      await tester.pumpAndSettle();

      expect(find.text('START STOPWATCH'), findsOneWidget);
      expect(find.text('Count-up timer'), findsOneWidget);

      await tester.tap(find.text('START STOPWATCH'));
      await tester.pumpAndSettle();

      expect(FocusController.instance.hasActiveSession, true);
      expect(FocusController.instance.activeSession?.mode, FocusMode.stopwatch);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('FocusHistoryScreen Phase 9 Widget Tests', () {
    testWidgets('renders summary stats card, filter chips, and history session items', (tester) async {
      FocusController.instance.startQuickFocus(duration: const Duration(minutes: 25));
      FocusController.instance.setPhase(FocusPhase.focusing);
      FocusController.instance.completeSession();

      await tester.pumpWidget(wrapWithApp(const FocusHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Focus & Distraction Stats'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Quick Focus'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
    });
  });

  group('FocusSessionScreen Phase 9 Widget Tests', () {
    testWidgets('displays Focus Guard live status banner during active session', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return true;
        if (call.method == 'hasOverlayPermission') return true;
        return null;
      });

      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
        subjectName: 'Audit & Assurance',
        objective: 'Standards on Auditing (SA 200)',
      );

      await tester.pumpWidget(wrapWithApp(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Audit & Assurance'), findsOneWidget);
      expect(find.text('Standards on Auditing (SA 200)'), findsOneWidget);
      expect(find.text('FOCUS MODE'), findsOneWidget);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
