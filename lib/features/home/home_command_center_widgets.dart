/// Home 3.0 — Command Center presentation components.
///
/// Pure presentation: every widget receives an already-derived
/// [HomeCommandCenterState] and performs no business logic, no scoring, and
/// no controller reads of its own.
library;

import 'package:flutter/material.dart';

import '../../core/animations/animated_entrance.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/design/tokens/student_os_tokens.dart';
import '../../core/intelligence/academic_intelligence_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import 'home_command_center_state.dart';

// ══════════════════════════════════════════════════════════════════════════
// ACTIVE SESSION — surfaces the ONE session that already exists.
// Home never starts, stops, or duplicates a session.
// ══════════════════════════════════════════════════════════════════════════

class HomeActiveSessionBanner extends StatelessWidget {
  const HomeActiveSessionBanner({
    super.key,
    required this.session,
    required this.onContinue,
  });

  final HomeActiveSessionView session;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    // A live session is the most important state on the whole screen, so it
    // gets the Deep Forest treatment. Paused drops to a quieter tone.
    final surface = session.isPaused ? palette.surface : palette.deepForest;
    final onSurface = session.isPaused ? palette.onSurface : Colors.white;
    final muted = session.isPaused
        ? palette.onSurfaceMuted
        : Colors.white.withValues(alpha: 0.78);
    final accent = session.isPaused ? palette.sage : palette.softSage;

