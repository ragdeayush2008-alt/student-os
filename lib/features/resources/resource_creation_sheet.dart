import 'package:flutter/material.dart';

import '../../core/constants/app_durations.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/academic_resource.dart';
import '../exams/exam_controller.dart';
import '../subjects/subject_controller.dart';
import 'resource_controller.dart';
import 'widgets/tag_input.dart';

/// A progressive resource creation bottom sheet.
///
/// Shows only the fields relevant to the chosen resource type, then optional
/// context (subject, exam, tags, description).
class ResourceCreationSheet extends StatefulWidget {
  const ResourceCreationSheet({
    super.key,
    required this.initialType,
    this.editing,
    this.preselectedSubjectId,
    this.preselectedExamId,
  });

  final ResourceType initialType;
  final AcademicResource? editing;
  final String? preselectedSubjectId;
  final String? preselectedExamId;

  /// Opens the sheet for the given resource type.
  static Future<void> show(
    BuildContext context,
    ResourceType type, {
    AcademicResource? editing,
    String? subjectId,
    String? examId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResourceCreationSheet(
        initialType: type,
        editing: editing,
        preselectedSubjectId: subjectId,
        preselectedExamId: examId,
      ),
    );
  }

  @override
  State<ResourceCreationSheet> createState() => _ResourceCreationSheetState();
}

