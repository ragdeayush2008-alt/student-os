import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../sleep_controller.dart';

/// Reusable sleep-window summary card (P1 Sleep Foundation).
///
/// Shows the planned window + duration with an Edit action, or an honest
/// empty state with a Set action when no schedule exists. Used by Home and
/// the Assistant Command Center — one component, no duplicates.
class SleepSummaryCard extends StatelessWidget {
  const SleepSummaryCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SleepController.instance,
      builder: (context, _) {
        final palette = AppTheme.colorsOf(context);
        final controller = SleepController.instance;
        final schedule = controller.schedule;

        final card = AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bedtime_rounded,
                      color: palette.onPrimaryContainer,
                      size: 20,
                      semanticLabel: 'Sleep schedule',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Sleep Schedule',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (schedule != null && !schedule.enabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'OFF',
                        style: context.text.labelSmall?.copyWith(
                          color: palette.onSurfaceMuted,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (schedule == null) ...[
                Text(
                  'Set your sleep schedule so Student OS can plan your day around it.',
                  style: context.text.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        AppRouter.openSleepSchedule(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Set Sleep Schedule'),
                  ),
                ),
              ] else ...[
                Text(
                  schedule.windowLabel,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${schedule.durationLabel} planned'
                  '${schedule.enabled ? '' : ' · paused'}',
                  style: context.text.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          AppRouter.openSleepSchedule(context),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
        // Compact mode has no explicit button, so the whole card opens
        // the schedule. Full mode has its own Set/Edit buttons.
        if (!compact) return card;
        return InkWell(
          onTap: () => AppRouter.openSleepSchedule(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: card,
        );
      },
    );
  }
}
