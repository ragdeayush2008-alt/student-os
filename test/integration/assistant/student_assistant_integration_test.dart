import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
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

  group('Student Assistant Integration Flows', () {
    test('FLOW 1: "I have 2 hours" -> plan generated -> real topics -> Start Plan', () async {
      final now = DateTime(2026, 9, 12, 9, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;

      final sub = await sc.createSubject(name: 'Accountancy');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Partnership');
      final top = await kc.createTopic(
        chapterId: ch.id,
        subjectId: sub.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 45,
      );

      final result = engine.process('I have 2 hours', referenceTime: now);

      expect(result.success, isTrue);
      expect(result.planResult, isNotNull);
      // P2: Apply is the primary confirm-gated action; Start rides along.
      expect(result.primaryAction?.type, AssistantActionType.applyPlan);
      final start = result.secondaryActions
          .where((a) => a.type == AssistantActionType.startPlan)
          .firstOrNull;
      expect(start, isNotNull);
      expect(start?.topicId, top.id);
      expect(start?.duration, const Duration(minutes: 45));
    });

    test('FLOW 2: "What should I study?" -> real topic recommendation -> Focus action', () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;

      final sub = await sc.createSubject(name: 'Economics');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Microeconomics');
      final top = await kc.createTopic(
        chapterId: ch.id,
        subjectId: sub.id,
        title: 'Consumer Equilibrium',
        estimatedMinutes: 35,
        importance: TopicImportance.high,
      );

      final result = engine.process('What should I study?', referenceTime: now);

      expect(result.success, isTrue);
      expect(result.primaryAction?.topicId, top.id);
      expect(result.primaryAction?.topicTitle, 'Consumer Equilibrium');
      expect(result.primaryAction?.duration, const Duration(minutes: 35));
    });

    test('FLOW 3: "What should I revise?" -> real revision recommendation -> Focus action', () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;

      final sub = await sc.createSubject(name: 'Business Law');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Contract Act');
      final top = await kc.createTopic(
        chapterId: ch.id,
        subjectId: sub.id,
        title: 'Consideration',
        estimatedMinutes: 30,
      );

      final oldSession = StudySession(
        id: 's_prev',
        subject: 'Business Law',
        subjectId: sub.id,
        topicId: top.id,
        chapterId: ch.id,
        durationSec: 1800,
        startedAt: now.subtract(const Duration(days: 7)),
        completed: true,
      );
      await StorageService.instance.saveJsonList(
        userId: 'demo',
        key: 'study_sessions',
        list: [oldSession.toJson()],
      );
      await StudyController.instance.load();

      final result = engine.process(
        'What should I revise?',
        referenceTime: now,
        sessions: [oldSession],
      );

      expect(result.success, isTrue);
      expect(result.primaryAction?.type, AssistantActionType.startRevision);
      expect(result.primaryAction?.topicId, top.id);
      expect(result.primaryAction?.duration, const Duration(minutes: 20));
    });

    test('FLOW 4: "Continue my day" -> Autopilot state -> next valid action', () async {
      final now = DateTime(2026, 9, 12, 11, 0);
      final sc = SubjectController.instance;
      final tc = TaskController.instance;

      final sub = await sc.createSubject(name: 'Physics');
      final task = await tc.createTask(
        title: 'Physics Numericals Chapter 4',
        subjectId: sub.id,
        estimatedMinutes: 30,
      );

      final result = engine.process('Continue my day', referenceTime: now);

      expect(result.success, isTrue);
      expect(result.primaryAction, isNotNull);
      expect(result.primaryAction?.taskId, task.id);
    });

    test('FLOW 5: "Move Session to tomorrow" -> resolve entity -> confirmation required', () async {
      final now = DateTime(2026, 9, 12, 15, 0);
      final pbc = PlanningBlockController.instance;

      final block = await pbc.scheduleBlock(
        null,
        now.add(const Duration(hours: 1)),
        now.add(const Duration(hours: 2)),
        subjectId: 'sub_acc',
        customTitle: 'Partnership Accounts Review',
      );

      final result = engine.process('Move Partnership Accounts Review to tomorrow', referenceTime: now);

      expect(result.success, isTrue);
      expect(result.requiresConfirmation, isTrue);
      expect(result.primaryAction?.requiresConfirmation, isTrue);
      expect(result.primaryAction?.planningBlockId, block.id);
    });

    test('FLOW 6: Ambiguous command -> clarification requested -> no accidental mutation', () async {
      final sc = SubjectController.instance;
      await sc.createSubject(name: 'Financial Accounting');
      await sc.createSubject(name: 'Management Accounting');

      final result = engine.process('Study Accounting');

      expect(result.clarificationRequired, isTrue);
      expect(result.clarificationChoices.length, 2);
      expect(result.primaryAction, isNull);
    });

    test('FLOW 7: Active Focus running -> Assistant protects active session', () {
      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'Law',
        objective: 'Contract Act Section 10',
      );

      expect(fc.hasActiveSession, isTrue);

      final result = engine.process('What should I do?');

      expect(result.title, contains('Focus'));
      expect(result.primaryAction?.label, contains('Return to Focus'));
    });

    test('FLOW 8: User A query -> logout -> User B query -> Zero leakage', () async {
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;

      // User A creates subject and topic
      final subA = await sc.createSubject(name: 'User A Subject');
      final chA = await kc.createChapter(subjectId: subA.id, title: 'User A Chapter');
      await kc.createTopic(chapterId: chA.id, subjectId: subA.id, title: 'User A Topic');

      final resultA = engine.process('What should I study?');
      expect(resultA.title, contains('User A Topic'));

      // Logout User A
      ControllerIsolation.instance.clearAllControllers();

      // User B creates subject
      await sc.createSubject(name: 'User B Subject');

      final resultB = engine.process('What should I study?');
      expect(resultB.title, isNot(contains('User A Topic')));
      expect(resultB.title, contains('User B Subject'));
    });
  });
}
