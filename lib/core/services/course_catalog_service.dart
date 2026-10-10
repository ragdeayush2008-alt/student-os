import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../data/catalog/higher_education_catalog_data.dart';
import '../../data/catalog/master_catalog_registry.dart';
import '../../data/catalog/professional_catalog_data.dart';
import '../../data/catalog/school_catalog_data.dart';
import '../../data/models/catalog/active_course_selection.dart';
import '../../data/models/catalog/catalog_category.dart';
import '../../data/models/catalog/catalog_course.dart';
import '../../data/models/catalog/catalog_curriculum.dart';
import '../../data/models/catalog/catalog_family.dart';
import '../../data/models/catalog/catalog_node.dart';
import '../../data/models/catalog/catalog_paper.dart';
import '../../data/models/catalog/catalog_program.dart';
import '../../data/models/catalog/catalog_subject.dart';
import '../../data/models/catalog/course_category.dart';
import '../../data/models/subject.dart';
import '../../features/auth/auth_service.dart';
import '../../features/subjects/subject_controller.dart';
import 'storage_service.dart';
import 'student_service.dart';

/// Central catalog registry, query service, and active academic track manager
/// for Student OS Catalog 2.0.
///
/// Supports:
/// - 18 Master Categories spanning School, Competitive Exams, Higher Ed, and Professional.
/// - Hierarchical traversal: Category -> Family -> Program -> Level -> Paper.
/// - Fast local offline search.
/// - Authoritative active course resolution ([getActiveCourse], [getActiveProgram], [getActiveLevel], [getActiveYear]).
/// - Non-destructive course switching and idempotent subject provisioning.
class CourseCatalogService extends ChangeNotifier {
  CourseCatalogService._() {
    ensureInitialized();
  }

  static final CourseCatalogService instance = CourseCatalogService._();

  static const _activeCourseKey = 'active_course_selection';

  final Map<String, CatalogCourse> _courses = {};
  ActiveCourseSelection? _activeSelection;
  bool _initialized = false;

  /// Ensures standard catalog data is populated if not yet loaded.
  void ensureInitialized() {
    if (_initialized) return;
    loadDefaults();
    _initialized = true;
  }

  /// Loads standard pre-populated school, senior secondary, undergraduate, postgraduate,
  /// and professional catalog courses, and indexes Catalog 2.0 offerings.
  void loadDefaults() {
    for (final c in SchoolCatalogData.getAllSchoolCourses()) {
      _courses[c.id] = c;
    }
    for (final c in HigherEducationCatalogData.getAllHigherEducationCourses()) {
      _courses[c.id] = c;
    }
    for (final c in ProfessionalCatalogData.getAllProfessionalCourses()) {
      _courses[c.id] = c;
    }

    // Bridge all Catalog 2.0 programs to CatalogCourse for backward compatibility
    for (final program in MasterCatalogRegistry.instance.allPrograms) {
      if (!_courses.containsKey(program.id)) {
        _courses[program.id] = program.toCatalogCourse();
      }
    }

    _initialized = true;
    notifyListeners();
  }

  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Catalog 2.0 Accessors ──────────────────────────────────────────

  List<CatalogCategory2> get categories2 =>
      MasterCatalogRegistry.instance.allCategories;

  CatalogCategory2? getCategoryById(String id) =>
      MasterCatalogRegistry.instance.getCategoryById(id);

  List<CatalogFamily> get families => MasterCatalogRegistry.instance.allFamilies;

  List<CatalogFamily> getFamiliesByCategory(String categoryId) =>
      MasterCatalogRegistry.instance.getFamiliesByCategory(categoryId);

  CatalogFamily? getFamilyById(String id) =>
      MasterCatalogRegistry.instance.getFamilyById(id);

  List<CatalogProgram> get programs =>
      MasterCatalogRegistry.instance.allPrograms;

  List<CatalogProgram> getProgramsByCategory(String categoryId) =>
      MasterCatalogRegistry.instance.getProgramsByCategory(categoryId);

  List<CatalogProgram> getProgramsByFamily(String familyId) =>
      MasterCatalogRegistry.instance.getProgramsByFamily(familyId);

  CatalogProgram? getProgramById(String id) =>
      MasterCatalogRegistry.instance.getProgramById(id);

  List<CatalogProgram> get popularPrograms =>
      MasterCatalogRegistry.instance.popularPrograms;

  /// Fast local search across Catalog 2.0.
  List<CatalogProgram> searchCatalog2(
    String query, {
    String? categoryId,
    String? familyId,
  }) =>
      MasterCatalogRegistry.instance.search(
        query,
        categoryId: categoryId,
        familyId: familyId,
      );

  Map<String, List<CatalogPaper>> resolvePapersForProgram({
    required String programId,
    String? levelId,
    String? subLevelId,
  }) =>
      MasterCatalogRegistry.instance.resolvePapers(
        programId: programId,
        levelId: levelId,
        subLevelId: subLevelId,
      );

