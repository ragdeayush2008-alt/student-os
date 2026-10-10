import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/academic_resource.dart';
import '../../data/models/subject.dart';
import '../exams/exam_controller.dart';
import '../notes/student_note_controller.dart';
import '../subjects/subject_controller.dart';
import 'note_editor_screen.dart';
import 'resource_creation_sheet.dart';
import 'resource_controller.dart';

/// Premium resource detail experience — the full control surface for a saved
/// academic resource (notes, links, documents, revision material, and more).
///
/// Reads directly from [ResourceController] and stays in sync with it. Renders
/// a clean data-only layout with no entrance animations, matching the detail
/// screens across the app.
class ResourceDetailScreen extends StatefulWidget {
  const ResourceDetailScreen({super.key, required this.resourceId});

  final String resourceId;

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  @override
  void initState() {
    super.initState();
    ResourceController.instance.addListener(_onChanged);
    StudentNoteController.instance.addListener(_onChanged);
    ResourceController.instance.markOpened(widget.resourceId);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ResourceController.instance.removeListener(_onChanged);
    StudentNoteController.instance.removeListener(_onChanged);
    super.dispose();
  }

  AcademicResource? get _resource => ResourceController.instance.resources
      .where((r) => r.id == widget.resourceId)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final resource = _resource;
    if (resource == null) {
      return AppScaffold(
        title: 'Resource',
        onBack: () => Navigator.of(context).pop(),
        body: Center(
          child: Text('Resource not found', style: context.text.bodyLarge),
        ),
      );
    }

