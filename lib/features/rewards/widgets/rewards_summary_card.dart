import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../progression/progression_controller.dart';
import '../redemption_controller.dart';

/// Summary card shown at the top of the Rewards Marketplace.
///
/// Displays:
/// - Current level & title
/// - Spendable XP balance
/// - Lifetime XP (for auditability)
/// - Owned rewards count
class RewardsSummaryCard extends StatelessWidget {
  const RewardsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final progression = ProgressionController.instance;
    final redemption = RedemptionController.instance;
    final level = progression.currentLevel;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              // Level circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.streak.withValues(alpha: 0.15),
                  border: Border.all(color: palette.streak, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${level.level}',
                    style: context.text.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.streak,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level ${level.level}',
                      style: context.text.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${level.xpToNextLevel} XP to Level ${level.level + 1}',
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Spendable XP badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.streak.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: palette.streak.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: palette.streak),
                    const SizedBox(width: 3),
                    Text(
                      '${progression.spendableXp} XP',
                      style: context.text.labelSmall!.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.streak,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: level.progressInLevel,
              minHeight: 6,
              backgroundColor: palette.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(palette.streak),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: palette.outline.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Lifetime XP',
                  value: '${progression.totalXp}',
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: palette.outline.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'XP Spent',
                  value: '${progression.spentXp}',
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: palette.outline.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Unlocked',
                  value: '${redemption.activeEntitlements.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: context.text.bodySmall!.copyWith(
            color: palette.onSurfaceMuted,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
