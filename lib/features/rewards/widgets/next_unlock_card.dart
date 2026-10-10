import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../data/models/reward.dart';
import '../../progression/progression_controller.dart';
import '../reward_catalog.dart';

/// Card showing the next closest reward the student is progressing toward unlocking.
class NextUnlockCard extends StatelessWidget {
  const NextUnlockCard({super.key, required this.onTap});

  final ValueChanged<Reward> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final progression = ProgressionController.instance;
    final level = progression.currentLevel.level;
    final spendableXp = progression.spendableXp;

    final nextReward = RewardCatalog.instance.nextUnlockableReward(
      level,
      spendableXp,
    );

    if (nextReward == null) {
      return const SizedBox.shrink();
    }

    final xpGap = (nextReward.xpCost - spendableXp).clamp(0, 999999);
    final levelGap = (nextReward.minimumLevel - level).clamp(0, 999);
    final isLevelLocked = levelGap > 0;

    return AppPressable(
      onTap: () => onTap(nextReward),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: palette.surfaceVariant.withValues(alpha: 0.5),
        borderColor: palette.streak.withValues(alpha: 0.3),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.streak.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                _getRewardIcon(nextReward.type),
                color: palette.streak,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NEXT GOAL',
                        style: context.text.labelSmall!.copyWith(
                          color: palette.streak,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isLevelLocked
                              ? 'Need Lvl ${nextReward.minimumLevel}'
                              : '$xpGap XP away',
                          style: context.text.labelSmall!.copyWith(
                            color: palette.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextReward.title,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: isLevelLocked
                          ? (level / nextReward.minimumLevel).clamp(0.0, 1.0)
                          : (spendableXp / nextReward.xpCost).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: palette.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(palette.streak),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    return switch (type) {
      'theme' => Icons.palette_outlined,
      'badge' => Icons.military_tech_outlined,
      'feature' => Icons.auto_awesome_outlined,
      'discount' => Icons.local_offer_outlined,
      _ => Icons.stars_rounded,
    };
  }
}
