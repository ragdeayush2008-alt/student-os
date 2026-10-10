import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/animations/animated_entrance.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/design/onboarding_design_tokens.dart';
import '../../../core/design/goal_icon_mapping.dart';
import '../../../core/design/premium_goal_card.dart';
import '../../../core/design/onboarding_ambient_background.dart';
import '../../../core/services/course_catalog_service.dart';
import '../../../core/services/student_service.dart';
import '../../guides/guide_progress_store.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/student_os_auth_shell.dart';
import '../../../data/models/catalog/active_course_selection.dart';
import '../../../data/models/catalog/catalog_category.dart';
import '../../../data/models/catalog/catalog_family.dart';
import '../../../data/models/catalog/catalog_level.dart';
import '../../../data/models/catalog/catalog_program.dart';
import '../../../data/models/student_profile.dart';
import '../../catalog/course_selection_tokens.dart';

/// Onboarding — Modern Academic Command Center (Unified Course Selection 2.0).
///
/// Single authoritative course-selection: shares catalog source, hierarchy,
/// and visual language with Profile → Change Course (CourseSelectionScreen).
///
/// Flow: Name → Unified Goal Picker (adaptive Category→Family→Program→Level→Papers) → Goals & Confirmation
/// No duplicate catalog data, no six fixed steps, no separate selection architecture.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.isEditMode = false});

  final bool isEditMode;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  int _step = 0;
  static const int _totalSteps = 3;
  bool _saving = false;

  // Unified Catalog 2.0 selection state — same source as CourseSelectionScreen
  CatalogCategory2? _selectedCategory;
  CatalogFamily? _selectedFamily;
  CatalogProgram? _selectedProgram;
  CatalogLevel? _selectedLevel;
  CatalogLevel? _selectedSubLevel;
  String _selectedYear = '2026';
  final Set<String> _selectedOptionalPaperIds = <String>{};

  bool _isSearching = false;
  List<CatalogProgram> _searchResults = [];

  // Goals & focus
  final Set<StudentGoal> _selectedGoals = <StudentGoal>{};
  AcademicFocus? _academicFocus;

  @override
  void initState() {
    super.initState();
    CourseCatalogService.instance.ensureInitialized();
    _restoreExistingData();
  }

  void _restoreExistingData() {
    final profile = StudentService.instance.profile;
    _nameCtrl.text = profile.displayName;

    // Restore from authoritative ActiveCourseSelection if present, else legacy profile
    final active = CourseCatalogService.instance.activeCourseSelection;
    if (active != null && active.programId.isNotEmpty) {
      final program = CourseCatalogService.instance.getProgramById(active.programId);
      if (program != null) {
        _selectedProgram = program;
        _selectedCategory = CourseCatalogService.instance.getCategoryById(program.categoryId);
        _selectedFamily = CourseCatalogService.instance.getFamilyById(program.familyId);
        _selectedYear = active.year;
        _selectedOptionalPaperIds.addAll(active.selectedPaperIds);
        if (active.levelId.isNotEmpty) {
          for (final lvl in program.levels) {
            final found = lvl.findLevelById(active.levelId);
            if (found != null) {
              _selectedLevel = found;
              break;
            }
            if (lvl.id == active.levelId) {
              _selectedLevel = lvl;
              break;
            }
          }
          _selectedLevel ??= program.levels.firstOrNull;
        }
        if (active.subLevelId != null && active.subLevelId!.isNotEmpty && _selectedLevel != null) {
          for (final child in _selectedLevel!.children) {
            if (child.id == active.subLevelId) {
              _selectedSubLevel = child;
              break;
            }
            final deep = child.findLevelById(active.subLevelId!);
            if (deep != null) {
              _selectedSubLevel = deep;
              break;
            }
          }
        }
      }
    } else if (profile.catalogCourseId != null) {
      final program = CourseCatalogService.instance.getProgramById(profile.catalogCourseId!);
      if (program != null) {
        _selectedProgram = program;
        _selectedCategory = CourseCatalogService.instance.getCategoryById(program.categoryId);
        _selectedFamily = CourseCatalogService.instance.getFamilyById(program.familyId);
        _selectedYear = program.defaultYear;
        _selectedOptionalPaperIds.addAll(profile.selectedOptionalSubjectIds);
      }
    }

    if (profile.catalogCourseId != null && _selectedCategory == null && profile.catalogCategory != null) {
      // Legacy fallback: map old category to new if possible — not critical
    }

    _selectedGoals.addAll(profile.goals);
    _academicFocus = profile.academicFocus;
    if (_selectedProgram != null && _selectedLevel == null && _selectedProgram!.levels.isNotEmpty) {
      _selectedLevel = _selectedProgram!.levels.first;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
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

  bool get _isCourseStepComplete {
    if (_selectedProgram == null) return false;
    if (_selectedProgram!.levels.length > 1 && _selectedLevel == null) return false;
    final active = _selectedLevel ?? _selectedProgram!.levels.firstOrNull;
    if (active != null && active.children.isNotEmpty && _selectedSubLevel == null) {
      // Allow completion without sub-level if group not required? Require selection for premium UX when children exist
      return false;
    }
    return true;
  }

  bool _canAdvance() {
    return switch (_step) {
      0 => _nameCtrl.text.trim().isNotEmpty || widget.isEditMode,
      1 => _isCourseStepComplete,
      2 => true,
      _ => true,
    };
  }

  void _next() {
    if (!_canAdvance()) return;
    if (_step < _totalSteps - 1) {
      _pageController.nextPage(duration: AppDurations.normal, curve: AppCurves.standard);
    }
  }

  void _back() {
    // If inside course picker hierarchy, navigate back within it first
    if (_step == 1) {
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
    }
    if (_step > 0) {
      _pageController.previousPage(duration: AppDurations.normal, curve: AppCurves.standard);
    } else if (widget.isEditMode) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _complete() async {
    if (_saving || _selectedProgram == null) return;
    setState(() => _saving = true);

    try {
      final program = _selectedProgram!;
      final levelTitle = _selectedSubLevel?.title ?? _selectedLevel?.title ?? program.title;
      final levelId = _selectedLevel?.id ?? program.levels.firstOrNull?.id ?? '';

      final displayName = _nameCtrl.text.trim();
      if (displayName.isNotEmpty) {
        await StudentService.instance.updateDisplayName(displayName);
      }

      final selection = ActiveCourseSelection(
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

      // Single authoritative write — provisions subjects, syncs profile, persists offline, user-isolated
      await CourseCatalogService.instance.setActiveCourse(
        selection,
        provisionSubjects: true,
        selectedOptionalPaperIds: _selectedOptionalPaperIds.toList(),
      );

      if (_selectedGoals.isNotEmpty) {
        await StudentService.instance.updateGoals(_selectedGoals.toList());
      }
      if (_academicFocus != null) {
        await StudentService.instance.updateAcademicFocus(_academicFocus);
      }

      await StudentService.instance.completeOnboarding();

      if (!widget.isEditMode) {
        // Fresh onboarding only: offer the 60-second interactive tour once
        // on Home. Edit mode never re-triggers the offer.
        try {
          await GuideProgressStore.instance.load();
          await GuideProgressStore.instance.setTourOfferPending(true);
        } catch (_) {}
      }

      if (widget.isEditMode && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete setup: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canAdvance = _canAdvance();
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      // Premium tonal backdrop: ivory → sage whisper (light),
      // deep emerald depth (dark). Extremely subtle by design.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  AppColors.veryDeepEmerald,
                  AppColors.deepForestDark,
                  AppColors.deepForestDark,
                ]
              : const [
                  AppColors.naturalWhite,
                  AppColors.mist,
                  AppColors.paleSage,
                ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(
              child: OnboardingAmbientBackground(),
            ),
            SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: CourseSelectionTokens.maxContentWidth),
            child: Column(
              children: [
                // ── Top Bar: back + progress ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: _step == 0 && widget.isEditMode ? 'Close' : 'Back',
                        child: Material(
                          color: scheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: scheme.outline)),
                          elevation: 1,
                          shadowColor: scheme.shadow.withValues(alpha: 0.12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _step == 0 && !widget.isEditMode ? null : _back,
                            child: SizedBox(
                              width: CourseSelectionTokens.headerBackButtonSize,
                              height: CourseSelectionTokens.headerBackButtonSize,
                              child: Center(
                                child: Icon(
                                  _step == 0 && !widget.isEditMode ? Icons.circle_outlined : Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: _step == 0 && !widget.isEditMode ? Colors.transparent : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: AnimatedEntrance(
                            duration: AppDurations.fast,
                            child: _OnboardingSegmentedProgress(step: _step, total: _totalSteps),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // ── Page View ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _step = i),
                    children: [
                      _NameStep(nameCtrl: _nameCtrl, isEditMode: widget.isEditMode, onChanged: () => setState(() {})),
                      _UnifiedCourseStep(
                        selectedCategory: _selectedCategory,
                        selectedFamily: _selectedFamily,
                        selectedProgram: _selectedProgram,
                        selectedLevel: _selectedLevel,
                        selectedSubLevel: _selectedSubLevel,
                        selectedYear: _selectedYear,
                        selectedOptionalIds: _selectedOptionalPaperIds,
                        isSearching: _isSearching,
                        searchResults: _searchResults,
                        searchCtrl: _searchCtrl,
                        searchFocus: _searchFocus,
                        onSearchChanged: _onSearchChanged,
                        onSelectCategory: (c) => setState(() => _selectedCategory = c),
                        onSelectFamily: (f) => setState(() => _selectedFamily = f),
                        onSelectProgram: _selectProgram,
                        onSelectLevel: (l) => setState(() {
                          _selectedLevel = l;
                          _selectedSubLevel = null;
                          _selectedOptionalPaperIds.clear();
                        }),
                        onSelectSubLevel: (s) => setState(() {
                          _selectedSubLevel = s;
                          _selectedOptionalPaperIds.clear();
                        }),
                        onSelectYear: (y) => setState(() => _selectedYear = y),
                        onToggleOptional: (id) => setState(() {
                          if (_selectedOptionalPaperIds.contains(id)) {
                            _selectedOptionalPaperIds.remove(id);
                          } else {
                            _selectedOptionalPaperIds.add(id);
                          }
                        }),
                        onBackToCategories: () => setState(() => _selectedCategory = null),
                        onBackToFamilies: () => setState(() => _selectedFamily = null),
                        onBackToPrograms: () => setState(() => _selectedProgram = null),
                        onClearSearch: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      ),
                      _GoalsAndConfirmationStep(
                        program: _selectedProgram,
                        level: _selectedLevel,
                        subLevel: _selectedSubLevel,
                        year: _selectedYear,
                        selectedOptionalIds: _selectedOptionalPaperIds,
                        selectedGoals: _selectedGoals,
                        academicFocus: _academicFocus,
                        onToggleGoal: (g) => setState(() {
                          if (_selectedGoals.contains(g)) {
                            _selectedGoals.remove(g);
                          } else {
                            _selectedGoals.add(g);
                          }
                        }),
                        onSelectFocus: (f) => setState(() => _academicFocus = f),
                      ),
                    ],
                  ),
                ),

                // ── Bottom Action Bar ──
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset * 0.2),
                    child: SizedBox(
                      width: double.infinity,
                      height: CourseSelectionTokens.primaryButtonHeight,
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : OnboardingDesignTokens.durationNormal,
                        curve: OnboardingDesignTokens.curveNormal,
                        decoration: (canAdvance && !_saving)
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    CourseSelectionTokens
                                        .primaryButtonRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: scheme.primary
                                        .withValues(alpha: 0.15),
                                    blurRadius: 36,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              )
                            : null,
                        child: FilledButton.icon(
                          onPressed: (canAdvance && !_saving)
                              ? (_step == _totalSteps - 1
                                  ? _complete
                                  : _next)
                              : null,
                          icon: _saving
                              ? const SizedBox.shrink()
                              : const Icon(Icons.arrow_forward_rounded,
                                  size: 18),
                          label: _saving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              scheme.onPrimary)))
                              : Text(
                                  _step == _totalSteps - 1
                                      ? (widget.isEditMode
                                          ? 'Update & Continue'
                                          : 'Create Subjects & Launch')
                                      : 'Continue',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            disabledBackgroundColor: AppColors.paleSage
                                .withValues(alpha: 0.5),
                            disabledForegroundColor: scheme.onSurfaceVariant
                                .withValues(alpha: 0.55),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    CourseSelectionTokens
                                        .primaryButtonRadius)),
                            padding:
                                CourseSelectionTokens.primaryButtonPadding,
                            textStyle: theme.textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                            elevation: (canAdvance && !_saving) ? 3 : 0,
                            shadowColor:
                                scheme.primary.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
          ],
        ),
      ),
    );
  }
}

