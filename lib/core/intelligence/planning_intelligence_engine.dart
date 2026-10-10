import 'package:flutter/material.dart';

import '../../features/planning/plan_controller.dart';
import 'student_snapshot.dart';

import '../../features/tasks/task_controller.dart';

/// An explainable, data-backed planning suggestion.
@immutable
class PlanningSuggestion {
  const PlanningSuggestion({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.examId,
    this.taskId,
  });

  final String id;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final String? examId;
  final String? taskId;
}

/// Deterministic intelligence engine for the Planning command center.
///
/// Analyzes the student's upcoming schedule to identify:
/// - Overloaded days
/// - Approaching exams with preparation gaps
/// - Unfinished high-priority work
/// - Study gaps for upcoming tests
///
/// All suggestions are derived purely from real stored data.
class PlanningIntelligenceEngine {
  const PlanningIntelligenceEngine();

  /// Derives smart planning suggestions for the selected day and upcoming horizon.
  List<PlanningSuggestion> deriveSuggestions(
    StudentSnapshot snapshot,
    DateTime selectedDay,
  ) {
    final suggestions = <PlanningSuggestion>[];
    final tc = TaskController.instance;
    final pc = PlanController.instance;

    // 1. Overloaded Day Detection
    final dayTasks = pc.tasksFor(selectedDay);
    final activeCount = dayTasks.where((t) => !t.isCompleted).length;
    if (activeCount >= 5) {
      suggestions.add(
        PlanningSuggestion(
          id: 'overload_${selectedDay.millisecondsSinceEpoch}',
          title: 'Heavy workload scheduled',
          detail:
              '$activeCount active tasks on this day. Consider rescheduling some tasks to prevent burnout.',
          icon: Icons.calendar_view_day_rounded,
          color: const Color(0xFF1F5C44),
          actionLabel: 'Review agenda',
        ),
      );
    }

    // 2. Exam Preparation Gap Detection
    for (final exam in snapshot.upcomingExams) {
      final days = exam.daysUntilExam;
      if (days != null && days <= 7 && !exam.isCompleted) {
        final linkedTasks = tc.tasksForExam(exam.id);
        final uncompleted = linkedTasks.where((t) => !t.isCompleted).length;

        if (uncompleted > 0) {
          suggestions.add(
            PlanningSuggestion(
              id: 'exam_gap_${exam.id}',
              title: '${exam.title} in $days days',
              detail:
                  '$uncompleted preparation task${uncompleted > 1 ? "s" : ""} remaining. Dedicate time to complete them before the exam.',
              icon: Icons.school_rounded,
              color: days <= 3
                  ? const Color(0xFF1F5C44)
                  : const Color(0xFF6F967F),
              examId: exam.id,
              actionLabel: 'View exam',
            ),
          );
          break; // Show at most one exam gap suggestion
        }
      }
    }

    // 3. High-priority overdue or pending tasks
    if (snapshot.hasOverdueTasks && suggestions.length < 2) {
      final count = snapshot.overdueTasks.length;
      suggestions.add(
        PlanningSuggestion(
          id: 'overdue_summary',
          title: '$count overdue task${count > 1 ? "s" : ""}',
          detail: 'Overdue tasks reduce your planning momentum. Clear or reschedule them today.',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFF1F5C44),
          actionLabel: 'View tasks',
        ),
      );
    }

    return suggestions.take(2).toList();
  }
}
