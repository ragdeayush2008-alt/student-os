import 'package:flutter/material.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/achievement.dart';
import 'achievement_controller.dart';
import 'widgets/achievement_detail_sheet.dart';

/// Full-featured Achievements & Badges screen for Student OS.
///
/// Features:
/// - Category filtering (Academic, Focus, Consistency, Progression, Goals, Exploration)
/// - Live progress calculation for every achievement
/// - Detailed bottom sheet inspection on tap
/// - Strict Black/White/Grey monochromatic theme (Zero purple)
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementController _controller = AchievementController.instance;
  AchievementCategory _selectedCategory = AchievementCategory.all;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.evaluate();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _openDetail(AchievementEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AchievementDetailSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final filteredEntries = _controller.entriesForCategory(_selectedCategory);
    final earnedCount = _controller.earnedCount;
    final totalCount = _controller.totalCount;
    final completionRatio = _controller.completionRatio;
    final recentlyUnlocked = _controller.recentlyUnlocked;

    return AppScaffold(
      title: 'Achievements',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Personal Progress Summary Hero ──────────────────────────
            _SummaryHeroCard(
              earnedCount: earnedCount,
              totalCount: totalCount,
              completionRatio: completionRatio,
              recentlyUnlocked: recentlyUnlocked,
              palette: palette,
              onTapRecent: _openDetail,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Category Filter Bar ─────────────────────────────────────
            _CategoryFilterBar(
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
              palette: palette,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Achievement Cards List ──────────────────────────────────
            if (filteredEntries.isEmpty)
              _EmptyCategoryState(palette: palette)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredEntries.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final entry = filteredEntries[index];
                  return _AchievementCard(
                    entry: entry,
                    palette: palette,
                    onTap: () => _openDetail(entry),
                  );
                },
              ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SUMMARY HERO CARD
// ══════════════════════════════════════════════════════════════════════════

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({
    required this.earnedCount,
    required this.totalCount,
    required this.completionRatio,
    required this.recentlyUnlocked,
    required this.palette,
    required this.onTapRecent,
  });

  final int earnedCount;
  final int totalCount;
  final double completionRatio;
  final List<AchievementEntry> recentlyUnlocked;
  final AppPalette palette;
  final ValueChanged<AchievementEntry> onTapRecent;

  @override
  Widget build(BuildContext context) {
    final pct = (completionRatio * 100).round();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OVERALL PROGRESS',
                    style: context.text.labelSmall!.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: palette.onSurfaceMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$earnedCount of $totalCount',
                    style: context.text.headlineMedium!.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: palette.outline.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '$pct% Unlocked',
                  style: context.text.labelSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: completionRatio,
              minHeight: 8,
              backgroundColor: palette.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(palette.primary),
            ),
          ),

          // Recently unlocked showcase
          if (recentlyUnlocked.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(
              height: 1,
              color: palette.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'RECENTLY UNLOCKED',
              style: context.text.labelSmall!.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                color: palette.onSurfaceMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentlyUnlocked.take(5).length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final entry = recentlyUnlocked[index];
                  return AppPressable(
                    onTap: () => onTapRecent(entry),
                    semanticLabel: 'View ${entry.achievement.title}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: palette.outline.withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: palette.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.achievement.title,
                            style: context.text.labelSmall!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CATEGORY FILTER BAR
// ══════════════════════════════════════════════════════════════════════════

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.palette,
  });

  final AchievementCategory selectedCategory;
  final ValueChanged<AchievementCategory> onCategorySelected;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AchievementCategory.values.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final cat = AchievementCategory.values[index];
          final isSelected = cat == selectedCategory;

          return AppPressable(
            onTap: () => onCategorySelected(cat),
            semanticLabel: 'Filter by ${cat.label}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.primary
                    : palette.surfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected
                      ? palette.primary
                      : palette.outline.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 14,
                    color: isSelected ? palette.onPrimary : palette.onSurfaceMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: context.text.labelSmall!.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? palette.onPrimary : palette.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT CARD
// ══════════════════════════════════════════════════════════════════════════

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.entry,
    required this.palette,
    required this.onTap,
  });

  final AchievementEntry entry;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = entry.achievement;
    final isUnlocked = entry.isUnlocked;

    return AppPressable(
      onTap: onTap,
      semanticLabel: '${a.title}: ${entry.progressSummary}',
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container with state badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked
                        ? palette.primary
                        : palette.surfaceVariant.withValues(alpha: 0.4),
                    border: Border.all(
                      color: isUnlocked ? palette.primary : palette.outline,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _iconFromString(a.iconName),
                      size: 24,
                      color: isUnlocked
                          ? palette.onPrimary
                          : palette.onSurfaceMuted,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.surface,
                    ),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUnlocked
                            ? palette.primary
                            : palette.surfaceVariant,
                      ),
                      child: Center(
                        child: Icon(
                          isUnlocked
                              ? Icons.check_rounded
                              : Icons.lock_outline_rounded,
                          size: 10,
                          color: isUnlocked
                              ? palette.onPrimary
                              : palette.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a.title,
                          style: context.text.titleSmall!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (a.xpReward > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '+${a.xpReward} XP',
                            style: context.text.labelSmall!.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              color: palette.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUnlocked ? a.description : a.condition,
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Progress row
                  if (isUnlocked)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: palette.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked',
                          style: context.text.labelSmall!.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.progressSummary,
                              style: context.text.labelSmall!.copyWith(
                                color: palette.onSurfaceMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${(entry.progressFraction * 100).round()}%',
                              style: context.text.labelSmall!.copyWith(
                                color: palette.onSurfaceMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: entry.progressFraction,
                            minHeight: 6,
                            backgroundColor: palette.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(palette.primary),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case 'check_circle':
        return Icons.check_circle_outline_rounded;
      case 'task_alt':
        return Icons.task_alt_rounded;
      case 'assignment_turned_in':
        return Icons.assignment_turned_in_rounded;
      case 'center_focus_strong':
        return Icons.center_focus_strong_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'whatshot':
        return Icons.whatshot_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'stars':
        return Icons.stars_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'folder':
        return Icons.folder_rounded;
      case 'library_books':
        return Icons.library_books_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// EMPTY CATEGORY STATE
// ══════════════════════════════════════════════════════════════════════════

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: palette.onSurfaceMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No achievements in this category',
              style: context.text.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
