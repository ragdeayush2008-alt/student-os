import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_surface.dart';

/// Semantic status categories for Student OS.
enum AppStatusType {
  active('Active', Icons.play_arrow_rounded, LiquidColors.primary),
  upcoming('Upcoming', Icons.schedule_rounded, LiquidColors.info),
  completed('Completed', Icons.check_circle_rounded, LiquidColors.success),
  missed('Missed', Icons.cancel_outlined, LiquidColors.warning),
  overdue('Overdue', Icons.error_outline_rounded, LiquidColors.error),
  focus('Focus', Icons.timelapse_rounded, LiquidColors.secondary),
  revision('Revision', Icons.repeat_rounded, LiquidColors.neonPurple),
  practice('Practice', Icons.quiz_outlined, LiquidColors.neonBlue),
  exam('Exam', Icons.school_outlined, LiquidColors.warning),
  offline('Offline', Icons.cloud_off_rounded, LiquidColors.textSecondaryLight),
  synced('Synced', Icons.cloud_done_rounded, LiquidColors.success),
  loading('Loading', Icons.sync_rounded, LiquidColors.info),
  custom('Custom', Icons.info_outline_rounded, LiquidColors.primary);

  const AppStatusType(this.defaultLabel, this.icon, this.color);

  final String defaultLabel;
  final IconData icon;
  final Color color;
}

/// Semantic Status Chip for displaying task/session/academic states.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.label,
    this.showIcon = true,
    this.icon,
    this.color,
    this.isSelected = false,
    this.onTap,
    this.compact = false,
  });

  final AppStatusType status;
  final String? label;
  final bool showIcon;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? status.color;
    final effectiveLabel = label ?? status.defaultLabel;
    final effectiveIcon = icon ?? status.icon;

    final bg = effectiveColor.withValues(
      alpha: isSelected ? (isDark ? 0.35 : 0.22) : (isDark ? 0.14 : 0.08),
    );

    final border = effectiveColor.withValues(
      alpha: isSelected ? (isDark ? 0.8 : 0.6) : (isDark ? 0.28 : 0.2),
    );

    return GlassSurface(
      level: isSelected ? GlassLevel.elevated : GlassLevel.standard,
      radius: LiquidRadius.pill,
      backgroundColor: bg,
      borderColor: border,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? LiquidSpacing.xs : LiquidSpacing.sm,
        vertical: compact ? 3 : 5,
      ),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              effectiveIcon,
              size: compact ? 12 : 14,
              color: effectiveColor,
            ),
            SizedBox(width: compact ? 3 : 5),
          ],
          Text(
            effectiveLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
