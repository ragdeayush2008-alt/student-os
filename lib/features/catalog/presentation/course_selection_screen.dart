import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/services/course_catalog_service.dart';
import '../../../core/services/student_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/catalog/active_course_selection.dart';
import '../../../data/models/catalog/catalog_category.dart';
import '../../../data/models/catalog/catalog_family.dart';
import '../../../data/models/catalog/catalog_level.dart';
import '../../../data/models/catalog/catalog_program.dart';
import '../course_selection_tokens.dart';

/// Select Your Goal / Change Course Flow — Modern Academic Command Center.
///
/// Single authoritative course-selection system.
/// Both initial setup and change-course entry points use this exact UI.
///
/// Adaptive hierarchy: Category → Family → Program → Level/Sub-Level → Confirmation.
/// Fast offline search across all catalog fields. Premium solid surfaces.
class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({
    super.key,
    this.initialCategoryId,
    this.onCourseSelected,
    this.mode,
  });

  final String? initialCategoryId;
  final ValueChanged<ActiveCourseSelection>? onCourseSelected;

  /// Explicit mode override. If null, inferred from [CourseCatalogService.hasActiveCourse].
  final CourseSelectionMode? mode;

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

enum CourseSelectionMode { setup, change }

class _CourseSelectionScreenState extends State<CourseSelectionScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  CatalogCategory2? _selectedCategory;
  CatalogFamily? _selectedFamily;
  CatalogProgram? _selectedProgram;
  CatalogLevel? _selectedLevel;
  CatalogLevel? _selectedSubLevel;
  String _selectedYear = '2026';
  final Set<String> _selectedOptionalPaperIds = <String>{};

  bool _isSearching = false;
  List<CatalogProgram> _searchResults = [];
  bool _isConfirming = false;

  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: AppDurations.medium);
    final catalog = CourseCatalogService.instance;
    catalog.ensureInitialized();
    if (widget.initialCategoryId != null) {
      _selectedCategory = catalog.getCategoryById(widget.initialCategoryId!);
    }
    _searchFocus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _isChangeMode {
    if (widget.mode != null) return widget.mode == CourseSelectionMode.change;
    return CourseCatalogService.instance.hasActiveCourse;
  }

  void _onSearchChanged(String query) {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    final results = CourseCatalogService.instance.searchCatalog2(clean);
    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  void _selectProgram(CatalogProgram program) {
    final cat = CourseCatalogService.instance.getCategoryById(program.categoryId);
    final fam = CourseCatalogService.instance.getFamilyById(program.familyId);

    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = cat;
      _selectedFamily = fam;
      _selectedProgram = program;
      _selectedYear = program.defaultYear;
      _selectedLevel = program.levels.isNotEmpty ? program.levels.first : null;
      _selectedSubLevel = null;
      _selectedOptionalPaperIds.clear();
      _isSearching = false;
      _searchCtrl.clear();
    });
  }

  Future<void> _handleConfirm() async {
    if (_selectedProgram == null || _isConfirming) return;
    final program = _selectedProgram!;
    final levelTitle = _selectedSubLevel?.title ?? _selectedLevel?.title ?? program.title;
    final levelId = _selectedLevel?.id ?? program.levels.firstOrNull?.id ?? '';

    final newSelection = ActiveCourseSelection(
      userId: StudentService.instance.profile.id,
      categoryId: program.categoryId,
      familyId: program.familyId,
      programId: program.id,
      programTitle: program.title,
      levelId: levelId,
      levelTitle: levelTitle,
      subLevelId: _selectedSubLevel?.id,
      subLevelTitle: _selectedSubLevel?.title,
      year: _selectedYear,
      selectedPaperIds: _selectedOptionalPaperIds.toList(),
      authority: program.authority,
    );

    // Initial setup: no existing course → save directly without comparative dialog
    if (!_isChangeMode || CourseCatalogService.instance.getActiveCourse() == null) {
      setState(() => _isConfirming = true);
      try {
        await CourseCatalogService.instance.switchCourse(
          newSelection: newSelection,
          selectedOptionalPaperIds: _selectedOptionalPaperIds.toList(),
        );
        if (widget.onCourseSelected != null) widget.onCourseSelected!(newSelection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Active course set to ${newSelection.programTitle} · $levelTitle $yearLabel'),
              backgroundColor: const Color(0xFF16B88A),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } finally {
        if (mounted) setState(() => _isConfirming = false);
      }
      return;
    }

    final currentCourse = CourseCatalogService.instance.getActiveCourse() ?? 'None';
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfirmationDialog(
        currentCourse: currentCourse,
        newSelection: newSelection,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          setState(() => _isConfirming = true);
          await CourseCatalogService.instance.switchCourse(
            newSelection: newSelection,
            selectedOptionalPaperIds: _selectedOptionalPaperIds.toList(),
          );
          if (widget.onCourseSelected != null) widget.onCourseSelected!(newSelection);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Active course updated to ${newSelection.programTitle} · $levelTitle'),
                backgroundColor: const Color(0xFF16B88A),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(true);
          }
          if (mounted) setState(() => _isConfirming = false);
        },
      ),
    );
  }

  String get yearLabel => _selectedYear;

  void _handleBackNavigation() {
    if (_isSearching) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchCtrl.clear();
      });
      return;
    }
    if (_selectedProgram != null) {
      setState(() => _selectedProgram = null);
      return;
    }
    if (_selectedFamily != null) {
      setState(() => _selectedFamily = null);
      return;
    }
    if (_selectedCategory != null) {
      setState(() => _selectedCategory = null);
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AppScaffold(
      title: 'Select Your Goal',
      onBack: _handleBackNavigation,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: CourseSelectionTokens.maxContentWidth),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  CourseSelectionTokens.horizontalMargin,
                  CourseSelectionTokens.headerToContent,
                  CourseSelectionTokens.horizontalMargin,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _PremiumSearchField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: _onSearchChanged,
                    onClear: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                      _searchFocus.unfocus();
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  CourseSelectionTokens.horizontalMargin,
                  CourseSelectionTokens.searchToSection,
                  CourseSelectionTokens.horizontalMargin,
                  16 + bottomInset * 0.2,
                ),
                sliver: SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _fadeController, curve: AppCurves.standard),
                    child: AnimatedSwitcher(
                      duration: AppDurations.base,
                      switchInCurve: AppCurves.entrance,
                      switchOutCurve: AppCurves.exit,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, if (current != null) current],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey<String>(_viewKey),
                        child: _buildCurrentView(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _viewKey {
    if (_isSearching) return 'search';
    if (_selectedProgram != null) return 'program_${_selectedProgram!.id}';
    if (_selectedFamily != null) return 'family_${_selectedFamily!.id}';
    if (_selectedCategory != null) return 'category_${_selectedCategory!.id}';
    return 'home';
  }

  Widget _buildCurrentView() {
    if (_isSearching) {
      return _SearchResultsView(
        results: _searchResults,
        onSelectProgram: _selectProgram,
      );
    }
    if (_selectedProgram != null) {
      return _ProgramDetailView(
        program: _selectedProgram!,
        selectedLevel: _selectedLevel,
        selectedSubLevel: _selectedSubLevel,
        selectedYear: _selectedYear,
        selectedOptionalIds: _selectedOptionalPaperIds,
        isConfirming: _isConfirming,
        isChangeMode: _isChangeMode,
        onSelectLevel: (lvl) => setState(() {
          _selectedLevel = lvl;
          _selectedSubLevel = null;
          _selectedOptionalPaperIds.clear();
        }),
        onSelectSubLevel: (sub) => setState(() {
          _selectedSubLevel = sub;
          _selectedOptionalPaperIds.clear();
        }),
        onSelectYear: (y) => setState(() => _selectedYear = y),
        onToggleOptionalPaper: (id) => setState(() {
          if (_selectedOptionalPaperIds.contains(id)) {
            _selectedOptionalPaperIds.remove(id);
          } else {
            _selectedOptionalPaperIds.add(id);
          }
        }),
        onBack: () => setState(() => _selectedProgram = null),
        onConfirm: _handleConfirm,
      );
    }
    if (_selectedFamily != null) {
      return _FamilyProgramsView(
        family: _selectedFamily!,
        programs: CourseCatalogService.instance.getProgramsByFamily(_selectedFamily!.id),
        onSelectProgram: _selectProgram,
        onBack: () => setState(() => _selectedFamily = null),
      );
    }
    if (_selectedCategory != null) {
      return _CategoryFamiliesView(
        category: _selectedCategory!,
        families: CourseCatalogService.instance.getFamiliesByCategory(_selectedCategory!.id),
        onSelectFamily: (fam) => setState(() => _selectedFamily = fam),
        onBack: () => setState(() => _selectedCategory = null),
      );
    }
    return _MasterCatalogHome(
      categories: CourseCatalogService.instance.categories2,
      popularPrograms: CourseCatalogService.instance.popularPrograms,
      onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
      onSelectProgram: _selectProgram,
    );
  }
}

