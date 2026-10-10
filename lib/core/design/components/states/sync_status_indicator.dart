import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_surface.dart';

/// Semantic sync & connectivity states.
enum SyncState {
  loading('Syncing...', Icons.sync_rounded, LiquidColors.info),
  synced('Synced', Icons.cloud_done_rounded, LiquidColors.success),
  offlineFallback('Offline Mode', Icons.cloud_off_rounded, LiquidColors.warning),
  unavailable('Unavailable', Icons.cloud_queue_rounded, LiquidColors.textSecondaryLight),
  error('Sync Error', Icons.sync_problem_rounded, LiquidColors.error);

  const SyncState(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Visual sync state indicator / pill.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.state,
    this.compact = true,
    this.onTap,
  });

  final SyncState state;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassSurface(
      level: GlassLevel.standard,
      radius: LiquidRadius.pill,
      backgroundColor: state.color.withValues(alpha: isDark ? 0.16 : 0.08),
      borderColor: state.color.withValues(alpha: isDark ? 0.35 : 0.22),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? LiquidSpacing.xs : LiquidSpacing.sm,
        vertical: compact ? 3 : 5,
      ),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == SyncState.loading)
            SizedBox(
              width: compact ? 10 : 12,
              height: compact ? 10 : 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(state.color),
              ),
            )
          else
            Icon(
              state.icon,
              size: compact ? 12 : 14,
              color: state.color,
            ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            state.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: state.color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Offline Banner widget for non-intrusive offline warnings.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.message = 'You are currently offline. Changes are saved locally and will sync when reconnected.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LiquidSpacing.md,
        vertical: LiquidSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: LiquidColors.warning.withValues(alpha: isDark ? 0.18 : 0.10),
        border: Border(
          bottom: BorderSide(
            color: LiquidColors.warning.withValues(alpha: isDark ? 0.35 : 0.22),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: LiquidColors.warning,
          ),
          const SizedBox(width: LiquidSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? LiquidColors.textPrimaryDark
                    : LiquidColors.textPrimaryLight,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
