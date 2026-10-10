import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/intelligence/academic_knowledge_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../data/models/topic.dart';
import '../../../data/models/topic_practice_attempt.dart';
import '../../notes/student_note_controller.dart';
import '../../planning/controllers/planning_block_controller.dart';
import '../../resources/resource_controller.dart';
import '../../revision/presentation/revision_session_screen.dart';
import '../../revision/revision_controller.dart';
import '../../revision/widgets/revision_why_sheet.dart';
import '../../study/study_controller.dart';
import '../../subjects/subject_controller.dart';
import '../academic_knowledge_controller.dart';
import '../practice_question_controller.dart';
import '../topic_practice_controller.dart';
import 'practice_mode_selection_sheet.dart';
import 'practice_record_sheet.dart';
import 'question_creation_sheet.dart';
import 'topic_creation_sheet.dart';

/// Topic Experience 2.0 — Topic Learning Workspace.
///
/// Encapsulates the entire Learn → Study → Practice → Revise → Master flow
/// in a structured, actionable workspace.
class TopicDetailSheet extends StatefulWidget {
  const TopicDetailSheet({
    super.key,
    required this.topicId,
  });

  final String topicId;

  static Future<void> show(BuildContext context, String topicId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TopicDetailSheet(topicId: topicId),
    );
  }

  @override
  State<TopicDetailSheet> createState() => _TopicDetailSheetState();
}

class _TopicDetailSheetState extends State<TopicDetailSheet> {
  @override
  void initState() {
    super.initState();
    AcademicKnowledgeController.instance.addListener(_onChanged);
    StudyController.instance.addListener(_onChanged);
    PracticeQuestionController.instance.addListener(_onChanged);
    TopicPracticeController.instance.addListener(_onChanged);
    RevisionController.instance.addListener(_onChanged);
    ResourceController.instance.addListener(_onChanged);
    StudentNoteController.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AcademicKnowledgeController.instance.removeListener(_onChanged);
    StudyController.instance.removeListener(_onChanged);
    PracticeQuestionController.instance.removeListener(_onChanged);
    TopicPracticeController.instance.removeListener(_onChanged);
    RevisionController.instance.removeListener(_onChanged);
    ResourceController.instance.removeListener(_onChanged);
    StudentNoteController.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final topic =
        AcademicKnowledgeController.instance.topicById(widget.topicId);

    if (topic == null) {
      return Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: const SafeArea(
          top: false,
          child: Center(child: Text('Topic not found')),
        ),
      );
    }

    final chapter =
        AcademicKnowledgeController.instance.chapterById(topic.chapterId);
    final subject = SubjectController.instance.subjectById(topic.subjectId);

    final sessions = StudyController.instance.sessions;
    final practiceAttempts =
        TopicPracticeController.instance.attemptsForTopic(topic.id);
    final resources = ResourceController.instance.resourcesForSubject(topic.subjectId);

    final progress = AcademicKnowledgeEngine.assessTopicProgress(
      topic,
      sessions: sessions,
      practiceAttempts: practiceAttempts,
    );

    Color statusColor;
    switch (progress.status) {
      case TopicStatus.notStarted:
        statusColor = palette.onSurfaceMuted;
        break;
      case TopicStatus.inProgress:
        statusColor = AppColors.forest;
        break;
      case TopicStatus.studied:
        statusColor = AppColors.success;
        break;
      case TopicStatus.needsRevision:
        statusColor = AppColors.warning;
        break;
      case TopicStatus.mastered:
        statusColor = AppColors.streak;
        break;
    }

    final studyDuration = topic.estimatedMinutes > 0
        ? Duration(minutes: topic.estimatedMinutes)
        : const Duration(minutes: 35);
    final reviseDuration = Duration(
      minutes: math.max(15, (topic.estimatedMinutes * 0.5).round()),
    );

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

