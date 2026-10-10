import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../models/premium_catalog.dart';
import '../models/premium_plan.dart';

/// Reusable Premium UI pieces, all rendered from central catalog data.

/// Small PRO pill used on gated features.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.label = 'PRO'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: palette.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// One plan card: price, monthly equivalent, honest savings, select state.
class PremiumPlanCard extends StatelessWidget {
  const PremiumPlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onSelect,
  });

  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onSelect,
      child: _PlanCardBody(
        plan: plan,
        selected: selected,
        savings: plan.savingsLabelVs(PremiumPlanCatalog.baseline),
      ),
    );
  }
}

class _PlanCardBody extends StatelessWidget {
  const _PlanCardBody({
    required this.plan,
    required this.selected,
    required this.savings,
  });

  final PremiumPlan plan;
  final bool selected;
  final String? savings;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      borderColor: selected ? palette.primary : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? palette.primary : palette.onSurfaceMuted,
                width: 2,
              ),
              color: selected ? palette.primary : Colors.transparent,
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 13, color: palette.onPrimary,)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (plan.isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'BEST VALUE',
                          style: context.text.labelSmall?.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  plan.periodLabel,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                  ),
                ),
                Text(
                  '${plan.effectiveMonthlyLabel}'
                  '${savings != null ? ' · $savings' : ''}',
                  style: context.text.bodySmall?.copyWith(
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

/// One benefit row: icon + title + description.
class PremiumBenefitCard extends StatelessWidget {
  const PremiumBenefitCard({super.key, required this.feature});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final comingSoon =
        feature.status == PremiumFeatureStatus.comingSoon;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(feature.icon, color: palette.primary, size: 19),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        feature.title,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (comingSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: palette.onSurface.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'SOON',
                          style: context.text.labelSmall?.copyWith(
                            color: palette.onSurfaceMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: context.text.bodySmall?.copyWith(
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

/// Wraps a locked affordance: PRO badge + tap routes to the paywall.
class PremiumFeatureGate extends StatelessWidget {
  const PremiumFeatureGate({
    super.key,
    required this.featureId,
    required this.child,
    required this.onLockedTap,
  });

  final String featureId;
  final Widget child;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onLockedTap,
            child: const PremiumBadge(),
          ),
        ),
      ],
    );
  }
}

/// Membership status card for the Membership screen.
class MembershipStatusCard extends StatelessWidget {
  const MembershipStatusCard({
    super.key,
    required this.isPro,
    required this.statusLabel,
    this.planName,
    this.detail,
  });

  final bool isPro;
  final String statusLabel;
  final String? planName;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      color: isPro ? palette.deepForest : null,
      borderColor: isPro ? palette.deepForest : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            isPro
                ? Icons.workspace_premium_rounded
                : Icons.person_outline_rounded,
            color: isPro ? Colors.white : palette.primary,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPro ? 'STUDENT OS PRO' : 'STUDENT OS FREE',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isPro ? Colors.white : null,
                  ),
                ),
                Text(
                  statusLabel,
                  style: context.text.bodySmall?.copyWith(
                    color: isPro
                        ? Colors.white.withValues(alpha: 0.8)
                        : palette.onSurfaceMuted,
                  ),
                ),
                if (planName != null)
                  Text(
                    planName!,
                    style: context.text.bodySmall?.copyWith(
                      color: isPro
                          ? Colors.white.withValues(alpha: 0.8)
                          : palette.onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (detail != null)
                  Text(
                    detail!,
                    style: context.text.bodySmall?.copyWith(
                      color: isPro
                          ? Colors.white.withValues(alpha: 0.8)
                          : palette.onSurfaceMuted,
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