// ─── PREMIUM SEARCH FIELD ─────────────────────────────────────────────

class _PremiumSearchField extends StatelessWidget {
  const _PremiumSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isFocused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return Semantics(
      label: 'Search exams and courses',
      textField: true,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        height: CourseSelectionTokens.searchHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(CourseSelectionTokens.searchRadius),
          border: Border.all(
            color: isFocused ? scheme.primary : scheme.outline.withValues(alpha: 0.9),
            width: isFocused ? 1.5 : 1,
          ),
          boxShadow: CourseSelectionTokens.cardShadow(context),
        ),
        padding: const EdgeInsets.symmetric(horizontal: CourseSelectionTokens.searchHorizontalPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              color: isFocused ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.9),
              size: CourseSelectionTokens.searchIconSize,
              semanticLabel: 'Search',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.2),
                decoration: InputDecoration(
                  hintText: 'Search exams/courses',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
            if (hasText)
              Semantics(
                button: true,
                label: 'Clear search',
                child: InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 16, color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              // Reserve space so field doesn't jump
              const SizedBox(width: 28, height: 28),
          ],
        ),
      ),
    );
  }
}

// ─── MASTER CATALOG HOME ─────────────────────────────────────────────

class _MasterCatalogHome extends StatelessWidget {
  const _MasterCatalogHome({
    required this.categories,
    required this.popularPrograms,
    required this.onSelectCategory,
    required this.onSelectProgram,
  });

