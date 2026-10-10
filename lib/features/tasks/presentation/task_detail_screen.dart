import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_progress.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/task.dart';
import '../../exams/exam_controller.dart';
import '../../focus/controller/focus_controller.dart';
import '../../focus/presentation/screens/focus_session_screen.dart';
import '../../planning/controllers/planning_block_controller.dart';
import '../../planning/models/planning_block.dart';
import '../../subjects/subject_controller.dart';
import '../task_controller.dart';
import 'task_creation_sheet.dart';

/// Premium task detail experience — the full control surface for a task.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    TaskController.instance.addListener(_onChanged);
    PlanningBlockController.instance.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    TaskController.instance.removeListener(_onChanged);
    PlanningBlockController.instance.removeListener(_onChanged);
    super.dispose();
  }

  StudentTask? get _task => TaskController.instance.tasks
      .where((t) => t.id == widget.taskId)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) {
      return AppScaffold(
        title: 'Task',
        onBack: () => Navigator.of(context).pop(),
        body: Center(
          child: Text('Task not found', style: context.text.bodyLarge),
        ),
      );
    }

    final palette = AppTheme.colorsOf(context);
    final isCompleted = task.isCompleted;

    return AppScaffold(
      title: '',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Edit',
          onPressed: () => _editTask(context, task),
        ),
        IconButton(
          icon: Icon(
            isCompleted
                ? Icons.replay_rounded
                : Icons.check_circle_outline_rounded,
            color: isCompleted ? palette.warning : palette.success,
          ),
          tooltip: isCompleted ? 'Reopen' : 'Complete',
          onPressed: () => _toggleComplete(task),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner
            if (isCompleted)
              _CompletedBanner(task: task)
            else if (task.isOverdue)
              _OverdueBanner(task: task),

            // Task info
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    task.title,
                    style: context.text.headlineSmall!.copyWith(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: palette.onSurfaceMuted,
                    ),
                  ),

                  // Description
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      task.description,
                      style: context.text.bodyLarge!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Metadata cards
                  _MetadataRow(
                    icon: Icons.flag_rounded,
                    label: 'Priority',
                    value: task.priority.label,
                    color: task.priority.color,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (task.estimatedMinutes > 0) ...[
                    _MetadataRow(
                      icon: Icons.timer_outlined,
                      label: 'Estimated effort',
                      value: '${task.estimatedMinutes} min',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  if (task.scheduledDate != null)
                    _MetadataRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Scheduled',
                      value: _formatDate(task.scheduledDate!),
                    ),
                  if (task.scheduledDate != null)
                    const SizedBox(height: AppSpacing.sm),

                  if (task.dueDate != null)
                    _MetadataRow(
                      icon: Icons.event_rounded,
                      label: 'Due date',
                      value: _formatDate(task.dueDate!),
                      color: task.isOverdue ? AppColors.error : null,
                    ),
                  if (task.dueDate != null)
                    const SizedBox(height: AppSpacing.sm),

                  if (task.category.isNotEmpty)
                    _MetadataRow(
                      icon: Icons.label_outline_rounded,
                      label: 'Category',
                      value: task.category,
                    ),
                  if (task.category.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),

                  if (task.hasRecurrence)
                    _MetadataRow(
                      icon: Icons.repeat_rounded,
                      label: 'Repeats',
                      value: task.recurrence!.frequency.label,
                    ),
                  if (task.hasRecurrence) const SizedBox(height: AppSpacing.sm),

                  if (task.reminderEnabled && task.reminderDateTime != null)
                    _MetadataRow(
                      icon: Icons.notifications_outlined,
                      label: 'Reminder',
                      value: _formatDateTime(task.reminderDateTime!),
                    ),

                  if (task.subjectId != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _LinkedSubjectRow(task: task),
                  ],

                  if (task.examId != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _LinkedExamRow(task: task),
                  ],

                  if (task.goalId != null && task.goalId!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _MetadataRow(
                      icon: Icons.flag_outlined,
                      label: 'Goal',
                      value: task.goalId!,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Scheduled work blocks
                  _ScheduledWorkSection(
                    task: task,
                    onSchedule: () => _openScheduleDialog(task),
                    onReschedule: (block) => _openScheduleDialog(
                      task,
                      existingBlock: block,
                    ),
                    onUnschedule: (blockId) => PlanningBlockController.instance
                        .unscheduleBlock(blockId),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Subtasks
                  if (task.hasSubtasks) ...[
                    _SubtaskDetailSection(task: task),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Created / completed metadata
                  _DetailMetadata(task: task),
                  const SizedBox(height: AppSpacing.xl),

                  // Start focus — real session preserving task context
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _startFocus(context, task),
                      icon: const Icon(Icons.timer_rounded, size: 18),
                      label: const Text('Start focus session'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, task),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete task'),
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

  void _toggleComplete(StudentTask task) {
    if (task.isCompleted) {
      TaskController.instance.reopenTask(task.id);
    } else {
      TaskController.instance.completeTask(task.id);
    }
  }

  void _editTask(BuildContext context, StudentTask task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskCreationSheet(editing: task),
    );
  }

  void _startFocus(BuildContext context, StudentTask task) {
    final subjectName = task.subjectId != null
        ? SubjectController.instance.subjectById(task.subjectId!)?.displayName
        : null;
    final duration = task.estimatedMinutes > 0
        ? Duration(minutes: task.estimatedMinutes)
        : const Duration(minutes: 25);
    AppRouter.openFocusModeSelection(
      context,
      taskId: task.id,
      taskTitle: task.title,
      subjectId: task.subjectId,
      subjectName: subjectName,
      examId: task.examId,
      focusTitle: task.title,
      suggestedDuration: duration,
    );
  }

  Future<void> _openScheduleDialog(
    StudentTask task, {
    PlanningBlock? existingBlock,
  }) async {
    final now = DateTime.now();
    final initialDate = existingBlock?.startAt ??
        task.dueDate ??
        task.scheduledDate ??
        now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null || !mounted) return;

    final initialStartTime = existingBlock != null
        ? TimeOfDay.fromDateTime(existingBlock.startAt)
        : TimeOfDay(hour: now.hour, minute: (now.minute ~/ 15) * 15);
    final pickedStartTime = await showTimePicker(
      context: context,
      initialTime: initialStartTime,
    );
    if (pickedStartTime == null || !mounted) return;

    final startDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedStartTime.hour,
      pickedStartTime.minute,
    );

    final defaultEndMinutes =
        task.estimatedMinutes > 0 ? task.estimatedMinutes : 45;
    final initialEndTime = existingBlock != null
        ? TimeOfDay.fromDateTime(existingBlock.endAt)
        : TimeOfDay.fromDateTime(
            startDateTime.add(Duration(minutes: defaultEndMinutes)),
          );
    final pickedEndTime = await showTimePicker(
      context: context,
      initialTime: initialEndTime,
    );
    if (pickedEndTime == null || !mounted) return;

    var endDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedEndTime.hour,
      pickedEndTime.minute,
    );

    if (!endDateTime.isAfter(startDateTime)) {
      endDateTime = startDateTime.add(const Duration(minutes: 30));
    }

    if (existingBlock != null) {
      await PlanningBlockController.instance.rescheduleBlock(
        existingBlock.id,
        startDateTime,
        endDateTime,
      );
    } else {
      await PlanningBlockController.instance.scheduleBlock(
        task.id,
        startDateTime,
        endDateTime,
      );
    }
  }

  void _confirmDelete(BuildContext context, StudentTask task) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete task'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
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
              TaskController.instance.deleteTask(task.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff < 7) return 'In $diff days';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Completed banner ──────────────────────────────────────────────────

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner({required this.task});

  final StudentTask task;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: palette.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Completed${task.completedAt != null ? ' · ${_formatTime(task.completedAt!)}' : ''}',
              style: context.text.labelMedium!.copyWith(
                color: palette.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Overdue banner ────────────────────────────────────────────────────

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.task});

  final StudentTask task;

  @override
  Widget build(BuildContext context) {
    final daysOverdue = DateTime.now()
        .difference(
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day),
        )
        .inDays;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Overdue by $daysOverdue ${daysOverdue == 1 ? 'day' : 'days'}',
              style: context.text.labelMedium!.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metadata row ──────────────────────────────────────────────────────

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final valueColor = color ?? palette.onSurface;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? palette.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: context.text.bodySmall),
          const Spacer(),
          Text(
            value,
            style: context.text.labelMedium!.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Linked subject row ─────────────────────────────────────────────────

class _LinkedSubjectRow extends StatelessWidget {
  const _LinkedSubjectRow({required this.task});

  final StudentTask task;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subject = SubjectController.instance.subjectById(task.subjectId!);

    final card = AppCard(
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
              color: (subject?.colorValue ?? palette.primary).withValues(
                alpha: 0.15,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              subject?.icon ?? Icons.menu_book_outlined,
              size: 15,
              color: subject?.colorValue ?? palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Subject', style: context.text.bodySmall)),
          Text(
            subject != null ? subject.name : 'Unavailable',
            style: context.text.labelMedium!.copyWith(
              color: subject != null
                  ? palette.onSurface
                  : palette.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subject != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.onSurfaceMuted,
            ),
          ],
        ],
      ),
    );

    if (subject == null) return card;
    return AppPressable(
      onTap: () => AppRouter.openSubjectDetail(context, task.subjectId!),
      child: card,
    );
  }
}

