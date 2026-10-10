import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/data/models/catalog/active_course_selection.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  group('ActiveCourseSelection & Non-Destructive Switching — Unit Tests', () {
    late CourseCatalogService catalog;
    late StudentService studentService;
    late SubjectController subjectController;
    late TaskController taskController;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      catalog = CourseCatalogService.instance;
      catalog.ensureInitialized();
      catalog.loadDefaults();

      studentService = StudentService.instance;
      studentService.clearProfile();

      subjectController = SubjectController.instance;
      subjectController.clearData();

      taskController = TaskController.instance;
      taskController.clearData();

      AuthIsolation.instance.setAuthenticatedUser('test_student_1');
    });

    tearDown(() {
      studentService.clearProfile();
      subjectController.clearData();
      taskController.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('1. Model: ActiveCourseSelection serialization & display label', () {
      final selection = ActiveCourseSelection(
        userId: 'user_123',
        categoryId: 'commerce_accounting_finance',
        familyId: 'ca',
        programId: 'ca_foundation',
        programTitle: 'CA Foundation',
        levelId: 'ca_f_level',
        levelTitle: 'Foundation Level',
        year: '2026',
        authority: 'ICAI',
      );

      expect(selection.fullDisplayName, contains('CA Foundation'));
      expect(selection.fullDisplayName, contains('2026'));

      final json = selection.toJson();
      final restored = ActiveCourseSelection.fromJson(json);

      expect(restored.userId, 'user_123');
      expect(restored.programId, 'ca_foundation');
      expect(restored.year, '2026');
      expect(restored.authority, 'ICAI');
    });

    test('2. Authoritative Resolution: getActiveCourse(), getActiveProgram(), getActiveLevel(), getActiveYear()', () async {
      expect(catalog.getActiveCourse(), isNull);

      final caSelection = ActiveCourseSelection(
        userId: 'test_student_1',
        categoryId: 'commerce_accounting_finance',
        familyId: 'ca',
        programId: 'ca_foundation',
        programTitle: 'CA Foundation',
        levelId: 'ca_f_level',
        levelTitle: 'Foundation Level',
        year: '2026',
        authority: 'ICAI',
      );

      await catalog.setActiveCourse(caSelection);

      expect(catalog.getActiveCourse(), 'CA Foundation');
      expect(catalog.getActiveProgram(), 'ca_foundation');
      expect(catalog.getActiveLevel(), 'Foundation Level');
      expect(catalog.getActiveYear(), '2026');
      expect(catalog.hasActiveCourse, isTrue);
    });

    test('3. Non-Destructive Switching: Preserves tasks and existing custom subjects', () async {
      // 1. Student selects CA Foundation 2026
      final caSelection = ActiveCourseSelection(
        userId: 'test_student_1',
        categoryId: 'commerce_accounting_finance',
        familyId: 'ca',
        programId: 'ca_foundation',
        programTitle: 'CA Foundation',
        levelId: 'ca_f_level',
        levelTitle: 'Foundation Level',
        year: '2026',
      );
      await catalog.setActiveCourse(caSelection);

      // Verify CA subjects provisioned
      expect(subjectController.subjects.length, 4);
      final accountingSubj = subjectController.subjects.firstWhere((s) => s.name == 'Accounting');

      // 2. Student creates a task for Accounting
      await taskController.createTask(
        title: 'Complete Chapter 1 Trial Balance',
        subjectId: accountingSubj.id,
      );
      expect(taskController.tasks.length, 1);

      // 3. Student switches course to JEE Main 2026
      final jeeSelection = ActiveCourseSelection(
        userId: 'test_student_1',
        categoryId: 'engineering_technology',
        familyId: 'jee',
        programId: 'jee_main',
        programTitle: 'JEE Main',
        levelId: 'jee_m_p1',
        levelTitle: 'Paper 1',
        year: '2026',
      );
      await catalog.switchCourse(newSelection: jeeSelection);

      // Verify active course is updated to JEE Main
      expect(catalog.getActiveCourse(), 'JEE Main');
      expect(catalog.getActiveProgram(), 'jee_main');

      // Verify JEE subjects (Physics, Chemistry, Mathematics) are provisioned
      expect(subjectController.subjects.any((s) => s.name == 'Physics'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Chemistry'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Mathematics'), isTrue);

      // CRITICAL SAFETY: Verify old Accounting subject and task are NOT destroyed
      expect(subjectController.subjects.any((s) => s.name == 'Accounting'), isTrue);
      expect(taskController.tasks.length, 1);
      expect(taskController.tasks.first.title, 'Complete Chapter 1 Trial Balance');
      expect(taskController.tasks.first.subjectId, accountingSubj.id);
    });

    test('4. Idempotency: Selecting the same course again does not duplicate subjects', () async {
      final caSelection = ActiveCourseSelection(
        userId: 'test_student_1',
        categoryId: 'commerce_accounting_finance',
        familyId: 'ca',
        programId: 'ca_foundation',
        programTitle: 'CA Foundation',
        levelId: 'ca_f_level',
        levelTitle: 'Foundation Level',
        year: '2026',
      );

      await catalog.setActiveCourse(caSelection);
      expect(subjectController.subjects.length, 4);

      // Set again
      await catalog.setActiveCourse(caSelection);
      expect(subjectController.subjects.length, 4); // Still 4, no duplicates
    });

    test('5. User Isolation: Course selection is isolated between User A and User B', () async {
      // User A selects CA Foundation
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      await catalog.setActiveCourse(
        ActiveCourseSelection(
          userId: 'user_A',
          categoryId: 'commerce_accounting_finance',
          familyId: 'ca',
          programId: 'ca_foundation',
          programTitle: 'CA Foundation',
          levelId: 'ca_f_level',
          levelTitle: 'Foundation Level',
        ),
      );
      expect(catalog.getActiveCourse(), 'CA Foundation');

      // User B logs in
      AuthIsolation.instance.setAuthenticatedUser('user_B');
      studentService.clearProfile();
      await catalog.loadActiveCourse();

      // User B selects JEE Main
      await catalog.setActiveCourse(
        ActiveCourseSelection(
          userId: 'user_B',
          categoryId: 'engineering_technology',
          familyId: 'jee',
          programId: 'jee_main',
          programTitle: 'JEE Main',
          levelId: 'jee_m_p1',
          levelTitle: 'Paper 1',
        ),
      );
      expect(catalog.getActiveCourse(), 'JEE Main');

      // Switch back to User A
      AuthIsolation.instance.setAuthenticatedUser('user_A');
      studentService.clearProfile();
      await catalog.loadActiveCourse();
      expect(catalog.getActiveCourse(), 'CA Foundation');
    });
  });
}
