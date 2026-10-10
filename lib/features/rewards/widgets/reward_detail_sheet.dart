import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reward.dart';
import '../../progression/progression_controller.dart';
import '../redemption_controller.dart';
import '../reward_catalog.dart';
import 'redemption_confirmation_dialog.dart';
import 'reward_unlocked_dialog.dart';

/// Modal bottom sheet displaying complete details for a reward and redemption actions.
class RewardDetailSheet extends StatefulWidget {
  const RewardDetailSheet({super.key, required this.reward});

  final Reward reward;

  @override
  State<RewardDetailSheet> createState() => _RewardDetailSheetState();
}

class _RewardDetailSheetState extends State<RewardDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final progression = ProgressionController.instance;
    final redemption = RedemptionController.instance;
    final reward = widget.reward;

    final isOwned = reward.isOneTime && redemption.ownsReward(reward.id);
    final isEquipped = redemption.isEquipped(reward.id);
    final isComingSoon = reward.availability == RewardAvailability.comingSoon;
    final isFavorite = redemption.isFavorite(reward.id);

    final level = progression.currentLevel.level;
    final hasLevel = level >= reward.minimumLevel;
    final spendableXp = progression.spendableXp;
    final hasXp = spendableXp >= reward.xpCost;

    final currentStreak = StreakService.instance.currentStreak;
    final hasStreak = reward.requiredStreak == null ||
        currentStreak >= reward.requiredStreak!;

    final canRedeem =
        !isOwned && !isComingSoon && hasLevel && hasXp && hasStreak;

    final collection = reward.collectionId != null
        ? RewardCatalog.instance.findCollectionById(reward.collectionId!)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header with icon, title, rarity, and favorite button
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: reward.rarity.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(
                      _getRewardIcon(reward.type),
                      color: reward.rarity.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reward.title,
                                style: context.text.titleLarge!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite
                                    ? palette.streak
                                    : palette.onSurfaceMuted,
                              ),
                              onPressed: () {
                                redemption.toggleFavorite(reward.id);
                                setState(() {});
                              },
                              tooltip: 'Favorite',
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    reward.rarity.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reward.rarity.label,
                                style: context.text.labelSmall!.copyWith(
                                  color: reward.rarity.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              reward.category.label,
                              style: context.text.bodySmall!.copyWith(
                                color: palette.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Description
              Text(
                reward.description,
                style: context.text.bodyMedium!.copyWith(height: 1.4),
              ),

              if (reward.whyThisText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reward.whyThisText!,
                          style: context.text.bodySmall!.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Requirements & Status Grid
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    _DetailRequirementRow(
                      label: 'XP Cost',
                      value: '${reward.xpCost} XP',
                      isMet: hasXp,
                      metText: hasXp
                          ? 'Available'
                          : 'Need ${reward.xpCost - spendableXp} more XP',
                    ),
                    const Divider(height: AppSpacing.md),
                    _DetailRequirementRow(
                      label: 'Required Level',
                      value: 'Level ${reward.minimumLevel}',
                      isMet: hasLevel,
                      metText: hasLevel ? 'Reached' : 'Current: Level $level',
                    ),
                    if (reward.requiredStreak != null) ...[
                      const Divider(height: AppSpacing.md),
                      _DetailRequirementRow(
                        label: 'Required Streak',
                        value: '${reward.requiredStreak} Days',
                        isMet: hasStreak,
                        metText: hasStreak
                            ? 'Streak Met'
                            : 'Current: $currentStreak Days',
                      ),
                    ],
                    if (collection != null) ...[
                      const Divider(height: AppSpacing.md),
                      _DetailRequirementRow(
                        label: 'Collection',
                        value: collection.title,
                        isMet: true,
                        metText:
                            '${collection.unlockedCount(redemption.ownedRewardIds)} / ${collection.totalItems}',
                      ),
                    ],
                    if (isOwned) ...[
                      const Divider(height: AppSpacing.md),
                      _DetailRequirementRow(
                        label: 'Status',
                        value: 'Owned in Inventory',
                        isMet: true,
                        metText: isEquipped ? 'Equipped' : 'Ready to Equip',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action buttons: Equip / Unequip vs Redeem
              if (isOwned && reward.isEquippable) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          isEquipped
                              ? Icons.close_rounded
                              : Icons.check_circle_rounded,
                        ),
                        onPressed: () async {
                          if (isEquipped) {
                            await redemption.unequipSlot(reward.equipmentSlot);
                          } else {
                            await redemption.equipReward(reward);
                          }
                          setState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        label: Text(isEquipped ? 'Unequip' : 'Equip'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: palette.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: isOwned
                      ? OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.check_circle,
                            color: palette.success,
                          ),
                          label: const Text('Already Owned'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        )
                      : isComingSoon
                          ? OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              child: const Text('Coming Soon in Future Update'),
                            )
                          : ElevatedButton(
                              onPressed: canRedeem
                                  ? () => _startRedemption(context)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: palette.primary,
                                foregroundColor: palette.onPrimary,
                                disabledBackgroundColor:
                                    palette.primary.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                !hasLevel
                                    ? 'Requires Level ${reward.minimumLevel}'
                                    : !hasStreak
                                        ? 'Requires ${reward.requiredStreak}d Streak'
                                        : !hasXp
                                            ? 'Need ${reward.xpCost - spendableXp} More XP'
                                            : 'Redeem for ${reward.xpCost} XP',
                                style: context.text.titleSmall!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: canRedeem
                                      ? Colors.white
                                      : palette.onSurfaceMuted,
                                ),
                              ),
                            ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _startRedemption(BuildContext context) {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = AppTheme.colorsOf(context).error;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => RedemptionConfirmationDialog(
        reward: widget.reward,
        onConfirm: () async {
          final result = await RedemptionController.instance.redeemReward(
            widget.reward.id,
          );
          if (!mounted) return;
          navigator.pop(); // Close detail sheet
          if (result.success && result.transaction != null) {
            showRewardUnlockedDialog(
              context,
              reward: widget.reward,
              transaction: result.transaction!,
            );
          } else if (result.errorMessage != null) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(result.errorMessage!),
                backgroundColor: errorColor,
              ),
            );
          }
        },
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
      'feature' || 'academic' => Icons.auto_awesome_rounded,
      'discount' => Icons.local_offer_outlined,
      _ => Icons.stars_rounded,
    };
  }
}

class _DetailRequirementRow extends StatelessWidget {
  const _DetailRequirementRow({
    required this.label,
    required this.value,
    required this.isMet,
    required this.metText,
  });

  final String label;
  final String value;
  final bool isMet;
  final String metText;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: context.text.titleSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isMet ? palette.success : palette.error).withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            metText,
            style: context.text.labelSmall!.copyWith(
              color: isMet ? palette.success : palette.error,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