// ─── Linked exam row ────────────────────────────────────────────────────

class _LinkedExamRow extends StatelessWidget {
  const _LinkedExamRow({required this.task});

  final StudentTask task;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final exam = ExamController.instance.exams
        .where((e) => e.id == task.examId)
        .firstOrNull;

    final card = AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(Icons.school_outlined, size: 18, color: palette.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Linked exam', style: context.text.bodySmall)),
          Flexible(
            child: Text(
              exam?.title ?? 'Unknown exam',
              style: context.text.labelMedium!.copyWith(
                color: exam != null
                    ? palette.onSurface
                    : palette.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
          if (exam != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.onSurfaceMuted,
            ),
          ],
        ],
      ),
    );

    if (exam == null) return card;
    return AppPressable(
      onTap: () => AppRouter.openExamDetail(context, task.examId!),
      semanticLabel: 'View exam ${exam.title}',
      child: card,
    );
  }
}

// ─── Subtask detail section ────────────────────────────────────────────

class _SubtaskDetailSection extends StatefulWidget {
  const _SubtaskDetailSection({required this.task});

  final StudentTask task;

  @override
  State<_SubtaskDetailSection> createState() => _SubtaskDetailSectionState();
}

class _SubtaskDetailSectionState extends State<_SubtaskDetailSection> {
  final _subtaskCtrl = TextEditingController();

