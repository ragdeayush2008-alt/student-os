import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Identifier for a custom theme variant.
enum ThemeVariantId {
  defaultTheme('default', 'Forest'),
  focusDark('focus_dark', 'Focus Dark'),
  academicLight('academic_light', 'Academic Light'),
  midnightScholar('midnight_scholar', 'Midnight Scholar');

  const ThemeVariantId(this.id, this.displayName);

  final String id;
  final String displayName;

  static ThemeVariantId fromId(String? id) {
    if (id == null) return ThemeVariantId.defaultTheme;
    return ThemeVariantId.values.firstWhere(
      (v) => v.id == id,
      orElse: () => ThemeVariantId.defaultTheme,
    );
  }
}

/// Specifications for building a custom [ColorScheme] based on a ThemeVariant.
abstract final class ThemeVariants {
  /// Builds a [ColorScheme] for a given [ThemeVariantId] and [Brightness].
  static ColorScheme buildColorScheme({
    required ThemeVariantId variant,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    return switch (variant) {
      ThemeVariantId.defaultTheme => _defaultScheme(isDark),
      ThemeVariantId.focusDark => _focusDarkScheme(isDark),
      ThemeVariantId.academicLight => _academicLightScheme(isDark),
      ThemeVariantId.midnightScholar => _midnightScholarScheme(isDark),
    };
  }

  // ─── Default Theme (Forest / Sage) ────────────────────────────────────

  static ColorScheme _defaultScheme(bool isDark) {
    if (isDark) {
      return const ColorScheme.dark(
        primary: AppColors.sageDark,
        onPrimary: Color(0xFF08211C),
        primaryContainer: Color(0xFF1E3A32),
        onPrimaryContainer: AppColors.paleSage,
        secondary: AppColors.secondary,
        onSecondary: Color(0xFF10252A),
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: Color(0xFF0C3B36),
        surface: AppColors.backgroundDark,
        onSurface: AppColors.onSurfaceDark,
        surfaceContainerLowest: AppColors.veryDeepEmerald,
        surfaceContainerLow: AppColors.surfaceDark,
        surfaceContainer: AppColors.surfaceVariantDark,
        surfaceContainerHighest: AppColors.forestDark,
        onSurfaceVariant: AppColors.onSurfaceMutedDark,
        outline: AppColors.outlineDark,
        outlineVariant: AppColors.outlineDark,
        error: AppColors.error,
      );
    }

    return const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: Color(0xFF0C3B36),
      surface: AppColors.backgroundLight,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerLowest: AppColors.surfaceElevatedLight,
      surfaceContainerLow: AppColors.surfaceLight,
      surfaceContainer: AppColors.surfaceVariantLight,
      surfaceContainerHighest: AppColors.paleSage,
      onSurfaceVariant: AppColors.onSurfaceMutedLight,
      outline: AppColors.outlineLight,
      outlineVariant: AppColors.outlineLight,
      error: AppColors.error,
    );
  }

  // ─── Focus Theme (Deep Pine Focus — luminous sage on pine charcoal) ──
  //
  // Same theme slot, now a forest-family expression: green-tinted charcoal
  // surfaces with a luminous sage primary. No amber.

  static ColorScheme _focusDarkScheme(bool isDark) {
    if (isDark) {
      return const ColorScheme.dark(
        primary: Color(0xFF8FB49A), // Luminous sage focus accent
        onPrimary: Color(0xFF08211C),
        primaryContainer: Color(0xFF1E3A32),
        onPrimaryContainer: Color(0xFFE7EFDC),
        secondary: Color(0xFF2E7D5B), // Deep emerald
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF1E3A32),
        onSecondaryContainer: Color(0xFFA9C1AE),
        surface: Color(0xFF0B1512), // Pine-tinted focus charcoal
        onSurface: Color(0xFFEFF4EC),
        surfaceContainerLowest: Color(0xFF060F0C),
        surfaceContainerLow: Color(0xFF101F1A),
        surfaceContainer: Color(0xFF16261F),
        surfaceContainerHighest: Color(0xFF1E3329),
        onSurfaceVariant: Color(0xFFA9BFAF),
        outline: Color(0xFF24473A),
        outlineVariant: Color(0xFF24473A),
        error: Color(0xFFE7EFDC),
        onError: Color(0xFF08211C),
      );
    }

