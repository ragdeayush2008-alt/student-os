import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_activity_visuals.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light(),
    home: Scaffold(body: Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    )),
  );
}

void main() {
  group('StudentOSWeeklyBars', () {
    testWidgets('renders seven bars with day labels', (tester) async {
      await tester.pumpWidget(_wrap(const StudentOSWeeklyBars(
        values: [1, 2, 3, 2, 4, 0, 1],
      )));
      await tester.pumpAndSettle();

      expect(find.text('M'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('S'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('zero week renders without overflow or crash', (tester) async {
      await tester.pumpWidget(_wrap(const StudentOSWeeklyBars(
        values: [0, 0, 0, 0, 0, 0, 0],
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(_wrap(
        const StudentOSWeeklyBars(values: [2, 2, 2, 2, 2, 2, 2]),
        theme: AppTheme.dark(),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow from 320dp to 430dp', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      for (final w in [320.0, 360.0, 390.0, 412.0, 430.0]) {
        tester.view.physicalSize = Size(w, 800);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(_wrap(const StudentOSWeeklyBars(
          values: [3.5, 1.2, 4.8, 0.4, 2.2, 5.0, 1.0],
          highlightedIndex: 4,
        )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${w}dp');
      }
    });
  });

  group('StudentOSHeatmap', () {
    const weeks = [
      [0.0, 1.0, 2.0, 0.0, 3.0, 1.0, 0.0],
      [2.0, 2.0, 4.0, 1.0, 0.0, 3.0, 2.0],
      [1.0, 0.0, 1.0, 5.0, 2.0, 0.0, 1.0],
    ];

    testWidgets('renders week grid with sage progression', (tester) async {
      await tester.pumpWidget(_wrap(const StudentOSHeatmap(weeks: weeks)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty weeks render nothing without crashing',
        (tester) async {
      await tester.pumpWidget(_wrap(const StudentOSHeatmap(weeks: [])));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(_wrap(
        const StudentOSHeatmap(weeks: weeks),
        theme: AppTheme.dark(),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('color scale is sage-only and monotonic', (tester) async {
      await tester.pumpWidget(_wrap(const StudentOSHeatmap(weeks: weeks)));
      await tester.pumpAndSettle();
      final palette = AppTheme.colorsOf(tester.element(find.byType(StudentOSHeatmap)));
      expect(StudentOSHeatmap.colorFor(0, palette), palette.surfaceVariant);
      expect(StudentOSHeatmap.colorFor(0.1, palette), palette.paleSage);
      expect(StudentOSHeatmap.colorFor(0.3, palette), palette.softSage);
      expect(StudentOSHeatmap.colorFor(0.6, palette), palette.sage);
      expect(StudentOSHeatmap.colorFor(0.9, palette), palette.forest);
      expect(tester.takeException(), isNull);
    });
  });
}
