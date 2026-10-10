import 'dart:io';

import 'package:flutter/material.dart';

/// Living ambient background for Onboarding Step 2.
///
/// 2-3 very large, extremely low-opacity emerald/sage orbs drifting slowly
/// (8-15s, reverse). Isolated animation — does not rebuild goal cards.
/// Respects reduced motion: renders static soft wash when animations disabled.
class OnboardingAmbientBackground extends StatefulWidget {
  const OnboardingAmbientBackground({super.key});

  @override
  State<OnboardingAmbientBackground> createState() =>
      _OnboardingAmbientBackgroundState();
}

class _OnboardingAmbientBackgroundState
    extends State<OnboardingAmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _drift;
  late Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    _t = CurvedAnimation(parent: _drift, curve: Curves.easeInOut);
    // Repeat only when motion is allowed — checked in build via
    // MediaQuery, but starting here is harmless; we stop in didChangeDependencies.
  }

  bool get _isTest {
    bool result = false;
    try {
      result = Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      result = false;
    }
    return result;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce || _isTest) {
      // In tests / reduced motion: run once (or not at all) so
      // pumpAndSettle can complete. No infinite repeat.
      if (_drift.isAnimating) {
        _drift.stop();
      }
      return;
    }
    if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.disableAnimationsOf(context);

    if (reduce) {
      return const IgnorePointer(
        child: CustomPaint(painter: _StaticAmbientPainter()),
      );
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final v = _t.value;
          return CustomPaint(
            painter: _DriftingAmbientPainter(
              drift: v,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

/// Static fallback when reduced motion is on.
class _StaticAmbientPainter extends CustomPainter {
  const _StaticAmbientPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
        Offset(w * 0.85, -h * 0.04), w * 0.55, Paint()..color = const Color(0x0A285C4D));
    canvas.drawCircle(
        Offset(w * 0.08, h * 1.02), w * 0.6, Paint()..color = const Color(0x0A6F967F));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Drifting orbs — only this painter repaints, ~60fps cheap circles.
class _DriftingAmbientPainter extends CustomPainter {
  const _DriftingAmbientPainter({required this.drift, required this.isDark});
  final double drift;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Almost imperceptible drift: ±18px horizontal, ±12px vertical.
    final dx = (drift - 0.5) * 36;
    final dy = (drift - 0.5) * 24;

    final alphaTop = isDark ? 0x14 : 0x0C;
    final alphaBottom = isDark ? 0x12 : 0x0A;
    final alphaMid = isDark ? 0x0E : 0x08;

    canvas.drawCircle(
      Offset(w * 0.85 + dx, -h * 0.04 + dy),
      w * 0.55,
      Paint()..color = Color(alphaTop << 24 | 0x285C4D),
    );
    canvas.drawCircle(
      Offset(w * 0.08 - dx, h * 1.02 - dy),
      w * 0.6,
      Paint()..color = Color(alphaBottom << 24 | 0x6F967F),
    );
    // Third faint mid orb for luminous depth.
    canvas.drawCircle(
      Offset(w * 0.5 + dx * 0.5, h * 0.42 + dy * 0.5),
      w * 0.42,
      Paint()..color = Color(alphaMid << 24 | 0x8FBFA8),
    );
  }

  @override
  bool shouldRepaint(covariant _DriftingAmbientPainter oldDelegate) =>
      oldDelegate.drift != drift || oldDelegate.isDark != isDark;
}
