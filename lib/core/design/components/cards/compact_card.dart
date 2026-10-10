import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_surface.dart';

/// Compact Card for dense grid views and secondary modules.
class CompactCard extends StatelessWidget {
  const CompactCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = LiquidSpacing.compactCardPadding,
    this.level = GlassLevel.standard,
    this.radius = LiquidRadius.md,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final GlassLevel level;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: level,
      radius: radius,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}
