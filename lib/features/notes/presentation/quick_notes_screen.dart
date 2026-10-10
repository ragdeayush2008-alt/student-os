import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_states.dart';
import '../student_note_controller.dart';

/// Quick Notes workspace — Optimized for fast note capture and search.
class QuickNotesScreen extends StatefulWidget {
  const QuickNotesScreen({super.key});

  @override
  State<QuickNotesScreen> createState() => _QuickNotesScreenState();
}

class _QuickNotesScreenState extends State<QuickNotesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final StudentNoteController _controller = StudentNoteController.instance;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDataChanged);
    _controller.load();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _controller.removeListener(_onDataChanged);
    super.dispose();
  }

  void _openCreateNote() {
    AppRouter.openNoteEditor(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final allNotes = _controller.allActiveNotes;
    final pinnedNotes = _controller.pinnedNotes;

    final filteredNotes = _searchQuery.isEmpty
        ? allNotes
        : allNotes.where((n) {
            final titleMatch = n.title.toLowerCase().contains(_searchQuery);
            final contentMatch = n.content.toLowerCase().contains(_searchQuery);
            final tagMatch = n.tags.any((t) => t.toLowerCase().contains(_searchQuery));
            return titleMatch || contentMatch || tagMatch;
          }).toList();

    return AppScaffold(
      title: 'Quick Notes',
      actions: [
        IconButton(
          icon: const Icon(Icons.note_add_outlined),
          tooltip: 'New Note',
          onPressed: _openCreateNote,
        ),
      ],
      body: Column(
        children: [
          // ── Search & Fast Capture Bar ──
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
                      controller: _searchCtrl,
                      style: context.text.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search notes by title, topic or tags...',
                        hintStyle: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: palette.onSurfaceMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
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
                  onPressed: _openCreateNote,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Create Note',
                  style: IconButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Notes List ──
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppEmptyState(
                            title: _searchQuery.isEmpty ? 'No notes captured yet' : 'No matching notes',
                            icon: Icons.note_alt_outlined,
                            description: _searchQuery.isEmpty
                                ? 'Capture thoughts, lecture summaries, or formulas quickly.'
                                : 'Try a different search keyword.',
                            compact: true,
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton.icon(
                              onPressed: _openCreateNote,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Write First Note'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          onTap: () => AppRouter.openNoteDetail(context, note.id),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (note.isPinned) ...[
                                      Icon(Icons.push_pin_rounded, size: 16, color: palette.primary),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        note.title.isNotEmpty ? note.title : 'Untitled Note',
                                        style: context.text.titleSmall!.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(note.updatedAt),
                                      style: context.text.labelSmall!.copyWith(
                                        color: palette.onSurfaceMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                if (note.content.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    note.content,
                                    style: context.text.bodySmall!.copyWith(
                                      color: palette.onSurfaceMuted,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (note.tags.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      for (final tag in note.tags.take(3))
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: palette.surfaceVariant,
                                            borderRadius: BorderRadius.circular(AppRadius.pill),
                                          ),
                                          child: Text(
                                            '#$tag',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              color: palette.onSurfaceMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
