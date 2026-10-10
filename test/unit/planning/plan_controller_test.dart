import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/utils/app_week_utils.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    TaskController.instance.clearData();
    PlanController.instance.clearData();
  });

  group('PlanController — Today & Week', () {
    test('selectedDay defaults to today', () {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      expect(PlanController.instance.selectedDay, today);
    });

    test('isTodaySelected returns true for default', () {
      expect(PlanController.instance.isTodaySelected, true);
    });

    test('selectDay updates selectedDay', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      PlanController.instance.selectDay(tomorrow);
      expect(
        PlanController.instance.selectedDay,
        AppWeekUtils.dateOnly(tomorrow),
      );
    });

    test('selectToday resets to today', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      PlanController.instance.selectDay(tomorrow);
      PlanController.instance.selectToday();
      expect(
        PlanController.instance.selectedDay,
        AppWeekUtils.dateOnly(DateTime.now()),
      );
    });

    test('week returns 7 dates', () {
      final week = PlanController.instance.week;
      expect(week.length, 7);
    });

    test('isSelected works correctly', () {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      expect(PlanController.instance.isSelected(today), true);
      final tomorrow = DateTime.now().add(const Duration(days: 10));
      expect(PlanController.instance.isSelected(tomorrow), false);
    });

    test('isToday works correctly', () {
      final today = DateTime.now();
      expect(PlanController.instance.isToday(today), true);
      final future = DateTime.now().add(const Duration(days: 10));
      expect(PlanController.instance.isToday(future), false);
    });
  });

  group('PlanController — Task Derivation', () {
    test('tasksFor returns tasks scheduled on that day', () async {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      await TaskController.instance.createTask(
        title: 'Study Math',
        scheduledDate: today,
      );

      final tasks = PlanController.instance.tasksFor(today);
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Study Math');
    });

    test('tasksFor returns tasks due on that day', () async {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      await TaskController.instance.createTask(
        title: 'Submit Essay',
        dueDate: today,
      );

      final tasks = PlanController.instance.tasksFor(today);
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Submit Essay');
    });

    test('tasksFor does not return tasks on other days', () async {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      final tomorrow = today.add(const Duration(days: 1));
      await TaskController.instance.createTask(
        title: 'Future Task',
        scheduledDate: tomorrow,
      );

      final todayTasks = PlanController.instance.tasksFor(today);
      expect(todayTasks.length, 0);
    });

    test('metricsFor computes correct metrics', () async {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      await TaskController.instance.createTask(
        title: 'Task 1',
        scheduledDate: today,
      );
      final task2 = await TaskController.instance.createTask(
        title: 'Task 2',
        scheduledDate: today,
      );
      await TaskController.instance.completeTask(task2.id);

      final metrics = PlanController.instance.metricsFor(today);
      expect(metrics.total, 2);
      expect(metrics.completed, 1);
      expect(metrics.progress, 0.5);
    });

    test('completed tasks are pushed to bottom of list', () async {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      final task1 = await TaskController.instance.createTask(
        title: 'First',
        scheduledDate: today,
        priority: TaskPriority.high,
      );
      await TaskController.instance.createTask(
        title: 'Second',
        scheduledDate: today,
        priority: TaskPriority.medium,
      );
      await TaskController.instance.completeTask(task1.id);

      final tasks = PlanController.instance.tasksFor(today);
      expect(tasks.length, 2);
      expect(tasks.last.title, 'First');
    });
  });

  group('PlanController — Overdue Handling', () {
    test('overdue tasks exist when due date is past', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayNorm = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );
      await TaskController.instance.createTask(
        title: 'Overdue Task',
        dueDate: yesterdayNorm,
      );

      final overdueTasks = TaskController.instance.overdueTasks;
      expect(overdueTasks.length, 1);
      expect(overdueTasks.first.title, 'Overdue Task');
    });
  });

  group('PlanController — No Destructive Rescheduling', () {
    test('planTask does not modify existing tasks', () async {
      final today = AppWeekUtils.dateOnly(DateTime.now());
      await TaskController.instance.createTask(
        title: 'Existing Task',
        dueDate: today,
      );

      PlanController.instance.planTask(title: 'New Planned Task');

      final allTasks = TaskController.instance.tasks;
      expect(allTasks.length, 2);
      expect(allTasks.any((t) => t.title == 'Existing Task'), true);
    });

    test('clearData does not delete persistent storage', () {
      PlanController.instance.clearData();
      expect(
        PlanController.instance.selectedDay,
        AppWeekUtils.dateOnly(DateTime.now()),
      );
    });
  });
}