  @override
  void dispose() {
    _subtaskCtrl.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final title = _subtaskCtrl.text.trim();
    if (title.isEmpty) return;
    TaskController.instance.addSubtask(widget.task.id, title);
    _subtaskCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final task = widget.task;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist_rounded, size: 18, color: palette.primary),
            const SizedBox(width: 6),
            Text('Subtasks', style: context.text.titleSmall),
            const Spacer(),
            Text(
              '${task.subtasksCompleted}/${task.subtaskCount}',
              style: context.text.labelMedium!.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppLinearProgress(
          value: task.subtaskProgress,
          height: 6,
          color: task.allSubtasksComplete ? palette.success : palette.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...task.subtasks.map(
          (sub) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AppPressable(
              onTap: () =>
                  TaskController.instance.toggleSubtask(task.id, sub.id),
              semanticLabel:
                  '${sub.completed ? 'Reopen' : 'Complete'} subtask ${sub.title}',
              child: Row(
                children: [
                  Icon(
                    sub.completed
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 20,
                    color: sub.completed
                        ? palette.success
                        : palette.onSurfaceMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      sub.title,
                      style: context.text.bodyMedium!.copyWith(
                        decoration: sub.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: sub.completed
                            ? palette.onSurfaceMuted
                            : palette.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _subtaskCtrl,
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Add a subtask',
                  hintStyle: context.text.bodyMedium!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(color: palette.outline),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addSubtask(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              color: palette.primary,
              tooltip: 'Add subtask',
              onPressed: _addSubtask,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Detail metadata ───────────────────────────────────────────────────

class _DetailMetadata extends StatelessWidget {
  const _DetailMetadata({required this.task});

  final StudentTask task;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details', style: context.text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Created', value: _formatDate(task.createdAt)),
          if (task.completedAt != null)
            _DetailRow(
              label: 'Completed',
              value: _formatDate(task.completedAt!),
            ),
          _DetailRow(label: 'Last updated', value: _formatDate(task.updatedAt)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.text.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledWorkSection extends StatelessWidget {
  const _ScheduledWorkSection({
    required this.task,
    required this.onSchedule,
    required this.onReschedule,
    required this.onUnschedule,
  });

  final StudentTask task;
  final VoidCallback onSchedule;
  final ValueChanged<PlanningBlock> onReschedule;
  final ValueChanged<String> onUnschedule;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final blocks = PlanningBlockController.instance.blocksForTask(task.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: palette.primary),
            const SizedBox(width: 6),
            Text('Scheduled Work', style: context.text.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: onSchedule,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Schedule'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (blocks.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: palette.onSurfaceMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No scheduled work blocks',
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...blocks.map(
            (block) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      size: 18,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatBlockDate(block.startAt),
                            style: context.text.labelMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_formatTime(block.startAt, context)} – ${_formatTime(block.endAt, context)}',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      tooltip: 'Reschedule',
                      color: palette.onSurfaceMuted,
                      onPressed: () => onReschedule(block),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Unschedule',
                      color: palette.onSurfaceMuted,
                      onPressed: () => onUnschedule(block.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatBlockDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt, BuildContext context) {
    final tod = TimeOfDay.fromDateTime(dt);
    return tod.format(context);
  }
}
