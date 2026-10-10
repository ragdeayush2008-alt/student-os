import 'performance_snapshot.dart';

enum PerformanceTrendDirection {
  improving,
  stable,
  declining,
  insufficientData,
}

class PerformanceTrendResult {
  final double currentValue;
  final double previousValue;
  final double delta;
  final double deltaPercent;
  final PerformanceTrendDirection direction;
  final String explanation;

  const PerformanceTrendResult({
    required this.currentValue,
    required this.previousValue,
    required this.delta,
    required this.deltaPercent,
    required this.direction,
    required this.explanation,
  });
}

class StudyTimeTrend {
  final int currentMinutes;
  final int previousMinutes;
  final double changePercent;
  final PerformanceTrendDirection direction;
  final String explanation;

  const StudyTimeTrend({
    required this.currentMinutes,
    required this.previousMinutes,
    required this.changePercent,
    required this.direction,
    required this.explanation,
  });
}

class CompletionTrend {
  final double currentRate;
  final double previousRate;
  final double delta;
  final PerformanceTrendDirection direction;
  final String explanation;

  const CompletionTrend({
    required this.currentRate,
    required this.previousRate,
    required this.delta,
    required this.direction,
    required this.explanation,
  });
}

class PerformanceTrendAnalyzer {
  const PerformanceTrendAnalyzer();

  StudyTimeTrend analyzeStudyTimeTrend(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final now = DateTime.now();
    final limit = now.subtract(window);

    final currentSessions = snapshot.allSessions
        .where(
          (s) =>
              s.isCompleted &&
              s.startedAt.isAfter(limit) &&
              s.startedAt.isBefore(now),
        )
        .toList();
    final currentMinutes =
        currentSessions.fold<int>(0, (sum, s) => sum + s.durationSec) ~/ 60;

    final prevWindowStart = limit.subtract(window);
    final prevSessions = snapshot.allSessions
        .where(
          (s) =>
              s.isCompleted &&
              s.startedAt.isAfter(prevWindowStart) &&
              s.startedAt.isBefore(limit),
        )
        .toList();
    final previousMinutes =
        prevSessions.fold<int>(0, (sum, s) => sum + s.durationSec) ~/ 60;

    final changePercent = previousMinutes > 0
        ? ((currentMinutes - previousMinutes) / previousMinutes * 100).clamp(
            -100.0,
            100.0,
          )
        : 0.0;

    final direction = _classifyStudyTrend(currentMinutes, previousMinutes);
    String explanation;
    switch (direction) {
      case PerformanceTrendDirection.improving:
        explanation =
            'Study time increased by ${currentMinutes - previousMinutes} minutes compared to the previous period.';
      case PerformanceTrendDirection.stable:
        explanation =
            'Study time is stable at approximately $currentMinutes minutes per period.';
      case PerformanceTrendDirection.declining:
        explanation =
            'Study time decreased by ${previousMinutes - currentMinutes} minutes compared to the previous period.';
      case PerformanceTrendDirection.insufficientData:
        explanation = 'Not enough data to determine study time trend.';
    }

    return StudyTimeTrend(
      currentMinutes: currentMinutes,
      previousMinutes: previousMinutes,
      changePercent: changePercent,
      direction: direction,
      explanation: explanation,
    );
  }

  CompletionTrend analyzeCompletionTrend(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final now = DateTime.now();
    final limit = now.subtract(window);

    final currentTasks = snapshot.allTasks
        .where((t) => t.createdAt.isAfter(limit) && t.createdAt.isBefore(now))
        .toList();
    final currentCompleted = currentTasks.where((t) => t.isCompleted).length;
    final currentRate = currentTasks.isNotEmpty
        ? currentCompleted / currentTasks.length
        : 0.0;

    final prevWindowStart = limit.subtract(window);
    final prevTasks = snapshot.allTasks
        .where(
          (t) =>
              t.createdAt.isAfter(prevWindowStart) &&
              t.createdAt.isBefore(limit),
        )
        .toList();
    final prevCompleted = prevTasks.where((t) => t.isCompleted).length;
    final prevRate = prevTasks.isNotEmpty
        ? prevCompleted / prevTasks.length
        : 0.0;

    final delta = currentRate - prevRate;
    final direction = _classifyCompletionTrend(currentRate, prevRate);

    String explanation;
    switch (direction) {
      case PerformanceTrendDirection.improving:
        explanation =
            'Task completion improved from ${(prevRate * 100).round()}% to ${(currentRate * 100).round()}%.';
      case PerformanceTrendDirection.stable:
        explanation =
            'Task completion is stable at approximately ${(currentRate * 100).round()}%.';
      case PerformanceTrendDirection.declining:
        explanation =
            'Task completion declined from ${(prevRate * 100).round()}% to ${(currentRate * 100).round()}%.';
      case PerformanceTrendDirection.insufficientData:
        explanation = 'Not enough task data to determine completion trend.';
    }

    return CompletionTrend(
      currentRate: currentRate,
      previousRate: prevRate,
      delta: delta,
      direction: direction,
      explanation: explanation,
    );
  }

