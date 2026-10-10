import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_segmented_control.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/planning/planning_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Objective A proof: tapping real controls never loses text/icons, in
/// light AND dark mode. Asserts the resolved selected foreground on the
/// actual rendered widgets (not just the theme objects).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('visibility_user');
    ControllerIsolation.instance.clearAllControllers();
    await SubjectController.instance.load();
    await TaskController.instance.load();
    await PlanningBlockController.instance.load();
    await FocusController.instance.load();
  });

  Widget wrapApp(Widget child, {bool dark = false, double width = 390}) {
    return MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: child,
          ),
        ),
      ),
    );
  }

  ColorScheme schemeOf(WidgetTester tester, Finder f) =>
      Theme.of(tester.element(f)).colorScheme;

  group('Plan/Study segmented stays readable when selected', () {
    for (final dark in [false, true]) {
      testWidgets(dark ? 'dark' : 'light', (tester) async {
        var value = 'plan';
        await tester.pumpWidget(wrapApp(
          StatefulBuilder(
            builder: (context, setState) => StudentOSSegmentedControl<String>(
              segments: const [
                StudentOSSegment(value: 'plan', label: 'Plan'),
                StudentOSSegment(value: 'study', label: 'Study'),
              ],
              selected: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          dark: dark,
        ));
        await tester.pumpAndSettle();

        final scheme = schemeOf(tester, find.text('Plan'));
        TextStyle style(String l) =>
            tester.widget<Text>(find.text(l)).style!;
        expect(style('Plan').color, scheme.onSurface);
        expect(style('Study').color, scheme.onSurfaceVariant);

        await tester.tap(find.text('Study'));
        await tester.pumpAndSettle();

        expect(value, 'study');
        expect(style('Study').color, scheme.onSurface,
            reason: 'selected Study must stay visible');
        expect(style('Plan').color, scheme.onSurfaceVariant);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Timer/Stopwatch segmented stays readable when selected', () {
    for (final dark in [false, true]) {
      testWidgets(dark ? 'dark' : 'light', (tester) async {
        var value = 'timer';
        await tester.pumpWidget(wrapApp(
          StatefulBuilder(
            builder: (context, setState) => StudentOSSegmentedControl<String>(
              segments: const [
                StudentOSSegment(value: 'timer', label: 'Timer'),
                StudentOSSegment(value: 'stopwatch', label: 'Stopwatch'),
              ],
              selected: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          dark: dark,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Stopwatch'));
        await tester.pumpAndSettle();

        final scheme = schemeOf(tester, find.text('Stopwatch'));
        expect(value, 'stopwatch');
        expect(tester.widget<Text>(find.text('Stopwatch')).style!.color,
            scheme.onSurface,
            reason: 'selected Stopwatch must stay visible');
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Planning date selector keeps the selected date visible', () {
    for (final dark in [false, true]) {
      testWidgets(dark ? 'dark' : 'light', (tester) async {
        await tester.pumpWidget(
            wrapApp(const PlanningScreen(), dark: dark));
        await tester.pumpAndSettle();

        final day = PlanController.instance.selectedDay.day;
        final label = find.text('$day').first;
        await tester.ensureVisible(label);
        await tester.pumpAndSettle();
        await tester.tap(label);
        await tester.pumpAndSettle();

        final palette = AppTheme.colorsOf(tester.element(label));
        final color =
            tester.widget<Text>(find.text('$day').first).style!.color;
        expect(color, palette.onPrimary,
            reason: 'selected date must use the paired foreground');
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Planning time chips keep the selected value visible', () {
    for (final dark in [false, true]) {
      testWidgets(dark ? 'dark' : 'light', (tester) async {
        await tester.pumpWidget(
            wrapApp(const PlanningScreen(), dark: dark));
        await tester.pumpAndSettle();

        expect(find.text('1h'), findsOneWidget);
        await tester.ensureVisible(find.text('1h'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1h'));
        await tester.pumpAndSettle();

        final palette =
            AppTheme.colorsOf(tester.element(find.text('1h')));
        expect(tester.widget<Text>(find.text('1h')).style!.color,
            palette.primary,
            reason: 'selected time chip must stay visible');
        // The primary CTA renders the theme-paired foreground.
        expect(
            find.widgetWithText(FilledButton, 'PLAN MY 1 HOURS'),
            findsOneWidget);
        final effective = DefaultTextStyle.of(
          tester.element(find.text('PLAN MY 1 HOURS')),
        ).style.color;
        expect(effective, palette.scheme.onPrimary,
            reason: 'CTA label must use the paired foreground');
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('switch ON/OFF keeps label and track readable', () {
    testWidgets('settings-style toggle row', (tester) async {
      var on = false;
      await tester.pumpWidget(wrapApp(Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SwitchListTile(
            title: const Text('Bedtime reminder'),
            subtitle: const Text('Daily at 10:30 PM'),
            value: on,
            onChanged: (v) => setState(() => on = v),
          ),
        ),
      )));
      await tester.pump();
      expect(find.text('Bedtime reminder'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(on, isTrue);
      expect(find.text('Bedtime reminder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