  final List<CatalogCategory2> categories;
  final List<CatalogProgram> popularPrograms;
  final ValueChanged<CatalogCategory2> onSelectCategory;
  final ValueChanged<CatalogProgram> onSelectProgram;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Popular Quick Access ──
        if (popularPrograms.isNotEmpty) ...[
          Semantics(
            header: true,
            child: Text(
              'Popular Exams & Goals',
              style: theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.1),
            ),
          ),
          const SizedBox(height: CourseSelectionTokens.sectionLabelGap),
          // Responsive wrap with consistent chip height
          Wrap(
            spacing: CourseSelectionTokens.chipSpacing,
            runSpacing: CourseSelectionTokens.chipRunSpacing,
            children: popularPrograms.take(12).map((p) {
              return _PopularChip(
                label: p.displayTitle,
                onTap: () => onSelectProgram(p),
              );
            }).toList(),
          ),
          const SizedBox(height: CourseSelectionTokens.sectionGap),
        ],

        // ── All Categories ──
        Semantics(
          header: true,
          child: Text(
            'All Categories',
            style: theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.1),
          ),
        ),
        const SizedBox(height: CourseSelectionTokens.sectionLabelGap),
        // Lazy list via ListView is okay for <20 items but use Column for simplicity + avoid nested scroll
        ...categories.map((cat) => Padding(
              padding: const EdgeInsets.only(bottom: CourseSelectionTokens.cardGap),
              child: _CategoryCard(
                category: cat,
                onTap: () => onSelectCategory(cat),
              ),
            )),
        // Subtle footer hint
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 14, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tip: Search for “CA”, “JEE”, “NEET”, “SSC CGL”, “UPSC”, “GATE CSE”',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PopularChip extends StatelessWidget {
  const _PopularChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Popular: $label',
      child: Material(
        color: scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.18), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: scheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                          fontSize: 12.5,
                          letterSpacing: 0.1,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});
  final CatalogCategory2 category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: category.title,
      hint: category.description,
      child: AppCard(
        padding: CourseSelectionTokens.cardPadding,
        onTap: onTap,
        radius: CourseSelectionTokens.cardRadius,
        borderColor: scheme.outline.withValues(alpha: isDark ? 0.8 : 0.7),
        elevation: 1,
        child: SizedBox(
          // Enforce consistent min height for premium alignment
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon container — fixed 44x44
              Container(
                width: CourseSelectionTokens.iconContainerSize,
                height: CourseSelectionTokens.iconContainerSize,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(CourseSelectionTokens.iconContainerRadius),
                  border: Border.all(color: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.12), width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(category.resolvedIcon, color: scheme.primary, size: CourseSelectionTokens.iconSize),
              ),
              const SizedBox(width: 14),
              // Title / Description — baselines aligned
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.title,
                      style: CourseSelectionTokens.cardTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.description != null && category.description!.isNotEmpty) ...[
                      const SizedBox(height: CourseSelectionTokens.titleSubtitleGap),
                      Text(
                        category.description!,
                        style: CourseSelectionTokens.cardSubtitle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right chevron — always 20x20, consistent right edge
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.7), size: CourseSelectionTokens.chevronSize),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SEARCH RESULTS ─────────────────────────────────────────────────

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({required this.results, required this.onSelectProgram});

  final List<CatalogProgram> results;
  final ValueChanged<CatalogProgram> onSelectProgram;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded, size: 32, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text('No matching courses found', style: theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Try CA, JEE Main, NEET, SSC CGL, UPSC, CLAT, CUET',
                  style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'}',
            style: theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: CourseSelectionTokens.sectionLabelGap),
        ...results.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: CourseSelectionTokens.cardGap),
              child: _ProgramRowCard(program: p, onTap: () => onSelectProgram(p)),
            )),
      ],
    );
  }
}

