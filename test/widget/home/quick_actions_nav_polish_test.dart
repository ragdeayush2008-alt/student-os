import 'package:flutter/material.dart' hide PrioritizedAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/navigation/shell_destinations.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_card.dart';
import 'package:student_os/core/widgets/module_placeholder_screen.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/calendar/presentation/calendar_screen.dart';
import 'package:student_os/features/home/home_screen.dart';

/// Quick Actions 4x2 polish + minimal bottom navigation polish.
///
/// Locks in: exactly 8 actions, Calendar navigation, responsive 320–430
/// with no overflow, no selected pill/dot/border in the nav, and working
/// destination switching with a settled animation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapWithApp(Widget child, {double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      onUnknownRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const ModulePlaceholderScreen(
          title: 'Fallback',
          icon: Icons.circle_outlined,
          description: 'Test fallback route.',
        ),
      ),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  Future<void> pumpHome(WidgetTester tester, {double width = 390}) async {
    await tester.pumpWidget(wrapWithApp(const HomeScreen(), width: width));
    await tester.pumpAndSettle();
  }

  const quickLabels = [
    'Focus',
    'Plan Day',
    'Study',
    'Revise',
    'Add Task',
    'Exams',
    'Calendar',
  ];

  group('Quick Actions hero hierarchy', () {
    testWidgets('exactly 7 actions render as 3 featured + 4 compact', (
      tester,
    ) async {
      await pumpHome(tester);

      for (final label in quickLabels) {
        expect(find.text(label), findsWidgets, reason: 'missing $label');
      }
      // Ask OS owns the canonical Assistant entry card, not the grid.
      expect(find.text('Ask Student OS'), findsWidgets,
          reason: 'missing canonical Assistant entry');

      // Featured (Focus, Plan Day, Study) form the first row; the remaining
      // four compact tiles form the second row.
      final centers = <double, int>{};
      for (final label in quickLabels) {
        final box = tester.getRect(find.text(label).first);
        // Group by row band so sub-pixel top differences still collapse.
        final band = (box.top / 8).roundToDouble();
        centers[band] = (centers[band] ?? 0) + 1;
      }
      expect(
        centers.length,
        2,
        reason: 'expected exactly 2 rows, got $centers',
      );
      final counts = centers.values.toList()..sort();
      expect(counts, [3, 4],
          reason: 'expected 3 featured + 4 compact, got $centers');
      expect(tester.takeException(), isNull);
    });

    testWidgets('action tiles stay compact on wide screens', (tester) async {
      // Regression guard for the "giant empty card" bug: the grid is
      // width-capped, so tiles must not grow as the viewport widens.
      double firstTileWidth(double width) {
        final labelBox = find.text('Focus').first;
        final ancestor = find.ancestor(
          of: labelBox,
          matching: find.byType(Container),
        );
        return tester.getSize(ancestor.first).width;
      }

      await pumpHome(tester, width: 390);
      final narrowWidth = firstTileWidth(390);

      await pumpHome(tester, width: 1400);
      final wideWidth = firstTileWidth(1400);

      expect(
        wideWidth,
        lessThanOrEqualTo(narrowWidth + 1),
        reason: 'action tile width must not expand on wide screens',
      );
      // A quick-action tile is a compact block, never a giant rectangle.
      expect(wideWidth, lessThan(300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Calendar tile opens the calendar', (tester) async {
      await pumpHome(tester);

      await tester.ensureVisible(find.text('Calendar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendar').first);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final width in [320.0, 360.0, 390.0, 412.0, 430.0]) {
      testWidgets('quick grid fits ${width.toInt()}dp with no overflow', (
        tester,
      ) async {
        await pumpHome(tester, width: width);

        for (final label in quickLabels) {
          expect(find.text(label), findsWidgets, reason: 'missing $label');
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Bottom navigation minimal polish', () {
    Future<void> pumpNav(
      WidgetTester tester, {
      required int selected,
      required ValueChanged<int> onSelect,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            bottomNavigationBar: StudentOSBottomNavigation(
              selectedIndex: selected,
              onDestinationSelected: onSelect,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('all 5 destinations render and switch', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              bottomNavigationBar: StudentOSBottomNavigation(
                selectedIndex: selected,
                onDestinationSelected: (i) => setState(() => selected = i),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudentOSBottomNavigation), findsOneWidget);
      for (final d in ShellDestinations.all) {
        expect(find.text(d.title), findsOneWidget);
      }

      // Tap through every destination: selection follows, no crash.
      for (var i = 0; i < ShellDestinations.all.length; i++) {
        await tester.tap(find.text(ShellDestinations.all[i].title));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(selected, i);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('soft capsule indicator, no dot or top border',
        (tester) async {
      await pumpNav(tester, selected: 0, onSelect: (_) {});

      final nav = find.byType(StudentOSBottomNavigation);
      final containers = tester
          .widgetList<Container>(find.descendant(of: nav, matching: find.byType(Container)))
          .toList();

      var capsuleCount = 0;
      for (final c in containers) {
        final decoration = c.decoration;
        if (decoration is! BoxDecoration) continue;
        final color = decoration.color;
        if (decoration.borderRadius == BorderRadius.circular(999) &&
            color != null &&
            color.a > 0.01) {
          capsuleCount++;
        }
        // No top divider line above the navigation.
        expect(
          decoration.border,
          isNot(isA<Border>()),
          reason: 'top border above navigation must not exist',
        );
        // No small solid dot indicator.
        final size = (c.constraints?.maxWidth ?? 99) < 12 &&
            (c.constraints?.maxHeight ?? 99) < 12;
        final isDot =
            size && decoration.shape == BoxShape.circle && decoration.color != null;
        expect(isDot, isFalse, reason: 'dot indicator must not exist');
      }
      // Exactly one soft active capsule for the selected destination.
      expect(capsuleCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selected icon uses primary color, others neutral', (
      tester,
    ) async {
      await pumpNav(tester, selected: 2, onSelect: (_) {});
      final scheme = Theme.of(
        tester.element(find.byType(StudentOSBottomNavigation)),
      ).colorScheme;

      Icon iconFor(String label) {
        final col = tester
            .widgetList<Column>(find.byType(Column))
            .firstWhere(
              (c) => find.descendant(
                of: find.byWidget(c),
                matching: find.text(label),
              ).evaluate().isNotEmpty,
            );
        return tester.widget<Icon>(
          find.descendant(of: find.byWidget(col), matching: find.byType(Icon)),
        );
      }

      expect(iconFor(ShellDestinations.all[2].title).color, scheme.primary);
      expect(
        iconFor(ShellDestinations.all[0].title).color,
        scheme.onSurfaceVariant,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
