import 'package:flutter/material.dart';

import '../analytics/performance_snapshot.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'student_behavior_profile.dart';

/// Personalized insight card for Home/Analytics — derived from real student data.
class PersonalizedInsightSection extends StatelessWidget {
  const PersonalizedInsightSection({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = StudentBehaviorProfile.fromSnapshot(
      PerformanceSnapshot.fromControllers(),
    );
    final palette = AppTheme.colorsOf(context);

    if (!profile.hasSufficientData) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalized for you',
                style: context.text.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Keep studying to unlock personalized recommendations.',
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      color: palette.primaryContainer.withValues(alpha: 0.3),
      borderColor: palette.primary.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized for you',
              style: context.text.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (profile.averageSessionMinutes > 0)
              _InsightLine(
                icon: Icons.timer_rounded,
                text: 'Average session: ~${profile.averageSessionMinutes} min.',
                color: palette.primary,
              ),
            if (profile.consistency30Day > 0.0)
              _InsightLine(
                icon: Icons.local_fire_department_rounded,
                text:
                    'Consistency: ${(profile.consistency30Day * 100).round()}%.',
                color: AppColors.success,
              ),
            if (profile.recentStudyMinutes > 0)
              _InsightLine(
                icon: Icons.trending_up_rounded,
                text: 'Recent study: ${profile.recentStudyMinutes}m this week.',
                color: palette.info,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              profile.recommendationReason,
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

class _InsightLine extends StatelessWidget {
  const _InsightLine({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: context.text.bodySmall)),
      ],
    );
  }
}