class _ProgramRowCard extends StatelessWidget {
  const _ProgramRowCard({required this.program, required this.onTap});
  final CatalogProgram program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return AppCard(
      padding: CourseSelectionTokens.cardPadding,
      onTap: onTap,
      radius: CourseSelectionTokens.cardRadius,
      borderColor: scheme.outline.withValues(alpha: isDark ? 0.8 : 0.7),
      child: Row(
        children: [
          Container(
            width: CourseSelectionTokens.smallIconContainerSize,
            height: CourseSelectionTokens.smallIconContainerSize,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.school_rounded, color: scheme.primary, size: CourseSelectionTokens.smallIconSize),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(program.title, style: CourseSelectionTokens.cardTitle(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (program.authority != null && program.authority!.isNotEmpty) ...[
                  const SizedBox(height: CourseSelectionTokens.titleSubtitleGap),
                  Text(program.authority!, style: CourseSelectionTokens.cardSubtitle(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.7), size: CourseSelectionTokens.chevronSize),
        ],
      ),
    );
  }
}

// ─── CATEGORY FAMILIES ──────────────────────────────────────────────

class _CategoryFamiliesView extends StatelessWidget {
  const _CategoryFamiliesView({required this.category, required this.families, required this.onSelectFamily, required this.onBack});

  final CatalogCategory2 category;
  final List<CatalogFamily> families;
  final ValueChanged<CatalogFamily> onSelectFamily;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackHeader(title: category.title, subtitle: 'Select Exam Family', onBack: onBack),
        const SizedBox(height: 12),
        if (families.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No programs available in this category', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
          )
        else
          ...families.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: CourseSelectionTokens.cardGap),
                child: _FamilyCard(family: f, onTap: () => onSelectFamily(f)),
              )),
      ],
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.family, required this.onTap});
  final CatalogFamily family;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return AppCard(
      padding: CourseSelectionTokens.cardPadding,
      onTap: onTap,
      radius: CourseSelectionTokens.cardRadius,
      borderColor: scheme.outline.withValues(alpha: isDark ? 0.8 : 0.7),
      child: Row(
        children: [
          Container(
            width: CourseSelectionTokens.smallIconContainerSize,
            height: CourseSelectionTokens.smallIconContainerSize,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(family.resolvedIcon, color: scheme.primary, size: CourseSelectionTokens.smallIconSize),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(family.title, style: CourseSelectionTokens.cardTitle(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (family.description != null) ...[
                  const SizedBox(height: CourseSelectionTokens.titleSubtitleGap),
                  Text(family.description!, style: CourseSelectionTokens.cardSubtitle(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.7), size: CourseSelectionTokens.chevronSize),
        ],
      ),
    );
  }
}

// ─── FAMILY PROGRAMS ────────────────────────────────────────────────

class _FamilyProgramsView extends StatelessWidget {
  const _FamilyProgramsView({required this.family, required this.programs, required this.onSelectProgram, required this.onBack});

  final CatalogFamily family;
  final List<CatalogProgram> programs;
  final ValueChanged<CatalogProgram> onSelectProgram;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackHeader(title: family.title, subtitle: 'Select Program', onBack: onBack),
        const SizedBox(height: 12),
        if (programs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No programs in this family', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
          )
        else
          ...programs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: CourseSelectionTokens.cardGap),
                child: _ProgramRowCard(program: p, onTap: () => onSelectProgram(p)),
              )),
      ],
    );
  }
}

