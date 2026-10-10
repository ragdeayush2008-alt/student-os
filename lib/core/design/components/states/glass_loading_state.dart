import 'package:flutter/material.dart';

import '../../../widgets/shimmer_scope.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_card.dart';

/// Shimmer-style skeleton box — TCC-optimized shared ticker.
class GlassSkeleton extends StatelessWidget {
  const GlassSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = LiquidRadius.sm,
    this.isCircle = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final animation = ShimmerScope.of(context);
    final baseColor = isDark
        ? LiquidColors.surfaceVariantDark
        : LiquidColors.surfaceVariantLight;
    final highlightColor = isDark
        ? LiquidColors.surfaceElevatedDark
        : Colors.white;
    final shape = isCircle ? BoxShape.circle : BoxShape.rectangle;
    final borderRadius =
        isCircle ? null : BorderRadius.circular(radius);
    final staticBox = Container(
      width: isCircle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        shape: shape,
        borderRadius: borderRadius,
      ),
    );
    if (animation == null) return staticBox;
    return AnimatedBuilder(
      animation: animation,
      child: staticBox,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.0 + (animation.value * 2.5), -0.3),
            end: Alignment(1.0 + (animation.value * 2.5), 0.3),
            colors: [baseColor, highlightColor, baseColor],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// Skeleton Card placeholder — one shared ticker per card.
class GlassSkeletonCard extends StatelessWidget {
  const GlassSkeletonCard({
    super.key,
    this.lines = 2,
    this.hasLeading = true,
  });

  final int lines;
  final bool hasLeading;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: GlassCard(
        padding: LiquidSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (hasLeading) ...[
                  const GlassSkeleton(
                    width: 36,
                    height: 36,
                    isCircle: true,
                  ),
                  const SizedBox(width: LiquidSpacing.md),
                ],
                const Expanded(
                  child: GlassSkeleton(height: 16, width: 140),
                ),
              ],
            ),
            const SizedBox(height: LiquidSpacing.md),
            for (int i = 0; i < lines; i++) ...[
              if (i > 0) const SizedBox(height: LiquidSpacing.xs),
              GlassSkeleton(
                height: 12,
                width: i == lines - 1 ? 200 : double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// List of skeleton cards — one shared ticker for entire list.
class GlassSkeletonList extends StatelessWidget {
  const GlassSkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: Column(
        children: [
          for (int i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: LiquidSpacing.cardGap),
            // Direct card content without nesting another ShimmerScope.
            GlassCard(
              padding: LiquidSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      GlassSkeleton(width: 36, height: 36, isCircle: true),
                      SizedBox(width: LiquidSpacing.md),
                      Expanded(child: GlassSkeleton(height: 16, width: 140)),
                    ],
                  ),
                  const SizedBox(height: LiquidSpacing.md),
                  for (int i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(height: LiquidSpacing.xs),
                    GlassSkeleton(
                      height: 12,
                      width: i == 1 ? 200 : double.infinity,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
