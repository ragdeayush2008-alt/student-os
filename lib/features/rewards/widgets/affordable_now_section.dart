import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../data/models/reward.dart';
import '../recommendation_engine.dart';
import 'reward_card.dart';

/// Section in Rewards Marketplace showcasing rewards that can be redeemed right now.
class AffordableNowSection extends StatelessWidget {
  const AffordableNowSection({super.key, required this.onRewardTap});

  final ValueChanged<Reward> onRewardTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final affordable = RecommendationEngine.getAffordableRewards();

    if (affordable.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Affordable Now',
          icon: Icons.check_circle_outline_rounded,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: palette.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '${affordable.length} ready',
              style: context.text.labelSmall!.copyWith(
                color: palette.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: affordable.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final reward = affordable[index];
              return SizedBox(
                width: 170,
                child: RewardCard(
                  reward: reward,
                  onTap: () => onRewardTap(reward),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
