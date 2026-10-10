import 'package:flutter/material.dart';

import '../analytics/academic_analytics_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_section_header.dart';

/// Light notification/accountability center for Home / Analytics.
class AccountabilityCenter extends StatelessWidget {
  const AccountabilityCenter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AcademicAnalyticsController.instance;
    final palette = AppTheme.colorsOf(context);
    final hasOverdue = controller.overdueTaskCount > 0;
    final hasExam = controller.totalExamsUpcoming > 0;
    final consistency = controller.consistency;

    return AppCard(
      color: palette.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Accountability',
              icon: Icons.balance_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            if (hasExam || hasOverdue)
              Row(
                children: [
                  Icon(
                    hasOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.event_note_rounded,
                    size: 20,
                    color: hasOverdue ? AppColors.warning : palette.info,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasOverdue
                          ? '${controller.overdueTaskCount} overdue task(s) need attention.'
                          : '${controller.totalExamsUpcoming} upcoming exam(s).',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              consistency > 0.7
                  ? 'Your consistency is good (${(consistency * 100).round()}%). Keep it up.'
                  : consistency > 0.3
                  ? 'Your consistency is ${(consistency * 100).round()}%. Try one more study day this week.'
                  : 'Starting a study streak helps build momentum.',
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
