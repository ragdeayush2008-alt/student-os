import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/intelligence/academic_knowledge_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../data/models/topic.dart';
import '../../../study/study_controller.dart';
import '../../../subjects/subject_controller.dart';
import '../../topic_practice_controller.dart';
import '../topic_detail_sheet.dart';

class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.topic,
  });

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final sessions = StudyController.instance.sessions;
    final practices = TopicPracticeController.instance.attemptsForTopic(topic.id);

    final progress = AcademicKnowledgeEngine.assessTopicProgress(
      topic,
      sessions: sessions,
      practiceAttempts: practices,
    );

    Color statusColor;
    IconData statusIcon;
    switch (progress.status) {
      case TopicStatus.notStarted:
        statusColor = palette.onSurfaceMuted.withValues(alpha: 0.6);
        statusIcon = Icons.radio_button_unchecked_rounded;
        break;
      case TopicStatus.inProgress:
        statusColor = AppColors.forest;
        statusIcon = Icons.timelapse_rounded;
        break;
      case TopicStatus.studied:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case TopicStatus.needsRevision:
        statusColor = AppColors.warning;
        statusIcon = Icons.replay_rounded;
        break;
      case TopicStatus.mastered:
        statusColor = AppColors.streak;
        statusIcon = Icons.check_circle_rounded;
        break;
    }

    final subject = SubjectController.instance.subjectById(topic.subjectId);
    final studyDuration = Duration(
      minutes: topic.estimatedMinutes > 0 ? topic.estimatedMinutes : 35,
    );

    return AppPressable(
      onTap: () => TopicDetailSheet.show(context, topic.id),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceVariant.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: palette.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      Text(
                        '${topic.estimatedMinutes}m',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                      if (progress.totalStudyMinutes > 0)
                        Text(
                          '• ${progress.totalStudyMinutes}m studied',
                          style: context.text.bodySmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      if (progress.practiceAttemptsCount > 0)
                        Text(
                          '• ${progress.practiceAttemptsCount} practice${progress.practiceAttemptsCount == 1 ? "" : "s"}',
                          style: context.text.bodySmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      if (progress.isRevisionDue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'Revise',
                            style: context.text.labelSmall!.copyWith(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              iconSize: 22,
              color: palette.primary,
              tooltip: 'Study ${topic.title}',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                AppRouter.openFocusModeSelection(
                  context,
                  suggestedDuration: studyDuration,
                  subjectId: topic.subjectId,
                  subjectName: subject?.displayName ?? topic.subjectId,
                  topicId: topic.id,
                  topicName: topic.title,
                  chapterId: topic.chapterId,
                  focusTitle: 'Study ${topic.title}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
