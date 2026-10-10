import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/constants/app_colors.dart';
import 'package:student_os/core/design/tokens/design_tokens.dart';
import 'package:student_os/core/theme/app_theme.dart';

void main() {
  group('Command Center Design Tokens — Colors', () {
    test('brand colors match specification (Forest primary, blue accent)', () {
      // Phase 1: the green family is the product identity; Student OS Blue
      // survives as a small strategic accent.
      expect(LiquidColors.primary, const Color(0xFF315CF6));
      expect(LiquidColors.secondary, const Color(0xFF7657F5));
      expect(AppColors.primary, const Color(0xFF285C4D));
      expect(AppColors.primaryDark, const Color(0xFF123D35));
      expect(AppColors.secondary, const Color(0xFF7657F5));
      expect(AppColors.studentBlue, const Color(0xFF315CF6));
      expect(AppColors.studentBlueDark, const Color(0xFF2447C7));
    });

    test('the green family forms the tonal ladder', () {
      expect(AppColors.deepForest, const Color(0xFF123D35));
      expect(AppColors.forest, const Color(0xFF285C4D));
      expect(AppColors.mutedGreen, const Color(0xFF4F7D68));
      expect(AppColors.sage, const Color(0xFF6F967F));
      expect(AppColors.softSage, const Color(0xFFA9C1AE));
      expect(AppColors.paleSage, const Color(0xFFE7EFDC));
      expect(AppColors.mist, const Color(0xFFF2F6EC));
      expect(AppColors.naturalWhite, const Color(0xFFFAFCF7));
    });

    test('semantic status colors are defined', () {
      expect(LiquidColors.success, const Color(0xFF16B88A));
      expect(LiquidColors.warning, const Color(0xFFF5A524));
      expect(LiquidColors.error, const Color(0xFFEF5B63));
      expect(LiquidColors.info, const Color(0xFF3B82F6));
      expect(LiquidColors.streak, const Color(0xFFF5A524));
    });

    test('light mode foundation layers mist -> natural white', () {
      expect(AppColors.backgroundLight, const Color(0xFFF2F6EC));
      expect(AppColors.surfaceLight, const Color(0xFFFAFCF7));
      expect(AppColors.textPrimaryLight, const Color(0xFF16241F));
      expect(AppColors.textSecondaryLight, const Color(0xFF5C6B63));
    });

    test('dark mode uses deep emerald surfaces, not inversion', () {
      expect(AppColors.backgroundDark, const Color(0xFF08211C));
      expect(AppColors.surfaceDark, const Color(0xFF0C2924));
      expect(AppColors.textPrimaryDark, const Color(0xFFEFF4EC));
      expect(AppColors.textSecondaryDark, const Color(0xFFA9BFAF));
    });
  });

  group('Command Center Design Tokens — Spacing', () {
    test('spacing scale follows the 8-point system', () {
      expect(LiquidSpacing.xxs, 4);
      expect(LiquidSpacing.xs, 8);
      expect(LiquidSpacing.sm, 12);
      expect(LiquidSpacing.md, 16);
      expect(LiquidSpacing.lg, 20);
      expect(LiquidSpacing.xl, 24);
      expect(LiquidSpacing.xxl, 32);
      expect(LiquidSpacing.xxxl, 40);
      expect(LiquidSpacing.huge, 48);
      expect(LiquidSpacing.maxContentWidth, 720);
    });

    test('prebuilt insets are accurate', () {
      expect(LiquidSpacing.screenPadding, const EdgeInsets.symmetric(horizontal: 16));
      expect(LiquidSpacing.allScreen, const EdgeInsets.all(16));
    });
  });

  group('Command Center Design Tokens — Radius', () {
    test('radii scale is locked to 8/12/16/20/24/999', () {
      expect(LiquidRadius.xs, 8);
      expect(LiquidRadius.sm, 12);
      expect(LiquidRadius.md, 16);
      expect(LiquidRadius.lg, 20);
      expect(LiquidRadius.xl, 24);
      expect(LiquidRadius.xxl, 24);
      expect(LiquidRadius.pill, 999);
    });

    test('prebuilt BorderRadius constants are correct', () {
      expect(LiquidRadius.xsAll, const BorderRadius.all(Radius.circular(8)));
      expect(LiquidRadius.smAll, const BorderRadius.all(Radius.circular(12)));
      expect(LiquidRadius.mdAll, const BorderRadius.all(Radius.circular(16)));
      expect(LiquidRadius.lgAll, const BorderRadius.all(Radius.circular(20)));
      expect(LiquidRadius.xlAll, const BorderRadius.all(Radius.circular(24)));
      expect(LiquidRadius.xxlAll, const BorderRadius.all(Radius.circular(24)));
      expect(LiquidRadius.pillAll, const BorderRadius.all(Radius.circular(999)));
    });
  });

  group('Command Center Design Tokens — Borders & Shadows', () {
    test('border scale is defined correctly', () {
      expect(LiquidBorders.hair, 0.5);
      expect(LiquidBorders.thin, 1.0);
      expect(LiquidBorders.medium, 1.5);
      expect(LiquidBorders.thick, 2.0);
    });

    test('border helpers build correct BorderSide', () {
      final side = LiquidBorders.thinSide(Colors.blue, 0.5);
      expect(side.width, 1.0);
      expect(side.color, Colors.blue.withValues(alpha: 0.5));
    });

    test('elevation presets return valid BoxShadows', () {
      final subtle = LiquidElevation.subtle(Colors.black);
      expect(subtle.length, 1);
      expect(subtle.first.blurRadius, 10);

      final glass = LiquidElevation.glass(Colors.black);
      expect(glass.length, 2);
      expect(glass.first.blurRadius, 18);

      final elevated = LiquidElevation.elevated(Colors.black);
      expect(elevated.length, 2);
      expect(elevated.first.blurRadius, 32);
    });
  });

  group('Command Center Design Tokens — Typography', () {
    test('buildTextTheme creates complete TextTheme for light mode', () {
      final tt = LiquidTypography.buildTextTheme(
        Brightness.light,
        textPrimary: LiquidColors.textPrimaryLight,
        textSecondary: LiquidColors.textSecondaryLight,
      );

      expect(tt.displayLarge?.fontFamily, 'Inter');
      expect(tt.displayLarge?.fontSize, 38);
      expect(tt.displayMedium?.fontSize, 28);
      expect(tt.headlineSmall?.fontSize, 18);
      expect(tt.bodyMedium?.fontSize, 14);
      expect(tt.labelLarge?.fontSize, 13);
    });

    test('numericStat creates bold tabular figures style', () {
      final style = LiquidTypography.numericStat(color: Colors.blue);
      expect(style.fontSize, 28);
      expect(style.fontWeight, FontWeight.w800);
      expect(style.fontFeatures, isNotEmpty);
    });
  });

  group('AppPalette — Integration with Command Center Tokens', () {
    test('AppPalette provides all semantic tokens in light mode', () {
      final palette = AppPalette(
        scheme: AppTheme.light().colorScheme,
        isDark: false,
      );

      expect(palette.isDark, isFalse);
      expect(palette.primary, const Color(0xFF285C4D));
      expect(palette.secondary, const Color(0xFF7657F5));
      // Blue is exposed only as the strategic action accent.
      expect(palette.accent, const Color(0xFF315CF6));
      expect(palette.background, const Color(0xFFF2F6EC));
      expect(palette.surface, const Color(0xFFFAFCF7));
      expect(palette.textPrimary, const Color(0xFF16241F));
      expect(palette.textSecondary, const Color(0xFF5C6B63));
      expect(palette.glass, isNotNull);
      expect(palette.glassStrong, isNotNull);
      expect(palette.glassSubtle, isNotNull);
      expect(palette.glassBorder, isNotNull);
      expect(palette.border, isNotNull);
      expect(palette.borderStrong, isNotNull);
      // Green tonal ladder resolves per brightness.
      expect(palette.deepForest, const Color(0xFF123D35));
      expect(palette.sage, const Color(0xFF6F967F));
      expect(palette.mist, const Color(0xFFF2F6EC));
    });

    test('AppPalette provides all semantic tokens in dark mode', () {
      final palette = AppPalette(
        scheme: AppTheme.dark().colorScheme,
        isDark: true,
      );

      expect(palette.isDark, isTrue);
      // Dark mode uses a tuned sage primary for readability on deep emerald.
      expect(palette.primary, const Color(0xFF8FB49A));
      expect(palette.secondary, const Color(0xFF7657F5));
      expect(palette.accent, const Color(0xFF6F8FFF));
      expect(palette.background, const Color(0xFF08211C));
      expect(palette.surface, const Color(0xFF0C2924));
      expect(palette.textPrimary, const Color(0xFFEFF4EC));
      expect(palette.textSecondary, const Color(0xFFA9BFAF));
      expect(palette.deepForest, const Color(0xFF0C2924));
      expect(palette.sage, const Color(0xFF8FB49A));
    });
  });
}
