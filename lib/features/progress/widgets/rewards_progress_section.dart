import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/services/student_service.dart';
import '../../rewards/badge_display.dart';
import '../../rewards/redemption_controller.dart';
import '../../rewards/rewards_screen.dart';
import '../../rewards/theme_manager.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_radius.dart';

/// Section in Progress screen showing active cosmetics, badges, and marketplace access.
class RewardsProgressSection extends StatelessWidget {
  const RewardsProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        RedemptionController.instance,
        ThemeManager.instance,
        StudentService.instance,
      ]),
      builder: (context, _) {
        final redemption = RedemptionController.instance;
        final owned = redemption.activeEntitlements;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge Showcase
            const BadgeDisplay(),
            const SizedBox(height: AppSpacing.xl),

            // All unlocked rewards overview
            AppSectionHeader(
              title: 'Unlocked Entitlements',
              icon: Icons.workspace_premium_rounded,
              trailing: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RewardsScreen(),
                    ),
                  );
                },
                child: const Text('Marketplace'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (owned.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.redeem_rounded,
                        size: 36,
                        color: palette.onSurfaceMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No rewards unlocked yet',
                        style: context.text.titleSmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Earn XP and redeem rewards in the marketplace',
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
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: owned.map((entitlement) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: palette.streak.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: palette.streak.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconForType(entitlement.type.name),
                          size: 16,
                          color: palette.streak,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entitlement.type.label,
                          style: context.text.labelMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: palette.streak,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'theme' => Icons.palette_outlined,
      'badge' => Icons.military_tech_outlined,
      'feature' => Icons.auto_awesome_outlined,
      'discount' => Icons.local_offer_outlined,
      'premium' => Icons.workspace_premium,
      _ => Icons.stars_rounded,
    };
  }
}