// ─── PROGRAM DETAIL & CONFIRMATION ──────────────────────────────────

class _ProgramDetailView extends StatelessWidget {
  const _ProgramDetailView({
    required this.program,
    required this.selectedLevel,
    required this.selectedSubLevel,
    required this.selectedYear,
    required this.selectedOptionalIds,
    required this.isConfirming,
    required this.isChangeMode,
    required this.onSelectLevel,
    required this.onSelectSubLevel,
    required this.onSelectYear,
    required this.onToggleOptionalPaper,
    required this.onBack,
    required this.onConfirm,
  });

  final CatalogProgram program;
  final CatalogLevel? selectedLevel;
  final CatalogLevel? selectedSubLevel;
  final String selectedYear;
  final Set<String> selectedOptionalIds;
  final bool isConfirming;
  final bool isChangeMode;
  final ValueChanged<CatalogLevel> onSelectLevel;
  final ValueChanged<CatalogLevel> onSelectSubLevel;
  final ValueChanged<String> onSelectYear;
  final ValueChanged<String> onToggleOptionalPaper;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeLevel = selectedLevel ?? (program.levels.isNotEmpty ? program.levels.first : null);

    final resolved = CourseCatalogService.instance.resolvePapersForProgram(
      programId: program.id,
      levelId: activeLevel?.id,
      subLevelId: selectedSubLevel?.id,
    );

