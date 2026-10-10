import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'ambient_variant.dart';

export 'ambient_variant.dart';

/// Reusable Ambient Background Layer for Student OS Liquid Glass.
///
/// Provides a controlled, LUMINOUS atmospheric light field behind glass
/// surfaces so transparency, blur and specular highlights are physically
/// grounded and depth-separated. The field deliberately contains both bright
/// and dark zones — glass needs light to interact with:
///
/// ```
/// ATMOSPHERIC GRADIENT
///     ↓
/// MAIN CONTENT HALO (bright zone behind content)
///     ↓
/// BROAD LIGHT WASHES (sage / mist / emerald)
///     ↓
/// DEPTH ORBS (calm color regions)
///     ↓
/// DARKER EDGE VIGNETTE (faces the glass away from content)
///     ↓
/// TRANSLUCENT GLASS CONTENT
/// ```
///
/// The environment is calm and premium: soft luminous color with smooth
/// transitions — never neon, never rainbow, never sharp blobs. Light appears
/// to glow *through* the glass above it.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.variant = AmbientVariant.defaultVariant,
    this.intensity = 1.0,
    this.showOrbs = true,
    this.darkStage = false,
  });

  final Widget child;
  final AmbientVariant variant;
  final double intensity;
  final bool showOrbs;

  /// Forces the dark atmospheric environment regardless of theme brightness.
  ///
  /// Used by the authentication and onboarding "stage" so those flows present
  /// one continuous premium glass environment in both light and dark modes.
  final bool darkStage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = darkStage || theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base atmospheric light field
          CustomPaint(
            painter: _AmbientEnvironmentPainter(
              isDark: isDark,
              variant: variant,
              intensity: intensity,
              showOrbs: showOrbs,
            ),
            size: Size.infinite,
          ),

          // Content Layer
          child,
        ],
      ),
    );
  }
}

class _AmbientEnvironmentPainter extends CustomPainter {
  const _AmbientEnvironmentPainter({
    required this.isDark,
    required this.variant,
    required this.intensity,
    required this.showOrbs,
  });

