import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/task.dart';
import '../../../data/models/topic.dart';
import '../plan_study_state.dart';

/// §4 — Academic planning header.
///
/// Reads PLAN/date/planned-minutes/block-count straight from [PlanDayView].
/// No hard-coded values: with no plan it says so instead of inventing numbers.
class PlanStudyPlanHeader extends StatelessWidget {
  const PlanStudyPlanHeader({
    super.key,
    required this.day,
  });

  final PlanDayView day;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: palette.forest.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PLAN',
                style: context.text.labelSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: palette.mutedGreen,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  day.isToday ? 'Today' : 'Selected day',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.onSurfaceMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (day.hasPlan)
                _PlanHeaderBadge(
                  label: day.allCompleted
                      ? 'Done'
                      : '${day.remainingBlocks} left',
                  color: day.allCompleted ? palette.softSage : palette.sage,
                  foreground: palette.deepForest,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            day.dayLabel,
            style: context.text.titleLarge!.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            day.hasPlan
                ? '${formatPlanMinutes(day.plannedMinutes)} planned · '
                    '${day.blocks.length} ${day.blocks.length == 1 ? 'block' : 'blocks'}'
                : 'Nothing planned yet',
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (day.hasPlan) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: day.progress,
                minHeight: 5,
                backgroundColor: palette.paleSage.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(palette.forest),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatPlanMinutes(day.completedMinutes)} of '
                    '${formatPlanMinutes(day.plannedMinutes)} complete',
                    style: context.text.labelSmall!.copyWith(
                      color: palette.onSurfaceMuted,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(day.progress * 100).round()}%',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.forest,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanHeaderBadge extends StatelessWidget {
  const _PlanHeaderBadge({
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: context.text.labelSmall!.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// §6 — The block happening right now.
///
/// When a Focus session is already running this preserves it and offers
/// Continue; it never starts a second session.
class PlanActiveBlockCard extends StatelessWidget {
  const PlanActiveBlockCard({
    super.key,
    required this.day,
    required this.onStart,
    required this.onContinueFocus,
  });

  final PlanDayView day;
  final void Function(PlanBlockView block) onStart;
  final VoidCallback onContinueFocus;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final block = day.activeBlock!;
    final focusRunning = day.hasFocusSession;

    // Light canonical treatment (same card family as the rest of Plan &
    // Study): emphasis via the NOW pill + primary CTA, never a dark fill.
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: palette.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'NOW',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${block.startLabel} – ${block.endLabel}',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.onSurfaceMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            block.subjectName ?? block.title,
            style: context.text.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (block.chapterTitle != null || block.topicTitle != null) ...[
            const SizedBox(height: 2),
            Text(
              [block.chapterTitle, block.topicTitle]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            focusRunning
                ? 'Focus session running · ${day.focusObjective}'
                : '${block.remainingMinutes} min remaining',
            style: context.text.labelSmall!.copyWith(
              color: palette.onSurfaceMuted,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size(0, 40),
                  ),
                  icon: Icon(
                    focusRunning
                        ? Icons.timer_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(focusRunning ? 'Continue Focus' : 'Start Now'),
                  onPressed: focusRunning
                      ? onContinueFocus
                      : () => onStart(block),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// §5 — Compact planned-block row with full academic context.
///
/// time · subject · chapter/topic · duration · status · priority · completion.
class PlanBlockRow extends StatelessWidget {
  const PlanBlockRow({
    super.key,
    required this.view,
    required this.onStart,
    this.onReschedule,
  });

  final PlanBlockView view;
  final void Function(PlanBlockView view) onStart;
  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final (statusColor, statusIcon, statusLabel) = switch (view.status) {
      PlanBlockStatus.completed =>
        (palette.softSage, Icons.check_rounded, 'Done'),
      PlanBlockStatus.active =>
        (palette.accent, Icons.play_arrow_rounded, 'Now'),
      PlanBlockStatus.missed =>
        (palette.warning, Icons.priority_high_rounded, 'Missed'),
      PlanBlockStatus.upcoming =>
        (palette.sage, Icons.circle_outlined, 'Planned'),
    };

    final detail = [
      if (view.subjectName != null) view.subjectName!,
      if (view.chapterTitle != null) view.chapterTitle!,
      if (view.topicTitle != null) view.topicTitle!,
    ].join(' · ');

    return Semantics(
      label: '${view.startLabel} ${view.title}, '
          '${view.durationMinutes} minutes, $statusLabel',
      button: !view.isCompleted,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.startLabel,
                    style: context.text.labelSmall!.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: view.isCompleted
                          ? palette.onSurfaceMuted
                          : palette.onSurface,
                    ),
                  ),
                  Text(
                    view.endLabel,
                    style: context.text.labelSmall!.copyWith(
                      color: palette.onSurfaceMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, size: 14, color: statusColor),
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
                          view.title,
                          style: context.text.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: view.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: view.isCompleted
                                ? palette.onSurfaceMuted
                                : palette.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (view.priority != TaskPriority.low)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            view.priority.icon,
                            size: 12,
                            color: view.priority.color,
                          ),
                        ),
                    ],
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      style: context.text.labelSmall!.copyWith(
                        color: palette.mutedGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${view.durationMinutes} min · $statusLabel',
                    style: context.text.labelSmall!.copyWith(
                      color: palette.onSurfaceMuted,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!view.isCompleted)
              IconButton(
                tooltip: view.isMissed ? 'Reschedule' : 'Start block',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: Icon(
                  view.isMissed
                      ? Icons.event_repeat_rounded
                      : Icons.play_circle_outline_rounded,
                  size: 20,
                  color: view.isMissed ? palette.warning : palette.accent,
                ),
                onPressed: () =>
                    view.isMissed && onReschedule != null
                        ? onReschedule!()
                        : onStart(view),
              ),
          ],
        ),
      ),
    );
  }
}

