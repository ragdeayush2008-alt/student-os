import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared atmospheric background for the main app (learning layer of the
/// visual system, not a feature).
///
/// Extremely subtle sage/emerald radial washes over the theme background —
/// the same spirit as the setup screen, barely noticeable by design.
/// Static paint (no animation, no blur, one repaint per theme change), so
/// it costs essentially nothing on Android/iOS/web.
class StudentOSAtmosphere extends StatelessWidget {
  const StudentOSAtmosphere({
    super.key,
    required this.child,
    this.variant = StudentOSAtmosphereVariant.calm,
  });

  final Widget child;
  final StudentOSAtmosphereVariant variant;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return CustomPaint(
      painter: _AtmospherePainter(
        isDark: palette.isDark,
        variant: variant,
      ),
      child: child,
    );
  }
}

enum StudentOSAtmosphereVariant { calm, focus, night }

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter({required this.isDark, required this.variant});

  final bool isDark;
  final StudentOSAtmosphereVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Base: theme background (never a colored page).
    final bg = Paint()
      ..color = isDark ? const Color(0xFF08211C) : const Color(0xFFF2F6EC);
    canvas.drawRect(Offset.zero & size, bg);

    // Two large, very low-opacity washes. Emerald up top, sage low.
    final topAlpha = isDark ? 0.10 : 0.07;
    final bottomAlpha = isDark ? 0.08 : 0.06;
    final topColor = variant == StudentOSAtmosphereVariant.night
        ? const Color(0xFF1E3A32)
        : const Color(0xFF2D5C4B);
    const bottomColor = Color(0xFF6F967F);

    canvas.drawCircle(
      Offset(w * 0.88, -h * 0.06),
      w * 0.62,
      Paint()..color = topColor.withValues(alpha: topAlpha),
    );
    canvas.drawCircle(
      Offset(w * 0.06, h * 1.04),
      w * 0.66,
      Paint()..color = bottomColor.withValues(alpha: bottomAlpha),
    );
    if (variant == StudentOSAtmosphereVariant.focus) {
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.30),
        w * 0.44,
        Paint()..color = topColor.withValues(alpha: topAlpha * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.variant != variant;
}
