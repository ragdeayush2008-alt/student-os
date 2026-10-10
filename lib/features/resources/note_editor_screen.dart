import 'package:flutter/material.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/academic_resource.dart';
import '../../data/models/subject.dart';
import '../subjects/subject_controller.dart';
import '../exams/exam_controller.dart';
import 'resource_controller.dart' show ResourceController;
import 'widgets/tag_input.dart';

/// Premium Note Editor — a distraction-light writing experience for notes.
///
/// Edits an existing [AcademicResource] where [type == ResourceType.note].
/// Provides title + content editing, tags, subject/exam context,
/// reliable save-on-back with visible state feedback.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, required this.resourceId});

  final String resourceId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  List<String> _tags = [];

  String? _subjectId;
  String? _examId;

  SaveState _saveState = SaveState.idle;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadResource();
  }

  Future<void> _loadResource() async {
    final rc = ResourceController.instance;
    final resource = rc.resources
        .where((r) => r.id == widget.resourceId)
        .firstOrNull;

    if (resource == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    _titleCtrl.text = resource.title;
    _contentCtrl.text = resource.content ?? '';
    _tags = List.of(resource.tags);
    _subjectId = resource.subjectId;
    _examId = resource.examId;

    _titleCtrl.addListener(_markDirty);
    _contentCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
        _saveState = SaveState.idle;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save({bool forced = false}) async {
    if (!_hasUnsavedChanges && !forced) return;

    final rc = ResourceController.instance;
    final resource = rc.resources
        .where((r) => r.id == widget.resourceId)
        .firstOrNull;
    if (resource == null) return;

    setState(() {
      _saveState = SaveState.saving;
    });

    await rc.updateResource(
      resource.copyWith(
        title: _titleCtrl.text.trim().isEmpty
            ? resource.title
            : _titleCtrl.text.trim(),
        content: _contentCtrl.text,
        tags: AcademicResource.normalizeTags(_tags),
        subjectId: _subjectId,
        examId: _examId,
        clearSubjectId: _subjectId == null,
        clearExamId: _examId == null,
      ),
    );

    setState(() {
      _hasUnsavedChanges = false;
      _saveState = SaveState.saved;
    });

    // Show brief saved confirmation, then return to idle.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _saveState = SaveState.idle);
      }
    });
  }

  Future<bool> _onWillPop() async {
    await _save(forced: true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final rc = ResourceController.instance;
    final resource = rc.resources
        .where((r) => r.id == widget.resourceId)
        .firstOrNull;

    if (resource == null) {
      return AppScaffold(
        title: 'Note',
        onBack: () => Navigator.of(context).pop(),
        body: Center(
          child: Text('Note not found', style: context.text.bodyLarge),
        ),
      );
    }

    final sc = SubjectController.instance;
    final ec = ExamController.instance;
    final subject = _subjectId != null ? sc.subjectById(_subjectId!) : null;
    final exam = _examId != null
        ? ec.exams.where((e) => e.id == _examId).firstOrNull
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        await _onWillPop();
        if (!mounted) return;
        navigator.pop();
      },
      child: AppScaffold(
        title: '',
        onBack: () async {
          final navigator = Navigator.of(context);
          await _onWillPop();
          if (!mounted) return;
          navigator.pop();
        },
        actions: [
          _SaveIndicator(
            saveState: _saveState,
            hasUnsavedChanges: _hasUnsavedChanges,
          ),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field (always visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                AppSpacing.xs,
              ),
              child: TextField(
                controller: _titleCtrl,
                style: context.text.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Note title',
                  hintStyle: context.text.headlineMedium!.copyWith(
                    fontWeight: FontWeight.w400,
                    color: palette.onSurfaceMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            // Subtle divider
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Divider(
                height: 1,
                color: palette.outline.withValues(alpha: 0.3),
              ),
            ),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: TextField(
                  controller: _contentCtrl,
                  maxLines: null,
                  expands: true,
                  style: context.text.bodyLarge!.copyWith(height: 1.7),
                  decoration: InputDecoration(
                    hintText: 'Start writing…',
                    hintStyle: context.text.bodyLarge!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
            // Context bar (tags, subject, exam)
            _ContextBar(
              tags: _tags,
              onTagsChanged: (t) => setState(() => _tags = t),
              subjectId: _subjectId,
              examId: _examId,
              onSubjectChanged: (id) => setState(() => _subjectId = id),
              onExamChanged: (id) => setState(() => _examId = id),
              subject: subject,
              exam: exam,
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({
    required this.saveState,
    required this.hasUnsavedChanges,
  });

  final SaveState saveState;
  final bool hasUnsavedChanges;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    Widget child;
    Color color;
    switch (saveState) {
      case SaveState.saving:
        child = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
          ),
        );
        color = palette.primary;
        break;
      case SaveState.saved:
        child = Icon(Icons.check_rounded, size: 16, color: palette.success);
        color = palette.success;
        break;
      default:
        child = Icon(
          hasUnsavedChanges ? Icons.edit_rounded : Icons.check_rounded,
          size: 16,
          color: hasUnsavedChanges ? palette.warning : palette.onSurfaceMuted,
        );
        color = hasUnsavedChanges ? palette.warning : palette.onSurfaceMuted;
    }

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Tooltip(
        message: hasUnsavedChanges
            ? 'Unsaved changes'
            : (saveState == SaveState.saved ? 'Saved' : 'Saved'),
        child: Semantics(
          label: hasUnsavedChanges ? 'Unsaved changes' : 'All changes saved',
          child: IconTheme(
            data: IconThemeData(color: color),
            child: child,
          ),
        ),
      ),
    );
  }
}

enum SaveState { idle, saving, saved }

class _ContextBar extends StatelessWidget {
  const _ContextBar({
    required this.tags,
    required this.onTagsChanged,
    required this.subjectId,
    required this.examId,
    required this.onSubjectChanged,
    required this.onExamChanged,
    required this.subject,
    required this.exam,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final String? subjectId;
  final String? examId;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onExamChanged;
  final Subject? subject;
  final dynamic exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceVariant.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: palette.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Tags
          if (tags.isNotEmpty)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '#$tag',
                        style: context.text.labelSmall!.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          TagInput(tags: tags, onChanged: onTagsChanged),
          // Subject context
          if (subjectId != null || examId != null)
            _ContextPill(
              icon: subject?.icon ?? Icons.book_outlined,
              label: subject?.displayName ?? 'No subject',
              tint: subject?.colorValue ?? palette.primary,
              onTap: () => _pickSubject(context),
            ),
          // Exam context
          if (examId != null)
            _ContextPill(
              icon: Icons.school_rounded,
              label: exam?.title ?? 'No exam',
              tint: palette.primary,
              onTap: () => _pickExam(context),
            ),
        ],
      ),
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
        title: 'Subject',
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
        title: 'Link to exam',
        options: ec.exams
            .map(
              (e) => _PickerOption(
                label: e.title,
                value: e.id,
                icon: Icons.school_rounded,
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) onExamChanged(selected);
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: tint.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tint),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.text.labelSmall!.copyWith(
                color: tint,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.edit_rounded,
              size: 12,
              color: tint.withValues(alpha: 0.7),
            ),
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
