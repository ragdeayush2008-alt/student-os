import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/constants/app_colors.dart';
import 'package:student_os/core/constants/app_elevation.dart';
import 'package:student_os/core/constants/app_radius.dart';
import 'package:student_os/core/constants/app_spacing.dart';
import 'package:student_os/core/theme/app_theme.dart';

void main() {
  group('AppPalette', () {
    AppPalette darkPalette() =>
        AppPalette(scheme: AppTheme.dark().colorScheme, isDark: true);

    AppPalette lightPalette() =>
        AppPalette(scheme: AppTheme.light().colorScheme, isDark: false);

    test('semantic colors are accessible in dark mode', () {
      final p = darkPalette();
      expect(p.primary, isNotNull);
      expect(p.secondary, isNotNull);
      expect(p.background, isNotNull);
      expect(p.surface, isNotNull);
      expect(p.onSurface, isNotNull);
      expect(p.onSurfaceMuted, isNotNull);
      expect(p.error, isNotNull);
      expect(p.success, isNotNull);
      expect(p.warning, isNotNull);
    });

    test('semantic colors are accessible in light mode', () {
      final p = lightPalette();
      expect(p.primary, isNotNull);
      expect(p.secondary, isNotNull);
      expect(p.background, isNotNull);
      expect(p.surface, isNotNull);
      expect(p.onSurface, isNotNull);
      expect(p.onSurfaceMuted, isNotNull);
    });

    test('onSurfaceMuted differs between light and dark', () {
      expect(
        darkPalette().onSurfaceMuted,
        isNot(lightPalette().onSurfaceMuted),
      );
    });

    test('glassBorder is accessible', () {
      expect(darkPalette().glassBorder, isNotNull);
      expect(lightPalette().glassBorder, isNotNull);
      expect(darkPalette().glassBorder, isNot(lightPalette().glassBorder));
    });

    test('gradients return non-empty color lists', () {
      final p = darkPalette();
      expect(p.rewardGradient, isNotEmpty);
      expect(p.accentGradient, isNotEmpty);
      expect(p.neonGradient, isNotEmpty);
      expect(p.sunsetGradient, isNotEmpty);
      expect(p.primaryGradient, isNotEmpty);
    });

    test('glassShadow returns non-empty shadow list', () {
      expect(darkPalette().glassShadow, isNotEmpty);
      expect(lightPalette().glassShadow, isNotEmpty);
    });

    test('isDark flag is respected', () {
      expect(darkPalette().isDark, isTrue);
      expect(lightPalette().isDark, isFalse);
    });

    test('neon colors are accessible', () {
      final p = darkPalette();
      expect(p.neonPink, AppColors.neonPink);
      expect(p.neonBlue, AppColors.neonBlue);
      expect(p.neonGreen, AppColors.neonGreen);
      expect(p.neonYellow, AppColors.neonYellow);
      expect(p.neonOrange, AppColors.neonOrange);
      expect(p.neonPurple, AppColors.neonPurple);
    });

    test('streak color matches AppColors', () {
      expect(darkPalette().streak, AppColors.streak);
    });
  });

  group('AppElevation', () {
    test('soft shadow returns two BoxShadows', () {
      final shadows = AppElevation.soft(Colors.black);
      expect(shadows.length, 2);
      expect(shadows[0].blurRadius, 20);
      expect(shadows[1].blurRadius, 4);
    });

    test('stronger shadow returns two BoxShadows', () {
      final shadows = AppElevation.stronger(Colors.black);
      expect(shadows.length, 2);
      expect(shadows[0].blurRadius, 28);
      expect(shadows[1].blurRadius, 6);
    });

    test('token values are correct', () {
      expect(AppElevation.none, 0);
      expect(AppElevation.low, 1);
      expect(AppElevation.medium, 3);
      expect(AppElevation.high, 8);
    });
  });

  group('AppRadius', () {
    test('scale values follow the locked 8/12/16/20/24/999 scale', () {
      expect(AppRadius.xs, 8);
      expect(AppRadius.sm, 12);
      expect(AppRadius.md, 16);
      expect(AppRadius.lg, 20);
      expect(AppRadius.xl, 24);
      // xxl is capped at the hero radius (24) — no arbitrary large radii.
      expect(AppRadius.xxl, 24);
      expect(AppRadius.xs, lessThan(AppRadius.sm));
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
      expect(AppRadius.lg, lessThan(AppRadius.xl));
      expect(AppRadius.xl, lessThanOrEqualTo(AppRadius.xxl));
    });

    test('pill is very large', () {
      expect(AppRadius.pill, greaterThan(100));
    });

    test('prebuilt BorderRadius constants are correct', () {
      expect(AppRadius.xsAll, const BorderRadius.all(Radius.circular(8)));
      expect(AppRadius.smAll, const BorderRadius.all(Radius.circular(12)));
      expect(AppRadius.mdAll, const BorderRadius.all(Radius.circular(16)));
      expect(AppRadius.lgAll, const BorderRadius.all(Radius.circular(20)));
      expect(AppRadius.xlAll, const BorderRadius.all(Radius.circular(24)));
      expect(AppRadius.xxlAll, const BorderRadius.all(Radius.circular(24)));
    });
  });

  group('AppSpacing', () {
    test('scale values are monotonically increasing', () {
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
      expect(AppSpacing.xl, lessThan(AppSpacing.xxl));
      expect(AppSpacing.xxl, lessThan(AppSpacing.xxxl));
    });

    test('screen padding is reasonable', () {
      expect(AppSpacing.screen, greaterThanOrEqualTo(16));
      expect(AppSpacing.screen, lessThanOrEqualTo(24));
    });
  });
}
