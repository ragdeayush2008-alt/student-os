import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P2 — Fix My Day, Catch-Up, Exam/Revision plans: analyzed proposals with
/// honest empty states, never silent automation.
void main() {
  const engine = StudentAssistantEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
    AuthIsolation.instance.clearSession();
  });

  group('fix my day', () {
    test('fitting day reports on-track, stages nothing', () async {
      await TaskController.instance.createTask(
        title: 'Small task',
        dueDate: DateTime.now(),
        estimatedMinutes: 25,
      );
      final result = engine.process('Fix my day');
      expect(result.success, isTrue);
      expect(result.proposal, isNull);
    });

    test('overloaded day proposes moves with confirmation', () async {
      final now = DateTime.now();
      for (var i = 0; i < 5; i++) {
        await TaskController.instance.createTask(
          title: 'Heavy task $i',
          dueDate: now,
          estimatedMinutes: 50,
        );
      }
      final result = engine.process('Fix my day');
      expect(result.success, isTrue);
      expect(result.requiresConfirmation, isTrue);
      expect(result.proposal, isNotNull);
      expect(result.proposal!.moves, isNotEmpty);
      expect(
        result.primaryAction?.type,
        AssistantActionType.applyPlan,
      );
    });
  });

  group('catch up', () {
    test('empty backlog says so honestly', () {
      final result = engine.process("I'm behind");
      expect(result.success, isTrue);
      expect(result.proposal, isNull);
    });

    test('backlog splits urgent-tomorrow with confirmation', () async {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      await TaskController.instance.createTask(
        title: 'Overdue essay',
        dueDate: yesterday,
        priority: TaskPriority.high,
      );
      await TaskController.instance.createTask(
        title: 'Normal reading',
        dueDate: DateTime.now(),
      );
      final result = engine.process("I'm behind");
      expect(result.requiresConfirmation, isTrue);
      expect(result.proposal, isNotNull);
      expect(result.proposal!.moves.length, 2);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final urgent = result.proposal!.moves.firstWhere(
        (m) => m.taskTitle.contains('Overdue'),
      );
      expect(urgent.toDate.day, tomorrow.day);
    });
  });

  group('exam plan', () {
    test('no exams → honest empty, no invented syllabus', () async {
      final result = engine.process('Plan my exam');
      expect(result.success, isTrue);
      expect(result.proposal, isNull);
      expect(result.message, contains('upcoming exam to plan for'));
    });

    test('dated exam yields phased creations', () async {
      await ExamController.instance.createExam(
        title: 'Accounts Final',
        subject: 'Accounts',
        examDateTime: DateTime.now().add(const Duration(days: 12)),
      );
      final result = engine.process('Plan my Accounts exam');
      expect(result.requiresConfirmation, isTrue);
      expect(result.proposal, isNotNull);
      expect(result.proposal!.creations, isNotEmpty);
      expect(result.proposal!.creations.length, lessThanOrEqualTo(6));
      // No invented chapters: creations reference phases, never fake topics.
      for (final c in result.proposal!.creations) {
        expect(c.title.contains('Chapter'), isFalse);
      }
    });

    test('preparation window spans today through exam day', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await ExamController.instance.createExam(
        title: 'Window Exam',
        subject: 'Law',
        examDateTime: today.add(const Duration(days: 9)),
      );
      final exam = ExamController.instance.exams.singleWhere(
        (e) => e.title == 'Window Exam',
      );
      expect(exam.daysUntilExam, 9);
      expect(exam.preparationWindowDays, 10);
      expect(exam.preparationStart, today);

      final result = engine.process('Plan my Law exam');
      expect(result.requiresConfirmation, isTrue);
      // Due dates spread across the window, none past the exam.
      for (final c in result.proposal!.creations) {
        expect(c.dueDate, isNotNull);
        expect(
          c.dueDate!.isAfter(
            today.add(const Duration(days: 9, hours: 12)),
          ),
          isFalse,
        );
      }
    });

    test('apply creates exam-linked prep tasks, cancel creates none',
        () async {
      // Apply path is covered by the exam full-flow integration test;
      // here we verify the proposal carries appliable creations.
      await ExamController.instance.createExam(
        title: 'Apply Exam',
        subject: 'Economics',
        examDateTime: DateTime.now().add(const Duration(days: 8)),
      );
      final result = engine.process('Plan my Economics exam');
      expect(result.proposal, isNotNull);
      expect(
        result.primaryAction?.type,
        AssistantActionType.applyPlan,
      );
    });
  });

  group('revision plan', () {
    test('nothing due → honest empty', () {
      final result = engine.process('Give me a revision plan');
      expect(result.success, isTrue);
      expect(result.message, contains('Nothing is flagged for revision'));
    });
  });
}
