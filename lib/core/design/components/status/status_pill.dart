import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import 'status_chip.dart';

/// Lightweight dot + text status pill.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    this.label,
    this.showDot = true,
  });

  final AppStatusType status;
  final String? label;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveLabel = label ?? status.defaultLabel;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LiquidSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: LiquidRadius.pillAll,
        border: Border.all(
          color: status.color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            effectiveLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
