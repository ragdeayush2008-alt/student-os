import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/chapter.dart';
import '../../../data/models/topic.dart';
import '../academic_knowledge_controller.dart';

class TopicCreationSheet extends StatefulWidget {
  const TopicCreationSheet({
    super.key,
    required this.subjectId,
    this.initialChapterId,
    this.editing,
  });

  final String subjectId;
  final String? initialChapterId;
  final Topic? editing;

  static Future<void> show(
    BuildContext context, {
    required String subjectId,
    String? initialChapterId,
    Topic? editing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TopicCreationSheet(
        subjectId: subjectId,
        initialChapterId: initialChapterId,
        editing: editing,
      ),
    );
  }

  @override
  State<TopicCreationSheet> createState() => _TopicCreationSheetState();
}

class _TopicCreationSheetState extends State<TopicCreationSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _estMinCtrl = TextEditingController();

  String? _selectedChapterId;
  TopicImportance _selectedImportance = TopicImportance.normal;
  bool _saving = false;

  bool get isEditing => widget.editing != null;

  List<Chapter> get _availableChapters =>
      AcademicKnowledgeController.instance.chaptersForSubject(widget.subjectId);

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.editing!;
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _estMinCtrl.text = e.estimatedMinutes.toString();
      _selectedChapterId = e.chapterId;
      _selectedImportance = e.importance;
    } else {
      _selectedChapterId = widget.initialChapterId ??
          (_availableChapters.isNotEmpty ? _availableChapters.first.id : null);
      _estMinCtrl.text = '35';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _estMinCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleCtrl.text.trim().isNotEmpty &&
      (_selectedChapterId != null && _selectedChapterId!.isNotEmpty);

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final estMins = int.tryParse(_estMinCtrl.text.trim()) ?? 35;

    if (isEditing) {
      await AcademicKnowledgeController.instance.updateTopic(
        widget.editing!.copyWith(
          chapterId: _selectedChapterId,
          title: title,
          description: desc,
          estimatedMinutes: estMins,
          importance: _selectedImportance,
        ),
      );
    } else {
      await AcademicKnowledgeController.instance.createTopic(
        chapterId: _selectedChapterId!,
        subjectId: widget.subjectId,
        title: title,
        description: desc,
        estimatedMinutes: estMins,
        importance: _selectedImportance,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final chapters = _availableChapters;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottom,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Topic' : 'New Topic',
                    style: context.text.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (chapters.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: chapters.any((c) => c.id == _selectedChapterId)
                      ? _selectedChapterId
                      : chapters.first.id,
                  decoration: InputDecoration(
                    labelText: 'Chapter *',
                    filled: true,
                    fillColor: palette.surfaceVariant.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: chapters.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedChapterId = val),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                controller: _titleCtrl,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Topic title *',
                  hintText: 'e.g. Admission of a Partner',
                  filled: true,
                  fillColor: palette.surfaceVariant.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Concepts and sub-topics to understand',
                  filled: true,
                  fillColor: palette.surfaceVariant.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _estMinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Estimated minutes',
                        suffixText: 'min',
                        filled: true,
                        fillColor: palette.surfaceVariant.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Wrap(
                    spacing: 4,
                    children: [20, 35, 45].map((mins) {
                      return ChoiceChip(
                        label: Text('${mins}m'),
                        selected: _estMinCtrl.text == mins.toString(),
                        onSelected: (_) {
                          setState(() => _estMinCtrl.text = mins.toString());
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Importance',
                style: context.text.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                children: TopicImportance.values.map((imp) {
                  final selected = _selectedImportance == imp;
                  return ChoiceChip(
                    label: Text(imp.label),
                    selected: selected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedImportance = imp);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _canSave && !_saving ? _save : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.onPrimary,
                        ),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Create Topic',
                        style: context.text.labelLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.onPrimary,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
