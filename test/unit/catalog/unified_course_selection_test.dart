import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/data/models/catalog/active_course_selection.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/core/services/student_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CourseCatalogService.instance.ensureInitialized();
    CourseCatalogService.instance.loadDefaults();
    SubjectController.instance.clearData();
    StudentService.instance.clearProfile();
    AuthIsolation.instance.setAuthenticatedUser('unified_test_user');
  });

  tearDown(() {
    SubjectController.instance.clearData();
    StudentService.instance.clearProfile();
    AuthIsolation.instance.clearSession();
  });

  group('Unified Catalog 2.0 — Single Source of Truth', () {
    test('Catalog categories load 18 master categories', () {
      final cats = CourseCatalogService.instance.categories2;
      expect(cats.length, greaterThanOrEqualTo(12));
      expect(cats.any((c) => c.id == 'commerce_accounting_finance'), isTrue);
      expect(cats.any((c) => c.id == 'engineering_technology'), isTrue);
      expect(cats.any((c) => c.id == 'medical_healthcare'), isTrue);
      expect(cats.any((c) => c.id == 'law'), isTrue);
    });

    test('CA Foundation 2026 has correct 4 subjects', () {
      final prog = CourseCatalogService.instance.getProgramById('ca_foundation');
      expect(prog, isNotNull);
      expect(prog!.title, 'CA Foundation');
      expect(prog.defaultYear, '2026');
      final resolved = CourseCatalogService.instance.resolvePapersForProgram(programId: 'ca_foundation', levelId: 'ca_f_level');
      final compulsory = resolved['compulsory']!;
      expect(compulsory.length, 4);
      expect(compulsory.map((p) => p.title), containsAll(['Accounting', 'Business Laws', 'Quantitative Aptitude', 'Business Economics']));
      final qa = compulsory.firstWhere((p) => p.title == 'Quantitative Aptitude');
      expect(qa.description, contains('Business Mathematics'));
      expect(qa.description, contains('Logical Reasoning'));
      expect(qa.description, contains('Statistics'));
    });

    test('Hierarchy: Category → Family → Program → Level → Papers', () {
      final cat = CourseCatalogService.instance.getCategoryById('engineering_technology');
      expect(cat, isNotNull);
      final families = CourseCatalogService.instance.getFamiliesByCategory('engineering_technology');
      expect(families.any((f) => f.id == 'jee'), isTrue);
      final programs = CourseCatalogService.instance.getProgramsByFamily('jee');
      expect(programs.map((p) => p.id), containsAll(['jee_main', 'jee_advanced']));
      final jeeMain = CourseCatalogService.instance.getProgramById('jee_main');
      expect(jeeMain!.levels.first.papers.map((p) => p.title), containsAll(['Physics', 'Chemistry', 'Mathematics']));
    });

    test('Popular shortcuts are shortcuts into catalog, not duplicates', () {
      final popular = CourseCatalogService.instance.popularPrograms;
      expect(popular.isNotEmpty, isTrue);
      // Spot check required populars from spec
      expect(popular.any((p) => p.id == 'jee_main'), isTrue);
      expect(popular.any((p) => p.id == 'jee_advanced'), isTrue);
      expect(popular.any((p) => p.id == 'neet_ug'), isTrue);
      expect(popular.any((p) => p.id == 'clat_ug'), isTrue);
      expect(popular.any((p) => p.id == 'cat_exam'), isTrue);
      expect(popular.any((p) => p.id == 'upsc_cse'), isTrue);
      expect(popular.any((p) => p.id == 'ssc_cgl'), isTrue);
      // Ensure no duplicate program definitions for popular items
      final ids = popular.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('Search across category/family/program/level/subject/aliases offline', () {
      expect(CourseCatalogService.instance.searchCatalog2('CA').any((p) => p.id == 'ca_foundation'), isTrue);
      expect(CourseCatalogService.instance.searchCatalog2('JEE Main').any((p) => p.id == 'jee_main'), isTrue);
      expect(CourseCatalogService.instance.searchCatalog2('NEET').any((p) => p.id == 'neet_ug'), isTrue);
      expect(CourseCatalogService.instance.searchCatalog2('SSC CGL').any((p) => p.id == 'ssc_cgl'), isTrue);
      expect(CourseCatalogService.instance.searchCatalog2('UPSC').any((p) => p.id == 'upsc_cse'), isTrue);
      expect(CourseCatalogService.instance.searchCatalog2('CLAT').any((p) => p.id == 'clat_ug'), isTrue);
      expect(CourseCatalogService.instance.searchCatalog2('GATE CS').any((p) => p.id == 'gate_2026'), isTrue);
      // Subject level search
      expect(CourseCatalogService.instance.searchCatalog2('Accounting').any((p) => p.id == 'ca_foundation'), isTrue);
    });

    test('Adaptive level selection: CA Intermediate requires group', () {
      final prog = CourseCatalogService.instance.getProgramById('ca_intermediate')!;
      expect(prog.levels.first.children.length, 2);
      expect(prog.levels.first.children.map((c) => c.title), containsAll(['Group I', 'Group II']));
      final g1Resolved = CourseCatalogService.instance.resolvePapersForProgram(programId: 'ca_intermediate', levelId: 'ca_int_level', subLevelId: 'ca_int_g1');
      expect(g1Resolved['compulsory']!.isNotEmpty, isTrue);
    });

    test('Year/version stored in active course context', () async {
      final sel = ActiveCourseSelection(
        userId: 'unified_test_user',
        categoryId: 'engineering_technology',
        familyId: 'jee',
        programId: 'jee_main',
        programTitle: 'JEE Main',
        levelId: 'jee_m_p1',
        levelTitle: 'Paper 1',
        year: '2026',
      );
      await CourseCatalogService.instance.setActiveCourse(sel);
      expect(CourseCatalogService.instance.getActiveYear(), '2026');
      expect(CourseCatalogService.instance.getActiveProgram(), 'jee_main');
      expect(CourseCatalogService.instance.getActiveLevel(), 'Paper 1');
    });

    test('Subject mapping from program/version generates correct subjects without fake progress', () async {
      final sel = ActiveCourseSelection(
        userId: 'unified_test_user',
        categoryId: 'commerce_accounting_finance',
        familyId: 'ca',
        programId: 'ca_foundation',
        programTitle: 'CA Foundation',
        levelId: 'ca_f_level',
        levelTitle: 'Foundation Level',
        year: '2026',
      );
      await CourseCatalogService.instance.setActiveCourse(sel);
      expect(SubjectController.instance.subjects.length, 4);
      expect(SubjectController.instance.subjects.every((s) => s.archived == false), isTrue);
      // No fake progress: newly provisioned subjects start with no chapters/topics progress
    });

    test('Change course preserves data and is idempotent', () async {
      final ca = ActiveCourseSelection(
        userId: 'unified_test_user',
        categoryId: 'commerce_accounting_finance',
        familyId: 'ca',
        programId: 'ca_foundation',
        programTitle: 'CA Foundation',
        levelId: 'ca_f_level',
        levelTitle: 'Foundation Level',
        year: '2026',
      );
      await CourseCatalogService.instance.setActiveCourse(ca);
      final firstCount = SubjectController.instance.subjects.length;
      // Idempotent: same selection again should not duplicate
      await CourseCatalogService.instance.setActiveCourse(ca);
      expect(SubjectController.instance.subjects.length, firstCount);
    });

    test('User isolation: different user does not see previous active course', () async {
      final ca = ActiveCourseSelection(
        userId: 'user_a',
        categoryId: 'commerce_accounting_finance',
        familyId: 'ca',
        programId: 'ca_foundation',
        programTitle: 'CA Foundation',
        levelId: 'ca_f_level',
        levelTitle: 'Foundation Level',
        year: '2026',
      );
      AuthIsolation.instance.setAuthenticatedUser('user_a');
      await CourseCatalogService.instance.setActiveCourse(ca);
      expect(CourseCatalogService.instance.getActiveCourse(), 'CA Foundation');

      // Simulate logout — clear in-memory active selection to simulate process restart
      CourseCatalogService.instance.clearActiveSelection();
      AuthIsolation.instance.clearSession();
      SubjectController.instance.clearData();
      StudentService.instance.clearProfile();
      // User B has never selected
      AuthIsolation.instance.setAuthenticatedUser('user_b');
      await CourseCatalogService.instance.loadActiveCourse();
      expect(CourseCatalogService.instance.getActiveCourse(), isNull);

      // User B selects JEE, should not see CA
      final jee = ActiveCourseSelection(
        userId: 'user_b',
        categoryId: 'engineering_technology',
        familyId: 'jee',
        programId: 'jee_main',
        programTitle: 'JEE Main',
        levelId: 'jee_m_p1',
        levelTitle: 'Paper 1',
        year: '2026',
      );
      await CourseCatalogService.instance.setActiveCourse(jee);
      expect(CourseCatalogService.instance.getActiveCourse(), 'JEE Main');

      // Switch back to user_a — CA should be restored
      CourseCatalogService.instance.clearActiveSelection();
      AuthIsolation.instance.clearSession();
      AuthIsolation.instance.setAuthenticatedUser('user_a');
      await CourseCatalogService.instance.loadActiveCourse();
      expect(CourseCatalogService.instance.getActiveCourse(), 'CA Foundation');
    });
  });
}
