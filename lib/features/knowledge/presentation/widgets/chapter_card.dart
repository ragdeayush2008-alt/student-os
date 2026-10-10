import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/intelligence/academic_knowledge_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/chapter.dart';
import '../../../../data/models/subject.dart';
import '../../../../data/models/topic.dart';
import '../../../notes/student_note_controller.dart';
import '../../../study/study_controller.dart';
import '../../../subjects/subject_controller.dart';
import '../../academic_knowledge_controller.dart';
import '../chapter_creation_sheet.dart';
import '../topic_creation_sheet.dart';
import 'topic_tile.dart';

/// Chapter Experience 2.0 — Enhanced Chapter Presentation with Progress & Recommended Action.
class ChapterCard extends StatefulWidget {
  const ChapterCard({
    super.key,
    required this.chapter,
    required this.subjectId,
    this.initiallyExpanded = false,
  });

  final Chapter chapter;
  final String subjectId;
  final bool initiallyExpanded;

  @override
  State<ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<ChapterCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final kc = AcademicKnowledgeController.instance;
    final topics = kc.topicsForChapter(widget.chapter.id);
    final sessions = StudyController.instance.sessions;
    final subject = SubjectController.instance.subjectById(widget.subjectId);
    final chapterNotes = StudentNoteController.instance.notesForChapter(widget.chapter.id);

    final progress = AcademicKnowledgeEngine.assessChapterProgress(
      widget.chapter,
      topics,
      sessions: sessions,
    );

    final recommendedTopic = AcademicKnowledgeEngine.getRecommendedTopicForChapter(
      widget.chapter,
      topics: topics,
      sessions: sessions,
    );

    final isAllComplete =
        progress.totalTopics > 0 && progress.studiedTopics == progress.totalTopics;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isAllComplete) ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Text(
                          widget.chapter.title,
                          style: context.text.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          if (val == 'add_topic') {
                            TopicCreationSheet.show(
                              context,
                              subjectId: widget.subjectId,
                              initialChapterId: widget.chapter.id,
                            );
                          } else if (val == 'edit') {
                            ChapterCreationSheet.show(
                              context,
                              subjectId: widget.subjectId,
                              editing: widget.chapter,
                            );
                          } else if (val == 'delete') {
                            _confirmDeleteChapter(context);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'add_topic',
                            child: Text('Add Topic'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Chapter'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Chapter'),
                          ),
                        ],
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: palette.onSurfaceMuted,
                      ),
                    ],
                  ),
                  if (widget.chapter.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.chapter.description,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.completionFraction,
                            backgroundColor:
                                palette.surfaceVariant.withValues(alpha: 0.3),
                            color: isAllComplete
                                ? AppColors.success
                                : palette.primary,
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '${progress.completionPercentage}%',
                        style: context.text.labelSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isAllComplete
                              ? AppColors.success
                              : palette.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '(${progress.studiedTopics}/${progress.totalTopics})',
                        style: context.text.labelSmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  if (progress.needsRevisionTopics > 0 ||
                      progress.totalStudyMinutes > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (progress.totalStudyMinutes > 0)
                          Text(
                            '${progress.totalStudyMinutes}m studied',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                        if (progress.totalStudyMinutes > 0 &&
                            progress.needsRevisionTopics > 0)
                          Text(
                            ' · ',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                        if (progress.needsRevisionTopics > 0)
                          Text(
                            '${progress.needsRevisionTopics} need revision',
                            style: context.text.bodySmall!.copyWith(
                              color: AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Recommended Next Topic in Chapter
                  if (recommendedTopic != null && !isAllComplete) ...[
                    _ChapterRecommendedRow(
                      topic: recommendedTopic,
                      subject: subject,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // Chapter Notes Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: palette.surfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description_outlined, size: 15, color: palette.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${chapterNotes.length} notes',
                          style: context.text.labelSmall!.copyWith(
                            color: palette.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            AppRouter.openNoteEditor(
                              context,
                              subjectId: widget.subjectId,
                              chapterId: widget.chapter.id,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, size: 14, color: palette.primary),
                                const SizedBox(width: 2),
                                Text(
                                  'Add Note',
                                  style: context.text.labelSmall!.copyWith(
                                    color: palette.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (topics.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'No topics in this chapter yet',
                              style: context.text.bodySmall!.copyWith(
                                color: palette.onSurfaceMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Topic'),
                              onPressed: () {
                                TopicCreationSheet.show(
                                  context,
                                  subjectId: widget.subjectId,
                                  initialChapterId: widget.chapter.id,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ...topics.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TopicTile(topic: t),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Topic to Chapter'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () {
                        TopicCreationSheet.show(
                          context,
                          subjectId: widget.subjectId,
                          initialChapterId: widget.chapter.id,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteChapter(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete chapter'),
        content: Text(
          'Delete "${widget.chapter.title}" and its topics? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              AcademicKnowledgeController.instance
                  .deleteChapter(widget.chapter.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ChapterRecommendedRow extends StatelessWidget {
  const _ChapterRecommendedRow({
    required this.topic,
    this.subject,
  });

  final Topic topic;
  final Subject? subject;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final durationMins =
        topic.estimatedMinutes > 0 ? topic.estimatedMinutes : 30;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: palette.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Recommended: ${topic.title}',
              style: context.text.labelSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              AppRouter.openFocusModeSelection(
                context,
                suggestedDuration: Duration(minutes: durationMins),
                subjectId: topic.subjectId,
                subjectName: subject?.displayName ?? topic.subjectId,
                topicId: topic.id,
                topicName: topic.title,
                chapterId: topic.chapterId,
                focusTitle: 'Study ${topic.title}',
              );
            },
            child: const Text('STUDY'),
          ),
        ],
      ),
    );
  }
}
