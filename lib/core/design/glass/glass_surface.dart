import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../tokens/app_borders.dart';
import '../tokens/app_radius.dart';

/// Semantic material hierarchy levels for Student OS True Liquid Glass.
///
/// Every level differs in clarity (blur), translucency (tint), edge light,
/// border and depth. Higher levels are not merely "more opaque" — they stay
/// translucent so the ambient light field shows through, while gaining crisper
/// edges, fresher frost and softer elevation. The goal is premium *clear*
/// glass: background details stay recognizable, content stays crisp on top.
enum GlassLevel {
  /// The ambient atmosphere itself. No surface, no blur.
  base,

  /// Small utility surfaces — chips, pills, compact tiles. Clear and quiet:
  /// almost no frost, restrained edge, tiny elevation. Dense enough not to
  /// compete, translucent enough to reveal the environment.
  subtle,

  /// Standard content cards. Balanced clarity: moderate frost, low tint,
  /// crisp specular edge, soft depth.
  standard,

  /// Hero and floating surfaces — primary cards, bottom navigation, drawers.
  /// Slightly cooler, violet-tinted glass with deeper frost, a bright thin
  /// upper edge and strong soft floating elevation.
  elevated,

  /// Modals, sheets, dialogs and menus. The clearest floating glass: highest
  /// edge definition, marked inner light and the strongest, softest elevation
  /// so the surface visibly rests above everything else.
  modal,
}

