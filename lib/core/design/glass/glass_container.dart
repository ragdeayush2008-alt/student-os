import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import 'glass_surface.dart';

/// Flexible Glass Container widget for wrapping any UI content with glass styling.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.alignment,
    this.constraints,
    this.level = GlassLevel.standard,
    this.borderRadius,
    this.radius = LiquidRadius.md,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.useBlur = true,
    this.showHighlight = true,
    this.shadows,
    this.onTap,
  });

  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final GlassLevel level;
  final BorderRadius? borderRadius;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool useBlur;
  final bool showHighlight;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = child ?? const SizedBox();
    if (alignment != null) {
      content = Align(alignment: alignment!, child: content);
    }
    if (constraints != null) {
      content = ConstrainedBox(constraints: constraints!, child: content);
    }

    return GlassSurface(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      level: level,
      borderRadius: borderRadius,
      radius: radius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      useBlur: useBlur,
      showHighlight: showHighlight,
      shadows: shadows,
      onTap: onTap,
      child: content,
    );
  }
}
