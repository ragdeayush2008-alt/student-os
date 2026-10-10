import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/design/student_os_premium.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../models/premium_catalog.dart';
import '../services/premium_analytics.dart';
import '../widgets/premium_widgets.dart';

/// WHY STUDENT OS PRO: full benefit catalog grouped by section, rendered
/// from [PremiumCatalog]. Free vs Pro comparison included once, here.
class PremiumBenefitsScreen extends StatefulWidget {
  const PremiumBenefitsScreen({super.key});

  @override
  State<PremiumBenefitsScreen> createState() => _PremiumBenefitsScreenState();
}

class _PremiumBenefitsScreenState extends State<PremiumBenefitsScreen> {
  @override
  void initState() {
    super.initState();
    PremiumAnalytics.log(PremiumAnalytics.catalogViewed);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppScaffold(
      title: 'Why Pro',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: PremiumSurface.hero(),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STUDENT OS PRO',
                        style: PremiumType.eyebrow(context).copyWith(
                          color: const Color(0xFFA9C1AE),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Unlock the intelligence to run your student life.',
                        style: PremiumType.hero(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deeper planning, smarter focus, and sleep-aware days.',
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final category in PremiumFeatureCategory.values) ...[
                  AppSectionHeader(title: category.label),
                  const SizedBox(height: AppSpacing.xs),
                  ...PremiumCatalog.byCategory(category).map(
                    (f) => PremiumBenefitCard(feature: f),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const AppSectionHeader(title: 'Free vs Pro'),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.2),
                      1: FlexColumnWidth(1.4),
                      2: FlexColumnWidth(1.4),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: palette.onSurface.withValues(alpha: 0.05),
                        ),
                        children: const [
                          _CompareCell('', header: true),
                          _CompareCell('FREE', header: true),
                          _CompareCell('PRO', header: true),
                        ],
                      ),
                      for (final row in PlanComparison.rows)
                        TableRow(
                          children: [
                            _CompareCell(row.label),
                            _CompareCell(row.free),
                            _CompareCell(row.pro, highlight: true),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Free includes: ${FreeBaseline.items.take(6).join(' · ')} …',
                  style: context.text.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareCell extends StatelessWidget {
  const _CompareCell(this.text, {this.header = false, this.highlight = false});

  final String text;
  final bool header;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: context.text.bodySmall?.copyWith(
          fontWeight: header || highlight ? FontWeight.w800 : null,
          color: highlight ? palette.primary : null,
        ),
      ),
    );
  }
}
