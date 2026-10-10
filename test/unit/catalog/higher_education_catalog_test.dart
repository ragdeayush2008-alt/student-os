import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/data/models/catalog/catalog_node.dart';
import 'package:student_os/data/models/catalog/course_category.dart';

void main() {
  group('Higher Education Catalog — Phase 3', () {
    late CourseCatalogService catalog;

    setUp(() {
      catalog = CourseCatalogService.instance;
      catalog.clearCatalog();
      catalog.loadDefaults();
    });

    test('B.Com has Year → Semester structure with representative subjects', () {
      final bcom = catalog.getCourseById('bcom');
      expect(bcom, isNotNull);
      expect(bcom!.category, CourseCategory.undergraduate);
      expect(bcom.authority, 'Generic');

      final curr = bcom.activeCurriculum!;
      expect(curr.structure.length, 3);

      final year1 = curr.findNodeById('node_bcom_year_1');
      expect(year1, isNotNull);
      expect(year1!.type, CatalogNodeType.year);
      expect(year1.children.length, 2);

      final sem1 = curr.findNodeById('bcom_y1_sem1');
      expect(sem1, isNotNull);
      expect(sem1!.type, CatalogNodeType.semester);
      expect(sem1.subjects.any((s) => s.name == 'Financial Accounting' && s.isCompulsory), isTrue);
      expect(sem1.subjects.any((s) => s.name == 'Business Communication'), isTrue);
    });

    test('BCA has Semester structure (6 semesters) with programming fundamentals', () {
      final bca = catalog.getCourseById('bca');
      expect(bca, isNotNull);
      expect(bca!.category, CourseCategory.undergraduate);

      final curr = bca.activeCurriculum!;
      expect(curr.structure.length, 6);

      final sem1 = curr.findNodeById('node_bca_sem_1');
      expect(sem1, isNotNull);
      expect(sem1!.type, CatalogNodeType.semester);
      expect(sem1.subjects.any((s) => s.name == 'Programming Fundamentals'), isTrue);
      expect(sem1.subjects.any((s) => s.name == 'Mathematics'), isTrue);
    });

    test('B.Tech Computer Science has 8 semesters with engineering fundamentals', () {
      final btech = catalog.getCourseById('btech_cse');
      expect(btech, isNotNull);
      expect(btech!.category, CourseCategory.undergraduate);
      expect(btech.name, 'B.Tech Computer Science');

      final curr = btech.activeCurriculum!;
      expect(curr.structure.length, 8);

      final sem1 = curr.findNodeById('node_btech_cse_sem_1');
      expect(sem1, isNotNull);
      expect(sem1!.subjects.any((s) => s.name == 'Engineering Mathematics I'), isTrue);
      expect(sem1.subjects.any((s) => s.name == 'Engineering Physics'), isTrue);
      expect(sem1.subjects.any((s) => s.name == 'Engineering Chemistry'), isTrue);

      final sem3 = curr.findNodeById('node_btech_cse_sem_3');
      expect(sem3, isNotNull);
      expect(sem3!.subjects.any((s) => s.name == 'Branch Core Subject'), isTrue);
      expect(sem3.subjects.any((s) => s.type.name == 'elective'), isTrue);
    });

    test('B.Tech branches cover major engineering disciplines', () {
      final branches = [
        'btech_cse',
        'btech_it',
        'btech_aiml',
        'btech_ds',
        'btech_ece',
        'btech_ee',
        'btech_me',
        'btech_civil',
        'btech_chemical',
        'btech_biotech',
        'btech_aerospace',
        'btech_automobile',
        'btech_instrumentation',
        'btech_robotics',
        'btech_biomedical',
      ];

      for (final id in branches) {
        final course = catalog.getCourseById(id);
        expect(course, isNotNull, reason: '$id should exist');
        expect(course!.category, CourseCategory.undergraduate);
        expect(course.activeCurriculum!.structure.length, 8);
      }
    });

    test('BA specializations exist with generic year structure', () {
      final baSpecs = [
        'ba',
        'ba_english',
        'ba_economics',
        'ba_psychology',
        'ba_history',
        'ba_political_science',
        'ba_sociology',
        'ba_geography',
      ];

      for (final id in baSpecs) {
        final course = catalog.getCourseById(id);
        expect(course, isNotNull, reason: '$id should exist');
        expect(course!.category, CourseCategory.undergraduate);
      }

      final baEng = catalog.getCourseById('ba_english')!;
      final year1 = baEng.activeCurriculum!.findNodeById('node_ba_eng_year_1');
      expect(year1, isNotNull);
      expect(year1!.children.length, 2);
    });

    test('B.Sc specializations exist', () {
      final bscCourses = [
        'bsc',
        'bsc_mathematics',
        'bsc_physics',
        'bsc_chemistry',
        'bsc_computer_science',
      ];

      for (final id in bscCourses) {
        final course = catalog.getCourseById(id);
        expect(course, isNotNull, reason: '$id should exist');
        expect(course!.category, CourseCategory.undergraduate);
      }
    });

    test('Law courses support 3-year and 5-year integrated programs', () {
      final llb = catalog.getCourseById('llb');
      expect(llb, isNotNull);
      expect(llb!.activeCurriculum!.structure.length, 6);

      final baLlb = catalog.getCourseById('ba_llb');
      expect(baLlb, isNotNull);
      expect(baLlb!.activeCurriculum!.structure.length, 10);

      final bbaLlb = catalog.getCourseById('bba_llb');
      expect(bbaLlb, isNotNull);

      final bcomLlb = catalog.getCourseById('bcom_llb');
      expect(bcomLlb, isNotNull);
    });

    test('Healthcare courses exist with appropriate semester counts', () {
      final mbbs = catalog.getCourseById('mbbs');
      expect(mbbs, isNotNull);
      expect(mbbs!.category, CourseCategory.undergraduate);
      expect(mbbs.activeCurriculum!.structure.length, 9);

      final sem1 = mbbs.activeCurriculum!.findNodeById('node_mbbs_sem_1');
      expect(sem1!.subjects.any((s) => s.name == 'Anatomy'), isTrue);
      expect(sem1.subjects.any((s) => s.name == 'Physiology'), isTrue);

      final bds = catalog.getCourseById('bds');
      expect(bds, isNotNull);
      expect(bds!.activeCurriculum!.structure.length, 8);

      final bpharm = catalog.getCourseById('b_pharm');
      expect(bpharm, isNotNull);

      final bpt = catalog.getCourseById('bpt');
      expect(bpt, isNotNull);

      final nursing = catalog.getCourseById('bsc_nursing');
      expect(nursing, isNotNull);
    });

    test('Design and Architecture courses exist', () {
      final bdes = catalog.getCourseById('b_des');
      expect(bdes, isNotNull);
      expect(bdes!.category, CourseCategory.undergraduate);
      expect(bdes.activeCurriculum!.structure.length, 8);

      final barch = catalog.getCourseById('b_arch');
      expect(barch, isNotNull);
      expect(barch!.activeCurriculum!.structure.length, 10);
    });

    test('MBA has specialization structure with multiple options', () {
      final mba = catalog.getCourseById('mba');
      expect(mba, isNotNull);
      expect(mba!.category, CourseCategory.postgraduate);

      final curr = mba.activeCurriculum!;
      final root = curr.structure.first;
      expect(root.children.length, 6);

      final finance = root.findNodeById('node_mba_finance');
      expect(finance, isNotNull);
      expect(finance!.type, CatalogNodeType.specialization);
      expect(finance.children.length, 4);

      final financeSem1 = finance.findNodeById('node_mba_finance_sem_1');
      expect(financeSem1, isNotNull);
      expect(financeSem1!.subjects.any((s) => s.name.contains('Finance')), isTrue);

      final specializations = ['finance', 'marketing', 'hr', 'operations', 'analytics', 'international'];
      for (final spec in specializations) {
        final node = root.findNodeById('node_mba_$spec');
        expect(node, isNotNull, reason: 'MBA $spec should exist');
        expect(node!.type, CatalogNodeType.specialization);
      }
    });

    test('M.Sc has specialization structure', () {
      final msc = catalog.getCourseById('msc');
      expect(msc, isNotNull);
      expect(msc!.category, CourseCategory.postgraduate);

      final curr = msc.activeCurriculum!;
      final root = curr.structure.first;

      final specializations = ['physics', 'chemistry', 'mathematics', 'biology'];
      for (final spec in specializations) {
        final node = root.findNodeById('node_msc_$spec');
        expect(node, isNotNull, reason: 'M.Sc $spec should exist');
        expect(node!.type, CatalogNodeType.specialization);
        expect(node.children.length, 4);
      }
    });

    test('Postgraduate courses exist across disciplines', () {
      final pgCourses = [
        'mcom',
        'mba',
        'ma',
        'msc',
        'mca',
        'mtech_cse',
        'mtech_aiml',
        'mtech_ds',
        'llm',
        'm_des',
      ];

      for (final id in pgCourses) {
        final course = catalog.getCourseById(id);
        expect(course, isNotNull, reason: '$id should exist');
        expect(course!.category, CourseCategory.postgraduate);
      }
    });

    test('M.Tech specializations exist', () {
      final mtech = catalog.getCourseById('mtech_cse');
      expect(mtech, isNotNull);
      expect(mtech!.activeCurriculum!.structure.length, 4);

      final mtechAI = catalog.getCourseById('mtech_aiml');
      expect(mtechAI, isNotNull);

      final mtechDS = catalog.getCourseById('mtech_ds');
      expect(mtechDS, isNotNull);
    });

    test('Curriculum versioning works for higher education', () {
      final btech = catalog.getCourseById('btech_cse')!;
      expect(btech.catalogVersion, '2025-2026');

      final curr = btech.getCurriculumByVersion('2025-2026');
      expect(curr, isNotNull);
      expect(curr!.versionCode, '2025-2026');
    });

    test('Authority field is set to Generic for representative structures', () {
      final bcom = catalog.getCourseById('bcom')!;
      expect(bcom.authority, 'Generic');

      final btech = catalog.getCourseById('btech_cse')!;
      expect(btech.authority, 'Generic');

      final mba = catalog.getCourseById('mba')!;
      expect(mba.authority, 'Generic');
    });

    test('getCoursesByCategory returns undergraduate courses', () {
      final ugCourses = catalog.getCoursesByCategory(CourseCategory.undergraduate);
      expect(ugCourses.length, greaterThan(30));

      expect(ugCourses.any((c) => c.id == 'bcom'), isTrue);
      expect(ugCourses.any((c) => c.id == 'bca'), isTrue);
      expect(ugCourses.any((c) => c.id == 'btech_cse'), isTrue);
      expect(ugCourses.any((c) => c.id == 'mbbs'), isTrue);
    });

    test('getCoursesByCategory returns postgraduate courses', () {
      final pgCourses = catalog.getCoursesByCategory(CourseCategory.postgraduate);
      expect(pgCourses.length, greaterThan(5));

      expect(pgCourses.any((c) => c.id == 'mba'), isTrue);
      expect(pgCourses.any((c) => c.id == 'mca'), isTrue);
      expect(pgCourses.any((c) => c.id == 'mtech_cse'), isTrue);
    });

    test('searchCourses works for higher education', () {
      final btechResults = catalog.searchCourses('B.Tech');
      expect(btechResults.length, greaterThan(10));

      final mbaResults = catalog.searchCourses('MBA', category: CourseCategory.postgraduate);
      expect(mbaResults.length, 1);
      expect(mbaResults.first.id, 'mba');

      final csResults = catalog.searchCourses('Computer Science');
      expect(csResults.length, greaterThan(2));
    });

    test('Existing school catalog courses coexist with higher education', () {
      final schoolCourses = catalog.getCoursesByCategory(CourseCategory.school);
      expect(schoolCourses.length, greaterThan(5));

      final seniorSecCourses = catalog.getCoursesByCategory(CourseCategory.seniorSecondary);
      expect(seniorSecCourses.length, greaterThan(3));

      final cbse10 = catalog.getCourseById('cbse_class_10');
      expect(cbse10, isNotNull);

      final cbse12 = catalog.getCourseById('cbse_class_12');
      expect(cbse12, isNotNull);
    });

    test('Optional and elective metadata is preserved', () {
      final btech = catalog.getCourseById('btech_cse')!;
      final sem3 = btech.activeCurriculum!.findNodeById('node_btech_cse_sem_3')!;
      
      final elective = sem3.subjects.firstWhere((s) => s.name == 'Elective');
      expect(elective.type.name, 'elective');
    });

    test('createStudentSubject works with higher education catalog subject', () {
      final bca = catalog.getCourseById('bca')!;
      final progSubj = bca.activeCurriculum!.findSubjectById('bca_sem1_prog')!;

      final studentSubject = catalog.createStudentSubject(
        catalogSubject: progSubj,
        courseId: bca.id,
        catalogVersion: bca.catalogVersion,
      );

      expect(studentSubject.name, 'Programming Fundamentals');
      expect(studentSubject.catalogCourseId, 'bca');
      expect(studentSubject.catalogSubjectId, 'bca_sem1_prog');
      expect(studentSubject.catalogVersion, '2025-2026');
      expect(studentSubject.isCatalogLinked, isTrue);
    });
  });
}
