import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_context.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_result.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  const engine = StudentAssistantEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() async {
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Assistant 4.0 engine — context-aware responses', () {
    test('every result carries a cardKind and context line when snapshot given',
        () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final subject = await sc.createSubject(name: 'Accountancy');
      final chapter =
          await kc.createChapter(subjectId: subject.id, title: 'Partnership');
      await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 35,
      );

      final snapshot = AssistantContextSnapshot.capture(referenceTime: now);
      final result = engine.process(
        'What should I do?',
        referenceTime: now,
        context: snapshot,
      );

      expect(result.cardKind, isNot(AssistantCardKind.neutral));
      expect(result.contextLine, isNotNull);
      expect(result.contextLine, isNotEmpty);
    });

    test('available-time plan exposes structured steps', () async {
      final now = DateTime(2026, 9, 12, 9, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final subject = await sc.createSubject(name: 'Accountancy');
      final chapter =
          await kc.createChapter(subjectId: subject.id, title: 'Partnership');
      await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Partnership Accounts',
        estimatedMinutes: 45,
      );

      final result = engine.process('I have 2 hours', referenceTime: now);

      expect(result.cardKind, AssistantCardKind.todayPlan);
      expect(result.steps, isNotEmpty);
      expect(result.steps.first.label, isNotEmpty);
      expect(result.steps.first.minutes, greaterThan(0));
    });

    test("today's plan exposes one step per block", () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final pbc = PlanningBlockController.instance;
      await pbc.scheduleBlock(
        null,
        DateTime(2026, 9, 12, 11, 0),
        DateTime(2026, 9, 12, 12, 0),
        customTitle: 'Morning Review',
      );
      await pbc.scheduleBlock(
        null,
        DateTime(2026, 9, 12, 13, 0),
        DateTime(2026, 9, 12, 13, 45),
        customTitle: 'Practice Set',
      );

      final result = engine.process("Show today's plan.", referenceTime: now);

      expect(result.cardKind, AssistantCardKind.todayPlan);
      expect(result.steps.length, 2);
      expect(result.steps.first.label, isNotEmpty);
    });

    test('completed query reports success card when work exists today',
        () async {
      final now = DateTime.now();
      final tc = TaskController.instance;
      final task = await tc.createTask(
        title: 'Revise Chapter 3',
        dueDate: now,
      );
      await tc.completeTask(task.id);

      final result = engine.process(
        'What have I completed today?',
        referenceTime: now,
      );

      expect(result.cardKind, AssistantCardKind.success);
      expect(result.title, contains('Completed'));
    });

    test('completed query returns empty card when nothing done', () {
      final result = engine.process(
        'What have I completed today?',
        referenceTime: DateTime(2026, 9, 12, 15, 0),
      );
      expect(result.cardKind, AssistantCardKind.empty);
    });

    test('priorities query delegates to authoritative intelligence', () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      await SubjectController.instance.createSubject(name: 'Economics');

      final result = engine.process(
        'What should I prioritize?',
        referenceTime: now,
      );
      expect(result.success, isTrue);
      expect(result.primaryAction, isNotNull);
    });

    test('overdue tasks query sets overdue mode and structured list', () async {
      final now = DateTime(2026, 9, 12, 14, 0);
      final tc = TaskController.instance;
      await tc.createTask(
        title: 'Late Assignment',
        dueDate: DateTime(2026, 9, 10),
      );

      final result = engine.process(
        'What tasks are overdue?',
        referenceTime: now,
      );

      expect(result.title, contains('Overdue'));
      expect(result.previewItems.any((p) => p.contains('Late Assignment')),
          isTrue);
    });

    test('stop focus with no session returns empty card', () {
      final result = engine.process('Stop focus.');
      expect(result.cardKind, AssistantCardKind.empty);
      expect(result.title, contains('No Active Focus'));
    });

    test('stop focus resolves when a session is running', () {
      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'Economics',
        objective: 'Deep Work',
      );
      final result = engine.process('Stop focus.');
      expect(result.success, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.stopFocus);
    });
  });

  group('Assistant 4.0 engine — schedule topic', () {
    test('scheduleTopic with an unresolved topic asks to pick one', () async {
      final result = engine.process('Plan this topic.');
      expect(result.cardKind, AssistantCardKind.empty);
      expect(result.title, contains('Pick a Topic'));
    });

    test('scheduleTopic with a resolved topic previews a blocked write',
        () async {
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final subject = await sc.createSubject(name: 'Accountancy');
      final chapter =
          await kc.createChapter(subjectId: subject.id, title: 'Partnership');
      final topic = await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 40,
      );

      final result = engine.process(
        'Plan this topic.',
        explicitIntent: StudentAssistantIntent(
          rawText: 'Plan this topic.',
          intentType: AssistantIntentType.scheduleTopic,
          topicId: topic.id,
        ),
      );

      expect(result.cardKind, AssistantCardKind.schedulePreview);
      expect(result.requiresConfirmation, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.scheduleTopic);
      expect(result.primaryAction?.duration, const Duration(minutes: 40));
    });
  });

  group('Assistant 4.0 engine — recovery offers real multi-slots', () {
    test('missed block yields concrete recovery slot options', () async {
      final now = DateTime(2026, 9, 12, 18, 0);
      final sc = SubjectController.instance;
      final pbc = PlanningBlockController.instance;
      final subject = await sc.createSubject(name: 'Accountancy');

      final missed = await pbc.scheduleBlock(
        null,
        DateTime(2026, 9, 12, 15, 0),
        DateTime(2026, 9, 12, 16, 0),
        subjectId: subject.id,
        customTitle: 'Accountancy Study',
      );

      final result = engine.process(
        'Give me a recovery plan.',
        blocks: [missed],
        referenceTime: now,
      );

      expect(result.success, isTrue);
      expect(result.cardKind, AssistantCardKind.schedulePreview);
      expect(result.steps, isNotEmpty);
      expect(result.requiresConfirmation, isTrue);
    });

    test('no missed blocks returns a clean empty state', () {
      final result = engine.process(
        'Give me a recovery plan.',
        blocks: const [],
        tasks: const [],
        referenceTime: DateTime(2026, 9, 12, 18, 0),
      );
      expect(result.cardKind, AssistantCardKind.empty);
      expect(result.title, contains('Recover'));
    });
  });

  group('Assistant 4.0 engine — no duplicate scoring engine', () {
    test('recommendation body matches authoritative intelligence exactly',
        () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final subject = await sc.createSubject(name: 'Accountancy');
      final chapter =
          await kc.createChapter(subjectId: subject.id, title: 'Partnership');
      final topic = await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 35,
        importance: TopicImportance.high,
      );

      final result = engine.process('What should I do?', referenceTime: now);
      expect(result.primaryAction?.topicId, topic.id);
    });
  });
}
