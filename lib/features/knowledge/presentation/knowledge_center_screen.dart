import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/student_note.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/topic.dart';
import '../../notes/presentation/note_detail_screen.dart';
import '../../notes/presentation/note_editor_screen.dart';
import '../../notes/student_note_controller.dart';
import '../../subjects/subject_controller.dart';
import '../academic_knowledge_controller.dart';

enum KnowledgeFilter { all, pinned, recent, subjects, tags, archived }

/// Dedicated Knowledge Center — the personal academic memory layer of Student OS.
class KnowledgeCenterScreen extends StatefulWidget {
  const KnowledgeCenterScreen({
    super.key,
    this.initialSubjectId,
    this.initialTag,
  });

  final String? initialSubjectId;
  final String? initialTag;

  @override
  State<KnowledgeCenterScreen> createState() => _KnowledgeCenterScreenState();
}

class _KnowledgeCenterScreenState extends State<KnowledgeCenterScreen> {
  final _searchController = TextEditingController();
  KnowledgeFilter _activeFilter = KnowledgeFilter.all;
  String? _selectedSubjectId;
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
    _selectedTag = widget.initialTag;
    if (_selectedTag != null) {
      _activeFilter = KnowledgeFilter.tags;
    } else if (_selectedSubjectId != null) {
      _activeFilter = KnowledgeFilter.subjects;
    }

