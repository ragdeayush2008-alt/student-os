import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/academic_resource.dart';
import '../../../data/models/chapter.dart';
import '../../../data/models/student_note.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/topic.dart';
import '../../knowledge/academic_knowledge_controller.dart';
import '../../resources/resource_controller.dart';
import '../../resources/widgets/tag_input.dart';
import '../../subjects/subject_controller.dart';
import '../student_note_controller.dart';

enum NoteSaveState { idle, saving, saved }

/// Premium Student Note Editor.
///
/// Distraction-free, offline-safe note composition and editing supporting
/// academic hierarchy linking (Subject, Chapter, Topic) and attached resources.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.initialSubjectId,
    this.initialChapterId,
    this.initialTopicId,
    this.initialResourceId,
    this.initialTitle,
    this.initialContent,
    this.initialTags,
  });

  final String? noteId;
  final String? initialSubjectId;
  final String? initialChapterId;
  final String? initialTopicId;
  final String? initialResourceId;
  final String? initialTitle;
  final String? initialContent;
  final List<String>? initialTags;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();

  String? _subjectId;
  String? _chapterId;
  String? _topicId;
  List<String> _resourceIds = [];
  List<String> _tags = [];
  bool _isPinned = false;
  bool _isArchived = false;

  NoteSaveState _saveState = NoteSaveState.idle;
  bool _hasUnsavedChanges = false;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.noteId != null) {
      final note = StudentNoteController.instance.noteById(widget.noteId!);
      if (note != null) {
        _titleController.text = note.title;
        _contentController.text = note.content;
        _subjectId = note.subjectId;
        _chapterId = note.chapterId;
        _topicId = note.topicId;
        _resourceIds = List.from(note.resourceIds);
        _tags = List.from(note.tags);
        _isPinned = note.isPinned;
        _isArchived = note.isArchived;
        _wordCount = note.wordCount;
      }
    } else {
      _titleController.text = widget.initialTitle ?? '';
      _contentController.text = widget.initialContent ?? '';
      _subjectId = widget.initialSubjectId;
      _chapterId = widget.initialChapterId;
      _topicId = widget.initialTopicId;
      if (widget.initialResourceId != null) {
        _resourceIds.add(widget.initialResourceId!);
      }
      if (widget.initialTags != null) {
        _tags = List.from(widget.initialTags!);
      }
      _wordCount = StudentNote.computeWordCount(_contentController.text);
    }

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final words = StudentNote.computeWordCount(_contentController.text);
    if (!_hasUnsavedChanges || _wordCount != words) {
      setState(() {
        _hasUnsavedChanges = true;
        _saveState = NoteSaveState.idle;
        _wordCount = words;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote({bool forced = false}) async {
    final title = _titleController.text.trim();
    final content = _contentController.text;

    if (title.isEmpty && content.trim().isEmpty) {
      return; // Do not save empty notes
    }

    final finalTitle = title.isEmpty ? 'Untitled Note' : title;

    setState(() {
      _saveState = NoteSaveState.saving;
    });

    final nc = StudentNoteController.instance;

    if (widget.noteId != null) {
      final existing = nc.noteById(widget.noteId!);
      if (existing != null) {
        final updated = existing.copyWith(
          title: finalTitle,
          content: content,
          subjectId: _subjectId,
          chapterId: _chapterId,
          topicId: _topicId,
          resourceIds: _resourceIds,
          tags: _tags,
          isPinned: _isPinned,
          isArchived: _isArchived,
          clearSubjectId: _subjectId == null,
          clearChapterId: _chapterId == null,
          clearTopicId: _topicId == null,
        );
        await nc.updateNote(updated);
      }
    } else {
      await nc.createNote(
        title: finalTitle,
        content: content,
        subjectId: _subjectId,
        chapterId: _chapterId,
        topicId: _topicId,
        resourceIds: _resourceIds,
        tags: _tags,
        isPinned: _isPinned,
      );
    }

    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
        _saveState = NoteSaveState.saved;
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() => _saveState = NoteSaveState.idle);
        }
      });
    }
  }

  void _insertFormatting(String prefix, [String suffix = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final selectedText = text.substring(start, end);
    final replacement = '$prefix$selectedText$suffix';

    final newText = text.replaceRange(start, end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      ),
    );
    _contentFocusNode.requestFocus();
  }

  Future<void> _pickSubject() async {
    final sc = SubjectController.instance;
    final active = sc.activeSubjects;
    if (active.isEmpty) return;

    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _HierarchyPickerSheet(
        title: 'Select Subject',
        items: [
          const _PickerItem(id: '', title: 'None (Unlinked)', icon: Icons.clear_rounded),
          ...active.map((s) => _PickerItem(id: s.id, title: s.displayName, icon: s.icon)),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _subjectId = result.isEmpty ? null : result;
        _chapterId = null;
        _topicId = null;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _pickChapter() async {
    if (_subjectId == null) {
      await _pickSubject();
      if (!mounted || _subjectId == null) return;
    }

    final kc = AcademicKnowledgeController.instance;
    final chapters = kc.chaptersForSubject(_subjectId!);
    if (chapters.isEmpty) return;

    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _HierarchyPickerSheet(
        title: 'Select Chapter',
        items: [
          const _PickerItem(id: '', title: 'None', icon: Icons.clear_rounded),
          ...chapters.map((c) => _PickerItem(id: c.id, title: c.title, icon: Icons.bookmark_border_rounded)),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _chapterId = result.isEmpty ? null : result;
        _topicId = null;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _pickTopic() async {
    if (_chapterId == null) {
      await _pickChapter();
      if (!mounted || _chapterId == null) return;
    }

    final kc = AcademicKnowledgeController.instance;
    final topics = kc.topicsForChapter(_chapterId!);
    if (topics.isEmpty) return;

    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _HierarchyPickerSheet(
        title: 'Select Topic',
        items: [
          const _PickerItem(id: '', title: 'None', icon: Icons.clear_rounded),
          ...topics.map((t) => _PickerItem(id: t.id, title: t.title, icon: Icons.lightbulb_outline_rounded)),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _topicId = result.isEmpty ? null : result;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _linkResource() async {
    final rc = ResourceController.instance;
    final all = rc.allActiveResources;
    if (all.isEmpty) return;

    final available = all.where((r) => !_resourceIds.contains(r.id)).toList();
    if (available.isEmpty) return;

    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _HierarchyPickerSheet(
        title: 'Link Resource',
        items: available
            .map((r) => _PickerItem(id: r.id, title: r.title, icon: r.resourceType.icon))
            .toList(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _resourceIds.add(result);
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _deleteCurrentNote() async {
    if (widget.noteId == null) {
      Navigator.of(context).pop();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to permanently delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.colorsOf(context).error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await StudentNoteController.instance.deleteNote(widget.noteId!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      await _saveNote(forced: true);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final sc = SubjectController.instance;
    final kc = AcademicKnowledgeController.instance;
    final rc = ResourceController.instance;

    final subject = _subjectId != null ? sc.subjectById(_subjectId!) : null;
    final chapter = _chapterId != null ? kc.chapterById(_chapterId!) : null;
    final topic = _topicId != null ? kc.topicById(_topicId!) : null;

    final linkedResources = _resourceIds
        .map((id) => rc.resources.where((r) => r.id == id).firstOrNull)
        .whereType<AcademicResource>()
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        await _onWillPop();
        if (mounted) nav.pop();
      },
      child: AppScaffold(
        title: '',
        onBack: () async {
          final nav = Navigator.of(context);
          await _onWillPop();
          if (mounted) nav.pop();
        },
        actions: [
          // Pinned toggle
          IconButton(
            tooltip: _isPinned ? 'Unpin note' : 'Pin note',
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? palette.primary : palette.onSurfaceMuted,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isPinned = !_isPinned;
                _hasUnsavedChanges = true;
              });
            },
          ),
          // Save status / manual save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: _SaveActionButton(
              saveState: _saveState,
              hasUnsavedChanges: _hasUnsavedChanges,
              onSave: () => _saveNote(forced: true),
            ),
          ),
          if (widget.noteId != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: palette.onSurfaceMuted),
              onSelected: (val) {
                if (val == 'delete') {
                  _deleteCurrentNote();
                } else if (val == 'archive') {
                  setState(() {
                    _isArchived = !_isArchived;
                    _hasUnsavedChanges = true;
                  });
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(_isArchived ? Icons.unarchive_rounded : Icons.archive_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(_isArchived ? 'Restore' : 'Archive'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: palette.error),
                      const SizedBox(width: 8),
                      Text('Delete Note', style: TextStyle(color: palette.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
        body: Column(
          children: [
            // Scrollable Editor Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    // Title Field
                    TextField(
                      controller: _titleController,
                      style: context.text.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note Title',
                        hintStyle: context.text.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w500,
                          color: palette.onSurfaceMuted.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      ),
                      textInputAction: TextInputAction.next,
                    ),

                    // Academic Context Hierarchy Selector Bar
                    _ContextPillRow(
                      subject: subject,
                      chapter: chapter,
                      topic: topic,
                      onPickSubject: _pickSubject,
                      onPickChapter: _pickChapter,
                      onPickTopic: _pickTopic,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Linked Resources (if any)
                    if (linkedResources.isNotEmpty) ...[
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: linkedResources.map((res) {
                          return Chip(
                            avatar: Icon(res.resourceType.icon, size: 14, color: palette.primary),
                            label: Text(
                              res.title,
                              style: context.text.labelSmall!.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () {
                              setState(() {
                                _resourceIds.remove(res.id);
                                _hasUnsavedChanges = true;
                              });
                            },
                            backgroundColor: palette.surfaceVariant.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],

                    Divider(
                      height: 1,
                      color: palette.outline.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Content Field
                    TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: context.text.bodyLarge!.copyWith(
                        height: 1.65,
                        color: palette.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: r'Write your academic notes here...'
                            '\n\n'
                            r'Supports headings (#), bullet lists (-), numbered lists (1.), checklists ([ ]), bold (**text**), and math notation ($$...$$).',
                        hintStyle: context.text.bodyMedium!.copyWith(
                          color: palette.onSurfaceMuted.withValues(alpha: 0.6),
                          height: 1.6,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Tags & Metadata Section
                    Text(
                      'TAGS',
                      style: context.text.labelSmall!.copyWith(
                        color: palette.onSurfaceMuted,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TagInput(
                      tags: _tags,
                      onChanged: (updated) {
                        setState(() {
                          _tags = updated;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Bottom Formatting Toolbar
            _EditorToolbar(
              wordCount: _wordCount,
              onHeading: () => _insertFormatting('# '),
              onBullet: () => _insertFormatting('- '),
              onNumbered: () => _insertFormatting('1. '),
              onChecklist: () => _insertFormatting('- [ ] '),
              onBold: () => _insertFormatting('**', '**'),
              onMath: () => _insertFormatting(r'$$', r'$$'),
              onQuote: () => _insertFormatting('> '),
              onLinkResource: _linkResource,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formatting Toolbar ────────────────────────────────────────────────────────

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.wordCount,
    required this.onHeading,
    required this.onBullet,
    required this.onNumbered,
    required this.onChecklist,
    required this.onBold,
    required this.onMath,
    required this.onQuote,
    required this.onLinkResource,
  });

  final int wordCount;
  final VoidCallback onHeading;
  final VoidCallback onBullet;
  final VoidCallback onNumbered;
  final VoidCallback onChecklist;
  final VoidCallback onBold;
  final VoidCallback onMath;
  final VoidCallback onQuote;
  final VoidCallback onLinkResource;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Tool buttons
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ToolButton(
                      icon: Icons.title_rounded,
                      tooltip: 'Heading',
                      onPressed: onHeading,
                    ),
                    _ToolButton(
                      icon: Icons.format_bold_rounded,
                      tooltip: 'Bold',
                      onPressed: onBold,
                    ),
                    _ToolButton(
                      icon: Icons.format_list_bulleted_rounded,
                      tooltip: 'Bullet list',
                      onPressed: onBullet,
                    ),
                    _ToolButton(
                      icon: Icons.format_list_numbered_rounded,
                      tooltip: 'Numbered list',
                      onPressed: onNumbered,
                    ),
                    _ToolButton(
                      icon: Icons.checklist_rounded,
                      tooltip: 'Checklist',
                      onPressed: onChecklist,
                    ),
                    _ToolButton(
                      icon: Icons.functions_rounded,
                      tooltip: 'Formula / Math notation',
                      onPressed: onMath,
                    ),
                    _ToolButton(
                      icon: Icons.format_quote_rounded,
                      tooltip: 'Quote',
                      onPressed: onQuote,
                    ),
                    _ToolButton(
                      icon: Icons.link_rounded,
                      tooltip: 'Attach Resource',
                      onPressed: onLinkResource,
                    ),
                  ],
                ),
              ),
            ),
            // Word count pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$wordCount words',
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18, color: palette.onSurface),
        visualDensity: VisualDensity.compact,
        splashRadius: 18,
        onPressed: onPressed,
      ),
    );
  }
}

// ─── Context Pill Row ──────────────────────────────────────────────────────────

class _ContextPillRow extends StatelessWidget {
  const _ContextPillRow({
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.onPickSubject,
    required this.onPickChapter,
    required this.onPickTopic,
  });

  final Subject? subject;
  final Chapter? chapter;
  final Topic? topic;
  final VoidCallback onPickSubject;
  final VoidCallback onPickChapter;
  final VoidCallback onPickTopic;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Pill(
            icon: subject?.icon ?? Icons.folder_outlined,
            label: subject?.displayName ?? 'Subject',
            isSelected: subject != null,
            color: subject?.colorValue ?? palette.primary,
            onTap: onPickSubject,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            icon: Icons.bookmark_border_rounded,
            label: chapter?.title ?? 'Chapter',
            isSelected: chapter != null,
            color: palette.primary,
            onTap: onPickChapter,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            icon: Icons.lightbulb_outline_rounded,
            label: topic?.title ?? 'Topic',
            isSelected: topic != null,
            color: palette.primary,
            onTap: onPickTopic,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : palette.surfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.35) : palette.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? color : palette.onSurfaceMuted,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                style: context.text.labelSmall!.copyWith(
                  color: isSelected ? color : palette.onSurfaceMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isSelected ? color : palette.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Save Action Button ────────────────────────────────────────────────────────

class _SaveActionButton extends StatelessWidget {
  const _SaveActionButton({
    required this.saveState,
    required this.hasUnsavedChanges,
    required this.onSave,
  });

  final NoteSaveState saveState;
  final bool hasUnsavedChanges;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    if (saveState == NoteSaveState.saving) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
          ),
        ),
      );
    }

    if (saveState == NoteSaveState.saved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 16, color: palette.success),
            const SizedBox(width: 4),
            Text(
              'Saved',
              style: context.text.labelSmall!.copyWith(
                color: palette.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return AppPrimaryButton(
      label: 'Save',
      expand: false,
      onPressed: onSave,
    );
  }
}

// ─── Hierarchy Picker Sheet ────────────────────────────────────────────────────

class _PickerItem {
  const _PickerItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

class _HierarchyPickerSheet extends StatelessWidget {
  const _HierarchyPickerSheet({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_PickerItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: palette.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Text(title, style: context.text.titleMedium),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: items.length,
                separatorBuilder: (ctx, idx) => Divider(
                  height: 1,
                  indent: 52,
                  color: palette.outline.withValues(alpha: 0.15),
                ),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return ListTile(
                    leading: Icon(item.icon, color: palette.primary, size: 20),
                    title: Text(item.title, style: context.text.bodyMedium),
                    onTap: () => Navigator.of(context).pop(item.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
