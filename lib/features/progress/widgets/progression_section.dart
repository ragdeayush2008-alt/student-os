import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../data/models/level.dart';
import '../../progression/progression_controller.dart';
import '../../progression/widgets/xp_history_screen.dart';

/// Progression section showing the student's level, XP, and progression.
///
/// Designed to be subtle and academic, not dominating the Progress screen.
/// Academic progress remains the primary focus.
class ProgressionSection extends StatelessWidget {
  const ProgressionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return ListenableBuilder(
      listenable: ProgressionController.instance,
      builder: (context, _) {
        final controller = ProgressionController.instance;
        final level = controller.currentLevel;
        final levelLabel = LevelCurve.labelForLevel(level.level);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Student Progression',
              icon: Icons.auto_awesome_rounded,
              trailing: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const XpHistoryScreen(),
                    ),
                  );
                },
                child: const Text('History'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Level circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.streak.withValues(alpha: 0.15),
                          border: Border.all(color: palette.streak, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${level.level}',
                            style: context.text.headlineSmall!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.streak,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Level ${level.level}',
                                  style: context.text.titleLarge!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.surfaceVariant,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    levelLabel,
                                    style: context.text.labelSmall!.copyWith(
                                      color: palette.onSurfaceMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${controller.totalXp} Total XP',
                              style: context.text.bodyMedium!.copyWith(
                                color: palette.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Progress bar to next level
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress to Level ${level.level + 1}',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                          Text(
                            '${level.xpToNextLevel} XP needed',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: level.progressInLevel,
                          minHeight: 8,
                          backgroundColor: palette.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(palette.streak),
                        ),
                      ),
                    ],
                  ),

                  // Quick stats row
                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    height: 1,
                    color: palette.outline.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Today',
                        value: '+${controller.todayXp} XP',
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: palette.outline.withValues(alpha: 0.3),
                      ),
                      _StatColumn(
                        label: 'This Week',
                        value: '+${controller.weekXp} XP',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Column(
      children: [
        Text(
          value,
          style: context.text.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.streak,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: context.text.bodySmall!.copyWith(
            color: palette.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
