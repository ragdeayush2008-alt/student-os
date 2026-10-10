import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/data/models/academic_resource.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/resources/resource_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 7 Step 14 — Exam ↔ Resource integration', () {
    test(
      'resourcesForExam returns only resources linked to that exam',
      () async {
        final exam = await ExamController.instance.createExam(
          title: 'Physics Final',
          subject: 'Physics',
          examDateTime: DateTime.now().add(const Duration(days: 7)),
        );

        final linked = await ResourceController.instance.createResource(
          title: 'Physics notes',
          resourceType: ResourceType.note,
          examId: exam.id,
        );

        final unlinked = await ResourceController.instance.createResource(
          title: 'Unrelated note',
          resourceType: ResourceType.note,
        );

        final result = ResourceController.instance.resourcesForExam(exam.id);
        expect(result.length, 1);
        expect(result.first.id, linked.id);
        expect(result.first.examId, exam.id);

        // Cleanup
        await ExamController.instance.deleteExam(exam.id);
        await ResourceController.instance.deleteResource(linked.id);
        await ResourceController.instance.deleteResource(unlinked.id);
      },
    );

    test('creating resource with examId links it to the exam', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Math Quiz',
        subject: 'Math',
        examDateTime: DateTime.now().add(const Duration(days: 3)),
      );

      final resource = await ResourceController.instance.createResource(
        title: 'Revision notes',
        resourceType: ResourceType.revision,
        examId: exam.id,
      );

      expect(resource.examId, exam.id);
      expect(resource.hasExam, isTrue);

      final retrieved = ResourceController.instance.resources
          .where((r) => r.id == resource.id)
          .single;
      expect(retrieved.examId, exam.id);

      // Cleanup
      await ExamController.instance.deleteExam(exam.id);
      await ResourceController.instance.deleteResource(resource.id);
    });

    test('resource can be linked to both exam and subject', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Chemistry',
      );
      final exam = await ExamController.instance.createExam(
        title: 'Chemistry Midterm',
        subject: 'Chemistry',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
      );

      final resource = await ResourceController.instance.createResource(
        title: 'Organic chemistry guide',
        resourceType: ResourceType.document,
        subjectId: subject.id,
        examId: exam.id,
      );

      expect(resource.subjectId, subject.id);
      expect(resource.examId, exam.id);
      expect(resource.hasSubject, isTrue);
      expect(resource.hasExam, isTrue);

      // Cleanup
      await SubjectController.instance.deleteSubject(subject.id);
      await ExamController.instance.deleteExam(exam.id);
      await ResourceController.instance.deleteResource(resource.id);
    });

    test(
      'clearExamReference removes exam link but preserves resource',
      () async {
        final exam = await ExamController.instance.createExam(
          title: 'Bio Final',
          subject: 'Biology',
          examDateTime: DateTime.now().add(const Duration(days: 10)),
        );

        final resource = await ResourceController.instance.createResource(
          title: 'Bio study material',
          resourceType: ResourceType.document,
          examId: exam.id,
        );

        expect(resource.examId, exam.id);

        // Clear exam reference
        await ResourceController.instance.clearExamReference(exam.id);

        final updated = ResourceController.instance.resources
            .where((r) => r.id == resource.id)
            .single;

        expect(updated.examId, isNull);
        expect(updated.hasExam, isFalse);
        expect(updated.title, 'Bio study material'); // Resource still exists

        // Cleanup
        await ExamController.instance.deleteExam(exam.id);
        await ResourceController.instance.deleteResource(resource.id);
      },
    );
  });

  group('Phase 7 Step 15 — Task ↔ Subject integration', () {
    test('task can have subjectId', () {
      final task = StudentTask(
        id: 't1',
        title: 'Complete assignment',
        subjectId: 'sub_123',
      );

      expect(task.subjectId, 'sub_123');
    });

    test('task JSON with subjectId serializes correctly', () {
      final task = StudentTask(
        id: 't1',
        title: 'Task',
        subjectId: 'sub_1',
        category: 'Math', // Legacy field
      );

      final json = task.toJson();
      expect(json['subjectId'], 'sub_1');
      expect(json['category'], 'Math');

      final restored = StudentTask.fromJson(json);
      expect(restored.subjectId, 'sub_1');
      expect(restored.category, 'Math');
    });

    test('legacy task JSON without subjectId deserializes correctly', () {
      final legacyJson = {
        'id': 't_legacy',
        'title': 'Old task',
        'description': '',
        'priority': 'medium',
        'status': 'active',
        'category': 'History',
        'createdAt': '2024-01-01T10:00:00.000',
        'sortOrder': 0,
      };

      final task = StudentTask.fromJson(legacyJson);
      expect(task.subjectId, isNull);
      expect(task.category, 'History');
      expect(task.title, 'Old task');
    });

    test(
      'activeTasksForSubject returns only active tasks for subject',
      () async {
        final subject = await SubjectController.instance.createSubject(
          name: 'English',
        );

        final activeTask = await TaskController.instance.createTask(
          title: 'Write essay',
          subjectId: subject.id,
        );

        final completedTask = await TaskController.instance.createTask(
          title: 'Read chapter',
          subjectId: subject.id,
        );
        await TaskController.instance.completeTask(completedTask.id);

        final otherTask = await TaskController.instance.createTask(
          title: 'Unrelated task',
        );

        final result = TaskController.instance.activeTasksForSubject(
          subject.id,
        );
        expect(result.length, 1);
        expect(result.first.id, activeTask.id);

        // Cleanup
        await TaskController.instance.deleteTask(activeTask.id);
        await TaskController.instance.deleteTask(completedTask.id);
        await TaskController.instance.deleteTask(otherTask.id);
        await SubjectController.instance.deleteSubject(subject.id);
      },
    );

    test('task can have both subjectId and examId', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Physics',
      );
      final exam = await ExamController.instance.createExam(
        title: 'Physics Test',
        subject: 'Physics',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );

      final task = await TaskController.instance.createTask(
        title: 'Revise for test',
        subjectId: subject.id,
        examId: exam.id,
      );

      expect(task.subjectId, subject.id);
      expect(task.examId, exam.id);

      // Cleanup
      await TaskController.instance.deleteTask(task.id);
      await ExamController.instance.deleteExam(exam.id);
      await SubjectController.instance.deleteSubject(subject.id);
    });
  });

  group('Phase 7 Step 16 — Subject deletion/reference policy', () {
    test(
      'deleting subject clears task references but preserves tasks',
      () async {
        final subject = await SubjectController.instance.createSubject(
          name: 'Geography',
        );

        final task = await TaskController.instance.createTask(
          title: 'Map assignment',
          subjectId: subject.id,
        );

        expect(task.subjectId, subject.id);

        // Delete subject
        await SubjectController.instance.deleteSubject(subject.id);

        // Task still exists but link is cleared
        final updatedTask = TaskController.instance.tasks
            .where((t) => t.id == task.id)
            .single;
        expect(updatedTask.subjectId, isNull);
        expect(updatedTask.title, 'Map assignment');

        // Cleanup
        await TaskController.instance.deleteTask(task.id);
      },
    );

    test(
      'deleting subject clears resource references but preserves resources',
      () async {
        final subject = await SubjectController.instance.createSubject(
          name: 'Art',
        );

        final resource = await ResourceController.instance.createResource(
          title: 'Art history notes',
          resourceType: ResourceType.note,
          subjectId: subject.id,
        );

        expect(resource.subjectId, subject.id);

        // Delete subject
        await SubjectController.instance.deleteSubject(subject.id);

        // Resource still exists but link is cleared
        final updatedResource = ResourceController.instance.resources
            .where((r) => r.id == resource.id)
            .single;
        expect(updatedResource.subjectId, isNull);
        expect(updatedResource.title, 'Art history notes');

        // Cleanup
        await ResourceController.instance.deleteResource(resource.id);
      },
    );

    test('archiving subject does NOT clear references', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Music',
      );

      final task = await TaskController.instance.createTask(
        title: 'Practice scales',
        subjectId: subject.id,
      );

      final resource = await ResourceController.instance.createResource(
        title: 'Theory guide',
        resourceType: ResourceType.document,
        subjectId: subject.id,
      );

      // Archive subject
      await SubjectController.instance.archiveSubject(subject.id);

      // References remain intact
      final updatedTask = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .single;
      final updatedResource = ResourceController.instance.resources
          .where((r) => r.id == resource.id)
          .single;

      expect(updatedTask.subjectId, subject.id);
      expect(updatedResource.subjectId, subject.id);

      // Cleanup
      await TaskController.instance.deleteTask(task.id);
      await ResourceController.instance.deleteResource(resource.id);
      await SubjectController.instance.deleteSubject(subject.id);
    });

    test('restoring subject keeps existing references', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Drama',
      );

      final task = await TaskController.instance.createTask(
        title: 'Learn lines',
        subjectId: subject.id,
      );

      await SubjectController.instance.archiveSubject(subject.id);
      await SubjectController.instance.restoreSubject(subject.id);

      final updatedTask = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .single;
      expect(updatedTask.subjectId, subject.id);

      // Cleanup
      await TaskController.instance.deleteTask(task.id);
      await SubjectController.instance.deleteSubject(subject.id);
    });

    test('renaming subject preserves all references', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Computer Science',
      );

      final task = await TaskController.instance.createTask(
        title: 'Code review',
        subjectId: subject.id,
      );

      final resource = await ResourceController.instance.createResource(
        title: 'Algorithm notes',
        resourceType: ResourceType.note,
        subjectId: subject.id,
      );

      // Rename subject
      await SubjectController.instance.updateSubject(
        subject.copyWith(name: 'CS'),
      );

      // References still point to same subject ID
      final updatedTask = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .single;
      final updatedResource = ResourceController.instance.resources
          .where((r) => r.id == resource.id)
          .single;

      expect(updatedTask.subjectId, subject.id);
      expect(updatedResource.subjectId, subject.id);

      // Cleanup
      await TaskController.instance.deleteTask(task.id);
      await ResourceController.instance.deleteResource(resource.id);
      await SubjectController.instance.deleteSubject(subject.id);
    });
  });

  group('Phase 7 Step 17 — Resource context surfaces', () {
    test('resource with subject and exam preserves both links', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Economics',
      );
      final exam = await ExamController.instance.createExam(
        title: 'Econ Final',
        subject: 'Economics',
        examDateTime: DateTime.now().add(const Duration(days: 14)),
      );

      final resource = await ResourceController.instance.createResource(
        title: 'Macro notes',
        resourceType: ResourceType.note,
        subjectId: subject.id,
        examId: exam.id,
        content: 'Supply and demand basics',
      );

      expect(resource.subjectId, subject.id);
      expect(resource.examId, exam.id);
      expect(resource.hasSubject, isTrue);
      expect(resource.hasExam, isTrue);
      expect(resource.hasContent, isTrue);

      // Verify queries work
      final bySubject = ResourceController.instance.resourcesForSubject(
        subject.id,
      );
      final byExam = ResourceController.instance.resourcesForExam(exam.id);

      expect(bySubject, contains(resource));
      expect(byExam, contains(resource));

      // Cleanup
      await ResourceController.instance.deleteResource(resource.id);
      await ExamController.instance.deleteExam(exam.id);
      await SubjectController.instance.deleteSubject(subject.id);
    });

    test('updating resource can add/remove subject and exam links', () async {
      final subject1 = await SubjectController.instance.createSubject(
        name: 'Subject 1',
      );
      final subject2 = await SubjectController.instance.createSubject(
        name: 'Subject 2',
      );

      final resource = await ResourceController.instance.createResource(
        title: 'Movable note',
        resourceType: ResourceType.note,
        subjectId: subject1.id,
      );

      expect(resource.subjectId, subject1.id);

      // Move to subject2
      await ResourceController.instance.updateResource(
        resource.copyWith(subjectId: subject2.id),
      );

      final updated1 = ResourceController.instance.resources
          .where((r) => r.id == resource.id)
          .single;
      expect(updated1.subjectId, subject2.id);

      // Clear subject link
      await ResourceController.instance.updateResource(
        updated1.copyWith(clearSubjectId: true),
      );

      final updated2 = ResourceController.instance.resources
          .where((r) => r.id == resource.id)
          .single;
      expect(updated2.subjectId, isNull);

      // Cleanup
      await ResourceController.instance.deleteResource(resource.id);
      await SubjectController.instance.deleteSubject(subject1.id);
      await SubjectController.instance.deleteSubject(subject2.id);
    });
  });
}