    final compulsoryPapers = resolved['compulsory'] ?? [];
    final optionalPapers = resolved['optional'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackHeader(
          title: program.title,
          subtitle: program.authority != null ? '${program.authority} · $selectedYear' : 'Syllabus $selectedYear',
          onBack: onBack,
        ),
        const SizedBox(height: 16),

        // ── Year selector if multiple years available ──
        if (program.availableYears.length > 1) ...[
          Text('Syllabus Year', style: theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: CourseSelectionTokens.levelChipSpacing,
            runSpacing: CourseSelectionTokens.levelChipSpacing,
            children: program.availableYears.map((y) {
              final isSel = y == selectedYear;
              return _LevelChip(label: y, selected: isSel, onTap: () => onSelectYear(y));
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // ── Level Selector if Multiple Levels ──
        if (program.levels.length > 1) ...[
          Text('Select Level / Stream', style: theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: CourseSelectionTokens.levelChipSpacing,
            runSpacing: CourseSelectionTokens.levelChipSpacing,
            children: program.levels.map((lvl) {
              final isSelected = lvl.id == activeLevel?.id;
              return _LevelChip(label: lvl.displayTitle, selected: isSelected, onTap: () => onSelectLevel(lvl));
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // ── Sub-level / Group Selector if active level has children ──
        if (activeLevel != null && activeLevel.children.isNotEmpty) ...[
          Text('Select Section / Group', style: theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: CourseSelectionTokens.levelChipSpacing,
            runSpacing: CourseSelectionTokens.levelChipSpacing,
            children: activeLevel.children.map((sub) {
              final isSelected = sub.id == selectedSubLevel?.id;
              return _LevelChip(label: sub.displayTitle, selected: isSelected, onTap: () => onSelectSubLevel(sub));
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // ── Compulsory Papers ──
        if (compulsoryPapers.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Core Papers',
                style: theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.primary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                child: Text('${compulsoryPapers.length}', style: theme.textTheme.labelSmall!.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...compulsoryPapers.map((paper) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.7)),
                boxShadow: CourseSelectionTokens.cardShadow(context),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, color: scheme.primary, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(paper.title, style: theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600, height: 1.25)),
                        if (paper.description != null && paper.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(paper.description!, style: theme.textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant, fontSize: 11.5, height: 1.3)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        // ── Optional / Elective Papers ──
        if (optionalPapers.isNotEmpty) ...[
          Text('Optional / Elective', style: theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...optionalPapers.map((paper) {
            final isChecked = selectedOptionalIds.contains(paper.id);
            return Semantics(
              button: true,
              checked: isChecked,
              label: paper.title,
              child: InkWell(
                onTap: () => onToggleOptionalPaper(paper.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isChecked ? scheme.primary.withValues(alpha: 0.08) : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isChecked ? scheme.primary : scheme.outline.withValues(alpha: 0.7), width: isChecked ? 1.5 : 1),
                    boxShadow: CourseSelectionTokens.cardShadow(context),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: isChecked,
                          onChanged: (_) => onToggleOptionalPaper(paper.id),
                          activeColor: scheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          paper.title,
                          style: theme.textTheme.bodyMedium!.copyWith(fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500, color: isChecked ? scheme.primary : scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        // ── Premium Summary: YOUR GOAL ──
        _GoalSummaryCard(
          program: program,
          level: activeLevel,
          subLevel: selectedSubLevel,
          year: selectedYear,
          compulsoryCount: compulsoryPapers.length,
          optionalSelected: selectedOptionalIds.length,
        ),
        const SizedBox(height: 16),

        // ── Primary CTA ──
        SizedBox(
          height: CourseSelectionTokens.primaryButtonHeight,
          child: FilledButton(
            onPressed: isConfirming ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CourseSelectionTokens.primaryButtonRadius)),
              padding: CourseSelectionTokens.primaryButtonPadding,
              textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
              elevation: 0,
            ),
            child: isConfirming
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isChangeMode ? 'Switch Course' : 'Continue'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your previous data will be preserved. Only your active academic context will change.',
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.8), width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: selected ? 0 : 0,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: selected ? scheme.onPrimary : (isDark ? scheme.onSurface : scheme.onSurfaceVariant),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.program,
    required this.level,
    required this.subLevel,
    required this.year,
    required this.compulsoryCount,
    required this.optionalSelected,
  });

  final CatalogProgram program;
  final CatalogLevel? level;
  final CatalogLevel? subLevel;
  final String year;
  final int compulsoryCount;
  final int optionalSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final levelName = subLevel?.title ?? level?.title ?? program.title;
    final total = compulsoryCount + optionalSelected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: isDark ? 0.25 : 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(6)),
                child: Text('YOUR GOAL', style: theme.textTheme.labelSmall!.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 10)),
              ),
              const Spacer(),
              Icon(Icons.flag_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Text('PREMIUM', style: theme.textTheme.labelSmall!.copyWith(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 12),
          Text(program.title, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MetaPill(label: levelName),
              _MetaPill(label: year),
              if (program.authority != null) _MetaPill(label: program.authority!),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('$total subjects · $compulsoryCount core${optionalSelected > 0 ? ' + $optionalSelected elective' : ''}',
                  style: theme.textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(999), border: Border.all(color: scheme.outline.withValues(alpha: 0.6))),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.title, required this.subtitle, required this.onBack});
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          label: 'Back',
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: scheme.outline.withValues(alpha: 0.7))),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBack,
              child: const SizedBox(width: 40, height: 40, child: Center(child: Icon(Icons.arrow_back_rounded, size: 18))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Text(subtitle, style: theme.textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── CONFIRMATION DIALOG ───────────────────────────────────────────

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog({required this.currentCourse, required this.newSelection, required this.onConfirm});

  final String currentCourse;
  final ActiveCourseSelection newSelection;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.swap_horiz_rounded, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Switch Active Course', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are switching your active academic goal to:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('CURRENT: ', style: theme.textTheme.labelSmall!.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                      Expanded(child: Text(currentCourse, style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 2)),
                    ],
                  ),
                  Divider(height: 20, color: scheme.outline.withValues(alpha: 0.5)),
                  Row(
                    children: [
                      Text('NEW: ', style: theme.textTheme.labelSmall!.copyWith(color: scheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                      Expanded(child: Text(newSelection.fullDisplayName, style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w700, color: scheme.primary), overflow: TextOverflow.ellipsis, maxLines: 2)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF16B88A).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF16B88A).withValues(alpha: 0.18))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF16B88A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Your previous course data will be preserved. Only your active academic context will change.',
                        style: theme.textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Switch Course'),
        ),
      ],
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