    return Semantics(
      liveRegion: true,
      container: true,
      label:
          '${session.badgeLabel}. ${session.title}. ${session.timeLabel}.',
      child: AppCard(
        color: surface,
        borderColor: session.isPaused
            ? palette.border
            : palette.deepForest,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Meaningful icon, not colour alone: countdown modes differ from
            // an open-ended stopwatch.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: session.isPaused ? 0.14 : 0.18),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                session.isOpenEnded
                    ? Icons.hourglass_bottom_rounded
                    : Icons.timer_rounded,
                color: accent,
                size: 20,
                semanticLabel: session.isOpenEnded ? 'Stopwatch' : 'Timer',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.badgeLabel,
                    style: context.text.labelSmall?.copyWith(
                      color: session.isPaused ? palette.warning : accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.title,
                    style: context.text.titleSmall?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    session.timeLabel,
                    style: context.text.bodySmall?.copyWith(color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Deep forest emerald is the reserved "take action" accent.
            FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: StudentOSColors.studentBlue,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// RECOMMENDED ACTION — exactly ONE recommendation with a visible "why".
// Ranking comes from AdaptivePriorityEngine; Home only selects and presents.
// ══════════════════════════════════════════════════════════════════════════

class HomeRecommendedActionCard extends StatelessWidget {
  const HomeRecommendedActionCard({
    super.key,
    required this.recommendation,
    required this.onStart,
    required this.onWhy,
  });

  final HomeRecommendationView recommendation;
  final VoidCallback onStart;
  final VoidCallback onWhy;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final accent = _urgencyColor(palette);

    return Semantics(
      container: true,
      label:
          'Recommended for you. ${recommendation.title}. ${recommendation.reason}',
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderColor: accent.withValues(alpha: 0.30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13, color: accent),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'RECOMMENDED FOR YOU',
                    style: context.text.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (recommendation.estimatedMinutes > 0)
                  Text(
                    '${recommendation.estimatedMinutes} min',
                    style: context.text.labelSmall?.copyWith(
                      color: palette.onSurfaceMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              recommendation.title,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // The engine's own explanation. Home never paraphrases a claim the
            // intelligence layer did not derive.
            Text(
              recommendation.reason,
              style: context.text.bodySmall?.copyWith(
                color: palette.onSurfaceMuted,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      backgroundColor: StudentOSColors.studentBlue,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: onWhy,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: palette.onSurface,
                    side: BorderSide(color: palette.border),
                  ),
                  child: const Text('Why?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tonal hierarchy, not a new severity system: the urgency came from the
  /// engine's priority score, this only maps it onto the Phase 1 palette.
  Color _urgencyColor(dynamic palette) {
    switch (recommendation.action.urgency) {
      case RecommendationUrgency.critical:
        return AppColors.error;
      case RecommendationUrgency.high:
        return AppColors.warning;
      case RecommendationUrgency.medium:
        return StudentOSColors.forest;
      case RecommendationUrgency.low:
        return StudentOSColors.mutedGreen;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// AUTOPILOT AWARENESS — reads the existing preference. Implements nothing.
// ══════════════════════════════════════════════════════════════════════════

class HomeAutopilotStrip extends StatelessWidget {
  const HomeAutopilotStrip({
    super.key,
    required this.awareness,
    required this.nextActionTitle,
  });

  final HomeAutopilotAwareness awareness;
  final String? nextActionTitle;

  @override
  Widget build(BuildContext context) {
    if (awareness == HomeAutopilotAwareness.off) {
      return const SizedBox.shrink();
    }
    final palette = AppTheme.colorsOf(context);
    final isManaging = awareness == HomeAutopilotAwareness.managing;

    final title = isManaging
        ? 'Your day is being managed.'
        : 'Autopilot suggests.';
    final detail = nextActionTitle == null || nextActionTitle!.isEmpty
        ? (isManaging
            ? 'Safe planning decisions are being applied for you.'
            : 'Review the suggestion before it is applied.')
        : (isManaging ? 'Next action: $nextActionTitle' : 'Suggested: $nextActionTitle');

    return Semantics(
      container: true,
      label: '$title $detail',
      child: AppCard(
        color: palette.paleSage,
        borderColor: palette.softSage,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              isManaging
                  ? Icons.auto_mode_rounded
                  : Icons.lightbulb_outline_rounded,
              size: 16,
              color: palette.forest,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.text.bodySmall?.copyWith(
                      color: palette.forest,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    detail,
                    style: context.text.labelSmall?.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// TODAY PROGRESS METRICS — 2–4 metrics, prioritised. No analytics engine.
// ══════════════════════════════════════════════════════════════════════════

/// One compact metric cell. Meaning is carried by the label, not the colour.
class HomeMetricCell extends StatelessWidget {
  const HomeMetricCell({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final color = tone ?? palette.primary;

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      // Laid out inside a Wrap, so this must NOT be an Expanded. A minimum
      // width keeps the cells evenly readable while still reflowing on 320dp.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      color: palette.onSurfaceMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress ring plus the prioritised metric row.
class HomeProgressSummary extends StatelessWidget {
  const HomeProgressSummary({
    super.key,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.overdueTaskCount,
    required this.focusMinutesToday,
    required this.isOverloaded,
  });

  final int plannedMinutes;
  final int completedMinutes;
  final int overdueTaskCount;
  final int focusMinutesToday;
  final bool isOverloaded;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    // A calm/complete day should not keep screaming Forest at the student.
    final isComplete = plannedMinutes > 0 && completedMinutes >= plannedMinutes;
    final ringColor = isOverloaded
        ? palette.error
        : isComplete
            ? StudentOSColors.sage
            : palette.primary;
    final progress = plannedMinutes > 0
        ? (completedMinutes / plannedMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          label: 'Today progress: ${(progress * 100).round()} percent of '
              'planned study time completed',
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: palette.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(ringColor),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ringColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Wrap so the 2–4 metrics reflow on a 320dp screen instead of clipping.
        Expanded(
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: _metrics(palette),
          ),
        ),
      ],
    );
  }

  /// Only the metrics that are actually useful given real data. Zero-value
  /// metrics are dropped rather than rendered as "0 overdue".
  List<Widget> _metrics(dynamic palette) {
    final cells = <Widget>[];

    if (plannedMinutes > 0) {
      cells.add(HomeMetricCell(
        label: 'Planned',
        value: formatHomeMinutes(plannedMinutes),
        icon: Icons.event_rounded,
        tone: palette.primary,
      ));
    }

    if (completedMinutes > 0) {
      cells.add(HomeMetricCell(
        label: 'Done',
        value: formatHomeMinutes(completedMinutes),
        icon: Icons.check_circle_rounded,
        tone: StudentOSColors.sage,
      ));
    }

    final remaining = plannedMinutes - completedMinutes;
    if (remaining > 0) {
      cells.add(HomeMetricCell(
        label: 'Left',
        value: formatHomeMinutes(remaining),
        icon: Icons.timelapse_rounded,
        tone: StudentOSColors.mutedGreen,
      ));
    }

    // Overdue outranks everything else: it is the one number that should be
    // impossible to miss.
    if (overdueTaskCount > 0) {
      cells.add(HomeMetricCell(
        label: 'Overdue',
        value: '$overdueTaskCount',
        icon: Icons.error_outline_rounded,
        tone: palette.error,
      ));
    }

    if (focusMinutesToday > 0) {
      cells.add(HomeMetricCell(
        label: 'Focus',
        value: '${focusMinutesToday}m',
        icon: Icons.timer_rounded,
        tone: StudentOSColors.softSage,
      ));
    }

    if (cells.isEmpty) {
      cells.add(HomeMetricCell(
        label: 'Planned',
        value: 'Nothing yet',
        icon: Icons.event_rounded,
        tone: palette.onSurfaceMuted,
      ));
    }

    // Cap at 4 so the row never becomes a dashboard.
    return cells.take(4).toList();
  }
}

// ══════════════════════════════════════════════════════════════════════════
// EMPTY STATE — actionable, never fake progress.
// ══════════════════════════════════════════════════════════════════════════

class HomeEmptyStateCard extends StatelessWidget {
  const HomeEmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.explore_outlined,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      color: palette.paleSage,
      borderColor: palette.softSage,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.mutedGreen),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  message,
                  style: context.text.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Re-export so Home can wrap a changing section without duplicating the
/// Phase 1 entrance animation.
class HomeSectionEntrance extends StatelessWidget {
  const HomeSectionEntrance({super.key, required this.child, this.delay});

  final Widget child;
  final Duration? delay;

  @override
  Widget build(BuildContext context) => AnimatedEntrance(
        delay: delay ?? Duration.zero,
        child: child,
      );
}
