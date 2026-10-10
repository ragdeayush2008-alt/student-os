import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/intelligence/academic_knowledge_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../data/models/subject.dart';
import '../../../study/study_controller.dart';
import '../../academic_knowledge_controller.dart';
import '../chapter_creation_sheet.dart';
import '../topic_creation_sheet.dart';
import 'chapter_card.dart';

class SubjectSyllabusSection extends StatelessWidget {
  const SubjectSyllabusSection({
    super.key,
    required this.subject,
  });

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final kc = AcademicKnowledgeController.instance;
    final chapters = kc.chaptersForSubject(subject.id);
    final topics = kc.topicsForSubject(subject.id);
    final sessions = StudyController.instance.sessions;

    final progress = AcademicKnowledgeEngine.assessSubjectProgress(
      subject,
      chapters: chapters,
      topics: topics,
      sessions: sessions,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Syllabus & Chapters',
          icon: Icons.auto_stories_rounded,
          subtitle: chapters.isEmpty
              ? null
              : '${chapters.length} chapter${chapters.length == 1 ? "" : "s"} in curriculum',
          trailing: TextButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Chapter'),
            onPressed: () {
              ChapterCreationSheet.show(
                context,
                subjectId: subject.id,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Chapters List
        if (chapters.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 32,
                  color: palette.onSurfaceMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No chapters added yet',
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Organize ${subject.displayName} into chapters and topics for structured learning.',
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add First Chapter'),
                  onPressed: () {
                    ChapterCreationSheet.show(
                      context,
                      subjectId: subject.id,
                    );
                  },
                ),
              ],
            ),
          )
        else ...[
          // Academic Progress summary header
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Academic Progress',
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${progress.studiedTopics}/${progress.totalTopics} topics (${progress.syllabusPercentage}%)',
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...chapters.map(
            (ch) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ChapterCard(
                chapter: ch,
                subjectId: subject.id,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Chapter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () {
                      ChapterCreationSheet.show(
                        context,
                        subjectId: subject.id,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('New Topic'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () {
                      TopicCreationSheet.show(
                        context,
                        subjectId: subject.id,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
