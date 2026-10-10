import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 5 — Exams workspace controller semantics.
///
/// Covers exam CRUD + status lifecycle, subject-name lookup, linked-task
/// derivation, deterministic readiness, and safe deletion.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _clean();
  });

  tearDown(() async {
    await _clean();
  });

  group('Exam CRUD + lifecycle', () {
    test('create stores title, subject, and date', () async {
      final date = DateTime.now().add(const Duration(days: 5));
      final exam = await ExamController.instance.createExam(
        title: 'Finals',
        subject: 'Math',
        examDateTime: date,
      );
      addTearDown(() => ExamController.instance.deleteExam(exam.id));

      expect(exam.title, 'Finals');
      expect(exam.subject, 'Math');
      expect(exam.examDateTime, date);
      expect(exam.isUpcoming, isTrue);
    });

    test('complete → reopen lifecycle', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Lifecycle exam',
        examDateTime: DateTime.now().add(const Duration(days: 4)),
      );
      addTearDown(() => ExamController.instance.deleteExam(exam.id));

      await ExamController.instance.completeExam(exam.id);
      expect(
        ExamController.instance.completedExams.any((e) => e.id == exam.id),
        isTrue,
      );

      await ExamController.instance.reopenExam(exam.id);
      expect(
        ExamController.instance.upcomingExams.any((e) => e.id == exam.id),
        isTrue,
      );
    });

    test('cancel → reopen lifecycle', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Cancel exam',
      );
      addTearDown(() => ExamController.instance.deleteExam(exam.id));

      await ExamController.instance.cancelExam(exam.id);
      expect(
        ExamController.instance.cancelledExams.any((e) => e.id == exam.id),
        isTrue,
      );

      await ExamController.instance.reopenExam(exam.id);
      expect(
        ExamController.instance.upcomingExams.any((e) => e.id == exam.id),
        isTrue,
      );
    });
  });

  group('Exam ↔ Subject lookup', () {
    test('examsForSubjectName matches case-insensitively', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Chemistry',
      );
      addTearDown(() => SubjectController.instance.deleteSubject(subject.id));
      final exam = await ExamController.instance.createExam(
        title: 'Chem midterm',
        subject: 'chemistry',
        examDateTime: DateTime.now().add(const Duration(days: 6)),
      );
      addTearDown(() => ExamController.instance.deleteExam(exam.id));

      final found = ExamController.instance.examsForSubjectName('Chemistry');
      expect(found.map((e) => e.id), contains(exam.id));
    });

    test('examsForSubjectName empty for blank or missing', () {
      expect(ExamController.instance.examsForSubjectName(''), isEmpty);
      expect(
        ExamController.instance.examsForSubjectName('No such subject'),
        isEmpty,
      );
    });
  });

  group('Exam ↔ Task linkage', () {
    test('linked task completion derives correctly', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Linked exam',
      );
      addTearDown(() => ExamController.instance.deleteExam(exam.id));
      final t1 = await TaskController.instance.createTask(
        title: 'Prep 1',
        examId: exam.id,
      );
      final t2 = await TaskController.instance.createTask(
        title: 'Prep 2',
        examId: exam.id,
      );
      addTearDown(() => TaskController.instance.deleteTask(t1.id));
      addTearDown(() => TaskController.instance.deleteTask(t2.id));

      expect(ExamController.instance.hasLinkedTasks(exam), isTrue);
      expect(ExamController.instance.linkedTaskCompletion(exam), 0);

      await TaskController.instance.completeTask(t1.id);
      expect(ExamController.instance.linkedTaskCompletion(exam), 0.5);
    });

    test('readiness is deterministic for same state', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Deterministic exam',
        examDateTime: DateTime.now().add(const Duration(days: 6)),
      );
      addTearDown(() => ExamController.instance.deleteExam(exam.id));

      final first = ExamController.instance.readiness(exam);
      final second = ExamController.instance.readiness(exam);
      expect(first.label, second.label);
      expect(first.reasons, second.reasons);
    });

    test('deleteExam preserves tasks and clears references', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Doomed exam 2',
      );
      final task = await TaskController.instance.createTask(
        title: 'Linked task',
        examId: exam.id,
      );

      await ExamController.instance.deleteExam(exam.id);

      final remaining = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .toList();
      expect(remaining.length, 1);
      expect(remaining.single.examId, isNull);

      await TaskController.instance.deleteTask(task.id);
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
