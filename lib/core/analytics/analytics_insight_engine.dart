import 'performance_snapshot.dart';
import 'academic_analytics_engine.dart';
import 'consistency_analyzer.dart';
import 'task_performance_analyzer.dart';

/// Unified analytics insight engine.
class AnalyticsInsightEngine {
  const AnalyticsInsightEngine();

  List<String> generateInsights(PerformanceSnapshot snapshot) {
    final insights = <String>[];
    const engine = AcademicAnalyticsEngine();
    const consistency = ConsistencyAnalyzer();
    const tasks = TaskPerformanceAnalyzer();

    final lastWeek = const Duration(days: 7);
    final consistencyScore = consistency.calculateConsistency(
      snapshot,
      lastWeek,
    );

    if (consistencyScore > 0.8) {
      insights.add(
        "Your study consistency is excellent (over 80%). Keep it up!",
      );
    } else if (consistencyScore > 0.0) {
      insights.add(
        "Your study consistency is ${(consistencyScore * 100).round()}%. Try to add one more dedicated study day this week.",
      );
    }

    final overdueCount = tasks.countOverdue(snapshot);
    if (overdueCount > 0) {
      insights.add(
        "You have $overdueCount overdue task${overdueCount == 1 ? '' : 's'} that need your attention.",
      );
    }

    final completionRate = engine.calculatePlanCompletionRate(
      snapshot,
      lastWeek,
    );
    final examCount = snapshot.allExams
        .where(
          (e) =>
              !e.isCompleted &&
              e.examDateTime != null &&
              e.examDateTime!.isAfter(DateTime.now()),
        )
        .length;
    final studyMinutes =
        snapshot.allSessions
            .where(
              (s) =>
                  s.isCompleted &&
                  s.startedAt.isAfter(DateTime.now().subtract(lastWeek)),
            )
            .fold<int>(0, (sum, s) => sum + s.durationSec) ~/
        60;

    if (examCount > 0 && studyMinutes < 30) {
      insights.add(
        'Upcoming exams found with low recent study time — consider planning study sessions.',
      );
    }

    if (completionRate < 0.5 && overdueCount > 0) {
      insights.add(
        "Plan completion is below 50% with overdue work — focus on critical tasks first.",
      );
    } else if (completionRate >= 0.8) {
      insights.add("Strong task execution this week.");
    }

    return insights;
  }
}