/// Premium segmented progress: active segment glows emerald with a tiny
/// traveling highlight on entry; completed = muted emerald; remaining = sage.
/// Respects reduced motion. Full screen-reader semantics.
class _OnboardingSegmentedProgress extends StatefulWidget {
  const _OnboardingSegmentedProgress({required this.step, required this.total});
  final int step;
  final int total;

  @override
  State<_OnboardingSegmentedProgress> createState() =>
      _OnboardingSegmentedProgressState();
}

class _OnboardingSegmentedProgressState
    extends State<_OnboardingSegmentedProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _sheen;
  late Animation<double> _sheenPos;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _sheenPos = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _sheen, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context)) {
      // One gentle sweep on entry — not looping.
      Future.microtask(() {
        if (mounted && !_sheen.isAnimating && _sheen.value == 0) {
          _sheen.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clamped = widget.step.clamp(0, widget.total - 1);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Step ${clamped + 1} of ${widget.total}',
      value: '${(((clamped + 1) / widget.total) * 100).round()} percent complete',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STEP ${clamped + 1} OF ${widget.total}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < widget.total; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  flex: i == clamped ? 2 : 1,
                  child: AnimatedContainer(
                    duration:
                        reduceMotion ? Duration.zero : AppDurations.fast,
                    curve: AppCurves.standard,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < clamped
                          ? scheme.primary.withValues(alpha: 0.45)
                          : i == clamped
                              ? scheme.primary
                              : (isDark
                                  ? scheme.surfaceContainerHighest
                                  : AppColors.paleSage),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: i == clamped
                          ? [
                              BoxShadow(
                                color: scheme.primary
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: i == clamped && !reduceMotion
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: AnimatedBuilder(
                              animation: _sheenPos,
                              builder: (context, _) {
                                return Stack(
                                  children: [
                                    Positioned(
                                      left: _sheenPos.value * 60 - 30,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 30,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white
                                                  .withValues(alpha: 0),
                                              Colors.white
                                                  .withValues(alpha: 0.45),
                                              Colors.white
                                                  .withValues(alpha: 0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── STEP 0: NAME ───────────────────────────────────────────────────

class _NameStep extends StatelessWidget {
  const _NameStep({required this.nameCtrl, required this.isEditMode, required this.onChanged});
  final TextEditingController nameCtrl;
  final bool isEditMode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Center(child: StudentOSBrandMark(size: 64, iconSize: 32)),
            const SizedBox(height: 24),
            Text(isEditMode ? 'Edit Education Setup' : 'Welcome to Student OS', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(isEditMode ? 'Update your course, level, and subjects safely.' : 'Set up your academic goal once. Student OS handles the rest.', style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Text('YOUR NAME', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              onChanged: (_) => onChanged(),
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g. Alex Sharma',
                filled: true,
                fillColor: scheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outline)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outline)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary, width: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STEP 1: UNIFIED COURSE SELECTION (Same catalog + UI as Change Course) ──

class _UnifiedCourseStep extends StatelessWidget {
  const _UnifiedCourseStep({
    required this.selectedCategory,
    required this.selectedFamily,
    required this.selectedProgram,
    required this.selectedLevel,
    required this.selectedSubLevel,
    required this.selectedYear,
    required this.selectedOptionalIds,
    required this.isSearching,
    required this.searchResults,
    required this.searchCtrl,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.onSelectCategory,
    required this.onSelectFamily,
    required this.onSelectProgram,
    required this.onSelectLevel,
    required this.onSelectSubLevel,
    required this.onSelectYear,
    required this.onToggleOptional,
    required this.onBackToCategories,
    required this.onBackToFamilies,
    required this.onBackToPrograms,
    required this.onClearSearch,
  });

  final CatalogCategory2? selectedCategory;
  final CatalogFamily? selectedFamily;
  final CatalogProgram? selectedProgram;
  final CatalogLevel? selectedLevel;
  final CatalogLevel? selectedSubLevel;
  final String selectedYear;
  final Set<String> selectedOptionalIds;
  final bool isSearching;
  final List<CatalogProgram> searchResults;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CatalogCategory2> onSelectCategory;
  final ValueChanged<CatalogFamily> onSelectFamily;
  final ValueChanged<CatalogProgram> onSelectProgram;
  final ValueChanged<CatalogLevel> onSelectLevel;
  final ValueChanged<CatalogLevel> onSelectSubLevel;
  final ValueChanged<String> onSelectYear;
  final ValueChanged<String> onToggleOptional;
  final VoidCallback onBackToCategories;
  final VoidCallback onBackToFamilies;
  final VoidCallback onBackToPrograms;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    // Wrap in SingleChildScrollView for narrow screens, but inner lists use shrinkWrap Column instead of nested ListView to avoid overflow
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: CourseSelectionTokens.horizontalMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Hero with subtle radial glow + staggered entrance (eyebrow → title → subtitle).
          Stack(
            alignment: Alignment.topCenter,
            children: [
              IgnorePointer(
                child: Container(
                  width: 320,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.10),
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  AnimatedEntrance(
                    duration: AppDurations.fast,
                    child: Text(
                      'TELL STUDENT OS YOUR GOAL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedEntrance(
                    duration: AppDurations.fast,
                    delay: const Duration(milliseconds: 70),
                    child: Text('Select Your Goal',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                height: 1.05),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 8),
                  AnimatedEntrance(
                    duration: AppDurations.fast,
                    delay: const Duration(milliseconds: 140),
                    child: Text(
                        'Choose what you are preparing for. Student OS adapts to you.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                height: 1.45),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Premium search field — layered surface with focus glow.
          AnimatedEntrance(
            duration: AppDurations.fast,
            delay: const Duration(milliseconds: 200),
            child: _OnboardingSearchField(
                controller: searchCtrl,
                focusNode: searchFocus,
                onChanged: onSearchChanged,
                onClear: onClearSearch),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: AppDurations.fast,
            switchInCurve: AppCurves.entrance,
            switchOutCurve: AppCurves.exit,
            transitionBuilder: (child, animation) {
              final reduce =
                  MediaQuery.disableAnimationsOf(context);
              if (reduce) {
                return child;
              }
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: _buildInner(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInner(BuildContext context) {
    if (isSearching) {
      return _OnboardingSearchResults(results: searchResults, onSelectProgram: onSelectProgram, key: const ValueKey('search'));
    }
    if (selectedProgram != null) {
      return _OnboardingProgramDetail(
        key: ValueKey('prog_${selectedProgram!.id}'),
        program: selectedProgram!,
        selectedLevel: selectedLevel,
        selectedSubLevel: selectedSubLevel,
        selectedYear: selectedYear,
        selectedOptionalIds: selectedOptionalIds,
        onSelectLevel: onSelectLevel,
        onSelectSubLevel: onSelectSubLevel,
        onSelectYear: onSelectYear,
        onToggleOptional: onToggleOptional,
        onBack: onBackToPrograms,
      );
    }
    if (selectedFamily != null) {
      return _OnboardingFamilyPrograms(
        key: ValueKey('fam_${selectedFamily!.id}'),
        family: selectedFamily!,
        programs: CourseCatalogService.instance.getProgramsByFamily(selectedFamily!.id),
        onSelectProgram: onSelectProgram,
        onBack: onBackToFamilies,
      );
    }
    if (selectedCategory != null) {
      return _OnboardingCategoryFamilies(
        key: ValueKey('cat_${selectedCategory!.id}'),
        category: selectedCategory!,
        families: CourseCatalogService.instance.getFamiliesByCategory(selectedCategory!.id),
        onSelectFamily: onSelectFamily,
        onBack: onBackToCategories,
      );
    }
    return _OnboardingHome(
      key: const ValueKey('home'),
      categories: CourseCatalogService.instance.categories2,
      popularPrograms: CourseCatalogService.instance.popularPrograms,
      onSelectCategory: onSelectCategory,
      onSelectProgram: onSelectProgram,
    );
  }
}

class _OnboardingSearchField extends StatefulWidget {
  const _OnboardingSearchField(
      {required this.controller,
      required this.focusNode,
      required this.onChanged,
      required this.onClear});
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_OnboardingSearchField> createState() => _OnboardingSearchFieldState();
}

class _OnboardingSearchFieldState extends State<_OnboardingSearchField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant _OnboardingSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
  }

  void _onFocus() {
    if (mounted) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  void _onText() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFocused = _focused;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Search exams, courses or goals',
      textField: true,
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : OnboardingDesignTokens.durationSnappy,
        curve: OnboardingDesignTokens.curveSnappy,
        height: CourseSelectionTokens.searchHeight,
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerLow : AppColors.naturalWhite,
          borderRadius:
              BorderRadius.circular(CourseSelectionTokens.searchRadius),
          border: Border.all(
              color: isFocused
                  ? scheme.primary
                  : AppColors.paleSage.withValues(alpha: 0.5),
              width: isFocused ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: isFocused
                  ? scheme.primary.withValues(alpha: 0.18)
                  : scheme.shadow.withValues(alpha: 0.05),
              blurRadius: isFocused ? 20 : 10,
              offset: const Offset(0, 4),
            ),
            if (isFocused)
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: CourseSelectionTokens.searchHorizontalPadding),
        child: Row(
          children: [
            AnimatedScale(
              duration: reduceMotion
                  ? Duration.zero
                  : OnboardingDesignTokens.durationSnappy,
              scale: isFocused ? 1.1 : 1.0,
              child: AnimatedOpacity(
                duration: reduceMotion
                    ? Duration.zero
                    : OnboardingDesignTokens.durationSnappy,
                opacity: isFocused ? 1.0 : 0.75,
                child: Icon(Icons.search_rounded,
                    color: isFocused
                        ? scheme.primary
                        : scheme.onSurfaceVariant
                            .withValues(alpha: 0.9),
                    size: CourseSelectionTokens.searchIconSize),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Search exams, courses or goals',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.65)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (widget.controller.text.isNotEmpty)
              InkWell(
                onTap: widget.onClear,
                borderRadius: BorderRadius.circular(20),
                child: Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: scheme.onSurface.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.close_rounded, size: 16, color: scheme.onSurfaceVariant)),
              )
            else
              const SizedBox(width: 28),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHome extends StatelessWidget {
  const _OnboardingHome({super.key, required this.categories, required this.popularPrograms, required this.onSelectCategory, required this.onSelectProgram});
  final List<CatalogCategory2> categories;
  final List<CatalogProgram> popularPrograms;
  final ValueChanged<CatalogCategory2> onSelectCategory;
  final ValueChanged<CatalogProgram> onSelectProgram;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 900;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (popularPrograms.isNotEmpty) ...[
          AnimatedEntrance(
            duration: AppDurations.fast,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'POPULAR GOALS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  'Popular Exams & Goals',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 12),
                _PopularGoalsGrid(
                  programs: popularPrograms.take(8).toList(),
                  onSelectProgram: onSelectProgram,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
        AnimatedEntrance(
          duration: AppDurations.fast,
          delay: const Duration(milliseconds: 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'EXPLORE ALL PATHS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Text(
                'All Categories',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 12),
              ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: OnboardingDesignTokens.gapCards),
                    child: _OnboardingCategoryCardPremium(category: cat, onTap: () => onSelectCategory(cat)),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Responsive grid for popular goals: 4 columns on desktop, 2-3 on tablet, 2 on mobile.
class _PopularGoalsGrid extends StatelessWidget {
  const _PopularGoalsGrid({
    required this.programs,
    required this.onSelectProgram,
    required this.isMobile,
    required this.isTablet,
  });

  final List<CatalogProgram> programs;
  final ValueChanged<CatalogProgram> onSelectProgram;
  final bool isMobile;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: OnboardingDesignTokens.gapCards,
        crossAxisSpacing: OnboardingDesignTokens.gapCards,
        // Taller than square so icon aura + title + category breathe.
        childAspectRatio: 0.88,
      ),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        return PremiumGoalCard(
          title: programs[index].displayTitle,
          onTap: () => onSelectProgram(programs[index]),
        );
      },
    );
  }
}

/// Premium category card with icon capsule, layered surface, and interactive arrow.
/// Replaces flat settings-style rows with tactile, luminous, premium surfaces.
class _OnboardingCategoryCardPremium extends StatelessWidget {
  const _OnboardingCategoryCardPremium(
      {required this.category, required this.onTap});
  final CatalogCategory2 category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = GoalIconMapping.getTintForGoal(category.title);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: category.title,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(OnboardingDesignTokens.radiusCard),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius:
                BorderRadius.circular(OnboardingDesignTokens.radiusCard),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: OnboardingDesignTokens.paddingCard,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    OnboardingDesignTokens.radiusCard),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.4),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark
                        ? scheme.surfaceContainerLow
                        : AppColors.paleSage.withValues(alpha: 0.2),
                    isDark ? scheme.surfaceContainerLow : Colors.white,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tint.withValues(alpha: 0.12),
                          tint.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tint.withValues(alpha: 0.15),
                          border: Border.all(
                            color: tint.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            category.resolvedIcon,
                            color: tint,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? scheme.onSurface
                                    : AppColors.deepForest,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            category.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.08),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: scheme.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSearchResults extends StatelessWidget {
  const _OnboardingSearchResults({super.key, required this.results, required this.onSelectProgram});
  final List<CatalogProgram> results;
  final ValueChanged<CatalogProgram> onSelectProgram;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Column(children: [Icon(Icons.search_off_rounded, size: 40, color: scheme.onSurfaceVariant), const SizedBox(height: 12), Text('No matching courses found', style: Theme.of(context).textTheme.titleSmall), Text('Try CA, JEE, NEET, SSC, UPSC, CLAT…', style: Theme.of(context).textTheme.bodySmall)])),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${results.length} results', style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...results.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: CourseSelectionTokens.cardGap),
              child: _GoalListTile(
                icon: Icons.school_rounded,
                title: p.title,
                subtitle: p.authority,
                onTap: () => onSelectProgram(p),
              ),
            )),
      ],
    );
  }
}

/// Shared tonal list tile for search results, families, and programs.
/// One coherent geometry: sage-tinted icon, two-line text, arrow affordance.
class _GoalListTile extends StatelessWidget {
  const _GoalListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: isDark ? scheme.surfaceContainerLow : AppColors.naturalWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CourseSelectionTokens.cardRadius),
          side: BorderSide(color: scheme.outline.withValues(alpha: isDark ? 0.7 : 0.6), width: 1),
        ),
        elevation: 1,
        shadowColor: scheme.shadow.withValues(alpha: 0.07),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: CourseSelectionTokens.cardPadding,
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12), borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Icon(icon, color: scheme.primary, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: CourseSelectionTokens.cardTitle(context), maxLines: 1, overflow: TextOverflow.ellipsis), if (subtitle != null && subtitle!.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle!, style: CourseSelectionTokens.cardSubtitle(context), maxLines: 2, overflow: TextOverflow.ellipsis)]])),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.7), size: CourseSelectionTokens.chevronSize),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OnboardingCategoryFamilies extends StatelessWidget {
  const _OnboardingCategoryFamilies({super.key, required this.category, required this.families, required this.onSelectFamily, required this.onBack});
  final CatalogCategory2 category;
  final List<CatalogFamily> families;
  final ValueChanged<CatalogFamily> onSelectFamily;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OnboardingBackHeader(title: category.title, subtitle: 'Select Exam Family', onBack: onBack),
        const SizedBox(height: 12),
        ...families.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: CourseSelectionTokens.cardGap),
              child: _GoalListTile(
                icon: f.resolvedIcon,
                title: f.title,
                subtitle: f.description,
                onTap: () => onSelectFamily(f),
              ),
            )),
      ],
    );
  }
}

class _OnboardingFamilyPrograms extends StatelessWidget {
  const _OnboardingFamilyPrograms({super.key, required this.family, required this.programs, required this.onSelectProgram, required this.onBack});
  final CatalogFamily family;
  final List<CatalogProgram> programs;
  final ValueChanged<CatalogProgram> onSelectProgram;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OnboardingBackHeader(title: family.title, subtitle: 'Select Program', onBack: onBack),
        const SizedBox(height: 12),
        ...programs.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: CourseSelectionTokens.cardGap),
              child: AppCard(
                padding: CourseSelectionTokens.cardPadding,
                onTap: () => onSelectProgram(p),
                radius: CourseSelectionTokens.cardRadius,
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.school_rounded, color: Theme.of(context).colorScheme.primary, size: 20)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.title, style: CourseSelectionTokens.cardTitle(context), maxLines: 1, overflow: TextOverflow.ellipsis), if (p.authority != null) Text(p.authority!, style: CourseSelectionTokens.cardSubtitle(context))])),
                  Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7), size: CourseSelectionTokens.chevronSize),
                ]),
              ),
            )),
      ],
    );
  }
}

