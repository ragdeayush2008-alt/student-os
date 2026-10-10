import 'package:flutter/material.dart';

import 'dart:math' as math;

import '../animations/animated_entrance.dart';
import '../constants/app_durations.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// A smooth, gradient linear progress bar with an animated fill.
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
    this.color,
    this.trackColor,
  });

  final double value;
  final double height;
  final List<Color>? gradient;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final fillColor = color ?? palette.primary;
    const radius = BorderRadius.all(Radius.circular(AppRadius.pill));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0, double.infinity);
        return AnimatedContainer(
          duration: AppDurations.slow,
          curve: AppCurves.standard,
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: trackColor ?? palette.surfaceVariant,
            borderRadius: radius,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width * value.clamp(0, 1),
              height: height,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: gradient != null
                    ? LinearGradient(
                        colors: gradient!,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: gradient == null ? fillColor : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A circular progress component used for "time of day" and overall progress.
class AppCircularProgress extends StatelessWidget {
  const AppCircularProgress({
    super.key,
    required this.value,
    this.label,
    this.labelBuilder,
    this.subtitle,
    this.size = 96,
    this.color,
    this.strokeWidth = 9,
  });

  /// The target progress value (0.0–1.0).
  final double value;

  /// Static center label. Ignored when [labelBuilder] is provided.
  final String? label;

  /// Optional builder that receives the currently animated progress value,
  /// letting callers present a live-updating number (e.g. an animated percent).
  final Widget Function(BuildContext context, double progress)? labelBuilder;

  final String? subtitle;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final progressColor = color ?? palette.primary;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: AppDurations.slow,
        curve: AppCurves.standard,
        builder: (context, animationValue, _) {
          final labelWidget = labelBuilder != null
              ? labelBuilder!(context, animationValue)
              : Text(label ?? '', style: context.text.titleMedium);

          return CustomPaint(
            painter: _CircleProgressPainter(
              value: animationValue,
              color: progressColor,
              trackColor: palette.surfaceVariant,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  labelWidget,
                  if (subtitle != null)
                    Text(subtitle!, style: context.text.labelSmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  _CircleProgressPainter({
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

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

/// A compact stat card showing a value and label.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Icon(icon, size: 20, color: iconColor ?? palette.primary),
            ),
          Text(value, style: context.text.headlineSmall),
          const SizedBox(height: 2),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

/// A premium streak/badge chip used for consistency displays.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final fill = color ?? palette.primary;

    return AnimatedEntrance(
      child: Material(
        color: fill.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fill),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: context.text.labelMedium!.copyWith(color: fill),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
