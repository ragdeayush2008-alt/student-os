import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

/// A compact grid of real ecosystem metrics at the top of the More hub.
///
/// Each cell represents real data (study streak, weekly completions, study time,
/// goals progress) and is tappable to navigate to the relevant module.
class EcosystemStatus extends StatelessWidget {
  const EcosystemStatus({
    super.key,
    required this.streak,
    required this.weeklyTasks,
    required this.weeklyStudyLabel,
    required this.goalsProgress,
    required this.onStudy,
    required this.onTasks,
    required this.onProgress,
    required this.onGoals,
  });

  final int streak;
  final int weeklyTasks;
  final String weeklyStudyLabel;
  final double goalsProgress;
  final VoidCallback onStudy;
  final VoidCallback onTasks;
  final VoidCallback onProgress;
  final VoidCallback onGoals;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Student OS', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricCell(
                icon: Icons.local_fire_department_rounded,
                color: palette.streak,
                value: '$streak',
                label: 'Day streak',
                onTap: onStudy,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCell(
                icon: Icons.task_alt_rounded,
                color: palette.primary,
                value: '$weeklyTasks',
                label: 'Tasks / week',
                onTap: onTasks,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricCell(
                icon: Icons.timer_outlined,
                color: palette.warning,
                value: weeklyStudyLabel,
                label: 'Study / week',
                onTap: onStudy,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCell(
                icon: Icons.flag_rounded,
                color: palette.info,
                value: '${(goalsProgress * 100).round()}%',
                label: 'Goals hit',
                onTap: onGoals,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(label, style: context.text.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
