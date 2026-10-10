import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Premium design tokens for Onboarding Step 2 visual language.
/// Centralized glow, depth, border, and motion system.
abstract final class OnboardingDesignTokens {
  // ─── GLOW SYSTEM ───────────────────────────────────────────────

  static const glowSoft = [
    BoxShadow(
      color: Color(0x1A2D5C4B),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  static const glowMedium = [
    BoxShadow(
      color: Color(0x2A2D5C4B),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const glowSelected = [
    BoxShadow(
      color: Color(0x3A2D5C4B),
      blurRadius: 24,
      offset: Offset(0, 6),
    ),
  ];

  // ─── DEPTH / ELEVATION ─────────────────────────────────────────

  static const double elevationSurface = 0;
  static const double elevationRaised = 1;
  static const double elevationInteractive = 2;
  static const double elevationSelected = 3;
  static const double elevationCTA = 2;

  // ─── BORDER SYSTEM ─────────────────────────────────────────────

  static BorderSide borderIdle(ColorScheme scheme) =>
      BorderSide(color: AppColors.paleSage.withValues(alpha: 0.4), width: 1);

  static BorderSide borderHover(ColorScheme scheme) =>
      BorderSide(color: AppColors.paleSage.withValues(alpha: 0.6), width: 1);

  static BorderSide borderSelected(ColorScheme scheme) =>
      BorderSide(color: scheme.primary, width: 1.5);

  // ─── RADIUS ────────────────────────────────────────────────────

  static const double radiusCard = 16;
  static const double radiusIcon = 12;
  static const double radiusSmall = 8;

  // ─── SPACING ───────────────────────────────────────────────────

  static const double gapCards = 12;
  static const double gapSections = 24;
  static const double paddingCard = 16;

  // ─── MOTION ────────────────────────────────────────────────────

  static const Duration durationMicro = Duration(milliseconds: 100);
  static const Duration durationSnappy = Duration(milliseconds: 180);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationRelaxed = Duration(milliseconds: 450);

  static const Curve curveSnappy = Curves.easeOut;
  static const Curve curveNormal = Curves.easeInOut;
  static const Curve curveRelaxed = Curves.easeInOutCubic;

  // ─── SIZES ─────────────────────────────────────────────────────

  static const double iconAuraSmall = 56;
  static const double iconAuraMedium = 64;
  static const double iconAuraLarge = 80;

  static const double iconSizeSmall = 24;
  static const double iconSizeMedium = 32;
  static const double iconSizeLarge = 40;
}
