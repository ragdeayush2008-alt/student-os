import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/reward.dart';
import '../progression/progression_controller.dart';
import 'recommendation_engine.dart';
import 'redemption_controller.dart';
import 'reward_catalog.dart';
import 'widgets/my_collection_sheet.dart';
import 'widgets/next_unlock_card.dart';
import 'widgets/reward_card.dart';
import 'widgets/reward_detail_sheet.dart';
import 'widgets/reward_history_screen.dart';
import 'widgets/rewards_summary_card.dart';

/// Full Rewards Marketplace 2.0 Screen for Student OS.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  RewardCategory? _selectedCategory;
  bool _showForYou = false;
  String _activeFilter = 'all'; // 'all', 'affordable', 'owned', 'locked', 'favorites'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openRewardDetail(BuildContext context, Reward reward) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RewardDetailSheet(reward: reward),
    );
  }

  void _openCollectionScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MyCollectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppScaffold(
      title: 'Rewards Marketplace',
      actions: [
        IconButton(
          icon: const Icon(Icons.inventory_2_outlined),
          tooltip: 'My Collection',
          onPressed: () => _openCollectionScreen(context),
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded),
          tooltip: 'Reward History',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RewardHistoryScreen(),
              ),
            );
          },
        ),
      ],
      body: ListenableBuilder(
        listenable: Listenable.merge([
          ProgressionController.instance,
          RedemptionController.instance,
        ]),
        builder: (context, _) {
          final catalog = RewardCatalog.instance;
          final progression = ProgressionController.instance;
          final redemption = RedemptionController.instance;
          final spendableXp = progression.spendableXp;
          final level = progression.currentLevel.level;

          List<Reward> pool;
          if (_searchQuery.isNotEmpty) {
            pool = catalog.search(_searchQuery);
          } else if (_showForYou) {
            final recs = RecommendationEngine.getRecommendations(
              maxRecommendations: 12,
            );
            pool = recs.map((r) => r.reward).toList();
          } else if (_selectedCategory != null) {
            pool = catalog.rewardsInCategory(_selectedCategory!);
          } else {
            pool = catalog.allRewards;
          }

          // Apply secondary filter
          List<Reward> displayedRewards = pool.where((r) {
            if (_activeFilter == 'affordable') {
              return r.minimumLevel <= level && r.xpCost <= spendableXp;
            } else if (_activeFilter == 'owned') {
              return redemption.ownsReward(r.id);
            } else if (_activeFilter == 'locked') {
              return !redemption.ownsReward(r.id) &&
                  (r.minimumLevel > level || r.xpCost > spendableXp);
            } else if (_activeFilter == 'favorites') {
              return redemption.isFavorite(r.id);
            }
            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              // ── 1. Summary Card at Top ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: RewardsSummaryCard(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // ── 2. Next Unlock Progression Preview ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: NextUnlockCard(
                    onTap: (reward) => _openRewardDetail(context, reward),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // ── 3. My Collection Shortcut Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onTap: () => _openCollectionScreen(context),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: palette.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.inventory_2_rounded, color: palette.primary, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Collection & Equipment',
                                style: context.text.titleSmall!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${redemption.inventory.length} items unlocked · Tap to equip themes & badges',
                                style: context.text.bodySmall!.copyWith(
                                  color: palette.onSurfaceMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: palette.onSurfaceMuted),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // ── 4. Search Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.outline),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 20, color: palette.onSurfaceMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: const InputDecoration(
                              hintText: 'Search rewards, themes, badges, tools...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: context.text.bodyMedium,
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

              // ── 5. Primary Category Tabs ──
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      _buildTabChip(
                        label: 'All',
                        isSelected: !_showForYou && _selectedCategory == null,
                        onSelected: () => setState(() {
                          _showForYou = false;
                          _selectedCategory = null;
                        }),
                        palette: palette,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildTabChip(
                        label: '✨ For You',
                        isSelected: _showForYou,
                        onSelected: () => setState(() {
                          _showForYou = true;
                          _selectedCategory = null;
                        }),
                        palette: palette,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildTabChip(
                        label: '🔥 Featured',
                        isSelected: !_showForYou && _selectedCategory == RewardCategory.featured,
                        onSelected: () => setState(() {
                          _showForYou = false;
                          _selectedCategory = RewardCategory.featured;
                        }),
                        palette: palette,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildTabChip(
                        label: '🎨 Cosmetics',
                        isSelected: !_showForYou && _selectedCategory == RewardCategory.cosmetic,
                        onSelected: () => setState(() {
                          _showForYou = false;
                          _selectedCategory = RewardCategory.cosmetic;
                        }),
                        palette: palette,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildTabChip(
                        label: '📚 Academic',
                        isSelected: !_showForYou && _selectedCategory == RewardCategory.academic,
                        onSelected: () => setState(() {
                          _showForYou = false;
                          _selectedCategory = RewardCategory.academic;
                        }),
                        palette: palette,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildTabChip(
                        label: '⚡ Focus & Tools',
                        isSelected: !_showForYou && _selectedCategory == RewardCategory.focus,
                        onSelected: () => setState(() {
                          _showForYou = false;
                          _selectedCategory = RewardCategory.focus;
                        }),
                        palette: palette,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildTabChip(
                        label: '💎 Premium',
                        isSelected: !_showForYou && _selectedCategory == RewardCategory.premium,
                        onSelected: () => setState(() {
                          _showForYou = false;
                          _selectedCategory = RewardCategory.premium;
                        }),
                        palette: palette,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),

              // ── 6. Secondary Filter Chips (Affordable, Owned, Locked, Favorites) ──
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      _buildSecondaryChip('all', 'All Items', palette),
                      const SizedBox(width: AppSpacing.xs),
                      _buildSecondaryChip('affordable', '🟢 Affordable Now', palette),
                      const SizedBox(width: AppSpacing.xs),
                      _buildSecondaryChip('owned', '✓ Owned (${redemption.ownedRewardIds.length})', palette),
                      const SizedBox(width: AppSpacing.xs),
                      _buildSecondaryChip('favorites', '❤️ Favorites (${redemption.favoriteIds.length})', palette),
                      const SizedBox(width: AppSpacing.xs),
                      _buildSecondaryChip('locked', '🔒 Locked', palette),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // ── 7. Themed Collections Section (on Home tab) ──
              if (!_showForYou && _selectedCategory == null && _searchQuery.isEmpty && _activeFilter == 'all') ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'Themed Collections',
                      style: context.text.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: catalog.collections.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final col = catalog.collections[i];
                        final unlocked = col.unlockedCount(redemption.ownedRewardIds);
                        return AppCard(
                          padding: const EdgeInsets.all(12),
                          onTap: () => _openCollectionScreen(context),
                          child: SizedBox(
                            width: 160,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, color: palette.primary, size: 18),
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
                                  style: context.text.bodySmall!.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: col.progress(redemption.ownedRewardIds),
                                    minHeight: 3,
                                    backgroundColor: palette.outline,
                                    valueColor: AlwaysStoppedAnimation(palette.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              ],

              // ── 8. Rewards Grid ──
              if (displayedRewards.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: palette.onSurfaceMuted),
                          const SizedBox(height: AppSpacing.md),
                          Text('No rewards found', style: context.text.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No rewards match "$_searchQuery".'
                                : 'Try changing your active category or filter.',
                            style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final reward = displayedRewards[index];
                        return RewardCard(
                          reward: reward,
                          onTap: () => _openRewardDetail(context, reward),
                        );
                      },
                      childCount: displayedRewards.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required AppPalette palette,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: palette.primary,
      labelStyle: TextStyle(
        color: isSelected ? palette.onPrimary : palette.onSurface,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildSecondaryChip(String filterId, String label, AppPalette palette) {
    final isSelected = _activeFilter == filterId;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: palette.surface,
      selectedColor: palette.primary.withValues(alpha: 0.12),
      checkmarkColor: palette.primary,
      labelStyle: TextStyle(
        color: isSelected ? palette.primary : palette.onSurfaceMuted,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 11,
      ),
      side: BorderSide(
        color: isSelected ? palette.primary : palette.outline,
      ),
      onSelected: (_) => setState(() => _activeFilter = filterId),
    );
  }
}
