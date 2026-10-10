import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../progress_controller.dart';
import 'progress_base.dart';

/// Section C — a compact, polished weekly activity visualization.
///
/// Shows all seven days of the current week as vertical bars whose height
/// reflects real combined activity (completed tasks + study time). Each bar
/// reveals animatedly once, and a meaningful zero-data state is shown while
/// keeping the visual structure intact.
class WeeklyActivity extends StatelessWidget {
  const WeeklyActivity({super.key, required this.days});

  final List<ProgressDay> days;

  @override
  Widget build(BuildContext context) {
    final hasAny = days.any((d) => d.hasActivity);
    final maxScore = days.fold<double>(
      0,
      (m, d) => d.combinedScore > m ? d.combinedScore : m,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'This week',
          icon: Icons.insights_rounded,
          subtitle: hasAny
              ? 'Real activity across your seven days'
              : 'No activity logged yet this week',
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 112,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < days.length; i++)
                      Expanded(
                        child: _DayBar(day: days[i], maxScore: maxScore),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _Legend(),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.day, required this.maxScore});

  final ProgressDay day;
  final double maxScore;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final ratio = day.activityRatio(maxScore);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (day.tasksCompleted > 0 || day.studySeconds > 0)
          Text(
            day.tasksCompleted > 0 ? '${day.tasksCompleted}✓' : '',
            style: context.text.labelSmall!.copyWith(color: palette.primary),
          )
        else
          const SizedBox(height: 14),
        const SizedBox(height: 3),
        Expanded(
          child: SizedBox(
            width: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _AnimatedBar(value: ratio, day: day),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ProgressFormat.dayMarker(day.date),
          style: context.text.labelSmall!.copyWith(
            color: day.isToday ? palette.primary : palette.onSurfaceMuted,
            fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  const _AnimatedBar({required this.value, required this.day});

  final double value;
  final ProgressDay day;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final hasActivity = day.hasActivity;

    final bar = Container(
      width: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: hasActivity ? null : palette.surfaceVariant,
        gradient: hasActivity
            ? LinearGradient(
                colors: [
                  palette.primary,
                  palette.primary.withValues(alpha: 0.6),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              )
            : null,
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        final h = (72 * animated).clamp(4.0, 72.0);
        return SizedBox(height: h, child: bar);
      },
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          _LegendItem(color: palette.primary, label: 'Task completions'),
          _LegendItem(color: palette.warning, label: 'Study time'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: context.text.labelSmall),
      ],
    );
  }
}