  // ─── Active Course Track / Selection ─────────────────────────────────

  ActiveCourseSelection? get activeCourseSelection {
    if (_activeSelection != null) return _activeSelection;
    // Fallback adapter for profile if not directly loaded into ActiveCourseSelection
    final profile = StudentService.instance.profile;
    if (profile.hasCatalogCourse && profile.catalogCourseId != null) {
      final courseId = profile.catalogCourseId!;
      final program = getProgramById(courseId);
      return ActiveCourseSelection(
        userId: _userId ?? '',
        categoryId: profile.catalogCategory?.name ?? program?.categoryId ?? '',
        familyId: program?.familyId ?? '',
        programId: courseId,
        programTitle: profile.course.isNotEmpty
            ? profile.course
            : (program?.title ?? courseId),
        levelId: profile.catalogLevelId ?? '',
        levelTitle: profile.currentYear,
        subLevelId: profile.catalogNodeId,
        year: program?.defaultYear ?? '2026',
        selectedPaperIds: profile.selectedOptionalSubjectIds,
        authority: profile.catalogAuthority ?? program?.authority,
        institution: profile.institution,
      );
    }
    return null;
  }

  bool get hasActiveCourse {
    return _activeSelection != null ||
        (StudentService.instance.profile.hasCatalogCourse &&
            StudentService.instance.profile.course.isNotEmpty);
  }

  /// Authoritative single resolver for active course / exam name.
  String? getActiveCourse() {
    final sel = activeCourseSelection;
    if (sel != null && sel.programTitle.isNotEmpty) {
      return sel.programTitle;
    }
    final profile = StudentService.instance.profile;
    if (profile.course.isNotEmpty) return profile.course;
    return null;
  }

  /// Authoritative single resolver for active program ID or title.
  String? getActiveProgram() {
    final sel = activeCourseSelection;
    if (sel != null && sel.programId.isNotEmpty) {
      return sel.programId;
    }
    final profile = StudentService.instance.profile;
    if (profile.catalogCourseId != null && profile.catalogCourseId!.isNotEmpty) {
      return profile.catalogCourseId;
    }
    return null;
  }

  /// Authoritative single resolver for active level title.
  String? getActiveLevel() {
    final sel = activeCourseSelection;
    if (sel != null && sel.levelTitle.isNotEmpty) {
      return sel.levelTitle;
    }
    final profile = StudentService.instance.profile;
    if (profile.currentYear.isNotEmpty) return profile.currentYear;
    return null;
  }

  /// Authoritative single resolver for active year / syllabus version.
  String? getActiveYear() {
    final sel = activeCourseSelection;
    if (sel != null && sel.year.isNotEmpty) {
      return sel.year;
    }
    return '2026';
  }

