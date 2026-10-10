import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/services/google_play_subscription_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../rewards/premium_entitlement.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final entitlement = PremiumEntitlement.instance;
    final isPremium = entitlement.isPremiumActive;
    final status = entitlement.status;
    final trialDays = entitlement.trialDaysRemaining;
    final trialActivated = entitlement.trialActivatedAt;

    return AppScaffold(
      title: 'Student OS Premium',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppSectionHeader(
            title: 'Premium',
            icon: Icons.workspace_premium_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Active' : 'Not Active',
                  style: context.text.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPremium ? AppColors.success : palette.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  status.label,
                  style: context.text.bodyMedium!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                if (trialActivated != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Trial activated: ${trialActivated.toString().substring(0, 10)}',
                    style: context.text.bodySmall,
                  ),
                  if (trialDays > 0)
                    Text(
                      '$trialDays day(s) remaining',
                      style: context.text.bodySmall!.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: 'What Premium provides',
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureRow(
            icon: Icons.insights_rounded,
            title: 'Advanced Analytics',
            description: 'Deeper trends, subject insights, and exam preparation analysis.',
          ),
          _FeatureRow(
            icon: Icons.smart_toy_rounded,
            title: 'Smart Scheduling',
            description:
                'AI-optimized study planning and time-budget recommendations.',
          ),
          _FeatureRow(
            icon: Icons.palette_rounded,
            title: 'Premium Themes',
            description: 'Exclusive theme unlocks for personalization.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trial available',
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '7-day trial activates once. After expiration, Premium requires subscription.',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _BillingStatusSection(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No fake purchases or simulated billing are implemented. A real billing provider can be connected to the SubscriptionProvider interface.',
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingStatusSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final provider = const GooglePlaySubscriptionProvider();
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  provider.isAvailable
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: provider.isAvailable
                      ? AppColors.success
                      : palette.info,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    provider.isAvailable
                        ? 'Google Play configured'
                        : 'Billing unavailable — configure Play Store products',
                    style: context.text.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Provider: ${provider.providerName ?? 'None'}',
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
            if (!provider.isAvailable)
              Text(
                'To activate billing, configure products in Google Play Console and integrate in_app_purchase.',
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
