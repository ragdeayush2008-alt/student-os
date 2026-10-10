import 'package:flutter/material.dart';

class FuturisticColors {
  final bool isDark;

  const FuturisticColors({required this.isDark});

  // === Primary accent — muted violet-blue ===
  static const Color _primary = Color(0xFF111111);
  Color get primary => isDark ? primaryDark : _primary;
  static const Color primaryLight = Color(0xFF4F7D68);
  static const Color primaryDark = Color(0xFF123D35);
  static const Color primaryGlow = Color(0xFF285C4D);

  // === Secondary accent - Electric cyan ===
  static const Color _secondary = Color(0xFF2E7D5B);
  Color get secondary => isDark ? secondaryDark : _secondary;
  static const Color secondaryLight = Color(0xFF6F967F);
  static const Color secondaryDark = Color(0xFF1F5C44);

  // === Neon accents ===
  static const Color neonPink = Color(0xFF2F453D);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color neonGreen = Color(0xFF2E7D5B);
  static const Color neonYellow = Color(0xFF7A8450);
  static const Color neonOrange = Color(0xFF7A8450);
  static const Color neonPurple = Color(0xFF6F967F);
  static const Color neonRed = Color(0xFF2F453D);

  // === Background ===
  Color get background => isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);

  static const Color backgroundDark = Color(0xFF050510);
  static const Color backgroundLight = Color(0xFFF7F6F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantLight = Color(0xFFF5F5F7);
  Color get surface => isDark ? surfaceDark : surfaceLight;
  Color get surfaceVariant => isDark ? surfaceVariantDark : surfaceVariantLight;
  static const Color surfaceVariantDark = Color(0xFF1A1A3A);

  // === Glass morphism ===
  Color get glassBg => isDark
      ? const Color(0xFF2A2A2A).withValues(alpha: 0.8)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.95);

  Color get glassBorder => isDark
      ? const Color(0xFF333333).withValues(alpha: 0.8)
      : const Color(0xFFE2E0DA).withValues(alpha: 0.9);

  static const Color glassBorderLight = Color(0xFFC0C0E0);
  static const Color glassBorderDark = Color(0xFF3A3A6A);

  Color get glassHighlight => isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.6);

  // === Text ===
  static const Color onSurfaceLight = Color(0xFF17182A);
  static const Color onSurfaceDark = Color(0xFFF0F0FF);
  static const Color onSurfaceMutedLight = Color(0xFF5A5C78);
  static const Color onSurfaceMutedDark = Color(0xFF9A9CC8);

  Color get onSurface => isDark ? onSurfaceDark : onSurfaceLight;
  Color get onSurfaceMuted => isDark ? onSurfaceMutedDark : onSurfaceMutedLight;

  // === Semantic ===
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFF7A8450);
  static const Color error = Color(0xFF2F453D);
  static const Color info = Color(0xFF3B82F6);
  static const Color streak = Color(0xFF777777);

  // === Gradients ===
  List<Color> get primaryGradient => const [
    Color(0xFF285C4D),
    Color(0xFF4F7D68),
  ];

  List<Color> get accentGradient => const [
    Color(0xFF2E7D5B),
    Color(0xFF285C4D),
    Color(0xFF3B82F6),
  ];

  List<Color> get neonGradient => const [
    Color(0xFF285C4D),
    Color(0xFF6F967F),
    Color(0xFF4F7D68),
    Color(0xFF2E7D5B),
  ];

  List<Color> get sunsetGradient => const [
    Color(0xFF2F453D),
    Color(0xFF285C4D),
    Color(0xFF3B82F6),
  ];

  List<Color> get meshGradient => const [
    Color(0xFF0A0A1A),
    Color(0xFF1A1A3A),
    Color(0xFF0A0A2A),
  ];

  List<Color> get glassGradient => [
    const Color(0xFFFFFFFF).withValues(alpha: 0.15),
    const Color(0xFFFFFFFF).withValues(alpha: 0.05),
  ];

  // === Glow colors ===
  Color get primaryGlowColor => primary.withValues(alpha: 0.3);
  Color get secondaryGlowColor => _secondary.withValues(alpha: 0.3);
  Color get neonPinkGlowColor => neonPink.withValues(alpha: 0.3);

  // === Shadow ===
  List<BoxShadow> get glassShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.08),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: secondary.withValues(alpha: 0.05),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  List<BoxShadow> get neonShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: secondary.withValues(alpha: 0.2),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  List<BoxShadow> get strongerShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ];
}
