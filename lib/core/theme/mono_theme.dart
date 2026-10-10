import 'package:flutter/material.dart';

class MonoTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF111111),
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF111111),
        outline: Color(0xFFE5E5EA),
        outlineVariant: Color(0xFFE5E5EA),
      ),
      textTheme: _textTheme(),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF111111),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF111111),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF111111).withValues(alpha: 0.08),
        height: 56,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? const Color(0xFF111111) : const Color(0xFF777777),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Inter', fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? const Color(0xFF111111) : const Color(0xFF777777),
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE5E5EA), thickness: 0.5, space: 0),
      filledButtonTheme: const FilledButtonThemeData(),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFF111111),
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Color(0xFF111111),
        surface: Color(0xFF1C1C1E),
        onSurface: Colors.white,
        outline: Color(0xFF38383A),
        outlineVariant: Color(0xFF38383A),
      ),
      textTheme: _textThemeDark(),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF111111),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white,
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1C1E),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF38383A), width: 0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF38383A), thickness: 0.5, space: 0),
      filledButtonTheme: const FilledButtonThemeData(),
    );
  }

  static TextTheme _textTheme() {
    const black = Color(0xFF111111);
    const grey = Color(0xFF777777);
    return TextTheme(
      displayLarge: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: black, height: 1.15, letterSpacing: -0.6),
      headlineMedium: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: black, height: 1.2, letterSpacing: -0.4),
      headlineSmall: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: black, height: 1.25),
      titleLarge: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: black, height: 1.3),
      bodyLarge: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w400, color: black, height: 1.35),
      bodyMedium: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: black, height: 1.4),
      bodySmall: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: grey, height: 1.35),
      labelLarge: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: black, height: 1.3),
      labelMedium: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: grey, height: 1.2),
    );
  }

  static TextTheme _textThemeDark() {
    const white = Colors.white;
    const grey = Color(0xFF8E8E93);
    return TextTheme(
      displayLarge: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: white, height: 1.15, letterSpacing: -0.6),
      headlineMedium: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: white, height: 1.2, letterSpacing: -0.4),
      headlineSmall: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: white, height: 1.25),
      titleLarge: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: white, height: 1.3),
      bodyLarge: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w400, color: white, height: 1.35),
      bodyMedium: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: white, height: 1.4),
      bodySmall: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: grey, height: 1.35),
      labelLarge: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: white, height: 1.3),
      labelMedium: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: grey, height: 1.2),
    );
  }
}
