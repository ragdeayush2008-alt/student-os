import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/practice_session_result.dart';
import '../../planning/controllers/planning_block_controller.dart';
import '../../subjects/subject_controller.dart';
import '../academic_knowledge_controller.dart';
import 'practice_mode_selection_sheet.dart';
import 'practice_review_mistakes_sheet.dart';

/// Screen presenting the results of a completed practice session.
class PracticeResultScreen extends StatelessWidget {
  const PracticeResultScreen({
    super.key,
    required this.result,
  });

  final PracticeSessionResult result;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final topic = result.topicId != null
        ? AcademicKnowledgeController.instance.topicById(result.topicId!)
        : null;
    final subject = result.subjectId != null
        ? SubjectController.instance.subjectById(result.subjectId!)
        : null;

    final durationSec = result.durationSec;
    final durationMins = durationSec ~/ 60;
    final remainingSecs = durationSec % 60;
    final durationString = durationMins > 0
        ? '${durationMins}m ${remainingSecs}s'
        : '${remainingSecs}s';

    Color scoreColor;
    if (result.accuracyPercentage >= 80) {
      scoreColor = AppColors.success;
    } else if (result.accuracyPercentage >= 60) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Results'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Score Hero ───────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withValues(alpha: 0.12),
                        border: Border.all(color: scoreColor, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${result.accuracyPercentage}%',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            'accuracy',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      result.isPerfectScore
                          ? 'PERFECT SCORE! 🎉'
                          : (result.accuracyPercentage >= 70
                              ? 'PRACTICE COMPLETE 🎉'
                              : 'PRACTICE RECORDED'),
                      style: context.text.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.title,
                      style: context.text.bodyMedium!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Summary Metrics Grid ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Correct',
                      value: '${result.correctCount} / ${result.totalQuestions}',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetricCard(
                      label: 'Time',
                      value: durationString,
                      color: palette.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetricCard(
                      label: 'Skipped',
                      value: '${result.skippedCount}',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── What Went Well ───────────────────────────────────────────
              if (result.whatWentWell.isNotEmpty) ...[
                AppCard(
                  borderColor: AppColors.success.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'WHAT WENT WELL',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (final point in result.whatWentWell)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: palette.onSurfaceMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  point,
                                  style: context.text.bodySmall!.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Needs Attention ──────────────────────────────────────────
              if (result.needsAttention.isNotEmpty) ...[
                AppCard(
                  borderColor: AppColors.warning.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'NEEDS ATTENTION',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (final point in result.needsAttention)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: palette.onSurfaceMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  point,
                                  style: context.text.bodySmall!.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Recommended Next Step Card ───────────────────────────────
              AppCard(
                borderColor: palette.primary.withValues(alpha: 0.35),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: palette.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'RECOMMENDED NEXT STEP',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: palette.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      result.recommendedNextStep,
                      style: context.text.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Action Buttons ───────────────────────────────────────────
              if (result.details.isNotEmpty)
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Review Mistakes & Answers'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () {
                    PracticeReviewMistakesSheet.show(
                      context,
                      result: result,
                      initialShowMistakesOnly: result.incorrectCount > 0,
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.sm),

              if (result.topicId != null && topic != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.replay_rounded, size: 18),
                        label: const Text('Revise Topic'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          AppRouter.startContextualFocus(
                            context,
                            duration: const Duration(minutes: 20),
                            subjectId: topic.subjectId,
                            subjectName: subject?.displayName ?? topic.subjectId,
                            topicId: topic.id,
                            chapterId: topic.chapterId,
                            focusTitle: 'Revise ${topic.title}',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: const Text('Plan Practice'),
                        onPressed: () async {
                          final now = DateTime.now();
                          final start = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            now.hour,
                          ).add(Duration(minutes: ((now.minute / 15).ceil() * 15)));
                          final end = start.add(const Duration(minutes: 20));

                          await PlanningBlockController.instance.scheduleTopicBlock(
                            topic.id,
                            start,
                            end,
                            subjectId: topic.subjectId,
                            chapterId: topic.chapterId,
                            customTitle: 'Practice — ${topic.title}',
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Scheduled practice for "${topic.title}" in today\'s plan',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              Row(
                children: [
                  if (topic != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          PracticeModeSelectionSheet.show(
                            context,
                            topic: topic,
                          );
                        },
                      ),
                    ),
                  if (topic != null) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.text.titleSmall!.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
