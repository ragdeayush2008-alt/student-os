import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/assistant_planning_engine.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P2 — proposal lifecycle: preview stages, refine edits in words,
/// Confirm executes through existing controllers, Cancel clears.
void main() {
  const engine = StudentAssistantEngine();

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

  AssistantDayPlan buildPlan() {
    return AssistantPlanningEngine.proposeDayPlan(
      now: DateTime.now(),
      budgetMinutes: 180,
      tasks: [
        StudentTask(
          id: 'a',
          title: 'Accounts Chapter 3',
          priority: TaskPriority.high,
          createdAt: DateTime(2026, 1, 1),
        ),
        StudentTask(
          id: 'b',
          title: 'Economics reading',
          createdAt: DateTime(2026, 1, 2),
        ),
        StudentTask(
          id: 'c',
          title: 'Law notes review',
          createdAt: DateTime(2026, 1, 3),
        ),
      ],
    );
  }

  group('refine (deterministic, engine level)', () {
    test('remove drops the item and keeps the rest', () {
      final plan = buildPlan();
      expect(plan.sessions.length, 3);

      final result = engine.process(
        'Remove Economics',
        explicitIntent: const StudentAssistantIntent(
          rawText: 'Remove Economics',
          intentType: AssistantIntentType.refinePlan,
          refineOp: 'remove',
          refineIndex: 1,
        ),
        proposal: plan,
      );
      expect(result.success, isTrue);
      expect(result.proposal!.sessions.length, 2);
      expect(
        result.proposal!.sessions
            .where((s) => s.title.contains('Economics')),
        isEmpty,
      );
    });

    test('move-first reorders sessions', () {
      final plan = buildPlan();
      final result = engine.process(
        'Make Economics first',
        explicitIntent: const StudentAssistantIntent(
          rawText: 'Make Economics first',
          intentType: AssistantIntentType.refinePlan,
          refineOp: 'moveFirst',
          refineIndex: 1,
        ),
        proposal: plan,
      );
      expect(
        result.proposal!.sessions.first.title,
        contains('Economics'),
      );
    });

    test('unknown index clarifies with real item titles', () {
      final plan = buildPlan();
      final result = engine.process(
        'Remove it',
        explicitIntent: const StudentAssistantIntent(
          rawText: 'Remove it',
          intentType: AssistantIntentType.refinePlan,
          refineOp: 'remove',
          refineIndex: -1,
        ),
        proposal: plan,
      );
      expect(result.clarificationRequired, isTrue);
      expect(result.clarificationChoices.length, 3);
    });

    test('no staged proposal explains honestly', () {
      final result = engine.process(
        'Remove Economics',
        explicitIntent: const StudentAssistantIntent(
          rawText: 'Remove Economics',
          intentType: AssistantIntentType.refinePlan,
          refineOp: 'remove',
          refineIndex: 0,
        ),
      );
      expect(result.title, 'No Active Proposal');
    });
  });

  group('controller lifecycle', () {
    testWidgets('plan → apply executes blocks + reports', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('p2_proposal_user');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('host'))),
      );
      final context = tester.element(find.text('host'));
      final controller = StudentAssistantController.instance;
      await TaskController.instance.createTask(
        title: 'Accounts Chapter 3',
        priority: TaskPriority.high,
        dueDate: DateTime.now(),
        estimatedMinutes: 25,
      );

      final proposal = await controller.ask('I have 2 hours');
      expect(proposal.requiresConfirmation, isTrue);
      expect(controller.hasPendingProposal, isTrue);
      expect(controller.isAwaitingConfirmation, isTrue);

      final blocksBefore =
          PlanningBlockController.instance.blocks.length;
      await controller.confirmAction(context);
      expect(controller.hasPendingProposal, isFalse);
      expect(
        PlanningBlockController.instance.blocks.length,
        greaterThan(blocksBefore),
      );
      expect(controller.lastResult?.title, 'Done');
    });

    testWidgets('cancel clears the staged proposal', (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('p2_proposal_user');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('host'))),
      );
      final controller = StudentAssistantController.instance;
      await TaskController.instance.createTask(title: 'Solo task');

      await controller.ask('I have 2 hours');
      expect(controller.hasPendingProposal, isTrue);

      controller.cancelConfirmation();
      expect(controller.hasPendingProposal, isFalse);
      expect(controller.isAwaitingConfirmation, isFalse);
    });

    testWidgets('unmatched remove clarifies, then exact title applies',
        (tester) async {
      AuthIsolation.instance.setAuthenticatedUser('p2_proposal_user');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('host'))),
      );
      final controller = StudentAssistantController.instance;
      await TaskController.instance.createTask(
        title: 'Accounts Chapter 3',
        estimatedMinutes: 25,
      );

      await controller.ask('I have 2 hours');
      expect(controller.hasPendingProposal, isTrue);

      final clarification = await controller.ask('Remove Economics');
      expect(clarification.clarificationRequired, isTrue);
      // The staged proposal survives the clarification round.
      expect(controller.hasPendingProposal, isTrue);

      final refined = await controller.ask('Accounts Chapter 3');
      expect(refined.success, isTrue);
      expect(refined.title, 'Updated Plan');
      // The last item was removed: nothing left to apply.
      expect(controller.hasPendingProposal, isFalse);
    });
  });
}