class _OnboardingProgramDetail extends StatelessWidget {
  const _OnboardingProgramDetail({super.key, required this.program, required this.selectedLevel, required this.selectedSubLevel, required this.selectedYear, required this.selectedOptionalIds, required this.onSelectLevel, required this.onSelectSubLevel, required this.onSelectYear, required this.onToggleOptional, required this.onBack});
  final CatalogProgram program;
  final CatalogLevel? selectedLevel;
  final CatalogLevel? selectedSubLevel;
  final String selectedYear;
  final Set<String> selectedOptionalIds;
  final ValueChanged<CatalogLevel> onSelectLevel;
  final ValueChanged<CatalogLevel> onSelectSubLevel;
  final ValueChanged<String> onSelectYear;
  final ValueChanged<String> onToggleOptional;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeLevel = selectedLevel ?? (program.levels.isNotEmpty ? program.levels.first : null);
    final resolved = CourseCatalogService.instance.resolvePapersForProgram(programId: program.id, levelId: activeLevel?.id, subLevelId: selectedSubLevel?.id);
    final compulsory = resolved['compulsory'] ?? [];
    final optional = resolved['optional'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OnboardingBackHeader(title: program.title, subtitle: program.authority != null ? '${program.authority} · $selectedYear' : 'Syllabus $selectedYear', onBack: onBack),
        const SizedBox(height: 16),
        if (program.availableYears.length > 1) ...[
          Text('Syllabus Year', style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: program.availableYears.map((y) => _OnboardingLevelChip(label: y, selected: y == selectedYear, onTap: () => onSelectYear(y))).toList()),
          const SizedBox(height: 16),
        ],
        if (program.levels.length > 1) ...[
          Text('Select Level / Stream', style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: program.levels.map((lvl) => _OnboardingLevelChip(label: lvl.displayTitle, selected: lvl.id == activeLevel?.id, onTap: () => onSelectLevel(lvl))).toList()),
          const SizedBox(height: 16),
        ],
        if (activeLevel != null && activeLevel.children.isNotEmpty) ...[
          Text('Select Section / Group', style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: activeLevel.children.map((sub) => _OnboardingLevelChip(label: sub.displayTitle, selected: sub.id == selectedSubLevel?.id, onTap: () => onSelectSubLevel(sub))).toList()),
          const SizedBox(height: 16),
        ],
        if (compulsory.isNotEmpty) ...[
          Row(children: [Text('Core Papers', style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: scheme.primary, letterSpacing: 0.6)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)), child: Text('${compulsory.length}', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 8),
          ...compulsory.map((p) => Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: scheme.outline.withValues(alpha: 0.7))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 22, height: 22, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(Icons.check_rounded, color: scheme.primary, size: 14)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.title, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600)), if (p.description != null && p.description!.isNotEmpty) Text(p.description!, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant, fontSize: 11.5))]))]))),
          const SizedBox(height: 12),
        ],
        if (optional.isNotEmpty) ...[
          Text('Optional / Elective', style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          ...optional.map((p) {
            final isChecked = selectedOptionalIds.contains(p.id);
            return InkWell(
              onTap: () => onToggleOptional(p.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isChecked ? scheme.primary.withValues(alpha: 0.08) : scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: isChecked ? scheme.primary : scheme.outline.withValues(alpha: 0.7), width: isChecked ? 1.5 : 1)), child: Row(children: [SizedBox(width: 20, height: 20, child: Checkbox(value: isChecked, onChanged: (_) => onToggleOptional(p.id), activeColor: scheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)), const SizedBox(width: 10), Expanded(child: Text(p.title, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500, color: isChecked ? scheme.primary : scheme.onSurface)))])),
            );
          }),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: scheme.primary.withValues(alpha: 0.15))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(6)), child: Text('YOUR GOAL', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 10))),
            const SizedBox(height: 10),
            Text(program.title, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Wrap(spacing: 8, runSpacing: 4, children: [ _Pill(label: selectedSubLevel?.title ?? selectedLevel?.title ?? program.title), _Pill(label: selectedYear), if (program.authority != null) _Pill(label: program.authority!)]),
            const SizedBox(height: 8),
            Row(children: [Icon(Icons.menu_book_outlined, size: 14, color: scheme.onSurfaceVariant), const SizedBox(width: 6), Text('${compulsory.length + selectedOptionalIds.length} subjects · ${compulsory.length} core${selectedOptionalIds.isNotEmpty ? ' + ${selectedOptionalIds.length} elective' : ''}', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant))]),
          ]),
        ),
      ],
    );
  }
}