  /// Loads the persisted active course selection for the authenticated user.
  Future<void> loadActiveCourse() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final json = await StorageService.instance.loadJson(
        userId: uid,
        key: _activeCourseKey,
      );
      if (json != null) {
        _activeSelection = ActiveCourseSelection.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseCatalogService] Load active course error: $e');
    }
  }

  /// Sets the active course selection and provisions student subjects.
  /// Non-destructive: preserves existing tasks, sessions, focus records, exams, and custom subjects.
  Future<void> setActiveCourse(
    ActiveCourseSelection selection, {
    bool provisionSubjects = true,
    List<String>? selectedOptionalPaperIds,
  }) async {
    _activeSelection = selection;

    final uid = _userId;
    if (uid != null) {
      await StorageService.instance.saveJson(
        userId: uid,
        key: _activeCourseKey,
        json: selection.toJson(),
      );
    }

    // Synchronize into StudentProfile
    final category = CourseCategory.fromString(selection.categoryId);
    await StudentService.instance.updateCatalogEducation(
      category: category,
      courseId: selection.programId,
      courseName: selection.programTitle,
      authority: selection.authority,
      levelId: selection.levelId,
      nodeId: selection.subLevelId ?? selection.levelId,
      currentYear: selection.levelTitle,
      institution: selection.institution,
      selectedOptionalSubjectIds: selectedOptionalPaperIds ?? selection.selectedPaperIds,
    );

    if (provisionSubjects) {
      // 1. Check if Program exists in Catalog 2.0
      final program = getProgramById(selection.programId);
      if (program != null) {
        await _provisionFromCatalog2(
          program: program,
          levelId: selection.levelId,
          subLevelId: selection.subLevelId,
          selectedOptionalIds: selectedOptionalPaperIds ?? selection.selectedPaperIds,
          year: selection.year,
        );
      } else {
        // Fallback to legacy provisioning
        await provisionStudentSubjects(
          courseId: selection.programId,
          selectedNodeIds: [
            if (selection.subLevelId != null && selection.subLevelId!.isNotEmpty)
              selection.subLevelId!
            else if (selection.levelId.isNotEmpty)
              selection.levelId,
          ],
          selectedOptionalSubjectIds: selectedOptionalPaperIds ?? selection.selectedPaperIds,
          versionCode: selection.year,
        );
      }
    }

    notifyListeners();
  }

  /// Provisions student subjects from a Catalog 2.0 [CatalogProgram].
  Future<List<Subject>> _provisionFromCatalog2({
    required CatalogProgram program,
    required String levelId,
    String? subLevelId,
    List<String> selectedOptionalIds = const [],
    required String year,
  }) async {
    final resolved = resolvePapersForProgram(
      programId: program.id,
      levelId: levelId,
      subLevelId: subLevelId,
    );

    final subjectsToInstantiate = <Subject>[];

    // 1. Compulsory / group-specific papers
    for (final paper in resolved['compulsory'] ?? <CatalogPaper>[]) {
      subjectsToInstantiate.add(
        createStudentSubjectFromPaper(
          paper: paper,
          courseId: program.id,
          catalogVersion: year,
        ),
      );
    }

    // 2. Selected optional / elective papers
    for (final paper in resolved['optional'] ?? <CatalogPaper>[]) {
      if (selectedOptionalIds.contains(paper.id)) {
        subjectsToInstantiate.add(
          createStudentSubjectFromPaper(
            paper: paper,
            courseId: program.id,
            catalogVersion: year,
          ),
        );
      }
    }

    return await SubjectController.instance.addCatalogSubjects(subjectsToInstantiate);
  }

  /// Bridges a [CatalogPaper] to a student-owned [Subject].
  Subject createStudentSubjectFromPaper({
    required CatalogPaper paper,
    required String courseId,
    required String catalogVersion,
    String? customId,
  }) {
    return Subject(
      id: customId ??
          'subj_${courseId}_${paper.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: paper.title,
      shortName: paper.shortTitle ?? '',
      description: paper.description ?? '',
      color: paper.color,
      iconCodePoint: paper.iconCodePoint,
      catalogSubjectId: paper.id,
      catalogCourseId: courseId,
      catalogVersion: catalogVersion,
      code: paper.code,
      credits: paper.credits,
    );
  }

  /// Switches the active course safely without deleting any user data.
  Future<void> switchCourse({
    required ActiveCourseSelection newSelection,
    List<String>? selectedOptionalPaperIds,
  }) async {
    await setActiveCourse(
      newSelection,
      provisionSubjects: true,
      selectedOptionalPaperIds: selectedOptionalPaperIds,
    );
  }

  // ─── Legacy Catalog 1.0 Compatibility APIs ───────────────────────────

  /// All registered courses in the catalog.
  List<CatalogCourse> get allCourses {
    ensureInitialized();
    return List.unmodifiable(_courses.values.where((c) => c.active));
  }

  /// Returns courses matching a specific [CourseCategory].
  List<CatalogCourse> getCoursesByCategory(CourseCategory category) {
    ensureInitialized();
    return _courses.values
        .where((c) => c.active && c.category == category)
        .toList();
  }

  /// Finds a course by ID.
  CatalogCourse? getCourseById(String courseId) {
    ensureInitialized();
    return _courses[courseId];
  }

  /// Retrieves a specific curriculum version for a course.
  CatalogCurriculum? getCurriculum(String courseId, {String? versionCode}) {
    final course = getCourseById(courseId);
    if (course == null) return null;
    if (versionCode != null) {
      return course.getCurriculumByVersion(versionCode);
    }
    return course.activeCurriculum;
  }

  /// Finds a specific structural node within a course curriculum.
  CatalogNode? getNode(
    String courseId,
    String nodeId, {
    String? versionCode,
  }) {
    final curriculum = getCurriculum(courseId, versionCode: versionCode);
    return curriculum?.findNodeById(nodeId);
  }

  /// Finds a specific subject within a course curriculum.
  CatalogSubject? getSubject(
    String courseId,
    String subjectId, {
    String? versionCode,
  }) {
    final curriculum = getCurriculum(courseId, versionCode: versionCode);
    return curriculum?.findSubjectById(subjectId);
  }

  /// Searches courses by name, description, or authority.
  List<CatalogCourse> searchCourses(
    String query, {
    CourseCategory? category,
  }) {
    ensureInitialized();
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return category != null ? getCoursesByCategory(category) : allCourses;
    }

    return _courses.values.where((c) {
      if (!c.active) return false;
      if (category != null && c.category != category) return false;

      final matchName = c.name.toLowerCase().contains(cleanQuery);
      final matchAuthority =
          c.authority?.toLowerCase().contains(cleanQuery) ?? false;
      final matchDesc =
          c.description?.toLowerCase().contains(cleanQuery) ?? false;

      return matchName || matchAuthority || matchDesc;
    }).toList();
  }

  /// Registers or updates a course in the catalog registry.
  void registerCourse(CatalogCourse course) {
    _courses[course.id] = course;
    notifyListeners();
  }

  /// Registers multiple courses in batch.
  void registerCourses(Iterable<CatalogCourse> courses) {
    for (final c in courses) {
      _courses[c.id] = c;
    }
    notifyListeners();
  }

  /// Clears the in-memory registry (useful for testing).
  void clearCatalog() {
    _courses.clear();
    _activeSelection = null;
    _initialized = true;
    notifyListeners();
  }

  /// Clears only the active selection (useful for user isolation testing).
  void clearActiveSelection() {
    _activeSelection = null;
    notifyListeners();
  }

  /// Instantiates a student-owned [Subject] from a [CatalogSubject] blueprint.
  Subject createStudentSubject({
    required CatalogSubject catalogSubject,
    required String courseId,
    required String catalogVersion,
    String? customId,
    int? color,
    int? iconCodePoint,
  }) {
    return Subject(
      id: customId ??
          'subj_${courseId}_${catalogSubject.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: catalogSubject.name,
      shortName: catalogSubject.shortName ?? '',
      description: catalogSubject.description ?? '',
      color: color ?? catalogSubject.color,
      iconCodePoint: iconCodePoint ?? catalogSubject.iconCodePoint,
      catalogSubjectId: catalogSubject.id,
      catalogCourseId: courseId,
      catalogVersion: catalogVersion,
      code: catalogSubject.code,
      credits: catalogSubject.credits,
    );
  }

  /// Resolves the candidate subjects for a course and node selection.
  Map<String, List<CatalogSubject>> resolveSubjectsForSelection({
    required String courseId,
    required List<String> selectedNodeIds,
    String? versionCode,
  }) {
    ensureInitialized();
    final curriculum = getCurriculum(courseId, versionCode: versionCode);
    if (curriculum == null) {
      return {'compulsory': [], 'optional': []};
    }

    final candidateSubjects = <CatalogSubject>[];
    final seenSubjectIds = <String>{};

    void addSubject(CatalogSubject s) {
      if (seenSubjectIds.add(s.id)) {
        candidateSubjects.add(s);
      }
    }

    if (selectedNodeIds.isEmpty) {
      for (final rootNode in curriculum.structure) {
        for (final s in rootNode.allSubjects) {
          addSubject(s);
        }
      }
    } else {
      for (final nodeId in selectedNodeIds) {
        final node = curriculum.findNodeById(nodeId);
        if (node != null) {
          for (final s in node.subjects) {
            addSubject(s);
          }
          for (final child in node.children) {
            for (final s in child.allSubjects) {
              addSubject(s);
            }
          }
        }
      }
    }

    final compulsory = <CatalogSubject>[];
    final optional = <CatalogSubject>[];

    for (final s in candidateSubjects) {
      if (s.isCompulsory ||
          s.type == SubjectRequirementType.groupSpecific ||
          s.type == SubjectRequirementType.specializationSpecific) {
        compulsory.add(s);
      } else {
        optional.add(s);
      }
    }

    return {
      'compulsory': List.unmodifiable(compulsory),
      'optional': List.unmodifiable(optional),
    };
  }

  /// Automatically provisions student subjects from catalog choices.
  Future<List<Subject>> provisionStudentSubjects({
    required String courseId,
    required List<String> selectedNodeIds,
    List<String> selectedOptionalSubjectIds = const [],
    String? versionCode,
  }) async {
    ensureInitialized();
    final resolved = resolveSubjectsForSelection(
      courseId: courseId,
      selectedNodeIds: selectedNodeIds,
      versionCode: versionCode,
    );

    final course = getCourseById(courseId);
    final curriculum = getCurriculum(courseId, versionCode: versionCode);
    final version = versionCode ?? course?.catalogVersion ?? curriculum?.versionCode ?? 'DEFAULT';

    final subjectsToInstantiate = <Subject>[];

    for (final catSubj in resolved['compulsory'] ?? <CatalogSubject>[]) {
      subjectsToInstantiate.add(
        createStudentSubject(
          catalogSubject: catSubj,
          courseId: courseId,
          catalogVersion: version,
        ),
      );
    }

    for (final catSubj in resolved['optional'] ?? <CatalogSubject>[]) {
      if (selectedOptionalSubjectIds.contains(catSubj.id)) {
        subjectsToInstantiate.add(
          createStudentSubject(
            catalogSubject: catSubj,
            courseId: courseId,
            catalogVersion: version,
          ),
        );
      }
    }

    return await SubjectController.instance.addCatalogSubjects(subjectsToInstantiate);
  }
}
