import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/assistant/assistant_launch_context.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/intelligence/academic_intelligence_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_completion_check.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_progress.dart';
import '../../premium/services/premium_gate.dart';
import '../../premium/widgets/premium_widgets.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../data/models/academic_resource.dart';
import '../../../data/models/exam.dart';
import '../../../data/models/task.dart';
import '../../resources/note_editor_screen.dart';
import '../../resources/resource_controller.dart';
import '../../resources/resource_creation_sheet.dart';
import '../../subjects/subject_controller.dart';
import '../../tasks/presentation/task_creation_sheet.dart';
import '../../tasks/task_controller.dart';
import '../exam_controller.dart';
import 'exam_creation_sheet.dart';

/// Premium exam detail experience.
class ExamDetailScreen extends StatefulWidget {
  const ExamDetailScreen({super.key, required this.examId});

  final String examId;

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  final _syllabusCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ExamController.instance.addListener(_onChanged);
    TaskController.instance.addListener(_onChanged);
    ResourceController.instance.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    ExamController.instance.removeListener(_onChanged);
    TaskController.instance.removeListener(_onChanged);
    ResourceController.instance.removeListener(_onChanged);
    _syllabusCtrl.dispose();
    super.dispose();
  }

  StudentExam? get _exam => ExamController.instance.exams
      .where((e) => e.id == widget.examId)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final exam = _exam;
    if (exam == null) {
      return AppScaffold(
        title: 'Exam',
        onBack: () => Navigator.of(context).pop(),
        body: Center(
          child: Text('Exam not found', style: context.text.bodyLarge),
        ),
      );
    }

    final palette = AppTheme.colorsOf(context);

    return AppScaffold(
      title: '',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        if (exam.isUpcoming) ...[
          IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded),
            tooltip: 'Mark completed',
            onPressed: () => _toggleComplete(context, exam),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            tooltip: 'Cancel exam',
            onPressed: () => _toggleCancel(context, exam),
          ),
        ] else if (exam.isCancelled || exam.isCompleted)
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            tooltip: 'Reopen exam',
            onPressed: () => _reopenExam(context, exam),
          ),
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Edit',
          onPressed: () => _editExam(context, exam),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preparation command center
            _PreparationBanner(exam: exam),
            const SizedBox(height: AppSpacing.lg),
            // Status banner
            if (exam.isCompleted)
              _StatusBanner(
                text: 'Completed',
                color: palette.success,
                icon: Icons.check_circle_rounded,
              )
            else if (exam.isCancelled)
              _StatusBanner(
                text: 'Cancelled',
                color: palette.onSurfaceMuted,
                icon: Icons.cancel_rounded,
              ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(exam.title, style: context.text.headlineSmall),

                  // Countdown
                  if (exam.isUpcoming && exam.countdown != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (exam.daysUntilExam != null &&
                                        exam.daysUntilExam! <= 3
                                    ? AppColors.error
                                    : palette.primary)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        exam.countdown!,
                        style: context.text.labelMedium!.copyWith(
                          color:
                              exam.daysUntilExam != null &&
                                  exam.daysUntilExam! <= 3
                              ? AppColors.error
                              : palette.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Metadata
                  if (exam.subject.isNotEmpty)
                    _InfoRow(
                      icon: Icons.book_outlined,
                      label: 'Subject',
                      value: exam.subject,
                    ),
                  if (exam.examDateTime != null)
                    _InfoRow(
                      icon: Icons.event_rounded,
                      label: 'Date & time',
                      value:
                          '${exam.examDateTime!.day}/${exam.examDateTime!.month}/${exam.examDateTime!.year} ${exam.examDateTime!.hour}:${exam.examDateTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  if (exam.notes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _InfoRow(
                      icon: Icons.notes_rounded,
                      label: 'Notes',
                      value: exam.notes,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.sm),

                  // Linked subject workspace (only when the exam subject
                  // matches a real subject).
                  _LinkedSubjectCard(exam: exam),

                  const SizedBox(height: AppSpacing.xl),

                  // Syllabus
                  _SyllabusSection(exam: exam),

                  const SizedBox(height: AppSpacing.xl),

                  // Preparation summary
                  _PreparationSummary(exam: exam),

                  const SizedBox(height: AppSpacing.xl),

                  // Preparation tasks
                  _PreparationTasksSection(exam: exam),

                  const SizedBox(height: AppSpacing.md),

                  // Exam Intelligence (Pro): phased preparation planning.
                  _ExamIntelligenceCard(exam: exam),

                  const SizedBox(height: AppSpacing.xl),

                  // Study material — linked resources
                  _ExamStudyMaterialSection(exam: exam),

                  const SizedBox(height: AppSpacing.xl),

                  // Execution actions
                  _ExamActions(exam: exam),

                  const SizedBox(height: AppSpacing.md),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, exam),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete exam'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  void _editExam(BuildContext context, StudentExam exam) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExamCreationSheet(editing: exam),
    );
  }

  void _toggleComplete(BuildContext context, StudentExam exam) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark completed'),
        content: Text('Mark "${exam.title}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ExamController.instance.completeExam(exam.id);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _toggleCancel(BuildContext context, StudentExam exam) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel exam'),
        content: Text('Cancel "${exam.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ExamController.instance.cancelExam(exam.id);
            },
            child: const Text('Cancel exam'),
          ),
        ],
      ),
    );
  }

  void _reopenExam(BuildContext context, StudentExam exam) {
    ExamController.instance.reopenExam(exam.id);
  }

  void _confirmDelete(BuildContext context, StudentExam exam) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete exam'),
        content: Text(
          'Delete "${exam.title}"? '
          '${exam.hasSyllabus ? "All ${exam.syllabusTotal} syllabus items will also be removed. " : ""}'
          'Linked tasks and study material are kept — only their exam link is removed. '
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
              ExamController.instance.deleteExam(exam.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Linked subject workspace ──────────────────────────────────────────

/// Opens the matching [Subject] workspace when the exam's free-text subject
/// resolves to a real subject (case-insensitive). Renders nothing when there
/// is no match — never fabricates a link.
class _LinkedSubjectCard extends StatelessWidget {
  const _LinkedSubjectCard({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final needle = exam.subject.trim().toLowerCase();
    if (needle.isEmpty) return const SizedBox.shrink();
    final subject = SubjectController.instance.activeSubjects
        .where((s) => s.name.trim().toLowerCase() == needle)
        .firstOrNull;
    if (subject == null) return const SizedBox.shrink();

    return AppPressable(
      onTap: () => AppRouter.openSubjectDetail(context, subject.id),
      semanticLabel: 'Open subject ${subject.name}',
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: subject.colorValue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(subject.icon, size: 15, color: subject.colorValue),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('Subject workspace', style: context.text.bodySmall),
            ),
            Flexible(
              child: Text(
                subject.name,
                style: context.text.labelMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Execution actions ─────────────────────────────────────────────────

/// Study / Focus / Planning / Revision entry points carrying this exam's context.
class _ExamActions extends StatelessWidget {
  const _ExamActions({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: () {
                    final subject = exam.subject.trim();
                    AppRouter.openFocusModeSelection(
                      context,
                      subjectName: subject.isEmpty ? exam.title : subject,
                      examId: exam.id,
                      examTitle: exam.title,
                      focusTitle: 'Study for ${exam.title}',
                      suggestedDuration: const Duration(minutes: 45),
                    );
                  },
                  icon: const Icon(Icons.timer_rounded, size: 18),
                  label: const Text('Start focus'),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => AppRouter.openPlan(context),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Plan Prep'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: () => AppRouter.openRevision(context),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('Revision'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: () {
                    TaskController.instance.setFilter(TaskFilter(examId: exam.id));
                    AppRouter.openTasks(context);
                  },
                  icon: const Icon(Icons.checklist_rounded, size: 16),
                  label: const Text('Tasks'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Status banner ─────────────────────────────────────────────────────

class _PreparationBanner extends StatelessWidget {
  const _PreparationBanner({required this.exam});
  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final pressure = AcademicIntelligenceController.instance.examPressure(exam);
    final urgencyColor = pressure.level.color;

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
                Icon(Icons.school_rounded, size: 20, color: urgencyColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    pressure.level.label,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: urgencyColor,
                    ),
                  ),
                ),
                Text(
                  pressure.daysRemaining == 999
                      ? "No date"
                      : "${pressure.daysRemaining}d left",
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (pressure.reasons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...pressure.reasons.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 4, color: urgencyColor),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          r,
                          style: context.text.bodySmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      ),
                    ],
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: context.text.labelMedium!.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info row ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.onSurfaceMuted),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: context.text.bodySmall),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: context.text.labelMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Syllabus section ──────────────────────────────────────────────────

class _SyllabusSection extends StatefulWidget {
  const _SyllabusSection({required this.exam});

  final StudentExam exam;

  @override
  State<_SyllabusSection> createState() => _SyllabusSectionState();
}

class _SyllabusSectionState extends State<_SyllabusSection> {
  final _syllabusCtrl = TextEditingController();

  @override
  void dispose() {
    _syllabusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final exam = widget.exam;
    final ctrl = ExamController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist_rounded, size: 18, color: palette.primary),
            const SizedBox(width: 6),
            Text(
              'Syllabus${exam.hasSyllabus ? ' (${exam.syllabusCompleted}/${exam.syllabusTotal})' : ''}',
              style: context.text.titleSmall,
            ),
          ],
        ),
        if (exam.hasSyllabus) ...[
          const SizedBox(height: AppSpacing.sm),
          AppLinearProgress(
            value: exam.syllabusProgress,
            height: 6,
            color: exam.allSyllabusComplete ? palette.success : palette.primary,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Existing items
        ...exam.syllabusItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              child: Row(
                children: [
                  AppCompletionCheck(
                    completed: item.completed,
                    onTap: () => ctrl.toggleSyllabusItem(exam.id, item.id),
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.title,
                      style: context.text.bodyMedium!.copyWith(
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.completed
                            ? palette.onSurfaceMuted
                            : palette.onSurface,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ctrl.deleteSyllabusItem(exam.id, item.id),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Add syllabus item
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: palette.onSurfaceMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _syllabusCtrl,
                    style: context.text.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Add topic or chapter',
                      hintStyle: context.text.bodyMedium!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        ctrl.addSyllabusItem(exam.id, value.trim());
                        _syllabusCtrl.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Preparation summary ───────────────────────────────────────────────

class _PreparationSummary extends StatelessWidget {
  const _PreparationSummary({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final ec = ExamController.instance;
    final linked = TaskController.instance.tasksForExam(exam.id);
    final linkedTotal = linked.length;
    final linkedCompleted = linked.where((t) => t.isCompleted).length;
    final readiness = ec.readiness(exam);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: palette.primary),
              const SizedBox(width: 6),
              Text('Preparation', style: context.text.titleSmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  readiness.label,
                  style: context.text.labelSmall!.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (exam.hasSyllabus)
            _SummaryRow(
              label: 'Syllabus',
              value:
                  '${exam.syllabusCompleted} / ${exam.syllabusTotal} complete',
              progress: exam.syllabusProgress,
            ),
          if (linkedTotal > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _SummaryRow(
              label: 'Preparation tasks',
              value: '$linkedCompleted / $linkedTotal complete',
              progress: linkedTotal == 0 ? 0 : linkedCompleted / linkedTotal,
            ),
          ],
          if (readiness.reasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: palette.outline),
            const SizedBox(height: AppSpacing.sm),
            ...readiness.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: palette.onSurfaceMuted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        r,
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: context.text.bodySmall),
            const Spacer(),
            Text(
              value,
              style: context.text.labelMedium!.copyWith(
                color: palette.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppLinearProgress(value: progress, height: 5, color: palette.primary),
      ],
    );
  }
}

// ─── Preparation tasks section ─────────────────────────────────────────

class _PreparationTasksSection extends StatelessWidget {
  const _PreparationTasksSection({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final linked = TaskController.instance.tasksForExam(exam.id);
    final linkedTotal = linked.length;
    final linkedCompleted = linked.where((t) => t.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_outlined, size: 18, color: palette.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Preparation tasks${linkedTotal > 0 ? ' ($linkedCompleted/$linkedTotal)' : ''}',
                style: context.text.titleSmall,
              ),
            ),
            if (linkedTotal > 0)
              TextButton(
                onPressed: () {
                  TaskController.instance.setFilter(
                    TaskFilter(examId: exam.id),
                  );
                  AppRouter.openTasks(context);
                },
                child: const Text('View all'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (linked.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No preparation tasks yet',
                  style: context.text.bodyMedium!.copyWith(
                    color: palette.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Add tasks to track your preparation for this exam.',
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          )
        else
          ...linked.map((task) => _buildTaskRow(context, task)),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _createPreparationTask(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create preparation task'),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.primary,
              side: BorderSide(color: palette.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskRow(BuildContext context, StudentTask task) {
    final palette = AppTheme.colorsOf(context);
    final isCompleted = task.isCompleted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => AppRouter.openTaskDetail(context, task.id),
          child: Row(
            children: [
              AppCompletionCheck(
                completed: isCompleted,
                onTap: () {
                  if (isCompleted) {
                    TaskController.instance.reopenTask(task.id);
                  } else {
                    TaskController.instance.completeTask(task.id);
                  }
                },
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  task.title,
                  style: context.text.bodyMedium!.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? palette.onSurfaceMuted
                        : palette.onSurface,
                  ),
                ),
              ),
              if (task.isOverdue && !isCompleted)
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _createPreparationTask(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskCreationSheet(
        initialExamId: exam.id,
        initialCategory: exam.subject.isEmpty ? null : exam.subject,
      ),
    );
  }
}

// ─── Study material (exam ↔ resources) ─────────────────────────────────

class _ExamStudyMaterialSection extends StatelessWidget {
  const _ExamStudyMaterialSection({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final resources = ResourceController.instance.resourcesForExam(exam.id);
    final hasMaterial = resources.isNotEmpty;

    // Rebuild wrapper already listens to ResourceController via parent state.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Study material',
          subtitle: 'Resources linked to this exam',
          icon: Icons.menu_book_outlined,
          trailing: hasMaterial
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${resources.length}',
                    style: context.text.labelSmall!.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasMaterial)
          _EmptyStudyMaterial(exam: exam)
        else ...[
          ...resources.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ExamResourceTile(resource: r),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (hasMaterial) const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _addStudyMaterial(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add study material'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.primary,
                  side: BorderSide(
                    color: palette.primary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _createExamNote(context),
                icon: const Icon(Icons.sticky_note_2_outlined, size: 18),
                label: const Text('Create exam note'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.primary,
                  side: BorderSide(
                    color: palette.primary.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addStudyMaterial(BuildContext context) {
    ResourceCreationSheet.show(context, ResourceType.document, examId: exam.id);
  }

  Future<void> _createExamNote(BuildContext context) async {
    final navigator = Navigator.of(context);
    final resource = await ResourceController.instance.createResource(
      title: 'Note for ${exam.title}',
      resourceType: ResourceType.note,
      examId: exam.id,
      content: '',
    );
    if (!navigator.mounted) return;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorScreen(resourceId: resource.id),
      ),
    );
  }
}

class _EmptyStudyMaterial extends StatelessWidget {
  const _EmptyStudyMaterial({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 40,
            color: palette.onSurfaceMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No study material yet',
            style: context.text.titleSmall!.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Add notes, links, videos or revision material for this exam.',
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ResourceCreationSheet.show(
                context,
                ResourceType.document,
                examId: exam.id,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add study material'),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.primary,
                side: BorderSide(color: palette.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final resource = await ResourceController.instance.createResource(
                title: 'Note for ${exam.title}',
                resourceType: ResourceType.note,
                examId: exam.id,
                content: '',
              );
              if (!navigator.mounted) return;
              navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => NoteEditorScreen(resourceId: resource.id),
                ),
              );
            },
            icon: const Icon(Icons.sticky_note_2_outlined, size: 18),
            label: const Text('Create exam note'),
            style: TextButton.styleFrom(foregroundColor: palette.primary),
          ),
        ],
      ),
    );
  }
}

class _ExamResourceTile extends StatelessWidget {
  const _ExamResourceTile({required this.resource});

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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        resource.resourceType.icon,
                        size: 12,
                        color: palette.onSurfaceMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        resource.resourceType.label,
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                      if (resource.hasTags) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            resource.tags.take(2).join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () =>
                  ResourceController.instance.toggleFavorite(resource.id),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  resource.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 20,
                  color: resource.isFavorite
                      ? AppColors.streak
                      : palette.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exam Intelligence entry (Pro): phased preparation planning through the
/// Assistant. Free users redirect straight to the Pro page.
class _ExamIntelligenceCard extends StatelessWidget {
  const _ExamIntelligenceCard({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.school_rounded,
              color: palette.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Exam Intelligence',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const PremiumBadge(),
                  ],
                ),
                Text(
                  'Phased preparation built from this exam.',
                  style: context.text.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              if (!PremiumGate.check(
                  context, 'premium.exam.intelligence')) {
                return;
              }
              AppRouter.openAssistant(
                context,
                initialQuery: 'Plan my ${exam.subject} exam',
                launchContext: AssistantLaunchContext(
                  origin: AssistantOrigin.exam,
                  examId: exam.id,
                  examTitle: exam.title,
                ),
              );
            },
            child: const Text('Prepare'),
          ),
        ],
      ),
    );
  }
}
