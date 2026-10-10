import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_animated_number.dart';
import 'app_card.dart';

/// A premium stat metric card with a meaningful hierarchy: an icon, a smoothly
/// animating numeric value, a label and an optional note. Supports zero states
/// and optional navigation via [onTap]. Reduced-motion is handled by the number
/// component.
class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    this.value,
    this.valueBuilder,
    this.icon,
    this.iconColor,
    this.note,
    this.onTap,
    this.accent,
  }) : assert(
         value != null || valueBuilder != null,
         'Provide a value or a valueBuilder',
       );

  final String label;

  /// A plain numeric value animated via [AppAnimatedNumberText].
  final double? value;

  /// Custom value widget (use when the value isn't a plain number, e.g. time).
  final Widget Function(BuildContext)? valueBuilder;

  final IconData? icon;
  final Color? iconColor;
  final String? note;
  final VoidCallback? onTap;

  /// Optional subtle accent tint for the card surface.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final fill = iconColor ?? palette.primary;

    final number = valueBuilder != null
        ? valueBuilder!(context)
        : AppAnimatedNumberText(
            value: value ?? 0,
            format: (v) => v.round().toString(),
            style: context.text.headlineSmall,
          );

    return AppCard(
      onTap: onTap,
      color: accent?.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: fill.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon ?? Icons.circle, size: 18, color: fill),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: palette.onSurfaceMuted,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          number,
          const SizedBox(height: 2),
          Text(label, style: context.text.bodySmall),
          if (note != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                note!,
                style: context.text.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
