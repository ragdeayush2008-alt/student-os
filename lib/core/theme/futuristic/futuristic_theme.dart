import 'package:flutter/material.dart';

import '../../constants/app_radius.dart';
import '../../animations/app_page_transitions.dart';
import 'futuristic_colors.dart';
import '../theme_variants.dart';
import 'futuristic_text_theme.dart';

export 'futuristic_colors.dart';
export 'futuristic_text_theme.dart';

class FuturisticTheme {
  static const String fontFamily = 'Inter';

  static ThemeData light() =>
      _build(Brightness.light, ThemeVariantId.defaultTheme);
  static ThemeData dark() =>
      _build(Brightness.dark, ThemeVariantId.defaultTheme);

  static ThemeData forVariant(Brightness brightness, ThemeVariantId variant) {
    return _build(brightness, variant);
  }

  static ThemeData _build(Brightness brightness, ThemeVariantId variant) {
    final isDark = brightness == Brightness.dark;
    final colors = FuturisticColors(isDark: isDark);
    final scheme = variant == ThemeVariantId.defaultTheme
        ? _buildColorScheme(isDark)
        : ThemeVariants.buildColorScheme(
            variant: variant,
            brightness: brightness,
          );
    final textTheme = FuturisticTextTheme.textTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitions(),
          TargetPlatform.iOS: AppPageTransitions(),
          TargetPlatform.macOS: AppPageTransitions(),
          TargetPlatform.linux: AppPageTransitions(),
          TargetPlatform.windows: AppPageTransitions(),
          TargetPlatform.fuchsia: AppPageTransitions(),
        },
      ),
    ).copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 17),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.glassBorder.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colors.primary.withValues(alpha: 0.1),
        height: 56,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.primary : colors.onSurfaceMuted,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? colors.primary : colors.onSurfaceMuted,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFFE5E5EA),
        thickness: 0.5,
        space: 0,
      ),
      filledButtonTheme: const FilledButtonThemeData(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.glassBg.withValues(alpha: 0.5),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceMuted.withValues(alpha: 0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }

  static ColorScheme _buildColorScheme(bool isDark) {
    final colors = FuturisticColors(isDark: isDark);
    return isDark
        ? ColorScheme.dark(
            primary: colors.primary,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFF1A1A3A),
            onPrimaryContainer: const Color(0xFF8B8BFF),
            secondary: colors.secondary,
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFF0A2A2A),
            onSecondaryContainer: const Color(0xFF5EFFD0),
            surface: colors.background,
            onSurface: colors.onSurface,
            surfaceContainerLowest: colors.background,
            surfaceContainerLow: colors.surface,
            surfaceContainer: colors.surfaceVariant,
            surfaceContainerHighest: const Color(0xFF2A2C50),
            onSurfaceVariant: colors.onSurfaceMuted,
            outline: colors.glassBorder.withValues(alpha: 0.8),
            outlineVariant: colors.glassBorder.withValues(alpha: 0.8),
            error: FuturisticColors.error,
          )
        : ColorScheme.light(
            primary: colors.primary,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFEAE6F8),
            onPrimaryContainer: const Color(0xFFA9C1AE),
            secondary: colors.secondary,
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFD6F5F1),
            onSecondaryContainer: const Color(0xFF0A3B36),
            surface: colors.background,
            onSurface: colors.onSurface,
            surfaceContainerLowest: const Color(0xFFF8F7F4),
            surfaceContainerLow: colors.surface,
            surfaceContainer: colors.surfaceVariant,
            surfaceContainerHighest: const Color(0xFFEEEEEA),
            onSurfaceVariant: colors.onSurfaceMuted,
            outline: colors.glassBorder.withValues(alpha: 0.8),
            outlineVariant: colors.glassBorder.withValues(alpha: 0.8),
            error: FuturisticColors.error,
          );
  }
}
