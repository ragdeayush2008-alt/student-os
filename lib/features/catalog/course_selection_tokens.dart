import 'package:flutter/material.dart';

/// Systematic alignment + sizing tokens for unified Course Selection 2.0.
///
/// Every layout element in Select Your Goal / Change Course must
/// consume these tokens instead of ad-hoc padding/sizing.
///
/// Academic Command Center — premium, restrained, consistent grid.
abstract final class CourseSelectionTokens {
  // ── Page grid ────────────────────────────────────────────────────
  static const double horizontalMargin = 16; // AppSpacing.md
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: horizontalMargin);
  static const EdgeInsets pagePaddingWithVertical = EdgeInsets.fromLTRB(horizontalMargin, 16, horizontalMargin, 16);
  static const double maxContentWidth = 720;

  // ── Vertical rhythm ──────────────────────────────────────────────
  static const double sectionGap = 24; // xl
  static const double cardGap = 8; // xs
  static const double sectionLabelGap = 8;
  static const double headerToContent = 16;
  static const double searchToSection = 20;

  // ── Header ───────────────────────────────────────────────────────
  static const double headerHeight = 44;
  static const double headerIconSize = 20;
  static const double headerBackButtonSize = 44;
  static const double headerHorizontalPadding = 16;
  static const double headerBottomBorderWidth = 1;

  // ── Search field ─────────────────────────────────────────────────
  static const double searchHeight = 52;
  static const double searchRadius = 14;
  static const double searchHorizontalPadding = 14;
  static const double searchIconSize = 20;
  static const EdgeInsets searchContentPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 14);

  // ── Category / Family / Program cards ────────────────────────────
  static const double cardRadius = 16;
  static const double cardHorizontalPadding = 16;
  static const double cardVerticalPadding = 14;
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: cardHorizontalPadding, vertical: cardVerticalPadding);
  static const double iconContainerSize = 44;
  static const double iconContainerRadius = 12;
  static const double iconSize = 22;
  static const double smallIconContainerSize = 40;
  static const double smallIconSize = 20;
  static const double chevronSize = 20;
  static const double titleSubtitleGap = 2;
  static const double cardMinHeight = 72;

  // ── Popular chips ────────────────────────────────────────────────
  static const double chipSpacing = 8;
  static const double chipRunSpacing = 8;
  static const double chipHeight = 36;

  // ── Level / stage chips ──────────────────────────────────────────
  static const double levelChipSpacing = 8;

  // ── Buttons ──────────────────────────────────────────────────────
  static const double primaryButtonHeight = 52;
  static const double primaryButtonRadius = 12;
  static const EdgeInsets primaryButtonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

  // ── Selection states ─────────────────────────────────────────────
  static const double selectedBorderWidth = 1.5;
  static const double unselectedBorderWidth = 1;

  // ── Shadows ──────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return [];
    return [
      BoxShadow(
        color: const Color(0xFF101828).withValues(alpha: 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: const Color(0xFF101828).withValues(alpha: 0.03),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];
  }

  // ── Typography scales (relative to Theme) ────────────────────────
  static TextStyle sectionLabel(BuildContext context) {
    final base = Theme.of(context).textTheme.titleSmall;
    return base!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.1);
  }

  static TextStyle cardTitle(BuildContext context) {
    final base = Theme.of(context).textTheme.titleSmall;
    return base!.copyWith(fontWeight: FontWeight.w700, height: 1.25);
  }

  static TextStyle cardSubtitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFFA7B0C0) : const Color(0xFF667085);
    return Theme.of(context).textTheme.bodySmall!.copyWith(color: muted, fontSize: 12.5, height: 1.35);
  }
}
