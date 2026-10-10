import 'package:flutter/material.dart';

import '../constants/app_durations.dart';

/// A reusable entrance animation that fades + slides content in when it first
/// appears in the tree.
///
/// Use this for section/card appearance to keep motion consistent. It respects
/// [MediaQuery.disableAnimations] via [animate] param.
class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.offset = const Offset(0, 0.06),
    this.duration,
    this.delay = Duration.zero,
    this.curve = AppCurves.standard,
  });

  final Widget child;
  final Offset offset;
  final Duration? duration;
  final Duration delay;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration ?? AppDurations.normal,
      curve: curve,
      child: child,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: offset * (1 - value),
            child: childWidget,
          ),
        );
      },
    );
  }
}
