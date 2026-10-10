import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../progress_controller.dart';

/// Section F — premium progress milestones derived purely from real activity.
///
/// Milestones are recomputed from existing history (no extra persistence) and
/// always reflect the true earned state. Presented as refined progress markers,
/// not a game badge wall.
class MilestonesSection extends StatelessWidget {
  const MilestonesSection({super.key, required this.milestones});

  final List<ProgressMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    final earned = milestones.where((m) => m.earned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Milestones',
          icon: Icons.military_tech_outlined,
          subtitle: '$earned of ${milestones.length} earned so far',
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: [
              for (final m in milestones) ...[
                _MilestoneRow(milestone: m),
                if (m != milestones.last) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Divider(
                    height: 1,
                    color: AppTheme.colorsOf(context).outline
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone});

  final ProgressMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final earned = milestone.earned;
    final fill = earned ? palette.streak : palette.onSurfaceMuted;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 300);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned
                  ? fill.withValues(alpha: 0.15)
                  : palette.surfaceVariant,
              border: Border.all(
                color: earned ? fill.withValues(alpha: 0.5) : palette.outline,
                width: 1.5,
              ),
            ),
            child: Icon(
              milestone.icon,
              size: 18,
              color: earned
                  ? fill
                  : palette.onSurfaceMuted.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: context.text.bodyMedium!.copyWith(
                    color: earned ? palette.onSurface : palette.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  milestone.detail,
                  style: context.text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (earned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: fill.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Earned',
                style: context.text.labelSmall!.copyWith(color: fill),
              ),
            ),
        ],
      ),
    );
  }
}
