import 'package:flutter/material.dart';

class FuturisticTextTheme {
  static const double display = 40;
  static const double hero = 32;
  static const double headline = 24;
  static const double title = 20;
  static const double titleSmall = 16;
  static const double body = 14;
  static const double caption = 13;

  static const FontWeight w400 = FontWeight.w400;
  static const FontWeight w500 = FontWeight.w500;
  static const FontWeight w600 = FontWeight.w600;
  static const FontWeight w700 = FontWeight.w700;
  static const FontWeight w800 = FontWeight.w800;

  static TextStyle _style(
    double size,
    FontWeight weight,
    double height,
    Color color,
  ) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
      letterSpacing: size >= 28 ? -0.5 : (size >= 20 ? -0.3 : 0.0),
    );
  }

  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final Color onSurface = isDark
        ? const Color(0xFFF0F0FF)
        : const Color(0xFF17182A);
    final Color muted = isDark
        ? const Color(0xFF9A9CC8)
        : const Color(0xFF5A5C78);

    return TextTheme(
      displayLarge: _style(40, FontWeight.w800, 1.1, onSurface),
      displayMedium: _style(32, FontWeight.w800, 1.15, onSurface),
      headlineLarge: _style(28, FontWeight.w700, 1.2, onSurface),
      headlineMedium: _style(24, FontWeight.w700, 1.25, onSurface),
      headlineSmall: _style(20, FontWeight.w600, 1.3, onSurface),
      titleLarge: _style(18, FontWeight.w700, 1.4, onSurface),
      titleMedium: _style(16, FontWeight.w600, 1.4, onSurface),
      titleSmall: _style(14, FontWeight.w600, 1.4, onSurface),
      bodyLarge: _style(16, FontWeight.w400, 1.35, onSurface),
      bodyMedium: _style(14, FontWeight.w400, 1.4, onSurface),
      bodySmall: _style(12, FontWeight.w400, 1.4, muted),
      labelLarge: _style(14, FontWeight.w600, 1.3, onSurface),
      labelMedium: _style(12, FontWeight.w600, 1.3, muted),
      labelSmall: _style(11, FontWeight.w600, 1.3, muted),
    );
  }
}
