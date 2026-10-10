import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/screens/focus_center_screen.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.clearUser(userId: 'demo');
    FocusController.instance.clearData();
    ProgressionController.instance.clearData();
    TaskController.instance.clearData();
    SubjectController.instance.clearData();
  });

  tearDown(() {
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

  group('FocusCenterScreen Widget Tests', () {
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

    testWidgets('tapping Timer switches to Timer mode and allows starting timer', (tester) async {
      await tester.pumpWidget(wrapWithApp(const FocusCenterScreen()));
      await tester.pumpAndSettle();

      // Tap Timer segmented pill
      await tester.tap(find.text('Timer').first);
      await tester.pumpAndSettle();

      expect(find.text('START TIMER'), findsOneWidget);
      expect(find.text('Set duration'), findsOneWidget);

      final startTimerBtn = find.text('START TIMER');
      await tester.tap(startTimerBtn);
      await tester.pumpAndSettle();

      expect(FocusController.instance.hasActiveSession, true);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('FocusSessionScreen Widget Tests', () {
    testWidgets('shows empty state when no active session', (tester) async {
      await tester.pumpWidget(wrapWithApp(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No active session'), findsOneWidget);
      expect(find.text('Go to Focus Hub'), findsOneWidget);
    });

    testWidgets('shows active controls, timer and handles pause/resume', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      FocusController.instance.startFocusGuard(duration: const Duration(minutes: 25));
      FocusController.instance.setPhase(FocusPhase.focusing);

      await tester.pumpWidget(wrapWithApp(const FocusSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('PAUSE'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);

      // Tap Pause
      await tester.tap(find.text('PAUSE'));
      await tester.pumpAndSettle();

      expect(FocusController.instance.activeSession?.isPaused, true);
      expect(find.text('RESUME'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('RESUME'));
      await tester.pumpAndSettle();

      expect(FocusController.instance.activeSession?.isPaused, false);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
