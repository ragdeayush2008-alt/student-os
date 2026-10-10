import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/reward.dart';
import '../redemption_controller.dart';
import '../reward_catalog.dart';
import 'reward_detail_sheet.dart';

/// My Collection & Inventory screen showing all unlocked rewards and active equipment.
class MyCollectionScreen extends StatefulWidget {
  const MyCollectionScreen({super.key});

  @override
  State<MyCollectionScreen> createState() => _MyCollectionScreenState();
}

class _MyCollectionScreenState extends State<MyCollectionScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final redemption = RedemptionController.instance;

    return AppScaffold(
      title: 'My Collection',
      body: ListenableBuilder(
        listenable: redemption,
        builder: (context, _) {
          final inventory = redemption.inventory;
          final collections = RewardCatalog.instance.collections;
          final ownedIds = redemption.ownedRewardIds;

          List<Reward> filtered = inventory;
          if (_selectedFilter == 'themes') {
            filtered = inventory.where((r) => r.type == 'theme').toList();
          } else if (_selectedFilter == 'badges') {
            filtered = inventory.where((r) => r.type == 'badge').toList();
          } else if (_selectedFilter == 'frames') {
            filtered = inventory.where((r) => r.type == 'frame').toList();
          } else if (_selectedFilter == 'focus') {
            filtered = inventory
                .where((r) => r.type == 'focusStyle' || r.type == 'preset')
                .toList();
          } else if (_selectedFilter == 'utilities') {
            filtered = inventory
                .where((r) =>
                    r.type == 'feature' ||
                    r.type == 'academic' ||
                    r.type == 'discount')
                .toList();
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ── Collection Progress Cards ──
              Text(
                'Collection Progress',
                style: context.text.titleSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: collections.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final col = collections[i];
                    final unlocked = col.unlockedCount(ownedIds);
                    final isComplete = col.isComplete(ownedIds);

                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      color: isComplete
                          ? palette.primary.withValues(alpha: 0.1)
                          : palette.surface,
                      child: SizedBox(
                        width: 170,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  isComplete
                                      ? Icons.emoji_events_rounded
                                      : Icons.auto_awesome_rounded,
                                  color: isComplete
                                      ? palette.streak
                                      : palette.primary,
                                  size: 20,
                                ),
                                Text(
                                  '$unlocked / ${col.totalItems}',
                                  style: context.text.labelSmall!.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              col.title,
                              style: context.text.bodySmall!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: col.progress(ownedIds),
                                minHeight: 4,
                                backgroundColor: palette.outline,
                                valueColor: AlwaysStoppedAnimation(
                                  isComplete
                                      ? palette.streak
                                      : palette.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Filter Chips ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All (${inventory.length})', palette),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      'themes',
                      'Themes (${inventory.where((r) => r.type == 'theme').length})',
                      palette,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      'badges',
                      'Badges (${inventory.where((r) => r.type == 'badge').length})',
                      palette,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      'frames',
                      'Frames (${inventory.where((r) => r.type == 'frame').length})',
                      palette,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      'focus',
                      'Focus Styles',
                      palette,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip(
                      'utilities',
                      'Academic & Utilities',
                      palette,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Unlocked Items List ──
              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: palette.onSurfaceMuted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No rewards unlocked in this category yet',
                          style: context.text.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete study sessions & earn XP to unlock items in the marketplace.',
                          style: context.text.bodySmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, i) {
                    final reward = filtered[i];
                    final isEquipped = redemption.isEquipped(reward.id);

                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => RewardDetailSheet(reward: reward),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getRewardIcon(reward.type),
                              color: palette.primary,
                              size: 22,
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
                                        style:
                                            context.text.titleSmall!.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: reward.rarity.color
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        reward.rarity.label,
                                        style:
                                            context.text.labelSmall!.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: reward.rarity.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reward.description,
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
                          const SizedBox(width: AppSpacing.sm),
                          if (reward.isEquippable)
                            TextButton(
                              onPressed: () async {
                                if (isEquipped) {
                                  await redemption
                                      .unequipSlot(reward.equipmentSlot);
                                } else {
                                  await redemption.equipReward(reward);
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: isEquipped
                                    ? palette.streak
                                        .withValues(alpha: 0.15)
                                    : palette.primary.withValues(alpha: 0.1),
                                foregroundColor: isEquipped
                                    ? palette.streak
                                    : palette.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                isEquipped ? 'Equipped' : 'Equip',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterId, String label, AppPalette palette) {
    final isSelected = _selectedFilter == filterId;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: palette.primary,
      labelStyle: TextStyle(
        color: isSelected ? palette.onPrimary : palette.onSurface,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedFilter = filterId),
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
