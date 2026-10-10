import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_states.dart';
import '../../../data/models/checklist_item.dart';
import '../checklist_controller.dart';

/// Lightweight, quick-capture student checklist workspace.
///
/// Decoupled from academic Tasks (does not award XP, does not alter task metrics).
class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ChecklistController _controller = ChecklistController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDataChanged);
    _controller.load();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _controller.removeListener(_onDataChanged);
    super.dispose();
  }

  void _addItem() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _controller.addItem(text);
    _textCtrl.clear();
  }

  void _editItemDialog(ChecklistItem item) {
    final editCtrl = TextEditingController(text: item.title);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Checklist Item'),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Item title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editCtrl.text.trim().isNotEmpty) {
                _controller.editItem(item.id, editCtrl.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final items = _controller.items;
    final pending = _controller.pendingItems;
    final completed = _controller.completedItems;

    return AppScaffold(
      title: 'Quick Checklist',
      actions: [
        if (completed.isNotEmpty)
          TextButton(
            onPressed: () => _controller.clearCompleted(),
            child: Text(
              'Clear Done',
              style: TextStyle(color: palette.primary, fontSize: 13),
            ),
          ),
      ],
      body: Column(
        children: [
          // ── Quick Add Field ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceVariant.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: palette.outline.withValues(alpha: 0.4),
                      ),
                    ),
                    child: TextField(
                      controller: _textCtrl,
                      style: context.text.bodyMedium,
                      onSubmitted: (_) => _addItem(),
                      decoration: InputDecoration(
                        hintText: 'Add quick checklist item...',
                        hintStyle: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Status Bar ──
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Row(
                children: [
                  Text(
                    '${pending.length} pending · ${completed.length} done',
                    style: context.text.labelSmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),

          // ── Checklist List ──
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: AppEmptyState(
                      title: 'No checklist items',
                      icon: Icons.checklist_rounded,
                      description: 'Capture quick reminders or to-dos for today.',
                      compact: true,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.lg),
                          color: palette.error.withValues(alpha: 0.15),
                          child: Icon(Icons.delete_outline, color: palette.error),
                        ),
                        onDismissed: (_) => _controller.deleteItem(item.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isCompleted,
                                  onChanged: (_) => _controller.toggleItem(item.id),
                                  activeColor: palette.primary,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _controller.toggleItem(item.id),
                                    child: Text(
                                      item.title,
                                      style: context.text.bodyMedium!.copyWith(
                                        decoration: item.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: item.isCompleted
                                            ? palette.onSurfaceMuted
                                            : palette.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: palette.onSurfaceMuted,
                                  ),
                                  onPressed: () => _editItemDialog(item),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: palette.onSurfaceMuted,
                                  ),
                                  onPressed: () => _controller.deleteItem(item.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
