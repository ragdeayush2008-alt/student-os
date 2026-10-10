import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_states.dart';
import '../../controller/focus_controller.dart';
import '../../data/models/focus_mission.dart';

class FocusInsightsScreen extends StatelessWidget {
  const FocusInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fc = FocusController.instance;
    final palette = AppTheme.colorsOf(context);
    final insights = fc.insights;
    final sessions = fc.sessions
        .where(
          (s) =>
              s.isComplete &&
              s.mode == FocusMode.focusGuard,
        )
        .toList();

    return AppScaffold(
      title: 'Focus Insights',
      onBack: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Period',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StatRow('Sessions Completed', '${sessions.length}', palette),
                  _StatRow(
                    'Total Focus Time',
                    '${sessions.fold<int>(0, (sum, s) => sum + s.effectiveElapsed.inMinutes)} min',
                    palette,
                  ),
                  _StatRow(
                    'Average Session',
                    '${sessions.isEmpty ? 0 : sessions.fold<int>(0, (sum, s) => sum + s.effectiveElapsed.inMinutes) ~/ sessions.length.clamp(1, 999)} min',
                    palette,
                  ),
                  _StatRow(
                    'Distractions Captured',
                    '${fc.distractions.length}',
                    palette,
                  ),
                  _StatRow(
                    'Total Points Earned',
                    '${fc.sessions.where((s) => s.mode == FocusMode.focusGuard).fold<int>(0, (sum, s) => sum + s.sessionScore)}',
                    palette,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (insights.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Insights',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...insights.map(
                      (insight) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              color: palette.warning,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                insight.text,
                                style: context.text.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const AppEmptyState(
                title: 'Insights coming soon',
                icon: Icons.auto_awesome_outlined,
                description:
                    'Complete 3+ focus sessions to unlock personalized insights.',
                compact: true,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value, this.palette);
  final String label;
  final String value;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.text.bodyMedium?.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          Text(
            value,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.primary,
            ),
          ),
        ],
      ),
    );
  }
}
