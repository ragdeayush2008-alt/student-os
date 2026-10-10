import 'package:flutter/material.dart';

/// Shared shimmer ticker — one controller per scope, N skeletons share it.
///
/// Wraps a subtree where skeleton placeholders appear. A single
/// [AnimationController] drives all descendant skeletons, avoiding per-box
/// ticker storms. Respects reduced-motion by disabling animation.
/// Ticker is automatically paused when scope is off-screen via [TickerMode].
class ShimmerScope extends StatefulWidget {
  const ShimmerScope({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final Duration duration;

  /// Retrieves the shared shimmer animation from the nearest [ShimmerScope].
  static Animation<double>? of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_ShimmerInherited>();
    return scope?.animation;
  }

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      if (_controller.isAnimating) _controller.stop();
    } else {
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ShimmerScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      return _ShimmerInherited(
        animation: null,
        child: widget.child,
      );
    }
    // New API after v3.35: valuesOf replaces of.
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    return TickerMode(
      enabled: tickerEnabled,
      child: _ShimmerInherited(
        animation: _controller,
        child: widget.child,
      ),
    );
  }
}

class _ShimmerInherited extends InheritedWidget {
  const _ShimmerInherited({required this.animation, required super.child});

  final Animation<double>? animation;

  @override
  bool updateShouldNotify(covariant _ShimmerInherited old) =>
      old.animation != animation;
}

/// Lightweight static skeleton box — uses shared shimmer when available,
/// falls back to static color when outside a [ShimmerScope] or in reduced-motion.
class SharedShimmerBox extends StatelessWidget {
  const SharedShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
    this.circle = false,
    this.baseColor,
    this.highlightColor,
  });

  final double width;
  final double height;
  final double radius;
  final bool circle;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final defaultBase = baseColor ?? scheme.surfaceContainerHighest;
    final defaultHighlight = highlightColor ?? scheme.surfaceContainerLowest;
    final animation = ShimmerScope.of(context);

    final shape = circle ? BoxShape.circle : BoxShape.rectangle;
    final borderRadius =
        circle ? null : BorderRadius.circular(radius);

    final staticBox = Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: defaultBase,
        shape: shape,
        borderRadius: borderRadius,
      ),
    );

    if (animation == null) return staticBox;

    // Shared animated shimmer — single ticker drives all boxes in scope.
    return AnimatedBuilder(
      animation: animation,
      child: staticBox,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [defaultBase, defaultHighlight, defaultBase],
            stops: const [0.3, 0.5, 0.7],
            begin: Alignment(-1 + animation.value * 2, 0),
            end: Alignment(1 + animation.value * 2, 0),
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}
