import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P3 — automation safety: levels map correctly, confirmations gate L3,
/// double-confirm never duplicates, cancel is clean.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final b in List.of(PlanningBlockController.instance.blocks)) {
      await PlanningBlockController.instance.unscheduleBlock(b.id);
    }
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final b in List.of(PlanningBlockController.instance.blocks)) {
      await PlanningBlockController.instance.unscheduleBlock(b.id);
    }
    await StudentAssistantController.instance.clearConversation();
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
  });

  group('automation levels', () {
    test('read → L1, navigation → L2, mutating → L3', () {
      expect(
        AssistantActionType.openTasks.actionClass.automationLevel,
        AssistantAutomationLevel.information,
      );
      expect(
        AssistantActionType.openTasks.actionClass.automationLevel,
        AssistantAutomationLevel.information,
      );
      expect(
        AssistantActionType.startFocus.actionClass.automationLevel,
        AssistantAutomationLevel.preparation,
      );
      expect(
        AssistantActionType.applyPlan.actionClass.automationLevel,
        AssistantAutomationLevel.consequential,
      );
      expect(
        AssistantActionType.createTask.actionClass.automationLevel,
        AssistantAutomationLevel.consequential,
      );
      expect(
        AssistantActionType.updateSleepSchedule.actionClass.automationLevel,
        AssistantAutomationLevel.consequential,
      );
      expect(
        AssistantActionType.completeTask.actionClass.automationLevel,
        AssistantAutomationLevel.consequential,
      );
    });

    test('every action type has a level (exhaustive)', () {
      for (final type in AssistantActionType.values) {
        expect(
          type.actionClass.automationLevel,
          isNotNull,
          reason: type.name,
        );
      }
    });
  });

  group('confirmation gate', () {
    testWidgets('double confirm applies exactly once', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('p3_safe_user');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('host'))),
      );
      final context = tester.element(find.text('host'));
      final controller = StudentAssistantController.instance;
      await TaskController.instance.createTask(title: 'Solo task');

      await controller.ask('I have 2 hours');
      expect(controller.hasPendingProposal, isTrue);
      final blocksAfterFirst = PlanningBlockController.instance.blocks.length;

      await controller.confirmAction(context);
      final afterFirst = PlanningBlockController.instance.blocks.length;
      expect(afterFirst, greaterThan(blocksAfterFirst));

      // Second confirm is a silent no-op: nothing pending, nothing added.
      await controller.confirmAction(context);
      expect(
        PlanningBlockController.instance.blocks.length,
        afterFirst,
      );
    });

    testWidgets('cancel leaves zero trace', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('p3_safe_user');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('host'))),
      );
      final controller = StudentAssistantController.instance;
      await TaskController.instance.createTask(title: 'Solo task');
      final blocksBefore =
          PlanningBlockController.instance.blocks.length;

      await controller.ask('I have 2 hours');
      controller.cancelConfirmation();

      expect(controller.hasPendingProposal, isFalse);
      expect(controller.isAwaitingConfirmation, isFalse);
      expect(
        PlanningBlockController.instance.blocks.length,
        blocksBefore,
      );
    });
  });
}
