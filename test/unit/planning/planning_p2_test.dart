import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    TaskController.instance.clearData();
    PlanController.instance.clearData();
    PlanningBlockController.instance.clearData();
    FocusController.instance.clearData();
  });

  group('Planning P2 — Workspace & PlanningBlocks', () {
    test('PlanController tasksFor matches PlanningBlocks & scheduledDate', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final tc = TaskController.instance;
      final t1 = await tc.createTask(title: 'Due today', dueDate: today);
      final t2 = await tc.createTask(title: 'Unscheduled task');

      expect(PlanController.instance.tasksFor(today).map((t) => t.id), contains(t1.id));
      expect(PlanController.instance.tasksFor(today).map((t) => t.id), isNot(contains(t2.id)));

      final bc = PlanningBlockController.instance;
      await bc.scheduleBlock(t2.id, today, today.add(const Duration(hours: 1)));

      final todayTasks = PlanController.instance.tasksFor(today);
      expect(todayTasks.map((t) => t.id), contains(t1.id));
      expect(todayTasks.map((t) => t.id), contains(t2.id));
    });

    test('Schedule, reschedule, and unschedule work blocks without deleting task', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10);
      final tc = TaskController.instance;
      final task = await tc.createTask(title: 'Physics Revision');

      final bc = PlanningBlockController.instance;
      final block = await bc.scheduleBlock(
        task.id,
        today,
        today.add(const Duration(hours: 2)),
      );

      expect(bc.blocksForTask(task.id).length, 1);
      expect(bc.blocksForTask(task.id).first.id, block.id);
      expect(bc.blocksForDay(today).length, 1);

      final tomorrow = today.add(const Duration(days: 1));
      final rescheduled = await bc.rescheduleBlock(
        block.id,
        tomorrow,
        tomorrow.add(const Duration(hours: 1)),
      );

      expect(rescheduled, isNotNull);
      expect(rescheduled!.startAt, tomorrow);
      expect(bc.blocksForDay(today), isEmpty);
      expect(bc.blocksForDay(tomorrow).length, 1);

      await bc.unscheduleBlock(block.id);
      expect(bc.blocksForTask(task.id), isEmpty);
      expect(tc.tasks.any((t) => t.id == task.id), isTrue);
    });

    test('Prevent duplicate planning blocks for identical schedule operation', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 14);
      final end = start.add(const Duration(hours: 1));

      final tc = TaskController.instance;
      final task = await tc.createTask(title: 'Essay Draft');

      final bc = PlanningBlockController.instance;
      final b1 = await bc.scheduleBlock(task.id, start, end);
      final b2 = await bc.scheduleBlock(task.id, start, end);

      expect(b1.id, b2.id);
      expect(bc.blocksForTask(task.id).length, 1);
    });

    test('Validation enforces endAt after startAt', () async {
      final now = DateTime.now();
      final bc = PlanningBlockController.instance;

      expect(
        () => bc.scheduleBlock('t1', now, now.subtract(const Duration(minutes: 10))),
        throwsArgumentError,
      );

      final block = await bc.scheduleBlock('t1', now, now.add(const Duration(hours: 1)));
      expect(
        () => bc.rescheduleBlock(block.id, now, now.subtract(const Duration(minutes: 5))),
        throwsArgumentError,
      );
    });
  });

  group('Planning P2 — Task creation & metadata support', () {
    test('TaskController creates task with estimatedMinutes and goalId', () async {
      final tc = TaskController.instance;
      final task = await tc.createTask(
        title: 'Complete Project Report',
        priority: TaskPriority.high,
        estimatedMinutes: 90,
        goalId: 'goal_term1',
        subjectId: 'sub_cs',
      );

      expect(task.title, 'Complete Project Report');
      expect(task.priority, TaskPriority.high);
      expect(task.estimatedMinutes, 90);
      expect(task.goalId, 'goal_term1');
      expect(task.subjectId, 'sub_cs');
    });

    test('PlanningBlock copyWith updates fields correctly', () {
      final now = DateTime.now();
      final block = PlanningBlock(
        id: 'pb_1',
        userId: 'demo',
        taskId: 't1',
        startAt: now,
        endAt: now.add(const Duration(hours: 1)),
      );

      final updated = block.copyWith(
        startAt: now.add(const Duration(hours: 2)),
        endAt: now.add(const Duration(hours: 3)),
      );

      expect(updated.id, 'pb_1');
      expect(updated.startAt, now.add(const Duration(hours: 2)));
      expect(updated.endAt, now.add(const Duration(hours: 3)));
    });
  });

  group('Planning P2 — Focus Integration', () {
    test('Focus completed session preserves task and does not auto-complete it', () async {
      final tc = TaskController.instance;
      final task = await tc.createTask(
        title: 'Math Problems',
        subjectId: 'sub_math',
      );

      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 25),
        taskId: task.id,
        subjectId: task.subjectId,
        subjectName: 'Mathematics',
        objective: task.title,
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.taskId, task.id);
      expect(fc.activeSession?.subjectId, 'sub_math');

      fc.completeSession();

      expect(fc.hasActiveSession, isFalse);
      expect(fc.sessions.first.taskId, task.id);

      final refreshedTask = tc.tasks.firstWhere((t) => t.id == task.id);
      expect(refreshedTask.isCompleted, isFalse);
    });
  });
}
