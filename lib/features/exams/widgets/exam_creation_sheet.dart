import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/assistant/assistant_launch_context.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/exam.dart';
import '../../subjects/subject_controller.dart';
import '../exam_controller.dart';

/// Premium bottom sheet for creating or editing an exam.
class ExamCreationSheet extends StatefulWidget {
  const ExamCreationSheet({super.key, this.editing, this.initialSubject});

  final StudentExam? editing;
  final String? initialSubject;

  @override
  State<ExamCreationSheet> createState() => _ExamCreationSheetState();
}

class _ExamCreationSheetState extends State<ExamCreationSheet> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _examDateTime;
  bool _showAdvanced = false;
  bool _saving = false;
  bool _reminder7Days = false;
  bool _reminder3Days = false;
  bool _reminder1Day = false;

  bool get isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.editing!;
      _titleCtrl.text = e.title;
      _subjectCtrl.text = e.subject;
      _notesCtrl.text = e.notes;
      _examDateTime = e.examDateTime;
      _reminder7Days = e.reminder7Days;
      _reminder3Days = e.reminder3Days;
      _reminder1Day = e.reminder1Day;
      if (e.notes.isNotEmpty ||
          e.reminder7Days ||
          e.reminder3Days ||
          e.reminder1Day) {
        _showAdvanced = true;
      }
    } else if (widget.initialSubject != null) {
      _subjectCtrl.text = widget.initialSubject!;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _titleCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final wasCreate = !isEditing;
    final previousDate = widget.editing?.examDateTime;
    final subject = _subjectCtrl.text.trim();
    final title = _titleCtrl.text.trim();

    if (isEditing) {
      await ExamController.instance.updateExam(
        widget.editing!.copyWith(
          title: title,
          subject: subject,
          examDateTime: _examDateTime,
          notes: _notesCtrl.text.trim(),
          clearExamDateTime: _examDateTime == null,
          reminder7Days: _reminder7Days,
          reminder3Days: _reminder3Days,
          reminder1Day: _reminder1Day,
        ),
      );
    } else {
      await ExamController.instance.createExam(
        title: title,
        subject: subject,
        examDateTime: _examDateTime,
        notes: _notesCtrl.text.trim(),
        reminder7Days: _reminder7Days,
        reminder3Days: _reminder3Days,
        reminder1Day: _reminder1Day,
      );
    }

    if (!mounted) return;

    // Offer preparation planning: on create with a date, or when an edit
    // changed the date (existing prep work is never touched).
    final dateChanged = previousDate != _examDateTime &&
        (previousDate?.millisecondsSinceEpoch !=
            _examDateTime?.millisecondsSinceEpoch);
    if (_examDateTime != null && (wasCreate || dateChanged)) {
      // Capture the navigator before popping: this sheet context is
      // unmounted after dismissal, but the navigator stays valid.
      final navigator = Navigator.of(context);
      Navigator.of(context).pop();
      _offerPreparationPlan(navigator, title, subject);
      return;
    }
    Navigator.of(context).pop();
  }

  /// Post-save offer: plan preparation through the Assistant. Never touches
  /// existing prep work.
  void _offerPreparationPlan(
    NavigatorState navigator,
    String title,
    String subject,
  ) {
    final label = subject.isNotEmpty ? subject : title;
    showDialog<void>(
      context: navigator.context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan preparation?'),
        content: const Text(
          'Build a preparation plan for this exam from your real subjects, topics, and available time?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AppRouter.openAssistant(
                navigator.context,
                initialQuery: 'Plan my $label exam',
                launchContext: const AssistantLaunchContext(
                  origin: AssistantOrigin.exam,
                ),
              );
            },
            child: const Text('Plan preparation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: palette.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
                    isEditing ? 'Edit exam' : 'New exam',
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
                  TextField(
                    controller: _titleCtrl,
                    autofocus: !isEditing,
                    style: context.text.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Exam name',
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
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _subjectCtrl,
                    style: context.text.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Subject (optional)',
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
                    onChanged: (_) => setState(() {}),
                  ),
                  _SubjectMatchHint(subjectText: _subjectCtrl.text.trim()),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _pickSubject(context),
                      icon: const Icon(Icons.folder_outlined, size: 16),
                      label: const Text('Choose from my subjects'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Exam date & time', style: context.text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 20,
                            color: palette.onSurfaceMuted,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _examDateTime != null
                                  ? '${_examDateTime!.day}/${_examDateTime!.month}/${_examDateTime!.year}'
                                  : 'Pick date & time',
                              style: context.text.bodyMedium!.copyWith(
                                color: _examDateTime != null
                                    ? palette.onSurface
                                    : palette.onSurfaceMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_examDateTime != null)
                            GestureDetector(
                              onTap: () => setState(() => _examDateTime = null),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: palette.onSurfaceMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_isPastDate)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: palette.warning,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'This date is in the past.',
                              style: context.text.bodySmall!.copyWith(
                                color: palette.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
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
                  AnimatedSize(
                    duration: AppDurations.normal,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _showAdvanced
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _notesCtrl,
                                maxLines: 2,
                                style: context.text.bodyMedium,
                                decoration: InputDecoration(
                                  hintText: 'Notes (optional)',
                                  hintStyle: context.text.bodyMedium!.copyWith(
                                    color: palette.onSurfaceMuted,
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: palette.outline,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: palette.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text('Reminders', style: context.text.labelLarge),
                              const SizedBox(height: AppSpacing.sm),
                              _ReminderToggle(
                                label: '7 days before',
                                value: _reminder7Days,
                                onChanged: (v) =>
                                    setState(() => _reminder7Days = v),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _ReminderToggle(
                                label: '3 days before',
                                value: _reminder3Days,
                                onChanged: (v) =>
                                    setState(() => _reminder3Days = v),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _ReminderToggle(
                                label: '1 day before',
                                value: _reminder1Day,
                                onChanged: (v) =>
                                    setState(() => _reminder1Day = v),
                              ),
                              if (!NotificationService
                                  .instance
                                  .hasPermission) ...[
                                const SizedBox(height: AppSpacing.sm),
                                _PermissionHint(
                                  onRequest: () async {
                                    await NotificationService.instance
                                        .requestPermission();
                                    if (mounted) setState(() {});
                                  },
                                ),
                              ],
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_canSave && !_saving) ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.onPrimary,
                        disabledBackgroundColor: palette.primary.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  palette.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              isEditing ? 'Save changes' : 'Add exam',
                              style: context.text.titleMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.onPrimary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lets the student pick one of their real subjects instead of typing a
  /// free-text name (keeps the free-text field for flexibility; the sheet
  /// still saves whatever is typed).
  Future<void> _pickSubject(BuildContext context) async {
    final subjects = SubjectController.instance.activeSubjects;
    if (subjects.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No subjects yet — type a subject name instead.'),
          ),
        );
      }
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in subjects)
              ListTile(
                leading: Icon(s.icon, color: s.colorValue),
                title: Text(s.name),
                onTap: () => Navigator.of(ctx).pop(s.name),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() => _subjectCtrl.text = picked);
    }
  }

  bool get _isPastDate {
    final dt = _examDateTime;
    if (dt == null) return false;
    final now = DateTime.now();
    return DateTime(
      dt.year,
      dt.month,
      dt.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  Future<void> _pickDateTime() async {
    final datePicked = await showDatePicker(
      context: context,
      initialDate: _examDateTime ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (datePicked != null && mounted) {
      final timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _examDateTime ?? DateTime.now().add(const Duration(hours: 9)),
        ),
      );
      setState(() {
        _examDateTime = DateTime(
          datePicked.year,
          datePicked.month,
          datePicked.day,
          timePicked?.hour ?? 9,
          timePicked?.minute ?? 0,
        );
      });
    }
  }
}

/// Truthful link hint: shows when the typed subject matches one of the
/// student's real subjects (case-insensitive), so they know the exam will
/// appear in that subject's workspace.
class _SubjectMatchHint extends StatelessWidget {
  const _SubjectMatchHint({required this.subjectText});

  final String subjectText;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final needle = subjectText.trim().toLowerCase();
    if (needle.isEmpty) return const SizedBox.shrink();
    final match = SubjectController.instance.activeSubjects
        .where((s) => s.name.trim().toLowerCase() == needle)
        .firstOrNull;
    if (match == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'No matching subject — the exam will use this name as-is.',
          style: context.text.bodySmall!.copyWith(
            color: palette.onSurfaceMuted,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: palette.success),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Linked to subject ${match.name}',
              style: context.text.bodySmall!.copyWith(
                color: palette.success,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  const _ReminderToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              value
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 20,
              color: value ? palette.primary : palette.onSurfaceMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: context.text.bodyMedium!.copyWith(
                  color: value ? palette.onSurface : palette.onSurfaceMuted,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionHint extends StatelessWidget {
  const _PermissionHint({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 18,
            color: palette.onSurfaceMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Notifications are off. Enable to receive exam reminders.',
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
          ),
          SizedBox(
            height: 30,
            child: TextButton(
              onPressed: onRequest,
              child: const Text('Enable'),
            ),
          ),
        ],
      ),
    );
  }
}
