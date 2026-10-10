import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../data/models/achievement.dart';
import '../../progression/achievement_controller.dart';
import '../../progression/widgets/achievement_detail_sheet.dart';

/// Displays earned and locked achievements from real academic behavior in the Progress screen.
class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  void _openDetail(BuildContext context, AchievementEntry entry) {
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

    return ListenableBuilder(
      listenable: AchievementController.instance,
      builder: (context, _) {
        final controller = AchievementController.instance;
        final entries = controller.entries;
        final previewEntries = entries.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Achievements',
              icon: Icons.emoji_events_rounded,
              trailing: TextButton(
                onPressed: () => AppRouter.openAchievements(context),
                child: Text(
                  '${controller.earnedCount}/${controller.totalCount} · View all',
                  style: context.text.labelMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (entries.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 40,
                        color: palette.onSurfaceMuted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No achievements yet',
                        style: context.text.bodyMedium!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ...previewEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _AchievementTile(
                    entry: entry,
                    palette: palette,
                    onTap: () => _openDetail(context, entry),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.entry,
    required this.palette,
    required this.onTap,
  });

  final AchievementEntry entry;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final achievement = entry.achievement;
    final isUnlocked = entry.isUnlocked;
    final icon = _iconFromString(achievement.iconName);

    return AppPressable(
      onTap: onTap,
      semanticLabel: '${achievement.title}: ${entry.progressSummary}',
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? palette.primary
                    : palette.surfaceVariant.withValues(alpha: 0.5),
                border: Border.all(
                  color: isUnlocked ? palette.primary : palette.outline,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: isUnlocked ? palette.onPrimary : palette.onSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Title & progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: context.text.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (achievement.xpReward > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '+${achievement.xpReward} XP',
                            style: context.text.labelSmall!.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUnlocked ? achievement.description : entry.progressSummary,
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Status Icon
            Icon(
              isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
              size: 20,
              color: isUnlocked ? palette.primary : palette.onSurfaceMuted,
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
