import 'package:flutter/material.dart';

/// Central border tokens for Student OS Liquid Glass Design System.
abstract final class LiquidBorders {
  static const double hair = 0.5;
  static const double thin = 1.0;
  static const double medium = 1.5;
  static const double thick = 2.0;

  /// Subtle opacity for glass borders (10-15%)
  static const double subtleOpacity = 0.12;

  /// Standard opacity for interactive glass borders (20-28%)
  static const double standardOpacity = 0.22;

  /// Strong opacity for active/selected borders (40-60%)
  static const double strongOpacity = 0.50;

  static BorderSide thinSide(Color color, [double opacity = 1.0]) =>
      BorderSide(color: opacity == 1.0 ? color : color.withValues(alpha: opacity), width: thin);

  static BorderSide hairSide(Color color, [double opacity = 1.0]) =>
      BorderSide(color: opacity == 1.0 ? color : color.withValues(alpha: opacity), width: hair);

  static BorderSide mediumSide(Color color, [double opacity = 1.0]) =>
      BorderSide(color: opacity == 1.0 ? color : color.withValues(alpha: opacity), width: medium);

  static Border allThin(Color color, [double opacity = 1.0]) =>
      Border.all(color: opacity == 1.0 ? color : color.withValues(alpha: opacity), width: thin);

  static Border allHair(Color color, [double opacity = 1.0]) =>
      Border.all(color: opacity == 1.0 ? color : color.withValues(alpha: opacity), width: hair);
}