    // Light side: warm paper with forest ink.
    return const ColorScheme.light(
      primary: AppColors.forest,
      onPrimary: Colors.white,
      primaryContainer: AppColors.paleSage,
      onPrimaryContainer: AppColors.deepForest,
      secondary: AppColors.mutedGreen,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.paleSage,
      onSecondaryContainer: AppColors.deepForest,
      surface: AppColors.mist,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerLowest: AppColors.surfaceElevatedLight,
      surfaceContainerLow: AppColors.naturalWhite,
      surfaceContainer: AppColors.surfaceVariantLight,
      surfaceContainerHighest: AppColors.paleSage,
      onSurfaceVariant: AppColors.onSurfaceMutedLight,
      outline: AppColors.outlineLight,
      outlineVariant: AppColors.outlineLight,
      error: AppColors.error,
      onError: Colors.white,
    );
  }

  // ─── Academic Light Theme (Warm Paper / Deep Forest Ink) ─────────────
  //
  // Same theme slot, now warm ivory paper with forest ink. No Oxford navy.

  static ColorScheme _academicLightScheme(bool isDark) {
    if (isDark) {
      return const ColorScheme.dark(
        primary: Color(0xFF8FB49A),
        onPrimary: Color(0xFF08211C),
        primaryContainer: Color(0xFF1E3A32),
        onPrimaryContainer: Color(0xFFE7EFDC),
        secondary: Color(0xFF2E7D5B),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF1E3A32),
        onSecondaryContainer: Color(0xFFA9C1AE),
        surface: AppColors.veryDeepEmerald,
        onSurface: AppColors.onSurfaceDark,
        surfaceContainerLowest: Color(0xFF051713),
        surfaceContainerLow: AppColors.deepForestDark,
        surfaceContainer: AppColors.surfaceVariantDark,
        surfaceContainerHighest: AppColors.forestDark,
        onSurfaceVariant: AppColors.onSurfaceMutedDark,
        outline: AppColors.outlineDark,
        outlineVariant: AppColors.outlineDark,
        error: Color(0xFFE7EFDC),
        onError: Color(0xFF08211C),
      );
    }

    return const ColorScheme.light(
      primary: AppColors.forest, // Deep forest academic ink
      onPrimary: Colors.white,
      primaryContainer: AppColors.paleSage,
      onPrimaryContainer: AppColors.deepForest,
      secondary: AppColors.mutedGreen,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.paleSage,
      onSecondaryContainer: AppColors.deepForest,
      surface: Color(0xFFFAFCF7), // Warm paper
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFFAFCF7),
      surfaceContainer: AppColors.surfaceVariantLight,
      surfaceContainerHighest: AppColors.paleSage,
      onSurfaceVariant: AppColors.onSurfaceMutedLight,
      outline: AppColors.outlineLight,
      outlineVariant: AppColors.outlineLight,
      error: AppColors.error,
      onError: Colors.white,
    );
  }

  // ─── Midnight Scholar (Pine Night — luminous sage on deep pine) ───────
  //
  // Same theme slot, now a quiet forest-at-night expression. No sapphire,
  // cyan glow, or indigo.

  static ColorScheme _midnightScholarScheme(bool isDark) {
    if (isDark) {
      return const ColorScheme.dark(
        primary: Color(0xFF8FB49A), // Luminous sage scholar glow
        onPrimary: Color(0xFF08211C),
        primaryContainer: Color(0xFF1E3A32),
        onPrimaryContainer: Color(0xFFE7EFDC),
        secondary: Color(0xFF4F7D68), // Muted pine accent
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF22382F),
        onSecondaryContainer: Color(0xFFA9C1AE),
        surface: Color(0xFF08211C), // Deep pine night
        onSurface: Color(0xFFEFF4EC),
        surfaceContainerLowest: Color(0xFF04100C),
        surfaceContainerLow: Color(0xFF0C2924),
        surfaceContainer: Color(0xFF1A322A),
        surfaceContainerHighest: Color(0xFF1E3A32),
        onSurfaceVariant: Color(0xFFA9BFAF),
        outline: Color(0xFF2B4A3E),
        outlineVariant: Color(0xFF2B4A3E),
        error: Color(0xFFE7EFDC),
        onError: Color(0xFF08211C),
      );
    }

    return const ColorScheme.light(
      primary: AppColors.forest,
      onPrimary: Colors.white,
      primaryContainer: AppColors.paleSage,
      onPrimaryContainer: AppColors.deepForest,
      secondary: AppColors.mutedGreen,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.paleSage,
      onSecondaryContainer: AppColors.deepForest,
      surface: AppColors.mist,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerLowest: AppColors.surfaceElevatedLight,
      surfaceContainerLow: AppColors.naturalWhite,
      surfaceContainer: AppColors.surfaceVariantLight,
      surfaceContainerHighest: AppColors.paleSage,
      onSurfaceVariant: AppColors.onSurfaceMutedLight,
      outline: AppColors.outlineLight,
      outlineVariant: AppColors.outlineLight,
      error: AppColors.error,
      onError: Colors.white,
    );
  }
}
