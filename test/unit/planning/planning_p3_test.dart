import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/utils/app_week_utils.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_planning_p3');
    await StorageService.instance.clearUser(userId: 'test_planning_p3');
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    TaskController.instance.clearData();
    PlanController.instance.clearData();
    PlanningBlockController.instance.clearData();
    ExamController.instance.clearData();
    FocusController.instance.clearData();
  });

  group('Planning P3 — Intelligent Planning Engine & Deterministic Scoring', () {
    test('1. Deterministic task scoring gives identical score for same input', () {
      final now = DateTime(2026, 9, 11, 10, 0);
      final task = StudentTask(
        id: 't1',
        title: 'Math Assignment',
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 9, 12, 12, 0),
        estimatedMinutes: 45,
      );

      final score1 = PlanningEngine.scoreTask(task, referenceTime: now);
      final score2 = PlanningEngine.scoreTask(task, referenceTime: now);

      expect(score1, equals(score2));
      expect(score1, isPositive);
    });

    test('2. Overdue priority: overdue tasks score higher than upcoming tasks', () {
      final now = DateTime(2026, 9, 11, 10, 0);
      final overdueTask = StudentTask(
        id: 't_overdue',
        title: 'Overdue Project',
        priority: TaskPriority.medium,
        dueDate: DateTime(2026, 9, 9, 10, 0), // 2 days overdue
      );
      final futureTask = StudentTask(
        id: 't_future',
        title: 'Future Project',
        priority: TaskPriority.medium,
        dueDate: DateTime(2026, 9, 14, 10, 0),
      );

      final overdueScore = PlanningEngine.scoreTask(overdueTask, referenceTime: now);
      final futureScore = PlanningEngine.scoreTask(futureTask, referenceTime: now);

      expect(overdueScore, greaterThan(futureScore));
    });

    test('3. Urgent/high priority handling: critical > high > medium > low', () {
      final now = DateTime(2026, 9, 11, 10, 0);
      final due = DateTime(2026, 9, 13, 10, 0);

      final tCrit = StudentTask(id: '1', title: 'C', priority: TaskPriority.critical, dueDate: due);
      final tHigh = StudentTask(id: '2', title: 'H', priority: TaskPriority.high, dueDate: due);
      final tMed = StudentTask(id: '3', title: 'M', priority: TaskPriority.medium, dueDate: due);
      final tLow = StudentTask(id: '4', title: 'L', priority: TaskPriority.low, dueDate: due);

      final sCrit = PlanningEngine.scoreTask(tCrit, referenceTime: now);
      final sHigh = PlanningEngine.scoreTask(tHigh, referenceTime: now);
      final sMed = PlanningEngine.scoreTask(tMed, referenceTime: now);
      final sLow = PlanningEngine.scoreTask(tLow, referenceTime: now);

      expect(sCrit, greaterThan(sHigh));
      expect(sHigh, greaterThan(sMed));
      expect(sMed, greaterThan(sLow));
    });

    test('4. Due-soon handling: due in 1 day > due in 3 days > due in 7 days > inbox', () {
      final now = DateTime(2026, 9, 11, 10, 0);

      final t1 = StudentTask(id: '1', title: '1d', dueDate: DateTime(2026, 9, 12));
      final t3 = StudentTask(id: '2', title: '3d', dueDate: DateTime(2026, 9, 14));
      final t7 = StudentTask(id: '3', title: '7d', dueDate: DateTime(2026, 9, 18));
      final tInbox = StudentTask(id: '4', title: 'Inbox');

      final s1 = PlanningEngine.scoreTask(t1, referenceTime: now);
      final s3 = PlanningEngine.scoreTask(t3, referenceTime: now);
      final s7 = PlanningEngine.scoreTask(t7, referenceTime: now);
      final sInbox = PlanningEngine.scoreTask(tInbox, referenceTime: now);

      expect(s1, greaterThan(s3));
      expect(s3, greaterThan(s7));
      expect(s7, greaterThan(sInbox));
    });

    test('5. Estimated effort resolution & fallback', () {
      final taskWithEst = StudentTask(id: '1', title: 'Est', estimatedMinutes: 50);
      final taskWithoutEst = StudentTask(id: '2', title: 'NoEst', estimatedMinutes: 0);

      expect(PlanningEngine.resolveTaskMinutes(taskWithEst), 50);
      expect(PlanningEngine.resolveTaskMinutes(taskWithoutEst), PlanningEngine.defaultTaskMinutes);
    });

    test('6. Exam proximity boosts task priority as exam approaches', () {
      // Relative dates: fixed 2026 dates become past as wall-clock advances,
      // which flips isUpcoming and breaks proximity scoring.
      final now = DateTime.now();

      final examNear = StudentExam(
        id: 'exam_near',
        title: 'Physics Midterm',
        examDateTime: now.add(const Duration(days: 2)), // 2 days away
      );
      final examFar = StudentExam(
        id: 'exam_far',
        title: 'History Final',
        examDateTime: now.add(const Duration(days: 19)), // 19 days away
      );

      final taskNear = StudentTask(id: '1', title: 'Review Waves', examId: 'exam_near');
      final taskFar = StudentTask(id: '2', title: 'Review Romans', examId: 'exam_far');

      final scoreNear = PlanningEngine.scoreTask(
        taskNear,
        referenceTime: now,
        exams: [examNear, examFar],
      );
      final scoreFar = PlanningEngine.scoreTask(
        taskFar,
        referenceTime: now,
        exams: [examNear, examFar],
      );

      expect(scoreNear, greaterThan(scoreFar));
    });
  });

  group('Planning P3 — "What should I do now?" & Edge Cases', () {
    test('7. "What should I do now?" returns top actionable recommendation', () {
      final now = DateTime(2026, 9, 11, 10, 0);
      final overdueTask = StudentTask(
        id: 't_top',
        title: 'Submit Lab Report',
        priority: TaskPriority.critical,
        dueDate: DateTime(2026, 9, 10),
        estimatedMinutes: 30,
      );
      final otherTask = StudentTask(
        id: 't_other',
        title: 'Read Chapter 4',
        priority: TaskPriority.low,
      );

      final rec = PlanningEngine.getWhatShouldIDoNow(
        tasks: [otherTask, overdueTask],
        referenceTime: now,
      );

      expect(rec, isNotNull);
      expect(rec!.task?.id, 't_top');
      expect(rec.reason, contains('Overdue'));
      expect(rec.estimatedMinutes, 30);
    });

    test('8. Completed tasks are excluded from scoring and recommendations', () {
      final now = DateTime(2026, 9, 11, 10, 0);
      final doneTask = StudentTask(
        id: 't_done',
        title: 'Done Task',
        status: TaskStatus.completed,
        dueDate: DateTime(2026, 9, 10),
      );

      final score = PlanningEngine.scoreTask(doneTask, referenceTime: now);
      expect(score, -1.0);

      final rec = PlanningEngine.getWhatShouldIDoNow(
        tasks: [doneTask],
        referenceTime: now,
      );
      expect(rec, isNull);
    });

    test('9. Cancelled / empty task state returns null safely', () {
      final rec = PlanningEngine.getWhatShouldIDoNow(tasks: []);
      expect(rec, isNull);
    });
  });

  group('Planning P3 — Daily Plan & Workload Calculations', () {
    test('10. Daily plan generation creates sensible schedule fitting budget', () {
      final today = DateTime(2026, 9, 11);
      final t1 = StudentTask(
        id: 't1',
        title: 'Math HW',
        dueDate: today,
        estimatedMinutes: 60,
        priority: TaskPriority.high,
      );
      final t2 = StudentTask(
        id: 't2',
        title: 'Physics HW',
        dueDate: today,
        estimatedMinutes: 60,
        priority: TaskPriority.medium,
      );

      final plan = PlanningEngine.generateDailyPlan(
        today,
        tasks: [t1, t2],
        availableBudgetMinutes: 180,
        baseStartTime: DateTime(2026, 9, 11, 9, 0),
      );

      expect(plan.items.length, 2);
      expect(plan.totalPlannedMinutes, 120);
      expect(plan.isOverloaded, isFalse);
      expect(plan.items.first.task?.id, 't1');
      expect(plan.items.first.suggestedStart, DateTime(2026, 9, 11, 9, 0));
      expect(plan.items.first.suggestedEnd, DateTime(2026, 9, 11, 10, 0));
    });

    test('11. Workload calculation aggregates remaining, scheduled, completed', () {
      final today = AppWeekUtils.dateOnly(DateTime.now());

      final t1 = StudentTask(id: '1', title: 'T1', dueDate: today, estimatedMinutes: 40);
      final t2 = StudentTask(id: '2', title: 'T2', dueDate: today, estimatedMinutes: 30, status: TaskStatus.completed);

      final workload = PlanningEngine.calculateDayWorkload(
        today,
        tasks: [t1, t2],
        blocks: [],
        availableMinutes: 120,
      );

      expect(workload.totalTasksCount, 2);
      expect(workload.completedTasksCount, 1);
      expect(workload.remainingTasksCount, 1);
      expect(workload.estimatedMinutesRemaining, 40);
      expect(workload.completedMinutes, 30);
      expect(workload.isOverloaded, isFalse);
    });

    test('12. Overload detection calculates correct overloadMinutes', () {
      final today = AppWeekUtils.dateOnly(DateTime.now());

      final t1 = StudentTask(id: '1', title: 'T1', dueDate: today, estimatedMinutes: 90);
      final t2 = StudentTask(id: '2', title: 'T2', dueDate: today, estimatedMinutes: 60);

      final workload = PlanningEngine.calculateDayWorkload(
        today,
        tasks: [t1, t2],
        blocks: [],
        availableMinutes: 120,
      );

      expect(workload.estimatedMinutesRemaining, 150);
      expect(workload.isOverloaded, isTrue);
      expect(workload.overloadMinutes, 30);
    });

    test('13. Scheduled minutes derived from PlanningBlocks durations', () {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      final start1 = DateTime(today.year, today.month, today.day, 10, 0);
      final end1 = DateTime(today.year, today.month, today.day, 11, 30); // 90 min

      final block = PlanningBlock(
        id: 'pb_1',
        userId: 'demo',
        taskId: 't1',
        startAt: start1,
        endAt: end1,
      );

      final workload = PlanningEngine.calculateDayWorkload(
        today,
        tasks: [StudentTask(id: 't1', title: 'T1')],
        blocks: [block],
        availableMinutes: 180,
      );

      expect(workload.scheduledMinutes, 90);
    });

    test('14. Completed minutes derived from completed tasks', () {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      final task = StudentTask(
        id: 't1',
        title: 'T1',
        dueDate: today,
        status: TaskStatus.completed,
        estimatedMinutes: 45,
      );

      final workload = PlanningEngine.calculateDayWorkload(
        today,
        tasks: [task],
        blocks: [],
      );

      expect(workload.completedMinutes, 45);
    });
  });

  group('Planning P3 — Safe Rescheduling & Duplicate Prevention', () {
    test('15. Safe rescheduling moves eligible future blocks without deleting tasks or moving past', () async {
      final targetDay = DateTime(2026, 9, 11);
      final now = DateTime(2026, 9, 11, 9, 0);
      final start1 = DateTime(2026, 9, 11, 10, 0);
      final end1 = DateTime(2026, 9, 11, 12, 0); // 120m
      final start2 = DateTime(2026, 9, 11, 13, 0);
      final end2 = DateTime(2026, 9, 11, 15, 0); // 120m

      final tc = TaskController.instance;
      final t1 = await tc.createTask(title: 'Task 1', estimatedMinutes: 120);
      final t2 = await tc.createTask(title: 'Task 2', estimatedMinutes: 120);

      final bc = PlanningBlockController.instance;
      await bc.scheduleBlock(t1.id, start1, end1);
      await bc.scheduleBlock(t2.id, start2, end2);

      // Total scheduled today = 240m. Available = 120m.
      final moved = await PlanningEngine.rebalanceOverloadedDay(
        targetDay,
        tasks: tc.tasks,
        availableMinutes: 120,
        referenceTime: now,
      );

      expect(moved, greaterThanOrEqualTo(1));
      expect(tc.tasks.length, 2); // Tasks preserved
      expect(bc.blocks.length, 2); // Blocks preserved
      expect(bc.blocks.any((b) => b.startAt.isBefore(now)), isFalse); // Never into past
    });

    test('16. Duplicate block prevention on applyDailyPlan', () async {
      final today = DateTime.now();
      final tc = TaskController.instance;
      final task = await tc.createTask(title: 'Unique Task', estimatedMinutes: 30);

      final plan = PlanningEngine.generateDailyPlan(
        today,
        tasks: tc.tasks,
        availableBudgetMinutes: 180,
      );

      final blocks1 = await PlanningEngine.applyDailyPlan(plan);
      final blocks2 = await PlanningEngine.applyDailyPlan(plan);

      expect(blocks1.length, blocks2.length);
      expect(PlanningBlockController.instance.blocksForTask(task.id).length, 1);
    });
  });

  group('Planning P3 — Integration, Safety & User Isolation', () {
    test('17. Focus taskId integration preserves task state', () async {
      final tc = TaskController.instance;
      final task = await tc.createTask(title: 'Focus Goal', estimatedMinutes: 25);

      final rec = PlanningEngine.getWhatShouldIDoNow(tasks: tc.tasks);
      expect(rec, isNotNull);

      final fc = FocusController.instance;
      fc.startTimer(
        duration: Duration(minutes: rec!.estimatedMinutes),
        taskId: rec.task?.id,
        objective: rec.title,
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.taskId, task.id);

      fc.completeSession();
      expect(fc.hasActiveSession, isFalse);

      final refreshed = tc.tasks.firstWhere((t) => t.id == task.id);
      expect(refreshed.isCompleted, isFalse); // Does not auto-complete
    });

    test('18. Missing Subject/Exam/Goal safety fails gracefully', () {
      final taskWithMissingRefs = StudentTask(
        id: 't_missing',
        title: 'Orphaned Task',
        examId: 'non_existent_exam',
        subjectId: 'non_existent_subject',
        goalId: 'non_existent_goal',
      );

      // Should not throw
      final score = PlanningEngine.scoreTask(
        taskWithMissingRefs,
        exams: [],
        blocks: [],
      );
      expect(score, isPositive);

      final rec = PlanningEngine.getWhatShouldIDoNow(
        tasks: [taskWithMissingRefs],
        exams: [],
      );
      expect(rec, isNotNull);
      expect(rec!.task?.id, 't_missing');
    });

    test('19. User isolation via ControllerIsolation', () async {
      final bc = PlanningBlockController.instance;
      final now = DateTime.now();
      await bc.scheduleBlock('t1', now.add(const Duration(hours: 1)), now.add(const Duration(hours: 2)));
      expect(bc.blocks.length, 1);

      ControllerIsolation.instance.clearAllControllers();
      expect(bc.blocks, isEmpty);
      expect(PlanController.instance.selectedDay, AppWeekUtils.dateOnly(DateTime.now()));
    });

    test('20. Persistence of PlanningBlocks', () async {
      final bc = PlanningBlockController.instance;
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 10, 0);
      final end = start.add(const Duration(hours: 1));

      await bc.scheduleBlock('t_persist', start, end);
      expect(bc.blocks.length, 1);

      // Reload controller from storage
      bc.clearData();
      expect(bc.blocks, isEmpty);
      await bc.load();
      expect(bc.blocks.length, 1);
      expect(bc.blocks.first.taskId, 't_persist');
    });

    test('21. Deterministic output for identical input across repeated calls', () {
      final today = DateTime(2026, 9, 11);
      final tasks = [
        StudentTask(id: 't1', title: 'Task A', priority: TaskPriority.high, sortOrder: 1),
        StudentTask(id: 't2', title: 'Task B', priority: TaskPriority.medium, sortOrder: 2),
        StudentTask(id: 't3', title: 'Task C', priority: TaskPriority.low, sortOrder: 3),
      ];

      final plan1 = PlanningEngine.generateDailyPlan(today, tasks: tasks);
      final plan2 = PlanningEngine.generateDailyPlan(today, tasks: tasks);

      expect(plan1.items.length, plan2.items.length);
      for (int i = 0; i < plan1.items.length; i++) {
        expect(plan1.items[i].task?.id, equals(plan2.items[i].task?.id));
        expect(plan1.items[i].suggestedStart, equals(plan2.items[i].suggestedStart));
        expect(plan1.items[i].suggestedEnd, equals(plan2.items[i].suggestedEnd));
      }
    });
  });
}
