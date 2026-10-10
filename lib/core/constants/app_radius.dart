import 'package:flutter/material.dart';

/// Central border radius scale for Student OS Academic Command Center.
///
/// Consistent scale: 8 / 12 / 16 / 20 / 24 / pill(999).
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24; // hero
  static const double xxl = 24; // capped: hero max
  static const double pill = 999;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));

  static BorderRadius get pillAll => BorderRadius.all(Radius.circular(pill));
}
