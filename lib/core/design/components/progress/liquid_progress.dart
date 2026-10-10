import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_card.dart';

/// Smooth, animated linear progress bar with pill ends.
class LiquidLinearProgress extends StatelessWidget {
  const LiquidLinearProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
    this.color,
    this.trackColor,
    this.radius = LiquidRadius.pill,
  });

  final double value;
  final double height;
  final List<Color>? gradient;
  final Color? color;
  final Color? trackColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultFill = color ?? LiquidColors.primary;
    final defaultTrack = trackColor ??
        (isDark ? LiquidColors.surfaceVariantDark : LiquidColors.surfaceVariantLight);

    final borderRadius = BorderRadius.circular(radius);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final clampedValue = value.clamp(0.0, 1.0);

        return Container(
          height: height,
          width: totalWidth,
          decoration: BoxDecoration(
            color: defaultTrack,
            borderRadius: borderRadius,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: totalWidth * clampedValue,
              height: height,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: gradient != null
                    ? LinearGradient(
                        colors: gradient!,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: gradient == null ? defaultFill : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Circular Liquid Glass progress indicator with customizable center widget.
class LiquidCircularProgress extends StatelessWidget {
  const LiquidCircularProgress({
    super.key,
    required this.value,
    this.label,
    this.subtitle,
    this.labelBuilder,
    this.size = 96,
    this.strokeWidth = 8,
    this.color,
    this.trackColor,
  });

  final double value;
  final String? label;
  final String? subtitle;
  final Widget Function(BuildContext context, double progress)? labelBuilder;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = color ?? LiquidColors.primary;
    final track = trackColor ??
        (isDark ? LiquidColors.surfaceVariantDark : LiquidColors.surfaceVariantLight);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, animatedVal, _) {
          final labelWidget = labelBuilder != null
              ? labelBuilder!(context, animatedVal)
              : Text(
                  label ?? '${(animatedVal * 100).toInt()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                );

          return CustomPaint(
            painter: _LiquidCirclePainter(
              value: animatedVal,
              color: primary,
              trackColor: track,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  labelWidget,
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? LiquidColors.textSecondaryDark
                            : LiquidColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LiquidCirclePainter extends CustomPainter {
  const _LiquidCirclePainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (value > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * value,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidCirclePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Compact stat card that pairs a progress bar with a stat number.
class StatProgressCard extends StatelessWidget {
  const StatProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  final String title;
  final String value;
  final double progress;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = iconColor ?? LiquidColors.primary;

    return GlassCard(
      onTap: onTap,
      padding: LiquidSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: primary),
                const SizedBox(width: LiquidSpacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? LiquidColors.textSecondaryDark
                        : LiquidColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: LiquidSpacing.sm),
          LiquidLinearProgress(
            value: progress,
            color: primary,
            height: 6,
          ),
        ],
      ),
    );
  }
}

/// Formatted duration progress indicator (e.g. "25 / 45 min").
class DurationProgress extends StatelessWidget {
  const DurationProgress({
    super.key,
    required this.elapsedMinutes,
    required this.totalMinutes,
    this.color,
  });

  final int elapsedMinutes;
  final int totalMinutes;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? LiquidColors.primary;
    final progress = totalMinutes > 0 ? (elapsedMinutes / totalMinutes).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$elapsedMinutes min',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: effectiveColor,
              ),
            ),
            Text(
              'of $totalMinutes min',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? LiquidColors.textTertiaryDark
                    : LiquidColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: LiquidSpacing.xs),
        LiquidLinearProgress(
          value: progress,
          color: effectiveColor,
          height: 6,
        ),
      ],
    );
  }
}
