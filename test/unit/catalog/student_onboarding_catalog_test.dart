import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/data/models/catalog/course_category.dart';
import 'package:student_os/data/models/student_profile.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  group('Phase 5 — Student Onboarding & Automatic Subject Engine', () {
    late CourseCatalogService catalog;
    late SubjectController subjectController;
    late StudentService studentService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      catalog = CourseCatalogService.instance;
      catalog.ensureInitialized();
      catalog.loadDefaults();

      subjectController = SubjectController.instance;
      subjectController.clearData();

      studentService = StudentService.instance;
      studentService.clearProfile();

      AuthIsolation.instance.setAuthenticatedUser('test_user_1');
    });

    tearDown(() {
      subjectController.clearData();
      studentService.clearProfile();
      AuthIsolation.instance.clearSession();
    });

    test('1. Unconfigured student has incomplete onboarding state', () {
      final profile = studentService.profile;
      expect(profile.isOnboardingComplete, isFalse);
      expect(profile.hasCatalogCourse, isFalse);
    });

    test('2. Resolves subjects for School Class 10 CBSE with compulsory and optional electives', () {
      final resolved = catalog.resolveSubjectsForSelection(
        courseId: 'cbse_class_10',
        selectedNodeIds: ['node_cbse_class_10'],
      );

      final compulsory = resolved['compulsory']!;
      final optional = resolved['optional']!;

      expect(compulsory.length, greaterThanOrEqualTo(4));
      expect(compulsory.any((s) => s.name == 'English Language and Literature'), isTrue);
      expect(compulsory.any((s) => s.name == 'Mathematics (Standard)'), isTrue);
      expect(compulsory.any((s) => s.name == 'Science'), isTrue);
      expect(compulsory.any((s) => s.name == 'Social Science'), isTrue);

      expect(optional.length, greaterThanOrEqualTo(4));
      expect(optional.any((s) => s.name == 'Information Technology'), isTrue);
      expect(optional.any((s) => s.name == 'Artificial Intelligence'), isTrue);
    });

    test('3. Automatic Provisioning: Class 10 CBSE provisions compulsory + selected electives only', () async {
      final provisioned = await catalog.provisionStudentSubjects(
        courseId: 'cbse_class_10',
        selectedNodeIds: ['node_cbse_class_10'],
        selectedOptionalSubjectIds: ['cbse_c10_it', 'cbse_c10_ai'],
      );

      expect(provisioned.length, 6); // 4 compulsory + 2 selected electives
      expect(subjectController.subjects.length, 6);

      // Verify all subjects have catalog linkages
      for (final s in subjectController.subjects) {
        expect(s.isCatalogLinked, isTrue);
        expect(s.catalogCourseId, 'cbse_class_10');
        expect(s.catalogVersion, isNotNull);
      }

      // Check specific compulsory subjects exist
      expect(subjectController.subjects.any((s) => s.name == 'Mathematics (Standard)'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Science'), isTrue);

      // Check selected electives exist
      expect(subjectController.subjects.any((s) => s.name == 'Information Technology'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Artificial Intelligence'), isTrue);

      // Check unselected electives do NOT exist
      expect(subjectController.subjects.any((s) => s.name == 'Computer Applications'), isFalse);
      expect(subjectController.subjects.any((s) => s.name == 'Introduction to Financial Markets'), isFalse);
    });

    test('4. Automatic Provisioning: Class 11 Senior Secondary Science PCM stream', () async {
      final provisioned = await catalog.provisionStudentSubjects(
        courseId: 'cbse_class_11',
        selectedNodeIds: ['cbse_c11_sci_pcm'],
        selectedOptionalSubjectIds: ['cbse_c11_cs'], // Computer Science elective
      );

      expect(provisioned.length, 5); // English, Physics, Chem, Math + CS
      expect(subjectController.subjects.any((s) => s.name == 'English Core'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Physics'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Chemistry'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Mathematics'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Computer Science'), isTrue);

      // Unselected electives not added
      expect(subjectController.subjects.any((s) => s.name == 'Physical Education'), isFalse);
    });

    test('5. Automatic Provisioning: Class 11 Commerce with Mathematics', () async {
      final provisioned = await catalog.provisionStudentSubjects(
        courseId: 'cbse_class_11',
        selectedNodeIds: ['cbse_c11_comm_math'],
        selectedOptionalSubjectIds: ['cbse_c11_ent'], // Entrepreneurship
      );

      expect(provisioned.length, 6); // English, Accounts, BST, Eco, Math + Entrepreneurship
      expect(subjectController.subjects.any((s) => s.name == 'Accountancy'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Business Studies'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Economics'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Mathematics'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Entrepreneurship'), isTrue);
    });

    test('6. Automatic Provisioning: Undergraduate B.Tech Computer Science Semester 1', () async {
      final provisioned = await catalog.provisionStudentSubjects(
        courseId: 'btech_cse',
        selectedNodeIds: ['node_btech_cse_sem_1'],
      );

      expect(provisioned.length, 3);
      expect(subjectController.subjects.any((s) => s.name == 'Engineering Mathematics I'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Engineering Physics'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Engineering Chemistry'), isTrue);
    });

    test('7. Automatic Provisioning: Professional CA Intermediate Group I', () async {
      final provisioned = await catalog.provisionStudentSubjects(
        courseId: 'ca_intermediate',
        selectedNodeIds: ['node_ca_intermediate_group1'],
      );

      expect(provisioned.length, 4);
      expect(subjectController.subjects.any((s) => s.name == 'Accounting & Finance'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Audit & Assurance'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Company Law'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Cost & Management Accounting'), isTrue);
    });

    test('8. Automatic Provisioning: ACCA Strategic Professional with optional papers', () async {
      final provisioned = await catalog.provisionStudentSubjects(
        courseId: 'acca_strategic_professional',
        selectedNodeIds: ['node_acca_sp_compulsory', 'node_acca_sp_optional'],
        selectedOptionalSubjectIds: ['acca_sp_afm'], // Advanced Financial Management only
      );

      expect(provisioned.length, 3); // 2 compulsory + 1 selected optional
      expect(subjectController.subjects.any((s) => s.name == 'Strategic Business Leader'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Advanced Audit & Assurance'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Advanced Financial Management'), isTrue);

      // Unselected optionals not created
      expect(subjectController.subjects.any((s) => s.name == 'Advanced Taxation'), isFalse);
    });

    test('9. Idempotency: Re-running onboarding does NOT duplicate subjects', () async {
      // First run
      await catalog.provisionStudentSubjects(
        courseId: 'cbse_class_10',
        selectedNodeIds: ['node_cbse_class_10'],
        selectedOptionalSubjectIds: ['cbse_c10_it'],
      );
      expect(subjectController.subjects.length, 5);

      // Second run with same parameters
      await catalog.provisionStudentSubjects(
        courseId: 'cbse_class_10',
        selectedNodeIds: ['node_cbse_class_10'],
        selectedOptionalSubjectIds: ['cbse_c10_it'],
      );
      expect(subjectController.subjects.length, 5); // Count remains 5, no duplicates!
    });

    test('10. Non-destructive course transition: changing course preserves existing custom subjects', () async {
      // User creates a custom subject first
      final custom = await subjectController.createSubject(name: 'Robotics Club Project');
      expect(subjectController.subjects.length, 1);

      // User provisions CA Foundation
      await catalog.provisionStudentSubjects(
        courseId: 'ca_foundation',
        selectedNodeIds: ['node_ca_foundation'],
      );
      expect(subjectController.subjects.length, 5); // 1 custom + 4 CA Foundation

      // Verify custom subject is untouched
      expect(subjectController.subjectById(custom.id), isNotNull);
      expect(subjectController.subjectById(custom.id)!.name, 'Robotics Club Project');
    });

    test('11. StudentProfile stores complete catalog education metadata and persists', () async {
      await studentService.updateCatalogEducation(
        category: CourseCategory.undergraduate,
        courseId: 'btech_cse',
        courseName: 'B.Tech Computer Science',
        curriculumId: 'curr_btech_cse_2025',
        nodeId: 'node_btech_cse_sem_1',
        authority: 'Generic',
        levelId: 'node_btech_cse_sem_1',
        currentYear: 'Semester 1',
      );
      await studentService.completeOnboarding();

      final profile = studentService.profile;
      expect(profile.isOnboardingComplete, isTrue);
      expect(profile.hasCatalogCourse, isTrue);
      expect(profile.catalogCategory, CourseCategory.undergraduate);
      expect(profile.catalogCourseId, 'btech_cse');
      expect(profile.course, 'B.Tech Computer Science');
      expect(profile.currentYear, 'Semester 1');

      // Verify JSON serialization round-trip
      final json = profile.toJson();
      final restored = StudentProfile.fromJson(json);

      expect(restored.catalogCategory, CourseCategory.undergraduate);
      expect(restored.catalogCourseId, 'btech_cse');
      expect(restored.catalogCurriculumId, 'curr_btech_cse_2025');
      expect(restored.catalogNodeId, 'node_btech_cse_sem_1');
      expect(restored.isOnboardingComplete, isTrue);
    });

    test('12. Authenticated user isolation: user A and user B subjects are separate', () async {
      // User A setup
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      await subjectController.load();
      await catalog.provisionStudentSubjects(
        courseId: 'cbse_class_10',
        selectedNodeIds: ['node_cbse_class_10'],
      );
      expect(subjectController.subjects.length, 4);

      // Switch to User B
      AuthIsolation.instance.setAuthenticatedUser('user_B');
      subjectController.clearData();
      await subjectController.load();
      expect(subjectController.subjects, isEmpty);

      // User B provisions CA Foundation
      await catalog.provisionStudentSubjects(
        courseId: 'ca_foundation',
        selectedNodeIds: ['node_ca_foundation'],
      );
      expect(subjectController.subjects.length, 4);
      expect(subjectController.subjects.any((s) => s.name.contains('Accounting')), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Mathematics (Standard)'), isFalse);
    });
  });
}
