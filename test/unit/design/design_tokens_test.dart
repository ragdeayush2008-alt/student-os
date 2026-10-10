import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/core/constants/app_colors.dart';
import 'package:student_os/core/design/tokens/student_os_tokens.dart';
import 'package:student_os/core/theme/app_palette.dart';

void main() {
  group('Phase 6 — identity tokens stay locked', () {
    test('Forest is the primary identity; blue is a small accent', () {
      // Phase 1 superseded the blue-primary direction: the green family now
      // defines the product, and Student OS Blue is a strategic accent.
      expect(AppColors.primary, const Color(0xFF285C4D));
      expect(AppColors.primaryDark, const Color(0xFF123D35));
      expect(AppColors.secondary, const Color(0xFF7657F5));
      expect(StudentOSColors.primary, const Color(0xFF285C4D));
      expect(StudentOSColors.secondary, const Color(0xFF7657F5));
      // The accent itself is unchanged in value.
      expect(AppColors.studentBlue, const Color(0xFF315CF6));
      expect(AppColors.studentBlueDark, const Color(0xFF2447C7));
    });

    test('semantic accents are unchanged', () {
      expect(AppColors.success, const Color(0xFF16B88A));
      expect(AppColors.warning, const Color(0xFFF5A524));
      expect(AppColors.error, const Color(0xFFEF5B63));
    });

    test('foundations layer mist -> natural white, deep emerald in dark', () {
      expect(AppColors.backgroundLight, const Color(0xFFF2F6EC));
      expect(AppColors.surfaceLight, const Color(0xFFFAFCF7));
      expect(AppColors.backgroundDark, const Color(0xFF08211C));
    });
  });

  group('Phase 6 — Sage/Forest language is now primary', () {
    test('sage family values match the approved direction', () {
      expect(AppColors.deepForest, const Color(0xFF123D35));
      expect(AppColors.forest, const Color(0xFF285C4D));
      expect(AppColors.sage, const Color(0xFF6F967F));
      expect(AppColors.softSage, const Color(0xFFA9C1AE));
      expect(AppColors.paleSage, const Color(0xFFE7EFDC));
      expect(StudentOSColors.sage, const Color(0xFF6F967F));
      expect(StudentOSColors.paleSage, const Color(0xFFE7EFDC));
    });

    test('palette resolves the green family per brightness', () {
      const light = AppPalette(
        scheme: ColorScheme.light(),
        isDark: false,
      );
      const dark = AppPalette(
        scheme: ColorScheme.dark(),
        isDark: true,
      );
      expect(light.sage, AppColors.sage);
      expect(light.paleSage, AppColors.paleSage);
      expect(light.forest, AppColors.forest);
      expect(light.mist, AppColors.mist);
      expect(dark.sage, AppColors.sageDark);
      expect(dark.paleSage, AppColors.paleSageDark);
      expect(dark.deepForest, AppColors.deepForestDark);
      // Blue stays available as a discrete accent, distinct from primary.
      expect(light.accent, isNot(light.primary));
    });
  });

  group('Phase 6 — spacing, radius, motion standards', () {
    test('8pt spacing scale is ordered', () {
      expect(StudentOSSpacing.s4, 4);
      expect(StudentOSSpacing.s8, 8);
      expect(StudentOSSpacing.screenPadding, 16);
      expect(StudentOSSpacing.sectionGap, 32);
      expect(StudentOSSpacing.maxContentWidth, 720);
    });

    test('radius scale supports card hierarchy', () {
      expect(StudentOSRadius.small, 8);
      expect(StudentOSRadius.standard, 16);
      expect(StudentOSRadius.hero, 24);
      expect(StudentOSRadius.pill, 999);
    });

    test('motion stays within the 150–300ms UI standard', () {
      expect(StudentOSMotion.fast.inMilliseconds, 180);
      expect(StudentOSMotion.base.inMilliseconds, 300);
      expect(StudentOSMotion.standard.inMilliseconds, 300);
      expect(StudentOSMotion.fast.inMilliseconds, greaterThanOrEqualTo(150));
    });
  });
}