/// The foundational True Liquid Glass Surface widget.
///
/// Material Pipeline:
/// ```
/// BACKGROUND (Luminous Ambient Light Field)
///     ↓
/// FROST / BLUR (moderate, bounded — background stays recognizable)
///     ↓
/// TRANSLUCENT TINT (cool glass color, graded by level)
///     ↓
/// INNER GLOW (wide, soft, luminous — behind content)
///     ↓
/// SPECULAR EDGE (thin bright upper band + sheen + side reflections)
///     ↓
/// GLASS RIM (micro-contrast border)
///     ↓
/// FLOATING ELEVATION (soft diffused shadows)
///     ↓
/// CRISP CONTENT (text, icons, controls always sharp on top)
/// ```
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.level = GlassLevel.standard,
    this.borderRadius,
    this.radius = LiquidRadius.lg,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = LiquidBorders.thin,
    this.edgeLightBoost = 1.0,
    this.blurSigma,
    this.useBlur = true,
    this.showSpecular = true,
    this.showHighlight = true,
    this.shadows,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  });

  final Widget child;
  final GlassLevel level;
  final BorderRadius? borderRadius;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  /// Scales the brightness of the specular edge light — used by the floating
  /// bottom navigation to give it an extra crisp top reflection.
  final double edgeLightBoost;
  final double? blurSigma;
  final bool useBlur;
  final bool showSpecular;
  final bool showHighlight;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  BorderRadius get _effectiveRadius =>
      borderRadius ?? BorderRadius.circular(radius);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // ══ 1. Frost — moderate, bounded. Higher hierarchy = fresher frost but
    //        never heavy: background color and shapes must stay visible. ══
    final double effectiveBlur = blurSigma ??
        switch (level) {
          GlassLevel.base => 0.0,
          GlassLevel.subtle => 6.0,
          GlassLevel.standard => 10.0,
          GlassLevel.elevated => 14.0,
          GlassLevel.modal => 14.0,
        };

    // ══ 2. Translucent tint — NEUTRAL glass, graded by hierarchy. Low alpha
    //        means the ambient environment dominates; the surface is clear
    //        neutral frost, never blue paint. Dark surfaces are charcoal,
    //        light surfaces a faint cool white. ══
    final Color defaultBg = switch (level) {
      GlassLevel.base =>
        isDark ? const Color(0xD9151C29) : const Color(0xDFFFFFFF),
      GlassLevel.subtle =>
        isDark ? const Color(0x301D2534) : const Color(0x1CFFFFFF),
      GlassLevel.standard =>
        isDark ? const Color(0x45212A3A) : const Color(0x28FFFFFF),
      GlassLevel.elevated =>
        isDark ? const Color(0x52263042) : const Color(0x32FFFFFF),
      GlassLevel.modal =>
        isDark ? const Color(0x66232D3E) : const Color(0x3CFFFFFF),
    };

    // ══ 3. Glass rim — a precise NEUTRAL micro-contrast edge. Dark surfaces get
    //        a brighter white rim, light surfaces a restrained charcoal rim. ══
    final Color defaultBorder = switch (level) {
      GlassLevel.base =>
        isDark ? const Color(0x12FFFFFF) : const Color(0x12000000),
      GlassLevel.subtle =>
        isDark ? const Color(0x1CFFFFFF) : const Color(0x15000000),
      GlassLevel.standard =>
        isDark ? const Color(0x26FFFFFF) : const Color(0x1E000000),
      GlassLevel.elevated =>
        isDark ? const Color(0x30FFFFFF) : const Color(0x26000000),
      GlassLevel.modal =>
        isDark ? const Color(0x38FFFFFF) : const Color(0x2E000000),
    };

    // ══ 4. Elevation — soft, diffused, floating. Shadows stay NEUTRAL
    //        charcoal/black. A whisper of accent glow is reserved ONLY for
    //        elevated & modal surfaces so the object hovers without glowing
    //        like a colored card. ══
    final List<BoxShadow>? effectiveShadows =
        shadows ??
        switch (level) {
          GlassLevel.base => null,
          GlassLevel.subtle => [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.05)
                    : const Color(0xFF16241F).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          GlassLevel.standard => [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.10)
                    : const Color(0xFF16241F).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.05)
                    : const Color(0xFF16241F).withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          GlassLevel.elevated => [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.16)
                    : const Color(0xFF16241F).withValues(alpha: 0.06),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.07)
                    : const Color(0xFF16241F).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: isDark
                    ? const Color(0xFF6F967F).withValues(alpha: 0.03)
                    : const Color(0xFF6F967F).withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          GlassLevel.modal => [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.22)
                    : const Color(0xFF16241F).withValues(alpha: 0.09),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.08)
                    : const Color(0xFF16241F).withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: isDark
                    ? const Color(0xFF6F967F).withValues(alpha: 0.04)
                    : const Color(0xFF4F7D68).withValues(alpha: 0.035),
                blurRadius: 22,
                offset: const Offset(0, -6),
              ),
            ],
        };

    final bg = backgroundColor ?? defaultBg;
    final borderCol = borderColor ?? defaultBorder;
    final shouldApplyBlur = useBlur && !reduceMotion && effectiveBlur > 0;
    final showGlassEdges = showSpecular && level != GlassLevel.base;
    final showInnerGlow = showHighlight && level != GlassLevel.base;

    // ══ 5. Build the surface. ══
    final bool paintLights = showInnerGlow || showGlassEdges;
    Widget surface = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: shouldApplyBlur
            ? bg
            : (level == GlassLevel.base ? bg.withValues(alpha: 1.0) : bg),
        borderRadius: _effectiveRadius,
        border: Border.all(color: borderCol, width: borderWidth),
        boxShadow: effectiveShadows,
      ),
      child: CustomPaint(
        // The glass lighting (inner glow + specular edge) is painted in front
        // of the pane at very low alpha — like light reflecting off clear
        // glass. Content on top stays crisp (alpha ≤ ~0.1 at the interior,
        // ~0.5 only on the thin 1.5px upper edge).
        foregroundPainter: paintLights
            ? _GlassLightingPainter(
                isDark: isDark,
                level: level,
                showInnerGlow: showInnerGlow,
                showGlassEdges: showGlassEdges,
                edgeLightBoost: edgeLightBoost,
              )
            : null,
        child: child,
      ),
    );

    if (shouldApplyBlur) {
      surface = RepaintBoundary(
        child: ClipRRect(
          borderRadius: _effectiveRadius,
          clipBehavior: clipBehavior,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: effectiveBlur,
              sigmaY: effectiveBlur,
            ),
            child: surface,
          ),
        ),
      );
    } else {
      surface = RepaintBoundary(
        child: ClipRRect(
          borderRadius: _effectiveRadius,
          clipBehavior: clipBehavior,
          child: surface,
        ),
      );
    }

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        borderRadius: _effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: _effectiveRadius,
          child: surface,
        ),
      );
    }

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return surface;
  }
}

/// The full lighting pass for a glass pane, painted in one bounded foreground
/// painter (never a second BackdropFilter): a wide luminous inner glow plus the
/// crisp specular edge — thin bright upper band, soft falling sheen, subtle
/// side reflections and a faint base contact rim. Light striking clear glass.
class _GlassLightingPainter extends CustomPainter {
  const _GlassLightingPainter({
    required this.isDark,
    required this.level,
    required this.showInnerGlow,
    required this.showGlassEdges,
    this.edgeLightBoost = 1.0,
  });

