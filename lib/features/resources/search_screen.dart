import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../../data/models/academic_resource.dart';
import '../../data/models/subject.dart';
import '../subjects/subject_controller.dart';
import 'resource_controller.dart';
import 'widgets/resource_list_tile.dart';

/// Premium full-screen Resource Search experience.
///
/// When [initialTag] is provided (e.g. from "Browse by tags" surfaces), the
/// search opens pre-filtered to that tag without duplicating tag storage.
class ResourceSearchScreen extends StatefulWidget {
  const ResourceSearchScreen({super.key, this.initialTag});

  final String? initialTag;

  @override
  State<ResourceSearchScreen> createState() => _ResourceSearchScreenState();
}

class _ResourceSearchScreenState extends State<ResourceSearchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headerAnim;
  late final Animation<double> _resultsAnim;

  final _queryCtrl = TextEditingController();
  ResourceType? _typeFilter;
  String? _subjectFilter;
  String? _tagFilter;

  @override
  void initState() {
    super.initState();
    _tagFilter = widget.initialTag;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();

    _headerAnim = _stagger(0.00, 0.26);
    _resultsAnim = _stagger(0.18, 0.52);

    _queryCtrl.addListener(_onQueryChanged);
    ResourceController.instance.addListener(_onChanged);
    SubjectController.instance.addListener(_onChanged);
  }

  Animation<double> _stagger(double begin, double end) =>
      _entranceController.drive(
        CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic)),
      );

  void _onQueryChanged() => setState(() {});
  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _entranceController.dispose();
    _queryCtrl.dispose();
    ResourceController.instance.removeListener(_onChanged);
    SubjectController.instance.removeListener(_onChanged);
    super.dispose();
  }

  List<AcademicResource> get _results {
    final rc = ResourceController.instance;
    final query = _queryCtrl.text.trim();

    // Base set: all active resources
    var items = rc.allActiveResources;

    // Search filter
    if (query.isNotEmpty) {
      items = rc.searchResources(query);
    }

    // Type filter
    if (_typeFilter != null) {
      items = items.where((r) => r.resourceType == _typeFilter).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    // Subject filter
    if (_subjectFilter != null) {
      items = items.where((r) => r.subjectId == _subjectFilter).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    // Tag filter
    if (_tagFilter != null) {
      items =
          items
              .where((r) => r.tags.contains(_tagFilter!.toLowerCase()))
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    // Default sort when no query
    if (query.isEmpty) {
      items = items.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return items;
  }

  bool get _hasFilters =>
      _typeFilter != null || _subjectFilter != null || _tagFilter != null;
  bool get _isDefaultState => _queryCtrl.text.trim().isEmpty && !_hasFilters;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Search',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        if (_hasFilters)
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: 'Clear all filters',
            onPressed: () {
              setState(() {
                _typeFilter = null;
                _subjectFilter = null;
                _tagFilter = null;
              });
            },
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search bar
          _EntranceSection(
            animation: _headerAnim,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              child: _SearchBar(
                controller: _queryCtrl,
                onClear: () => _queryCtrl.clear(),
              ),
            ),
          ),
          // Filter bar
          if (_hasFilters || _isDefaultState)
            _EntranceSection(
              animation: _headerAnim,
              child: _FilterBar(
                typeFilter: _typeFilter,
                subjectFilter: _subjectFilter,
                tagFilter: _tagFilter,
                onTypeChanged: (t) => setState(() => _typeFilter = t),
                onSubjectChanged: (s) => setState(() => _subjectFilter = s),
                onTagChanged: (t) => setState(() => _tagFilter = t),
              ),
            ),
          // Results / empty state
          Expanded(
            child: _EntranceSection(
              animation: _resultsAnim,
              child: _isDefaultState
                  ? _DefaultBrowse(
                      onTapResource: (r) =>
                          AppRouter.openResourceDetail(context, r.id),
                      onTapSubject: (s) =>
                          setState(() => _subjectFilter = s.id),
                      onTapTag: (tag) => setState(() => _tagFilter = tag),
                    )
                  : _SearchResults(
                      resources: _results,
                      query: _queryCtrl.text.trim(),
                      onTapResource: (r) =>
                          AppRouter.openResourceDetail(context, r.id),
                      onClearFilters: () {
                        setState(() {
                          _typeFilter = null;
                          _subjectFilter = null;
                          _tagFilter = null;
                        });
                        _queryCtrl.clear();
                      },
                      hasActiveFilters: _hasFilters,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onClear});

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final hasText = controller.text.isNotEmpty;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Icon(Icons.search_rounded, color: palette.onSurfaceMuted),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: context.text.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search notes, links, documents…',
                hintStyle: context.text.bodyLarge!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (hasText)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Clear search',
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.typeFilter,
    required this.subjectFilter,
    required this.tagFilter,
    required this.onTypeChanged,
    required this.onSubjectChanged,
    required this.onTagChanged,
  });

  final ResourceType? typeFilter;
  final String? subjectFilter;
  final String? tagFilter;
  final ValueChanged<ResourceType?> onTypeChanged;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onTagChanged;

  static const _typeLabels = {
    ResourceType.note: 'Notes',
    ResourceType.link: 'Links',
    ResourceType.document: 'Docs',
    ResourceType.video: 'Videos',
    ResourceType.article: 'Articles',
    ResourceType.revision: 'Revision',
    ResourceType.other: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final sc = SubjectController.instance;
    final rc = ResourceController.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Type filters
            for (final t in ResourceType.values)
              _FilterChip(
                label: _typeLabels[t]!,
                isSelected: typeFilter == t,
                onTap: () => onTypeChanged(typeFilter == t ? null : t),
                leadingIcon: t.icon,
              ),
            // Subject filters
            for (final s in sc.activeSubjects.take(6))
              _FilterChip(
                label: s.displayName,
                isSelected: subjectFilter == s.id,
                onTap: () =>
                    onSubjectChanged(subjectFilter == s.id ? null : s.id),
                tint: s.colorValue,
              ),
            // Tag filters
            for (final tag in rc.allTags.take(8))
              _FilterChip(
                label: '#$tag',
                isSelected: tagFilter == tag,
                onTap: () => onTagChanged(tagFilter == tag ? null : tag),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leadingIcon,
    this.tint,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppDurations.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (tint ?? palette.primary).withValues(alpha: 0.15)
                : palette.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected
                  ? (tint ?? palette.primary)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null)
                Icon(
                  leadingIcon,
                  size: 16,
                  color: isSelected
                      ? (tint ?? palette.primary)
                      : palette.onSurfaceMuted,
                ),
              if (leadingIcon != null) const SizedBox(width: 4),
              Text(
                label,
                style: context.text.labelMedium!.copyWith(
                  color: isSelected
                      ? (tint ?? palette.primary)
                      : palette.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: tint ?? palette.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultBrowse extends StatelessWidget {
  const _DefaultBrowse({
    required this.onTapResource,
    required this.onTapSubject,
    required this.onTapTag,
  });

  final ValueChanged<AcademicResource> onTapResource;
  final ValueChanged<Subject> onTapSubject;
  final ValueChanged<String> onTapTag;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final rc = ResourceController.instance;
    final sc = SubjectController.instance;

    final isEmpty =
        !rc.hasResources && sc.activeSubjects.isEmpty && rc.allTags.isEmpty;

    if (isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xl,
          AppSpacing.screen,
          AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: palette.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your library is empty',
              style: context.text.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Capture your first note, link, or document to start building '
              'your academic library.',
              style: context.text.bodyMedium!.copyWith(
                color: palette.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent resources
          if (rc.hasRecent) ...[
            AppSectionHeader(title: 'Recent', icon: Icons.history_rounded),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rc.recentResources.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final r = rc.recentResources[index];
                  return SizedBox(
                    width: 180,
                    child: AppPressable(
                      onTap: () => onTapResource(r),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              r.resourceType.icon,
                              color: palette.primary,
                              size: 22,
                            ),
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
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          // Favorites
          if (rc.hasFavorites) ...[
            AppSectionHeader(title: 'Favorites', icon: Icons.star_rounded),
            const SizedBox(height: AppSpacing.md),
            ...rc.favoriteResources
                .take(4)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ResourceListTile(resource: r),
                  ),
                ),
            const SizedBox(height: AppSpacing.xl),
          ],
          // Subjects
          if (sc.activeSubjects.isNotEmpty) ...[
            AppSectionHeader(
              title: 'Browse by subject',
              icon: Icons.folder_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            ...sc.activeSubjects.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppPressable(
                  onTap: () => onTapSubject(s),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: s.colorValue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(s.icon, color: s.colorValue, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            s.name,
                            style: context.text.titleSmall!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${rc.resourcesForSubject(s.id).length} resources',
                          style: context.text.bodySmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: palette.onSurfaceMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          // Popular tags
          if (rc.allTags.isNotEmpty) ...[
            AppSectionHeader(title: 'Popular tags', icon: Icons.tag_outlined),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: rc.allTags
                  .take(12)
                  .map(
                    (tag) => GestureDetector(
                      onTap: () => onTapTag(tag),
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
            ),
          ],
        ],
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

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.resources,
    required this.query,
    required this.onTapResource,
    required this.onClearFilters,
    required this.hasActiveFilters,
  });

  final List<AcademicResource> resources;
  final String query;
  final ValueChanged<AcademicResource> onTapResource;
  final VoidCallback onClearFilters;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return _NoResults(
        query: query,
        onClearFilters: onClearFilters,
        showClearButton: query.isNotEmpty || hasActiveFilters,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.xxxl,
      ),
      itemCount: resources.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final r = resources[index];
        return ResourceListTile(resource: r);
      },
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({
    required this.query,
    required this.onClearFilters,
    required this.showClearButton,
  });

  final String query;
  final VoidCallback onClearFilters;
  final bool showClearButton;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: palette.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              query.isEmpty ? 'No resources found' : 'No matches for "$query"',
              style: context.text.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              showClearButton
                  ? 'Try a different search or filter.'
                  : 'Create your first note, link, or document.',
              style: context.text.bodyMedium!.copyWith(
                color: palette.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (showClearButton) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_list_rounded),
                label: const Text('Clear filters'),
                onPressed: onClearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.primary,
                  side: BorderSide(
                    color: palette.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
