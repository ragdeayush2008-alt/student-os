import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../animations/app_page_transitions.dart';
import '../design/tokens/app_typography.dart';
import 'app_palette.dart';
import 'theme_variants.dart';

export 'app_palette.dart' show AppPalette;
export 'app_text_theme.dart' show AppBuildContextText;
export 'theme_variants.dart' show ThemeVariantId;

/// Builds the complete [ThemeData] for Student OS.
///
/// FOREST / EMERALD / SAGE ONLY. Light mode layers mist/pale-sage
/// backgrounds under natural-white surfaces; dark mode uses deep
/// emerald/forest surfaces. SOLID surfaces throughout — no glassmorphism,
/// no blur.
abstract final class AppTheme {
  static const String fontFamily = 'Inter';

  /// Light theme (mist/pale-sage background, natural-white cards).
  static ThemeData light() => _buildTheme(Brightness.light, ThemeVariantId.defaultTheme);

  /// Dark theme (deep emerald/forest surfaces).
  static ThemeData dark() => _buildTheme(Brightness.dark, ThemeVariantId.defaultTheme);

  /// Builds theme for a specified [ThemeVariantId] and [Brightness].
  static ThemeData forVariant(Brightness brightness, ThemeVariantId variant) {
    return _buildTheme(brightness, variant);
  }

  static ThemeData _buildTheme(Brightness brightness, ThemeVariantId variant) {
    final isDark = brightness == Brightness.dark;

    final scheme = variant == ThemeVariantId.defaultTheme
        ? (isDark ? _darkColorScheme() : _lightColorScheme())
        : ThemeVariants.buildColorScheme(
            variant: variant,
            brightness: brightness,
          );

    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTheme = LiquidTypography.buildTextTheme(
      brightness,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
    );

    final scaffoldBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.outlineDark : AppColors.outlineLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
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
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: (isDark ? Colors.black : const Color(0xFF101828))
            .withValues(alpha: isDark ? 0.35 : 0.08),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
        height: 64,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : textSecondary,
            size: 24,
          );
        }),        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : textSecondary,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 0.5,
        space: 0,
      ),
      // Contextual (three-dot) menus share one Deep Forest treatment across
      // every screen: solid emerald surface, light text/icons, restrained sage
      // selected/pressed state, and a small emerald accent for action items.
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.deepForest,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: isDark
                ? AppColors.softSageDark.withValues(alpha: 0.35)
                : AppColors.forestDark,
          ),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.bodyMedium?.copyWith(
              color: AppColors.paleSage,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          );
        }),
        iconColor: Colors.white,
      ),
      // NOTE: foreground is scheme.onPrimary (NOT hardcoded white). Dark
      // mode primary is a light sage, so white text would be invisible.
      // Background + foreground are always designed as a pair.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.40),
          disabledForegroundColor:
              scheme.onPrimary.withValues(alpha: 0.60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.40),
          disabledForegroundColor:
              scheme.onPrimary.withValues(alpha: 0.60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      // Safety nets so Material selection controls always pair background
      // + foreground from the scheme (never an invisible combination).
      // Screens that specify explicit colors keep their own values.
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary,
        disabledColor: scheme.surfaceContainer,
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle:
            textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
        checkmarkColor: scheme.onPrimary,
        deleteIconColor: scheme.onSurfaceVariant,
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return scheme.surfaceContainer;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return textSecondary.withValues(alpha: 0.50);
            }
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return scheme.onSurface;
          }),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return scheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: borderColor, width: 1),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.surfaceContainerHighest.withValues(alpha: 0.50);
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return scheme.outline;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: scheme.primary, width: 1.5);
          }
          return BorderSide(color: borderColor, width: 1.5);
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.onSurfaceVariant;
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        labelStyle:
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return scheme.primary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.primary.withValues(alpha: 0.04);
          }
          return Colors.transparent;
        }),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondary.withValues(alpha: 0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }

  static ColorScheme _lightColorScheme() {
    return const ColorScheme.light(
      // Green family is the product identity.
      primary: AppColors.forest,
      onPrimary: Colors.white,
      primaryContainer: AppColors.paleSage,
      onPrimaryContainer: AppColors.deepForest,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.deepForest,
      // Mist background -> natural white cards.
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
      shadow: Color(0xFF16241F),
      tertiary: AppColors.sage,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.paleSage,
      onTertiaryContainer: AppColors.deepForest,
    );
  }

  static ColorScheme _darkColorScheme() {
    return const ColorScheme.dark(
      // Deep emerald surfaces rather than an inverted light scheme.
      primary: AppColors.sageDark,
      onPrimary: Color(0xFF08211C),
      primaryContainer: Color(0xFF1E3A32),
      onPrimaryContainer: AppColors.paleSage,
      secondary: AppColors.mutedGreenDark,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.paleSageDark,
      onSecondaryContainer: AppColors.paleSage,
      surface: AppColors.veryDeepEmerald,
      onSurface: AppColors.onSurfaceDark,
      surfaceContainerLowest: Color(0xFF051713),
      surfaceContainerLow: AppColors.deepForestDark,
      surfaceContainer: AppColors.surfaceVariantDark,
      surfaceContainerHighest: AppColors.forestDark,
      onSurfaceVariant: AppColors.onSurfaceMutedDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineDark,
      error: AppColors.error,
      onError: Colors.white,
      shadow: Colors.black,
      tertiary: AppColors.softSageDark,
      onTertiary: Color(0xFF08211C),
      tertiaryContainer: AppColors.paleSageDark,
      onTertiaryContainer: AppColors.paleSage,
    );
  }

  /// Semantic color accessor from a [BuildContext].
  static AppPalette colorsOf(BuildContext context) => AppPalette(
    scheme: Theme.of(context).colorScheme,
    isDark: Theme.of(context).brightness == Brightness.dark,
  );
}
