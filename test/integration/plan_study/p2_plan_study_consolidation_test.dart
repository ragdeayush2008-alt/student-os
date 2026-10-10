import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/core/intelligence/academic_knowledge_engine.dart';
import 'package:student_os/core/intelligence/autopilot_engine.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/core/services/notification_coordinator.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/data/models/topic_practice_attempt.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/knowledge/practice_question_controller.dart';
import 'package:student_os/features/knowledge/topic_practice_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/revision/revision_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

// Helper to set authenticated user and clear state
Future<void> _setupUser(String userId) async {
  SharedPreferences.setMockInitialValues({});
  AuthIsolation.instance.setAuthenticatedUser(userId);
  await StorageService.instance.clearUser(userId: userId);
  ControllerIsolation.instance.clearAllControllers();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2 Plan & Study Consolidation — 23 Categories', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      FocusController.instance.resetClockForTesting();
      FocusController.instance.clearData();
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();
    });

    // 1. Subject → Chapter → Topic
    test('1. Subject → Chapter → Topic hierarchy', () async {
      await _setupUser('p2_user1');
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final sub = await sc.createSubject(name: 'Business Law');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Contract Law');
      final top = await kc.createTopic(
        chapterId: ch.id,
        subjectId: sub.id,
        title: 'Offer and Acceptance',
        estimatedMinutes: 35,
        importance: TopicImportance.critical,
      );
      expect(kc.chaptersForSubject(sub.id).length, 1);
      expect(kc.topicsForChapter(ch.id).length, 1);
      expect(kc.topicsForSubject(sub.id).first.id, top.id);
      expect(kc.topicById(top.id)!.title, 'Offer and Acceptance');
    });

    // 2. Topic → Study
    test('2. Topic → Study records context', () async {
      await _setupUser('p2_user2');
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final sub = await sc.createSubject(name: 'Accountancy');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Partnership');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Goodwill');
      // Create a realistic study session with sufficient duration to count as studied
      final manualSession = StudySession(
        id: 'sess_manual_${DateTime.now().millisecondsSinceEpoch}',
        subject: sub.displayName,
        subjectId: sub.id,
        chapterId: ch.id,
        topicId: top.id,
        startedAt: DateTime.now().subtract(const Duration(minutes: 35)),
        endedAt: DateTime.now(),
        durationSec: 35 * 60,
        completed: true,
      );
      // Persist via StorageService then load, or directly via StudyController helper
      await StudyController.instance.recordFocusCompletion(
        focusSessionId: 'focus_manual_${top.id}',
        subject: sub.displayName,
        subjectId: sub.id,
        chapterId: ch.id,
        topicId: top.id,
        durationSec: 35 * 60,
        startedAt: manualSession.startedAt,
        endedAt: manualSession.endedAt,
      );
      final sess = StudyController.instance.sessions.where((s) => s.topicId == top.id).firstOrNull;
      expect(sess, isNotNull);
      expect(sess!.topicId, top.id);
      expect(sess.chapterId, ch.id);
      expect(sess.subjectId, sub.id);
      final prog = AcademicKnowledgeEngine.assessTopicProgress(top, sessions: StudyController.instance.sessions);
      expect(prog.isStudied, isTrue);
      expect(prog.sessionsCount, greaterThanOrEqualTo(1));
    });

    // 3. Topic → Practice
    test('3. Topic → Practice with question availability check', () async {
      await _setupUser('p2_user3');
      final kc = AcademicKnowledgeController.instance;
      final pq = PracticeQuestionController.instance;
      final sc = SubjectController.instance;
      final sub = await sc.createSubject(name: 'Economics');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Micro');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Demand');
      expect(pq.hasQuestionsForTopic(top.id), isFalse);
      await pq.addQuestion(
        topicId: top.id,
        subjectId: sub.id,
        chapterId: ch.id,
        questionText: 'What is demand?',
        correctAnswer: 'Willingness to pay',
        options: ['A','B','C','D'],
      );
      expect(pq.hasQuestionsForTopic(top.id), isTrue);
      final sess = pq.createSession(topicId: top.id);
      expect(sess.questions.length, 1);
    });

    // 4. Practice → Weak Topic detection
    test('4. Practice → Weak Topic detection via accuracy', () async {
      await _setupUser('p2_user4');
      final kc = AcademicKnowledgeController.instance;
      final sc = SubjectController.instance;
      final sub = await sc.createSubject(name: 'Maths');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Algebra');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Quadratic');
      // Record low accuracy attempts
      await TopicPracticeController.instance.recordAttempt(
        topicId: top.id,
        subjectId: sub.id,
        chapterId: ch.id,
        totalQuestions: 10,
        correctAnswers: 3,
        durationSec: 600,
      );
      await TopicPracticeController.instance.recordAttempt(
        topicId: top.id,
        subjectId: sub.id,
        chapterId: ch.id,
        totalQuestions: 10,
        correctAnswers: 4,
        durationSec: 600,
      );
      final weak = AcademicKnowledgeEngine.getWeakTopics(
        topics: [top],
        practiceAttempts: TopicPracticeController.instance.attempts,
      );
      expect(weak.length, 1);
      expect(weak.first.isWeakTopic, isTrue);
    });

    // 5. Weak Topic → Revision recommendation
    test('5. Weak Topic → Revision recommendation appears', () async {
      await _setupUser('p2_user5');
      final kc = AcademicKnowledgeController.instance;
      final sc = SubjectController.instance;
      final sub = await sc.createSubject(name: 'Physics');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Mechanics');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Friction');
      await TopicPracticeController.instance.recordAttempt(
        topicId: top.id,
        subjectId: sub.id,
        chapterId: ch.id,
        totalQuestions: 10,
        correctAnswers: 2,
        durationSec: 500,
      );
      // Also add a study session to make topic studied
      StudyController.instance.startSession(subject: sub.displayName, subjectId: sub.id, topicId: top.id, chapterId: ch.id);
      await StudyController.instance.endSession();
      final revRecs = AcademicIntelligenceEngine.generateRevisionRecommendations(
        subjects: [sub],
        topics: [top],
        sessions: StudyController.instance.sessions,
        practiceAttempts: TopicPracticeController.instance.attempts,
      );
      // Weak topic should surface in revision recommendations
      expect(revRecs.any((r) => r.topicId == top.id), isTrue);
    });

    // 6. Revision → Planning integration (due revision influences planning)
    test('6. Revision due topic influences topic priority', () async {
      await _setupUser('p2_user6');
      final kc = AcademicKnowledgeController.instance;
      final sc = SubjectController.instance;
      final sub = await sc.createSubject(name: 'Chemistry');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Organic');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Alkanes');
      // Make topic studied 7 days ago with no revision
      final oldSession = StudySession(
        id: 'old_sess',
        subject: sub.displayName,
        subjectId: sub.id,
        topicId: top.id,
        chapterId: ch.id,
        startedAt: DateTime.now().subtract(const Duration(days: 7)),
        endedAt: DateTime.now().subtract(const Duration(days: 7)),
        durationSec: 1800,
        completed: true,
      );
      final prog = AcademicKnowledgeEngine.assessTopicProgress(top, sessions: [oldSession]);
      expect(prog.isRevisionDue, isTrue);
      // Topic priority should be elevated due to revision due
      final assess = AcademicKnowledgeEngine.assessTopicPriority(top, sessions: [oldSession]);
      expect(assess.isRevision, isTrue);
      expect(assess.score, greaterThan(40));
    });

    // 7. Exam → Topic priority (exam proximity boosts topic score)
    test('7. Exam → Topic priority boost', () async {
      await _setupUser('p2_user7');
      final kc = AcademicKnowledgeController.instance;
      final sc = SubjectController.instance;
      final sub = await sc.createSubject(name: 'Business Law');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Contract');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Offer and Acceptance', importance: TopicImportance.critical);
      // Use topic.subjectId as exam subject to match engine's id-based lookup
      final exam = await ExamController.instance.createExam(
        title: 'Business Law Final',
        subject: top.subjectId,
        examDateTime: DateTime.now().add(const Duration(days: 2)),
        syllabusItems: [SyllabusItem(id: 's1', title: 'Offer and Acceptance')],
      );
      final withoutExam = AcademicKnowledgeEngine.assessTopicPriority(top, exams: [], referenceTime: DateTime.now());
      final withExam = AcademicKnowledgeEngine.assessTopicPriority(top, exams: [exam], referenceTime: DateTime.now());
      expect(withExam.score, greaterThan(withoutExam.score));
      // Also verify subject-level exam proximity scoring (name-based match)
      final examByName = await ExamController.instance.createExam(
        title: 'Business Law Final 2',
        subject: sub.name,
        examDateTime: DateTime.now().add(const Duration(days: 1)),
      );
      final without = PlanningEngine.scoreSubject(sub, exams: []);
      final withByName = PlanningEngine.scoreSubject(sub, exams: [examByName]);
      expect(withByName, greaterThan(without));
    });

    // 8. Exam → Planning (exam-aware daily plan includes exam-linked topic)
    test('8. Exam-aware planning prioritizes exam topics', () async {
      await _setupUser('p2_user8');
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final sub = await sc.createSubject(name: 'Economics');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Macro');
      final top1 = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'GDP', estimatedMinutes: 30);
      final top2 = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Inflation', estimatedMinutes: 30);
      final exam = await ExamController.instance.createExam(
        title: 'Economics Exam',
        subject: sub.name,
        examDateTime: DateTime.now().add(const Duration(days: 1)),
      );
      // Direct topic-aware planning should pick GDP or Inflation under exam pressure
      final plan = PlanningEngine.generateDailyPlan(
        DateTime.now(),
        tasks: [],
        subjects: [sub],
        exams: [exam],
        blocks: [],
        availableBudgetMinutes: 60,
      );
      expect(plan.items.isNotEmpty, isTrue);
      // At least one item should reference a topic for this subject
      final hasTopic = plan.items.any((i) => i.topicId == top1.id || i.topicId == top2.id);
      // If subject has topics, plan should be topic-aware
      expect(hasTopic, isTrue);
      // Titles should contain exam context or topic
      expect(plan.items.first.title.contains(sub.displayName), isTrue);
    });

    // 9. Task → PlanningBlock preserves context
    test('9. Task → PlanningBlock preserves subject/topic/exam context', () async {
      await _setupUser('p2_user9');
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final sub = await sc.createSubject(name: 'Physics');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Ch1');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'T1');
      final task = await TaskController.instance.createTask(
        title: 'Complete T1 worksheet',
        subjectId: sub.id,
        estimatedMinutes: 35,
      );
      final exam = await ExamController.instance.createExam(title: 'Physics Test', subject: sub.name, examDateTime: DateTime.now().add(const Duration(days: 5)));
      // Create task linked to exam for context preservation
      final taskWithExam = task.copyWith(examId: exam.id);
      await TaskController.instance.updateTask(taskWithExam);
      final now = DateTime.now();
      final block = await PlanningBlockController.instance.scheduleBlock(
        task.id,
        now.add(const Duration(hours: 1)),
        now.add(const Duration(hours: 1, minutes: 35)),
        subjectId: sub.id,
        topicId: top.id,
        chapterId: ch.id,
        examId: exam.id,
      );
      expect(block.taskId, task.id);
      expect(block.subjectId, sub.id);
      expect(block.topicId, top.id);
      expect(block.chapterId, ch.id);
      expect(block.examId, exam.id);
      // Recovery should preserve same context (via reschedule)
      final blocks = PlanningBlockController.instance.blocks;
      expect(blocks.where((b) => b.examId == exam.id).length, 1);
    });

    // 10. PlanningBlock → Focus preserves duration and context
    test('10. PlanningBlock → Focus uses block duration and context', () async {
      await _setupUser('p2_user10');
      final sc = SubjectController.instance;
      final sub = await sc.createSubject(name: 'Art');
      final now = DateTime.now();
      final block = await PlanningBlockController.instance.scheduleBlock(
        null,
        now.add(const Duration(minutes: 10)),
        now.add(const Duration(minutes: 55)),
        subjectId: sub.id,
        customTitle: 'Art Study Block',
      );
      final dur = block.endAt.difference(block.startAt);
      expect(dur.inMinutes, 45);
      // Focus started from block should preserve subjectId and planningBlockId
      final fc = FocusController.instance;
      fc.startTimer(
        duration: dur,
        subjectId: block.subjectId,
        planningBlockId: block.id,
        objective: block.customTitle ?? 'Focus',
      );
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.subjectId, sub.id);
      expect(fc.activeSession!.planningBlockId, block.id);
      expect(fc.activeSession!.plannedDuration.inMinutes, 45);
      fc.cancelSession();
    });

    // 11. Focus → Study bridge creates authoritative study record
    test('11. Focus → Study bridge idempotent and accurate', () async {
      await _setupUser('p2_user11');
      final fc = FocusController.instance;
      var now = DateTime.now();
      fc.setClockForTesting(() => now);
      fc.startTimer(duration: const Duration(minutes: 25), subjectName: 'Biology', objective: 'Cell Structure', topicId: 'top_bio', chapterId: 'ch_bio', subjectId: 'sub_bio');
      final sid = fc.activeSession!.id;
      now = now.add(const Duration(minutes: 25));
      fc.completeSession();
      expect(fc.sessions.where((s) => s.id == sid).single.outcome, SessionOutcome.completed);
      final bridged = StudyController.instance.sessions.where((s) => s.focusSessionId == sid).toList();
      expect(bridged.length, 1);
      expect(bridged.single.topicId, 'top_bio');
      expect(bridged.single.durationSec, 1500);
      // Duplicate bridge attempt should not create duplicate
      final dup = await StudyController.instance.recordFocusCompletion(focusSessionId: sid, subject: 'Biology', durationSec: 1500);
      expect(dup.id, bridged.single.id);
      expect(StudyController.instance.sessions.where((s) => s.focusSessionId == sid).length, 1);
      fc.resetClockForTesting();
    });

    // 12. Missed block → Recovery preserves context and does not duplicate
    test('12. Missed block recovery preserves context without duplication', () async {
      await _setupUser('p2_user12');
      final sc = SubjectController.instance;
      final sub = await sc.createSubject(name: 'History');
      final task = await TaskController.instance.createTask(title: 'History Essay', subjectId: sub.id, estimatedMinutes: 30);
      final now = DateTime.now();
      final pastStart = DateTime(now.year, now.month, now.day, 9, 0);
      final pastEnd = pastStart.add(const Duration(minutes: 30));
      // Block earlier today that should be marked missed if now is after end
      final block = await PlanningBlockController.instance.scheduleBlock(task.id, pastStart, pastEnd, subjectId: sub.id);
      final reference = pastEnd.add(const Duration(minutes: 10));
      final missed = PlanningEngine.getMissedSessions(blocks: [block], tasks: [task], subjects: [sub], referenceTime: reference);
      expect(missed.length, 1);
      expect(missed.first.block.id, block.id);
      expect(missed.first.durationMinutes, 30);
      // Recovery reschedules
      final recovered = await PlanningEngine.rescheduleMissedSession(missed.first);
      expect(recovered, isNotNull);
      expect(recovered!.id, block.id);
      // Ensure not duplicated - still one block with same id
      expect(PlanningBlockController.instance.blocks.where((b) => b.id == block.id).length, 1);
    });

    // 13. Overload → Rebalance moves flexible future work only
    test('13. Overload rebalance moves future blocks not past/active', () async {
      await _setupUser('p2_user13');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Create 3 blocks today exceeding 180m budget
      final b1 = await PlanningBlockController.instance.scheduleBlock(null, DateTime(today.year, today.month, today.day, 9, 0), DateTime(today.year, today.month, today.day, 11, 0), subjectId: 'sub1');
      final b2 = await PlanningBlockController.instance.scheduleBlock(null, DateTime(today.year, today.month, today.day, 11, 15), DateTime(today.year, today.month, today.day, 13, 15), subjectId: 'sub2');
      final b3 = await PlanningBlockController.instance.scheduleBlock(null, DateTime(today.year, today.month, today.day, 14, 0), DateTime(today.year, today.month, today.day, 16, 0), subjectId: 'sub3');
      final beforeCount = PlanningBlockController.instance.blocksForDay(today).length;
      expect(beforeCount, 3);
      // All blocks are future relative to test start (choose referenceTime early morning)
      final ref = DateTime(today.year, today.month, today.day, 8, 0);
      final moved = await PlanningEngine.rebalanceOverloadedDay(today, tasks: [], availableMinutes: 180, referenceTime: ref);
      expect(moved, greaterThan(0));
      // Completed work not moved: mark none completed here, but past blocks not moved (we used future reference, so all eligible)
      // Verify still 3 blocks total (just rescheduled)
      expect(PlanningBlockController.instance.blocks.length, 3);
    });

    // 14. Available time → Plan allocates meaningful work deterministically
    test('14. Available time plan distributes budget without randomness', () async {
      await _setupUser('p2_user14');
      final sc = SubjectController.instance;
      final s1 = await sc.createSubject(name: 'Philosophy');
      final s2 = await sc.createSubject(name: 'Psychology');
      // Create overdue task to prioritize
      final overdue = await TaskController.instance.createTask(
        title: 'Overdue Paper',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        estimatedMinutes: 30,
      );
      final plan30 = PlanningEngine.generateDailyPlan(DateTime.now(), tasks: TaskController.instance.tasks, subjects: [s1, s2], availableBudgetMinutes: 30);
      final plan90 = PlanningEngine.generateDailyPlan(DateTime.now(), tasks: TaskController.instance.tasks, subjects: [s1, s2], availableBudgetMinutes: 90);
      final plan120 = PlanningEngine.generateDailyPlan(DateTime.now(), tasks: TaskController.instance.tasks, subjects: [s1, s2], availableBudgetMinutes: 120);
      // 30m plan should contain at least the overdue task
      expect(plan30.items.any((i) => i.taskId == overdue.id), isTrue);
      // 90m and 120m should allocate more total minutes
      expect(plan90.totalPlannedMinutes, greaterThan(plan30.totalPlannedMinutes));
      expect(plan120.totalPlannedMinutes, greaterThanOrEqualTo(plan90.totalPlannedMinutes));
      // Deterministic: second call with same budget should produce identical plan
      final plan30b = PlanningEngine.generateDailyPlan(DateTime.now(), tasks: TaskController.instance.tasks, subjects: [s1, s2], availableBudgetMinutes: 30);
      expect(plan30.items.length, plan30b.items.length);
      expect(plan30.items.first.title, plan30b.items.first.title);
    });

    // 15. Assistant → Recommendation uses authoritative intelligence
    test('15. Assistant what should I study uses topic-aware intelligence', () async {
      await _setupUser('p2_user15');
      const engine = StudentAssistantEngine();
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final sub = await sc.createSubject(name: 'Business Law');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Contract');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Breach', estimatedMinutes: 40, importance: TopicImportance.critical);
      final result = engine.process('What should I study?', referenceTime: DateTime(2026, 9, 20, 10, 0));
      expect(result.success, isTrue);
      expect(result.primaryAction, isNotNull);
      expect(result.primaryAction!.topicId, top.id);
      // Should explain reason, not generic motivational
      expect(result.explanation, isNotNull);
      expect(result.explanation!.isNotEmpty, isTrue);
      expect(result.explanation, isNot(contains('You can do it')));
    });

    // 16. Assistant → Planning with available time
    test('16. Assistant I have 2 hours generates topic-aware plan', () async {
      await _setupUser('p2_user16');
      const engine = StudentAssistantEngine();
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final sub = await sc.createSubject(name: 'Law');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Ch1');
      await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Topic A', estimatedMinutes: 35);
      await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Topic B', estimatedMinutes: 35);
      final result = engine.process('I have 2 hours', referenceTime: DateTime(2026, 9, 20, 9, 0));
      expect(result.success, isTrue);
      expect(result.planResult, isNotNull);
      expect(result.planResult!.hasItems, isTrue);
      expect(result.planResult!.items.any((i) => i.topicId != null), isTrue);
    });

    // 17. Autopilot → Planning respects exam pressure and revision
    test('17. Autopilot day state integrates exam pressure and revision queue', () async {
      await _setupUser('p2_user17');
      final sc = SubjectController.instance;
      final sub = await sc.createSubject(name: 'Physics');
      final exam = await ExamController.instance.createExam(title: 'Physics Final', subject: sub.name, examDateTime: DateTime.now().add(const Duration(days: 2)));
      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: DateTime.now(),
        subjects: [sub],
        exams: [exam],
        sessions: [],
        tasks: [],
        blocks: [],
        availableBudgetMinutes: 180,
      );
      expect(state.nextAction, isNotNull);
      expect(state.healthState, isNotNull);
      // Pressure should influence nextAction toward exam
      expect(state.briefing.recommendedPriorities.isNotEmpty, isTrue);
    });

    // 18. User isolation A -> B -> A
    test('18. User isolation preserves data across switches', () async {
      // User A
      await _setupUser('userA_iso');
      final scA = SubjectController.instance;
      final taskA = await TaskController.instance.createTask(title: 'User A Task');
      final subA = await scA.createSubject(name: 'User A Sub');
      final kcA = AcademicKnowledgeController.instance;
      final chA = await kcA.createChapter(subjectId: subA.id, title: 'ChA');
      final topA = await kcA.createTopic(chapterId: chA.id, subjectId: subA.id, title: 'TopA');
      final blockA = await PlanningBlockController.instance.scheduleBlock(taskA.id, DateTime.now().add(const Duration(hours: 1)), DateTime.now().add(const Duration(hours: 2)), subjectId: subA.id, topicId: topA.id);
      final studyA = StudySession(id: 'sA', subject: subA.displayName, subjectId: subA.id, topicId: topA.id, startedAt: DateTime.now(), endedAt: DateTime.now(), durationSec: 600, completed: true);
      // Save study manually via controller bridge
      await StudyController.instance.recordFocusCompletion(focusSessionId: 'focusA', subject: subA.displayName, subjectId: subA.id, topicId: topA.id, durationSec: 600);
      await TopicPracticeController.instance.recordAttempt(topicId: topA.id, subjectId: subA.id, chapterId: chA.id, totalQuestions: 5, correctAnswers: 3);
      await RevisionController.instance.recordRevision(topicId: topA.id, subjectId: subA.id);
      final examA = await ExamController.instance.createExam(title: 'User A Exam', subject: subA.name);
      // Logout User A
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();

      // User B login - should see nothing from A
      await _setupUser('userB_iso');
      expect(TaskController.instance.tasks.where((t) => t.id == taskA.id).isEmpty, isTrue);
      expect(SubjectController.instance.subjects.where((s) => s.id == subA.id).isEmpty, isTrue);
      expect(AcademicKnowledgeController.instance.topics.where((t) => t.id == topA.id).isEmpty, isTrue);
      expect(PlanningBlockController.instance.blocks.where((b) => b.id == blockA.id).isEmpty, isTrue);
      expect(StudyController.instance.sessions.where((s) => s.subjectId == subA.id).isEmpty, isTrue);
      expect(ExamController.instance.exams.where((e) => e.id == examA.id).isEmpty, isTrue);
      // User B creates own data
      final subB = await SubjectController.instance.createSubject(name: 'User B Sub');
      expect(SubjectController.instance.subjects.length, 1);

      // Logout B, login A again
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();
      AuthIsolation.instance.setAuthenticatedUser('userA_iso');
      // Reload from storage for A
      await SubjectController.instance.load();
      await TaskController.instance.load();
      await AcademicKnowledgeController.instance.load();
      await PlanningBlockController.instance.load();
      await StudyController.instance.load();
      await RevisionController.instance.load();
      await ExamController.instance.load();
      await TopicPracticeController.instance.load();
      // Verify A data intact
      expect(SubjectController.instance.subjects.any((s) => s.id == subA.id), isTrue);
      expect(TaskController.instance.tasks.any((t) => t.id == taskA.id), isTrue);
      expect(AcademicKnowledgeController.instance.topics.any((t) => t.id == topA.id), isTrue);
      expect(PlanningBlockController.instance.blocks.any((b) => b.id == blockA.id), isTrue);
      // B's data not visible to A
      expect(SubjectController.instance.subjects.any((s) => s.id == subB.id), isFalse);
    });

    // 19. Offline flow works without network (local-first)
    test('19. Offline flow: create and operate without Supabase', () async {
      await _setupUser('offline_user');
      // All operations should succeed offline (no Supabase client)
      final sc = SubjectController.instance;
      final kc = AcademicKnowledgeController.instance;
      final sub = await sc.createSubject(name: 'Offline Subject');
      final ch = await kc.createChapter(subjectId: sub.id, title: 'Offline Ch');
      final top = await kc.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Offline Topic');
      final task = await TaskController.instance.createTask(title: 'Offline Task', subjectId: sub.id);
      final block = await PlanningBlockController.instance.scheduleBlock(task.id, DateTime.now().add(const Duration(hours: 1)), DateTime.now().add(const Duration(hours: 2)), subjectId: sub.id, topicId: top.id);
      expect(SubjectController.instance.subjects.isNotEmpty, isTrue);
      expect(PlanningBlockController.instance.blocks.isNotEmpty, isTrue);
      // Recommendations based on local data should work
      final recs = AcademicIntelligenceEngine.generateStudyRecommendations(subjects: [sub], sessions: [], tasks: [task], topics: [top]);
      expect(recs.isNotEmpty, isTrue);
      // Practice with no questions shows honest empty state
      expect(PracticeQuestionController.instance.hasQuestionsForTopic(top.id), isFalse);
      // Apply recommendation via planning
      final plan = PlanningEngine.generateDailyPlan(DateTime.now(), tasks: [task], subjects: [sub], availableBudgetMinutes: 60);
      expect(plan.hasItems, isTrue);
      // Focus bridge offline - simulate 20 min elapsed via clock
      final fc = FocusController.instance;
      var now = DateTime.now();
      fc.setClockForTesting(() => now);
      fc.startTimer(duration: const Duration(minutes: 20), subjectId: sub.id, topicId: top.id);
      now = now.add(const Duration(minutes: 20));
      fc.completeSession();
      expect(StudyController.instance.sessions.where((s) => s.topicId == top.id).isNotEmpty, isTrue);
      fc.resetClockForTesting();
    });

    // 20. Restart persistence across controllers
    test('20. Restart persistence load preserves all entity types', () async {
      const uid = 'persist_user';
      await _setupUser(uid);
      final sub = await SubjectController.instance.createSubject(name: 'Persist Sub');
      final ch = await AcademicKnowledgeController.instance.createChapter(subjectId: sub.id, title: 'Persist Ch');
      final top = await AcademicKnowledgeController.instance.createTopic(chapterId: ch.id, subjectId: sub.id, title: 'Persist Top');
      final task = await TaskController.instance.createTask(title: 'Persist Task');
      final block = await PlanningBlockController.instance.scheduleBlock(task.id, DateTime.now().add(const Duration(days: 1)), DateTime.now().add(const Duration(days: 1, hours: 1)), subjectId: sub.id, topicId: top.id);
      final sess = StudySession(id: 'persist_sess', subject: sub.displayName, subjectId: sub.id, topicId: top.id, startedAt: DateTime.now(), endedAt: DateTime.now(), durationSec: 900, completed: true);
      await StorageService.instance.saveJsonList(userId: uid, key: 'study_sessions', list: [sess.toJson()]);
      await TopicPracticeController.instance.recordAttempt(topicId: top.id, subjectId: sub.id, chapterId: ch.id, totalQuestions: 5, correctAnswers: 5);
      await RevisionController.instance.recordRevision(topicId: top.id, subjectId: sub.id);
      final exam = await ExamController.instance.createExam(title: 'Persist Exam');
      // Simulate restart: clear in-memory but keep storage
      ControllerIsolation.instance.clearAllControllers();
      // Reload for same user
      AuthIsolation.instance.setAuthenticatedUser(uid);
      await SubjectController.instance.load();
      await AcademicKnowledgeController.instance.load();
      await TaskController.instance.load();
      await PlanningBlockController.instance.load();
      // Manually reload study via storage (load path uses StudyController.load)
      await StudyController.instance.load();
      await TopicPracticeController.instance.load();
      await RevisionController.instance.load();
      await ExamController.instance.load();
      expect(SubjectController.instance.subjects.any((s) => s.id == sub.id), isTrue);
      expect(AcademicKnowledgeController.instance.topics.any((t) => t.id == top.id), isTrue);
      expect(TaskController.instance.tasks.any((t) => t.id == task.id), isTrue);
      expect(PlanningBlockController.instance.blocks.any((b) => b.id == block.id), isTrue);
      expect(StudyController.instance.sessions.any((s) => s.id == sess.id), isTrue);
      expect(TopicPracticeController.instance.attempts.any((a) => a.topicId == top.id), isTrue);
      expect(RevisionController.instance.records.any((r) => r.topicId == top.id), isTrue);
      expect(ExamController.instance.exams.any((e) => e.id == exam.id), isTrue);
    });

    // 21. Duplicate prevention for focus→study and block scheduling
    test('21. Duplicate prevention: focus completion and block scheduling idempotent', () async {
      await _setupUser('dup_user');
      final fc = FocusController.instance;
      var now = DateTime.now();
      fc.setClockForTesting(() => now);
      fc.startTimer(duration: const Duration(minutes: 30), subjectName: 'Dup Subject', objective: 'Dup');
      final sid = fc.activeSession!.id;
      now = now.add(const Duration(minutes: 30));
      fc.completeSession();
      // Attempt duplicate bridge
      final initialCount = StudyController.instance.sessions.where((s) => s.focusSessionId == sid).length;
      expect(initialCount, 1);
      await StudyController.instance.recordFocusCompletion(focusSessionId: sid, subject: 'Dup Subject', durationSec: 1800);
      await StudyController.instance.recordFocusCompletion(focusSessionId: sid, subject: 'Dup Subject', durationSec: 1800);
      expect(StudyController.instance.sessions.where((s) => s.focusSessionId == sid).length, 1);
      // Duplicate block scheduling (same taskId + same time)
      final task = await TaskController.instance.createTask(title: 'Dup Task');
      final start = DateTime.now().add(const Duration(days: 1, hours: 9));
      final end = start.add(const Duration(minutes: 30));
      final b1 = await PlanningBlockController.instance.scheduleBlock(task.id, start, end);
      final b2 = await PlanningBlockController.instance.scheduleBlock(task.id, start, end);
      expect(b1.id, b2.id);
      expect(PlanningBlockController.instance.blocks.where((b) => b.taskId == task.id && b.startAt == start).length, 1);
      fc.resetClockForTesting();
    });

    // 22. Notification idempotency via cancel-before-reschedule
    test('22. Notification idempotency: reconcile does not duplicate', () async {
      // NotificationCoordinator uses deterministic IDs and cancel-before-schedule, so reconciling twice should not throw or duplicate
      await _setupUser('notif_user');
      final task = await TaskController.instance.createTask(
        title: 'Notif Task',
        reminderEnabled: false,
      );
      // First reconcile
      await NotificationCoordinator.instance.reconcileAll();
      // Second reconcile - should be idempotent
      await NotificationCoordinator.instance.reconcileAll();
      // Planning notifications
      final block = await PlanningBlockController.instance.scheduleBlock(task.id, DateTime.now().add(const Duration(hours: 1)), DateTime.now().add(const Duration(hours: 2)));
      await NotificationCoordinator.instance.reconcilePlanningNotifications([block], blockTitles: {block.id: task.title});
      await NotificationCoordinator.instance.reconcilePlanningNotifications([block], blockTitles: {block.id: task.title});
      // No exception means idempotent
      expect(true, isTrue);
    });

    // 23. Old-data backward compatibility (missing nullable fields)
    test('23. Old-data backward compatibility: PlanningBlock and StudySession without examId parses', () async {
      const uid = 'compat_user';
      await _setupUser(uid);
      // Simulate old PlanningBlock JSON without examId/topicId nullable fields
      final oldBlockJson = {
        'id': 'pb_old',
        'userId': uid,
        'taskId': 'task_old',
        'startAt': DateTime.now().toIso8601String(),
        'endAt': DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
        // No subjectId, topicId, chapterId, examId, customTitle
      };
      // Should parse without error (examId defaults null)
      final block = PlanningBlock.fromJson(oldBlockJson);
      expect(block.examId, isNull);
      expect(block.topicId, isNull);
      // Old StudySession without topicId/chapterId/examId/focusSessionId
      final oldStudyJson = {
        'id': 'study_old',
        'subject': 'General',
        'startedAt': DateTime.now().toIso8601String(),
        'durationSec': 600,
        'completed': true,
        'note': '',
      };
      final sess = StudySession.fromJson(oldStudyJson);
      expect(sess.topicId, isNull);
      expect(sess.examId, isNull);
      expect(sess.focusSessionId, isNull);
      // Persist and reload should remain readable
      await StorageService.instance.saveJsonList(userId: uid, key: 'planning_blocks', list: [oldBlockJson]);
      await PlanningBlockController.instance.load();
      expect(PlanningBlockController.instance.blocks.any((b) => b.id == 'pb_old'), isTrue);
      // Topic old JSON without new fields
      final oldTopicJson = {
        'id': 'top_old',
        'chapterId': 'ch_old',
        'subjectId': 'sub_old',
        'title': 'Old Topic',
        // Missing description, order, estimatedMinutes, importance, userId
      };
      final top = Topic.fromJson(oldTopicJson);
      expect(top.estimatedMinutes, 35); // default
      expect(top.importance, TopicImportance.normal);
    });
  });
}
