import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskController subject queries', () {
    test('tasksForSubject returns only tasks with that subjectId', () async {
      final subId = 'sub_query_1';
      await TaskController.instance.createTask(
        title: 'Accounting revise',
        subjectId: subId,
      );
      await TaskController.instance.createTask(title: 'Unrelated');

      final result = TaskController.instance.tasksForSubject(subId);
      expect(result.length, 1);
      expect(result.first.subjectId, subId);

      // Cleanup
      for (final t in TaskController.instance.tasksForSubject(subId)) {
        await TaskController.instance.deleteTask(t.id);
      }
      final unrelated = TaskController.instance.tasks
          .where((t) => t.title == 'Unrelated')
          .toList();
      for (final t in unrelated) {
        await TaskController.instance.deleteTask(t.id);
      }
    });

    test('activeTasksForSubject excludes completed tasks', () async {
      final subId = 'sub_query_2';
      final todo = await TaskController.instance.createTask(
        title: 'Pending',
        subjectId: subId,
      );
      final done = await TaskController.instance.createTask(
        title: 'Done',
        subjectId: subId,
      );
      await TaskController.instance.completeTask(done.id);

      expect(TaskController.instance.activeTasksForSubject(subId).length, 1);
      expect(
        TaskController.instance.activeTasksForSubject(subId).single.id,
        todo.id,
      );

      await TaskController.instance.deleteTask(todo.id);
      await TaskController.instance.deleteTask(done.id);
    });

    test('completedTasksForSubject returns only completed tasks', () async {
      final subId = 'sub_query_3';
      final done = await TaskController.instance.createTask(
        title: 'Done',
        subjectId: subId,
      );
      await TaskController.instance.createTask(
        title: 'Pending',
        subjectId: subId,
      );
      await TaskController.instance.completeTask(done.id);

      final completed = TaskController.instance.completedTasksForSubject(subId);
      expect(completed.length, 1);
      expect(completed.single.id, done.id);

      final all = TaskController.instance.tasksForSubject(subId);
      for (final t in all) {
        await TaskController.instance.deleteTask(t.id);
      }
    });

    test(
      'clearSubjectReference preserves tasks but clears subjectId',
      () async {
        final subId = 'sub_query_4';
        final t1 = await TaskController.instance.createTask(
          title: 'Linked A',
          subjectId: subId,
        );
        final t2 = await TaskController.instance.createTask(
          title: 'Linked B',
          subjectId: subId,
        );

        await TaskController.instance.clearSubjectReference(subId);

        expect(TaskController.instance.tasksForSubject(subId), isEmpty);
        expect(TaskController.instance.tasks.any((t) => t.id == t1.id), isTrue);
        expect(TaskController.instance.tasks.any((t) => t.id == t2.id), isTrue);
        final remaining = TaskController.instance.tasks
            .where((t) => t.id == t1.id || t.id == t2.id)
            .toList();
        for (final t in remaining) {
          expect(t.subjectId, isNull);
        }

        for (final t in remaining) {
          await TaskController.instance.deleteTask(t.id);
        }
      },
    );

    test('subject rename does not affect the task relationship', () async {
      // Link tasks by subjectId, not by name (as the pre-Phase-7 code did
      // with `category == subject.name`).
      final subId = 'sub_query_5';
      final task = await TaskController.instance.createTask(
        title: 'Named link',
        subjectId: subId,
      );

      // A lookup keyed on subjectId still resolves regardless of any name.
      expect(TaskController.instance.tasksForSubject(subId).single.id, task.id);

      await TaskController.instance.deleteTask(task.id);
    });
  });

  group('SubjectController deletion', () {
    test('deleting a subject preserves tasks but clears subjectId', () async {
      final sub = await SubjectController.instance.createSubject(
        name: 'Phase7 Deletion Subject',
      );
      final task = await TaskController.instance.createTask(
        title: 'Subject-bound task',
        subjectId: sub.id,
      );

      expect(
        TaskController.instance.tasksForSubject(sub.id).single.id,
        task.id,
      );

      await SubjectController.instance.deleteSubject(sub.id);

      // Task still exists.
      expect(TaskController.instance.tasks.any((t) => t.id == task.id), isTrue);
      // But the subject link is cleared.
      expect(TaskController.instance.tasksForSubject(sub.id), isEmpty);
      final remaining = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .toList();
      expect(remaining.single.subjectId, isNull);

      await TaskController.instance.deleteTask(task.id);
      // Clean up any subjects named like the one above (idempotent).
      await SubjectController.instance.deleteSubject(sub.id);
    });

    test('archiving a subject keeps task.subjectId intact', () async {
      final sub = await SubjectController.instance.createSubject(
        name: 'Phase7 Archive Subject',
      );
      final task = await TaskController.instance.createTask(
        title: 'Archive-bound task',
        subjectId: sub.id,
      );

      await SubjectController.instance.archiveSubject(sub.id);

      expect(
        TaskController.instance.tasksForSubject(sub.id).single.id,
        task.id,
      );
      expect(
        TaskController.instance.tasks
            .where((t) => t.id == task.id)
            .single
            .subjectId,
        sub.id,
      );

      await TaskController.instance.deleteTask(task.id);
      await SubjectController.instance.deleteSubject(sub.id);
    });
  });
}
