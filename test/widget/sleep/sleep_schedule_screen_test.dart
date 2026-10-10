import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/presentation/sleep_schedule_screen.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/sleep/widgets/sleep_summary_card.dart';

/// P1 — Sleep UI: schedule screen renders all sections, the summary card
/// shows the honest empty state, layouts hold at 360/390dp.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    SleepController.instance.clearData();
  });

  tearDown(() async {
    await SleepController.instance.clearSchedule();
    AuthIsolation.instance.clearSession();
    SleepController.instance.clearData();
  });

  Widget wrap(Widget child, {double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: AppScope(
          controller: AppShellController(),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('SleepScheduleScreen', () {
    testWidgets('renders window, times, days, reminders, save', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const SleepScheduleScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sleep Schedule'), findsWidgets);
      expect(find.text('Bedtime'), findsOneWidget);
      expect(find.text('Wake up'), findsOneWidget);
      expect(find.text('Active days'), findsOneWidget);
      expect(find.text('Bedtime reminder'), findsOneWidget);
      expect(find.text('Wind-down reminder'), findsOneWidget);
      expect(find.text('Save Schedule'), findsOneWidget);
    });

    testWidgets('shows computed overnight duration', (tester) async {
      await tester.pumpWidget(wrap(const SleepScheduleScreen()));
      await tester.pumpAndSettle();

      // Defaults 11:00 PM → 7:00 AM = 8h planned.
      expect(find.text('8h planned'), findsOneWidget);
    });

    testWidgets('no overflow at 360dp and 390dp', (tester) async {
      for (final width in [360.0, 390.0]) {
        await tester.pumpWidget(wrap(const SleepScheduleScreen(), width: width));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('SleepSummaryCard', () {
    testWidgets('empty state invites setup', (tester) async {
      await tester.pumpWidget(wrap(const SleepSummaryCard()));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Set your sleep schedule so Student OS can plan your day around it.',
        ),
        findsOneWidget,
      );
      expect(find.text('Set Sleep Schedule'), findsOneWidget);
    });

    testWidgets('populated card shows window + duration', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('p1_card_user');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      await tester.pumpWidget(wrap(const SleepSummaryCard()));
      await tester.pumpAndSettle();

      expect(find.text('11 PM → 7 AM'), findsOneWidget);
      expect(find.text('8h planned'), findsOneWidget);
    });
  });
}
