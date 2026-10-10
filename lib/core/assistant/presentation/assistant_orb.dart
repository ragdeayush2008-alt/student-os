import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Luminous emerald Assistant orb — the visual signature of Student OS.
///
/// Abstract layered light (deep forest core → emerald body → sage halo),
/// forest/emerald/sage only. Gentle 6s breathing scale + halo drift.
/// Fully static when reduced motion is on. Isolated repaint boundary so the
/// rest of the screen never rebuilds per frame.
class AssistantOrb extends StatefulWidget {
  const AssistantOrb({super.key, this.size = 120, this.breathing = true});

  final double size;
  final bool breathing;

  @override
  State<AssistantOrb> createState() => _AssistantOrbState();
}

class _AssistantOrbState extends State<AssistantOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _breath;
  late Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _t = CurvedAnimation(parent: _breath, curve: Curves.easeInOut);
  }

  bool get _isTest {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    // Never repeat forever in widget tests — pumpAndSettle must settle.
    if (reduce || !widget.breathing || _isTest) {
      if (_breath.isAnimating) {
        _breath.stop();
      }
      return;
    }
    if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AssistantOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    didChangeDependencies();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          // Subtle: ±3% scale, halo drifts almost imperceptibly.
          final s = 1.0 + (_t.value - 0.5) * 0.06;
          final halo = 1.0 + (_t.value - 0.5) * 0.10;
          return SizedBox(
            width: widget.size * 1.5,
            height: widget.size * 1.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer halo.
                Transform.scale(
                  scale: halo,
                  child: Container(
                    width: widget.size * 1.42,
                    height: widget.size * 1.42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.sage.withValues(
                              alpha: isDark ? 0.22 : 0.16),
                          AppColors.sage.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Mid glow.
                Transform.scale(
                  scale: s,
                  child: Container(
                    width: widget.size * 1.12,
                    height: widget.size * 1.12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.mutedGreen.withValues(
                              alpha: isDark ? 0.35 : 0.28),
                          AppColors.mutedGreen.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Orb body: forest → emerald.
                Transform.scale(
                  scale: s,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.25, -0.3),
                        colors: [
                          Color(0xFF3D7F6F),
                          AppColors.forest,
                          AppColors.deepForest,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forest.withValues(
                              alpha: isDark ? 0.45 : 0.30),
                          blurRadius: 28,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: widget.size * 0.44,
                        height: widget.size * 0.44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(
                                  alpha: isDark ? 0.85 : 0.9),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white.withValues(alpha: 0.95),
                            size: widget.size * 0.30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
