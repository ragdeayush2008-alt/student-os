import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/achievement.dart';

/// Modal bottom sheet showing detailed information, progress, and actionable steps for an achievement.
class AchievementDetailSheet extends StatelessWidget {
  const AchievementDetailSheet({
    super.key,
    required this.entry,
  });

  final AchievementEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final a = entry.achievement;
    final isUnlocked = entry.isUnlocked;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: palette.outline.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              0,
            ),
            child: Row(
              children: [
                // Category Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.category.icon, size: 12, color: palette.onSurfaceMuted),
                      const SizedBox(width: 4),
                      Text(
                        a.category.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUnlocked
                            ? palette.primary
                            : palette.surfaceVariant.withValues(alpha: 0.5),
                        border: Border.all(
                          color: isUnlocked ? palette.primary : palette.outline,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _iconFromString(a.iconName),
                          size: 38,
                          color: isUnlocked ? palette.onPrimary : palette.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title & Description
                  Text(
                    a.title,
                    style: context.text.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.description,
                    style: context.text.bodyMedium!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Progress Box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: palette.surfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: palette.outline.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isUnlocked ? 'Status' : 'Progress',
                              style: context.text.labelMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.onSurfaceMuted,
                              ),
                            ),
                            Text(
                              entry.progressSummary,
                              style: context.text.labelMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: entry.progressFraction,
                            minHeight: 8,
                            backgroundColor: palette.outline.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation(palette.primary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          entry.actionNeeded,
                          style: context.text.bodySmall!.copyWith(
                            color: palette.onSurfaceMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // XP Reward Box
                  if (a.xpReward > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: palette.outline.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: palette.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Reward',
                              style: context.text.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '+${a.xpReward} XP',
                            style: context.text.titleSmall!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
