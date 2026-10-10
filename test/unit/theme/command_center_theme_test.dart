import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/constants/app_colors.dart';
import 'package:student_os/core/design/tokens/student_os_tokens.dart';
import 'package:student_os/core/theme/app_theme.dart';

void main() {
  group('Command Center color tokens', () {
    test('Forest identity is canonical, blue is the accent', () {
      // Phase 1: green defines the product; blue is a small accent only.
      expect(StudentOSColors.primary, const Color(0xFF285C4D));
      expect(StudentOSColors.primaryDark, const Color(0xFF123D35));
      expect(StudentOSColors.secondary, const Color(0xFF7657F5));
      expect(StudentOSColors.studentBlue, const Color(0xFF315CF6));
      expect(StudentOSColors.studentBlueDark, const Color(0xFF2447C7));
      expect(AppColors.primary, const Color(0xFF285C4D));
      expect(AppColors.primaryDark, const Color(0xFF123D35));
      expect(AppColors.secondary, const Color(0xFF7657F5));
    });

    test('semantic colors communicate state only', () {
      expect(StudentOSColors.success, const Color(0xFF16B88A));
      expect(StudentOSColors.warning, const Color(0xFFF5A524));
      expect(StudentOSColors.danger, const Color(0xFFEF5B63));
      expect(StudentOSColors.info, const Color(0xFF3B82F6));
    });

    test('backgrounds layer mist under natural-white cards', () {
      expect(StudentOSColors.background, const Color(0xFFF2F6EC));
      expect(StudentOSColors.surface, const Color(0xFFFAFCF7));
      expect(StudentOSColors.mist, const Color(0xFFF2F6EC));
      expect(StudentOSColors.paleSage, const Color(0xFFE7EFDC));
      expect(StudentOSColors.background, isNot(const Color(0xFFFFFFFF)));
    });

    test('dark mode uses deep emerald surfaces, not inversion', () {
      expect(StudentOSColors.darkBackground, const Color(0xFF08211C));
      expect(StudentOSColors.darkSurface, const Color(0xFF0C2924));
      expect(StudentOSColors.veryDeepEmerald, const Color(0xFF08211C));
      expect(StudentOSColors.darkText, const Color(0xFFEFF4EC));
      expect(StudentOSColors.darkPrimary, const Color(0xFF8FB49A));
    });

    test('radius scale is consistent (8/12/16/20/24/999)', () {
      expect(StudentOSRadius.small, 8);
      expect(StudentOSRadius.medium, 12);
      expect(StudentOSRadius.standard, 16);
      expect(StudentOSRadius.large, 20);
      expect(StudentOSRadius.hero, 24);
      expect(StudentOSRadius.pill, 999);
    });

    test('spacing follows 8-point system', () {
      expect(StudentOSSpacing.s4, 4);
      expect(StudentOSSpacing.s8, 8);
      expect(StudentOSSpacing.s12, 12);
      expect(StudentOSSpacing.s16, 16);
      expect(StudentOSSpacing.s20, 20);
      expect(StudentOSSpacing.s24, 24);
      expect(StudentOSSpacing.s32, 32);
      expect(StudentOSSpacing.s40, 40);
      expect(StudentOSSpacing.s48, 48);
      expect(StudentOSSpacing.s64, 64);
    });

    test('motion tokens are restrained', () {
      // TCC-aligned tokens: fast 180 · base/standard 300 · page/nav 380 · slow/large 450
      expect(StudentOSMotion.fast.inMilliseconds, 180);
      expect(StudentOSMotion.standard.inMilliseconds, 300);
      expect(StudentOSMotion.navigation.inMilliseconds,
          inInclusiveRange(370, 390));
      expect(StudentOSMotion.large.inMilliseconds, inInclusiveRange(440, 460));
      // Ensure base/page/slow aliases are coherent.
      expect(StudentOSMotion.base.inMilliseconds, 300);
      expect(StudentOSMotion.page.inMilliseconds, 380);
      expect(StudentOSMotion.slow.inMilliseconds, 450);
    });
  });

  group('Command Center ThemeData', () {
    test('light theme uses mist background + Forest primary', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF285C4D));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF2F6EC));
      expect(theme.colorScheme.surface, const Color(0xFFF2F6EC));
      // Blue is available as a strategic accent, not the surface identity.
      expect(theme.colorScheme.tertiary, const Color(0xFF315CF6));
    });

    test('dark theme uses deep emerald foundation + tuned sage primary', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFF8FB49A));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF08211C));
      expect(theme.colorScheme.surface, const Color(0xFF08211C));
    });

    test('cards are solid with subtle border', () {
      final theme = AppTheme.light();
      final card = theme.cardTheme;
      expect(card.color, const Color(0xFFFAFCF7));
      expect(
        card.shape,
        isA<RoundedRectangleBorder>().having(
          (s) => s.borderRadius,
          'radius',
          BorderRadius.circular(16),
        ),
      );
    });

    test('buttons use 12-14 radius, inputs focus Forest', () {
      final theme = AppTheme.light();
      final filled =
          theme.filledButtonTheme.style?.shape?.resolve({}) as RoundedRectangleBorder?;
      expect(
        filled?.borderRadius,
        BorderRadius.circular(12),
      );
      final focused = theme.inputDecorationTheme.focusedBorder
          as OutlineInputBorder?;
      expect(focused?.borderSide.color, const Color(0xFF285C4D));
      expect(focused?.borderRadius, BorderRadius.circular(12));
    });

    test('bottom sheets are solid with 20-24 top radius', () {
      final theme = AppTheme.light();
      final shape = theme.bottomSheetTheme.shape
          as RoundedRectangleBorder?;
      expect(
        shape?.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(24)),
      );
      expect(theme.bottomSheetTheme.backgroundColor,
          const Color(0xFFFAFCF7));
    });
  });
}
