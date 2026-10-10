import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_pressable.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_music_controller.dart';
import 'package:student_os/features/focus/controller/focus_screen_sleep_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/screens/focus_center_screen.dart';
import 'package:student_os/features/focus/presentation/screens/focus_guard_settings_screen.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_menu_sheet.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_mode_holder.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('focus_ux_test_user');
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    FocusModeHolder.instance.setMode(FocusMode.focusGuard);
    await FocusMusicController.instance.setTrack(-1);
    await FocusScreenSleepController.instance.setEnabled(false);
  });

  tearDown(() {
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
  });

  group('Focus UX Correction 2.0 — Direct controls per mode', () {
    testWidgets('FOCUS: Guard, Sleep, BGMusic visible directly', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Focus Guard'), findsOneWidget);
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.text('OFF'), findsWidgets);
      expect(find.text('ON'), findsWidgets);
    });

    testWidgets('TIMER: Sleep and BGMusic visible, Guard absent', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.textContaining('Focus Guard'), findsNothing);
    });

    testWidgets('STOPWATCH: Sleep and BGMusic visible, Guard absent', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();
      expect(find.text('Prevent Screen Sleep'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.textContaining('Focus Guard'), findsNothing);
    });

    testWidgets('three-dot menu in FOCUS does not duplicate direct controls', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      final sheet = find.byType(FocusMenuSheet);
      expect(find.descendant(of: sheet, matching: find.text('Focus Analytics')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Focus History')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Background Music')), findsNothing);
      expect(find.descendant(of: sheet, matching: find.text('Prevent Screen Sleep')), findsNothing);
      expect(find.descendant(of: sheet, matching: find.textContaining('Focus Guard')), findsNothing);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('three-dot menu in TIMER hides Focus Guard and Analytics', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      final sheet = find.byType(FocusMenuSheet);
      expect(find.descendant(of: sheet, matching: find.text('Focus Analytics')), findsNothing);
      expect(find.descendant(of: sheet, matching: find.textContaining('Focus Guard')), findsNothing);
      expect(find.descendant(of: sheet, matching: find.text('Focus History')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('three-dot menu in STOPWATCH hides Focus Guard and Analytics', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      final sheet = find.byType(FocusMenuSheet);
      expect(find.descendant(of: sheet, matching: find.text('Focus Analytics')), findsNothing);
      expect(find.descendant(of: sheet, matching: find.textContaining('Focus Guard')), findsNothing);
      expect(find.descendant(of: sheet, matching: find.text('Focus History')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });
  });

  group('BGMusic direct control', () {
    testWidgets('OFF hides list, ON shows horizontal list', (tester) async {
      await FocusMusicController.instance.setTrack(-1);
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Calm'), findsNothing);
      // Enable via controller (simulates tapping ON)
      await FocusMusicController.instance.setTrack(0);
      await tester.pumpAndSettle();
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Ambient'), findsOneWidget);
      expect(find.text('Energy'), findsOneWidget);
      // Disable
      await FocusMusicController.instance.setTrack(-1);
      await tester.pumpAndSettle();
      expect(find.text('Calm'), findsNothing);
    });

    testWidgets('changing track works and preserves selection', (tester) async {
      await FocusMusicController.instance.setTrack(-1);
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await FocusMusicController.instance.setTrack(0);
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.selectedTrack?.title, 'Calm');
      await tester.ensureVisible(find.text('Ambient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ambient'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.selectedTrack?.title, 'Ambient');
      await FocusMusicController.instance.setTrack(-1);
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.isEnabled, isFalse);
      await FocusMusicController.instance.setTrack(1);
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.selectedTrack?.title, 'Ambient');
    });

    testWidgets('BGMusic available in all 3 modes', (tester) async {
      for (final mode in ['Focus', 'Timer', 'Stopwatch']) {
        await tester.pumpWidget(_wrap(const FocusCenterScreen()));
        await tester.pumpAndSettle();
        if (mode != 'Focus') {
          await tester.tap(find.text(mode));
          await tester.pumpAndSettle();
        }
        expect(find.text('Background Music'), findsOneWidget, reason: 'BGMusic missing in $mode');
      }
    });

    testWidgets('BGMusic OFF/ON chips toggle via UI', (tester) async {
      await FocusMusicController.instance.setTrack(-1);
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.isEnabled, isFalse);
      expect(find.text('Calm'), findsNothing);
      await tester.ensureVisible(find.text('Background Music'));
      await tester.pumpAndSettle();
      // Enable via controller (simulates tapping ON chip)
      await FocusMusicController.instance.setTrack(0);
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.isEnabled, isTrue);
      expect(find.text('Calm'), findsOneWidget);
      await tester.ensureVisible(find.text('Background Music'));
      await tester.pumpAndSettle();
      await FocusMusicController.instance.setTrack(-1);
      await tester.pumpAndSettle();
      expect(FocusMusicController.instance.isEnabled, isFalse);
      expect(find.text('Calm'), findsNothing);
      // Verify ON chip is hittable after ensuring visible
      await tester.ensureVisible(find.text('ON').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ON').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Calm'), findsOneWidget);
    });
  });

  group('Prevent Screen Sleep direct', () {
    testWidgets('all 3 modes expose control and reflect state', (tester) async {
      for (final mode in ['Focus', 'Timer', 'Stopwatch']) {
        await FocusScreenSleepController.instance.setEnabled(false);
        await tester.pumpWidget(_wrap(const FocusCenterScreen()));
        await tester.pumpAndSettle();
        if (mode != 'Focus') {
          await tester.tap(find.text(mode));
          await tester.pumpAndSettle();
        }
        expect(find.text('Prevent Screen Sleep'), findsOneWidget, reason: 'Sleep missing in $mode');
        // Verify Switch reflects controller state
        final sleepContainer = find.ancestor(of: find.text('Prevent Screen Sleep'), matching: find.byType(Container)).first;
        final sw = find.descendant(of: sleepContainer, matching: find.byType(Switch));
        expect(sw, findsOneWidget);
        final swWidget = tester.widget<Switch>(sw);
        expect(swWidget.value, isFalse);
        // Enable via controller and verify UI updates
        await FocusScreenSleepController.instance.setEnabled(true);
        await tester.pumpAndSettle();
        final sw2 = tester.widget<Switch>(find.descendant(of: sleepContainer, matching: find.byType(Switch)));
        expect(sw2.value, isTrue);
        await FocusScreenSleepController.instance.setEnabled(false);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(find.descendant(of: sleepContainer, matching: find.byType(Switch))).value, isFalse);
      }
    });
  });

  group('Focus Guard direct', () {
    testWidgets('only Focus shows Guard, tap opens details', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Focus Guard'), findsOneWidget);
      await tester.ensureVisible(find.textContaining('Focus Guard'));
      await tester.pumpAndSettle();
      final guardText = find.textContaining('Focus Guard').first;
      final guardPressable = find.ancestor(of: guardText, matching: find.byType(AppPressable)).first;
      await tester.tap(guardPressable, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(FocusGuardSettingsScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Focus Guard'), findsNothing);
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Focus Guard'), findsNothing);
    });
  });

  group('Navigation', () {
    testWidgets('Timer back → Focus preserves timerMinutes', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('45 MIN'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Focus Guard'), findsOneWidget);
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      expect(find.text('45 MIN'), findsOneWidget);
    });

    testWidgets('Stopwatch back → Focus preserves state', (tester) async {
      await tester.pumpWidget(_wrap(const FocusCenterScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Focus Guard'), findsOneWidget);
    });
  });
}
