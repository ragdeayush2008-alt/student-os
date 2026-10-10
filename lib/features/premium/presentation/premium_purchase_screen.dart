import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../models/premium_catalog.dart';
import '../models/premium_plan.dart';
import '../services/entitlement_service.dart';
import '../services/premium_analytics.dart';
import 'premium_benefits_screen.dart';
import '../widgets/premium_widgets.dart';

/// Student OS Pro purchase page — the single destination for every
/// Premium redirect. Context-aware: when opened for a feature, the header
/// explains that feature first, then full Pro benefits and plans.
///
/// No provider is connected: Continue honestly reports that purchases are
/// not enabled yet. Never claims a purchase occurred.
class PremiumPurchaseScreen extends StatefulWidget {
  const PremiumPurchaseScreen({super.key, this.sourceFeatureId});

  /// Catalog feature id that triggered the redirect (null = general).
  final String? sourceFeatureId;

  @override
  State<PremiumPurchaseScreen> createState() =>
      _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends State<PremiumPurchaseScreen> {
  String _selectedPlanId = PremiumPlanCatalog.yearly.id;

  @override
  void initState() {
    super.initState();
    PremiumAnalytics.log(
      PremiumAnalytics.paywallViewed,
      params: {'source': widget.sourceFeatureId ?? 'general'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final sourceFeature = widget.sourceFeatureId == null
        ? null
        : PremiumCatalog.byId(widget.sourceFeatureId!);

    return AppScaffold(
      title: 'Student OS Pro',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Context header ──
                Text(
                  sourceFeature == null
                      ? 'STUDENT OS PRO'
                      : 'UNLOCK ${sourceFeature.title.toUpperCase()}',
                  style: context.text.labelLarge?.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  sourceFeature?.description ??
                      'Your student life, intelligently organized.',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Key benefits (top 10 active) ──
                ...PremiumCatalog.activeFeatures
                    .take(10)
                    .map((f) => PremiumBenefitCard(feature: f)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PremiumBenefitsScreen(),
                    ),
                  ),
                  child: const Text('See all Pro benefits'),
                ),
                const SizedBox(height: AppSpacing.sm),

                const AppSectionHeader(title: 'Plans'),
                const SizedBox(height: AppSpacing.xs),
                ...PremiumPlanCatalog.plans.map(
                  (plan) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: PremiumPlanCard(
                      plan: plan,
                      selected: _selectedPlanId == plan.id,
                      onSelect: () {
                        setState(() => _selectedPlanId = plan.id);
                        PremiumAnalytics.log(
                          PremiumAnalytics.planSelected,
                          params: {'plan': plan.id},
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                FilledButton(
                  onPressed: () => _continue(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continue'),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _restore(context),
                      child: const Text('Restore Purchases'),
                    ),
                    TextButton(
                      onPressed: () => _manage(context),
                      child: const Text('Manage Membership'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _continue(BuildContext context) {
    PremiumAnalytics.log(
      PremiumAnalytics.checkoutStarted,
      params: {'plan': _selectedPlanId},
    );
    final isPro = EntitlementService.instance.isPro;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purchases not enabled yet'),
        content: Text(
          isPro
              ? 'Billing is not connected in this build, so no purchase is needed for your preview access.'
              : 'Student OS Pro billing is not connected yet. Pick a plan now and check out once purchases go live — nothing is charged today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _restore(BuildContext context) {
    PremiumAnalytics.log(PremiumAnalytics.restoreStarted);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Purchases'),
        content: const Text(
          'Restore Purchases is not available yet — no billing provider is connected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _manage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manage Membership'),
        content: const Text(
          'Membership management will be available through your store account once billing is connected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
