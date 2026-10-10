import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/core/constants/app_colors.dart';
import 'package:student_os/core/design/tokens/student_os_tokens.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/core/widgets/student_os_menu.dart';

/// Phase 1 — Final Visual System + Global UX Transformation.
///
/// Locks in the green-primary visual language, the blue strategic accent,
/// solid surfaces (no glassmorphism), and the Deep Forest menu treatment.
void main() {
  group('Phase 1 — green family is the primary visual language', () {
    test('the tonal ladder runs dark -> medium -> muted -> light', () {
      // Depth increases downward toward Deep Forest.
      const ladder = [
        AppColors.deepForest,
        AppColors.forest,
        AppColors.mutedGreen,
        AppColors.sage,
        AppColors.softSage,
        AppColors.paleSage,
        AppColors.mist,
        AppColors.naturalWhite,
      ];

      for (var i = 0; i < ladder.length - 1; i++) {
        final darker = ladder[i];
        final lighter = ladder[i + 1];
        final dSum = darker.computeLuminance();
        final lSum = lighter.computeLuminance();
        expect(
          dSum,
          lessThan(lSum),
          reason: 'step $i must get lighter going down the ladder '
              '($darker -> $lighter)',
        );
      }
    });

    test('primary drives the color scheme, blue stays a separate accent', () {
      final light = AppTheme.light().colorScheme;
      final dark = AppTheme.dark().colorScheme;

      expect(light.primary, AppColors.forest);
      expect(light.tertiary, AppColors.studentBlue);
      // Blue must not masquerade as the product identity.
      expect(light.primary, isNot(AppColors.studentBlue));
      expect(dark.primary, isNot(AppColors.studentBlue));
    });

    test('blue is never used as a broad surface color', () {
      final light = AppTheme.light().colorScheme;
      expect(light.surface, isNot(AppColors.studentBlue));
      expect(light.surfaceContainerLow, isNot(AppColors.studentBlue));
      expect(light.surfaceContainer, isNot(AppColors.studentBlue));
    });
  });

  group('Phase 1 — light and dark foundations', () {
    test('light mode layers mist under natural-white cards', () {
      final theme = AppTheme.light();
      final scheme = theme.colorScheme;

      expect(scheme.surface, AppColors.mist);
      expect(theme.scaffoldBackgroundColor, AppColors.mist);
      // Cards sit one tonal step up from the background.
      expect(
        scheme.surfaceContainerLow.computeLuminance(),
        greaterThan(scheme.surface.computeLuminance()),
      );
    });

    test('dark mode uses deep emerald, not an inverted light scheme', () {
      final scheme = AppTheme.dark().colorScheme;

      expect(scheme.surface, AppColors.veryDeepEmerald);
      expect(
        scheme.surface.computeLuminance(),
        lessThan(AppTheme.light().colorScheme.surface.computeLuminance()),
      );
      // Dark surfaces must read as green, not neutral grey.
      expect(scheme.surface.g, greaterThan(scheme.surface.r));
      expect(scheme.surface.g, greaterThan(scheme.surface.b));
    });

    test('body text meets WCAG AA contrast in both modes', () {
      double ratio(Color a, Color b) {
        final la = a.computeLuminance();
        final lb = b.computeLuminance();
        final hi = la > lb ? la : lb;
        final lo = la > lb ? lb : la;
        return (hi + 0.05) / (lo + 0.05);
      }

      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(
        ratio(
          light.colorScheme.onSurface,
          light.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(
          dark.colorScheme.onSurface,
          dark.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
      // Muted supporting text still clears AA for body copy.
      expect(
        ratio(
          light.colorScheme.onSurfaceVariant,
          light.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('Phase 1 — no glassmorphism', () {
    test('theme never installs a translucent surface', () {
      // Solid surfaces only: every base surface must be fully opaque.
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(theme.colorScheme.surface.a, 1.0);
        expect(theme.scaffoldBackgroundColor.a, 1.0);
        expect(theme.cardTheme.color?.a, 1.0);
      }
    });

    test('popup menus use an opaque Deep Forest surface', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final menu = theme.popupMenuTheme;
        expect(menu.color, AppColors.deepForest);
        expect(
          menu.color?.a,
          1.0,
          reason: 'menus must not be translucent',
        );
        expect(menu.surfaceTintColor, Colors.transparent);
      }
    });
  });

  group('Phase 1 — Deep Forest menu treatment', () {
    test('menu surface is Deep Forest with a sage accent', () {
      expect(StudentOSMenu.menuSurface, AppColors.deepForest);
      expect(StudentOSMenu.menuBlue, StudentOSMenu.menuSurface);
      expect(StudentOSMenu.menuAccent, AppColors.sage);
      // The menu must not revert to the old blue identity.
      expect(StudentOSMenu.menuSurface, isNot(AppColors.studentBlue));
    });

    testWidgets('menu renders opaque with light text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: StudentOSMenu(
              selectedIndex: 0,
              onSelect: (_) {},
              onClose: () {},
              onProgress: () {},
              onAssistant: () {},
              onSettings: () {},
              onLogout: () {},
              itemAnimation: const AlwaysStoppedAnimation<double>(1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Light text on the dark forest surface.
      final title = tester.widget<Text>(find.text('Student OS'));
      expect(title.style?.color, Colors.white);
      expect(tester.takeException(), isNull);
    });

    testWidgets('menu exposes all locked destinations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: StudentOSMenu(
              selectedIndex: 0,
              onSelect: (_) {},
              onClose: () {},
              onProgress: () {},
              onAssistant: () {},
              onSettings: () {},
              onLogout: () {},
              itemAnimation: const AlwaysStoppedAnimation<double>(1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in [
        'Home',
        'Plan & Study',
        'SprintX',
        'Tools Hub',
        'Workspace',
        'Progress',
        'Ask Student OS',
        'Settings',
        'Logout',
      ]) {
        expect(find.text(label), findsWidgets, reason: 'missing $label');
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 1 — bottom navigation', () {
    testWidgets('keeps exactly 5 destinations in the locked order', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            bottomNavigationBar: StudentOSBottomNavigation(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titles = [
        'Home',
        'Plan & Study',
        'SprintX',
        'Tools Hub',
        'Workspace',
      ];
      for (final title in titles) {
        expect(find.text(title), findsOneWidget, reason: 'missing tab $title');
      }
      // Exactly five tabs — Phase 1 must not add or remove any.
      expect(
        tester.widget<StudentOSBottomNavigation>(
          find.byType(StudentOSBottomNavigation),
        ).destinations.length,
        5,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('active tab uses the green identity, not blue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            bottomNavigationBar: StudentOSBottomNavigation(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final icons = tester
          .widgetList<Icon>(find.descendant(
            of: find.byType(StudentOSBottomNavigation),
            matching: find.byType(Icon),
          ))
          .toList();
      expect(icons, isNotEmpty);
      // The selected icon is Forest (or its dark sage variant), never blue.
      for (final icon in icons) {
        expect(icon.color, isNot(AppColors.studentBlue));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow across the required mobile widths', (
      tester,
    ) async {
      for (final width in [320.0, 360.0, 390.0, 412.0, 430.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 800)),
              child: Scaffold(
                bottomNavigationBar: StudentOSBottomNavigation(
                  selectedIndex: 1,
                  onDestinationSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'overflow at $width');
      }
    });
  });

  group('Phase 1 — gradients stay in the green family', () {
    test('identity gradient is Forest-based', () {
      expect(StudentOSColors.heroGradient, [
        AppColors.deepForest,
        AppColors.forest,
      ]);
    });

    test('data visualization gradient runs forest -> pale', () {
      final data = StudentOSColors.dataGradient;
      expect(data.first, AppColors.forest);
      expect(data.last, AppColors.softSage);
      // Each step moves up the tonal ladder, i.e. gets lighter.
      for (var i = 0; i < data.length - 1; i++) {
        expect(
          data[i].computeLuminance(),
          lessThan(data[i + 1].computeLuminance()),
          reason: 'step $i must get lighter (${data[i]} -> ${data[i + 1]})',
        );
      }
    });

    test('blue action gradient is reserved for execution accents', () {
      expect(StudentOSColors.actionGradient, [
        AppColors.studentBlue,
        AppColors.studentBlueDark,
      ]);
    });
  });
}
