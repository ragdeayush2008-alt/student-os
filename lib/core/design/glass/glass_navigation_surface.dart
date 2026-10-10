import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import 'glass_surface.dart';

/// Elevated Liquid Glass Navigation Surface.
///
/// Designed for floating bottom navigation bars and floating app bars.
class GlassNavigationSurface extends StatelessWidget {
  const GlassNavigationSurface({
    super.key,
    required this.child,
    this.height,
    this.margin,
    this.padding,
    this.borderRadius,
    this.radius = LiquidRadius.xxl,
    this.useBlur = true,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double radius;
  final bool useBlur;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.elevated,
      height: height,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      radius: radius,
      useBlur: useBlur,
      child: child,
    );
  }
}
