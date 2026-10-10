import 'package:flutter/material.dart';

/// Central animation duration tokens — TCC-aligned (single source of truth).
///
/// Delegates to [AppDurations] / [StudentOSMotion]; kept for backward
/// compatibility with existing `Liquid*` imports.
abstract final class LiquidDurations {
  static const Duration fastest = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration base = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration slower = Duration(milliseconds: 450);

  static const Duration pageTransition = Duration(milliseconds: 380);
  static const Duration themeTransition = Duration(milliseconds: 380);
}

/// Central animation curves — TCC-aligned.
abstract final class LiquidCurves {
  /// Standard smooth deceleration for UI transitions.
  static const Curve standard = Curves.easeOutCubic;

  /// Entrance — TCC aligned, no overshoot (was easeOutBack).
  static const Curve entrance = Curves.easeOutCubic;

  /// Exit.
  static const Curve exit = Curves.easeInCubic;

  /// Expressive curve for celebration — restrained (was easeOutQuint).
  static const Curve emphasis = Curves.easeOutCubic;

  /// Restrained micro spring — only where useful.
  static const Curve spring = Curves.easeOutBack;

  /// Smooth bidirectional curve.
  static const Curve smooth = Curves.easeInOutCubic;
}

/// Entrance animation that smoothly fades and slides content in.
class LiquidEntrance extends StatelessWidget {
  const LiquidEntrance({
    super.key,
    required this.child,
    this.offset = const Offset(0, 0.05),
    this.duration = LiquidDurations.normal,
    this.curve = LiquidCurves.standard,
  });

  final Widget child;
  final Offset offset;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      child: child,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: offset * (1.0 - value) * 100,
            child: childWidget,
          ),
        );
      },
    );
  }
}

/// Press-feedback widget that scales down smoothly on tap — TCC 180ms 0.975.
class LiquidScalePress extends StatefulWidget {
  const LiquidScalePress({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.975,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final String? semanticLabel;

  @override
  State<LiquidScalePress> createState() => _LiquidScalePressState();
}

class _LiquidScalePressState extends State<LiquidScalePress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: !reduceMotion && _pressed ? widget.scale : 1.0,
          duration: LiquidDurations.fast,
          curve: LiquidCurves.standard,
          child: widget.child,
        ),
      ),
    );
  }
}
