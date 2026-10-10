import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 5 — TaskFilter subject/exam scope + applyFilter consistency.
///
/// Search, filters, and workspace scope must behave identically across every
/// task view base (Today/Overdue/Upcoming/Inbox/Completed), not just "All".
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TaskController.instance.clearFilters();
    await _clean();
  });

  tearDown(() async {
    TaskController.instance.clearFilters();
    await _clean();
  });

  group('TaskFilter scope fields', () {
    test('empty by default, scoped when subject/exam set', () {
      expect(const TaskFilter().isEmpty, isTrue);
      expect(const TaskFilter().isScoped, isFalse);
      expect(const TaskFilter(subjectId: 's1').isEmpty, isFalse);
      expect(const TaskFilter(subjectId: 's1').isScoped, isTrue);
      expect(const TaskFilter(examId: 'e1').isScoped, isTrue);
    });

    test('copyWith clears scope ids', () {
      const scoped = TaskFilter(subjectId: 's1', examId: 'e1');
      expect(scoped.copyWith(clearSubjectId: true).subjectId, isNull);
      expect(scoped.copyWith(clearExamId: true).examId, isNull);
      expect(
        scoped.copyWith(clearSubjectId: true, clearExamId: true).isEmpty,
        isTrue,
      );
    });
  });

  group('applyFilter with subject/exam scope', () {
    test('subject scope returns only that subject tasks', () async {
      final sub = await SubjectController.instance.createSubject(
        name: 'FilterSub',
      );
      final inTask = await TaskController.instance.createTask(
        title: 'In scope task',
        subjectId: sub.id,
      );
      await TaskController.instance.createTask(title: 'Out of scope task');

      TaskController.instance.setFilter(TaskFilter(subjectId: sub.id));
      final result = TaskController.instance.filteredTasks;

      expect(result.map((t) => t.id), contains(inTask.id));
      expect(result.length, 1);

      await TaskController.instance.deleteTask(inTask.id);
      await SubjectController.instance.deleteSubject(sub.id);
    });

    test('exam scope returns only that exam tasks', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Filter exam',
      );
      final inTask = await TaskController.instance.createTask(
        title: 'Exam scoped task',
        examId: exam.id,
      );
      await TaskController.instance.createTask(title: 'Unscoped task');

      TaskController.instance.setFilter(TaskFilter(examId: exam.id));
      final result = TaskController.instance.filteredTasks;

      expect(result.map((t) => t.id), contains(inTask.id));
      expect(result.length, 1);

      await TaskController.instance.deleteTask(inTask.id);
      await ExamController.instance.deleteExam(exam.id);
    });
  });

  group('applyFilter consistency across view bases', () {
    test('search applies to today base, not just All', () async {
      await TaskController.instance.createTask(
        title: 'Algebra homework',
        dueDate: DateTime.now(),
      );
      await TaskController.instance.createTask(
        title: 'Biology reading',
        dueDate: DateTime.now(),
      );

      TaskController.instance.search('algebra');
      final tc = TaskController.instance;
      final today = tc.applyFilter(tc.todayTasks);

      expect(today.length, 1);
      expect(today.single.title, 'Algebra homework');
    });

    test('search applies to completed base', () async {
      final task = await TaskController.instance.createTask(
        title: 'Finished essay',
      );
      await TaskController.instance.completeTask(task.id);

      TaskController.instance.search('essay');
      final tc = TaskController.instance;
      final done = tc.applyFilter(tc.completedTasks);

      expect(done.length, 1);

      TaskController.instance.search('missing');
      expect(tc.applyFilter(tc.completedTasks), isEmpty);
    });

    test('priority filter applies to overdue base', () async {
      await TaskController.instance.createTask(
        title: 'Critical overdue',
        priority: TaskPriority.critical,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await TaskController.instance.createTask(
        title: 'Low overdue',
        priority: TaskPriority.low,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      TaskController.instance.setFilter(
        const TaskFilter(priorities: [TaskPriority.critical]),
      );
      final tc = TaskController.instance;
      final overdue = tc.applyFilter(tc.overdueTasks);

      expect(overdue.length, 1);
      expect(overdue.single.title, 'Critical overdue');
    });

    test('clearing filters restores full bases', () async {
      await TaskController.instance.createTask(title: 'Any task');
      TaskController.instance.search('zzz-no-match');
      expect(TaskController.instance.filteredTasks, isEmpty);

      TaskController.instance.clearFilters();
      expect(TaskController.instance.filteredTasks.length, 1);
    });
  });
}

Future<void> _clean() async {
  for (final task in List.of(TaskController.instance.tasks)) {
    await TaskController.instance.deleteTask(task.id);
  }
  for (final exam in List.of(ExamController.instance.exams)) {
    await ExamController.instance.deleteExam(exam.id);
  }
  for (final subject in List.of(SubjectController.instance.subjects)) {
    await SubjectController.instance.deleteSubject(subject.id);
  }
}
