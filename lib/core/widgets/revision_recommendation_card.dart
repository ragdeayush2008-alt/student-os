import 'package:flutter/material.dart';

import '../analytics/performance_snapshot.dart';
import '../analytics/revision_priority_engine.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/exam.dart';

/// Revision recommendation card for Exam Detail / Home / Study.
class RevisionRecommendationCard extends StatelessWidget {
  const RevisionRecommendationCard({
    super.key,
    required this.exam,
    this.result,
  });

  final StudentExam exam;
  final RevisionPriorityResult? result;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    const engine = RevisionPriorityEngine();
    final r =
        result ??
        engine.assessRevision(
          exam,
          const PerformanceSnapshot(
            allSessions: [],
            allTasks: [],
            allSubjects: [],
            allExams: [],
            studyDates: {},
          ),
        );

    final urgencyColor = r.priorityLabel == 'Critical'
        ? AppColors.error
        : r.priorityLabel == 'High'
        ? AppColors.warning
        : r.priorityLabel == 'Medium'
        ? AppColors.info
        : palette.success;

    return AppCard(
      color: urgencyColor.withValues(alpha: 0.06),
      borderColor: urgencyColor.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.refresh_rounded, size: 20, color: urgencyColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Revision — ${r.priorityLabel}',
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: urgencyColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(r.explanation, style: context.text.bodySmall),
            if (r.recommendations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              ...r.recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• $rec',
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
