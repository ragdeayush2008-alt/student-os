import 'package:flutter/material.dart';

/// Canonical design tokens for Student OS.
///
/// FOREST / EMERALD / SAGE ONLY — layered tonally from Deep Forest down to
/// Natural White. Former accent names are compatibility aliases resolving
/// into the green family. SOLID surfaces throughout — no glassmorphism,
/// no blur, no neon.
abstract final class StudentOSColors {
  // === Green family — primary visual language ===
  static const Color deepForest = Color(0xFF123D35);
  static const Color forest = Color(0xFF285C4D);
  static const Color mutedGreen = Color(0xFF4F7D68);
  static const Color sage = Color(0xFF6F967F);
  static const Color softSage = Color(0xFFA9C1AE);
  static const Color paleSage = Color(0xFFE7EFDC);
  static const Color mist = Color(0xFFF2F6EC);
  static const Color naturalWhite = Color(0xFFFAFCF7);

  // === Dark green family — deep emerald surfaces ===
  static const Color veryDeepEmerald = Color(0xFF08211C);
  static const Color deepForestDark = Color(0xFF0C2924);
  static const Color forestDark = Color(0xFF1E3A32);
  static const Color mutedGreenDark = Color(0xFF3E6A57);
  static const Color sageDark = Color(0xFF8FB49A);
  static const Color softSageDark = Color(0xFF5E7D68);

  // === Primary (drives the color scheme) — Forest ===
  static const Color primary = forest;
  static const Color primaryDark = deepForest;

  // === Primary action accent — forest emerald (NOT blue) ===
  static const Color studentBlue = forest;
  static const Color studentBlueDark = deepForest;
  static const Color blue = studentBlue;
  static const Color blueDark = studentBlueDark;

  // === Secondary — sage tonal step (NOT purple) ===
  static const Color secondary = mutedGreen;

  // === Semantic — green-family equivalents ===
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFF7A8450);
  static const Color danger = Color(0xFF2F453D);
  static const Color info = mutedGreen;

  // === Light surfaces ===
  static const Color background = mist;
  static const Color surface = naturalWhite;
  static const Color surfaceSecondary = Color(0xFFF4F7EF);

  static const Color textMain = Color(0xFF16241F);
  static const Color textSecondary = Color(0xFF5C6B63);
  static const Color textMuted = Color(0xFF8B9A91);

  static const Color border = Color(0xFFD8E2D4);
  static const Color divider = Color(0xFFE2EADF);

  // === Dark surfaces ===
  static const Color darkBackground = veryDeepEmerald;
  static const Color darkSurface = deepForestDark;
  static const Color darkSecondary = Color(0xFF1A322A);
  static const Color darkText = Color(0xFFEFF4EC);
  static const Color darkSecondaryText = Color(0xFFA9BFAF);
  static const Color darkPrimary = sageDark;

  // === Gradients ===
  /// Forest -> Sage signature identity gradient.
  static const List<Color> heroGradient = [deepForest, forest];

  /// Forest -> Muted Green -> Sage data-visualization family.
  static const List<Color> dataGradient = [forest, mutedGreen, sage, softSage];

  /// Forest action gradient (deep emerald tonal depth).
  static const List<Color> actionGradient = [studentBlue, studentBlueDark];
}

/// 8-point spacing tokens.
abstract final class StudentOSSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;

  static const double screenPadding = s16;
  static const double cardPadding = s16;
  static const double sectionGap = s32;
  static const double maxContentWidth = 720;
  static const double maxContentWidthTablet = 720;
}

/// Corner radius tokens: 8 / 12 / 16 / 20 / 24 / 999.
abstract final class StudentOSRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double standard = 16;
  static const double large = 20;
  static const double hero = 24;
  static const double pill = 999;
}

/// Motion tokens — one global language for Student OS (TCC-aligned).
///
/// TCC tokens: fast 180 · base 300 · page 380 · slow 450
/// default/enter easeOutCubic, exit easeInCubic, restrained spring only where useful.
abstract final class StudentOSMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 300);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration page = Duration(milliseconds: 380);
  static const Duration navigation = Duration(milliseconds: 380);
  static const Duration emphasis = Duration(milliseconds: 450);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration large = Duration(milliseconds: 450);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve standardCurve = Curves.easeOutCubic;
  // Restrained micro spring — use sparingly.
  static const Curve spring = Curves.easeOutBack;
}

/// Soft, restrained solid-surface shadows (no glow, no blur-heavy glass).
abstract final class StudentOSElevation {
  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.30)
              : const Color(0xFF101828).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.18)
              : const Color(0xFF101828).withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> elevated(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.40)
              : const Color(0xFF101828).withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
