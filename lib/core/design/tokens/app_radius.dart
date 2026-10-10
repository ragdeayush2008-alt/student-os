import 'package:flutter/material.dart';

/// Central border radius scale for Student OS Academic Command Center.
///
/// Consistent scale: 8 / 12 / 16 / 20 / 24 / pill(999).
abstract final class LiquidRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 24;
  static const double pill = 999;

  static const Radius xsRadius = Radius.circular(xs);
  static const Radius smRadius = Radius.circular(sm);
  static const Radius mdRadius = Radius.circular(md);
  static const Radius lgRadius = Radius.circular(lg);
  static const Radius xlRadius = Radius.circular(xl);
  static const Radius xxlRadius = Radius.circular(xxl);
  static const Radius pillRadius = Radius.circular(pill);

  static const BorderRadius xsAll = BorderRadius.all(xsRadius);
  static const BorderRadius smAll = BorderRadius.all(smRadius);
  static const BorderRadius mdAll = BorderRadius.all(mdRadius);
  static const BorderRadius lgAll = BorderRadius.all(lgRadius);
  static const BorderRadius xlAll = BorderRadius.all(xlRadius);
  static const BorderRadius xxlAll = BorderRadius.all(xxlRadius);
  static const BorderRadius pillAll = BorderRadius.all(pillRadius);

  // Sheet top radius
  static const BorderRadius sheetTop = BorderRadius.vertical(top: xxlRadius);
  static const BorderRadius dialog = BorderRadius.all(xxlRadius);
}
