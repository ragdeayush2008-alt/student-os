import '../../data/models/task.dart';

/// A deterministic task recommendation with an explainable reason.
class RecommendedTask {
  const RecommendedTask({
    required this.task,
    required this.reason,
    required this.urgency,
    required this.rank,
  });

  final StudentTask task;
  final String reason;
  final int urgency; // higher = more urgent
  final int rank;
}

/// Deterministic, pure-function task recommendation engine.
///
/// Signals used: overdue status, due-date proximity, explicit priority,
/// scheduled-date match, subtask completion, task age.
/// No fake AI scores — every recommendation is explainable.
abstract final class TaskRecommendationEngine {
  /// Returns up to [limit] recommended active tasks, ordered by urgency.
  ///
  /// Completed tasks are never recommended.
  static List<RecommendedTask> recommend(
    List<StudentTask> tasks, {
    int limit = 3,
  }) {
    final active = tasks.where((t) => !t.isCompleted).toList();
    if (active.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scored = <RecommendedTask>[];

    for (final task in active) {
      final result = _scoreTask(task, now, today);
      if (result != null) scored.add(result);
    }

    scored.sort((a, b) {
      if (a.urgency != b.urgency) return b.urgency.compareTo(a.urgency);
      return a.rank.compareTo(b.rank);
    });

    return scored.take(limit).toList();
  }

  static RecommendedTask? _scoreTask(
    StudentTask task,
    DateTime now,
    DateTime today,
  ) {
    // Overdue
    if (task.isOverdue) {
      final daysOverdue = today
          .difference(
            DateTime(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
            ),
          )
          .inDays;
      return RecommendedTask(
        task: task,
        reason: 'Overdue by $daysOverdue ${daysOverdue == 1 ? 'day' : 'days'}',
        urgency: 100 + daysOverdue,
        rank: task.sortOrder,
      );
    }

    // Due today
    if (task.isDueToday) {
      return RecommendedTask(
        task: task,
        reason: 'Due today',
        urgency: 90,
        rank: task.sortOrder,
      );
    }

    // Due tomorrow
    if (task.dueDate != null) {
      final dueDay = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      final diff = dueDay.difference(today).inDays;
      if (diff == 1) {
        return RecommendedTask(
          task: task,
          reason: 'Due tomorrow',
          urgency: 80,
          rank: task.sortOrder,
        );
      }
      if (diff <= 3) {
        return RecommendedTask(
          task: task,
          reason: 'Due in $diff days',
          urgency: 70 - diff,
          rank: task.sortOrder,
        );
      }
    }

    // Scheduled today
    if (task.isScheduledToday) {
      return RecommendedTask(
        task: task,
        reason: 'Scheduled for today',
        urgency: 75,
        rank: task.sortOrder,
      );
    }

    // High/critical priority due soon (within 7 days)
    if ((task.priority == TaskPriority.critical ||
            task.priority == TaskPriority.high) &&
        task.dueDate != null) {
      return RecommendedTask(
        task: task,
        reason: '${task.priority.label} priority',
        urgency: 50 + task.priority.index * 10,
        rank: task.sortOrder,
      );
    }

    // Nearly complete subtasks
    if (task.hasSubtasks && task.subtaskProgress >= 0.5) {
      final remaining = task.subtaskCount - task.subtasksCompleted;
      return RecommendedTask(
        task: task,
        reason:
            '$remaining ${remaining == 1 ? 'subtask' : 'subtasks'} remaining',
        urgency: 40,
        rank: task.sortOrder,
      );
    }

    // Old unfinished task (created more than 7 days ago)
    final age = today
        .difference(
          DateTime(
            task.createdAt.year,
            task.createdAt.month,
            task.createdAt.day,
          ),
        )
        .inDays;
    if (age > 7 && task.priority.index <= TaskPriority.medium.index) {
      return RecommendedTask(
        task: task,
        reason: 'Created $age days ago',
        urgency: 20,
        rank: task.sortOrder,
      );
    }

    return null;
  }
}
