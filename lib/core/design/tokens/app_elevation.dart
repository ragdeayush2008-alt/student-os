import 'package:flutter/material.dart';

/// Central elevation and shadow presets for Student OS Liquid Glass.
abstract final class LiquidElevation {
  static const double none = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 8;
  static const double floating = 16;

  /// Subtle Level 1 shadow
  static List<BoxShadow> subtle(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  /// Standard Level 2 glass card shadow
  static List<BoxShadow> glass(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.08),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Elevated Level 3 / floating modal shadow
  static List<BoxShadow> elevated(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.16),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  /// Soft glow for active elements
  static List<BoxShadow> glow(Color accent) => [
    BoxShadow(
      color: accent.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}