class _ResourceCreationSheetState extends State<ResourceCreationSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  List<String> _tags = [];

  late ResourceType _type;
  String? _subjectId;
  String? _examId;
  bool _showContext = false;
  bool _saving = false;

  bool get isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _subjectId = widget.preselectedSubjectId;
    _examId = widget.preselectedExamId;
    if (_subjectId != null || _examId != null) {
      _showContext = true;
    }
    if (isEditing) {
      final e = widget.editing!;
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _referenceCtrl.text = e.reference ?? '';
      _contentCtrl.text = e.content ?? '';
      _tags = List.of(e.tags);
      _type = e.resourceType;
      _subjectId = e.subjectId;
      _examId = e.examId;
      if (e.hasSubject ||
          e.hasExam ||
          e.hasTags ||
          e.description.isNotEmpty ||
          e.hasContent) {
        _showContext = true;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _referenceCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_type == ResourceType.link && _referenceCtrl.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    if (isEditing) {
      await ResourceController.instance.updateResource(
        widget.editing!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          resourceType: _type,
          subjectId: _subjectId,
          examId: _examId,
          reference: _referenceCtrl.text.trim().isEmpty
              ? null
              : _referenceCtrl.text.trim(),
          content: _contentCtrl.text,
          tags: _tags,
          clearSubjectId: _subjectId == null,
          clearExamId: _examId == null,
        ),
      );
    } else {
      await ResourceController.instance.createResource(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        resourceType: _type,
        subjectId: _subjectId,
        examId: _examId,
        reference: _referenceCtrl.text.trim().isEmpty
            ? null
            : _referenceCtrl.text.trim(),
        content: _contentCtrl.text,
        tags: _tags,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit resource' : 'Add resource',
                      style: context.text.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (!isEditing) ...[
                const SizedBox(height: AppSpacing.sm),
                _TypeSelector(
                  selected: _type,
                  enabled: true,
                  onSelected: (t) => setState(() => _type = t),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              // Title (always)
              TextField(
                controller: _titleCtrl,
                autofocus: !isEditing,
                style: context.text.bodyLarge,
                decoration: _inputDecoration(
                  context,
                  hint: _type == ResourceType.note
                      ? 'Note title'
                      : 'Resource title',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Type-specific primary field
              if (_requiresReference(_type)) ...[
                TextField(
                  controller: _referenceCtrl,
                  style: context.text.bodyMedium,
                  keyboardType: TextInputType.url,
                  decoration: _inputDecoration(
                    context,
                    hint: _type == ResourceType.link
                        ? 'https://…'
                        : 'Reference or URL',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_type == ResourceType.note) ...[
                TextField(
                  controller: _contentCtrl,
                  maxLines: 6,
                  minLines: 4,
                  style: context.text.bodyMedium,
                  decoration: _inputDecoration(context, hint: 'Start writing…'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              // Toggle context
              if (!_showContext)
                TextButton.icon(
                  onPressed: () => setState(() => _showContext = true),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Add context'),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.onSurfaceMuted,
                    alignment: Alignment.centerLeft,
                  ),
                )
              else ...[
                const SizedBox(height: AppSpacing.md),
                _ContextFields(
                  subjectId: _subjectId,
                  examId: _examId,
                  onSubjectChanged: (id) => setState(() => _subjectId = id),
                  onExamChanged: (id) => setState(() => _examId = id),
                  onHide: () => setState(() => _showContext = false),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Description (optional)', style: context.text.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  style: context.text.bodyMedium,
                  decoration: _inputDecoration(context, hint: 'Notes…'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Tags', style: context.text.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                TagInput(
                  tags: _tags,
                  onChanged: (t) => setState(() => _tags = t),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              // Save button
              SizedBox(
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
                          isEditing ? 'Save changes' : 'Add resource',
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
    );
  }

  bool _requiresReference(ResourceType t) =>
      t == ResourceType.link ||
      t == ResourceType.document ||
      t == ResourceType.video ||
      t == ResourceType.article ||
      t == ResourceType.revision;

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
  }) {
    final palette = AppTheme.colorsOf(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: context.text.bodyMedium!.copyWith(
        color: palette.onSurfaceMuted,
      ),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: palette.outline),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: palette.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// TYPE SELECTOR
// ══════════════════════════════════════════════════════════════════════════

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ResourceType selected;
  final bool enabled;
  final ValueChanged<ResourceType> onSelected;

  static const _types = [
    ResourceType.note,
    ResourceType.link,
    ResourceType.document,
    ResourceType.revision,
    ResourceType.video,
    ResourceType.article,
    ResourceType.other,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final t = _types[index];
          final isSelected = t == selected;
          return GestureDetector(
            onTap: enabled ? () => onSelected(t) : null,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.primary.withValues(alpha: 0.15)
                    : palette.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected ? palette.primary : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    t.icon,
                    size: 16,
                    color: isSelected ? palette.primary : palette.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t.label,
                    style: context.text.labelMedium!.copyWith(
                      color: isSelected ? palette.primary : palette.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CONTEXT FIELDS
// ══════════════════════════════════════════════════════════════════════════

class _ContextFields extends StatelessWidget {
  const _ContextFields({
    required this.subjectId,
    required this.examId,
    required this.onSubjectChanged,
    required this.onExamChanged,
    required this.onHide,
  });

  final String? subjectId;
  final String? examId;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onExamChanged;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final sc = SubjectController.instance;
    final ec = ExamController.instance;
    final subject = subjectId != null ? sc.subjectById(subjectId!) : null;
    final exam = examId != null
        ? ec.exams.where((e) => e.id == examId).firstOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subject', style: context.text.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        _PickerField(
          icon: subject?.icon ?? Icons.book_outlined,
          label: subject?.name ?? 'No subject',
          hint: 'Select a subject',
          trailing: subjectId != null
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () => onSubjectChanged(null),
                )
              : null,
          onTap: () => _pickSubject(context),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Exam (optional)', style: context.text.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        _PickerField(
          icon: Icons.school_outlined,
          label: exam?.title ?? 'No exam',
          hint: 'Link to an exam',
          trailing: examId != null
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () => onExamChanged(null),
                )
              : null,
          onTap: () => _pickExam(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onHide,
            child: const Text('Hide context'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickSubject(BuildContext context) async {
    final sc = SubjectController.instance;
    if (sc.activeSubjects.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ListPickerSheet(
        title: 'Select a subject',
        options: sc.activeSubjects
            .map((s) => _PickerOption(label: s.name, value: s.id, icon: s.icon))
            .toList(),
      ),
    );
    if (selected != null) onSubjectChanged(selected);
  }

  Future<void> _pickExam(BuildContext context) async {
    final ec = ExamController.instance;
    if (ec.exams.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ListPickerSheet(
        title: 'Link to an exam',
        options: ec.exams
            .map(
              (e) => _PickerOption(
                label: e.title,
                value: e.id,
                icon: Icons.school_outlined,
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) onExamChanged(selected);
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: palette.onSurfaceMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label.isEmpty ? hint : label,
                style: context.text.bodyMedium!.copyWith(
                  color: label.isEmpty
                      ? palette.onSurfaceMuted
                      : palette.onSurface,
                ),
              ),
            ),
            trailing ?? const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PickerOption {
  const _PickerOption({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
}

class _ListPickerSheet extends StatelessWidget {
  const _ListPickerSheet({required this.title, required this.options});

  final String title;
  final List<_PickerOption> options;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...options.map(
              (o) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(o.icon, color: palette.primary),
                title: Text(o.label),
                onTap: () => Navigator.of(context).pop(o.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
