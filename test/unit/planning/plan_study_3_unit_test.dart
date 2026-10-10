import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/planning/plan_study_state.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 3 — Plan & Study 3.0 unit tests.
///
/// Covers the read-only presentation model and the new slot-lookup helpers.
/// Business rules are asserted to come from the existing engines, never from
/// a second implementation inside Plan & Study.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String userId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final realNow = AppClock.current;
    AppClock.freezeAt(DateTime(realNow.year, realNow.month, realNow.day, 7, 0));
    userId = 'plan_study_3_unit_${DateTime.now().microsecondsSinceEpoch}';
    AuthIsolation.instance.setAuthenticatedUser(userId);
    ControllerIsolation.instance.clearAllControllers();
    await SubjectController.instance.load();
    await TaskController.instance.load();
    await PlanningBlockController.instance.load();
    await StudyController.instance.load();
    await AcademicKnowledgeController.instance.load();
    await ExamController.instance.load();
  });

  tearDown(() {
    ControllerIsolation.instance.clearAllControllers();
    AppClock.reset();
  });

  /// Persists a genuine [StudySession] with real elapsed minutes, then reloads.
  /// A zero-length session is legitimately ignored by the knowledge engine, so
  /// study-history tests seed real evidence rather than faking progress.
  Future<void> seedStudySession({
    required String subject,
    required String subjectId,
    String? topicId,
    String? chapterId,
    int minutes = 35,
    int daysAgo = 0,
  }) async {
    final end = AppClock.current.subtract(Duration(days: daysAgo));
    final session = StudySession(
      id: 'seed_session_${DateTime.now().microsecondsSinceEpoch}',
      subject: subject,
      subjectId: subjectId,
      topicId: topicId,
      chapterId: chapterId,
      startedAt: end.subtract(Duration(minutes: minutes)),
      endedAt: end,
      durationSec: minutes * 60,
      completed: true,
    );
    await StorageService.instance.saveJsonList(
      userId: userId,
      key: 'study_sessions',
      list: [session.toJson()],
    );
    await StudyController.instance.load();
  }

  DateTime todayAt(int hour, [int minute = 0]) {
    final now = AppClock.current;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  group('§4/§5 — PlanDayView derivation', () {
    test('empty day reports no plan and no blocks', () {
      final view = PlanStudyState.planDay(AppClock.current);
      expect(view.hasPlan, isFalse);
      expect(view.blocks, isEmpty);
      expect(view.plannedMinutes, 0);
      expect(view.activeBlock, isNull);
      expect(view.hasMissed, isFalse);
      expect(view.allCompleted, isFalse);
      expect(view.progress, 0);
    });

    test('planned minutes and block count come from real blocks', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Accountancy');
      await PlanningBlockController.instance.scheduleBlock(
        null,
        todayAt(9),
        todayAt(9, 45),
        subjectId: subject.id,
        customTitle: 'Partnership Accounts',
      );
      await PlanningBlockController.instance.scheduleBlock(
        null,
        todayAt(11),
        todayAt(11, 30),
        subjectId: subject.id,
        customTitle: 'Contract Act',
      );

      final view = PlanStudyState.planDay(AppClock.current);
      expect(view.blocks.length, 2);
      expect(view.plannedMinutes, 75);
      expect(view.plannedMinutes, greaterThan(0));
    });

    test('resolves real subject / chapter / topic context onto a block', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Business Law');
      final chapter =
          await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Contract Act',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Offer & Acceptance',
      );

      await PlanningBlockController.instance.scheduleTopicBlock(
        topic.id,
        todayAt(9),
        todayAt(9, 45),
        subjectId: subject.id,
        chapterId: chapter.id,
      );

      final view = PlanStudyState.planDay(AppClock.current);
      final block = view.blocks.single;
      expect(block.subjectName, 'Business Law');
      expect(block.chapterTitle, 'Contract Act');
      expect(block.topicTitle, 'Offer & Acceptance');
      expect(block.hasAcademicContext, isTrue);
      expect(block.subjectId, subject.id);
      expect(block.topicId, topic.id);
    });

    test('day label is a real weekday + month name', () {
      final view = PlanStudyState.planDay(DateTime(2026, 9, 29));
      expect(view.dayLabel, 'Tuesday, September 29');
    });
  });

  group('§6 — Active block detection', () {
    test('a block whose window contains now is the active block', () async {
      final now = AppClock.current;
      final subject = await SubjectController.instance.createSubject(name: 'Economics');
      await PlanningBlockController.instance.scheduleBlock(
        null,
        now.subtract(const Duration(minutes: 10)),
        now.add(const Duration(minutes: 20)),
        subjectId: subject.id,
        customTitle: 'Live Block',
      );

      final view = PlanStudyState.planDay(AppClock.current);
      expect(view.hasActiveBlock, isTrue);
      expect(view.activeBlock!.isActive, isTrue);
      expect(view.activeBlock!.remainingMinutes, greaterThan(0));
    });

    test('no active block when the plan is empty or past', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Economics');
      await PlanningBlockController.instance.scheduleBlock(
        null,
        todayAt(1),
        todayAt(2),
        subjectId: subject.id,
        customTitle: 'Past Block',
      );
      final view = PlanStudyState.planDay(AppClock.current);
      expect(view.activeBlock, isNull);
      expect(view.hasMissed, isTrue);
    });
  });

  group('§10 — Missed blocks are surfaced, never dropped', () {
    test('a past unfinished block is reported as missed with its duration',
        () async {
      final subject = await SubjectController.instance.createSubject(name: 'Business Law');
      await PlanningBlockController.instance.scheduleBlock(
        null,
        todayAt(1),
        todayAt(1, 30),
        subjectId: subject.id,
        customTitle: 'Missed Work',
      );

      final view = PlanStudyState.planDay(AppClock.current);
      expect(view.hasMissed, isTrue);
      expect(view.missedBlocks.single.durationMinutes, 30);
      expect(view.missedBlocks.single.isMissed, isTrue);
      // Still present in the day plan — not deleted.
      expect(view.blocks.length, 1);
    });
  });

  group('§11 — Completion uses one authoritative rule', () {
    test('block is complete only when its linked task is complete', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Quant');
      final task = await TaskController.instance.createTask(
        title: 'Ratio practice',
        subjectId: subject.id,
      );
      final block = await PlanningBlockController.instance.scheduleBlock(
        task.id,
        todayAt(9),
        todayAt(9, 30),
        subjectId: subject.id,
      );

      expect(PlanStudyState.isBlockCompleted(block), isFalse);

      await TaskController.instance.completeTask(task.id);
      expect(PlanStudyState.isBlockCompleted(block), isTrue);

      final view = PlanStudyState.planDay(AppClock.current);
      expect(view.completedCount, 1);
      expect(view.blocks.single.isCompleted, isTrue);
      expect(view.allCompleted, isTrue);
    });

    test('a subject block with no task is never auto-completed', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Quant');
      final block = await PlanningBlockController.instance.scheduleBlock(
        null,
        todayAt(9),
        todayAt(9, 30),
        subjectId: subject.id,
      );
      expect(PlanStudyState.isBlockCompleted(block), isFalse);
    });

    test('completion writes no second record on the block store', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Quant');
      final task = await TaskController.instance.createTask(title: 'Algebra');
      await PlanningBlockController.instance.scheduleBlock(
        task.id,
        todayAt(9),
        todayAt(9, 30),
        subjectId: subject.id,
      );
      final before = PlanningBlockController.instance.blocks.length;

      await TaskController.instance.completeTask(task.id);
      PlanStudyState.planDay(AppClock.current);
      PlanStudyState.planDay(AppClock.current);

      expect(PlanningBlockController.instance.blocks.length, before);
    });
  });

  group('§9 — Subject allocation comes from the existing PlanningEngine', () {
    test('allocation aggregates minutes per subject', () async {
      await SubjectController.instance.createSubject(name: 'Accountancy');
      await SubjectController.instance.createSubject(name: 'Business Law');

      final allocation = PlanStudyState.allocation(budgetMinutes: 180);
      expect(allocation.budgetMinutes, 180);
      expect(allocation.entries, isNotEmpty);
      for (final e in allocation.entries) {
        expect(e.minutes, greaterThan(0));
        expect(e.subjectName, isNotEmpty);
      }
      // Ordered heaviest-first.
      for (var i = 1; i < allocation.entries.length; i++) {
        expect(
          allocation.entries[i - 1].minutes,
          greaterThanOrEqualTo(allocation.entries[i].minutes),
        );
      }
    });

    test('allocation matches generateDailyPlan totals exactly', () {
      final plan = PlanController.instance.generateDailyPlan(budgetMinutes: 180);
      final allocation = PlanStudyState.allocation(budgetMinutes: 180);
      final summed = allocation.entries.fold<int>(0, (s, e) => s + e.minutes);
      expect(summed, plan.totalPlannedMinutes);
    });

    test('a tiny budget produces a smaller or equal plan', () async {
      await SubjectController.instance.createSubject(name: 'Economics');
      final small = PlanStudyState.allocation(budgetMinutes: 15);
      final large = PlanStudyState.allocation(budgetMinutes: 240);
      expect(small.totalPlannedMinutes,
          lessThanOrEqualTo(large.totalPlannedMinutes));
    });
  });

  group('§18 — Continue learning uses real persisted sessions only', () {
    test('no continue state when nothing has ever been studied', () {
      expect(PlanStudyState.continueLearning(), isNull);
    });

    test('continue state is built from a completed session', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Accounting');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Partnership',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Partnership Accounts',
      );

      await seedStudySession(
        subject: 'Accounting',
        subjectId: subject.id,
        topicId: topic.id,
        chapterId: chapter.id,
        minutes: 35,
        daysAgo: 1,
      );

      final cl = PlanStudyState.continueLearning();
      expect(cl, isNotNull);
      expect(cl!.subjectName, 'Accounting');
      expect(cl.topicId, topic.id);
      expect(cl.topicTitle, 'Partnership Accounts');
      expect(cl.chapterTitle, 'Partnership');
      expect(cl.lastStudiedLabel, 'Yesterday');
    });
  });

  group('§13 — Study overview derivation', () {
    test('no course means no subjects and no curriculum', () {
      final overview = PlanStudyState.studyOverview();
      expect(overview.hasCourse, isFalse);
      expect(overview.hasSubjects, isFalse);
      expect(overview.totalTopics, 0);
      expect(overview.recommended, isNull);
    });

    test('subject progress is derived by the knowledge engine', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Physics');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Mechanics',
      );
      await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Kinematics',
      );

      final overview = PlanStudyState.studyOverview();
      expect(overview.hasCourse, isTrue);
      expect(overview.subjects.length, 1);
      final sv = overview.subjects.single;
      expect(sv.subject.displayName, 'Physics');
      expect(sv.progress.totalTopics, 1);
      expect(sv.progress.studiedTopics, 0);
      expect(sv.syllabusPercentage, 0);
      expect(sv.health, isNotNull);
    });

    test('a real session moves a topic out of not-started', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Physics');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Mechanics',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Kinematics',
        estimatedMinutes: 30,
      );

      await seedStudySession(
        subject: 'Physics',
        subjectId: subject.id,
        topicId: topic.id,
        chapterId: chapter.id,
        minutes: 40,
      );

      final overview = PlanStudyState.studyOverview();
      expect(overview.studiedTopics, 1);
      expect(overview.syllabusPercentage, 100);
      final rec = overview.recommended;
      expect(rec, isNotNull);
      expect(rec!.topic.id, topic.id);
      expect(rec.status, isNot(TopicStatus.notStarted));
      expect(rec.actionLabel, isNotEmpty);
      expect(rec.reason, isNotEmpty);
    });

    test('a studied topic with no practice surfaces as a practice opportunity',
        () async {
      final subject = await SubjectController.instance.createSubject(name: 'Chemistry');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Organic',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Alkenes',
        estimatedMinutes: 30,
      );

      await seedStudySession(
        subject: 'Chemistry',
        subjectId: subject.id,
        topicId: topic.id,
        chapterId: chapter.id,
        minutes: 45,
      );

      final overview = PlanStudyState.studyOverview();
      final practice =
          overview.practiceOpportunities.map((p) => p.topic.id).toList();
      expect(practice, contains(topic.id));
    });
  });

  group('§25 — Exam context reaches subject rows', () {
    test('a subject with an upcoming exam reports a real countdown', () async {
      final subject = await SubjectController.instance.createSubject(name: 'CA Foundation');
      final now = AppClock.current;
      await ExamController.instance.createExam(
        title: 'CA Foundation',
        subject: 'CA Foundation',
        examDateTime:
            DateTime(now.year, now.month, now.day).add(const Duration(days: 12)),
      );

      final overview = PlanStudyState.studyOverview();
      final sv = overview.subjects.firstWhere((s) => s.subject.id == subject.id);
      expect(sv.daysUntilNextExam, isNotNull);
      expect(sv.daysUntilNextExam, anyOf(11, 12));
      expect(sv.nextExamTitle, 'CA Foundation');
    });

    test('a subject with no exam reports no countdown', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Zoology');
      final overview = PlanStudyState.studyOverview();
      final sv = overview.subjects.firstWhere((s) => s.subject.id == subject.id);
      expect(sv.daysUntilNextExam, isNull);
    });
  });

  group('§10 — findNextAvailableSlot respects the existing day', () {
    test('returns a slot inside the searchable window', () async {
      final tomorrow = AppClock.current.add(const Duration(days: 1));
      final slot = PlanningEngine.findNextAvailableSlot(
        tomorrow,
        durationMinutes: 45,
        availableMinutes: 180,
      );
      expect(slot, isNotNull);
      final end = slot!.add(const Duration(minutes: 45));
      expect(end.isAfter(slot), isTrue);
    });

    test('never overlaps an existing block', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Economics');
      final target = AppClock.current.add(const Duration(days: 1));
      final start = DateTime(target.year, target.month, target.day, 10);
      final end = DateTime(target.year, target.month, target.day, 11);
      await PlanningBlockController.instance.scheduleBlock(
        null,
        start,
        end,
        subjectId: subject.id,
        customTitle: 'Busy',
      );

      final slot = PlanningEngine.findNextAvailableSlot(
        target,
        durationMinutes: 30,
        availableMinutes: 600,
      );
      expect(slot, isNotNull);
      final slotEnd = slot!.add(const Duration(minutes: 30));
      final overlaps = slot.isBefore(end) && slotEnd.isAfter(start);
      expect(overlaps, isFalse);
    });

    test('returns null when the day has no budget left', () async {
      final subject = await SubjectController.instance.createSubject(name: 'Economics');
      final target = AppClock.current.add(const Duration(days: 1));
      await PlanningBlockController.instance.scheduleBlock(
        null,
        DateTime(target.year, target.month, target.day, 8),
        DateTime(target.year, target.month, target.day, 20),
        subjectId: subject.id,
        customTitle: 'All Day',
      );

      final slot = PlanningEngine.findNextAvailableSlot(
        target,
        durationMinutes: 30,
        availableMinutes: 120,
      );
      expect(slot, isNull);
    });

    test('returns null for a non-positive duration', () {
      expect(
        PlanningEngine.findNextAvailableSlot(
          AppClock.current.add(const Duration(days: 1)),
          durationMinutes: 0,
        ),
        isNull,
      );
    });

    test('recovery slots for a missed block are ordered and non-overlapping',
        () async {
      final subject = await SubjectController.instance.createSubject(name: 'Business Law');
      final block = await PlanningBlockController.instance.scheduleBlock(
        null,
        todayAt(1),
        todayAt(1, 30),
        subjectId: subject.id,
        customTitle: 'Missed',
      );

      final slots = PlanningEngine.findRecoverySlots(
        block,
        availableMinutes: 300,
        limit: 3,
      );
      expect(slots, isNotEmpty);
      for (var i = 1; i < slots.length; i++) {
        expect(slots[i].isAfter(slots[i - 1]), isTrue);
      }
    });
  });

  group('§34 — user isolation', () {
    test('User A plan is not visible to User B', () async {
      final subjectA = await SubjectController.instance.createSubject(name: 'A Subject');
      await PlanningBlockController.instance.scheduleBlock(
        null,
        todayAt(9),
        todayAt(10),
        subjectId: subjectA.id,
        customTitle: 'A Work',
      );
      expect(PlanStudyState.planDay(AppClock.current).blocks.length, 1);

      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.setAuthenticatedUser('other_user_$userId');
      await PlanningBlockController.instance.load();
      await SubjectController.instance.load();
      await TaskController.instance.load();

      final viewB = PlanStudyState.planDay(AppClock.current);
      expect(viewB.blocks, isEmpty);
      expect(SubjectController.instance.activeSubjects, isEmpty);
      expect(PlanStudyState.studyOverview().hasCourse, isFalse);
    });
  });
}