class _OnboardingLevelChip extends StatelessWidget {
  const _OnboardingLevelChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.8), width: selected ? 1.5 : 1)),
        elevation: selected ? 2 : 0,
        shadowColor: scheme.primary.withValues(alpha: 0.30),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, child: Text(label, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: selected ? scheme.onPrimary : (isDark ? scheme.onSurface : scheme.onSurfaceVariant), fontWeight: selected ? FontWeight.w700 : FontWeight.w600, fontSize: 12.5))),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(999), border: Border.all(color: scheme.outline.withValues(alpha: 0.6))), child: Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, fontSize: 11)));
  }
}

class _OnboardingBackHeader extends StatelessWidget {
  const _OnboardingBackHeader({required this.title, required this.subtitle, required this.onBack});
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Material(color: scheme.surfaceContainerHighest.withValues(alpha: 0.6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: scheme.outline.withValues(alpha: 0.7))), child: InkWell(onTap: onBack, borderRadius: BorderRadius.circular(10), child: const SizedBox(width: 40, height: 40, child: Center(child: Icon(Icons.arrow_back_rounded, size: 18))))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis), Text(subtitle, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis)])),
    ]);
  }
}

// ── STEP 2: GOALS & FINAL CONFIRMATION (YOUR GOAL) ─────────────────

