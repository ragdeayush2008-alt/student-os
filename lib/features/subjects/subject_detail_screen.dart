import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart' show AppSpacing;
import '../../core/intelligence/academic_knowledge_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_completion_check.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../../data/models/academic_resource.dart';
import '../../data/models/exam.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/topic.dart';
import '../exams/exam_controller.dart';
import '../exams/widgets/exam_creation_sheet.dart';
import '../knowledge/academic_knowledge_controller.dart';
import '../knowledge/presentation/topic_detail_sheet.dart';
import '../knowledge/presentation/widgets/subject_syllabus_section.dart';
import '../knowledge/topic_practice_controller.dart';
import '../notes/student_note_controller.dart';
import '../resources/resource_controller.dart';
import '../study/study_controller.dart';
import '../tasks/presentation/task_creation_sheet.dart';
import '../tasks/task_controller.dart';
import 'presentation/subject_creation_sheet.dart';
import 'subject_controller.dart';

/// Subject Experience 2.0 — Premium Academic Learning Command Center.
class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    SubjectController.instance.addListener(_onChanged);
    AcademicKnowledgeController.instance.addListener(_onChanged);
    StudyController.instance.addListener(_onChanged);
    TopicPracticeController.instance.addListener(_onChanged);
    ResourceController.instance.addListener(_onChanged);
    StudentNoteController.instance.addListener(_onChanged);
    ExamController.instance.addListener(_onChanged);
    TaskController.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SubjectController.instance.removeListener(_onChanged);
    AcademicKnowledgeController.instance.removeListener(_onChanged);
    StudyController.instance.removeListener(_onChanged);
    TopicPracticeController.instance.removeListener(_onChanged);
    ResourceController.instance.removeListener(_onChanged);
    StudentNoteController.instance.removeListener(_onChanged);
    ExamController.instance.removeListener(_onChanged);
    TaskController.instance.removeListener(_onChanged);
    super.dispose();
  }

  Subject? get _subject =>
      SubjectController.instance.subjectById(widget.subjectId);

  @override
  Widget build(BuildContext context) {
    final subject = _subject;
    if (subject == null) {
      return AppScaffold(
        title: 'Subject',
        onBack: () => Navigator.of(context).pop(),
        body: Center(
          child: Text('Subject not found', style: context.text.bodyLarge),
        ),
      );
    }

    final palette = AppTheme.colorsOf(context);
    final kc = AcademicKnowledgeController.instance;
    final sc = StudyController.instance;
    final pc = TopicPracticeController.instance;
    final ec = ExamController.instance;
    final rc = ResourceController.instance;
    final tc = TaskController.instance;

    final chapters = kc.chaptersForSubject(subject.id);
    final topics = kc.topicsForSubject(subject.id);
    final sessions = sc.sessions;
    final practices = pc.attemptsForSubject(subject.id);
    final exams = ec.examsForSubjectName(subject.name);
    final resources = rc.resourcesForSubject(subject.id);
    final notes = StudentNoteController.instance.notesForSubject(subject.id);
    final tasks = tc.activeTasksForSubject(subject.id);
    final completedTasks = tc.completedTasksForSubject(subject.id);

    final progress = AcademicKnowledgeEngine.assessSubjectProgress(
      subject,
      chapters: chapters,
      topics: topics,
      sessions: sessions,
      exams: ec.exams,
    );

    final recommendedTopic = AcademicKnowledgeEngine.getRecommendedTopicForSubject(
      subject,
      chapters: chapters,
      topics: topics,
      sessions: sessions,
      exams: ec.exams,
    );

    final needsAttentionTopics = AcademicKnowledgeEngine.getNeedsAttentionTopics(
      subject.id,
      topics: topics,
      sessions: sessions,
      practiceAttempts: practices,
    );

    final upcomingExams = exams.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => (a.daysUntilExam ?? 999).compareTo(b.daysUntilExam ?? 999));
    final nextExam = upcomingExams.firstOrNull;

    Color healthColor;
    switch (progress.health) {
      case SubjectHealthState.onTrack:
        healthColor = AppColors.success;
        break;
      case SubjectHealthState.needsAttention:
        healthColor = AppColors.warning;
        break;
      case SubjectHealthState.atRisk:
        healthColor = AppColors.error;
        break;
    }

    return AppScaffold(
      title: subject.name,
      onBack: () => Navigator.of(context).pop(),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Edit subject',
          onPressed: () => SubjectCreationSheet.show(context, editing: subject),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: 'Subject options',
          onSelected: (value) {
            switch (value) {
              case 'archive':
                if (subject.archived) {
                  SubjectController.instance.restoreSubject(subject.id);
                } else {
                  SubjectController.instance.archiveSubject(subject.id);
                }
              case 'delete':
                _confirmDelete(context, subject);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'archive',
              child: Text(subject.archived ? 'Restore' : 'Archive'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. SUBJECT HEADER ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: subject.colorValue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            subject.icon,
                            color: subject.colorValue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subject.name,
                                      style: context.text.titleLarge!.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: healthColor.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      progress.health.label,
                                      style: context.text.labelSmall!.copyWith(
                                        color: healthColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (subject.shortName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subject.shortName,
                                  style: context.text.bodyMedium!.copyWith(
                                    color: palette.onSurfaceMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (subject.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        subject.description,
                        style: context.text.bodyMedium!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: progress.syllabusFraction,
                        backgroundColor:
                            palette.surfaceVariant.withValues(alpha: 0.35),
                        color: subject.colorValue,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          progress.hasSyllabus
                              ? '${progress.syllabusPercentage}% Complete'
                              : 'No curriculum defined',
                          style: context.text.labelSmall!.copyWith(
                            color: palette.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${progress.studiedTopics}/${progress.totalTopics} topics studied',
                          style: context.text.labelSmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. METRICS ROW (Progress, Study, Revision) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.pie_chart_outline_rounded,
                                  size: 16, color: palette.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Progress',
                                style: context.text.labelSmall!.copyWith(
                                  color: palette.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            progress.hasSyllabus
                                ? '${progress.syllabusPercentage}%'
                                : '—',
                            style: context.text.titleMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${progress.studiedTopics} studied',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 11,
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
                          Row(
                            children: [
                              Icon(Icons.timer_outlined,
                                  size: 16, color: palette.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Study Time',
                                style: context.text.labelSmall!.copyWith(
                                  color: palette.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatMinutes(progress.totalStudyMinutes),
                            style: context.text.titleMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Total recorded',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 11,
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
                          Row(
                            children: [
                              Icon(Icons.replay_rounded,
                                  size: 16,
                                  color: progress.needsRevisionTopics > 0
                                      ? AppColors.warning
                                      : palette.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Revision',
                                style: context.text.labelSmall!.copyWith(
                                  color: palette.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            progress.needsRevisionTopics > 0
                                ? '${progress.needsRevisionTopics} due'
                                : 'Up to date',
                            style: context.text.titleMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: progress.needsRevisionTopics > 0
                                  ? AppColors.warning
                                  : palette.onSurface,
                            ),
                          ),
                          Text(
                            progress.studiedTopics > 0
                                ? '${progress.revisionPercentage}% healthy'
                                : 'No debt',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 3. CONTINUE LEARNING HERO BANNER ───────────────────────────
            if (recommendedTopic != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _ContinueLearningCard(
                  subject: subject,
                  topic: recommendedTopic,
                  chapter: kc.chapterById(recommendedTopic.chapterId),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── 4. NEEDS ATTENTION / WEAK TOPICS ───────────────────────────
            if (needsAttentionTopics.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppSectionHeader(
                  title: 'Needs attention',
                  icon: Icons.priority_high_rounded,
                  subtitle: '${needsAttentionTopics.length} topic(s) needing recall or study',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: needsAttentionTopics.take(3).map((prog) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AttentionTopicCard(
                        progress: prog,
                        subject: subject,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── 5. UPCOMING EXAM RELEVANCE ─────────────────────────────────
            if (nextExam != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppSectionHeader(
                  title: 'Upcoming exam',
                  icon: Icons.school_outlined,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _UpcomingExamCard(
                  exam: nextExam,
                  subject: subject,
                  progress: progress,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── 6. SYLLABUS & CHAPTERS ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SubjectSyllabusSection(subject: subject),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── 6.5. KNOWLEDGE & NOTES ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppSectionHeader(
                title: 'Knowledge & Notes',
                icon: Icons.menu_book_rounded,
                subtitle: notes.isNotEmpty ? '${notes.length} notes created' : 'No notes yet',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Note'),
                      onPressed: () => AppRouter.openNoteEditor(
                        context,
                        subjectId: subject.id,
                      ),
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => AppRouter.openKnowledgeCenter(
                          context,
                          initialSubjectId: subject.id,
                        ),
                        child: const Text('View all'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: notes.take(3).map((n) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: AppCard(
                        elevation: 0,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        onTap: () => AppRouter.openNoteDetail(context, n.id),
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, size: 18, color: palette.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title.isEmpty ? 'Untitled Note' : n.title,
                                    style: context.text.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (n.plainText.isNotEmpty)
                                    Text(
                                      n.snippet,
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
                            Icon(Icons.chevron_right_rounded, size: 18, color: palette.onSurfaceMuted),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            // ── 7. RESOURCES ───────────────────────────────────────────────
            if (resources.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppSectionHeader(
                  title: 'Resources',
                  icon: Icons.menu_book_outlined,
                  trailing: resources.length > 4
                      ? TextButton(
                          onPressed: () => AppRouter.openSubjectResources(
                            context,
                            subject.id,
                          ),
                          child: const Text('View all'),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: resources
                      .take(4)
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ResourceListTile(resource: r),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── 8. TASKS ───────────────────────────────────────────────────
            if (tasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppSectionHeader(
                  title: 'Upcoming work',
                  icon: Icons.assignment_rounded,
                  subtitle: completedTasks.isEmpty
                      ? null
                      : '${completedTasks.length} completed',
                  trailing: TextButton(
                    onPressed: () => _viewAllTasks(context, subject.id),
                    child: const Text('View all'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: tasks
                      .take(4)
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _TaskTile(task: t),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Empty workspace hint
            if (resources.isEmpty && tasks.isEmpty && exams.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: palette.onSurfaceMuted,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'No work linked yet. Add a task or exam below to get started.',
                          style: context.text.bodySmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── 9. WORKSPACE QUICK ACTIONS ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppSectionHeader(
                title: 'Add to ${subject.name}',
                icon: Icons.add_rounded,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _CaptureButton(
                      icon: Icons.assignment_rounded,
                      label: 'Task',
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            TaskCreationSheet(initialSubjectId: subject.id),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CaptureButton(
                      icon: Icons.school_outlined,
                      label: 'Exam',
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            ExamCreationSheet(initialSubject: subject.name),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CaptureButton(
                      icon: Icons.timer_outlined,
                      label: 'Focus',
                      onTap: () => _startFocus(context, subject),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CaptureButton(
                      icon: Icons.menu_book_outlined,
                      label: 'Study',
                      onTap: () => AppRouter.openStudy(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewAllTasks(BuildContext context, String subjectId) {
    TaskController.instance.setFilter(TaskFilter(subjectId: subjectId));
    AppRouter.openTasks(context);
  }

  void _startFocus(BuildContext context, Subject subject) {
    AppRouter.openFocusModeSelection(
      context,
      subjectId: subject.id,
      subjectName: subject.displayName,
      focusTitle: subject.displayName,
      suggestedDuration: const Duration(minutes: 35),
    );
  }

  void _confirmDelete(BuildContext context, Subject subject) {
    final linkedTasks = TaskController.instance
        .tasksForSubject(subject.id)
        .length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete subject'),
        content: Text(
          'Delete "${subject.name}"? '
          '${linkedTasks > 0 ? '$linkedTasks task(s) will be kept, but unlinked from this subject. ' : ''}'
          'This cannot be undone.',
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
              Navigator.of(context).pop();
              SubjectController.instance.deleteSubject(subject.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}

// ── Continue Learning Hero Card ──────────────────────────────────────────────

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.subject,
    required this.topic,
    this.chapter,
  });

  final Subject subject;
  final Topic topic;
  final dynamic chapter;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final durationMins =
        topic.estimatedMinutes > 0 ? topic.estimatedMinutes : 35;

    return AppCard(
      color: palette.surface,
      borderColor: palette.primary.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: palette.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'CONTINUE LEARNING',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${durationMins}m',
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  topic.title,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (chapter != null)
                  Text(
                    chapter.title,
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
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: () {
              AppRouter.openFocusModeSelection(
                context,
                suggestedDuration: Duration(minutes: durationMins),
                subjectId: subject.id,
                subjectName: subject.displayName,
                topicId: topic.id,
                topicName: topic.title,
                chapterId: topic.chapterId,
                focusTitle: 'Study ${topic.title}',
              );
            },
            child: const Text('START'),
          ),
        ],
      ),
    );
  }
}

// ── Attention Topic Card ─────────────────────────────────────────────────────

class _AttentionTopicCard extends StatelessWidget {
  const _AttentionTopicCard({
    required this.progress,
    required this.subject,
  });

  final TopicProgress progress;
  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final topic = progress.topic;
    final isRev = progress.isRevisionDue;

    return AppPressable(
      onTap: () => TopicDetailSheet.show(context, topic.id),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Icon(
              isRev ? Icons.replay_rounded : Icons.timelapse_rounded,
              color: isRev ? AppColors.warning : AppColors.secondary,
              size: 20,
            ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isRev
                        ? 'Revision due (${progress.daysSinceStudied}d since study)'
                        : 'In progress (${progress.totalStudyMinutes}m studied)',
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () {
                AppRouter.openFocusModeSelection(
                  context,
                  suggestedDuration: Duration(
                    minutes: topic.estimatedMinutes > 0
                        ? topic.estimatedMinutes
                        : 30,
                  ),
                  subjectId: subject.id,
                  subjectName: subject.displayName,
                  topicId: topic.id,
                  topicName: topic.title,
                  chapterId: topic.chapterId,
                  focusTitle: '${isRev ? "Revise" : "Study"} ${topic.title}',
                );
              },
              child: Text(isRev ? 'Revise' : 'Study'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming Exam Card ───────────────────────────────────────────────────────

class _UpcomingExamCard extends StatelessWidget {
  const _UpcomingExamCard({
    required this.exam,
    required this.subject,
    required this.progress,
  });

  final StudentExam exam;
  final Subject subject;
  final SubjectKnowledgeProgress progress;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final days = exam.daysUntilExam;
    final countdownStr = days == null
        ? 'Date pending'
        : (days == 0 ? 'Today!' : (days == 1 ? 'Tomorrow' : 'in $days days'));

    return AppPressable(
      onTap: () => AppRouter.openExamDetail(context, exam.id),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, color: palette.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    exam.title,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (days != null && days <= 5)
                        ? AppColors.error.withValues(alpha: 0.12)
                        : palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    countdownStr,
                    style: context.text.labelSmall!.copyWith(
                      color: (days != null && days <= 5)
                          ? AppColors.error
                          : palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Syllabus Coverage',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${progress.syllabusPercentage}% covered',
                        style: context.text.labelMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preparation Readiness',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ExamController.instance.readinessLabel(exam),
                        style: context.text.labelMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Resource & Task Subcomponents ───────────────────────────────────────────

class _ResourceListTile extends StatelessWidget {
  const _ResourceListTile({required this.resource});

  final AcademicResource resource;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppPressable(
      onTap: () => AppRouter.openResourceDetail(context, resource.id),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                resource.resourceType.icon,
                color: palette.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (resource.hasTags)
                    Text(
                      resource.tags.take(2).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (resource.isFavorite)
              const Icon(
                Icons.star_rounded,
                color: Color(0xFF1F5C44),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final StudentTask task;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppPressable(
      onTap: () => AppRouter.openTaskDetail(context, task.id),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            AppCompletionCheck(
              completed: task.isCompleted,
              onTap: () {
                if (task.isCompleted) {
                  TaskController.instance.reopenTask(task.id);
                } else {
                  TaskController.instance.completeTask(task.id);
                }
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium!.copyWith(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.dueDate != null)
                    Text(
                      _formatDate(task.dueDate!),
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return '${-diff}d overdue';
    return '${diff}d';
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppPressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: palette.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: context.text.labelMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
