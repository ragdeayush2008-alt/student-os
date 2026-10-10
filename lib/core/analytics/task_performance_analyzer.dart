import 'performance_snapshot.dart';

/// Analyzes task completion performance.
class TaskPerformanceAnalyzer {
  const TaskPerformanceAnalyzer();

  /// Calculates completion rate as (completed / total).
  double calculateCompletionRate(PerformanceSnapshot snapshot) {
    if (snapshot.allTasks.isEmpty) return 0.0;

    final completed = snapshot.allTasks.where((t) => t.isCompleted).length;
    return completed / snapshot.allTasks.length;
  }

  int countOverdue(PerformanceSnapshot snapshot) {
    return snapshot.allTasks.where((t) => t.isOverdue && !t.isCompleted).length;
  }
}
