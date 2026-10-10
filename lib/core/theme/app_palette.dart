import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Semantic colors for the active theme in Student OS.
///
/// UI reads these semantic colors via `AppTheme.colorsOf(context)`.
/// They adapt automatically between light and dark modes.
@immutable
class AppPalette {
  final ColorScheme scheme;
  final bool isDark;

  const AppPalette({required this.scheme, required this.isDark});

  // Base background & surfaces
  Color get background => scheme.surface;
  Color get backgroundSecondary =>
      isDark ? AppColors.backgroundSecondaryDark : AppColors.backgroundSecondaryLight;
  Color get surface => scheme.surfaceContainerLow;
  Color get surfaceElevated =>
      isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight;
  Color get surfaceVariant => scheme.surfaceContainerHighest;

  // Accents
  Color get primary => scheme.primary;
  Color get onPrimary => scheme.onPrimary;

  /// Paired emphasis tokens — THE canonical selected/active surface pair.
  ///
  /// RULE: [selectedBackground] and [selectedForeground] must ALWAYS be
  /// used together. Never pair an adaptive primary background with a
  /// hardcoded `Colors.white` foreground: in dark mode the primary is a
  /// light sage, so white text becomes invisible. [selectedForeground]
  /// resolves to white in light mode and deep ink in dark mode — it is the
  /// designed mate of [selectedBackground] in both modes.
  Color get selectedBackground => scheme.primary;
  Color get selectedForeground => scheme.onPrimary;
  Color get primaryContainer => scheme.primaryContainer;
  Color get onPrimaryContainer => scheme.onPrimaryContainer;
  Color get secondary => scheme.secondary;
  Color get onSecondary => scheme.onSecondary;
  Color get secondaryContainer => scheme.secondaryContainer;

  /// Primary action accent — deep forest emerald. Use for important primary
  /// actions, important links, and execution/action indicators. Do not use it
  /// as a broad surface or container color.
  Color get accent =>
      isDark ? AppColors.sageDark : AppColors.studentBlue;
  Color get accentDark =>
      isDark ? AppColors.sageDark : AppColors.studentBlueDark;
  Color get accentContainer =>
      isDark ? AppColors.paleSageDark : AppColors.studentBlueContainer;
  Color get onAccentContainer => isDark
      ? AppColors.paleSage
      : AppColors.onStudentBlueContainer;
  Color get accentSecondary => scheme.secondary;

  // Text hierarchy
  Color get onSurface => scheme.onSurface;
  Color get onSurfaceMuted =>
      isDark ? AppColors.onSurfaceMutedDark : AppColors.onSurfaceMutedLight;
  Color get text => scheme.onSurface;
  Color get textPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get textTertiary =>
      isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
  Color get textDisabled =>
      isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight;
  Color get textMuted => onSurfaceMuted;

  // Borders & Outlines
  Color get outline => scheme.outlineVariant;
  Color get border => isDark ? AppColors.outlineDark : AppColors.outlineLight;
  Color get borderStrong =>
      isDark ? AppColors.glassBorderStrongDark : AppColors.glassBorderStrongLight;
  Color get glassBorder =>
      isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

  // Liquid Glass Tokens
  Color get glass => isDark ? AppColors.glassDark : AppColors.glassLight;
  Color get glassStrong =>
      isDark ? AppColors.glassStrongDark : AppColors.glassStrongLight;
  Color get glassSubtle =>
      isDark ? AppColors.glassSubtleDark : AppColors.glassSubtleLight;

  // Green/Forest tonal family — THE primary visual language for learning,
  // consistency, progress, wellbeing, success and calm/active states.
  Color get deepForest =>
      isDark ? AppColors.deepForestDark : AppColors.deepForest;
  Color get forest => isDark ? AppColors.forestDark : AppColors.forest;
  Color get mutedGreen =>
      isDark ? AppColors.mutedGreenDark : AppColors.mutedGreen;
  Color get sage => isDark ? AppColors.sageDark : AppColors.sage;
  Color get softSage => isDark ? AppColors.softSageDark : AppColors.softSage;
  Color get paleSage => isDark ? AppColors.paleSageDark : AppColors.paleSage;

  /// Very light sage / mist — the lightest tonal step (light backgrounds).
  Color get mist => isDark ? AppColors.deepForestDark : AppColors.mist;

  /// Natural warm white — card surfaces in light mode.
  Color get naturalWhite =>
      isDark ? AppColors.surfaceVariantDark : AppColors.naturalWhite;

  // Status tokens
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get error => scheme.error;
  Color get info => AppColors.info;
  Color get streak => AppColors.streak;

  // Neon tokens (controlled)
  Color get neonPink => AppColors.neonPink;
  Color get neonBlue => AppColors.neonBlue;
  Color get neonGreen => AppColors.neonGreen;
  Color get neonYellow => AppColors.neonYellow;
  Color get neonOrange => AppColors.neonOrange;
  Color get neonPurple => AppColors.neonPurple;

  // Gradients — green family only. No blue/purple/pink anywhere.
  List<Color> get rewardGradient => const [
    AppColors.rewardStart,
    AppColors.rewardEnd,
  ];
  List<Color> get accentGradient => const [
    AppColors.accentStart,
    AppColors.accentEnd,
  ];
  List<Color> get neonGradient => const [
    AppColors.deepForest,
    AppColors.forest,
    AppColors.mutedGreen,
    AppColors.sage,
  ];
  List<Color> get sunsetGradient => const [
    AppColors.forest,
    AppColors.mutedGreen,
    AppColors.sage,
  ];

  /// Forest -> Sage identity gradient (the product's signature tone).
  List<Color> get forestGradient => const [
    AppColors.deepForest,
    AppColors.forest,
  ];

  /// Forest -> Muted Green -> Sage data-visualization family.
  List<Color> get dataGradient => const [
    AppColors.forest,
    AppColors.mutedGreen,
    AppColors.sage,
    AppColors.softSage,
  ];

  /// Forest action gradient — deep emerald tonal depth.
  List<Color> get actionGradient => const [
    AppColors.studentBlue,
    AppColors.studentBlueDark,
  ];

  List<Color> get primaryGradient => forestGradient;

  // Shadows
  List<BoxShadow> get glassShadow => [
    BoxShadow(
      color: (isDark ? Colors.black : Colors.black).withValues(alpha: isDark ? 0.25 : 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: (isDark ? Colors.black : Colors.black).withValues(alpha: isDark ? 0.40 : 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
