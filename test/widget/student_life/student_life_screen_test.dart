import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/features/student_life/models/student_life_preferences.dart';
import 'package:student_os/features/student_life/presentation/student_life_screen.dart';
import 'package:student_os/features/student_life/student_life_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 30, 9);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    AppClock.freezeAt(now);
  });

  tearDown(() {
    AppClock.reset();
  });

  Future<void> signIn(String userId) async {
    AuthIsolation.instance.setAuthenticatedUser(userId);
    await StudentLifeController.instance.load();
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const StudentLifeScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('StudentLifeScreen — Widget Tests', () {
    testWidgets('I1. renders sleep, study target and routine sections',
        (tester) async {
      await signIn('sl_widget_sections');

      await pumpScreen(tester);

      expect(find.text('Student Life'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('No sleep logged'), findsOneWidget);
      expect(find.text('Study target'), findsOneWidget);
      expect(find.text("Today's routine"), findsOneWidget);
      expect(find.text('Bedtime'), findsOneWidget);
      expect(find.text('Wind down'), findsOneWidget);
    });

    testWidgets('I2. logs a night and shows the real summary', (tester) async {
      await signIn('sl_widget_log');
      await StudentLifeController.instance.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );

      await pumpScreen(tester);

      expect(find.text('No sleep logged'), findsNothing);
      expect(find.text('8h'), findsWidgets);
      expect(find.textContaining('Bedtime 23:00'), findsOneWidget);
    });

    testWidgets('I3. surfaces sleep-protection warnings', (tester) async {
      await signIn('sl_widget_warnings');
      await StudentLifeController.instance.updatePreferences(
        const StudentLifePreferences(targetSleepMinutes: 540),
      );

      await pumpScreen(tester);

      expect(find.text('Protect your sleep'), findsOneWidget);
      expect(
        find.textContaining('shorter than your 9h target'),
        findsOneWidget,
      );
    });

    testWidgets('I4. routine rows can be checked off', (tester) async {
      await signIn('sl_widget_toggle');

      await pumpScreen(tester);

      expect(find.byIcon(Icons.radio_button_unchecked), findsWidgets);

      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(
        StudentLifeController.instance.dailyPlan(now).completedRoutineCount,
        1,
      );
    });

    testWidgets('I5. renders without overflow on a 320dp screen', (tester) async {
      await signIn('sl_widget_320');

      await pumpScreen(tester, size: const Size(320, 640));

      expect(tester.takeException(), isNull);
      expect(find.text('Student Life'), findsOneWidget);
    });

    testWidgets('I6. renders warnings without overflow on a 320dp screen',
        (tester) async {
      await signIn('sl_widget_320_warnings');
      await StudentLifeController.instance.updatePreferences(
        const StudentLifePreferences(
          targetSleepMinutes: 540,
          mealRemindersEnabled: true,
          napEnabled: true,
          exerciseEnabled: true,
        ),
      );

      await pumpScreen(tester, size: const Size(320, 640));

      expect(tester.takeException(), isNull);
      expect(find.text('Protect your sleep'), findsOneWidget);
    });

    testWidgets('I7. renders without overflow on a 430dp screen', (tester) async {
      await signIn('sl_widget_430');

      await pumpScreen(tester, size: const Size(430, 932));

      expect(tester.takeException(), isNull);
    });

    testWidgets('I8. renders without overflow on a wide desktop viewport',
        (tester) async {
      await signIn('sl_widget_desktop');

      await pumpScreen(tester, size: const Size(1280, 900));

      expect(tester.takeException(), isNull);
      expect(find.text('Student Life'), findsOneWidget);
    });

    testWidgets('I9. routine settings sheet opens and edits preferences',
        (tester) async {
      await signIn('sl_widget_settings');

      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Routine settings'), findsOneWidget);

      await tester.tap(find.text('Meal reminders'));
      await tester.pumpAndSettle();

      expect(
        StudentLifeController.instance.preferences.mealRemindersEnabled,
        isTrue,
      );
      expect(find.text('Lunch'), findsWidgets);
    });

    testWidgets('I10. shows an empty routine state with no routine items',
        (tester) async {
      await signIn('sl_widget_empty');
      await StudentLifeController.instance.updatePreferences(
        const StudentLifePreferences(enabled: false),
      );

      await pumpScreen(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
