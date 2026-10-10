import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../rewards/premium_entitlement.dart';
import '../services/entitlement_service.dart';
import '../services/premium_analytics.dart';
import 'premium_benefits_screen.dart';
import 'premium_purchase_screen.dart';
import '../widgets/premium_widgets.dart';

/// Membership: current FREE/PRO state, plan, and next steps.
///
/// Shows verified plan data when available; never fabricates renewal or
/// payment information.
class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EntitlementService.instance,
      builder: (context, _) {
        final entitlement = EntitlementService.instance;
        final isPro = entitlement.isPro;
        final status = entitlement.status;
        final planName = _planName(entitlement);
        final detail = _detail(entitlement);

        return AppScaffold(
          title: 'Membership',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MembershipStatusCard(
                      isPro: isPro,
                      statusLabel: status.label,
                      planName: planName,
                      detail: detail,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (!isPro) ...[
                      Text(
                        'Explore what Pro can unlock.',
                        style: context.text.bodyMedium?.copyWith(
                          color: AppTheme.colorsOf(context).onSurfaceMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: () {
                          PremiumAnalytics.log(
                            PremiumAnalytics.featureViewed,
                            params: {'source': 'membership'},
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const PremiumPurchaseScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 18,
                        ),
                        label: const Text('Explore Student OS Pro'),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PremiumBenefitsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text('View Benefits'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _unavailable(
                                context,
                                'Restore Purchases',
                                'Restore Purchases is not available yet — no billing provider is connected.',
                              ),
                              child: const Text('Restore Purchases'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _unavailable(
                                context,
                                'Manage Membership',
                                'Membership management will live in your store account once billing is connected.',
                              ),
                              child: const Text('Manage Membership'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _planName(EntitlementService entitlement) {
    // Verified plan names only; legacy trial shows its own status.
    if (entitlement.isDevelopmentPreview) return 'Development preview';
    return null;
  }

  String? _detail(EntitlementService entitlement) {
    if (entitlement.isDevelopmentPreview) {
      return 'Local preview for development — not a purchase.';
    }
    if (entitlement.isPro) {
      final trial = PremiumEntitlement.instance;
      if (trial.trialDaysRemaining > 0) {
        return 'Trial · ${trial.trialDaysRemaining} day(s) remaining';
      }
      return 'Active Premium access';
    }
    return 'The tools to organize your student life, free.';
  }

  void _unavailable(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
