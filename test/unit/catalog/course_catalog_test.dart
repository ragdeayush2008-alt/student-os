import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/data/models/catalog/catalog_course.dart';
import 'package:student_os/data/models/catalog/catalog_curriculum.dart';
import 'package:student_os/data/models/catalog/catalog_node.dart';
import 'package:student_os/data/models/catalog/catalog_subject.dart';
import 'package:student_os/data/models/catalog/course_category.dart';
import 'package:student_os/data/models/student_profile.dart';
import 'package:student_os/data/models/subject.dart';

void main() {
  group('Course & Subject System Catalog — Phase 1 Foundation', () {
    setUp(() {
      CourseCatalogService.instance.clearCatalog();
    });

    test('Education categories are complete and identifiable', () {
      expect(CourseCategory.values.length, 8);
      expect(CourseCategory.school.label, 'School');
      expect(CourseCategory.seniorSecondary.label, 'Senior Secondary');
      expect(CourseCategory.undergraduate.label, 'Undergraduate');
      expect(CourseCategory.postgraduate.label, 'Postgraduate');
      expect(CourseCategory.professional.label, 'Professional');
      expect(CourseCategory.diploma.label, 'Diploma');
      expect(CourseCategory.vocational.label, 'Vocational');
      expect(CourseCategory.certification.label, 'Certification');

      expect(CourseCategory.fromString('school'), CourseCategory.school);
      expect(CourseCategory.fromString('professional'), CourseCategory.professional);
      expect(CourseCategory.fromString('unknown_val'), CourseCategory.school);
    });

    test('CatalogSubject model serialization, equality and requirement types', () {
      const subject = CatalogSubject(
        id: 'cbse_10_math',
        name: 'Mathematics',
        code: '041',
        shortName: 'Maths',
        description: 'Class 10 standard mathematics curriculum',
        type: SubjectRequirementType.compulsory,
        credits: 100.0,
        color: 0xFF1E88E5,
        iconCodePoint: 0xe123,
        metadata: {'board': 'CBSE'},
      );

      expect(subject.isCompulsory, isTrue);
      expect(subject.isElective, isFalse);
      expect(subject.displayName, 'Maths');

      final json = subject.toJson();
      final restored = CatalogSubject.fromJson(json);

      expect(restored, equals(subject));
      expect(restored.code, '041');
      expect(restored.credits, 100.0);
      expect(restored.metadata?['board'], 'CBSE');
    });

    test('Supports multi-depth School hierarchy: Course -> Class -> Subjects', () {
      const math = CatalogSubject(id: 'math_10', name: 'Mathematics', code: '041');
      const science = CatalogSubject(id: 'sci_10', name: 'Science', code: '086');
      const english = CatalogSubject(id: 'eng_10', name: 'English Language', code: '184');

      const class10Node = CatalogNode(
        id: 'node_class_10',
        name: 'Class 10',
        type: CatalogNodeType.level,
        subjects: [math, science, english],
      );

      const curriculum2024 = CatalogCurriculum(
        id: 'curr_cbse_10_2024',
        courseId: 'course_cbse_10',
        versionCode: '2024-2025',
        name: 'CBSE Secondary Curriculum 2024-25',
        structure: [class10Node],
      );

      const course = CatalogCourse(
        id: 'course_cbse_10',
        name: 'Class 10 CBSE',
        category: CourseCategory.school,
        authority: 'CBSE',
        catalogVersion: '2024-2025',
        curricula: [curriculum2024],
      );

      CourseCatalogService.instance.registerCourse(course);

      final retrieved = CourseCatalogService.instance.getCourseById('course_cbse_10');
      expect(retrieved, isNotNull);
      expect(retrieved!.category, CourseCategory.school);
      expect(retrieved.activeCurriculum?.totalSubjectCount, 3);
      expect(retrieved.activeCurriculum?.findSubjectById('math_10')?.name, 'Mathematics');
    });

    test('Supports multi-depth Professional hierarchy: Course -> Level -> Group -> Papers', () {
      const advAcc = CatalogSubject(id: 'ca_p1', name: 'Advanced Accounting', code: 'Paper 1');
      const corpLaw = CatalogSubject(id: 'ca_p2', name: 'Corporate and Other Laws', code: 'Paper 2');
      const tax = CatalogSubject(id: 'ca_p3', name: 'Taxation', code: 'Paper 3');

      const cost = CatalogSubject(id: 'ca_p4', name: 'Cost and Management Accounting', code: 'Paper 4');
      const audit = CatalogSubject(id: 'ca_p5', name: 'Auditing and Ethics', code: 'Paper 5');
      const fm = CatalogSubject(id: 'ca_p6', name: 'Financial Management', code: 'Paper 6');

      const group1 = CatalogNode(
        id: 'ca_inter_g1',
        name: 'Group I',
        type: CatalogNodeType.group,
        subjects: [advAcc, corpLaw, tax],
      );

      const group2 = CatalogNode(
        id: 'ca_inter_g2',
        name: 'Group II',
        type: CatalogNodeType.group,
        subjects: [cost, audit, fm],
      );

      const intermediateLevel = CatalogNode(
        id: 'ca_level_inter',
        name: 'Intermediate',
        type: CatalogNodeType.level,
        children: [group1, group2],
      );

      const caCurriculum = CatalogCurriculum(
        id: 'curr_icai_ca_inter_2024',
        courseId: 'icai_ca',
        versionCode: 'NEW_SCHEME_2024',
        name: 'ICAI New Scheme of Education and Training',
        structure: [intermediateLevel],
      );

      const caCourse = CatalogCourse(
        id: 'icai_ca',
        name: 'Chartered Accountancy',
        category: CourseCategory.professional,
        authority: 'ICAI',
        catalogVersion: 'NEW_SCHEME_2024',
        curricula: [caCurriculum],
      );

      CourseCatalogService.instance.registerCourse(caCourse);

      final foundCourse = CourseCatalogService.instance.getCourseById('icai_ca');
      expect(foundCourse, isNotNull);
      final activeCurr = foundCourse!.activeCurriculum!;
      expect(activeCurr.structure.length, 1);
      expect(activeCurr.structure.first.children.length, 2);
      expect(activeCurr.totalSubjectCount, 6);

      // Verify node search
      final g2Node = activeCurr.findNodeById('ca_inter_g2');
      expect(g2Node, isNotNull);
      expect(g2Node!.subjects.length, 3);
      expect(g2Node.subjects.map((s) => s.name), contains('Auditing and Ethics'));
    });

    test('Supports multi-depth University hierarchy: Course -> Specialization -> Semester -> Subjects', () {
      const ds = CatalogSubject(id: 'cs_ds', name: 'Data Structures', code: 'CS201', credits: 4.0);
      const dm = CatalogSubject(id: 'cs_dm', name: 'Discrete Mathematics', code: 'MA201', credits: 4.0);

      const sem3 = CatalogNode(
        id: 'btech_sem3',
        name: 'Semester 3',
        type: CatalogNodeType.semester,
        subjects: [ds, dm],
      );

      const aiSpec = CatalogNode(
        id: 'spec_ai',
        name: 'Artificial Intelligence & Machine Learning',
        type: CatalogNodeType.specialization,
        children: [sem3],
      );

      const btechCurriculum = CatalogCurriculum(
        id: 'curr_btech_cs_2024',
        courseId: 'btech_cs',
        versionCode: 'REV_2024',
        name: 'B.Tech CS Revised Curriculum',
        structure: [aiSpec],
      );

      const btechCourse = CatalogCourse(
        id: 'btech_cs',
        name: 'B.Tech Computer Science',
        category: CourseCategory.undergraduate,
        authority: 'University of Technology',
        catalogVersion: 'REV_2024',
        curricula: [btechCurriculum],
      );

      CourseCatalogService.instance.registerCourse(btechCourse);

      final retrieved = CourseCatalogService.instance.getCourseById('btech_cs');
      expect(retrieved, isNotNull);
      expect(retrieved!.category, CourseCategory.undergraduate);
      expect(retrieved.activeCurriculum?.allSubjects.length, 2);
    });

    test('Curriculum versioning allows switching between syllabus versions cleanly', () {
      const oldSubj = CatalogSubject(id: 'old_subj', name: 'Information Systems Control and Audit');
      const newSubj = CatalogSubject(id: 'new_subj', name: 'Information Technology and Strategic Management');

      const oldCurriculum = CatalogCurriculum(
        id: 'ca_old_2018',
        courseId: 'ca_course',
        versionCode: 'OLD_2018',
        name: 'Syllabus 2018',
        structure: [
          CatalogNode(
            id: 'old_node',
            name: 'Final Group 1',
            type: CatalogNodeType.group,
            subjects: [oldSubj],
          ),
        ],
      );

      const newCurriculum = CatalogCurriculum(
        id: 'ca_new_2024',
        courseId: 'ca_course',
        versionCode: 'NEW_2024',
        name: 'Syllabus 2024',
        structure: [
          CatalogNode(
            id: 'new_node',
            name: 'Final Group 1',
            type: CatalogNodeType.group,
            subjects: [newSubj],
          ),
        ],
      );

      const course = CatalogCourse(
        id: 'ca_course',
        name: 'CA Final',
        category: CourseCategory.professional,
        catalogVersion: 'NEW_2024',
        curricula: [oldCurriculum, newCurriculum],
      );

      CourseCatalogService.instance.registerCourse(course);

      // Active curriculum is NEW_2024
      final active = CourseCatalogService.instance.getCurriculum('ca_course');
      expect(active?.versionCode, 'NEW_2024');
      expect(active?.allSubjects.first.id, 'new_subj');

      // Specific lookup for OLD_2018
      final historical = CourseCatalogService.instance.getCurriculum('ca_course', versionCode: 'OLD_2018');
      expect(historical?.versionCode, 'OLD_2018');
      expect(historical?.allSubjects.first.id, 'old_subj');
    });

    test('Course search filters by text and category', () {
      final service = CourseCatalogService.instance;
      service.registerCourses([
        const CatalogCourse(
          id: 'c1',
          name: 'CBSE Class 10',
          category: CourseCategory.school,
          authority: 'CBSE',
        ),
        const CatalogCourse(
          id: 'c2',
          name: 'CBSE Class 12 Commerce',
          category: CourseCategory.seniorSecondary,
          authority: 'CBSE',
        ),
        const CatalogCourse(
          id: 'c3',
          name: 'Chartered Accountancy',
          category: CourseCategory.professional,
          authority: 'ICAI',
        ),
      ]);

      expect(service.searchCourses('cbse').length, 2);
      expect(service.searchCourses('accountancy').length, 1);
      expect(service.searchCourses('cbse', category: CourseCategory.seniorSecondary).length, 1);
    });

    test('Bridge: instantiates personal Subject from CatalogSubject preserving metadata', () {
      const catalogSubject = CatalogSubject(
        id: 'cat_acc_1',
        name: 'Financial Accounting',
        code: 'FA-101',
        shortName: 'Accounts',
        description: 'Basics of double entry bookkeeping',
        credits: 4.0,
        color: 0xFF2E7D32,
        iconCodePoint: 0xe84f,
      );

      final studentSubject = CourseCatalogService.instance.createStudentSubject(
        catalogSubject: catalogSubject,
        courseId: 'bcom_gen',
        catalogVersion: '2024',
      );

      expect(studentSubject.name, 'Financial Accounting');
      expect(studentSubject.shortName, 'Accounts');
      expect(studentSubject.displayName, 'Accounts');
      expect(studentSubject.catalogSubjectId, 'cat_acc_1');
      expect(studentSubject.catalogCourseId, 'bcom_gen');
      expect(studentSubject.catalogVersion, '2024');
      expect(studentSubject.code, 'FA-101');
      expect(studentSubject.credits, 4.0);
      expect(studentSubject.isCatalogLinked, isTrue);
    });

    test('Backward compatibility: legacy Subject and StudentProfile JSON loads cleanly', () {
      // 1. Legacy Subject JSON without catalog fields
      final legacySubjectJson = <String, dynamic>{
        'id': 'legacy_sub_1',
        'name': 'Physics',
        'shortName': 'Phy',
        'description': 'Mechanics and Waves',
        'color': 0xFF123456,
        'iconCodePoint': 0xeedf,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'archived': false,
      };

      final subject = Subject.fromJson(legacySubjectJson);
      expect(subject.id, 'legacy_sub_1');
      expect(subject.name, 'Physics');
      expect(subject.catalogSubjectId, isNull);
      expect(subject.catalogCourseId, isNull);
      expect(subject.isCatalogLinked, isFalse);

      // 2. Legacy StudentProfile JSON without catalog fields
      final legacyProfileJson = <String, dynamic>{
        'id': 'legacy_user',
        'displayName': 'Alex',
        'email': 'alex@example.com',
        'educationLevel': 'undergraduate',
        'institution': 'State College',
        'course': 'Computer Science',
        'currentYear': '2nd Year',
        'goals': ['academicExcellence'],
        'onboardingState': 'complete',
      };

      final profile = StudentProfile.fromJson(legacyProfileJson);
      expect(profile.id, 'legacy_user');
      expect(profile.displayName, 'Alex');
      expect(profile.catalogCourseId, isNull);
      expect(profile.hasCatalogCourse, isFalse);
    });
  });
}