  final bool isDark;
  final GlassLevel level;
  final bool showInnerGlow;
  final bool showGlassEdges;
  final double edgeLightBoost;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // ── 1. Wide, soft, luminous inner glow — barely obvious alone, it is the
    //        layer that makes the pane feel lit from within rather than tinted.
    //        Centered near the top as if light arrives from above. ──
    if (showInnerGlow) {
      final double glow = switch (level) {
        GlassLevel.subtle => isDark ? 0.030 : 0.045,
        GlassLevel.standard => isDark ? 0.040 : 0.060,
        GlassLevel.elevated => isDark ? 0.050 : 0.075,
        GlassLevel.modal => isDark ? 0.055 : 0.085,
        GlassLevel.base => 0.0,
      };
      if (glow > 0) {
        final center = Offset(size.width * 0.5, size.height * 0.12);
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = ui.Gradient.radial(
              center,
              size.width * 0.95,
              [
                Colors.white.withValues(alpha: glow),
                Colors.white.withValues(alpha: glow * 0.35),
                Colors.white.withValues(alpha: 0.0),
              ],
              const [0.0, 0.55, 1.0],
            ),
        );
      }
    }

    if (!showGlassEdges) return;

    final double bandAlpha = switch (level) {
      GlassLevel.subtle => isDark ? 0.22 : 0.30,
      GlassLevel.standard => isDark ? 0.30 : 0.40,
      GlassLevel.elevated => isDark ? 0.36 : 0.46,
      GlassLevel.modal => isDark ? 0.42 : 0.52,
      GlassLevel.base => 0.0,
    };
    final double sheenAlpha = switch (level) {
      GlassLevel.subtle => 0.06,
      GlassLevel.standard => 0.08,
      GlassLevel.elevated => 0.10,
      GlassLevel.modal => 0.11,
      GlassLevel.base => 0.0,
    };
    final double sideAlpha = switch (level) {
      GlassLevel.subtle => isDark ? 0.05 : 0.08,
      GlassLevel.standard => isDark ? 0.07 : 0.11,
      GlassLevel.elevated => isDark ? 0.09 : 0.13,
      GlassLevel.modal => isDark ? 0.10 : 0.14,
      GlassLevel.base => 0.0,
    };

    // ── 2. Soft sheen falling away from the top half. ──
    if (sheenAlpha > 0) {
      final boostedSheen = (sheenAlpha * (0.6 + 0.4 * edgeLightBoost)).clamp(0.0, 0.2);
      final sheenRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.30);
      canvas.drawRect(
        sheenRect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, 0),
            Offset(0, sheenRect.height),
            [
              Colors.white.withValues(alpha: boostedSheen),
              Colors.white.withValues(alpha: boostedSheen * 0.4),
              Colors.white.withValues(alpha: 0.0),
            ],
            const [0.0, 0.55, 1.0],
          ),
      );
    }

    // ── 3. Bright thin upper band — the perceptual glass edge. ──
    if (bandAlpha > 0) {
      final boosted = (bandAlpha * edgeLightBoost).clamp(0.0, 0.85);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, 1.5),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(size.width, 0),
            [
              Colors.white.withValues(alpha: boosted * 0.35),
              Colors.white.withValues(alpha: boosted),
              Colors.white.withValues(alpha: boosted * 0.35),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }

    // ── 4. Subtle side reflections (light catching the curved sides). ──
    if (sideAlpha > 0) {
      final sideTop = size.height * 0.08;
      final sideHeight = size.height * 0.8;
      canvas.drawRect(
        Rect.fromLTWH(0, sideTop, 1.2, sideHeight),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, sideTop),
            Offset(0, sideTop + sideHeight),
            [
              Colors.white.withValues(alpha: sideAlpha * 1.2),
              Colors.white.withValues(alpha: sideAlpha),
              Colors.white.withValues(alpha: sideAlpha * 0.25),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width - 1.2, sideTop, 1.2, sideHeight),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, sideTop),
            Offset(0, sideTop + sideHeight),
            [
              Colors.white.withValues(alpha: sideAlpha),
              Colors.white.withValues(alpha: sideAlpha * 0.6),
              Colors.white.withValues(alpha: sideAlpha * 0.15),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }

    // ── 5. Faint base contact rim — tiniest micro-contrast. ──
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 1.0, size.width, 1.0),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height - 1.0),
          Offset(0, size.height),
          [
            Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassLightingPainter old) {
    return old.isDark != isDark ||
        old.level != level ||
        old.showInnerGlow != showInnerGlow ||
        old.showGlassEdges != showGlassEdges ||
        old.edgeLightBoost != edgeLightBoost;
  }
}

/// Convenience alias
typedef LiquidGlassSurface = GlassSurface;