    StudentNoteController.instance.addListener(_onChanged);
    SubjectController.instance.addListener(_onChanged);
    AcademicKnowledgeController.instance.addListener(_onChanged);
    _searchController.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    StudentNoteController.instance.removeListener(_onChanged);
    SubjectController.instance.removeListener(_onChanged);
    AcademicKnowledgeController.instance.removeListener(_onChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateNote({String? subjectId, String? tag}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorScreen(
          initialSubjectId: subjectId ?? _selectedSubjectId,
          initialTags: tag != null ? [tag] : (_selectedTag != null ? [_selectedTag!] : null),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final nc = StudentNoteController.instance;
    final sc = SubjectController.instance;
    final kc = AcademicKnowledgeController.instance;

    final query = _searchController.text.trim();

    // Query results
    List<StudentNote> notes;
    if (query.isNotEmpty) {
      notes = nc.searchNotes(
        query,
        subjectId: _selectedSubjectId,
        tag: _selectedTag,
        includeArchived: _activeFilter == KnowledgeFilter.archived,
      );
    } else {
      switch (_activeFilter) {
        case KnowledgeFilter.all:
          notes = nc.allActiveNotes;
          break;
        case KnowledgeFilter.pinned:
          notes = nc.pinnedNotes;
          break;
        case KnowledgeFilter.recent:
          notes = nc.recentNotes;
          break;
        case KnowledgeFilter.subjects:
          if (_selectedSubjectId != null) {
            notes = nc.notesForSubject(_selectedSubjectId!);
          } else {
            notes = nc.allActiveNotes;
          }
          break;
        case KnowledgeFilter.tags:
          if (_selectedTag != null) {
            notes = nc.notesByTag(_selectedTag!);
          } else {
            notes = nc.allActiveNotes;
          }
          break;
        case KnowledgeFilter.archived:
          notes = nc.archivedNotes;
          break;
      }
    }

    final totalTopics = kc.topics.length;
    final coveredTopicIds = nc.allActiveNotes.where((n) => n.hasTopic).map((n) => n.topicId!).toSet();
    final topicsWithNotes = coveredTopicIds.length;
    final coveragePct = totalTopics > 0 ? ((topicsWithNotes / totalTopics) * 100).round() : 0;

    return AppScaffold(
      title: 'Knowledge',
      actions: [
        IconButton(
          tooltip: 'Add Note',
          icon: const Icon(Icons.note_add_outlined),
          onPressed: () => _openCreateNote(),
        ),
      ],
      body: CustomScrollView(
        slivers: [
          // Search & Filters Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xs,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search TextField
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: palette.outline.withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: context.text.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search notes, topics, subjects, #tags...',
                        hintStyle: context.text.bodyMedium!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: palette.onSurfaceMuted),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Filter Chips Carousel
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All (${nc.activeCount})',
                          isSelected: _activeFilter == KnowledgeFilter.all,
                          onTap: () => setState(() {
                            _activeFilter = KnowledgeFilter.all;
                            _selectedSubjectId = null;
                            _selectedTag = null;
                          }),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: 'Pinned (${nc.pinnedCount})',
                          isSelected: _activeFilter == KnowledgeFilter.pinned,
                          onTap: () => setState(() {
                            _activeFilter = KnowledgeFilter.pinned;
                            _selectedSubjectId = null;
                            _selectedTag = null;
                          }),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: 'Recent',
                          isSelected: _activeFilter == KnowledgeFilter.recent,
                          onTap: () => setState(() {
                            _activeFilter = KnowledgeFilter.recent;
                            _selectedSubjectId = null;
                            _selectedTag = null;
                          }),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: 'Subjects',
                          isSelected: _activeFilter == KnowledgeFilter.subjects,
                          onTap: () => setState(() {
                            _activeFilter = KnowledgeFilter.subjects;
                            _selectedTag = null;
                          }),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: 'Tags (${nc.allTags.length})',
                          isSelected: _activeFilter == KnowledgeFilter.tags,
                          onTap: () => setState(() {
                            _activeFilter = KnowledgeFilter.tags;
                            _selectedSubjectId = null;
                          }),
                        ),
                        if (nc.archivedCount > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _FilterChip(
                            label: 'Archived (${nc.archivedCount})',
                            isSelected: _activeFilter == KnowledgeFilter.archived,
                            onTap: () => setState(() {
                              _activeFilter = KnowledgeFilter.archived;
                              _selectedSubjectId = null;
                              _selectedTag = null;
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Secondary filter bar for Subjects or Tags
          if (_activeFilter == KnowledgeFilter.subjects && sc.activeSubjects.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  children: [
                    _SubFilterChip(
                      label: 'All Subjects',
                      isSelected: _selectedSubjectId == null,
                      onTap: () => setState(() => _selectedSubjectId = null),
                    ),
                    ...sc.activeSubjects.map((s) {
                      final count = nc.notesForSubject(s.id).length;
                      return Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: _SubFilterChip(
                          label: '${s.displayName} ($count)',
                          isSelected: _selectedSubjectId == s.id,
                          color: s.colorValue,
                          onTap: () => setState(() => _selectedSubjectId = s.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          if (_activeFilter == KnowledgeFilter.tags && nc.allTags.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  children: [
                    _SubFilterChip(
                      label: 'All Tags',
                      isSelected: _selectedTag == null,
                      onTap: () => setState(() => _selectedTag = null),
                    ),
                    ...nc.allTags.map((t) {
                      final count = nc.notesByTag(t).length;
                      return Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: _SubFilterChip(
                          label: '#$t ($count)',
                          isSelected: _selectedTag == t,
                          onTap: () => setState(() => _selectedTag = t),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Knowledge Coverage Summary Card (shown when not searching)
          if (query.isEmpty && _activeFilter == KnowledgeFilter.all && nc.hasNotes)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.xs),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_stories_rounded, color: palette.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Knowledge Coverage',
                              style: context.text.labelMedium!.copyWith(
                                color: palette.onSurfaceMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$coveragePct% coverage · ${nc.activeCount} notes across $topicsWithNotes topics',
                              style: context.text.titleSmall!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (totalTopics > 0) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                child: LinearProgressIndicator(
                                  value: totalTopics > 0 ? (topicsWithNotes / totalTopics).clamp(0.0, 1.0) : 0,
                                  minHeight: 5,
                                  backgroundColor: palette.surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Notes List / Grid
          if (notes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        query.isNotEmpty ? Icons.search_off_rounded : Icons.menu_book_outlined,
                        size: 48,
                        color: palette.onSurfaceMuted.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        query.isNotEmpty ? 'No notes matching "$query"' : 'Your knowledge base is empty.',
                        style: context.text.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        query.isNotEmpty
                            ? 'Try searching with different keywords or clearing filters.'
                            : 'Start by creating a note for a subject or topic.',
                        style: context.text.bodyMedium!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (query.isEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: () => _openCreateNote(),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create First Note'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = notes[index];
                    final subject = note.subjectId != null ? sc.subjectById(note.subjectId!) : null;
                    final topic = note.topicId != null ? kc.topicById(note.topicId!) : null;

                    return _NoteCardTile(
                      note: note,
                      subject: subject,
                      topic: topic,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => NoteDetailScreen(noteId: note.id),
                          ),
                        );
                      },
                    );
                  },
                  childCount: notes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : palette.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? palette.primary : palette.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: context.text.labelSmall!.copyWith(
            color: isSelected ? palette.onPrimary : palette.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SubFilterChip extends StatelessWidget {
  const _SubFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final tint = color ?? palette.primary;

    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? tint.withValues(alpha: 0.15) : palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? tint : palette.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: context.text.labelSmall!.copyWith(
            color: isSelected ? tint : palette.onSurfaceMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Note Card Tile ────────────────────────────────────────────────────────────

class _NoteCardTile extends StatelessWidget {
  const _NoteCardTile({
    required this.note,
    required this.subject,
    required this.topic,
    required this.onTap,
  });

  final StudentNote note;
  final Subject? subject;
  final Topic? topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadius.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: Title + Pin icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.isPinned) ...[
                Icon(Icons.push_pin_rounded, size: 14, color: palette.primary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled Note' : note.title,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatSnippetDate(note.updatedAt),
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Snippet
          Text(
            note.snippet,
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Footer row: Context Chips & Tags
          Row(
            children: [
              if (subject != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: subject!.colorValue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(subject!.icon, size: 11, color: subject!.colorValue),
                      const SizedBox(width: 3),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          subject!.displayName,
                          style: context.text.labelSmall!.copyWith(
                            color: subject!.colorValue,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (topic != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      topic!.title,
                      style: context.text.labelSmall!.copyWith(
                        color: palette.onSurfaceMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Spacer(),
              if (note.tags.isNotEmpty)
                Text(
                  '#${note.tags.first}${note.tags.length > 1 ? ' +${note.tags.length - 1}' : ''}',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatSnippetDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
