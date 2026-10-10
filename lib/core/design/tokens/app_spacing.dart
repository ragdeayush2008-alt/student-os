import 'package:flutter/material.dart';

/// Central spacing scale for Student OS Academic Command Center.
///
/// Strict 8-point system: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 / 64.
abstract final class LiquidSpacing {
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

  // Prebuilt Insets
  static const EdgeInsets zero = EdgeInsets.zero;
  static const EdgeInsets xxsAll = EdgeInsets.all(xxs);
  static const EdgeInsets xsAll = EdgeInsets.all(xs);
  static const EdgeInsets smAll = EdgeInsets.all(sm);
  static const EdgeInsets mdAll = EdgeInsets.all(md);
  static const EdgeInsets lgAll = EdgeInsets.all(lg);
  static const EdgeInsets xlAll = EdgeInsets.all(xl);
  static const EdgeInsets xxlAll = EdgeInsets.all(xxl);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: screen);
  static const EdgeInsets allScreen = EdgeInsets.all(screen);

  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets compactCardPadding = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );
  static const EdgeInsets heroCardPadding = EdgeInsets.all(lg);
}