/// §10 — A missed block with a recovery path. Never silently deleted.
class PlanMissedBlockRow extends StatelessWidget {
  const PlanMissedBlockRow({
    super.key,
    required this.view,
    required this.onReschedule,
  });

  final PlanBlockView view;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderColor: palette.warning.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(
            Icons.priority_high_rounded,
            size: 18,
            color: palette.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSED',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.warning,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  view.subjectName ?? view.title,
                  style: context.text.bodySmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${view.durationMinutes} min',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.onSurfaceMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              foregroundColor: palette.forest,
              side: BorderSide(color: palette.sage),
            ),
            icon: const Icon(Icons.event_repeat_rounded, size: 15),
            label: const Text('Reschedule'),
            onPressed: onReschedule,
          ),
        ],
      ),
    );
  }
}

/// §9 — Subject allocation derived from the existing PlanningEngine.
class PlanSubjectAllocationList extends StatelessWidget {
  const PlanSubjectAllocationList({
    super.key,
    required this.allocation,
  });

  final SubjectAllocation allocation;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final max = allocation.entries.fold<int>(
      1,
      (m, e) => e.minutes > m ? e.minutes : m,
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  size: 16, color: palette.forest),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'How ${formatPlanMinutes(allocation.budgetMinutes)} splits up',
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            allocation.isEmpty
                ? 'Nothing to allocate yet'
                : '${formatPlanMinutes(allocation.totalPlannedMinutes)} allocated'
                    '${allocation.isOverloaded ? ' · over budget' : ''}',
            style: context.text.labelSmall!.copyWith(
              color: allocation.isOverloaded
                  ? palette.error
                  : palette.onSurfaceMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (allocation.isEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add subjects or tasks, then generate a plan to see the split.',
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            // Proportional timeline: one glanceable day-strip where each
            // segment's width is its share of the plan.
            Semantics(
              label:
                  'Day timeline: ${allocation.entries.map((e) => '${e.subjectName} ${e.minutes} minutes').join(', ')}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      for (var i = 0;
                          i < allocation.entries.length;
                          i++) ...[
                        if (i > 0)
                          Container(
                            width: 2,
                            color: palette.surface,
                          ),
                        Expanded(
                          flex: allocation.entries[i].minutes > 0
                              ? allocation.entries[i].minutes
                              : 1,
                          child: Container(
                            color: _timelineTone(palette, i),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in allocation.entries) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.subjectName,
                            style: context.text.bodySmall!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primary
                                .withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${entry.minutes} min',
                            style: context.text.labelSmall!.copyWith(
                              color: palette.forest,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: entry.minutes / max,
                        minHeight: 4,
                        backgroundColor: palette.paleSage.withValues(alpha: 0.5),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(palette.sage),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Tonal emerald ladder for timeline segments (rotates, stays in family).
Color _timelineTone(AppPalette palette, int index) {
  const tones = [
    AppColors.deepForest,
    AppColors.forest,
    AppColors.success,
    AppColors.mutedGreen,
    AppColors.streak,
    AppColors.sage,
  ];
  return tones[index % tones.length];
}

/// §18 — CONTINUE LEARNING from real persisted study data.
class StudyContinueLearningCard extends StatelessWidget {
  const StudyContinueLearningCard({
    super.key,
    required this.continueLearning,
    required this.onContinue,
    required this.onPlan,
  });

  final ContinueLearningView continueLearning;
  final VoidCallback onContinue;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: palette.sage.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTINUE LEARNING',
            style: context.text.labelSmall!.copyWith(
              color: palette.mutedGreen,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            continueLearning.subjectName,
            style: context.text.titleSmall!.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (continueLearning.topicTitle != null)
            Text(
              continueLearning.topicTitle!,
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Last studied: ${continueLearning.lastStudiedLabel}',
            style: context.text.labelSmall!.copyWith(
              color: palette.onSurfaceMuted,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onPrimary,
                    minimumSize: const Size(0, 40),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 17),
                  label: const Text('Continue'),
                  onPressed: onContinue,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: palette.forest,
                    side: BorderSide(color: palette.sage),
                  ),
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: const Text('Plan'),
                  onPressed: onPlan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// §19 — ONE strong study recommendation with a plain-language reason.
class StudyRecommendationCard extends StatelessWidget {
  const StudyRecommendationCard({
    super.key,
    required this.recommended,
    required this.onStudy,
    required this.onPlan,
  });

  final StudyTopicView recommended;
  final VoidCallback onStudy;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final topic = recommended.topic;

    // Light canonical treatment, mirroring StudyContinueLearningCard:
    // emphasis via eyebrow + primary CTA, never a dark fill.
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: palette.sage.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECOMMENDED',
            style: context.text.labelSmall!.copyWith(
              color: palette.mutedGreen,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            topic.title,
            style: context.text.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (recommended.chapterTitle != null) ...[
            const SizedBox(height: 2),
            Text(
              recommended.chapterTitle!,
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            recommended.reason,
            style: context.text.labelSmall!.copyWith(
              color: palette.onSurfaceMuted,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${recommended.status.label} · ${topic.estimatedMinutes} min',
            style: context.text.labelSmall!.copyWith(
              color: palette.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onPrimary,
                    minimumSize: const Size(0, 40),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 17),
                  label: Text(recommended.actionLabel),
                  onPressed: onStudy,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: palette.forest,
                    side: BorderSide(color: palette.sage),
                  ),
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: const Text('Plan It'),
                  onPressed: onPlan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// §14 — Compact subject row with progress, study time, revision and exam.
class StudySubjectRow extends StatelessWidget {
  const StudySubjectRow({
    super.key,
    required this.view,
    required this.onOpen,
    required this.onStudy,
  });

  final StudySubjectView view;
  final VoidCallback onOpen;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subject = view.subject;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.displayName,
                      style: context.text.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      view.hasSyllabus
                          ? '${view.syllabusPercentage}% syllabus · '
                              '${formatPlanMinutes(view.totalStudyMinutes)} studied'
                          : 'No syllabus yet',
                      style: context.text.labelSmall!.copyWith(
                        color: palette.onSurfaceMuted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (view.daysUntilNextExam != null)
                _StudyMetaChip(
                  label: '${view.daysUntilNextExam}d',
                  color: view.daysUntilNextExam! <= 7
                      ? palette.error
                      : palette.warning,
                ),
              if (view.needsRevisionTopics > 0) ...[
                const SizedBox(width: 4),
                _StudyMetaChip(
                  label: '${view.needsRevisionTopics} rev',
                  color: palette.warning,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: view.hasSyllabus ? view.syllabusPercentage / 100 : 0,
              minHeight: 4,
              backgroundColor: palette.paleSage.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(palette.forest),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  view.recommendedTopicTitle == null
                      ? view.health.label
                      : 'Next: ${view.recommendedTopicTitle}',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.mutedGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: palette.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.bolt_rounded, size: 14),
                label: const Text('Focus'),
                onPressed: onStudy,
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: palette.forest,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.chevron_right_rounded, size: 16),
                label: const Text('Open'),
                onPressed: onOpen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyMetaChip extends StatelessWidget {
  const _StudyMetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: context.text.labelSmall!.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }
}

/// §16/§24 — Topic state chip driven by the engine's [TopicStatus].
class StudyTopicStatusChip extends StatelessWidget {
  const StudyTopicStatusChip({
    super.key,
    required this.status,
    this.dense = false,
  });

  final TopicStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final color = switch (status) {
      TopicStatus.notStarted => palette.onSurfaceMuted,
      TopicStatus.inProgress => palette.accent,
      TopicStatus.studied => palette.sage,
      TopicStatus.needsRevision => palette.warning,
      TopicStatus.mastered => palette.softSage,
    };
    final foreground =
        status == TopicStatus.mastered ? palette.deepForest : color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 5 : 7,
        vertical: dense ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: context.text.labelSmall!.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: dense ? 8 : 9,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// §13 — A single topic surfaced from weak/revision/practice signals.
class StudyTopicRow extends StatelessWidget {
  const StudyTopicRow({
    super.key,
    required this.view,
    required this.onOpen,
    required this.onPlan,
  });

  final StudyTopicView view;
  final VoidCallback onOpen;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.title,
                  style: context.text.bodySmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    StudyTopicStatusChip(status: view.status, dense: true),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        view.chapterTitle ?? view.reason,
                        style: context.text.labelSmall!.copyWith(
                          color: palette.onSurfaceMuted,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Study ${view.title}',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(Icons.play_circle_outline_rounded,
                size: 20, color: palette.accent),
            onPressed: onOpen,
          ),
          IconButton(
            tooltip: 'Plan ${view.title}',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(Icons.event_rounded, size: 18, color: palette.forest),
            onPressed: onPlan,
          ),
        ],
      ),
    );
  }
}

/// §30 — Empty state that always offers a useful next action.
class PlanStudyEmptyState extends StatelessWidget {
  const PlanStudyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: palette.mutedGreen),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            message,
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onPrimary,
                    minimumSize: const Size(0, 40),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(actionLabel, overflow: TextOverflow.ellipsis),
                  onPressed: onAction,
                ),
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      foregroundColor: palette.forest,
                      side: BorderSide(color: palette.sage),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      secondaryLabel!,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: onSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// `3h 20m` / `45m` — matches how the plan header and rows speak.
String formatPlanMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}
