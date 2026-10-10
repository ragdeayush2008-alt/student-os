import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/services/student_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_section_header.dart';
import '../../data/models/entitlement.dart';
import '../../data/models/reward.dart';
import 'entitlement_manager.dart';
import 'reward_catalog.dart';
import 'rewards_screen.dart';

/// Interactive showcase and selector for student badges earned through XP rewards.
class BadgeDisplay extends StatelessWidget {
  const BadgeDisplay({super.key, this.showEquippedSelector = true});

  final bool showEquippedSelector;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final unlockedBadges = EntitlementManager.instance.unlockedBadges;
    final student = StudentService.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Earned Badges',
          icon: Icons.military_tech_rounded,
          trailing: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RewardsScreen()),
              );
            },
            child: const Text('Get Badges'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (unlockedBadges.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.military_tech_outlined,
                    size: 40,
                    color: palette.onSurfaceMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No badges earned yet',
                    style: context.text.titleSmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reach milestones and redeem badges from the Marketplace',
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
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (student.profile.importantDateLabel.startsWith(
                  'primary_badge:',
                )) ...[
                  _FeaturedPrimaryBadge(
                    badgeRewardId: student.profile.importantDateLabel
                        .replaceFirst('primary_badge:', ''),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    height: 1,
                    color: palette.outline.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  'Tap a badge to feature it on your profile',
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: unlockedBadges.map((badgeEntitlement) {
                    final reward = RewardCatalog.instance.findById(
                      badgeEntitlement.rewardId,
                    );
                    final isEquipped =
                        student.profile.importantDateLabel ==
                        'primary_badge:${badgeEntitlement.rewardId}';

                    return _BadgeChip(
                      entitlement: badgeEntitlement,
                      reward: reward,
                      isEquipped: isEquipped,
                      onTap: () async {
                        if (isEquipped) {
                          await student.updateImportantDate(null, '');
                        } else {
                          await student.updateImportantDate(
                            DateTime.now(),
                            'primary_badge:${badgeEntitlement.rewardId}',
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FeaturedPrimaryBadge extends StatelessWidget {
  const _FeaturedPrimaryBadge({required this.badgeRewardId});

  final String badgeRewardId;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final reward = RewardCatalog.instance.findById(badgeRewardId);
    if (reward == null) return const SizedBox.shrink();

    final badgeHex = reward.metadata?['badgeColor'] as String? ?? '#3B82F6';
    final badgeColor = _parseHex(badgeHex);
    // Badge colors come from data (arbitrary hex), so the EQUIPPED foreground
    // is derived from background luminance — never assumed white.
    final onBadgeColor =
        ThemeData.estimateBrightnessForColor(badgeColor) == Brightness.dark
            ? Colors.white
            : const Color(0xFF08211C);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor.withValues(alpha: 0.2),
              border: Border.all(color: badgeColor, width: 2),
            ),
            child: Icon(
              _getBadgeIcon(reward.iconName ?? ''),
              color: badgeColor,
              size: 26,
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
                      'Featured Profile Badge',
                      style: context.text.labelSmall!.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'EQUIPPED',
                        style: context.text.labelSmall!.copyWith(
                          color: onBadgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reward.title,
                  style: context.text.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  reward.description,
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.forest;
    }
  }

  IconData _getBadgeIcon(String iconName) {
    return switch (iconName) {
      'star' => Icons.star_rounded,
      'local_fire_department' => Icons.local_fire_department_rounded,
      'school' => Icons.school_rounded,
      'emoji_events' => Icons.emoji_events_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.entitlement,
    required this.reward,
    required this.isEquipped,
    required this.onTap,
  });

  final StudentEntitlement entitlement;
  final Reward? reward;
  final bool isEquipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final title = reward?.title ?? 'Badge';
    final badgeHex = reward?.metadata?['badgeColor'] as String? ?? '#3B82F6';
    final color = _parseHex(badgeHex);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isEquipped
              ? color.withValues(alpha: 0.15)
              : palette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isEquipped ? color : palette.outline.withValues(alpha: 0.3),
            width: isEquipped ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getBadgeIcon(reward?.iconName ?? ''),
              size: 18,
              color: isEquipped ? color : palette.onSurfaceMuted,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: context.text.labelMedium!.copyWith(
                fontWeight: isEquipped ? FontWeight.w700 : FontWeight.w600,
                color: isEquipped ? color : palette.onSurface,
              ),
            ),
            if (isEquipped) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, size: 16, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.forest;
    }
  }

  IconData _getBadgeIcon(String iconName) {
    return switch (iconName) {
      'star' => Icons.star_rounded,
      'local_fire_department' => Icons.local_fire_department_rounded,
      'school' => Icons.school_rounded,
      'emoji_events' => Icons.emoji_events_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }
}
