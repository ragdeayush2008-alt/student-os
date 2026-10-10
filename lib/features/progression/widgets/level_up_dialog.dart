import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/level.dart';

/// Premium level-up celebration dialog.
///
/// Displays when a student reaches a new level. Design is mature and
/// professional, avoiding childish game-like effects. Respects reduce-motion
/// accessibility preferences.
class LevelUpDialog extends StatefulWidget {
  const LevelUpDialog({
    super.key,
    required this.oldLevel,
    required this.newLevel,
  });

  final int oldLevel;
  final int newLevel;

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
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
    final newLevel = widget.newLevel;
    final levelInfo = LevelCurve.forXp(LevelCurve.xpForLevel(newLevel));
    final levelLabel = LevelCurve.labelForLevel(newLevel);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with level circle
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        palette.streak.withValues(alpha: 0.15),
                        palette.streak.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Level badge
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.streak.withValues(alpha: 0.15),
                          border: Border.all(color: palette.streak, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            '$newLevel',
                            style: context.text.displaySmall!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.streak,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Level Up!',
                        style: context.text.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        levelLabel,
                        style: context.text.bodyLarge!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Body with progress info
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        "You've reached Level $newLevel",
                        style: context.text.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 20,
                              color: palette.streak,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${levelInfo.xpForNextLevel - levelInfo.currentXp} XP to Level ${newLevel + 1}',
                              style: context.text.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: palette.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Continue',
                            style: context.text.titleMedium!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.onPrimary,
                            ),
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
}

/// Shows the level-up dialog. Ensures it's only shown once per level-up.
void showLevelUpDialog(BuildContext context, int oldLevel, int newLevel) {
  // Don't show if already at the same level
  if (oldLevel >= newLevel) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LevelUpDialog(oldLevel: oldLevel, newLevel: newLevel),
  );
}