class _GoalsAndConfirmationStep extends StatelessWidget {
  const _GoalsAndConfirmationStep({required this.program, required this.level, required this.subLevel, required this.year, required this.selectedOptionalIds, required this.selectedGoals, required this.academicFocus, required this.onToggleGoal, required this.onSelectFocus});
  final CatalogProgram? program;
  final CatalogLevel? level;
  final CatalogLevel? subLevel;
  final String year;
  final Set<String> selectedOptionalIds;
  final Set<StudentGoal> selectedGoals;
  final AcademicFocus? academicFocus;
  final ValueChanged<StudentGoal> onToggleGoal;
  final ValueChanged<AcademicFocus> onSelectFocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    int totalSubjects = 0;
    int coreCount = 0;
    if (program != null) {
      final active = level ?? program!.levels.firstOrNull;
      final resolved = CourseCatalogService.instance.resolvePapersForProgram(programId: program!.id, levelId: active?.id, subLevelId: subLevel?.id);
      coreCount = (resolved['compulsory'] ?? []).length;
      totalSubjects = coreCount + selectedOptionalIds.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text('Academic Summary', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('Review your setup before launching your workspace.', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (program != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outline.withValues(alpha: 0.7))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(6)), child: Text('YOUR GOAL', style: theme.textTheme.labelSmall!.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.8))),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Program', value: program!.title),
                  if (program!.authority != null) _SummaryRow(label: 'Board / Authority', value: program!.authority!),
                  if (level != null) _SummaryRow(label: 'Level / Class', value: subLevel?.title ?? level!.title),
                  _SummaryRow(label: 'Syllabus', value: year),
                  _SummaryRow(label: 'Subjects to Create', value: '$totalSubjects ($coreCount core, ${selectedOptionalIds.length} elective)'),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outline)),
                child: Row(children: [Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20), const SizedBox(width: 12), Expanded(child: Text('No course selected yet. Go back to choose your goal.', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)))]),
              ),
            const SizedBox(height: 20),
            Text('PRIMARY FOCUS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: AcademicFocus.values.map((focus) {
              final isSelected = academicFocus == focus;
              return ChoiceChip(label: Text(focus.label), selected: isSelected, onSelected: (sel) { if (sel) onSelectFocus(focus); }, selectedColor: scheme.primary, backgroundColor: scheme.surfaceContainerLow, labelStyle: theme.textTheme.labelLarge?.copyWith(color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500), side: BorderSide(color: isSelected ? scheme.primary : scheme.outline), showCheckmark: false);
            }).toList()),
            const SizedBox(height: 20),
            Text('ACADEMIC GOALS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: StudentGoal.values.map((goal) {
              final isSelected = selectedGoals.contains(goal);
              return FilterChip(label: Text(goal.label), selected: isSelected, onSelected: (sel) => onToggleGoal(goal), selectedColor: scheme.primary, backgroundColor: scheme.surfaceContainerLow, labelStyle: theme.textTheme.labelLarge?.copyWith(color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500), side: BorderSide(color: isSelected ? scheme.primary : scheme.outline), showCheckmark: false);
            }).toList()),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
