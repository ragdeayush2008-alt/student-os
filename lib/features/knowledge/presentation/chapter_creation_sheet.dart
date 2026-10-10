import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/chapter.dart';
import '../academic_knowledge_controller.dart';

class ChapterCreationSheet extends StatefulWidget {
  const ChapterCreationSheet({
    super.key,
    required this.subjectId,
    this.editing,
  });

  final String subjectId;
  final Chapter? editing;

  static Future<void> show(
    BuildContext context, {
    required String subjectId,
    Chapter? editing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChapterCreationSheet(
        subjectId: subjectId,
        editing: editing,
      ),
    );
  }

  @override
  State<ChapterCreationSheet> createState() => _ChapterCreationSheetState();
}

class _ChapterCreationSheetState extends State<ChapterCreationSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _estMinCtrl = TextEditingController();
  bool _saving = false;

  bool get isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.editing!;
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      if (e.estimatedMinutes != null) {
        _estMinCtrl.text = e.estimatedMinutes.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _estMinCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _titleCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final estMins = int.tryParse(_estMinCtrl.text.trim());

    if (isEditing) {
      await AcademicKnowledgeController.instance.updateChapter(
        widget.editing!.copyWith(
          title: title,
          description: desc,
          estimatedMinutes: estMins,
          clearEstimatedMinutes: estMins == null,
        ),
      );
    } else {
      await AcademicKnowledgeController.instance.createChapter(
        subjectId: widget.subjectId,
        title: title,
        description: desc,
        estimatedMinutes: estMins,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

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
                    isEditing ? 'Edit Chapter' : 'New Chapter',
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
              TextField(
                controller: _titleCtrl,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Chapter title *',
                  hintText: 'e.g. Partnership Accounts',
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
                  hintText: 'Key areas covered in this chapter',
                  filled: true,
                  fillColor: palette.surfaceVariant.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _estMinCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Estimated minutes (optional)',
                  hintText: 'e.g. 120',
                  suffixText: 'min',
                  filled: true,
                  fillColor: palette.surfaceVariant.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
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
                        isEditing ? 'Save Changes' : 'Create Chapter',
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
