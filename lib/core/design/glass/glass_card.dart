import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'glass_surface.dart';

/// Reusable Glass Card for Student OS.
///
/// Provides a sleek, translucent container with rounded corners and specular highlight.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.level = GlassLevel.standard,
    this.padding = LiquidSpacing.cardPadding,
    this.margin,
    this.borderRadius,
    this.radius = LiquidRadius.lg,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showHighlight = true,
    this.useBlur = true,
    this.shadows,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final GlassLevel level;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool showHighlight;
  final bool useBlur;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: level,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      radius: radius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      showHighlight: showHighlight,
      useBlur: useBlur,
      shadows: shadows,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }
}
