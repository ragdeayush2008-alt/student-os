import 'performance_snapshot.dart';

/// Analyzes historical consistency of study activity.
class ConsistencyAnalyzer {
  const ConsistencyAnalyzer();

  /// Calculates consistency percentage over a given window.
  double calculateConsistency(PerformanceSnapshot snapshot, Duration window) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int activeDays = 0;
    int totalDays = window.inDays;

    for (int i = 0; i < totalDays; i++) {
      final date = today.subtract(Duration(days: i));
      if (snapshot.studyDates.contains(date)) {
        activeDays++;
      }
    }

    return totalDays > 0 ? activeDays / totalDays : 0.0;
  }
}