              // ── Breadcrumb & Menu ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${subject?.displayName ?? "Subject"} • ${chapter?.title ?? "Chapter"}',
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (val) {
                      if (val == 'edit') {
                        Navigator.of(context).pop();
                        TopicCreationSheet.show(
                          context,
                          subjectId: topic.subjectId,
                          editing: topic,
                        );
                      } else if (val == 'delete') {
                        _confirmDelete(context, topic);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Topic'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Topic'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Topic Title & Description ─────────────────────────────────
              Text(
                topic.title,
                style: context.text.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (topic.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  topic.description,
                  style: context.text.bodyMedium!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // ── Status Badges ─────────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      progress.status.label,
                      style: context.text.labelSmall!.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Mastery: ${progress.mastery.label}',
                      style: context.text.labelSmall!.copyWith(
                        color: palette.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (topic.importance != TopicImportance.normal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: topic.importance == TopicImportance.critical
                            ? AppColors.error.withValues(alpha: 0.12)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '${topic.importance.label} Importance',
                        style: context.text.labelSmall!.copyWith(
                          color: topic.importance == TopicImportance.critical
                              ? AppColors.error
                              : AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Evidence Metrics Row ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Studied',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${progress.totalStudyMinutes}m',
                            style: context.text.titleMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${progress.sessionsCount} sessions',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Studied',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            progress.daysSinceStudied == 999
                                ? 'Never'
                                : (progress.daysSinceStudied == 0
                                    ? 'Today'
                                    : '${progress.daysSinceStudied}d ago'),
                            style: context.text.titleMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            progress.isRevisionDue ? 'Revision due' : 'Fresh',
                            style: context.text.bodySmall!.copyWith(
                              color: progress.isRevisionDue
                                  ? AppColors.warning
                                  : palette.onSurfaceMuted,
                              fontSize: 10,
                              fontWeight: progress.isRevisionDue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            progress.practiceAttemptsCount > 0
                                ? '${progress.practiceAttemptsCount}'
                                : '0',
                            style: context.text.titleMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            progress.practiceAccuracyPercentage != null
                                ? '${progress.practiceAccuracyPercentage}% acc.'
                                : '${progress.revisionCount} revisions',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── WHAT NEXT? HERO RECOMMENDATION CARD ──────────────────────
              AppCard(
                color: palette.surface,
                borderColor: palette.primary.withValues(alpha: 0.35),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 16, color: palette.primary),
                        const SizedBox(width: 6),
                        Text(
                          'WHAT NEXT?',
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
                      progress.recommendationReason ??
                          'Continue your study flow for ${topic.title}.',
                      style: context.text.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          '${progress.recommendedActionLabel} (${studyDuration.inMinutes}m)',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (progress.isRevisionDue) {
                            AppRouter.startContextualFocus(
                              context,
                              duration: reviseDuration,
                              subjectId: topic.subjectId,
                              subjectName:
                                  subject?.displayName ?? topic.subjectId,
                              topicId: topic.id,
                              chapterId: topic.chapterId,
                              focusTitle: 'Revise ${topic.title}',
                            );
                          } else {
                            AppRouter.openFocusModeSelection(
                              context,
                              suggestedDuration: studyDuration,
                              subjectId: topic.subjectId,
                              subjectName:
                                  subject?.displayName ?? topic.subjectId,
                              topicId: topic.id,
                              topicName: topic.title,
                              chapterId: topic.chapterId,
                              focusTitle: 'Study ${topic.title}',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── PILLAR 1: LEARN ──────────────────────────────────────────
              _PillarHeader(
                title: 'LEARN',
                icon: Icons.menu_book_rounded,
                color: palette.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _ActionRow(
                      icon: Icons.timer_outlined,
                      title: 'Study (${studyDuration.inMinutes}m)',
                      subtitle: 'Launch full focus session',
                      onTap: () {
                        Navigator.of(context).pop();
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
                    const Divider(height: AppSpacing.md),
                    _ActionRow(
                      icon: Icons.calendar_today_rounded,
                      title: 'Schedule into Plan',
                      subtitle: 'Add to today\'s deterministic calendar schedule',
                      onTap: () async {
                        Navigator.of(context).pop();
                        final now = DateTime.now();
                        final start = DateTime(
                                now.year, now.month, now.day, now.hour)
                            .add(Duration(
                                minutes: ((now.minute / 15).ceil() * 15)));
                        final end = start.add(studyDuration);

                        await PlanningBlockController.instance
                            .scheduleTopicBlock(
                          topic.id,
                          start,
                          end,
                          subjectId: topic.subjectId,
                          chapterId: topic.chapterId,
                          customTitle:
                              '${subject?.displayName ?? "Study"} — ${topic.title}',
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Scheduled "${topic.title}" in today\'s plan'),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: AppSpacing.md),
                    _ActionRow(
                      icon: Icons.description_outlined,
                      title: 'Topic Notes (${StudentNoteController.instance.notesForTopic(topic.id).length})',
                      subtitle: StudentNoteController.instance.notesForTopic(topic.id).isNotEmpty
                          ? 'Latest: ${StudentNoteController.instance.notesForTopic(topic.id).first.title}'
                          : 'No notes yet — create one to build concept retention',
                      onTap: () {
                        final notes = StudentNoteController.instance.notesForTopic(topic.id);
                        if (notes.isNotEmpty) {
                          Navigator.of(context).pop();
                          AppRouter.openNoteDetail(context, notes.first.id);
                        } else {
                          Navigator.of(context).pop();
                          AppRouter.openNoteEditor(
                            context,
                            subjectId: topic.subjectId,
                            chapterId: topic.chapterId,
                            topicId: topic.id,
                          );
                        }
                      },
                    ),
                    const Divider(height: AppSpacing.md),
                    _ActionRow(
                      icon: Icons.note_add_outlined,
                      title: 'Add Note for Topic',
                      subtitle: 'Write key definitions, formulas & examples',
                      onTap: () {
                        Navigator.of(context).pop();
                        AppRouter.openNoteEditor(
                          context,
                          subjectId: topic.subjectId,
                          chapterId: topic.chapterId,
                          topicId: topic.id,
                        );
                      },
                    ),
                    if (resources.isNotEmpty) ...[
                      const Divider(height: AppSpacing.md),
                      _ActionRow(
                        icon: Icons.folder_open_rounded,
                        title: 'Resources',
                        subtitle: '${resources.length} study material(s) for this subject',
                        onTap: () {
                          Navigator.of(context).pop();
                          AppRouter.openSubjectResources(
                              context, topic.subjectId);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── PILLAR 2: PRACTICE ───────────────────────────────────────
              _PillarHeader(
                title: 'PRACTICE',
                icon: Icons.quiz_outlined,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.sm),
              Builder(
                builder: (context) {
                  final topicQuestions = PracticeQuestionController.instance
                      .questionsForTopic(topic.id);
                  return AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Practice Attempts (${practiceAttempts.length})',
                              style: context.text.titleSmall!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Record Practice'),
                              onPressed: () {
                                PracticeRecordSheet.show(context, topic);
                              },
                            ),
                          ],
                        ),
                        if (topicQuestions.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          FilledButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              'Start Practice (${topicQuestions.length} questions)',
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              PracticeModeSelectionSheet.show(
                                context,
                                topic: topic,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        if (practiceAttempts.isEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            topicQuestions.isEmpty
                                ? 'No practice questions yet for this topic. Record problem solving or add questions.'
                                : 'No attempts recorded yet for this topic.',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.add_task_rounded,
                                      size: 16),
                                  label: const Text('Record Attempt'),
                                  onPressed: () =>
                                      PracticeRecordSheet.show(context, topic),
                                ),
                              ),
                              if (topicQuestions.isEmpty) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.add_rounded,
                                        size: 16),
                                    label: const Text('Add Questions'),
                                    onPressed: () =>
                                        QuestionCreationSheet.show(
                                      context,
                                      topic: topic,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: AppSpacing.xs),
                          ...practiceAttempts.take(3).map((a) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: _PracticeAttemptRow(attempt: a),
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── PILLAR 3: REVISE ─────────────────────────────────────────
              _PillarHeader(
                title: 'REVISE',
                icon: Icons.replay_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.sm),
              Builder(
                builder: (context) {
                  final schedule =
                      RevisionController.instance.scheduleForTopic(topic.id);
                  final stateLabel = schedule?.state.label ??
                      (progress.isRevisionDue ? 'Due' : 'Learning');

                  return AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progress.isRevisionDue
                                      ? 'Revision Due Now ($stateLabel)'
                                      : 'Retention Up to Date ($stateLabel)',
                                  style: context.text.titleSmall!.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: progress.isRevisionDue
                                        ? AppColors.warning
                                        : palette.onSurface,
                                  ),
                                ),
                                Text(
                                  progress.daysSinceRevised < 900
                                      ? 'Last revised ${progress.daysSinceRevised}d ago • Every ${progress.revisionIntervalDays}d'
                                      : (progress.daysSinceStudied == 999
                                          ? 'Not yet revised'
                                          : 'Last studied ${progress.daysSinceStudied}d ago'),
                                  style: context.text.bodySmall!.copyWith(
                                    color: palette.onSurfaceMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            FilledButton.tonal(
                              onPressed: () {
                                Navigator.of(context).pop();
                                RevisionSessionScreen.open(
                                  context,
                                  topic: topic,
                                  suggestedDurationMinutes:
                                      reviseDuration.inMinutes,
                                );
                              },
                              child: Text('Revise (${reviseDuration.inMinutes}m)'),
                            ),
                          ],
                        ),
                        if (progress.whyReviseReasons.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 14,
                                color: palette.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  progress.whyReviseReasons.first,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: palette.onSurfaceMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  RevisionWhySheet.show(
                                    context,
                                    topic: topic,
                                    reasons: progress.whyReviseReasons,
                                    suggestedDurationMinutes:
                                        reviseDuration.inMinutes,
                                  );
                                },
                                child: Text(
                                  'Why?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: palette.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── PILLAR 4: MASTERY BREAKDOWN ──────────────────────────────
              _PillarHeader(
                title: 'MASTERY BREAKDOWN',
                icon: Icons.star_outline_rounded,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (progress.masteryBreakdown != null)
                _MasteryBreakdownCard(
                  breakdown: progress.masteryBreakdown!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Topic topic) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete topic'),
        content: Text('Delete "${topic.title}"? This cannot be undone.'),
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
              Navigator.of(context).pop();
              AcademicKnowledgeController.instance.deleteTopic(topic.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ───────────────────────────────────────────────────────

class _PillarHeader extends StatelessWidget {
  const _PillarHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: palette.primary, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: palette.onSurfaceMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PracticeAttemptRow extends StatelessWidget {
  const _PracticeAttemptRow({required this.attempt});

  final TopicPracticeAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final durMins = attempt.durationSec ~/ 60;
    final acc = attempt.accuracyPercentage;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 16, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc != null
                      ? '${attempt.correctAnswers}/${attempt.totalQuestions} questions correct ($acc%)'
                      : '${durMins}m practice session',
                  style: context.text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (attempt.notes.isNotEmpty)
                  Text(
                    attempt.notes,
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${durMins}m',
            style: context.text.labelSmall!.copyWith(
              color: palette.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryBreakdownCard extends StatelessWidget {
  const _MasteryBreakdownCard({required this.breakdown});

  final TopicMasteryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _MasteryProgressBar(
            label: 'Learning',
            fraction: breakdown.learningFraction,
            color: palette.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MasteryProgressBar(
            label: 'Practice',
            fraction: breakdown.practiceFraction,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MasteryProgressBar(
            label: 'Revision',
            fraction: breakdown.revisionFraction,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _MasteryProgressBar extends StatelessWidget {
  const _MasteryProgressBar({
    required this.label,
    required this.fraction,
    required this.color,
  });

  final String label;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final pct = (fraction * 100).round().clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: context.text.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            Text(
              '$pct%',
              style: context.text.labelSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: palette.surfaceVariant.withValues(alpha: 0.35),
            color: color,
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
