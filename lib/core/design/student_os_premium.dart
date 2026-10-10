import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../theme/app_theme.dart';

/// Premium type + surface tokens for the global UI 2.0 pass.
///
/// Inter only (bundled font). Hierarchy over size: display is used sparingly
/// for screen heroes; sections stay compact. All colors resolve from the
/// ambient theme so light/dark keep working.
abstract final class PremiumType {
  static TextStyle display(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.9,
      height: 1.08,
      color: scheme.onSurface,
    );
  }

  static TextStyle hero(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.12,
      color: scheme.onSurface,
    );
  }

  static TextStyle eyebrow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: scheme.primary,
    );
  }

  static TextStyle cardTitle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.25,
      color: scheme.onSurface,
    );
  }
}

/// Hero surface: deep forest → forest gradient, ivory text, soft emerald glow.
/// Light mode keeps the same identity (deep hero on light pages is the
/// product's signature contrast moment).
abstract final class PremiumSurface {
  static BoxDecoration hero({bool glow = true}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.deepForest, AppColors.forest],
      ),
      boxShadow: glow
          ? [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.30),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ]
          : null,
    );
  }

  /// Soft tonal surface: pale sage wash → warm ivory, sage hairline.
  static BoxDecoration tonal(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.paleSage.withValues(
              alpha: palette.isDark ? 0.35 : 0.55),
          palette.surface,
        ],
      ),
      border: Border.all(
        color: palette.sage.withValues(alpha: 0.35),
      ),
    );
  }
}
