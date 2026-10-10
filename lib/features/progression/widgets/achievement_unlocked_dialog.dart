import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/achievement.dart';

/// Premium, restrained celebration dialog when a student unlocks an achievement.
///
/// Follows the Student OS monochromatic guidelines:
/// - Inter font
/// - Black, White, Grey palette (Zero purple)
/// - Respects reduced-motion preferences
class AchievementUnlockedDialog extends StatefulWidget {
  const AchievementUnlockedDialog({
    super.key,
    required this.achievement,
  });

  final Achievement achievement;

  @override
  State<AchievementUnlockedDialog> createState() =>
      _AchievementUnlockedDialogState();
}

class _AchievementUnlockedDialogState extends State<AchievementUnlockedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppDurations.slow;

    _controller = AnimationController(vsync: this, duration: duration);

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.standard,
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final a = widget.achievement;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: palette.outline.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header with Icon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant.withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.primary,
                        ),
                        child: Center(
                          child: Icon(
                            _iconFromString(a.iconName),
                            size: 36,
                            color: palette.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'ACHIEVEMENT UNLOCKED',
                        style: context.text.labelSmall!.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: palette.onSurfaceMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.title,
                        style: context.text.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        a.description,
                        style: context.text.bodyMedium!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (a.xpReward > 0) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 8,
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
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: palette.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+${a.xpReward} XP Awarded',
                                style: context.text.labelMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: palette.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

/// Helper function to display the achievement celebration modal.
void showAchievementUnlockedDialog(BuildContext context, Achievement achievement) {
  showDialog<void>(
    context: context,
    builder: (context) => AchievementUnlockedDialog(achievement: achievement),
  );
}
