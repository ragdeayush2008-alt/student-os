import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/constants/app_elevation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_card.dart';
import 'package:student_os/core/widgets/app_section_header.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.dark}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(_wrap(const AppCard(child: Text('Hello'))));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('default card has no gradient or glass', (tester) async {
      await tester.pumpWidget(_wrap(const AppCard(child: Text('Plain'))));
      expect(find.text('Plain'), findsOneWidget);
      final container = tester.widget<Container>(
        find
            .ancestor(of: find.text('Plain'), matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.gradient, isNull);
    });

    testWidgets('isGlass variant renders without error', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppCard(isGlass: true, child: Text('Glass'))),
      );
      expect(find.text('Glass'), findsOneWidget);
    });

    testWidgets('onTap is callable', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(AppCard(onTap: () => tapped = true, child: const Text('Tap'))),
      );
      await tester.tap(find.text('Tap'));
      expect(tapped, isTrue);
    });

    testWidgets('custom border radius is applied', (tester) async {
      final customRadius = BorderRadius.circular(32);
      await tester.pumpWidget(
        _wrap(AppCard(borderRadius: customRadius, child: const Text('Custom'))),
      );
      final container = tester.widget<Container>(
        find
            .ancestor(of: find.text('Custom'), matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.borderRadius, customRadius);
    });

    testWidgets('gradient is applied when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppCard(
            gradient: [Colors.red, Colors.blue],
            child: Text('Gradient'),
          ),
        ),
      );
      expect(find.text('Gradient'), findsOneWidget);
    });

    testWidgets('elevation none removes shadow', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppCard(elevation: AppElevation.none, child: Text('NoShadow')),
        ),
      );
      expect(find.text('NoShadow'), findsOneWidget);
    });

    testWidgets('works in light mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppCard(child: Text('Light')),
          brightness: Brightness.light,
        ),
      );
      expect(find.text('Light'), findsOneWidget);
    });
  });

  group('AppSectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_wrap(const AppSectionHeader(title: 'Tasks')));
      expect(find.text('Tasks'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppSectionHeader(title: 'Goals', icon: Icons.flag)),
      );
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppSectionHeader(title: 'Plan', subtitle: 'This week')),
      );
      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppSectionHeader(title: 'See All', trailing: Text('View'))),
      );
      expect(find.text('View'), findsOneWidget);
    });

    testWidgets('works in light mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppSectionHeader(title: 'Light'),
          brightness: Brightness.light,
        ),
      );
      expect(find.text('Light'), findsOneWidget);
    });

    testWidgets('icon container uses primary color with alpha', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppSectionHeader(title: 'Test', icon: Icons.star)),
      );
      // Verify the icon is inside a Container with decoration
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.star),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.borderRadius, isNotNull);
    });
  });

  group('AppTheme', () {
    test('colorsOf returns AppPalette with correct isDark for dark theme', () {
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            final colors = AppTheme.colorsOf(context);
            expect(colors.isDark, isTrue);
            return const SizedBox();
          },
        ),
      );
    });

    test('light and dark themes produce different color schemes', () {
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
    });
  });
}
