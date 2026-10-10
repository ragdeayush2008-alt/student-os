import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/exam.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/task.dart';
import '../../exams/exam_controller.dart';
import '../../subjects/subject_controller.dart';
import '../task_controller.dart';

/// A premium bottom sheet for creating or editing a [StudentTask].
///
/// Progressive disclosure: essential fields (title, date, priority) are
/// immediately visible. Optional expansion reveals description, category,
/// subtasks, recurrence, and reminder.
class TaskCreationSheet extends StatefulWidget {
  const TaskCreationSheet({
    super.key,
    this.editing,
    this.initialDueDate,
    this.initialScheduledDate,
    this.initialCategory,
    this.initialExamId,
    this.initialSubjectId,
  });

  final StudentTask? editing;
  final DateTime? initialDueDate;
  final DateTime? initialScheduledDate;
  final String? initialCategory;
  final String? initialExamId;
  final String? initialSubjectId;

  @override
  State<TaskCreationSheet> createState() => _TaskCreationSheetState();
}

class _TaskCreationSheetState extends State<TaskCreationSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _subtaskCtrl = TextEditingController();
  final _effortCtrl = TextEditingController(); // Added
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  DateTime? _scheduledDate;
  bool _showAdvanced = false;
  bool _saving = false;
  String? _examId;
  String? _subjectId;
  String? _goalId; // Added

  // Advanced fields
  RecurrenceFrequency _recurrence = RecurrenceFrequency.none;
  bool _reminderEnabled = false;
  DateTime? _reminderDateTime;
  final List<StudentSubtask> _subtasks = [];

  bool get isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final t = widget.editing!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _categoryCtrl.text = t.category;
      _effortCtrl.text = t.estimatedMinutes > 0 ? t.estimatedMinutes.toString() : ''; // Added
      _priority = t.priority;
      _dueDate = t.dueDate;
      _scheduledDate = t.scheduledDate;
      _recurrence = t.recurrence?.frequency ?? RecurrenceFrequency.none;
      _reminderEnabled = t.reminderEnabled;
      _reminderDateTime = t.reminderDateTime;
      _examId = t.examId;
      _subjectId = t.subjectId;
      _goalId = t.goalId; // Added
      _subtasks.addAll(t.subtasks);
      if (t.description.isNotEmpty ||
          t.hasSubtasks ||
          t.hasRecurrence ||
          t.reminderEnabled ||
          t.category.isNotEmpty ||
          t.examId != null ||
          t.subjectId != null ||
          t.goalId != null ||
          t.estimatedMinutes > 0) { // Added
        _showAdvanced = true;
      }
    } else {
      _dueDate = widget.initialDueDate;
      _scheduledDate = widget.initialScheduledDate;
      _examId = widget.initialExamId;
      _subjectId = widget.initialSubjectId;
      if (widget.initialCategory != null) {
        _categoryCtrl.text = widget.initialCategory!;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _subtaskCtrl.dispose();
    _effortCtrl.dispose(); // Added
    super.dispose();
  }

  bool get _canSave => _titleCtrl.text.trim().isNotEmpty;

  /// Default reminder moment when the switch is on but no time was picked:
  /// due date, else scheduled date, else tomorrow morning. Always visible to
  /// the student after save (detail screen shows the reminder row).
  DateTime _defaultReminderDateTime() {
    final base = _dueDate ?? _scheduledDate;
    if (base != null) return DateTime(base.year, base.month, base.day, 9);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final recurrence = _recurrence != RecurrenceFrequency.none
        ? TaskRecurrence(frequency: _recurrence)
        : null;

    final subjectId =
        _subjectId != null &&
            SubjectController.instance.subjectById(_subjectId!) != null
        ? _subjectId
        : null;
    final examId =
        _examId != null &&
            ExamController.instance.exams.any((e) => e.id == _examId)
        ? _examId
        : null;
    final reminderDateTime = _reminderEnabled
        ? (_reminderDateTime ?? _defaultReminderDateTime())
        : null;
    final estimatedMinutes = int.tryParse(_effortCtrl.text.trim()) ?? 0; // Added

    if (isEditing) {
      await TaskController.instance.updateTask(
        widget.editing!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          scheduledDate: _scheduledDate,
          category: _categoryCtrl.text.trim(),
          clearDueDate: _dueDate == null,
          clearScheduledDate: _scheduledDate == null,
          subtasks: _subtasks,
          recurrence: recurrence,
          clearRecurrence: recurrence == null,
          reminderEnabled: _reminderEnabled,
          reminderDateTime: reminderDateTime,
          clearReminderDateTime: !_reminderEnabled,
          examId: examId,
          clearExamId: examId == null,
          subjectId: subjectId,
          clearSubjectId: subjectId == null,
          goalId: _goalId, // Added
          clearGoalId: _goalId == null, // Added
          estimatedMinutes: estimatedMinutes, // Added
        ),
      );
    } else {
      await TaskController.instance.createTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        scheduledDate: _scheduledDate,
        category: _categoryCtrl.text.trim(),
        subtasks: _subtasks,
        recurrence: recurrence,
        reminderEnabled: _reminderEnabled,
        reminderDateTime: reminderDateTime,
        examId: examId,
        subjectId: subjectId,
        goalId: _goalId, // Added
        estimatedMinutes: estimatedMinutes, // Added
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: palette.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Edit task' : 'New task',
                    style: context.text.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                bottom + AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextField(
                    controller: _titleCtrl,
                    autofocus: !isEditing,
                    style: context.text.bodyLarge,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'What needs to be done?',
                      hintStyle: context.text.bodyLarge!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: palette.outline),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: palette.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Priority
                  Text('Priority', style: context.text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _PrioritySelector(
                    selected: _priority,
                    onChanged: (p) => setState(() => _priority = p),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Estimated effort
                  TextField(
                    controller: _effortCtrl,
                    keyboardType: TextInputType.number,
                    style: context.text.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Estimated effort (minutes)',
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: palette.outline),
                      ),
                    ),
                  ),

                  // Scheduled date
                  _DateRow(
                    label: 'Scheduled',
                    icon: Icons.calendar_today_outlined,
                    date: _scheduledDate,
                    onPick: _pickScheduledDate,
                    onClear: () => setState(() => _scheduledDate = null),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Due date
                  _DateRow(
                    label: 'Due date',
                    icon: Icons.event_rounded,
                    date: _dueDate,
                    onPick: _pickDueDate,
                    onClear: () => setState(() => _dueDate = null),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Subtask quick add
                  if (_subtasks.isNotEmpty || _showAdvanced) ...[
                    _SubtaskSection(
                      subtasks: _subtasks,
                      controller: _subtaskCtrl,
                      onAdd: _addSubtask,
                      onToggle: _toggleSubtask,
                      onDelete: _deleteSubtask,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Show more / less
                  GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showAdvanced
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 20,
                          color: palette.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showAdvanced ? 'Less options' : 'More options',
                          style: context.text.labelMedium!.copyWith(
                            color: palette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Advanced section
                  AnimatedSize(
                    duration: reduceMotion
                        ? Duration.zero
                        : AppDurations.normal,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _showAdvanced
                        ? _AdvancedSection(
                            description: _descCtrl,
                            category: _categoryCtrl,
                            recurrence: _recurrence,
                            onRecurrenceChanged: (r) =>
                                setState(() => _recurrence = r),
                            reminderEnabled: _reminderEnabled,
                            reminderDateTime: _reminderDateTime,
                            onReminderToggle: (v) =>
                                setState(() => _reminderEnabled = v),
                            onReminderTimePick: _pickReminderTime,
                            examId: _examId,
                            exams: ExamController.instance.upcomingExams,
                            onExamChanged: (v) => setState(() => _examId = v),
                            dueDate: _dueDate,
                            subjectId: _subjectId,
                            subjects: SubjectController.instance.activeSubjects,
                            onSubjectChanged: (v) =>
                                setState(() => _subjectId = v),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Save button
                  _SaveButton(
                    canSave: _canSave,
                    saving: _saving,
                    isEditing: isEditing,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addSubtask() {
    final title = _subtaskCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks.add(
        StudentSubtask(
          id: 'sub_${DateTime.now().millisecondsSinceEpoch}_${_subtasks.length}',
          title: title,
        ),
      );
      _subtaskCtrl.clear();
    });
  }

  void _toggleSubtask(int index) {
    setState(() {
      final sub = _subtasks[index];
      _subtasks[index] = sub.copyWith(
        completed: !sub.completed,
        completedAt: !sub.completed ? DateTime.now() : null,
        clearCompletedAt: sub.completed,
      );
    });
  }

  void _deleteSubtask(int index) {
    setState(() => _subtasks.removeAt(index));
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickScheduledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _reminderDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      final timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _reminderDateTime ?? DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      if (timePicked != null) {
        setState(() {
          _reminderDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }
}

// ─── Priority selector ─────────────────────────────────────────────────

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.selected, required this.onChanged});

  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Row(
      children: TaskPriority.values.map((p) {
        final isSelected = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? p.color.withValues(alpha: 0.15)
                    : palette.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected ? p.color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    p.icon,
                    size: 18,
                    color: isSelected ? p.color : palette.onSurfaceMuted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.label,
                    style: context.text.labelSmall!.copyWith(
                      color: isSelected ? p.color : palette.onSurfaceMuted,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Date row ──────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.icon,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final IconData icon;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: palette.onSurfaceMuted),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: context.text.bodyMedium!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
            const Spacer(),
            if (date != null) ...[
              Text(
                '${date!.day}/${date!.month}/${date!.year}',
                style: context.text.bodyMedium!.copyWith(
                  color: palette.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: palette.onSurfaceMuted,
                ),
              ),
            ] else
              Text(
                'Pick a date',
                style: context.text.bodyMedium!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Subtask section ───────────────────────────────────────────────────

class _SubtaskSection extends StatelessWidget {
  const _SubtaskSection({
    required this.subtasks,
    required this.controller,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final List<StudentSubtask> subtasks;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist_rounded, size: 18, color: palette.primary),
            const SizedBox(width: 6),
            Text(
              'Subtasks${subtasks.isNotEmpty ? ' (${subtasks.where((s) => s.completed).length}/${subtasks.length})' : ''}',
              style: context.text.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Existing subtasks
        ...subtasks.asMap().entries.map((entry) {
          final i = entry.key;
          final sub = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onToggle(i),
                  child: Icon(
                    sub.completed
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 20,
                    color: sub.completed
                        ? palette.success
                        : palette.onSurfaceMuted,
                  ),
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
                GestureDetector(
                  onTap: () => onDelete(i),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          );
        }),
        // Add subtask field
        Row(
          children: [
            Icon(Icons.add_rounded, size: 18, color: palette.onSurfaceMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Add subtask',
                  hintStyle: context.text.bodyMedium!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Advanced section ──────────────────────────────────────────────────

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({
    required this.description,
    required this.category,
    required this.recurrence,
    required this.onRecurrenceChanged,
    required this.reminderEnabled,
    required this.reminderDateTime,
    required this.onReminderToggle,
    required this.onReminderTimePick,
    required this.examId,
    required this.exams,
    required this.onExamChanged,
    required this.dueDate,
    required this.subjectId,
    required this.subjects,
    required this.onSubjectChanged,
  });

  final TextEditingController description;
  final TextEditingController category;
  final RecurrenceFrequency recurrence;
  final ValueChanged<RecurrenceFrequency> onRecurrenceChanged;
  final bool reminderEnabled;
  final DateTime? reminderDateTime;
  final ValueChanged<bool> onReminderToggle;
  final VoidCallback onReminderTimePick;
  final String? examId;
  final List<StudentExam> exams;
  final ValueChanged<String?> onExamChanged;
  final DateTime? dueDate;
  final String? subjectId;
  final List<Subject> subjects;
  final ValueChanged<String?> onSubjectChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        // Description
        TextField(
          controller: description,
          maxLines: 2,
          style: context.text.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Description (optional)',
            hintStyle: context.text.bodyMedium!.copyWith(
              color: palette.onSurfaceMuted,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.outline),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Category
        TextField(
          controller: category,
          style: context.text.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Category (optional)',
            hintStyle: context.text.bodyMedium!.copyWith(
              color: palette.onSurfaceMuted,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.outline),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Subject
        Text('Subject', style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        _SubjectSelector(
          subjectId: subjectId,
          subjects: subjects,
          onChanged: onSubjectChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Linked exam
        Text('Linked exam', style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        _ExamLinkSelector(
          examId: examId,
          exams: exams,
          onChanged: onExamChanged,
        ),
        if (examId != null && dueDate != null)
          _examAfterWarning(context, examId!, dueDate!),
        const SizedBox(height: AppSpacing.lg),
        // Recurrence
        Text('Repeat', style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        _RecurrenceSelector(
          selected: recurrence,
          onChanged: onRecurrenceChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Reminder
        Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 20,
              color: palette.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Reminder', style: context.text.labelLarge)),
            Switch(
              value: reminderEnabled,
              onChanged: onReminderToggle,
              activeThumbColor: palette.primary,
            ),
          ],
        ),
        if (reminderEnabled)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: GestureDetector(
              onTap: onReminderTimePick,
              child: Text(
                reminderDateTime != null
                    ? 'Reminder at: ${reminderDateTime!.day}/${reminderDateTime!.month}/${reminderDateTime!.year} ${reminderDateTime!.hour}:${reminderDateTime!.minute.toString().padLeft(2, '0')}'
                    : 'Pick reminder time',
                style: context.text.bodySmall!.copyWith(
                  color: palette.primary,
                  fontWeight: reminderDateTime == null
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Shows a subtle warning when the task's due date is after the linked exam.
  Widget _examAfterWarning(BuildContext context, String examId, DateTime due) {
    final palette = AppTheme.colorsOf(context);
    final exam = exams.where((e) => e.id == examId).firstOrNull;
    if (exam?.examDateTime == null) return const SizedBox.shrink();
    if (!due.isAfter(exam!.examDateTime!)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: palette.onSurfaceMuted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'This task is scheduled after the linked exam.',
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recurrence selector ───────────────────────────────────────────────

class _RecurrenceSelector extends StatelessWidget {
  const _RecurrenceSelector({required this.selected, required this.onChanged});

  final RecurrenceFrequency selected;
  final ValueChanged<RecurrenceFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: RecurrenceFrequency.values.map((f) {
        final isSelected = f == selected;
        return GestureDetector(
          onTap: () => onChanged(f),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? palette.primary.withValues(alpha: 0.15)
                  : palette.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isSelected ? palette.primary : Colors.transparent,
              ),
            ),
            child: Text(
              f.label,
              style: context.text.labelMedium!.copyWith(
                color: isSelected ? palette.primary : palette.onSurfaceMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Save button ───────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.canSave,
    required this.saving,
    required this.isEditing,
    required this.onPressed,
  });

  final bool canSave;
  final bool saving;
  final bool isEditing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (canSave && !saving) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: palette.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
        child: saving
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(palette.onPrimary),
                ),
              )
            : Text(
                isEditing ? 'Save changes' : 'Create task',
                style: context.text.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.onPrimary,
                ),
              ),
      ),
    );
  }
}

// ─── Subject selector ──────────────────────────────────────────────────

class _SubjectSelector extends StatelessWidget {
  const _SubjectSelector({
    required this.subjectId,
    required this.subjects,
    required this.onChanged,
  });

  final String? subjectId;
  final List<Subject> subjects;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final selected = subjects.where((s) => s.id == subjectId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      // Own Material so the ListTile ink effects paint above the
      // container background instead of being hidden by it.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (selected?.colorValue ?? palette.primary).withValues(
                    alpha: 0.15,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected?.icon ?? Icons.menu_book_outlined,
                  size: 17,
                  color: selected?.colorValue ?? palette.onSurfaceMuted,
                ),
              ),
              title: Text(
                selected != null ? selected.name : 'Choose a subject',
                style: context.text.bodyMedium!.copyWith(
                  color: selected != null
                      ? palette.onSurface
                      : palette.onSurfaceMuted,
                ),
              ),
              trailing: subjectId != null
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Clear subject',
                      onPressed: () => onChanged(null),
                    )
                  : const Icon(Icons.expand_more_rounded, size: 20),
              onTap: () => _pickSubject(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSubject(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final p = AppTheme.colorsOf(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Choose a subject',
                  style: sheetContext.text.titleMedium,
                ),
              ),
              if (subjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No subjects yet',
                    textAlign: TextAlign.center,
                    style: sheetContext.text.bodyMedium!.copyWith(
                      color: p.onSurfaceMuted,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: subjects.map((s) {
                      final isSelected = s.id == subjectId;
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: s.colorValue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 17, color: s.colorValue),
                        ),
                        title: Text(s.name),
                        subtitle: s.shortName.isNotEmpty
                            ? Text(
                                s.shortName,
                                style: sheetContext.text.bodySmall!.copyWith(
                                  color: p.onSurfaceMuted,
                                ),
                              )
                            : null,
                        selected: isSelected,
                        trailing: isSelected
                            ? Icon(Icons.check_rounded, color: p.primary)
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(s.id),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }
}

// ─── Exam link selector ─────────────────────────────────────────────────

class _ExamLinkSelector extends StatelessWidget {
  const _ExamLinkSelector({
    required this.examId,
    required this.exams,
    required this.onChanged,
  });

  final String? examId;
  final List<StudentExam> exams;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final selected = exams.where((e) => e.id == examId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      // Own Material so the ListTile ink effects paint above the
      // container background instead of being hidden by it.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              leading: Icon(
                selected != null
                    ? Icons.school_outlined
                    : Icons.school_outlined,
                size: 20,
                color: selected != null
                    ? palette.primary
                    : palette.onSurfaceMuted,
              ),
              title: Text(
                selected != null ? selected.title : 'Link to exam',
                style: context.text.bodyMedium!.copyWith(
                  color: selected != null
                      ? palette.onSurface
                      : palette.onSurfaceMuted,
                ),
              ),
              subtitle: selected != null
                  ? Text(
                      selected.subject.isEmpty
                          ? 'Preparation task'
                          : selected.subject,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    )
                  : null,
              trailing: examId != null
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => onChanged(null),
                    )
                  : const Icon(Icons.expand_more_rounded, size: 20),
              onTap: () => _pickExam(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExam(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final p = AppTheme.colorsOf(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Link to exam',
                  style: sheetContext.text.titleMedium,
                ),
              ),
              if (exams.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No upcoming exams yet',
                    textAlign: TextAlign.center,
                    style: sheetContext.text.bodyMedium!.copyWith(
                      color: p.onSurfaceMuted,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: exams.map((e) {
                      return ListTile(
                        leading: Icon(Icons.school_outlined, color: p.primary),
                        title: Text(e.title),
                        subtitle: Text(
                          e.subject.isEmpty ? 'No subject' : e.subject,
                          style: sheetContext.text.bodySmall!.copyWith(
                            color: p.onSurfaceMuted,
                          ),
                        ),
                        selected: e.id == examId,
                        onTap: () => Navigator.of(sheetContext).pop(e.id),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }
}
