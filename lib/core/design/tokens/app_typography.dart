import 'package:flutter/material.dart';

/// Central typography system for Student OS Liquid Glass.
abstract final class LiquidTypography {
  static const String fontFamily = 'Inter';

  static TextStyle display({required Color color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4, // Less negative for "airy" feel
    height: 1.15,
    color: color,
  );

  static TextStyle largeTitle({required Color color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2, // Less negative
    height: 1.2,
    color: color,
  );

  static TextStyle title({required Color color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1, // Less negative
    height: 1.25,
    color: color,
  );

  static TextStyle headline({required Color color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: color,
  );

  static TextStyle body({required Color color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
    color: color,
  );

  static TextStyle bodyMedium({required Color color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: color,
  );

  static TextStyle bodySmall({required Color color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.35,
    color: color,
  );

  static TextStyle label({required Color color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.3,
    color: color,
  );

  static TextStyle caption({required Color color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.2,
    color: color,
  );

  static TextStyle numericStat({required Color color, double fontSize = 28}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.1,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );

  /// Builds a complete Flutter [TextTheme] for light/dark mode.
  static TextTheme buildTextTheme(Brightness brightness, {required Color textPrimary, required Color textSecondary}) {
    return TextTheme(
      displayLarge: display(color: textPrimary),
      displayMedium: largeTitle(color: textPrimary),
      displaySmall: title(color: textPrimary),
      headlineLarge: largeTitle(color: textPrimary),
      headlineMedium: title(color: textPrimary),
      headlineSmall: headline(color: textPrimary),
      titleLarge: headline(color: textPrimary),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
        color: textPrimary,
      ),
      bodyLarge: body(color: textPrimary),
      bodyMedium: bodyMedium(color: textPrimary),
      bodySmall: bodySmall(color: textSecondary),
      labelLarge: label(color: textPrimary),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.25,
        color: textSecondary,
      ),
      labelSmall: caption(color: textSecondary),
    );
  }
}
