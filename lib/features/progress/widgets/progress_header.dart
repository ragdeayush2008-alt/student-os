import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../progress_controller.dart';
import 'progress_base.dart';

/// Section A — the premium Progress header.
///
/// Shows a strong contextual title, current week/date context, and a concise
/// real insight derived solely from the snapshot's data — never generic
/// motivation disconnected from the data.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.snapshot,
    required this.milestones,
    required this.onPlan,
    required this.onStudy,
  });

  final ProgressSnapshot snapshot;
  final List<ProgressMilestone> milestones;
  final VoidCallback onPlan;
  final VoidCallback onStudy;

  String get _context => progressHeaderContext(snapshot);
  String? get _insight => progressHeaderInsight(snapshot, milestones);

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your progress',
                    style: context.text.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 14,
                        color: palette.onSurfaceMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _context,
                          style: context.text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _InsightBanner(
          insight: _insight,
          snapshot: snapshot,
          onPlan: onPlan,
          onStudy: onStudy,
        ),
      ],
    );
  }
}

/// A helper that derives a strong contextual title purely from [snapshot].
String progressHeaderTitle(ProgressSnapshot s) {
  return switch (s.range) {
    ProgressRange.today => "Today's momentum",
    ProgressRange.week => "This week's momentum",
    ProgressRange.month => "This month's progress",
  };
}

/// A helper that derives the date/week context label from [snapshot].
String progressHeaderContext(ProgressSnapshot s) {
  final now = DateTime.now();
  return switch (s.range) {
    ProgressRange.today =>
      '${ProgressFormat.weekdayFull(now.weekday)}, ${now.day} ${ProgressFormat.month(now.month)}',
    ProgressRange.week =>
      '${ProgressFormat.shortDate(s.span.start)} – ${ProgressFormat.shortDate(s.span.end.subtract(const Duration(days: 1)))}',
    ProgressRange.month =>
      '${ProgressFormat.month(s.span.start.month)} ${s.span.start.year}',
  };
}

/// Builds a concise, data-backed insight string. Returns null when no real
/// signal is available (falls back to a neutral, non-claiming line).
String? progressHeaderInsight(
  ProgressSnapshot s,
  List<ProgressMilestone> milestones,
) {
  if (!s.hasAnyActivity) {
    return 'Your progress becomes meaningful once you plan, complete and study.';
  }

  if (s.range == ProgressRange.week) {
    if (s.consistency > 0) {
      final days = (s.consistency * 7).round();
      if (days >= 5) {
        return 'Most consistent week yet — $days active days so far.';
      }
      if (s.taskDelta > 0) {
        return '${s.taskDelta} more ${s.taskDelta == 1 ? 'task' : 'tasks'} done than last week.';
      }
      if (s.studyDelta.inMinutes >= 30) {
        return 'Study time is up ${ProgressFormat.minutes(s.studyDelta)} vs last week.';
      }
    }
  }

  if (s.range == ProgressRange.today) {
    final completed = s.tasksCompletedInRange;
    if (completed > 0) {
      return '$completed ${completed == 1 ? 'task' : 'tasks'} completed today so far.';
    }
    if (s.studyDuration.inMinutes > 0) {
      return '${ProgressFormat.minutes(s.studyDuration)} studied today.';
    }
  }

  final anyEarned = milestones.any((m) => m.earned);
  if (!anyEarned) {
    return s.hasOnlyStudy
        ? 'Great start — your study rhythm is beginning to build.'
        : 'Start your first session to build momentum.';
  }

  if (s.momentumScore != null && s.currentStreak >= 2) {
    return '${s.currentStreak}-day streak — you\'re building momentum.';
  }

  return 'You\'re making real progress in Student OS.';
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({
    required this.insight,
    required this.snapshot,
    required this.onPlan,
    required this.onStudy,
  });

  final String? insight;
  final ProgressSnapshot snapshot;
  final VoidCallback onPlan;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppDurations.slow,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          colors: palette.accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              insight ??
                  'Your progress becomes meaningful with every completed task.',
              style: context.text.bodyMedium!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!snapshot.hasAnyActivity) ...[
            const Spacer(),
            _InlineAction(
              icon: Icons.add_task_rounded,
              label: 'Plan',
              onTap: onPlan,
            ),
            const SizedBox(width: 6),
            _InlineAction(
              icon: Icons.timer_rounded,
              label: 'Study',
              onTap: onStudy,
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.text.labelSmall!.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
