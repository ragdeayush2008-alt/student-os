import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_animated_number.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_progress.dart';
import '../progress_controller.dart';
import 'progress_base.dart';

/// Section B — the premium Momentum Hero.
///
/// One strong hero card summarizing the user's overall momentum using real
/// task + study data, with an explanation of what drives the number (never just
/// a giant unexplained percentage). Shows a meaningful zero-state when there is
/// no activity yet.
class MomentumHero extends StatelessWidget {
  const MomentumHero({
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
    if (!snapshot.hasAnyActivity) {
      return _MomentumZero(onTasks: onTasks, onStudy: onStudy);
    }

    final palette = AppTheme.colorsOf(context);
    final score = snapshot.momentumScore;
    final weeklyRate = snapshot.rangeCompletion;
    final studyDuration = snapshot.studyDuration;
    final consistency = snapshot.consistency;

    return AppCard(
      color: palette.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                size: 20,
                color: palette.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Momentum',
                  style: context.text.titleMedium!.copyWith(
                    color: palette.primary,
                  ),
                ),
              ),
              if (score != null) _ScoreBadge(score: score, palette: palette),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _HudRow(
            label: 'Tasks completed',
            value: snapshot.tasksCompletedInRange,
            icon: Icons.task_alt_rounded,
            color: palette.primary,
            onTap: onTasks,
          ),
          const SizedBox(height: AppSpacing.sm),
          _HudRow(
            label: 'Study time',
            valueBuilder: (context) => AppAnimatedNumberText(
              value: studyDuration.inMinutes.toDouble(),
              format: (v) => '${v.round()}m',
              style: context.text.titleSmall,
            ),
            icon: Icons.timer_outlined,
            color: palette.warning,
            onTap: onStudy,
          ),
          const SizedBox(height: AppSpacing.md),
          _ConsistencyBar(
            label: 'Consistency',
            value: consistency,
            caption:
                '${(consistency * 100).round()}% of days active in this period',
            color: palette.info,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CompletionBar(
            label: 'Completion rate',
            value: weeklyRate,
            caption: '${(weeklyRate * 100).round()}% of expected tasks done',
            color: palette.success,
          ),
          const SizedBox(height: AppSpacing.md),
          _TrendRow(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, required this.palette});

  final double score;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.streak,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 3),
          AppAnimatedNumberText(
            value: score,
            format: (v) => '${v.round()}',
            style: context.text.labelMedium!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudRow extends StatelessWidget {
  const _HudRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.value,
    this.valueBuilder,
  }) : assert(value != null || valueBuilder != null);

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? value;
  final Widget Function(BuildContext)? valueBuilder;

  @override
  Widget build(BuildContext context) {
    final valueWidget = valueBuilder != null
        ? valueBuilder!(context)
        : AppAnimatedNumberText(
            value: value!.toDouble(),
            format: (v) => '${v.round()}',
            style: context.text.titleSmall,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
              Expanded(child: Text(label, style: context.text.bodyMedium)),
              valueWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsistencyBar extends StatelessWidget {
  const _ConsistencyBar({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  final String label;
  final double value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.text.labelLarge)),
            Text(caption, style: context.text.labelSmall),
          ],
        ),
        const SizedBox(height: 6),
        AppLinearProgress(value: value, height: 7, color: color),
      ],
    );
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  final String label;
  final double value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.text.labelLarge)),
            Text(caption, style: context.text.labelSmall),
          ],
        ),
        const SizedBox(height: 6),
        AppLinearProgress(value: value, height: 7, color: color),
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.snapshot});

  final ProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final showPrev =
        snapshot.hasHistory && snapshot.range != ProgressRange.today;

    if (!showPrev) {
      if (snapshot.currentStreak >= 2) {
        return _TrendPill(
          icon: Icons.local_fire_department_rounded,
          color: palette.streak,
          text: '${snapshot.currentStreak}-day streak',
        );
      }
      return const SizedBox.shrink();
    }

    final taskImprovement = snapshot.prevTaskCompletionRate == null
        ? null
        : snapshot.rangeCompletion - snapshot.prevTaskCompletionRate!;
    final studyImprovement = snapshot.studyDelta;

    final List<Widget> pills = [];
    if (taskImprovement != null && taskImprovement.abs() >= 0.02) {
      final up = taskImprovement > 0;
      pills.add(
        _TrendPill(
          icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: up ? palette.success : palette.warning,
          text:
              '${(taskImprovement.abs() * 100).round()}% ${up ? 'faster' : 'slower'} on tasks',
        ),
      );
    }
    if (studyImprovement.inMinutes.abs() >= 15) {
      final up = studyImprovement.inMinutes > 0;
      pills.add(
        _TrendPill(
          icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: up ? palette.success : palette.info,
          text:
              '${ProgressFormat.minutes(studyImprovement.abs())} ${up ? 'more' : 'less'} study vs prior',
        ),
      );
    }

    if (pills.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: pills,
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(text, style: context.text.labelSmall!.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _MomentumZero extends StatelessWidget {
  const _MomentumZero({required this.onTasks, required this.onStudy});

  final VoidCallback onTasks;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              size: 26,
              color: palette.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Momentum starts here', style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Once you complete a task or study session, real momentum metrics appear here.',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _MiniCta(
                      icon: Icons.add_task_rounded,
                      label: 'Plan a task',
                      onTap: onTasks,
                      color: palette.primary,
                    ),
                    _MiniCta(
                      icon: Icons.timer_rounded,
                      label: 'Start study',
                      onTap: onStudy,
                      color: palette.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCta extends StatelessWidget {
  const _MiniCta({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: context.text.labelSmall!.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
