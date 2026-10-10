import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/academic_resource.dart';
import '../../../data/models/student_note.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/topic.dart';
import '../../focus/presentation/widgets/focus_mode_selection_sheet.dart';
import '../../knowledge/academic_knowledge_controller.dart';
import '../../planning/widgets/daily_plan_sheet.dart';
import '../../resources/resource_controller.dart';
import '../../revision/presentation/revision_session_screen.dart';
import '../../study/study_controller.dart';
import '../../subjects/subject_controller.dart';
import '../student_note_controller.dart';
import 'note_editor_screen.dart';

/// Reading and action view for a [StudentNote].
///
/// Provides structured rendering of notes with actionable links into
/// Focus, Study, Practice, Revision, Planning, and Resources.
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final String noteId;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  @override
  void initState() {
    super.initState();
    StudentNoteController.instance.addListener(_onChanged);
    StudentNoteController.instance.markViewed(widget.noteId);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    StudentNoteController.instance.removeListener(_onChanged);
    super.dispose();
  }

  StudentNote? get _note =>
      StudentNoteController.instance.noteById(widget.noteId);

  Future<void> _openEditor() async {
    final note = _note;
    if (note == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorScreen(noteId: note.id),
      ),
    );
  }

  void _launchFocus(StudentNote note, Subject? subject, Topic? topic) {
    FocusModeSelectionSheet.show(
      context,
      subjectId: note.subjectId,
      subjectName: subject?.displayName,
      chapterId: note.chapterId,
      topicId: note.topicId,
      topicName: topic?.title,
      focusTitle: 'Note: ${note.title}',
      suggestedDuration: Duration(minutes: (note.estimatedReadMinutes * 2).clamp(15, 60)),
    );
  }

  void _launchStudy(StudentNote note, Subject? subject) {
    final sc = StudyController.instance;
    sc.startSession(
      subject: subject?.displayName ?? 'General',
      subjectId: note.subjectId,
      chapterId: note.chapterId,
      topicId: note.topicId,
    );
    AppRouter.openStudy(context);
  }

  void _launchRevision(StudentNote note, Topic? topic) {
    if (topic != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RevisionSessionScreen(
            topic: topic,
            suggestedDurationMinutes: 15,
          ),
        ),
      );
    } else {
      AppRouter.openRevision(context);
    }
  }

  void _launchPractice(StudentNote note) {
    AppRouter.openPracticeCenter(context);
  }

  void _launchPlan(StudentNote note) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DailyPlanSheet(
        targetDay: DateTime.now(),
      ),
    );
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to permanently delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.colorsOf(context).error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await StudentNoteController.instance.deleteNote(widget.noteId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    final palette = AppTheme.colorsOf(context);

    if (note == null) {
      return AppScaffold(
        title: 'Note',
        onBack: () => Navigator.of(context).pop(),
        body: Center(
          child: Text('Note not found', style: context.text.bodyLarge),
        ),
      );
    }

    final sc = SubjectController.instance;
    final kc = AcademicKnowledgeController.instance;
    final rc = ResourceController.instance;

    final subject = note.subjectId != null ? sc.subjectById(note.subjectId!) : null;
    final chapter = note.chapterId != null ? kc.chapterById(note.chapterId!) : null;
    final topic = note.topicId != null ? kc.topicById(note.topicId!) : null;

    final linkedResources = note.resourceIds
        .map((id) => rc.resources.where((r) => r.id == id).firstOrNull)
        .whereType<AcademicResource>()
        .toList();

    return AppScaffold(
      title: '',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        IconButton(
          tooltip: note.isPinned ? 'Unpin' : 'Pin',
          icon: Icon(
            note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            color: note.isPinned ? palette.primary : palette.onSurfaceMuted,
            size: 20,
          ),
          onPressed: () => StudentNoteController.instance.togglePinned(note.id),
        ),
        IconButton(
          tooltip: 'Edit Note',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: _openEditor,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: palette.onSurfaceMuted),
          onSelected: (val) {
            if (val == 'archive') {
              if (note.isArchived) {
                StudentNoteController.instance.restoreNote(note.id);
              } else {
                StudentNoteController.instance.archiveNote(note.id);
              }
            } else if (val == 'delete') {
              _deleteNote();
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(note.isArchived ? Icons.unarchive_rounded : Icons.archive_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(note.isArchived ? 'Restore Note' : 'Archive Note'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xs),
            // Note Title
            Text(
              note.title.isEmpty ? 'Untitled Note' : note.title,
              style: context.text.headlineMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Metadata & Timestamp Row
            Row(
              children: [
                Text(
                  _formatDate(note.updatedAt),
                  style: context.text.labelSmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: palette.onSurfaceMuted)),
                const SizedBox(width: 8),
                Text(
                  '${note.wordCount} words',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: palette.onSurfaceMuted)),
                const SizedBox(width: 8),
                Text(
                  '${note.estimatedReadMinutes} min read',
                  style: context.text.labelSmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                if (note.isPinned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Pinned',
                      style: context.text.labelSmall!.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Academic Hierarchy Context Badges
            if (subject != null || chapter != null || topic != null) ...[
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (subject != null)
                    _DetailContextChip(
                      icon: subject.icon,
                      label: subject.displayName,
                      color: subject.colorValue,
                      onTap: () => AppRouter.openSubjectDetail(context, subject.id),
                    ),
                  if (chapter != null)
                    _DetailContextChip(
                      icon: Icons.bookmark_border_rounded,
                      label: chapter.title,
                      color: palette.primary,
                      onTap: null,
                    ),
                  if (topic != null)
                    _DetailContextChip(
                      icon: Icons.lightbulb_outline_rounded,
                      label: topic.title,
                      color: palette.primary,
                      onTap: null,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Contextual Action Buttons Row
            _ActionButtonsBar(
              onFocus: () => _launchFocus(note, subject, topic),
              onStudy: () => _launchStudy(note, subject),
              onPractice: () => _launchPractice(note),
              onRevise: () => _launchRevision(note, topic),
              onPlan: () => _launchPlan(note),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Linked Resources Section
            if (linkedResources.isNotEmpty) ...[
              Text(
                'LINKED RESOURCES',
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...linkedResources.map((res) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppCard(
                    elevation: 0,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    onTap: () => AppRouter.openResourceDetail(context, res.id),
                    child: Row(
                      children: [
                        Icon(res.resourceType.icon, size: 18, color: palette.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            res.title,
                            style: context.text.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 18, color: palette.onSurfaceMuted),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],

            Divider(
              height: 1,
              color: palette.outline.withValues(alpha: 0.25),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Formatted Note Content Reader
            _FormattedContentRenderer(
              content: note.content,
              onChecklistToggled: (index, isChecked) async {
                final updatedContent = _toggleChecklistInContent(note.content, index, isChecked);
                await StudentNoteController.instance.updateNote(
                  note.copyWith(content: updatedContent),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Tags display
            if (note.tags.isNotEmpty) ...[
              Text(
                'TAGS',
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: note.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: palette.outline.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '#$tag',
                      style: context.text.labelSmall!.copyWith(
                        color: palette.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.year == dt.year && now.month == dt.month && now.day == dt.day) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$min';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _toggleChecklistInContent(String content, int targetIndex, bool isChecked) {
    final lines = content.split('\n');
    int checklistCount = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final reg = RegExp(r'^([\*\-\+]\s+\[)([ xX])(\]\s+.*)');
      final match = reg.firstMatch(line);
      if (match != null) {
        if (checklistCount == targetIndex) {
          final mark = isChecked ? 'x' : ' ';
          lines[i] = '${match.group(1)}$mark${match.group(3)}';
          break;
        }
        checklistCount++;
      }
    }
    return lines.join('\n');
  }
}

// ─── Detail Context Chip ───────────────────────────────────────────────────────

class _DetailContextChip extends StatelessWidget {
  const _DetailContextChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              style: context.text.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 14, color: color),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return AppPressable(onTap: onTap!, child: chip);
    }
    return chip;
  }
}

// ─── Action Buttons Bar ────────────────────────────────────────────────────────

class _ActionButtonsBar extends StatelessWidget {
  const _ActionButtonsBar({
    required this.onFocus,
    required this.onStudy,
    required this.onPractice,
    required this.onRevise,
    required this.onPlan,
  });

  final VoidCallback onFocus;
  final VoidCallback onStudy;
  final VoidCallback onPractice;
  final VoidCallback onRevise;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.timer_rounded,
            label: 'Focus',
            isPrimary: true,
            onPressed: onFocus,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionButton(
            icon: Icons.menu_book_rounded,
            label: 'Study',
            onPressed: onStudy,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionButton(
            icon: Icons.quiz_outlined,
            label: 'Practice',
            onPressed: onPractice,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionButton(
            icon: Icons.auto_stories_outlined,
            label: 'Revise',
            onPressed: onRevise,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionButton(
            icon: Icons.calendar_today_rounded,
            label: 'Plan',
            onPressed: onPlan,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppPressable(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? palette.primary : palette.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isPrimary ? palette.primary : palette.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isPrimary ? Colors.white : palette.onSurface,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: context.text.labelSmall!.copyWith(
                color: isPrimary ? Colors.white : palette.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formatted Content Renderer ────────────────────────────────────────────────

class _FormattedContentRenderer extends StatelessWidget {
  const _FormattedContentRenderer({
    required this.content,
    required this.onChecklistToggled,
  });

  final String content;
  final void Function(int checklistIndex, bool isChecked) onChecklistToggled;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    if (content.trim().isEmpty) {
      return Text(
        'Empty note',
        style: context.text.bodyMedium!.copyWith(
          fontStyle: FontStyle.italic,
          color: palette.onSurfaceMuted,
        ),
      );
    }

    final lines = content.split('\n');
    final widgets = <Widget>[];
    int checklistCounter = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
        continue;
      }

      // 1. Heading 1 (# ...)
      if (trimmed.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
          child: Text(
            trimmed.substring(2).trim(),
            style: context.text.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.onSurface,
            ),
          ),
        ));
      }
      // 2. Heading 2 (## ...)
      else if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
          child: Text(
            trimmed.substring(3).trim(),
            style: context.text.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.onSurface,
            ),
          ),
        ));
      }
      // 3. Heading 3 (### ...)
      else if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 2),
          child: Text(
            trimmed.substring(4).trim(),
            style: context.text.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.onSurface,
            ),
          ),
        ));
      }
      // 4. Checklist item (- [ ] ... or - [x] ...)
      else if (RegExp(r'^[\*\-\+]\s+\[([ xX])\]\s+(.*)').hasMatch(trimmed)) {
        final match = RegExp(r'^[\*\-\+]\s+\[([ xX])\]\s+(.*)').firstMatch(trimmed)!;
        final isChecked = match.group(1)!.toLowerCase() == 'x';
        final text = match.group(2)!;
        final currentIdx = checklistCounter++;

        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: isChecked,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) {
                    if (val != null) {
                      onChecklistToggled(currentIdx, val);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: context.text.bodyMedium!.copyWith(
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    color: isChecked ? palette.onSurfaceMuted : palette.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ));
      }
      // 5. Bullet list (- ... or * ...)
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8, left: 4),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  trimmed.substring(2).trim(),
                  style: context.text.bodyMedium!.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ));
      }
      // 6. Numbered list (1. ...)
      else if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        final match = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(trimmed);
        final num = match?.group(1) ?? '1';
        final text = match?.group(2) ?? trimmed;

        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$num.',
                  style: context.text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: context.text.bodyMedium!.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ));
      }
      // 7. Math / Formula block ($$ ... $$)
      else if (trimmed.startsWith(r'$$') && trimmed.endsWith(r'$$') && trimmed.length > 4) {
        final formula = trimmed.substring(2, trimmed.length - 2).trim();
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: palette.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.functions_rounded, size: 18, color: palette.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  formula,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.primary,
                  ),
                ),
              ),
            ],
          ),
        ));
      }
      // 8. Blockquote (> ...)
      else if (trimmed.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: palette.primary, width: 3),
            ),
          ),
          child: Text(
            trimmed.substring(2).trim(),
            style: context.text.bodyMedium!.copyWith(
              fontStyle: FontStyle.italic,
              color: palette.onSurfaceMuted,
            ),
          ),
        ));
      }
      // 9. Standard paragraph text
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            trimmed,
            style: context.text.bodyLarge!.copyWith(
              height: 1.65,
              color: palette.onSurface,
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}
