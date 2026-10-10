import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/responsive_content.dart';
import '../../data/models/academic_resource.dart';
import '../../data/models/subject.dart';
import '../exams/exam_controller.dart';
import '../subjects/subject_controller.dart';
import 'resource_controller.dart';
import 'resource_creation_sheet.dart';

/// The premium Resources Command Center — the student's academic knowledge hub.
///
/// When [initialSubjectId] is provided (via [AppRouter.openSubjectResources]),
/// the browser is pre-filtered to that subject without duplicating storage or
/// controller logic.
class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key, this.initialSubjectId});

  final String? initialSubjectId;

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _metricsAnim;
  late final Animation<double> _captureAnim;
  late final Animation<double> _browserAnim;

  ResourceFilter? _filter;
  String? _subjectFilterId;

  @override
  void initState() {
    super.initState();
    _subjectFilterId = widget.initialSubjectId;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _metricsAnim = _stagger(0.00, 0.28);
    _captureAnim = _stagger(0.16, 0.44);
    _browserAnim = _stagger(0.32, 0.62);

    ResourceController.instance.addListener(_onChanged);
    SubjectController.instance.addListener(_onChanged);
    ExamController.instance.addListener(_onChanged);
  }

  Animation<double> _stagger(double begin, double end) =>
      _entranceController.drive(
        CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic)),
      );

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _entranceController.dispose();
    ResourceController.instance.removeListener(_onChanged);
    SubjectController.instance.removeListener(_onChanged);
    ExamController.instance.removeListener(_onChanged);
    super.dispose();
  }

  List<AcademicResource> get _filtered {
    final rc = ResourceController.instance;
    List<AcademicResource> base;
    switch (_filter) {
      case ResourceFilter.favorites:
        base = rc.favoriteResources;
        break;
      case ResourceFilter.notes:
        base = rc.noteResources;
        break;
      case ResourceFilter.links:
        base = rc.linkResources;
        break;
      case ResourceFilter.documents:
        base = rc.allActiveResources.where((r) => r.isDocument).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case ResourceFilter.revision:
        base = rc.revisionResources;
        break;
      default:
        base = rc.allActiveResources
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    if (_subjectFilterId != null) {
      base = base.where((r) => r.subjectId == _subjectFilterId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final rc = ResourceController.instance;
    final sc = SubjectController.instance;
    final hasAny = rc.hasResources;
    final filteredSubject = _subjectFilterId != null
        ? sc.subjectById(_subjectFilterId!)
        : null;

    return AppScaffold(
      title: filteredSubject?.displayName ?? 'Your knowledge',
      actions: [
        if (hasAny)
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search resources',
            onPressed: () => AppRouter.openResourceSearch(context),
          ),
      ],
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.md,
        ),
        child: ResponsiveContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (filteredSubject != null)
                _EntranceSection(
                  animation: _metricsAnim,
                  child: _SubjectFilterBanner(
                    subject: filteredSubject,
                    count: _filtered.length,
                    onClear: () => setState(() => _subjectFilterId = null),
                  ),
                ),
              if (filteredSubject == null && rc.hasResources)
                _EntranceSection(
                  animation: _metricsAnim,
                  child: _MetricsOverview(rc: rc),
                ),
              const SizedBox(height: AppSpacing.lg),
              _EntranceSection(
                animation: _metricsAnim,
                child: Text(
                  filteredSubject != null
                      ? '${_filtered.length} resource${_filtered.length == 1 ? '' : 's'} in ${filteredSubject.displayName}'
                      : _summaryLine(rc, sc),
                  style: context.text.bodySmall!.copyWith(
                    color: context.text.bodySmall?.color,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _EntranceSection(
                animation: _captureAnim,
                child: _QuickCapture(
                  onCreateNote: () => ResourceCreationSheet.show(
                    context,
                    ResourceType.note,
                    subjectId: _subjectFilterId,
                  ),
                  onCreateLink: () => ResourceCreationSheet.show(
                    context,
                    ResourceType.link,
                    subjectId: _subjectFilterId,
                  ),
                  onCreateOther: () => _showTypePicker(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (filteredSubject == null && rc.hasRecent) ...[
                _EntranceSection(
                  animation: _browserAnim,
                  child: AppSectionHeader(
                    title: 'Continue where you left off',
                    icon: Icons.history_rounded,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _EntranceSection(
                  animation: _browserAnim,
                  child: _RecentRow(resources: rc.recentResources),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (filteredSubject == null && rc.hasFavorites) ...[
                _EntranceSection(
                  animation: _browserAnim,
                  child: AppSectionHeader(
                    title: 'Favorites',
                    icon: Icons.star_rounded,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...rc.favoriteResources
                    .take(4)
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ResourceListTile(resource: r),
                      ),
                    ),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (filteredSubject == null && sc.activeSubjects.isNotEmpty) ...[
                _EntranceSection(
                  animation: _browserAnim,
                  child: AppSectionHeader(
                    title: 'Your subjects',
                    icon: Icons.folder_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...sc.activeSubjects.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SubjectRow(
                      subject: s,
                      count: rc.resourcesForSubject(s.id).length,
                      onTap: () => AppRouter.openSubjectDetail(context, s.id),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (filteredSubject == null && rc.allTags.isNotEmpty) ...[
                _EntranceSection(
                  animation: _browserAnim,
                  child: AppSectionHeader(
                    title: 'Browse by tags',
                    icon: Icons.tag_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _EntranceSection(
                  animation: _browserAnim,
                  child: _TagsRow(tags: rc.allTags.toList()..sort()),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              // Browser
              _EntranceSection(
                animation: _browserAnim,
                child: AppSectionHeader(
                  title: filteredSubject != null ? 'Resources' : 'All resources',
                  icon: Icons.grid_view_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _EntranceSection(
                animation: _browserAnim,
                child: _FilterBar(selected: _filter, onChanged: _setFilter),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_filtered.isEmpty)
                _EmptyBrowser(hasAny: hasAny)
              else
                ..._filtered.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ResourceListTile(resource: r),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _summaryLine(ResourceController rc, SubjectController sc) {
    final total = rc.activeCount;
    if (total == 0) return 'Build your academic library';
    if (sc.activeCount == 0) return '$total resource${total == 1 ? '' : 's'}';
    return '$total resource${total == 1 ? '' : 's'} across ${sc.activeCount} subject${sc.activeCount == 1 ? '' : 's'}';
  }

  void _setFilter(ResourceFilter? f) => setState(() => _filter = f);

  Future<void> _showTypePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<ResourceType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TypePickerSheet(),
    );
    if (selected != null && context.mounted) {
      ResourceCreationSheet.show(
        context,
        selected,
        subjectId: _subjectFilterId,
      );
    }
  }
}

enum ResourceFilter { all, notes, links, documents, revision, favorites }

// ══════════════════════════════════════════════════════════════════════════
// METRICS OVERVIEW
// ══════════════════════════════════════════════════════════════════════════

class _MetricsOverview extends StatelessWidget {
  const _MetricsOverview({required this.rc});

  final ResourceController rc;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final cards = [
      ('Resources', rc.activeCount, Icons.calculate_outlined, palette.primary),
      ('Notes', rc.noteCount, Icons.notes_rounded, palette.primary),
      ('Favorites', rc.favoriteCount, Icons.star_rounded, palette.primary),
    ];
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(cards[i].$3, color: cards[i].$4, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    '${cards[i].$2}',
                    style: context.text.headlineMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    cards[i].$1,
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// QUICK CAPTURE
// ══════════════════════════════════════════════════════════════════════════

class _QuickCapture extends StatelessWidget {
  const _QuickCapture({
    required this.onCreateNote,
    required this.onCreateLink,
    required this.onCreateOther,
  });

  final VoidCallback onCreateNote;
  final VoidCallback onCreateLink;
  final VoidCallback onCreateOther;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CaptureButton(
            icon: Icons.notes_rounded,
            label: 'New note',
            onTap: onCreateNote,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CaptureButton(
            icon: Icons.link_rounded,
            label: 'Add link',
            onTap: onCreateLink,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CaptureButton(
            icon: Icons.add_rounded,
            label: 'More',
            onTap: onCreateOther,
          ),
        ),
      ],
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppPressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: palette.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: context.text.labelMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// RECENT ROW
// ══════════════════════════════════════════════════════════════════════════

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.resources});

  final List<AcademicResource> resources;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: resources.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final r = resources[index];
          return SizedBox(
            width: 160,
            child: AppPressable(
              onTap: () => AppRouter.openResourceDetail(context, r.id),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(r.resourceType.icon, color: palette.primary, size: 22),
                    const Spacer(),
                    Text(
                      r.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(r.lastAccessedAt),
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SUBJECT ROW
// ══════════════════════════════════════════════════════════════════════════

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.count,
    required this.onTap,
  });

  final Subject subject;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppPressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: subject.colorValue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(subject.icon, color: subject.colorValue, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subject.description.isNotEmpty)
                    Text(
                      subject.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '$count resource${count == 1 ? '' : 's'}',
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, color: palette.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// TAGS ROW
// ══════════════════════════════════════════════════════════════════════════

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: tags
          .take(16)
          .map(
            (tag) => AppPressable(
              onTap: () =>
                  AppRouter.openResourceSearch(context, initialTag: tag),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
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
            ),
          )
          .toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// FILTER BAR
// ══════════════════════════════════════════════════════════════════════════

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final ResourceFilter? selected;
  final ValueChanged<ResourceFilter?> onChanged;

  static const _labels = {
    ResourceFilter.all: 'All',
    ResourceFilter.notes: 'Notes',
    ResourceFilter.links: 'Links',
    ResourceFilter.documents: 'Docs',
    ResourceFilter.revision: 'Revision',
    ResourceFilter.favorites: 'Favorites',
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final f = ResourceFilter.values[index];
          final isSelected = f == selected;
          return GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.primary.withValues(alpha: 0.15)
                    : palette.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected ? palette.primary : Colors.transparent,
                ),
              ),
              child: Text(
                _labels[f]!,
                style: context.text.labelMedium!.copyWith(
                  color: isSelected ? palette.primary : palette.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SUBJECT FILTER BANNER
// ══════════════════════════════════════════════════════════════════════════

class _SubjectFilterBanner extends StatelessWidget {
  const _SubjectFilterBanner({
    required this.subject,
    required this.count,
    required this.onClear,
  });

  final Subject subject;
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: subject.colorValue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(subject.icon, color: subject.colorValue, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.displayName,
                  style: context.text.labelLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$count resource${count == 1 ? '' : 's'}',
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          AppPressable(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: palette.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: palette.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Clear',
                    style: context.text.labelSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: palette.onSurfaceMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// RESOURCE TILE
// ══════════════════════════════════════════════════════════════════════════

class _ResourceListTile extends StatelessWidget {
  const _ResourceListTile({required this.resource});

  final AcademicResource resource;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final sc = SubjectController.instance;
    final subject = resource.subjectId != null
        ? sc.subjectById(resource.subjectId!)
        : null;

    return AppPressable(
      onTap: () => AppRouter.openResourceDetail(context, resource.id),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                resource.resourceType.icon,
                color: palette.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (resource.description.isNotEmpty ||
                      subject != null ||
                      resource.hasTags)
                    Text(
                      _subtitle(subject),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (resource.isFavorite)
              Icon(
                Icons.star_rounded,
                color: AppColors.streak,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  String _subtitle(Subject? subject) {
    final parts = <String>[];
    if (subject != null) parts.add(subject.name);
    if (resource.hasTags) parts.add(resource.tags.take(2).join(', '));
    if (resource.description.isNotEmpty && parts.isEmpty) {
      return resource.description;
    }
    return parts.join(' · ');
  }
}

// ══════════════════════════════════════════════════════════════════════════
// EMPTY BROWSER
// ══════════════════════════════════════════════════════════════════════════

class _EmptyBrowser extends StatelessWidget {
  const _EmptyBrowser({required this.hasAny});

  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: palette.onSurfaceMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasAny ? 'No resources in this view' : 'No resources yet',
            style: context.text.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasAny
                ? 'Try a different filter.'
                : 'Capture your first note, link, or revision material.',
            style: context.text.bodyMedium!.copyWith(
              color: palette.onSurfaceMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// TYPE PICKER
// ══════════════════════════════════════════════════════════════════════════

class _TypePickerSheet extends StatelessWidget {
  const _TypePickerSheet();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final types = [
      ResourceType.document,
      ResourceType.video,
      ResourceType.article,
      ResourceType.revision,
      ResourceType.other,
    ];
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add a resource', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...types.map(
              (t) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(t.icon, color: palette.primary),
                title: Text(t.label),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => Navigator.of(context).pop(t),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ENTRANCE
// ══════════════════════════════════════════════════════════════════════════

class _EntranceSection extends StatelessWidget {
  const _EntranceSection({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
