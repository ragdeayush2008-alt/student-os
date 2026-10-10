import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Full exam workflow through existing systems:
/// CREATE EXAM → DATE → PREP PLAN → TASKS → PLANNING → FOCUS → ASSISTANT,
/// then user isolation A/B.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final b in List.of(PlanningBlockController.instance.blocks)) {
      await PlanningBlockController.instance.unscheduleBlock(b.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
    await StudentAssistantController.instance.clearConversation();
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  Future<void> login(String user) async {
    AuthIsolation.instance.setAuthenticatedUser(user);
    ControllerIsolation.instance.reloadAllControllers(user);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  Future<void> logout() async {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  }

  test('exam → prep tasks → planning blocks → focus → assistant', () async {
    await login('exam_flow_a');
    final controller = StudentAssistantController.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // CREATE EXAM with a date 12 days out.
    final exam = await ExamController.instance.createExam(
      title: 'Accounts Final',
      subject: 'Accounts',
      examDateTime: today.add(const Duration(days: 12)),
    );
    expect(exam.daysUntilExam, 12);
    expect(exam.preparationWindowDays, 13);

    // PREPARATION PLAN through the Assistant creates real tasks.
    final plan = await controller.ask('Plan my Accounts exam');
    expect(plan.requiresConfirmation, isTrue);
    expect(controller.hasPendingProposal, isTrue);

    // TASKS: apply creates exam-linked tasks via TaskController.
    await controller.confirmAction(_FakeContext());
    final prepTasks = TaskController.instance.tasks
        .where((t) => t.title.contains('Accounts Final'))
        .toList();
    expect(prepTasks, isNotEmpty);

    // PLANNING: apply a day plan containing a prep task.
    await controller.ask('I have 2 hours');
    if (controller.hasPendingProposal) {
      await controller.confirmAction(_FakeContext());
    }
    expect(
      PlanningBlockController.instance.blocks,
      isNotEmpty,
    );

    // FOCUS: an exam prep task starts through the existing engine.
    final focusTask = prepTasks.first;
    FocusController.instance.startTimer(
      duration: const Duration(minutes: 25),
      taskId: focusTask.id,
      objective: focusTask.title,
    );
    expect(FocusController.instance.hasActiveSession, isTrue);
    expect(
      FocusController.instance.activeSession?.taskId,
      focusTask.id,
    );
    FocusController.instance.stopSession();

    // ASSISTANT understands the exam with real countdown math.
    final answer = await controller.ask(
      'How many days until my Accounts exam?',
    );
    expect(answer.success, isTrue);
    final answerText =
        '${answer.title} ${answer.message} ${answer.previewItems.join(' ')}';
    expect(answerText, contains('12'));
  });

  test('exam data is user-isolated end to end', () async {
    await login('exam_flow_a');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await ExamController.instance.createExam(
      title: 'Accounts Final',
      subject: 'Accounts',
      examDateTime: today.add(const Duration(days: 12)),
    );
    await StudentAssistantController.instance.ask(
      'Plan my Accounts exam',
    );

    await logout();
    await login('exam_flow_b');
    expect(ExamController.instance.exams, isEmpty);
    final answer = await StudentAssistantController.instance.ask(
      'Plan my exam',
    );
    // No leakage: honest empty, no Accounts data.
    expect(answer.message.contains('Accounts'), isFalse);

    await logout();
    await login('exam_flow_a');
    expect(
      ExamController.instance.exams.map((e) => e.title),
      contains('Accounts Final'),
    );
  });
}

class _FakeContext extends Fake implements BuildContext {
  @override
  bool get mounted => true;
}
