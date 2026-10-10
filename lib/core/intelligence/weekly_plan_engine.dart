import 'package:flutter/foundation.dart';

import '../../features/tasks/task_controller.dart';
import '../../features/exams/exam_controller.dart';

/// Derived weekly planning state from real controllers.
/// No mutation; no persistence; derived only.
@immutable
class WeeklyPlanEngine {
  const WeeklyPlanEngine();

  static List<DateTime> weekDays(DateTime anchor) {
    final start = DateTime(anchor.year, anchor.month, anchor.day).subtract(
      Duration(
        days: DateTime(anchor.year, anchor.month, anchor.day).weekday - 1,
      ),
    );
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  static Map<DateTime, int> dailyTaskCount(DateTime anchor) {
    final days = weekDays(anchor);
    final result = <DateTime, int>{};
    for (final d in days) {
      final count = TaskController.instance.activeTasks.where((t) {
        if (t.dueDate == null) return false;
        final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        final target = DateTime(d.year, d.month, d.day);
        return due == target && !t.isCompleted;
      }).length;
      result[d] = count;
    }
    return result;
  }

  static int overdueCount() => TaskController.instance.activeTasks
      .where((t) => t.isOverdue && !t.isCompleted)
      .length;
  static int completedTodayCount() {
    final now = DateTime.now();
    return TaskController.instance.tasks
        .where(
          (t) =>
              t.isCompleted &&
              t.completedAt != null &&
              t.completedAt!.year == now.year &&
              t.completedAt!.month == now.month &&
              t.completedAt!.day == now.day,
        )
        .length;
  }

  static int? upcomingExamDays() {
    final upcoming = ExamController.instance.upcomingExams
        .where((e) => !e.isCompleted && e.daysUntilExam != null)
        .toList();
    if (upcoming.isEmpty) return null;
    final closest = upcoming.reduce(
      (a, b) => (a.daysUntilExam! < b.daysUntilExam!) ? a : b,
    );
    return closest.daysUntilExam;
  }
}
