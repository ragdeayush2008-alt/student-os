import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/academic_resource.dart';

/// A premium chip-based tag input.
///
/// Tags are typed and committed with `Enter`, a comma, or by clearing focus.
/// Entries are normalized through [AcademicResource.normalizeTags] so casing,
/// whitespace and duplicates are handled consistently with persisted data.
class TagInput extends StatefulWidget {
  const TagInput({super.key, required this.tags, required this.onChanged});

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tryAdd(String raw) {
    final normalized = AcademicResource.normalizeTags([raw]);
    if (normalized.isEmpty) return;
    final tag = normalized.first;
    if (widget.tags.contains(tag)) {
      _controller.clear();
      return;
    }
    widget.onChanged([...widget.tags, tag]);
    _controller.clear();
  }

  void _remove(String tag) {
    widget.onChanged([...widget.tags.where((t) => t != tag)]);
  }

  void _onChanged(String value) {
    // Commit immediately when the user types a trailing comma.
    if (value.endsWith(',')) {
      final raw = value.substring(0, value.length - 1).trim();
      if (raw.isNotEmpty) {
        _tryAdd(raw);
        return;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final tag in widget.tags)
            _TagChip(tag: tag, onRemove: () => _remove(tag)),
          SizedBox(
            width: 120,
            height: 40,
            child: TextField(
              controller: _controller,
              style: context.text.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.tags.isEmpty ? 'Add a tag…' : '',
                hintStyle: context.text.bodyMedium!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              textInputAction: TextInputAction.done,
              onChanged: _onChanged,
              onSubmitted: _tryAdd,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag, required this.onRemove});

  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: context.text.labelMedium!.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 14),
            tooltip: 'Remove tag $tag',
            visualDensity: VisualDensity.compact,
            color: palette.primary,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
