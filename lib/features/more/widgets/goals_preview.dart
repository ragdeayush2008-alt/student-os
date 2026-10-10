import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../goals/goal_controller.dart';

/// A compact preview of configured goals with progress bars shown in the
/// More hub. Tapping navigates to the full goals screen.
class GoalsPreview extends StatelessWidget {
  const GoalsPreview({
    super.key,
    required this.goalController,
    required this.dailyProgress,
    required this.weeklyStudyProgress,
    required this.weeklyTaskProgress,
    required this.onViewAll,
  });

  final GoalController goalController;
  final GoalProgress dailyProgress;
  final GoalProgress weeklyStudyProgress;
  final GoalProgress weeklyTaskProgress;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final hasAnyTarget =
        goalController.weeklyStudyTarget.inMinutes > 0 ||
        goalController.weeklyTaskTarget > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Goals', style: context.text.titleMedium)),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: context.text.labelMedium!.copyWith(
                      color: palette.primary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: palette.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasAnyTarget && goalController.personalGoal.isEmpty)
          _EmptyGoals(onViewAll: onViewAll)
        else ...[
          if (goalController.weeklyStudyTarget.inMinutes > 0)
            _GoalProgressRow(
              label: 'Weekly study',
              progress: weeklyStudyProgress,
              color: palette.warning,
            ),
          if (goalController.weeklyStudyTarget.inMinutes > 0)
            const SizedBox(height: AppSpacing.xs),
          if (goalController.weeklyTaskTarget > 0)
            _GoalProgressRow(
              label: 'Weekly tasks',
              progress: weeklyTaskProgress,
              color: palette.primary,
            ),
          if (goalController.weeklyTaskTarget > 0)
            const SizedBox(height: AppSpacing.xs),
          if (goalController.dailyStudyTarget.inMinutes > 0)
            _GoalProgressRow(
              label: 'Daily study',
              progress: dailyProgress,
              color: palette.info,
            ),
          if (goalController.personalGoal.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _PersonalGoalChip(label: goalController.personalGoal),
          ],
        ],
      ],
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({
    required this.label,
    required this.progress,
    required this.color,
  });

  final String label;
  final GoalProgress progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.text.labelLarge)),
              Text(
                progress.summary,
                style: context.text.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 5,
              backgroundColor: AppTheme.colorsOf(context).surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.isComplete
                    ? AppTheme.colorsOf(context).success
                    : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalGoalChip extends StatelessWidget {
  const _PersonalGoalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(
            Icons.center_focus_strong_rounded,
            size: 18,
            color: palette.streak,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current focus', style: context.text.labelSmall),
                Text(
                  label,
                  style: context.text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      onTap: onViewAll,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flag_rounded, size: 22, color: palette.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No goals set', style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Set targets to help Student OS measure your direction.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: palette.onSurfaceMuted,
          ),
        ],
      ),
    );
  }
}
