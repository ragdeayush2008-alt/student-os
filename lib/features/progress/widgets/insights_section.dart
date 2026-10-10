import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../progress_controller.dart';

/// Section E — deterministic, data-backed productivity insights.
///
/// Every insight is computed from real persisted activity; none are AI-generated
/// or fabricated. When history is insufficient, a helpful message explains that
/// insights will improve as activity grows.
class InsightsSection extends StatelessWidget {
  const InsightsSection({
    super.key,
    required this.snapshot,
    required this.insights,
  });

  final ProgressSnapshot snapshot;
  final List<ProgressInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Insights',
            icon: Icons.psychology_outlined,
            subtitle: 'Real signals from your data',
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 30,
                    color: AppTheme.colorsOf(context).onSurfaceMuted
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Insights are taking shape',
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Text(
                      snapshot.hasAnyActivity
                          ? 'As you add more activity, focused insights about your strongest days and trends will appear here.'
                          : 'After you complete a task or study session, you\'ll get clear insights about your progress.',
                      style: context.text.bodySmall!.copyWith(
                        color: AppTheme.colorsOf(context).onSurfaceMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Insights',
          icon: Icons.psychology_outlined,
          subtitle: 'Real signals from your data',
        ),
        const SizedBox(height: AppSpacing.md),
        for (final insight in insights) ...[
          _InsightCard(insight: insight),
          if (insight != insights.last) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final ProgressInsight insight;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final fill = insight.tint ?? palette.primary;

    return AppCard(
      onTap: insight.onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: fill.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(insight.icon, size: 19, color: fill),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: context.text.labelLarge!.copyWith(color: fill),
                ),
                const SizedBox(height: 1),
                Text(insight.detail, style: context.text.bodySmall),
              ],
            ),
          ),
          if (insight.onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.onSurfaceMuted,
            ),
        ],
      ),
    );
  }
}
