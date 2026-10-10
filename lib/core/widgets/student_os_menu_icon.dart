import 'package:flutter/material.dart';

import 'student_os_icon_glow.dart';

/// Official Student OS hamburger icon: three left-aligned rounded bars.
///
/// LONG (30) / MEDIUM (21) / SHORT (13), 4-5px thick, fully rounded ends,
/// bolder than a standard hamburger. Morphs toward X via [progress]
/// (0 = menu, 1 = close).
class StudentOSMenuIcon extends StatelessWidget {
  const StudentOSMenuIcon({
    super.key,
    this.progress = 0,
    this.color,
    this.semanticLabel = 'Open navigation',
    this.excludeSemantics = false,
  });

  /// 0.0 = hamburger, 1.0 = X.
  final double progress;
  final Color? color;
  final String semanticLabel;

  /// When true, omits the inner [Semantics] node (for use inside a parent
  /// that already provides an accessibility label).
  final bool excludeSemantics;

  static const double _thickness = 4.5;
  static const double _topWidth = 30;
  static const double _midWidth = 21;
  static const double _bottomWidth = 13;
  static const double _gap = 5.5;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;
    final t = progress.clamp(0.0, 1.0);

    // Hamburger bars stay clean; only the active/morphed (X) state
    // carries a very subtle primary glow.
    final icon = StudentOSIconGlow.tone(
      tone: StudentOSGlowTone.primary,
      intensity: StudentOSGlowIntensity.minimal,
      radius: StudentOSGlowRadius.small,
      enabled: t > 0.5,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 34,
        height: 34,
        child: CustomPaint(
          painter: _MenuIconPainter(
            progress: t,
            color: effectiveColor,
          ),
        ),
      ),
    );

    if (excludeSemantics) return ExcludeSemantics(child: icon);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: icon,
    );
  }
}

class _MenuIconPainter extends CustomPainter {
  _MenuIconPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = StudentOSMenuIcon._thickness;

    // Left-aligned layout, vertically centered.
    const totalH = StudentOSMenuIcon._thickness * 3 +
        StudentOSMenuIcon._gap * 2;
    final startY = (size.height - totalH) / 2 +
        StudentOSMenuIcon._thickness / 2;
    const startX = 2.0;

    final topY = startY;
    final midY = startY +
        StudentOSMenuIcon._thickness +
        StudentOSMenuIcon._gap;
    final botY = midY +
        StudentOSMenuIcon._thickness +
        StudentOSMenuIcon._gap;

    if (progress <= 0.001) {
      _bar(canvas, paint, startX, topY, StudentOSMenuIcon._topWidth);
      _bar(canvas, paint, startX, midY, StudentOSMenuIcon._midWidth);
      _bar(canvas, paint, startX, botY, StudentOSMenuIcon._bottomWidth);
      return;
    }

    // Morph: top/bottom rotate toward diagonals around center, middle fades.
    final c = Offset(
      startX + StudentOSMenuIcon._topWidth / 2,
      startY +
          (totalH - StudentOSMenuIcon._thickness) / 2,
    );
    final angle = progress * 0.785398; // 45deg
    final len = StudentOSMenuIcon._topWidth * (1 - progress * 0.12);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    paint.color = color.withValues(alpha: 1);
    canvas.drawLine(
      Offset(-len / 2, 0),
      Offset(len / 2, 0),
      paint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-angle);
    canvas.drawLine(
      Offset(-len / 2, 0),
      Offset(len / 2, 0),
      paint,
    );
    canvas.restore();

    // Middle bar fades/scales out — draw only while faintly visible.
    if (progress < 0.7) {
      final p = Paint()
        ..color = color.withValues(alpha: (1 - progress / 0.7))
        ..strokeCap = StrokeCap.round
        ..strokeWidth = StudentOSMenuIcon._thickness;
      final w = StudentOSMenuIcon._midWidth * (1 - progress * 0.6);
      _bar(canvas, p, startX, midY, w);
    }

    // Suppress unused warnings for direct positions in morph state.
    topY;
    botY;
  }

  void _bar(Canvas canvas, Paint paint, double x, double y, double w) {
    canvas.drawLine(Offset(x, y), Offset(x + w, y), paint);
  }

  @override
  bool shouldRepaint(covariant _MenuIconPainter old) =>
      old.progress != progress || old.color != color;
}

/// Pressable hamburger button hosting [StudentOSMenuIcon].
class StudentOSMenuButton extends StatelessWidget {
  const StudentOSMenuButton({
    super.key,
    required this.onPressed,
    this.progress = 0,
    this.color,
    this.semanticLabel = 'Open navigation',
  });

  final VoidCallback? onPressed;
  final double progress;
  final Color? color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: StudentOSMenuIcon(
              progress: progress,
              color: color,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}
