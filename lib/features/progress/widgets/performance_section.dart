import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_metric_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../progress_controller.dart';
import 'progress_base.dart';

/// Section D — premium performance breakdown metric cards.
///
/// Real metrics (tasks completed, study time, completion rate, active streak)
/// with meaningful hierarchy and smooth number animation.
class PerformanceBreakdown extends StatelessWidget {
  const PerformanceBreakdown({
    super.key,
    required this.snapshot,
    required this.onTasks,
    required this.onStudy,
  });

  final ProgressSnapshot snapshot;
  final VoidCallback onTasks;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final s = snapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Performance',
          icon: Icons.speed_rounded,
          subtitle: 'Real activity in this period',
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppMetricCard(
                label: 'Tasks completed',
                value: s.tasksCompletedInRange.toDouble(),
                icon: Icons.task_alt_rounded,
                iconColor: palette.primary,
                onTap: onTasks,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppMetricCard(
                label: 'Study time',
                valueBuilder: (c) => Text(
                  ProgressFormat.duration(s.studyDuration),
                  style: c.text.headlineSmall,
                ),
                icon: Icons.timer_outlined,
                iconColor: palette.warning,
                onTap: onStudy,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppMetricCard(
                label: 'Completion rate',
                value: (s.lifetimeCompletion * 100).roundToDouble(),
                note:
                    '${(s.lifetimeCompletion * 100).round()}% of all tasks done',
                icon: Icons.done_all_rounded,
                iconColor: palette.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppMetricCard(
                label: 'Active streak',
                value: s.currentStreak.toDouble(),
                note: 'Best: ${s.bestStreak}',
                icon: Icons.local_fire_department_rounded,
                iconColor: palette.streak,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
