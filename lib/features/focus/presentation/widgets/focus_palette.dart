import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Shared palette for the SprintX / Focus experience.
///
/// SprintX consumes the SAME global Student OS theme as the rest of the app —
/// there is no Focus-only theme. Every field below is derived from the
/// canonical [AppPalette] (`AppTheme.colorsOf(context)`), so Light, Dark and
/// System theme modes flow into SprintX automatically, exactly like
/// Home / Tasks / Planning.
///
/// FOREST / EMERALD / SAGE ONLY. Field notes (canonical mapping):
/// - [bgTop]/[bgBottom]: session background gradient in the green family
///   (mist → pale sage in light; deep emerald in dark).
/// - [primary]: deep forest emerald — primary execution buttons, timer ring,
///   selected duration chips. Replaces the former blue action accent.
/// - [secondary]: sage tonal step — stopwatch ring, secondary actions.
///   Replaces the former purple.
/// - `tint*` fields: tinted container backgrounds with readable foregrounds,
///   derived from the matching container/on-container tokens (or a translucent
///   wash of the semantic color) so they adapt to dark mode. All green.
/// - [track]: neutral progress-track color ([AppPalette.border]).
@immutable
class FocusPalette {
  const FocusPalette._({
    required this.bgTop,
    required this.bgBottom,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.tintBlue,
    required this.tintBlueFg,
    required this.tintViolet,
    required this.tintVioletFg,
    required this.tintSuccess,
    required this.tintSuccessFg,
    required this.tintError,
    required this.tintErrorFg,
    required this.tintWarning,
    required this.tintWarningFg,
    required this.track,
    required this.isDark,
  });

  /// Resolves the palette from the ambient [Theme] via the canonical
  /// [AppPalette], so SprintX always matches the rest of the app.
  factory FocusPalette.of(BuildContext context) {
    final p = AppTheme.colorsOf(context);
    final dark = p.isDark;
    return FocusPalette._(
      bgTop: dark ? AppColors.veryDeepEmerald : AppColors.mist,
      bgBottom: dark ? AppColors.deepForestDark : AppColors.paleSage,
      primary: p.accent,
      // Paired mate of [primary]: white in light mode, deep ink in dark
      // mode (where the accent is a light sage). Never hardcode white —
      // white-on-sage is invisible.
      onPrimary: p.onPrimary,
      secondary: p.scheme.secondary,
      success: p.success,
      warning: p.warning,
      error: p.error,
      text: p.onSurface,
      textSecondary: p.onSurfaceMuted,
      textMuted: p.textTertiary,
      surface: p.surface,
      surfaceElevated: p.surfaceElevated,
      border: p.border,
      tintBlue: p.accentContainer,
      tintBlueFg: p.onAccentContainer,
      tintViolet: p.secondaryContainer,
      tintVioletFg: p.scheme.onSecondaryContainer,
      tintSuccess: p.success.withValues(alpha: dark ? 0.18 : 0.14),
      tintSuccessFg: dark ? p.success : _darken(p.success),
      tintError: p.error.withValues(alpha: dark ? 0.18 : 0.12),
      tintErrorFg: p.error,
      tintWarning: p.warning.withValues(alpha: dark ? 0.20 : 0.16),
      tintWarningFg: dark ? p.warning : _darken(p.warning),
      track: p.border,
      isDark: dark,
    );
  }

  /// Darkens a semantic color for readable text on a light tint.
  /// Computed (no hex literals) so it tracks the canonical tokens.
  static Color _darken(Color c) =>
      HSLColor.fromColor(c).withLightness(0.32).toColor();

  /// Canonical light values — prefer [FocusPalette.of] so dark mode adapts.
  /// All emerald/sage; no blue, purple, orange.
  static const FocusPalette light = FocusPalette._(
    bgTop: AppColors.mist,
    bgBottom: AppColors.paleSage,
    primary: AppColors.forest,
    onPrimary: Colors.white,
    secondary: AppColors.mutedGreen,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    text: AppColors.onSurfaceLight,
    textSecondary: AppColors.onSurfaceMutedLight,
    textMuted: AppColors.textTertiaryLight,
    surface: AppColors.naturalWhite,
    surfaceElevated: AppColors.surfaceElevatedLight,
    border: AppColors.outlineLight,
    tintBlue: AppColors.paleSage,
    tintBlueFg: AppColors.deepForest,
    tintViolet: AppColors.paleSage,
    tintVioletFg: AppColors.deepForest,
    tintSuccess: Color(0x242E7D5B),
    tintSuccessFg: Color(0xFF1F5C44),
    tintError: Color(0x1F2F453D),
    tintErrorFg: AppColors.error,
    tintWarning: Color(0x297A8450),
    tintWarningFg: Color(0xFF5C6538),
    track: AppColors.outlineLight,
    isDark: false,
  );

  /// Canonical dark values — prefer [FocusPalette.of] so the theme adapts.
  /// Deep emerald washes; no blue, purple, orange.
  static const FocusPalette dark = FocusPalette._(
    bgTop: AppColors.veryDeepEmerald,
    bgBottom: AppColors.deepForestDark,
    primary: AppColors.sageDark,
    onPrimary: Color(0xFF08211C),
    secondary: AppColors.mutedGreenDark,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    text: AppColors.onSurfaceDark,
    textSecondary: AppColors.onSurfaceMutedDark,
    textMuted: AppColors.textTertiaryDark,
    surface: AppColors.surfaceDark,
    surfaceElevated: AppColors.surfaceElevatedDark,
    border: AppColors.outlineDark,
    tintBlue: AppColors.paleSageDark,
    tintBlueFg: AppColors.paleSage,
    tintViolet: AppColors.paleSageDark,
    tintVioletFg: AppColors.paleSage,
    tintSuccess: Color(0x2E2E7D5B),
    tintSuccessFg: AppColors.success,
    tintError: Color(0x2E2F453D),
    tintErrorFg: AppColors.error,
    tintWarning: Color(0x337A8450),
    tintWarningFg: AppColors.warning,
    track: AppColors.outlineDark,
    isDark: true,
  );

  final Color bgTop;
  final Color bgBottom;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color surface;
  final Color surfaceElevated;
  final Color border;

  /// Tinted container roles for badges, pills and tool cards.
  /// Names retained for compatibility; all resolve to emerald/sage washes.
  final Color tintBlue;
  final Color tintBlueFg;
  final Color tintViolet;
  final Color tintVioletFg;
  final Color tintSuccess;
  final Color tintSuccessFg;
  final Color tintError;
  final Color tintErrorFg;
  final Color tintWarning;
  final Color tintWarningFg;

  /// Neutral progress-track color.
  final Color track;
  final bool isDark;
}
