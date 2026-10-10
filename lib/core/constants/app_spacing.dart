import 'package:flutter/material.dart';

/// Central spacing scale for Student OS Academic Command Center.
///
/// Strict 8-point system: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 / 64.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double giant = 64;

  /// Standard screen horizontal padding.
  static const double screen = md;

  /// Standard gap between cards in a stacked list.
  static const double cardGap = md;

  /// Standard gap between sections on a screen.
  static const double sectionGap = xxl;

  /// Max content width for large (tablet/desktop) layouts.
  static const double maxContentWidth = 720;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screen,
  );

  static const EdgeInsets allScreen = EdgeInsets.all(screen);
}