  PerformanceTrendResult calculateTrend(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final now = DateTime.now();
    final limit = now.subtract(window);

    final currentStudyMinutes =
        snapshot.allSessions
            .where(
              (s) =>
                  s.isCompleted &&
                  s.startedAt.isAfter(limit) &&
                  s.startedAt.isBefore(now),
            )
            .fold<int>(0, (sum, s) => sum + s.durationSec) ~/
        60;

    final prevWindowStart = limit.subtract(window);
    final prevStudyMinutes =
        snapshot.allSessions
            .where(
              (s) =>
                  s.isCompleted &&
                  s.startedAt.isAfter(prevWindowStart) &&
                  s.startedAt.isBefore(limit),
            )
            .fold<int>(0, (sum, s) => sum + s.durationSec) ~/
        60;

    final delta = currentStudyMinutes - prevStudyMinutes;
    final deltaPercent = prevStudyMinutes > 0
        ? (delta / prevStudyMinutes * 100).clamp(-100.0, 100.0)
        : 0.0;

    final direction = _classifyStudyTrend(
      currentStudyMinutes,
      prevStudyMinutes,
    );

    String explanation;
    switch (direction) {
      case PerformanceTrendDirection.improving:
        explanation =
            'Study activity increased by ${delta.abs()} minutes (${deltaPercent.toStringAsFixed(0)}%) compared to the previous period.';
      case PerformanceTrendDirection.stable:
        explanation =
            'Study activity is stable at approximately $currentStudyMinutes minutes per period.';
      case PerformanceTrendDirection.declining:
        explanation =
            'Study activity decreased by ${delta.abs()} minutes (${deltaPercent.toStringAsFixed(0)}%) compared to the previous period.';
      case PerformanceTrendDirection.insufficientData:
        explanation = 'Not enough data to determine trend.';
    }

    return PerformanceTrendResult(
      currentValue: currentStudyMinutes.toDouble(),
      previousValue: prevStudyMinutes.toDouble(),
      delta: delta.toDouble(),
      deltaPercent: deltaPercent,
      direction: direction,
      explanation: explanation,
    );
  }

  Map<String, int> calculateSubjectStudyTimeDistribution(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final now = DateTime.now();
    final limit = now.subtract(window);
    final distribution = <String, int>{};

    for (final session in snapshot.allSessions) {
      if (session.isCompleted &&
          session.startedAt.isAfter(limit) &&
          session.startedAt.isBefore(now) &&
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
    final distribution = calculateSubjectStudyTimeDistribution(
      snapshot,
      window,
    );
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

  List<Map<String, dynamic>> generateConsistencyReport(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final now = DateTime.now();
    final limit = now.subtract(window);
    final activeDays = snapshot.studyDates
        .where((d) => d.isAfter(limit) && d.isBefore(now))
        .toSet();

    final totalDays = window.inDays;
    final activeCount = activeDays.length;
    final consistency = totalDays > 0 ? activeCount / totalDays : 0.0;

    return [
      {
        'activeDays': activeCount,
        'totalDays': totalDays,
        'consistency': consistency,
        'streakDays': _countConsecutiveDays(snapshot, now),
      },
    ];
  }

  int _countConsecutiveDays(PerformanceSnapshot snapshot, DateTime now) {
    if (snapshot.studyDates.isEmpty) return 0;
    final sorted = snapshot.studyDates.toList()..sort((a, b) => b.compareTo(a));

    var streak = 0;
    for (var offset = 0; offset < sorted.length; offset++) {
      final expected = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: offset));
      if (sorted.contains(expected)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  PerformanceTrendDirection _classifyStudyTrend(int current, int previous) {
    if (current == 0 && previous == 0) {
      return PerformanceTrendDirection.insufficientData;
    }
    if (previous == 0) return PerformanceTrendDirection.improving;
    if (current == 0) return PerformanceTrendDirection.declining;

    final ratio = current / previous;
    if (ratio > 1.2) return PerformanceTrendDirection.improving;
    if (ratio < 0.8) return PerformanceTrendDirection.declining;
    return PerformanceTrendDirection.stable;
  }

  PerformanceTrendDirection _classifyCompletionTrend(
    double current,
    double previous,
  ) {
    if (current == 0.0 && previous == 0.0) {
      return PerformanceTrendDirection.insufficientData;
    }
    if (previous == 0.0) return PerformanceTrendDirection.improving;
    if (current == 0.0) return PerformanceTrendDirection.declining;

    final delta = current - previous;
    if (delta > 0.1) return PerformanceTrendDirection.improving;
    if (delta < -0.1) return PerformanceTrendDirection.declining;
    return PerformanceTrendDirection.stable;
  }
}
