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

void main() {
  const engine = StudentAssistantEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() async {
    ControllerIsolation.instance.clearAllControllers();
  });

  group('StudentAssistantEngine — What Should I Do & Study', () {
    test('recommends top topic when real topics exist', () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;

      final subject = await sc.createSubject(name: 'Accountancy');
      final chapter = await kc.createChapter(
        subjectId: subject.id,
        title: 'Partnership',
      );
      final topic = await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Admission of a Partner',
        estimatedMinutes: 35,
        importance: TopicImportance.high,
      );

      final result = engine.process('What should I study?', referenceTime: now);

      expect(result.success, isTrue);
      expect(result.title, contains('Admission of a Partner'));
      expect(result.primaryAction, isNotNull);
      expect(result.primaryAction?.topicId, topic.id);
      expect(result.primaryAction?.duration, const Duration(minutes: 35));
    });

    test('recommends revision when topic is due for spaced review', () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;

      final subject = await sc.createSubject(name: 'Business Law');
      final chapter = await kc.createChapter(
        subjectId: subject.id,
        title: 'Contract Act',
      );
      final topic = await kc.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Offer and Acceptance',
      );

      // Session from 6 days ago
      final oldSession = StudySession(
        id: 's_old',
        subject: 'Business Law',
        subjectId: subject.id,
        topicId: topic.id,
        chapterId: chapter.id,
        durationSec: 2100,
        startedAt: now.subtract(const Duration(days: 6)),
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
      expect(result.title, contains('Offer and Acceptance'));
      expect(result.primaryAction?.type, AssistantActionType.startRevision);
      expect(result.primaryAction?.topicId, topic.id);
    });
  });

  group('StudentAssistantEngine — Available Time & Planning', () {
    test('"I have 2 hours" generates structured plan preview', () async {
      final now = DateTime(2026, 9, 12, 9, 0);
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;

      final sub1 = await sc.createSubject(name: 'Accountancy');
      final ch1 = await kc.createChapter(subjectId: sub1.id, title: 'Partnership');
      await kc.createTopic(
        chapterId: ch1.id,
        subjectId: sub1.id,
        title: 'Partnership Accounts',
        estimatedMinutes: 45,
      );

      final result = engine.process('I have 2 hours', referenceTime: now);

      expect(result.success, isTrue);
      expect(result.title, contains('Plan for 120 Minutes'));
      expect(result.previewItems, isNotEmpty);
      expect(result.primaryAction?.type, AssistantActionType.applyPlan);
      expect(
        result.secondaryActions.any(
          (a) => a.type == AssistantActionType.startPlan,
        ),
        isTrue,
      );
    });
  });

  group('StudentAssistantEngine — Reschedule & Recovery Safety', () {
    test('reschedule requires confirmation before mutating', () async {
      final now = DateTime(2026, 9, 12, 14, 0);
      final pbc = PlanningBlockController.instance;

      final block = await pbc.scheduleBlock(
        null,
        now.add(const Duration(hours: 1)),
        now.add(const Duration(hours: 2)),
        subjectId: 'sub_law',
        customTitle: 'Business Law Review',
      );

      final result = engine.process('Move Business Law Review to tomorrow', referenceTime: now);

      expect(result.success, isTrue);
      expect(result.requiresConfirmation, isTrue);
      expect(result.primaryAction?.requiresConfirmation, isTrue);
      expect(result.primaryAction?.planningBlockId, block.id);
      expect(result.primaryAction?.type, AssistantActionType.reschedule);
    });

    test('active Focus timer protects session from being clobbered', () {
      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'Economics',
        objective: 'Microeconomics Deep Focus',
      );

      expect(fc.hasActiveSession, isTrue);

      final result = engine.process('Study Accountancy for 45 min');

      expect(result.title, contains('Focus in Progress'));
      expect(result.primaryAction?.label, contains('Return to Active Focus'));
    });
  });
}
