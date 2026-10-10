import 'performance_snapshot.dart';

class SubjectPerformanceAnalyzer {
  const SubjectPerformanceAnalyzer();

  Map<String, int> calculateStudyTimeDistribution(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final now = DateTime.now();
    final limit = now.subtract(window);
    final distribution = <String, int>{};

    for (final session in snapshot.allSessions) {
      if (session.isCompleted &&
          session.startedAt.isAfter(limit) &&
          session.subject.isNotEmpty) {
        final current = distribution[session.subject] ?? 0;
        distribution[session.subject] = current + (session.durationSec ~/ 60);
      }
    }
    return distribution;
  }

  double calculateWorkloadBalance(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final distribution = calculateStudyTimeDistribution(snapshot, window);
    if (distribution.isEmpty) return 0.0;

    final totalTime = distribution.values.fold(0, (sum, val) => sum + val);
    if (totalTime == 0) return 0.0;

    final mean = totalTime / distribution.length;
    final variance =
        distribution.values
            .map((val) => (val - mean) * (val - mean))
            .fold(0.0, (sum, val) => sum + val) /
        distribution.length;

    final cv = mean > 0 ? (variance / (mean * mean)) : 0.0;
    return (1.0 / (1.0 + cv)).clamp(0.0, 1.0);
  }
}
