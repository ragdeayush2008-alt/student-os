import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_states.dart';
import '../../controller/focus_controller.dart';

/// Distraction Box — Capture and organize off-task thoughts without losing momentum.
class FocusDistractionInboxScreen extends StatefulWidget {
  const FocusDistractionInboxScreen({super.key});

  @override
  State<FocusDistractionInboxScreen> createState() =>
      _FocusDistractionInboxScreenState();
}

class _FocusDistractionInboxScreenState
    extends State<FocusDistractionInboxScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final FocusController _controller = FocusController.instance;
  bool _showResolved = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDataChanged);
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

  void _captureDistraction() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _controller.captureDistraction(text);
    _textCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final unresolved = _controller.unresolvedDistractions;
    final resolved = _controller.resolvedDistractions;
    final palette = AppTheme.colorsOf(context);

    final currentList = _showResolved ? resolved : unresolved;

    return AppScaffold(
      title: 'Distraction Box',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Quick Capture Input ──
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
                      onSubmitted: (_) => _captureDistraction(),
                      decoration: InputDecoration(
                        hintText: 'Capture distracting thought or reminder...',
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
                  onPressed: _captureDistraction,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Capture',
                  style: IconButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Segmented Tab / Filter ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: [
                _TabPill(
                  label: 'Pending (${unresolved.length})',
                  isSelected: !_showResolved,
                  onTap: () => setState(() => _showResolved = false),
                  palette: palette,
                ),
                const SizedBox(width: AppSpacing.sm),
                _TabPill(
                  label: 'Handled (${resolved.length})',
                  isSelected: _showResolved,
                  onTap: () => setState(() => _showResolved = true),
                  palette: palette,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Distractions List ──
          Expanded(
            child: currentList.isEmpty
                ? Center(
                    child: AppEmptyState(
                      title: _showResolved ? 'No handled distractions' : 'Distraction Box is clear',
                      icon: Icons.check_circle_rounded,
                      description: _showResolved
                          ? 'Handled distractions will appear here.'
                          : 'Capture thoughts here so you can stay fully focused.',
                      compact: true,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final d = currentList[index];
                      return Dismissible(
                        key: Key(d.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.lg),
                          color: palette.error.withValues(alpha: 0.15),
                          child: Icon(Icons.delete_outline, color: palette.error),
                        ),
                        onDismissed: (_) => _controller.deleteDistraction(d.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    d.resolved
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: d.resolved ? palette.success : palette.onSurfaceMuted,
                                    size: 22,
                                  ),
                                  tooltip: d.resolved ? 'Mark pending' : 'Mark handled',
                                  onPressed: () {
                                    if (d.resolved) {
                                      _controller.unresolveDistraction(d.id);
                                    } else {
                                      _controller.resolveDistraction(d.id);
                                    }
                                  },
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        d.thought,
                                        style: context.text.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          decoration: d.resolved ? TextDecoration.lineThrough : null,
                                          color: d.resolved ? palette.onSurfaceMuted : palette.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${d.categoryLabel} • ${_relativeTime(d.capturedAt)}',
                                        style: context.text.labelSmall?.copyWith(
                                          color: palette.onSurfaceMuted,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!d.resolved)
                                  IconButton(
                                    icon: const Icon(Icons.add_task_rounded, size: 20),
                                    tooltip: 'Convert to Task',
                                    onPressed: () async {
                                      await _controller.convertDistractionToTask(d.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Converted "${d.thought}" to Task'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: palette.onSurfaceMuted,
                                  ),
                                  tooltip: 'Delete',
                                  onPressed: () => _controller.deleteDistraction(d.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.palette,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary.withValues(alpha: 0.15) : palette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? palette.primary : palette.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? palette.primary : palette.onSurface,
          ),
        ),
      ),
    );
  }
}
