import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  final controller = StudentAssistantController.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ControllerIsolation.instance.clearAllControllers();
    controller.clearData();
  });

  tearDown(() async {
    ControllerIsolation.instance.clearAllControllers();
    controller.clearData();
  });

  group('Assistant 4.0 integration — conversation memory', () {
    test('remembers the previous card and resolves an ordinal follow-up',
        () async {
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final pbc = PlanningBlockController.instance;

      final subject = await sc.createSubject(name: 'Accountancy');
      final chapter =
          await kc.createChapter(subjectId: subject.id, title: 'Partnership');
      final first = await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 40,
      );
      await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Retirement of a Partner',
      );

      final today = DateTime.now();
      await pbc.scheduleBlock(
        null,
        DateTime(today.year, today.month, today.day, 23, 0),
        DateTime(today.year, today.month, today.day, 23, 45),
        subjectId: subject.id,
        topicId: first.id,
        chapterId: chapter.id,
        customTitle: 'Study Session',
      );

      final plan = await controller.ask("Show today's plan.");
      expect(plan.steps, isNotEmpty);
      expect(controller.conversation.lastSteps, isNotEmpty);

      final followUp = await controller.ask('the first one');
      expect(followUp.primaryAction?.type, AssistantActionType.scheduleTopic);
      expect(followUp.primaryAction?.topicId, first.id);
    });

    test('an ambiguous turn stores a pending intent for the next turn',
        () async {
      final sc = SubjectController.instance;
      await sc.createSubject(name: 'Business Law');
      await sc.createSubject(name: 'Corporate Laws');

      final first = await controller.ask('Study Law');
      expect(first.clarificationRequired, isTrue);
      expect(controller.conversation.pendingIntent, isNotNull);
    });

    test('clearData resets conversation memory for user isolation', () async {
      await controller.ask('What should I do?');
      expect(controller.conversation.isEmpty, isFalse);

      controller.clearData();
      expect(controller.conversation.isEmpty, isTrue);
      expect(controller.lastResult, isNull);
    });
  });

  group('Assistant 4.0 integration — mutation safety', () {
    test('mutating recovery requires confirmation and does not write on ask',
        () async {
      final sc = SubjectController.instance;
      final pbc = PlanningBlockController.instance;
      final subject = await sc.createSubject(name: 'Accountancy');

      final now = DateTime.now();
      await pbc.scheduleBlock(
        null,
        now.subtract(const Duration(hours: 2)),
        now.subtract(const Duration(hours: 1)),
        subjectId: subject.id,
        customTitle: 'Early Missed Block',
      );

      final before = pbc.blocks.length;
      final result = await controller.ask('Give me a recovery plan.');

      if (result.requiresConfirmation) {
        expect(controller.isAwaitingConfirmation, isTrue);
        expect(controller.pendingConfirmationAction, isNotNull);
      }
      // Asking must never silently mutate the plan.
      expect(pbc.blocks.length, before);

      controller.cancelConfirmation();
      expect(controller.isAwaitingConfirmation, isFalse);
      expect(pbc.blocks.length, before);
    });

    test('read-only queries never require confirmation', () async {
      await SubjectController.instance.createSubject(name: 'Accountancy');
      final result = await controller.ask('What should I do?');
      expect(result.requiresConfirmation, isFalse);
      expect(controller.isAwaitingConfirmation, isFalse);
    });
  });

  group('Assistant 4.0 integration — no duplicate records', () {
    test('repeated read queries do not create planning blocks', () async {
      final pbc = PlanningBlockController.instance;
      final before = pbc.blocks.length;

      await controller.ask("Show today's plan.");
      await controller.ask("Show today's plan.");
      await controller.ask('What should I do?');

      expect(pbc.blocks.length, before);
    });
  });
}
