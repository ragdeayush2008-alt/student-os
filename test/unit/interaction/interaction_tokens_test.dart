import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/presentation/widgets/focus_palette.dart';

/// Global interaction-state contract: every selected/active background must
/// resolve a readable foreground IN THE SAME MODE.
///
/// Regression guard for the "invisible after tap" bug class: hardcoded white
/// foregrounds paired with theme-adaptive primary backgrounds (forest in
/// light, light sage in dark) rendered white-on-sage in dark mode.
void main() {
  double luminance(Color c) {
    double ch(double s) => s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  double contrast(Color a, Color b) {
    final l1 = luminance(a);
    final l2 = luminance(b);
    final hi = l1 > l2 ? l1 : l2;
    final lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  group('paired emphasis tokens', () {
    test('light: selectedForeground readable on selectedBackground', () {
      final t = AppTheme.light();
      final p = AppPalette(scheme: t.colorScheme, isDark: false);
      expect(p.selectedBackground, t.colorScheme.primary);
      expect(p.selectedForeground, t.colorScheme.onPrimary);
      expect(contrast(p.selectedBackground, p.selectedForeground),
          greaterThanOrEqualTo(4.5));
    });

    test('dark: selectedForeground readable on selectedBackground', () {
      final t = AppTheme.dark();
      final p = AppPalette(scheme: t.colorScheme, isDark: true);
      expect(contrast(p.selectedBackground, p.selectedForeground),
          greaterThanOrEqualTo(4.5));
      // Hardcoded white would fail here (white-on-sage ≈ 2.2:1).
      expect(contrast(p.selectedBackground, Colors.white), lessThan(4.5));
    });

    test('FocusPalette static pairs are readable in both modes', () {
      expect(contrast(FocusPalette.light.primary, FocusPalette.light.onPrimary),
          greaterThanOrEqualTo(4.5));
      expect(contrast(FocusPalette.dark.primary, FocusPalette.dark.onPrimary),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('button themes pair background + foreground', () {
    for (final mode in ['light', 'dark']) {
      test('$mode: FilledButton foreground is onPrimary, never white', () {
        final t = mode == 'light' ? AppTheme.light() : AppTheme.dark();
        final style = t.filledButtonTheme.style!;
        final fg = style.foregroundColor!.resolve({});
        expect(fg, t.colorScheme.onPrimary);
        final bg = style.backgroundColor!.resolve({});
        expect(contrast(bg!, fg!), greaterThanOrEqualTo(4.5));
        // Disabled pair resolves (intentionally muted, not broken).
        expect(
            style.backgroundColor!.resolve({WidgetState.disabled}), isNotNull);
        expect(
            style.foregroundColor!.resolve({WidgetState.disabled}), isNotNull);
      });

      test('$mode: ElevatedButton foreground is onPrimary', () {
        final t = mode == 'light' ? AppTheme.light() : AppTheme.dark();
        final style = t.elevatedButtonTheme.style!;
        expect(style.foregroundColor!.resolve({}), t.colorScheme.onPrimary);
      });
    }
  });

  group('selection control themes resolve per state', () {
    for (final mode in ['light', 'dark']) {
      test('$mode: SegmentedButton selected/unselected/disabled', () {
        final t = mode == 'light' ? AppTheme.light() : AppTheme.dark();
        final style = t.segmentedButtonTheme.style!;
        final selBg =
            style.backgroundColor!.resolve({WidgetState.selected})!;
        final selFg =
            style.foregroundColor!.resolve({WidgetState.selected})!;
        expect(contrast(selBg, selFg), greaterThanOrEqualTo(4.5));
        expect(
            style.foregroundColor!.resolve({}), t.colorScheme.onSurface);
        expect(style.foregroundColor!.resolve({WidgetState.disabled}),
            isNotNull);
        expect(
            style.iconColor!.resolve({WidgetState.selected}), selFg);
      });

      test('$mode: Switch selected track+thumb pair', () {
        final t = mode == 'light' ? AppTheme.light() : AppTheme.dark();
        final track =
            t.switchTheme.trackColor!.resolve({WidgetState.selected})!;
        final thumb =
            t.switchTheme.thumbColor!.resolve({WidgetState.selected})!;
        expect(track, t.colorScheme.primary);
        expect(contrast(track, thumb), greaterThanOrEqualTo(4.5));
        // OFF state has a visible track (not transparent/broken).
        final offTrack = t.switchTheme.trackColor!.resolve({});
        expect(offTrack!.a, greaterThan(0.5));
      });

      test('$mode: Checkbox check readable on fill', () {
        final t = mode == 'light' ? AppTheme.light() : AppTheme.dark();
        final fill =
            t.checkboxTheme.fillColor!.resolve({WidgetState.selected})!;
        final check = t.checkboxTheme.checkColor!.resolve({})!;
        expect(contrast(fill, check), greaterThanOrEqualTo(4.5));
      });

      test('$mode: Chip selected pair readable', () {
        final t = mode == 'light' ? AppTheme.light() : AppTheme.dark();
        expect(contrast(t.chipTheme.selectedColor!, t.colorScheme.onPrimary),
            greaterThanOrEqualTo(4.5));
      });

      test('$mode: TabBar selected vs unselected distinct', () {
        final t = mode == 'light' ? AppTheme.light() : AppTheme.dark();
        expect(t.tabBarTheme.labelColor, isNotNull);
        expect(t.tabBarTheme.unselectedLabelColor, isNotNull);
        expect(t.tabBarTheme.labelColor, isNot(t.tabBarTheme.unselectedLabelColor));
      });
    }
  });
}
