import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 5 — Subjects workspace controller semantics.
///
/// Covers subject CRUD, archive/restore, task linkage by canonical subjectId,
/// and safe deletion that preserves tasks while clearing references.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _clean();
  });

  tearDown(() async {
    await _clean();
  });

  group('Subject CRUD', () {
    test('create stores name and defaults', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Mathematics',
      );
      addTearDown(() => SubjectController.instance.deleteSubject(subject.id));

      expect(subject.name, 'Mathematics');
      expect(subject.id.isNotEmpty, isTrue);
      expect(subject.archived, isFalse);
      expect(
        SubjectController.instance.subjectById(subject.id)?.name,
        'Mathematics',
      );
    });

    test('update renames subject', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Maths',
      );
      addTearDown(() => SubjectController.instance.deleteSubject(subject.id));

      await SubjectController.instance.updateSubject(
        subject.copyWith(name: 'Mathematics'),
      );
      expect(
        SubjectController.instance.subjectById(subject.id)?.name,
        'Mathematics',
      );
    });

    test('archive hides from active, restore brings back', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Archived sub',
      );
      addTearDown(() => SubjectController.instance.deleteSubject(subject.id));

      await SubjectController.instance.archiveSubject(subject.id);
      expect(
        SubjectController.instance.activeSubjects.any(
          (s) => s.id == subject.id,
        ),
        isFalse,
      );
      expect(
        SubjectController.instance.archivedSubjects.any(
          (s) => s.id == subject.id,
        ),
        isTrue,
      );

      await SubjectController.instance.restoreSubject(subject.id);
      expect(
        SubjectController.instance.activeSubjects.any(
          (s) => s.id == subject.id,
        ),
        isTrue,
      );
    });

    test('subjectById returns null for missing id', () {
      expect(SubjectController.instance.subjectById('missing'), isNull);
    });
  });

  group('Subject ↔ Task relationship', () {
    test('tasksForSubject uses canonical subjectId', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Physics',
      );
      addTearDown(() => SubjectController.instance.deleteSubject(subject.id));
      final task = await TaskController.instance.createTask(
        title: 'Physics task',
        subjectId: subject.id,
      );
      addTearDown(() => TaskController.instance.deleteTask(task.id));

      expect(TaskController.instance.tasksForSubject(subject.id).length, 1);
      expect(
        TaskController.instance.activeTasksForSubject(subject.id).length,
        1,
      );

      await TaskController.instance.completeTask(task.id);
      expect(
        TaskController.instance.activeTasksForSubject(subject.id),
        isEmpty,
      );
      expect(
        TaskController.instance.completedTasksForSubject(subject.id).length,
        1,
      );
    });

    test('deleteSubject preserves tasks and clears references', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Doomed subject',
      );
      final task = await TaskController.instance.createTask(
        title: 'Orphaned task',
        subjectId: subject.id,
      );

      await SubjectController.instance.deleteSubject(subject.id);

      final remaining = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .toList();
      expect(remaining.length, 1);
      expect(remaining.single.subjectId, isNull);

      await TaskController.instance.deleteTask(task.id);
    });
  });
}

Future<void> _clean() async {
  for (final task in List.of(TaskController.instance.tasks)) {
    await TaskController.instance.deleteTask(task.id);
  }
  for (final subject in List.of(SubjectController.instance.subjects)) {
    await SubjectController.instance.deleteSubject(subject.id);
  }
}
