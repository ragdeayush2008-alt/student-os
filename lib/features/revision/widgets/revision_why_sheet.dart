import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/topic.dart';
import '../../planning/controllers/planning_block_controller.dart';
import '../../subjects/subject_controller.dart';
import '../presentation/revision_session_screen.dart';

/// Modal sheet explaining why a topic is recommended for revision in student-friendly language.
class RevisionWhySheet extends StatelessWidget {
  const RevisionWhySheet({
    super.key,
    required this.topic,
    required this.reasons,
    this.suggestedDurationMinutes = 20,
    this.subjectName,
    this.examTitle,
  });

  final Topic topic;
  final List<String> reasons;
  final int suggestedDurationMinutes;
  final String? subjectName;
  final String? examTitle;

  static Future<void> show(
    BuildContext context, {
    required Topic topic,
    required List<String> reasons,
    int suggestedDurationMinutes = 20,
    String? subjectName,
    String? examTitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RevisionWhySheet(
        topic: topic,
        reasons: reasons,
        suggestedDurationMinutes: suggestedDurationMinutes,
        subjectName: subjectName,
        examTitle: examTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subject = SubjectController.instance.subjectById(topic.subjectId);
    final displaySubject = subjectName ?? subject?.displayName ?? 'Curriculum';

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.onSurfaceMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title Header
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 20,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WHY REVISE THIS?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              Text(
                topic.title,
                style: context.text.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                displaySubject,
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Reason Explanations Card
              AppCard(
                borderColor: palette.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Signals & Evidence',
                      style: context.text.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (reasons.isEmpty)
                      Text(
                        '• Spaced repetition interval is ready to maintain long-term memory recall.',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurface,
                        ),
                      )
                    else
                      for (final r in reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✓ ', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  r,
                                  style: context.text.bodySmall!.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: palette.onSurface,
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

              // Recommended Duration Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 16, color: palette.onSurfaceMuted),
                    const SizedBox(width: 8),
                    Text(
                      'Suggested Duration: $suggestedDurationMinutes minutes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Start Revision ($suggestedDurationMinutes min)'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  RevisionSessionScreen.open(
                    context,
                    topic: topic,
                    suggestedDurationMinutes: suggestedDurationMinutes,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: const Text('Schedule into Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final now = DateTime.now();
                  final start = DateTime(now.year, now.month, now.day, now.hour)
                      .add(Duration(minutes: ((now.minute / 15).ceil() * 15)));
                  final end = start.add(Duration(minutes: suggestedDurationMinutes));

                  await PlanningBlockController.instance.scheduleTopicBlock(
                    topic.id,
                    start,
                    end,
                    subjectId: topic.subjectId,
                    chapterId: topic.chapterId,
                    customTitle: 'Revise — ${topic.title}',
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Scheduled revision for "${topic.title}" in today\'s plan'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
