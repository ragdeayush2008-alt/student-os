import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';

/// Section — elegant early-user state explaining the Student OS loop.
///
/// Shown only when there is no task or study activity yet. It explains how the
/// ecosystem connects (Plan → Complete → Study → Progress) without blockading
/// normal functionality; it naturally disappears as real data appears.
class EarlyUserState extends StatelessWidget {
  const EarlyUserState({
    super.key,
    required this.onPlan,
    required this.onTasks,
    required this.onStudy,
  });

  final VoidCallback onPlan;
  final VoidCallback onTasks;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'How progress works',
          icon: Icons.explore_outlined,
          subtitle: 'Your progress grows with your activity',
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _Step(
                index: 1,
                icon: Icons.calendar_today_outlined,
                color: palette.primary,
                title: 'Plan work',
                subtitle: 'Schedule what needs to be done.',
                onTap: onPlan,
              ),
              const SizedBox(height: AppSpacing.md),
              _Step(
                index: 2,
                icon: Icons.task_alt_rounded,
                color: palette.info,
                title: 'Complete tasks',
                subtitle: 'Finish tasks to build your completion record.',
                onTap: onTasks,
              ),
              const SizedBox(height: AppSpacing.md),
              _Step(
                index: 3,
                icon: Icons.timer_outlined,
                color: palette.warning,
                title: 'Study consistently',
                subtitle: 'Focus sessions build your study rhythm.',
                onTap: onStudy,
              ),
              const SizedBox(height: AppSpacing.md),
              _Step(
                index: 4,
                icon: Icons.auto_graph_rounded,
                color: palette.streak,
                title: 'Watch your progress become meaningful',
                subtitle: 'Strength, streaks and insights appear from your real data.',
                prominent: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'This is one connected ecosystem — every module feeds your progress.',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.prominent = false,
  });

  final int index;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppDurations.fast;

    final content = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: context.text.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (prominent) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.star_rounded, size: 15, color: palette.streak),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: context.text.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (index < 4 && onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: palette.onSurfaceMuted,
          ),
      ],
    );

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: prominent
            ? palette.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: prominent
            ? Border.all(color: palette.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: content,
            )
          : content,
    );
  }
}
