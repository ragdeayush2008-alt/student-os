import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../premium/services/entitlement_service.dart';
import '../services/widget_data_service.dart';
import '../widget_catalog.dart';

/// In-app widget catalog: what each home-screen widget shows, how to add
/// it per platform, and a development-only snapshot inspector.
///
/// Preview tiles use static design copy only — never live or fake user
/// data. Actual widgets always render the real snapshot.
class WidgetsScreen extends StatefulWidget {
  const WidgetsScreen({super.key});

  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends State<WidgetsScreen> {
  @override
  void initState() {
    super.initState();
    EntitlementService.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    EntitlementService.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppScaffold(
      title: 'Widgets',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Glanceable Student OS for your home screen.',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Android: long-press the home screen → Widgets → Student OS. '
                  'iOS: long-press → Edit → + → Student OS (requires app version 1.1+).',
                  style: context.text.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final tier in WidgetTier.values) ...[
                  AppSectionHeader(
                    title: switch (tier) {
                      WidgetTier.tier1 => 'Essentials',
                      WidgetTier.tier2 => 'More widgets',
                      WidgetTier.tier3 => 'Coming next',
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...WidgetCatalog.byTier(tier).map(
                    (def) => _WidgetTile(def: def),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (kDebugMode) const _WidgetDebugTools(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WidgetTile extends StatelessWidget {
  const _WidgetTile({required this.def});

  final StudentWidgetDef def;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final locked = def.premiumFeatureId != null &&
        !EntitlementService.instance
            .hasFeatureAccess(def.premiumFeatureId!);
    final comingSoon = def.tier == WidgetTier.tier3;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(def.icon, color: palette.primary, size: 20),
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
                        def.title,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (locked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else if (comingSoon)
                      Text(
                        'SOON',
                        style: context.text.labelSmall?.copyWith(
                          color: palette.onSurfaceMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                Text(
                  locked
                      ? 'Pro capability — tap to explore Student OS Pro.'
                      : def.description,
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

/// Development-only snapshot tools. Never shown in release builds.
class _WidgetDebugTools extends StatefulWidget {
  const _WidgetDebugTools();

  @override
  State<_WidgetDebugTools> createState() => _WidgetDebugToolsState();
}

class _WidgetDebugToolsState extends State<_WidgetDebugTools> {
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: 'Developer tools'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _status.isEmpty ? 'No action run yet.' : _status,
          style: context.text.bodySmall?.copyWith(
            color: palette.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () async {
                await WidgetDataService.instance.refreshNow();
                if (mounted) {
                  setState(() => _status = 'Snapshot refreshed.');
                }
              },
              child: const Text('Refresh widgets'),
            ),
            OutlinedButton(
              onPressed: () async {
                await WidgetDataService.instance.clearForLogout();
                if (mounted) {
                  setState(() => _status = 'Snapshot cleared.');
                }
              },
              child: const Text('Clear snapshot'),
            ),
          ],
        ),
      ],
    );
  }
}