  final bool isDark;
  final AmbientVariant variant;
  final double intensity;
  final bool showOrbs;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // ══ 1 ── Atmosphere: a primarily NEUTRAL foundation (cool neutral dark /
//        cool neutral light). Never a colored page — the environment supports
//        the glass instead of dominating it. ══
    final basePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, h),
        isDark
            ? const [Color(0xFF0B1512), Color(0xFF08211C), Color(0xFF051713)]
            : const [Color(0xFFFAFCF7), Color(0xFFF2F6EC), Color(0xFFE7EFDC)],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(Offset.zero & size, basePaint);

    if (!showOrbs) return;

    // ══ 2 ── Main content halo — ONE quiet luminous zone placed where the
    //        hero/content sits. Localized, not a full-page wash. ══
    final halo = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.5, h * 0.42),
        w * 0.95,
        isDark
            ? [
                const Color(0xFF6F967F).withValues(alpha: 0.05 * intensity),
                const Color(0xFF6F967F).withValues(alpha: 0.02 * intensity),
                const Color(0xFF6F967F).withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFF6F967F).withValues(alpha: 0.06 * intensity),
                const Color(0xFF6F967F).withValues(alpha: 0.02 * intensity),
                const Color(0xFF6F967F).withValues(alpha: 0.0),
              ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Offset.zero & size, halo);

    // ══ 3 ── Localized primary sage light, upper-left quadrant only. ══
    final wash = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.18, h * 0.10),
        w * 1.05,
        isDark
            ? [
                const Color(0xFFA9C1AE).withValues(alpha: 0.05 * intensity),
                const Color(0xFFA9C1AE).withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFFA9C1AE).withValues(alpha: 0.08 * intensity),
                const Color(0xFFA9C1AE).withValues(alpha: 0.0),
              ],
        const [0.0, 1.0],
      );
    canvas.drawRect(Offset.zero & size, wash);

    // ══ 4 ── Subtle pine reflection, lower-right quadrant only. ══
    final wash2 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.92, h * 0.86),
        w * 1.0,
        isDark
            ? [
                const Color(0xFF4F7D68).withValues(alpha: 0.04 * intensity),
                const Color(0xFF4F7D68).withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFF4F7D68).withValues(alpha: 0.06 * intensity),
                const Color(0xFF4F7D68).withValues(alpha: 0.0),
              ],
        const [0.0, 1.0],
      );
    canvas.drawRect(Offset.zero & size, wash2);

    // ══ 5 ── Tiny optional sage influence at the very bottom. ══
    final wash3 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.5, h * 1.02),
        w * 0.8,
        isDark
            ? [
                const Color(0xFF6F967F).withValues(alpha: 0.025 * intensity),
                const Color(0xFF6F967F).withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFFA9C1AE).withValues(alpha: 0.035 * intensity),
                const Color(0xFFA9C1AE).withValues(alpha: 0.0),
              ],
        const [0.0, 1.0],
      );
    canvas.drawRect(Offset.zero & size, wash3);

    // 6 ── Two-three color orbs — LARGE, very soft, low opacity, spatially
    //        separated, so color is perceived as local reflected light rather
    //        than a tinted theme. Most of the screen stays neutral.
    final orbs = _resolveOrbs(w, h, isDark, variant, intensity);
    for (final orb in orbs) {
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          orb.center,
          orb.radius,
          [
            orb.color.withValues(alpha: orb.alpha),
            orb.color.withValues(alpha: orb.alpha * 0.30),
            orb.color.withValues(alpha: 0.0),
          ],
          const [0.0, 0.5, 1.0],
        );
      canvas.drawCircle(orb.center, orb.radius, paint);
    }

    // 7 ── Calm edge vignette only: pure charcoal depth at the very corners.
    //        Center stays neutral — this is what separates glass from the
    //        environment without adding color.
    final vignette = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.5, h * 0.45),
        (w > h ? w : h) * 0.72,
        isDark
            ? [
                const Color(0xFF000000).withValues(alpha: 0.0),
                const Color(0xFF000000).withValues(alpha: 0.0),
                const Color(0xFF000000).withValues(alpha: 0.30 * intensity),
              ]
            : [
                const Color(0xFF123D35).withValues(alpha: 0.0),
                const Color(0xFF123D35).withValues(alpha: 0.0),
                const Color(0xFF123D35).withValues(alpha: 0.09 * intensity),
              ],
        const [0.0, 0.68, 1.0],
      );
    canvas.drawRect(Offset.zero & size, vignette);
  }

  List<_LightOrb> _resolveOrbs(
    double w,
    double h,
    bool isDark,
    AmbientVariant variant,
    double intensity,
  ) {
    final a1 = (isDark ? 0.10 : 0.08) * intensity;
    final a2 = (isDark ? 0.07 : 0.06) * intensity;
    final a3 = (isDark ? 0.045 : 0.035) * intensity;

    const sageLight = Color(0xFF6F967F);
    const pine = Color(0xFF4F7D68);
    const sageSoft = Color(0xFF6F967F);
    const pineDeep = Color(0xFF4F7D68);

    switch (variant) {
      case AmbientVariant.authentication:
        return [
          // Upper-right local sage light
          _LightOrb(
            center: Offset(w * 0.86, h * 0.10),
            radius: w * 0.74,
            color: sageLight,
            alpha: a1 * 1.1,
          ),
          // Center-left subtle pine atmosphere
          _LightOrb(
            center: Offset(w * 0.12, h * 0.50),
            radius: w * 0.78,
            color: pine,
            alpha: a2 * 1.1,
          ),
          // Bottom-soft sage region
          _LightOrb(
            center: Offset(w * 0.74, h * 0.92),
            radius: w * 0.64,
            color: sageSoft,
            alpha: a3,
          ),
        ];

      case AmbientVariant.focus:
        return [
          _LightOrb(
            center: Offset(w * 0.5, h * 0.14),
            radius: w * 0.82,
            color: const Color(0xFF285C4D),
            alpha: a1,
          ),
          _LightOrb(
            center: Offset(w * 0.84, h * 0.78),
            radius: w * 0.56,
            color: const Color(0xFF2E7D5B),
            alpha: a3 * 0.8,
          ),
        ];

      case AmbientVariant.learning:
        return [
          _LightOrb(
            center: Offset(w * 0.18, h * 0.12),
            radius: w * 0.74,
            color: sageSoft,
            alpha: a1,
          ),
          _LightOrb(
            center: Offset(w * 0.86, h * 0.64),
            radius: w * 0.78,
            color: pine,
            alpha: a2,
          ),
        ];

      case AmbientVariant.productivity:
        return [
          _LightOrb(
            center: Offset(w * 0.84, h * 0.16),
            radius: w * 0.74,
            color: sageLight,
            alpha: a1,
          ),
          _LightOrb(
            center: Offset(w * 0.14, h * 0.74),
            radius: w * 0.72,
            color: pine,
            alpha: a2,
          ),
        ];

      case AmbientVariant.calm:
        return [
          _LightOrb(
            center: Offset(w * 0.5, h * 0.20),
            radius: w * 0.88,
            color: pineDeep,
            alpha: a2,
          ),
          _LightOrb(
            center: Offset(w * 0.5, h * 0.86),
            radius: w * 0.66,
            color: sageSoft,
            alpha: a3,
          ),
        ];

      case AmbientVariant.workspace:
        return [
          _LightOrb(
            center: Offset(w * 0.12, h * 0.18),
            radius: w * 0.78,
            color: sageLight,
            alpha: a2,
          ),
          _LightOrb(
            center: Offset(w * 0.90, h * 0.80),
            radius: w * 0.72,
            color: const Color(0xFF4F7D68),
            alpha: a2,
          ),
        ];

      case AmbientVariant.defaultVariant:
        return [
          // Upper-right controlled ambient light
          _LightOrb(
            center: Offset(w * 0.84, h * 0.10),
            radius: w * 0.72,
            color: sageLight,
            alpha: a1,
          ),
          // Lower-left violet depth region
          _LightOrb(
            center: Offset(w * 0.12, h * 0.68),
            radius: w * 0.78,
            color: pine,
            alpha: a2,
          ),
          // Subtle cyan accent lower-right
          _LightOrb(
            center: Offset(w * 0.66, h * 0.90),
            radius: w * 0.56,
            color: sageSoft,
            alpha: a3,
          ),
        ];
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientEnvironmentPainter old) {
    return old.isDark != isDark ||
        old.variant != variant ||
        old.intensity != intensity ||
        old.showOrbs != showOrbs;
  }
}

class _LightOrb {
  const _LightOrb({
    required this.center,
    required this.radius,
    required this.color,
    required this.alpha,
  });

  final Offset center;
  final double radius;
  final Color color;
  final double alpha;
}