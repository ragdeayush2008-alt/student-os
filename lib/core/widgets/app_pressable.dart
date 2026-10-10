import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_durations.dart';

/// A premium press-feedback wrapper used across Student OS.
///
/// Gives high-end productivity-style tactile feedback: the [child] scales down
/// subtly while pressed and smoothly returns on release. Gesture handling is
/// tap-only, so it never competes with parent scrolling (e.g. inside a
/// [SingleChildScrollView]).
///
/// When a [builder] is supplied it replaces the default scale-down, allowing
/// callers to drive richer per-widget press animations from the same
/// interpolated press [double] (0.0 rested → 1.0 fully pressed). Reduced-motion
/// preferences are respected by disabling the press animation entirely.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    this.child,
    this.builder,
    required this.onTap,
    this.pressedScale = 0.975,
    this.semanticLabel,
  }) : assert(
         child != null || builder != null,
         'AppPressable requires a child or a builder',
       );

  /// Rendered while not pressed when [builder] is not used.
  final Widget? child;

  /// Custom press-driven content: receives the interpolated press value.
  final Widget Function(BuildContext context, double progress)? builder;

  /// Called when the surface is tapped.
  final VoidCallback onTap;

  /// Resting→pressed scale for the default [child] path (usually 0.97–0.99).
  final double pressedScale;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
      reverseDuration: AppDurations.fast,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    HapticFeedback.lightImpact();
    if (!MediaQuery.disableAnimationsOf(context)) _controller.forward();
  }

  void _onTapUp(_) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final progress = reduceMotion ? 0.0 : _controller.value;
    final eased = Curves.easeOutCubic.transform(progress);

    Widget surface;
    if (widget.builder != null) {
      surface = AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder!(context, eased),
      );
    } else {
      surface = AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, childWidget) {
          final scale = 1 - (1 - widget.pressedScale) * eased;
          return Transform.scale(scale: scale, child: childWidget);
        },
      );
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: surface,
      ),
    );
  }
}
