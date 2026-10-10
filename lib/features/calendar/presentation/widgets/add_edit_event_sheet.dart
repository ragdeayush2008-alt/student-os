import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../data/models/academic_calendar_event.dart';
import '../../../subjects/subject_controller.dart';
import '../../academic_schedule_controller.dart';

/// Modal bottom sheet for creating or editing an [AcademicCalendarEvent].
class AddEditEventSheet extends StatefulWidget {
  const AddEditEventSheet({
    super.key,
    this.initialEvent,
    this.initialDate,
    this.initialStartTime,
  });

  final AcademicCalendarEvent? initialEvent;
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;

  @override
  State<AddEditEventSheet> createState() => _AddEditEventSheetState();
}

class _AddEditEventSheetState extends State<AddEditEventSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  late AcademicEventType _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _allDay;
  late bool _isFixed;
  String? _selectedSubjectId;

  AcademicRecurrenceFrequency _recurrenceFrequency =
      AcademicRecurrenceFrequency.none;
  List<int> _selectedDaysOfWeek = [];
  int? _reminderMinutes;
  bool _isSaving = false;

  bool get _isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    final defaultDate = widget.initialDate ?? DateTime.now();

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');

    _selectedType = event?.type ?? AcademicEventType.classSession;
    _selectedDate = event != null
        ? DateTime(event.startAt.year, event.startAt.month, event.startAt.day)
        : DateTime(defaultDate.year, defaultDate.month, defaultDate.day);

    if (event != null) {
      _startTime = TimeOfDay.fromDateTime(event.startAt);
      _endTime = TimeOfDay.fromDateTime(event.endAt);
    } else if (widget.initialStartTime != null) {
      _startTime = widget.initialStartTime!;
      final endHour = (_startTime.hour + 1) % 24;
      _endTime = TimeOfDay(hour: endHour, minute: _startTime.minute);
    } else {
      final now = TimeOfDay.now();
      _startTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
      _endTime = TimeOfDay(hour: (now.hour + 2) % 24, minute: 0);
    }

    _allDay = event?.allDay ?? false;
    _isFixed = event?.isFixed ?? true;
    _selectedSubjectId = event?.subjectId;
    _reminderMinutes = event?.reminderMinutesBefore;

    if (event?.recurrence != null) {
      _recurrenceFrequency = event!.recurrence!.frequency;
      _selectedDaysOfWeek = List.from(event.recurrence!.daysOfWeek);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Adjust end time if needed
        final startMinutes = _startTime.hour * 60 + _startTime.minute;
        final endMinutes = _endTime.hour * 60 + _endTime.minute;
        if (endMinutes <= startMinutes) {
          final newEndHour = (_startTime.hour + 1) % 24;
          _endTime = TimeOfDay(hour: newEndHour, minute: _startTime.minute);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (!_allDay && endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final startAt = _allDay
        ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0)
        : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
            _startTime.hour, _startTime.minute);

    final endAt = _allDay
        ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59)
        : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
            _endTime.hour, _endTime.minute);

    AcademicRecurrenceRule? recurrence;
    if (_recurrenceFrequency != AcademicRecurrenceFrequency.none) {
      recurrence = AcademicRecurrenceRule(
        frequency: _recurrenceFrequency,
        daysOfWeek: _recurrenceFrequency == AcademicRecurrenceFrequency.weekly ||
                _recurrenceFrequency == AcademicRecurrenceFrequency.biweekly
            ? (_selectedDaysOfWeek.isNotEmpty
                ? _selectedDaysOfWeek
                : [_selectedDate.weekday])
            : const [],
      );
    }

    try {
      if (_isEditing) {
        await AcademicScheduleController.instance.updateEvent(
          widget.initialEvent!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          type: _selectedType,
          startAt: startAt,
          endAt: endAt,
          allDay: _allDay,
          location: _locationController.text,
          subjectId: _selectedSubjectId,
          isFixed: _isFixed,
          recurrence: recurrence,
          reminderMinutesBefore: _reminderMinutes,
          clearRecurrence: recurrence == null,
          clearSubjectId: _selectedSubjectId == null,
          clearLocation: _locationController.text.trim().isEmpty,
          clearReminder: _reminderMinutes == null,
        );
      } else {
        await AcademicScheduleController.instance.createEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          type: _selectedType,
          startAt: startAt,
          endAt: endAt,
          allDay: _allDay,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          subjectId: _selectedSubjectId,
          isFixed: _isFixed,
          recurrence: recurrence,
          reminderMinutesBefore: _reminderMinutes,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save event: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? Linked tasks and subjects will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.initialEvent != null) {
      await AcademicScheduleController.instance.deleteEvent(widget.initialEvent!.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subjects = SubjectController.instance.activeSubjects;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Commitment' : 'Add Academic Commitment',
                    style: context.text.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFE53935)),
                      onPressed: _delete,
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Title input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g. Accountancy Class, Physics Lab',
                  prefixIcon: Icon(Icons.title_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Event Type Selector
              Text(
                'Type',
                style: context.text.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AcademicEventType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return ChoiceChip(
                    avatar: Icon(type.icon,
                        size: 16,
                        color: isSelected ? Colors.white : type.color),
                    label: Text(type.label),
                    selected: isSelected,
                    selectedColor: type.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : palette.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Subject linkage (Optional)
              if (subjects.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Linked Subject (Optional)',
                    prefixIcon: Icon(Icons.menu_book_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None / General'),
                    ),
                    ...subjects.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.displayName),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedSubjectId = val),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Date & All-Day Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilterChip(
                    label: const Text('All Day'),
                    selected: _allDay,
                    onSelected: (val) => setState(() => _allDay = val),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Time pickers (if not all day)
              if (!_allDay) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text('Start: ${_startTime.format(context)}'),
                        onPressed: _pickStartTime,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time_filled_rounded,
                            size: 18),
                        label: Text('End: ${_endTime.format(context)}'),
                        onPressed: _pickEndTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Location input
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / Room (Optional)',
                  hintText: 'e.g. Hall 302, Online Zoom',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Recurrence Selector
              DropdownButtonFormField<AcademicRecurrenceFrequency>(
                value: _recurrenceFrequency,
                decoration: const InputDecoration(
                  labelText: 'Repeats',
                  prefixIcon: Icon(Icons.repeat_rounded),
                  border: OutlineInputBorder(),
                ),
                items: AcademicRecurrenceFrequency.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _recurrenceFrequency = val);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Recurrence weekdays selector if Weekly / Biweekly
              if (_recurrenceFrequency == AcademicRecurrenceFrequency.weekly ||
                  _recurrenceFrequency == AcademicRecurrenceFrequency.biweekly) ...[
                Text(
                  'On days:',
                  style: context.text.labelMedium!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  children: [
                    for (int day = 1; day <= 7; day++)
                      FilterChip(
                        label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][day - 1]),
                        selected: _selectedDaysOfWeek.contains(day),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDaysOfWeek.add(day);
                            } else {
                              _selectedDaysOfWeek.remove(day);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Reminder Selector
              DropdownButtonFormField<int?>(
                value: _reminderMinutes,
                decoration: const InputDecoration(
                  labelText: 'Notification Reminder',
                  prefixIcon: Icon(Icons.notifications_active_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('No reminder')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                  DropdownMenuItem(value: 60, child: Text('1 hour before')),
                ],
                onChanged: (val) => setState(() => _reminderMinutes = val),
              ),
              const SizedBox(height: AppSpacing.md),

              // Description input
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Description (Optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Fixed Commitment Notice
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_clock_rounded,
                        size: 18, color: palette.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Fixed Commitment — Student OS Planning Engine will automatically protect this time and plan study around it.',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Save Button
              AppPrimaryButton(
                label: _isSaving
                    ? 'Saving...'
                    : (_isEditing ? 'Update Commitment' : 'Add Commitment'),
                icon: Icons.check_circle_outline_rounded,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
