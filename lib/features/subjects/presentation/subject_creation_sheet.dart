import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/subject.dart';
import '../subject_controller.dart';

/// A premium bottom sheet for creating or editing a [Subject].
///
/// Supports name, short name, description, color and icon selection.
/// Reuses the curated icon catalog from the Subject model.
class SubjectCreationSheet extends StatefulWidget {
  const SubjectCreationSheet({super.key, this.editing});

  final Subject? editing;

  static Future<void> show(BuildContext context, {Subject? editing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubjectCreationSheet(editing: editing),
    );
  }

  @override
  State<SubjectCreationSheet> createState() => _SubjectCreationSheetState();
}

class _SubjectCreationSheetState extends State<SubjectCreationSheet> {
  final _nameCtrl = TextEditingController();
  final _shortNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  int _selectedColor = 0;
  int _selectedIconCodePoint = 0;

  bool _saving = false;

  bool get isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.editing!;
      _nameCtrl.text = e.name;
      _shortNameCtrl.text = e.shortName;
      _descriptionCtrl.text = e.description;
      _selectedColor = e.color;
      _selectedIconCodePoint = e.iconCodePoint;
    } else {
      _selectedColor = Subject.defaultColor;
      _selectedIconCodePoint = Subject.defaultIconCodePoint;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortNameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    if (isEditing) {
      await SubjectController.instance.updateSubject(
        widget.editing!.copyWith(
          name: _nameCtrl.text.trim(),
          shortName: _shortNameCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          color: _selectedColor,
          iconCodePoint: _selectedIconCodePoint,
        ),
      );
    } else {
      await SubjectController.instance.createSubject(
        name: _nameCtrl.text.trim(),
        shortName: _shortNameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        color: _selectedColor,
        iconCodePoint: _selectedIconCodePoint,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Edit subject' : 'New subject',
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
            const SizedBox(height: AppSpacing.md),

            // Name (required)
            TextField(
              controller: _nameCtrl,
              autofocus: !isEditing,
              style: context.text.bodyLarge,
              decoration: _inputDecoration(context, hint: 'Subject name'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Short name (optional)
            TextField(
              controller: _shortNameCtrl,
              style: context.text.bodyMedium,
              decoration: _inputDecoration(
                context,
                hint: 'Short name (e.g. CS, BIO)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Color selector
            Text('Color', style: context.text.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            _ColorSelector(
              selected: _selectedColor,
              onSelected: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: AppSpacing.md),

            // Icon selector
            Text('Icon', style: context.text.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            _IconSelector(
              selected: _selectedIconCodePoint,
              onSelected: (c) => setState(() => _selectedIconCodePoint = c),
            ),
            const SizedBox(height: AppSpacing.md),

            // Description (optional)
            Text('Description (optional)', style: context.text.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 3,
              style: context.text.bodyMedium,
              decoration: _inputDecoration(context, hint: 'Add a description…'),
            ),

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
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        isEditing ? 'Save changes' : 'Create subject',
                        style: context.text.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        borderSide: BorderSide(color: palette.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COLOR SELECTOR
// ══════════════════════════════════════════════════════════════════════════

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  // Forest/emerald/sage tonal scale — subject color choice stays on-brand.
  static const _colors = [
    0xFF123D35, // Deep forest
    0xFF1F5C44, // Deep emerald
    0xFF285C4D, // Forest
    0xFF2E7D5B, // Emerald
    0xFF4F7D68, // Muted green
    0xFF5C6538, // Deep olive
    0xFF6F967F, // Sage
    0xFF7A8450, // Olive
    0xFF8FB49A, // Light sage
    0xFFA9C1AE, // Soft sage
    0xFF3E6A57, // Pine
    0xFF0C2924, // Pine night
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final color = Color(_colors[index]);
          final isSelected = _colors[index] == selected;
          return GestureDetector(
            onTap: () => onSelected(_colors[index]),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? palette.onSurface : Colors.transparent,
                  width: isSelected ? 3 : 0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ICON SELECTOR
// ═══════════════════════════════════════════════════════════════════════════

class _IconSelector extends StatelessWidget {
  const _IconSelector({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Subject.availableIcons.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final icon = Subject.availableIcons[index];
          final isSelected = icon.codePoint == selected;
          return GestureDetector(
            onTap: () => onSelected(icon.codePoint),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.primary.withValues(alpha: 0.15)
                    : palette.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? palette.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? palette.primary : palette.onSurfaceMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}
