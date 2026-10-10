import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/intelligence/weekly_plan_engine.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    TaskController.instance.clearData();
    ExamController.instance.clearData();
  });

  group('WeeklyPlanEngine', () {
    test('upcomingExamDays returns null when no exams', () {
      final result = WeeklyPlanEngine.upcomingExamDays();
      expect(result, isNull);
    });

    test('upcomingExamDays returns days for closest exam', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 3));
      await ExamController.instance.createExam(
        title: 'Math Final',
        subject: 'Mathematics',
        examDateTime: tomorrow,
      );

      final result = WeeklyPlanEngine.upcomingExamDays();
      expect(result, isNotNull);
      expect(result, 3);
    });

    test('overdueCount returns correct count', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await TaskController.instance.createTask(
        title: 'Overdue Task',
        dueDate: yesterday,
      );

      expect(WeeklyPlanEngine.overdueCount(), 1);
    });

    test('completedTodayCount returns correct count', () async {
      final today = DateTime.now();
      final task = await TaskController.instance.createTask(
        title: 'Completed Task',
        dueDate: today,
      );
      await TaskController.instance.completeTask(task.id);

      expect(WeeklyPlanEngine.completedTodayCount(), 1);
    });

    test('weekDays returns 7 dates', () {
      final days = WeeklyPlanEngine.weekDays(DateTime.now());
      expect(days.length, 7);
    });

    test('dailyTaskCount returns counts per day', () async {
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      await TaskController.instance.createTask(
        title: 'Task',
        dueDate: todayNormalized,
      );

      final counts = WeeklyPlanEngine.dailyTaskCount(today);
      expect(counts[todayNormalized], 1);
    });
  });
}
