import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/data/models/catalog/active_course_selection.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/notes/student_note_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  group('Course Switch & Academic Track Preservation — Integration Tests', () {
    late CourseCatalogService catalog;
    late StudentService studentService;
    late SubjectController subjectController;
    late TaskController taskController;
    late StudyController studyController;
    late FocusController focusController;
    late StudentNoteController noteController;

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

      studyController = StudyController.instance;
      studyController.clearData();

      focusController = FocusController.instance;
      focusController.clearData();

      noteController = StudentNoteController.instance;
      noteController.clearData();

      AuthIsolation.instance.setAuthenticatedUser('integration_test_user');
    });

    tearDown(() {
      studentService.clearProfile();
      subjectController.clearData();
      taskController.clearData();
      studyController.clearData();
      focusController.clearData();
      noteController.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('End-to-End: Switch course from CA Foundation to JEE Main without losing any data', () async {
      // 1. Initial selection: CA Foundation 2026
      final caSelection = ActiveCourseSelection(
        userId: 'integration_test_user',
        categoryId: 'commerce_accounting_finance',
        familyId: 'ca',
        programId: 'ca_foundation',
        programTitle: 'CA Foundation',
        levelId: 'ca_f_level',
        levelTitle: 'Foundation Level',
        year: '2026',
      );
      await catalog.setActiveCourse(caSelection);

      expect(catalog.getActiveCourse(), 'CA Foundation');
      expect(catalog.getActiveYear(), '2026');
      expect(subjectController.subjects.length, 4);

      final accountingSubj = subjectController.subjects.firstWhere((s) => s.name == 'Accounting');

      // 2. User creates task on Accounting
      final task = await taskController.createTask(
        title: 'Study Accounting Standards',
        subjectId: accountingSubj.id,
      );
      expect(taskController.tasks.length, 1);

      // 3. User records a completed study session on Accounting
      await studyController.recordFocusCompletion(
        focusSessionId: 'test_session_1',
        subject: 'Accounting',
        subjectId: accountingSubj.id,
        durationSec: 45 * 60,
      );
      expect(studyController.sessions.length, 1);

      // 4. User creates a study note on Accounting
      await noteController.createNote(
        title: 'Depreciation Notes',
        content: 'Straight line method vs written down value',
        subjectId: accountingSubj.id,
      );
      expect(noteController.notes.length, 1);

      // 5. USER SWITCHES COURSE TO JEE MAIN 2026
      final jeeSelection = ActiveCourseSelection(
        userId: 'integration_test_user',
        categoryId: 'engineering_technology',
        familyId: 'jee',
        programId: 'jee_main',
        programTitle: 'JEE Main',
        levelId: 'jee_m_p1',
        levelTitle: 'Paper 1',
        year: '2026',
      );
      await catalog.switchCourse(newSelection: jeeSelection);

      // 6. Verify active academic track is updated
      expect(catalog.getActiveCourse(), 'JEE Main');
      expect(catalog.getActiveProgram(), 'jee_main');
      expect(studentService.profile.course, 'JEE Main');

      // 7. Verify new subjects provisioned
      expect(subjectController.subjects.any((s) => s.name == 'Physics'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Chemistry'), isTrue);
      expect(subjectController.subjects.any((s) => s.name == 'Mathematics'), isTrue);

      // 8. CRITICAL VERIFICATION: All previous user data is intact!
      // Task preserved:
      expect(taskController.tasks.length, 1);
      expect(taskController.tasks.first.id, task.id);
      expect(taskController.tasks.first.title, 'Study Accounting Standards');

      // Study session preserved:
      expect(studyController.sessions.length, 1);
      expect(studyController.sessions.first.subjectId, accountingSubj.id);
      expect(studyController.sessions.first.durationSec, 45 * 60);

      // Note preserved:
      expect(noteController.notes.length, 1);
      expect(noteController.notes.first.title, 'Depreciation Notes');

      // Accounting subject preserved:
      expect(subjectController.subjectById(accountingSubj.id), isNotNull);

      // 9. User switches back to CA Foundation 2026
      await catalog.switchCourse(newSelection: caSelection);
      expect(catalog.getActiveCourse(), 'CA Foundation');

      // 10. No duplicate subjects were created!
      expect(
        subjectController.subjects.where((s) => s.name == 'Accounting').length,
        1,
      );
    });
  });
}
