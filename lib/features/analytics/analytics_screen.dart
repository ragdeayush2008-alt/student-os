import 'package:flutter/material.dart';

import '../../core/analytics/academic_analytics_controller.dart';
import '../../core/analytics/exam_readiness_analyzer.dart';
import '../../core/analytics/performance_trend_analyzer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_metric_card.dart';
import '../../core/widgets/app_progress.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AcademicAnalyticsController.instance;
    final palette = AppTheme.colorsOf(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AppScaffold(
        title: 'Academic Analytics',
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildTimeRangeSelector(context, controller, palette),
            const SizedBox(height: AppSpacing.lg),
            _buildOverviewMetrics(context, controller, palette),
            const SizedBox(height: AppSpacing.lg),
            _buildStudyTrendSection(context, controller, palette),
            const SizedBox(height: AppSpacing.lg),
            _buildExamReadinessSection(context, controller, palette),
            const SizedBox(height: AppSpacing.lg),
            _buildSubjectDistributionSection(context, controller, palette),
            const SizedBox(height: AppSpacing.lg),
            _buildTaskMetricsSection(context, controller, palette),
            const SizedBox(height: AppSpacing.lg),
            _buildInsightsSection(context, controller, palette),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(
    BuildContext context,
    AcademicAnalyticsController controller,
    AppPalette palette,
  ) {
    final durations = [
      const Duration(days: 7),
      const Duration(days: 30),
      const Duration(days: 90),
    ];
    return Row(
      children: [
        for (final duration in durations)
          _buildRangeButton(
            context,
            _labelForDuration(duration),
            duration,
            controller,
          ),
        const SizedBox(width: AppSpacing.sm),
        _buildRangeButton(
          context,
          'All',
          const Duration(days: 365 * 10),
          controller,
        ),
      ],
    );
  }

  String _labelForDuration(Duration duration) {
    final days = duration.inDays;
    if (days == 7) return '7 Days';
    if (days == 30) return '30 Days';
    if (days == 90) return '90 Days';
    return 'All';
  }

  Widget _buildRangeButton(
    BuildContext context,
    String label,
    Duration window,
    AcademicAnalyticsController controller,
  ) {
    final isSelected = controller.window == window;
    final palette = AppTheme.colorsOf(context);
    return Tooltip(
      message: 'Show analytics for $label',
      child: OutlinedButton(
        onPressed: () => controller.window = window,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? palette.primary : Colors.transparent,
          side: BorderSide(
            color: isSelected ? palette.primary : palette.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? palette.onPrimary : palette.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewMetrics(
    BuildContext context,
    AcademicAnalyticsController controller,
    AppPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Performance Overview',
          icon: Icons.insights_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message:
                    'Study time: ${controller.totalStudyMinutes} minutes in selected range',
                child: AppMetricCard(
                  label: 'Study Time',
                  value: controller.totalStudyMinutes.toDouble(),
                  icon: Icons.timer_rounded,
                  note: 'Minutes in range',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppMetricCard(
                label: 'Consistency',
                value: (controller.consistency * 100),
                icon: Icons.local_fire_department_rounded,
                note: 'Activity frequency',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppMetricCard(
                label: 'Sessions',
                value: controller.totalSessionsInWindow.toDouble(),
                icon: Icons.play_circle_outline_rounded,
                note: 'Completed sessions',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppMetricCard(
                label: 'Exams',
                value: controller.totalExamsUpcoming.toDouble(),
                icon: Icons.event_rounded,
                note: 'Upcoming exams',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudyTrendSection(
    BuildContext context,
    AcademicAnalyticsController controller,
    AppPalette palette,
  ) {
    final trend = controller.studyTrend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Study Trend',
          icon: Icons.trending_up_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppMetricCard(
                      label: 'Current',
                      value: trend.currentValue,
                      icon: Icons.sensors_rounded,
                      note: 'Minutes this period',
                    ),
                  ),
                  Expanded(
                    child: AppMetricCard(
                      label: 'Previous',
                      value: trend.previousValue,
                      icon: Icons.history_rounded,
                      note: 'Minutes last period',
                    ),
                  ),
                  Expanded(
                    child: AppMetricCard(
                      label: 'Change',
                      value: trend.delta,
                      icon: Icons.compare_arrows_rounded,
                      note: '${trend.deltaPercent.toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppLinearProgress(
                value:
                    (trend.currentValue /
                            (trend.previousValue > 0 ? trend.previousValue : 1))
                        .clamp(0.0, 2.0),
                color: _directionColor(trend.direction, palette),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(trend.explanation, style: context.text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamReadinessSection(
    BuildContext context,
    AcademicAnalyticsController controller,
    AppPalette palette,
  ) {
    final results = controller.examReadinessResults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Exam Readiness',
          icon: Icons.school_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (results.isEmpty)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No upcoming exams. Add an exam to track readiness.',
                style: context.text.bodyMedium,
              ),
            ),
          ),
        for (final result in results)
          _buildExamReadinessCard(context, result, palette),
      ],
    );
  }

  Widget _buildExamReadinessCard(
    BuildContext context,
    ExamReadinessResult result,
    AppPalette palette,
  ) {
    final color = _readinessColor(result.level, palette);
    return AppCard(
      color: color.withValues(alpha: 0.06),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  _readinessIcon(result.level),
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.level.toString().replaceAll(
                        'ExamReadinessLevel.',
                        '',
                      ),
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Score: ${(result.score * 100).round()}%',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppLinearProgress(value: result.score.clamp(0.0, 1.0), color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(result.explanation, style: context.text.bodySmall),
          if (result.reasons.length > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            ...result.reasons
                .skip(1)
                .map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $reason',
                      style: context.text.bodySmall?.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectDistributionSection(
    BuildContext context,
    AcademicAnalyticsController controller,
    AppPalette palette,
  ) {
    final distribution = controller.subjectStudyDistribution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Subject Breakdown',
          icon: Icons.book_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (distribution.isEmpty)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No study session data by subject yet.',
                style: context.text.bodyMedium,
              ),
            ),
          ),
        for (final entry in distribution.entries)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: context.text.bodyMedium),
                    Text('${entry.value} min', style: context.text.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                AppLinearProgress(
                  value:
                      (entry.value /
                              (distribution.values.isEmpty
                                  ? 1
                                  : distribution.values.reduce(
                                      (a, b) => a > b ? a : b,
                                    )))
                          .clamp(0.0, 1.0),
                  color: palette.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTaskMetricsSection(
    BuildContext context,
    AcademicAnalyticsController controller,
    AppPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Task Metrics',
          icon: Icons.checklist_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppMetricCard(
                label: 'Completion',
                value: (controller.taskCompletionRate * 100),
                icon: Icons.task_rounded,
                note: 'Tasks done',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppMetricCard(
                label: 'Overdue',
                value: controller.overdueTaskCount.toDouble(),
                icon: Icons.warning_amber_rounded,
                note: 'Needs attention',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsSection(
    BuildContext context,
    AcademicAnalyticsController controller,
    AppPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Insights',
          icon: Icons.lightbulb_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final insight in controller.dailyInsights)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(insight, style: context.text.bodyMedium),
              ),
            ),
          ),
      ],
    );
  }

  Color _directionColor(
    PerformanceTrendDirection direction,
    AppPalette palette,
  ) {
    switch (direction) {
      case PerformanceTrendDirection.improving:
        return AppColors.success;
      case PerformanceTrendDirection.stable:
        return AppColors.info;
      case PerformanceTrendDirection.declining:
        return AppColors.error;
      case PerformanceTrendDirection.insufficientData:
        return palette.onSurfaceMuted;
    }
  }

  Color _readinessColor(ExamReadinessLevel level, AppPalette palette) {
    switch (level) {
      case ExamReadinessLevel.strong:
        return AppColors.success;
      case ExamReadinessLevel.onTrack:
        return AppColors.info;
      case ExamReadinessLevel.needsAttention:
        return AppColors.warning;
      case ExamReadinessLevel.critical:
        return AppColors.error;
      case ExamReadinessLevel.insufficientData:
        return palette.onSurfaceMuted;
    }
  }

  IconData _readinessIcon(ExamReadinessLevel level) {
    switch (level) {
      case ExamReadinessLevel.strong:
        return Icons.check_circle_rounded;
      case ExamReadinessLevel.onTrack:
        return Icons.timelapse_rounded;
      case ExamReadinessLevel.needsAttention:
        return Icons.trending_flat_rounded;
      case ExamReadinessLevel.critical:
        return Icons.warning_amber_rounded;
      case ExamReadinessLevel.insufficientData:
        return Icons.help_outline_rounded;
    }
  }
}
