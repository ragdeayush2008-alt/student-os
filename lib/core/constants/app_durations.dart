import 'package:flutter/material.dart';

@immutable
class AppTypeStyle {
  final TextStyle textStyle;
  const AppTypeStyle(this.textStyle);
}

/// Central animation duration & curve tokens for Student OS.
///
/// TCC-aligned motion system — single source of truth.
/// fast=180ms · base=300ms · page=380ms · slow=450ms
/// default/enter=easeOutCubic · exit=easeInCubic
/// (see TCC EDUCATION motion audit)
abstract final class AppDurations {
  static const Duration fastest = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration base = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  static const Duration pageTransition = Duration(milliseconds: 380);
  static const Duration page = Duration(milliseconds: 380);
  static const Duration themeTransition = Duration(milliseconds: 380);
}

/// Central curve tokens used across Student OS.
abstract final class AppCurves {
  /// Standard ease for most motion — smooth but not sluggish.
  static const Curve standard = Curves.easeOutCubic;

  /// Entrance motion — TCC aligned, no overshoot.
  static const Curve entrance = Curves.easeOutCubic;

  /// Exit motion.
  static const Curve exit = Curves.easeInCubic;

  /// Emphasis / celebration motion — restrained.
  static const Curve emphasis = Curves.easeOutCubic;

  /// Micro spring — only where useful, restrained.
  static const Curve spring = Curves.easeOutBack;
}

/// A mapper that can be reused by animated widgets marked with a
/// [ReduceMotion] preference, if a widget needs to observe platform settings.
/// Kept intentionally minimal; most transitions just use [AppDurations]/[AppCurves].
bool reduceMotionEnabled(MediaQueryData mediaQuery) =>
    mediaQuery.disableAnimations;
