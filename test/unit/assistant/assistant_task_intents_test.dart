import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P2 — task command intents: parse slots, preview through confirmation,
/// clarify on ambiguity, never guess.
void main() {
  const parser = DeterministicStudentIntentParser();
  const engine = StudentAssistantEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    AuthIsolation.instance.clearSession();
  });

  Future<StudentTask> seed(
    String title, {
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) {
    return TaskController.instance.createTask(
      title: title,
      priority: priority,
      dueDate: dueDate,
    );
  }

  group('create task parsing', () {
    test('"Create a task to finish Accounts Chapter 3 tomorrow"', () async {
      await seed('Physics homework');
      final tasks = TaskController.instance.tasks;
      final intent = parser.parse(
        'Create a task to finish Accounts Chapter 3 tomorrow',
        tasks: tasks,
      );
      expect(intent.intentType, AssistantIntentType.createTask);
      expect(intent.taskName, contains('Accounts Chapter 3'));
      expect(intent.targetDate, isNotNull);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      expect(intent.targetDate, todayDate.add(const Duration(days: 1)));
    });

    test('priority phrase extracted', () {
      final intent = parser.parse(
        'Create a high priority task to revise physics',
      );
      expect(intent.intentType, AssistantIntentType.createTask);
      expect(intent.taskPriority, 'high');
    });

    test('create preview carries confirmable fields', () async {
      await seed('Physics homework');
      final result = engine.process(
        'Create a task to finish Accounts Chapter 3 tomorrow',
      );
      expect(result.requiresConfirmation, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.createTask);
      expect(result.primaryAction?.taskTitle, contains('Accounts'));
    });

    test('missing title asks a concise clarification', () {
      final result = engine.process(
        'Create a task',
        explicitIntent: const StudentAssistantIntent(
          rawText: 'Create a task',
          intentType: AssistantIntentType.createTask,
        ),
      );
      expect(result.clarificationRequired, isTrue);
      expect(result.requiresConfirmation, isFalse);
    });
  });

  group('prioritize task', () {
    test('"Make Accounts high priority" resolves the task', () async {
      await seed('Accounts Chapter 3');
      await seed('Economics reading');
      final result = engine.process('Make Accounts high priority');
      expect(result.requiresConfirmation, isTrue);
      expect(
        result.primaryAction?.type,
        AssistantActionType.prioritizeTask,
      );
      expect(result.primaryAction?.taskPriority, 'high');
      expect(
        result.primaryAction?.taskTitle,
        contains('Accounts'),
      );
    });

    test('two matches clarify instead of guessing', () async {
      await seed('Accounts Chapter 3');
      await seed('Accounts Chapter 4');
      final result = engine.process('Make Accounts high priority');
      expect(result.clarificationRequired, isTrue);
      expect(result.clarificationChoices.length, 2);
      expect(result.requiresConfirmation, isFalse);
    });
  });

  group('reschedule task', () {
    test('"Move my Economics task to Saturday" sets the date', () async {
      await seed('Economics assignment');
      final tasks = TaskController.instance.tasks;
      final intent = parser.parse(
        'Move my Economics task to Saturday',
        tasks: tasks,
      );
      expect(intent.intentType, AssistantIntentType.rescheduleTask);
      expect(intent.taskName, contains('Economics'));
      expect(intent.targetDate, isNotNull);
      expect(intent.targetDate!.weekday, DateTime.saturday);
    });

    test('reschedule preview names the day', () async {
      await seed('Economics assignment');
      final result = engine.process('Move my Economics task to Saturday');
      expect(result.requiresConfirmation, isTrue);
      expect(
        result.primaryAction?.type,
        AssistantActionType.rescheduleTask,
      );
      expect(
        result.primaryAction?.targetDate?.weekday,
        DateTime.saturday,
      );
    });
  });

  group('break task', () {
    test('"Break X into 3 tasks" proposes parts', () async {
      await seed('Write essay');
      final result = engine.process('Break Write essay into 3 tasks');
      expect(result.requiresConfirmation, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.breakTask);
      expect(result.primaryAction?.subtaskCount, 3);
      expect(result.steps.length, 3);
    });
  });

  group('complete by title', () {
    test('"Complete Physics homework" stages confirmation', () async {
      await seed('Physics homework');
      final result = engine.process('Complete Physics homework');
      expect(result.requiresConfirmation, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.completeTask);
    });
  });

  group('fix my day + catch up routing', () {
    test('"Fix my day" proposes or reports fit', () {
      final result = engine.process('Fix my day');
      expect(result.success, isTrue);
    });

    test('"I\'m behind" opens the catch-up proposal', () {
      final intent = parser.parse("I'm behind");
      expect(intent.intentType, AssistantIntentType.catchUp);
    });
  });

  group('exam + revision routing', () {
    test('"Plan my exam" routes to examPlan', () {
      final intent = parser.parse('Plan my exam');
      expect(intent.intentType, AssistantIntentType.examPlan);
    });

    test('"Give me a revision plan" routes to revisionPlan', () {
      final intent = parser.parse('Give me a revision plan');
      expect(intent.intentType, AssistantIntentType.revisionPlan);
    });
  });
}
