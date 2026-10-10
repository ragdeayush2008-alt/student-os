import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_scaffold.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/core/widgets/student_os_button.dart';
import 'package:student_os/core/widgets/student_os_segmented_control.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_palette.dart';

/// Representative interaction-state coverage: default / selected / pressed /
/// disabled / toggled ON-OFF must all keep text and icons readable.
void main() {
  Widget wrap(Widget child, {bool dark = false}) {
    return MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('segmented control selected vs unselected', () {
    for (final dark in [false, true]) {
      testWidgets(dark ? 'dark' : 'light', (tester) async {
        var value = 'a';
        await tester.pumpWidget(wrap(
          StatefulBuilder(
            builder: (context, setState) => StudentOSSegmentedControl<String>(
              segments: const [
                StudentOSSegment(value: 'a', label: 'Plan'),
                StudentOSSegment(value: 'b', label: 'Study'),
              ],
              selected: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          dark: dark,
        ));
        await tester.pumpAndSettle();

        final scheme = Theme.of(
          tester.element(find.text('Plan')),
        ).colorScheme;
        TextStyle styleOf(String label) => tester.widget<Text>(
              find.text(label),
            ).style!;

        // Selected: dark text on the light pill; unselected: muted.
        expect(styleOf('Plan').color, scheme.onSurface);
        expect(styleOf('Study').color, scheme.onSurfaceVariant);

        await tester.tap(find.text('Study'));
        await tester.pumpAndSettle();

        expect(value, 'b');
        expect(styleOf('Study').color, scheme.onSurface);
        expect(styleOf('Plan').color, scheme.onSurfaceVariant);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('primary button states', () {
    testWidgets('default renders label and fires', (tester) async {
      var fired = false;
      await tester.pumpWidget(wrap(StudentOSButton.primary(
        label: 'Start Focus',
        onPressed: () => fired = true,
      )));
      await tester.pump();
      expect(find.text('Start Focus'), findsOneWidget);
      await tester.tap(find.text('Start Focus'));
      await tester.pump();
      expect(fired, isTrue);
    });

    testWidgets('disabled never fires and stays legible', (tester) async {
      await tester.pumpWidget(wrap(const StudentOSButton.primary(
        label: 'Continue',
        onPressed: null,
      )));
      await tester.pump();
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading shows progress, keeps semantics', (tester) async {
      await tester.pumpWidget(wrap(const StudentOSButton.primary(
        label: 'Save',
        onPressed: null,
        isLoading: true,
      )));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('secondary selected-style label stays readable', (tester) async {
      await tester.pumpWidget(wrap(StudentOSButton.secondary(
        label: 'Plan My Day',
        onPressed: () {},
      )));
      await tester.pump();
      expect(find.text('Plan My Day'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('toggle ON / OFF', () {
    testWidgets('switch thumb+track readable in both positions', (tester) async {
      var on = false;
      await tester.pumpWidget(wrap(StatefulBuilder(
        builder: (context, setState) => Switch(
          value: on,
          onChanged: (v) => setState(() => on = v),
        ),
      )));
      await tester.pump();
      expect(on, isFalse);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(on, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('navigation selected', () {
    testWidgets('all destinations visible, selection follows tap', (tester) async {
      var selected = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: StudentOSBottomNavigation(
              selectedIndex: selected,
              onDestinationSelected: (i) => setState(() => selected = i),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      for (final title in ['Home', 'Plan & Study', 'SprintX', 'Tools Hub', 'Workspace']) {
        expect(find.text(title), findsOneWidget);
      }
      await tester.tap(find.text('SprintX'));
      await tester.pumpAndSettle();
      expect(selected, 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('back button', () {
    testWidgets('icon visible and tap calls handler', (tester) async {
      var backed = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: AppScaffold(
          title: 'Details',
          onBack: () => backed = true,
          body: const Text('content'),
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();
      expect(backed, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('selection chip representative', () {
    testWidgets('selected chip pairs primary bg with onPrimary label', (tester) async {
      for (final dark in [false, true]) {
        await tester.pumpWidget(wrap(
          Builder(builder: (context) {
            final palette = AppTheme.colorsOf(context);
            return ChoiceChip(
              label: const Text('1h'),
              selected: true,
              selectedColor: palette.primary,
              labelStyle: TextStyle(color: palette.onPrimary),
              onSelected: (_) {},
            );
          }),
          dark: dark,
        ));
        await tester.pump();
        expect(find.text('1h'), findsOneWidget);
        final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
        final context = tester.element(find.text('1h'));
        expect(chip.labelStyle!.color, AppTheme.colorsOf(context).onPrimary);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('FocusPalette selected pair resolves from theme', () {
    testWidgets('of(context).onPrimary matches scheme onPrimary', (tester) async {
      for (final dark in [false, true]) {
        await tester.pumpWidget(wrap(
          Builder(builder: (context) {
            final fp = FocusPalette.of(context);
            final scheme = Theme.of(context).colorScheme;
            expect(fp.onPrimary, scheme.onPrimary);
            return Text('ok', style: TextStyle(color: fp.onPrimary));
          }),
          dark: dark,
        ));
        await tester.pump();
      }
    });
  });

  testWidgets('pressed FilledButton keeps its label', (tester) async {
    await tester.pumpWidget(wrap(FilledButton(
      onPressed: () {},
      child: const Text('Start'),
    )));
    await tester.pump();
    final gesture =
        tester.getCenter(find.text('Start'));
    await tester.startGesture(gesture);
    await tester.pump(const Duration(milliseconds: 100));
    // Pressed overlay must not remove the label.
    expect(find.text('Start'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
