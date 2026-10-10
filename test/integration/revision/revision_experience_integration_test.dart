import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/data/models/revision_record.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/knowledge/practice_question_controller.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/revision/revision_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_rev_experience_integ');
    AcademicKnowledgeController.instance.clearData();
    PracticeQuestionController.instance.clearData();
    TopicPracticeController.instance.clearData();
    RevisionController.instance.clearData();
    PlanningBlockController.instance.clearData();
    SubjectController.instance.clearData();
    StudyController.instance.clearData();
    ProgressionController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Revision Experience 2.0 Integration Tests', () {
    test('1. Full Study -> Practice -> Revision -> Spaced Schedule -> XP -> Planning loop', () async {
      final now = DateTime.now();

      final topic = Topic(
        id: 'top_loop_test',
        chapterId: 'ch_1',
        subjectId: 'sub_acc',
        title: 'Depreciation Reserve',
      );

      // 1. Initial Study Session
      await StudyController.instance.recordFocusCompletion(
        focusSessionId: 'sess_loop_1',
        topicId: topic.id,
        subjectId: topic.subjectId,
        subject: 'Accounting',
        startedAt: now.subtract(const Duration(days: 4)),
        completed: true,
        durationSec: 1800,
      );

      // 2. Practice attempt with low accuracy (40%) -> flags weak topic
      await TopicPracticeController.instance.recordAttempt(
        topicId: topic.id,
        subjectId: 'sub_acc',
        totalQuestions: 10,
        correctAnswers: 4,
        durationSec: 600,
        startedAt: now.subtract(const Duration(days: 1)),
      );

      // 3. Verify intelligence detects weak topic & generates reasons
      final progress = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: StudyController.instance.sessions,
        practiceAttempts: TopicPracticeController.instance.attempts,
        revisionRecords: RevisionController.instance.records,
        revisionSchedules: RevisionController.instance.schedules,
      );

      expect(progress.isWeakTopic, isTrue);
      expect(progress.isRevisionDue, isTrue);
      expect(progress.whyReviseReasons.isNotEmpty, isTrue);

      // 4. Complete Revision Session with "I Knew It" recall
      final revRecord = await RevisionController.instance.recordRevision(
        topicId: topic.id,
        subjectId: topic.subjectId,
        chapterId: topic.chapterId,
        durationSec: 1200,
        recallOutcome: RevisionRecallOutcome.knew,
        notes: 'Reinforced reserve accounts formula',
        source: 'recall_session',
      );

      expect(RevisionController.instance.records.length, 1);
      expect(RevisionController.instance.records.first.id, revRecord.id);

      // 5. Verify XP awarded idempotently
      final xpEvents = ProgressionController.instance.events;
      expect(xpEvents.any((e) => e.id == 'xp_revision_${revRecord.id}'), isTrue);

      // 6. Verify Spaced Schedule updated to 3 days
      final schedule = RevisionController.instance.scheduleForTopic(topic.id);
      expect(schedule, isNotNull);
      expect(schedule!.revisionCount, 1);
      expect(schedule.successfulRecallCount, 1);
      expect(schedule.intervalDays, 3);

      // 7. Schedule next revision into plan via PlanningBlockController
      final start = DateTime(now.year, now.month, now.day, 16, 0);
      final block = await PlanningBlockController.instance.scheduleTopicBlock(
        topic.id,
        start,
        start.add(const Duration(minutes: 20)),
        subjectId: topic.subjectId,
        customTitle: 'Revise — ${topic.title}',
      );

      expect(block.topicId, topic.id);
      expect(PlanningBlockController.instance.blocks.length, 1);
    });

    test('2. User isolation: User A revision data is completely separate from User B', () async {
      final rc = RevisionController.instance;

      // User A records revision
      AuthIsolation.instance.setAuthenticatedUser('user_A_rev_iso');
      await rc.recordRevision(
        topicId: 'top_iso_rev',
        notes: 'User A exclusive',
      );
      expect(rc.records.length, 1);

      // User B logs in
      AuthIsolation.instance.setAuthenticatedUser('user_B_rev_iso');
      ControllerIsolation.instance.clearAllControllers();
      await rc.load();

      expect(rc.records, isEmpty);
      expect(rc.schedules, isEmpty);

      // User B creates revision
      await rc.recordRevision(
        topicId: 'top_user_b_rev',
        notes: 'User B exclusive',
      );
      expect(rc.records.length, 1);

      // User A logs back in
      AuthIsolation.instance.setAuthenticatedUser('user_A_rev_iso');
      ControllerIsolation.instance.clearAllControllers();
      await rc.load();

      expect(rc.records.length, 1);
      expect(rc.records.first.notes, 'User A exclusive');
    });
  });
}
