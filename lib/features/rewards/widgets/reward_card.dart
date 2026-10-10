import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../data/models/reward.dart';
import '../../progression/progression_controller.dart';
import '../redemption_controller.dart';

/// State of a reward relative to the current student in Marketplace 2.0.
enum RewardDisplayState {
  equipped('Equipped'),
  owned('Owned'),
  available('Available'),
  needXp('Need XP'),
  levelLocked('Level Locked'),
  streakLocked('Streak Required'),
  comingSoon('Coming Soon');

  const RewardDisplayState(this.label);
  final String label;
}

/// Visual card displaying a single reward in the marketplace.
class RewardCard extends StatelessWidget {
  const RewardCard({super.key, required this.reward, required this.onTap});

  final Reward reward;
  final VoidCallback onTap;

  RewardDisplayState _calculateState(
    BuildContext context,
    ProgressionController progression,
    RedemptionController redemption,
  ) {
    if (reward.availability == RewardAvailability.comingSoon) {
      return RewardDisplayState.comingSoon;
    }

    if (reward.isOneTime && redemption.ownsReward(reward.id)) {
      if (redemption.isEquipped(reward.id)) {
        return RewardDisplayState.equipped;
      }
      return RewardDisplayState.owned;
    }

    final level = progression.currentLevel.level;
    if (level < reward.minimumLevel) {
      return RewardDisplayState.levelLocked;
    }

    if (reward.requiredStreak != null && reward.requiredStreak! > 0) {
      if (StreakService.instance.currentStreak < reward.requiredStreak!) {
        return RewardDisplayState.streakLocked;
      }
    }

    final spendableXp = progression.spendableXp;
    if (spendableXp < reward.xpCost) {
      return RewardDisplayState.needXp;
    }

    return RewardDisplayState.available;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final progression = ProgressionController.instance;
    final redemption = RedemptionController.instance;
    final state = _calculateState(context, progression, redemption);
    final isFavorite = redemption.isFavorite(reward.id);

    return AppPressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Rarity + Favorite Button
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(state, palette),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    _getRewardIcon(reward.type),
                    color: _getIconColor(state, palette),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: reward.rarity.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reward.rarity.label,
                      style: context.text.labelSmall!.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: reward.rarity.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => redemption.toggleFavorite(reward.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? palette.streak
                          : palette.onSurfaceMuted.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // State Badge
            _StateBadge(state: state, reward: reward),
            const SizedBox(height: 4),

            // Title
            Text(
              reward.title,
              style: context.text.titleSmall!.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Description
            Expanded(
              child: Text(
                reward.description,
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  height: 1.2,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),

            // Cost & Requirement Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: palette.streak),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${reward.xpCost} XP',
                          style: context.text.labelSmall!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.streak,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (reward.minimumLevel > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Lvl ${reward.minimumLevel}+',
                      style: context.text.labelSmall!.copyWith(
                        color: palette.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  )
                else if (reward.requiredStreak != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '${reward.requiredStreak}d streak',
                      style: context.text.labelSmall!.copyWith(
                        color: palette.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    return switch (type) {
      'theme' => Icons.palette_outlined,
      'badge' => Icons.workspace_premium_outlined,
      'frame' => Icons.crop_square_rounded,
      'focusStyle' => Icons.hourglass_empty_rounded,
      'preset' => Icons.bolt_rounded,
      'feature' || 'academic' => Icons.auto_awesome_outlined,
      'discount' => Icons.local_offer_outlined,
      _ => Icons.stars_rounded,
    };
  }

  Color _getIconBackgroundColor(RewardDisplayState state, AppPalette palette) {
    return switch (state) {
      RewardDisplayState.equipped =>
        palette.streak.withValues(alpha: 0.15),
      RewardDisplayState.owned => palette.success.withValues(alpha: 0.15),
      RewardDisplayState.available => palette.primary.withValues(alpha: 0.15),
      RewardDisplayState.needXp => palette.surfaceVariant,
      RewardDisplayState.levelLocked => palette.surfaceVariant,
      RewardDisplayState.streakLocked => palette.surfaceVariant,
      RewardDisplayState.comingSoon => palette.surfaceVariant,
    };
  }

  Color _getIconColor(RewardDisplayState state, AppPalette palette) {
    return switch (state) {
      RewardDisplayState.equipped => palette.streak,
      RewardDisplayState.owned => palette.success,
      RewardDisplayState.available => palette.primary,
      RewardDisplayState.needXp => palette.onSurfaceMuted,
      RewardDisplayState.levelLocked => palette.onSurfaceMuted,
      RewardDisplayState.streakLocked => palette.onSurfaceMuted,
      RewardDisplayState.comingSoon => palette.onSurfaceMuted,
    };
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state, required this.reward});

  final RewardDisplayState state;
  final Reward reward;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    final (color, bgColor) = switch (state) {
      RewardDisplayState.equipped => (
        palette.streak,
        palette.streak.withValues(alpha: 0.15),
      ),
      RewardDisplayState.owned => (
        palette.success,
        palette.success.withValues(alpha: 0.15),
      ),
      RewardDisplayState.available => (
        palette.primary,
        palette.primary.withValues(alpha: 0.15),
      ),
      RewardDisplayState.needXp => (
        palette.onSurfaceMuted,
        palette.surfaceVariant,
      ),
      RewardDisplayState.levelLocked => (
        palette.onSurfaceMuted,
        palette.surfaceVariant,
      ),
      RewardDisplayState.streakLocked => (
        palette.onSurfaceMuted,
        palette.surfaceVariant,
      ),
      RewardDisplayState.comingSoon => (
        palette.info,
        palette.info.withValues(alpha: 0.15),
      ),
    };

    String text = state.label;
    if (state == RewardDisplayState.levelLocked) {
      text = 'Req Lvl ${reward.minimumLevel}';
    } else if (state == RewardDisplayState.streakLocked &&
        reward.requiredStreak != null) {
      text = 'Req ${reward.requiredStreak}d Streak';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: context.text.labelSmall!.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
          fontSize: 9,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