    return AppScaffold(
      title: '',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Edit',
          onPressed: () => _editResource(context, resource),
        ),
        IconButton(
          icon: Icon(
            resource.isFavorite
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: resource.isFavorite
                ? AppTheme.colorsOf(context).warning
                : null,
          ),
          tooltip: resource.isFavorite
              ? 'Remove from favorites'
              : 'Add to favorites',
          onPressed: () =>
              ResourceController.instance.toggleFavorite(resource.id),
        ),
        PopupMenuButton<String>(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            switch (value) {
              case 'archive':
                _archiveResource(context, resource);
                break;
              case 'delete':
                _confirmDelete(context, resource);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'archive',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.archive_outlined),
                title: Text('Archive'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.colorsOf(context).error),
                ),
              ),
            ),
          ],
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type chip
                  Row(
                    children: [
                      Icon(
                        resource.resourceType.icon,
                        size: 18,
                        color: AppTheme.colorsOf(context).primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        resource.resourceType.label,
                        style: context.text.labelMedium!.copyWith(
                          color: AppTheme.colorsOf(context).onSurfaceMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (resource.isFavorite) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppTheme.colorsOf(context).warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Title
                  Text(resource.title, style: context.text.headlineLarge),

                  // Type-specific body
                  if (resource.isNote) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _NoteMetadata(resource: resource),
                  ] else if (resource.isLink) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _LinkSection(resource: resource),
                  ] else ...[
                    const SizedBox(height: AppSpacing.md),
                    _DocumentSection(resource: resource),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Subject / exam context
                  if (resource.subjectId != null ||
                      resource.examId != null) ...[
                    _ContextSection(resource: resource),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Tags
                  if (resource.tags.isNotEmpty) ...[
                    _TagsSection(tags: resource.tags),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Related Notes Section
                  _RelatedNotesSection(resource: resource),
                  const SizedBox(height: AppSpacing.xl),

                  // Access metadata
                  _AccessMetadata(resource: resource),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editResource(BuildContext context, AcademicResource resource) {
    if (resource.isNote) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NoteEditorScreen(resourceId: resource.id),
        ),
      );
    } else {
      ResourceCreationSheet.show(
        context,
        resource.resourceType,
        editing: resource,
      );
    }
  }

  void _archiveResource(BuildContext context, AcademicResource resource) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Archive resource'),
        content: Text('Archive "${resource.title}"? You can restore it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              ResourceController.instance.archiveResource(resource.id);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AcademicResource resource) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Delete resource'),
        content: Text('Delete "${resource.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              ResourceController.instance.deleteResource(resource.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Note metadata ─────────────────────────────────────────────────────

class _NoteMetadata extends StatelessWidget {
  const _NoteMetadata({required this.resource});

  final AcademicResource resource;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resource.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            resource.description,
            style: context.text.bodyMedium!.copyWith(
              color: AppTheme.colorsOf(context).onSurfaceMuted,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Last edited ${_format(resource.updatedAt)}',
          style: context.text.bodySmall!.copyWith(
            color: AppTheme.colorsOf(context).onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (resource.content != null && resource.content!.trim().isNotEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SelectableText(
              resource.content!,
              style: context.text.bodyLarge!.copyWith(height: 1.6),
            ),
          ),
      ],
    );
  }

  String _format(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Link section ──────────────────────────────────────────────────────

class _LinkSection extends StatelessWidget {
  const _LinkSection({required this.resource});

  final AcademicResource resource;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final ref = resource.reference ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (resource.description.isNotEmpty) ...[
          Text(
            resource.description,
            style: context.text.bodyMedium!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('URL', style: context.text.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                ref.isEmpty ? 'No link provided' : ref,
                style: context.text.bodyMedium!.copyWith(
                  color: ref.isEmpty ? palette.onSurfaceMuted : palette.primary,
                ),
              ),
              if (ref.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: palette.onSurfaceMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Link saved for later reference',
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (ref.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _copyLink(context, ref),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy link'),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.primary,
              side: BorderSide(color: palette.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.link_off_rounded, size: 18),
            label: const Text('No link to open'),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.onSurfaceMuted,
              side: BorderSide(color: palette.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
      ],
    );
  }

  void _copyLink(BuildContext context, String ref) {
    Clipboard.setData(ClipboardData(text: ref));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ─── Document / other section ──────────────────────────────────────────

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({required this.resource});

  final AcademicResource resource;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resource.description.isNotEmpty) ...[
          Text(
            resource.description,
            style: context.text.bodyLarge!.copyWith(color: palette.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (resource.reference != null && resource.reference!.isNotEmpty) ...[
          _DetailRow(
            icon: Icons.insert_link_rounded,
            label: 'Reference',
            value: resource.reference!,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (resource.content != null && resource.content!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SelectableText(
              resource.content!,
              style: context.text.bodyLarge!.copyWith(height: 1.6),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Context section (subject / exam) ─────────────────────────────────

class _ContextSection extends StatelessWidget {
  const _ContextSection({required this.resource});

  final AcademicResource resource;

  @override
  Widget build(BuildContext context) {
    final Subject? subject = resource.subjectId != null
        ? SubjectController.instance.subjectById(resource.subjectId!)
        : null;
    final exam = resource.examId != null
        ? ExamController.instance.exams
              .where((e) => e.id == resource.examId)
              .firstOrNull
        : null;

    final validExam = exam;
    final hasOrphanExam = resource.examId != null && validExam == null;

    // Hide the entire section when there is no usable context to show.
    if (subject == null && validExam == null && !hasOrphanExam) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Context',
          style: context.text.titleSmall!.copyWith(
            color: AppTheme.colorsOf(context).onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (subject != null)
          _ContextCard(
            icon: subject.icon,
            label: 'Subject',
            value: subject.displayName,
            tint: subject.colorValue,
            onTap: () => AppRouter.openSubjectDetail(context, subject.id),
          ),
        // Study / Focus from resource context — preserves IDs
        if (subject != null)
          _ActionRow(
            label: 'Study this material',
            icon: Icons.menu_book_rounded,
            onTap: () => AppRouter.openStudy(context),
          ),
        if (subject != null)
          _ActionRow(
            label: 'Focus session',
            icon: Icons.center_focus_strong_rounded,
            onTap: () => AppRouter.openFocusCenter(context),
          ),
        if (subject != null && (validExam != null || hasOrphanExam))
          const SizedBox(height: AppSpacing.sm),
        if (validExam != null)
          _ContextCard(
            icon: Icons.school_rounded,
            label: 'Linked exam',
            value: validExam.countdown != null
                ? '${validExam.title} · ${validExam.countdown}'
                : validExam.title,
            tint: AppTheme.colorsOf(context).primary,
            onTap: () => AppRouter.openExamDetail(context, validExam.id),
          )
        else if (hasOrphanExam)
          _ContextCard(
            icon: Icons.school_outlined,
            label: 'Linked exam',
            value: 'Unavailable',
            tint: AppTheme.colorsOf(context).onSurfaceMuted,
        ),
      ],
    );
  }
}

class _RelatedNotesSection extends StatelessWidget {
  const _RelatedNotesSection({required this.resource});

  final AcademicResource resource;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final nc = StudentNoteController.instance;
    final relatedNotes = nc.notesForResource(resource.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, size: 16, color: palette.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Related Notes (${relatedNotes.length})',
              style: context.text.labelMedium!.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Add Note'),
              onPressed: () {
                AppRouter.openNoteEditor(
                  context,
                  resourceId: resource.id,
                  subjectId: resource.subjectId,
                  initialTitle: 'Notes on ${resource.title}',
                );
              },
            ),
          ],
        ),
        if (relatedNotes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ...relatedNotes.map((note) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                elevation: 0,
                borderRadius: BorderRadius.circular(AppRadius.md),
                padding: const EdgeInsets.all(AppSpacing.sm),
                onTap: () => AppRouter.openNoteDetail(context, note.id),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: palette.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled Note' : note.title,
                        style: context.text.bodySmall!.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: palette.onSurfaceMuted),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.secondary,
      ),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: context.text.bodySmall)),
          Flexible(
            child: Text(
              value,
              style: context.text.labelMedium!.copyWith(
                color: AppTheme.colorsOf(context).onSurface,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tags section ──────────────────────────────────────────────────────

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: context.text.titleSmall!.copyWith(
            color: palette.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: tags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: palette.outline),
                  ),
                  child: Text(
                    '#$tag',
                    style: context.text.labelSmall!.copyWith(
                      color: palette.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─── Access metadata ───────────────────────────────────────────────────

class _AccessMetadata extends StatelessWidget {
  const _AccessMetadata({required this.resource});

  final AcademicResource resource;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details', style: context.text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            icon: Icons.create_rounded,
            label: 'Created',
            value: _format(resource.createdAt),
          ),
          if (resource.lastAccessedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _DetailRow(
              icon: Icons.history_rounded,
              label: 'Last accessed',
              value: _format(resource.lastAccessedAt!),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          _DetailRow(
            icon: Icons.visibility_outlined,
            label: 'Access count',
            value: '${resource.accessCount}',
          ),
          const SizedBox(height: AppSpacing.xs),
          _DetailRow(
            icon: Icons.update_rounded,
            label: 'Last updated',
            value: _format(resource.updatedAt),
          ),
        ],
      ),
    );
  }

  String _format(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: palette.onSurfaceMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '$label: ',
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: context.text.bodySmall!.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
