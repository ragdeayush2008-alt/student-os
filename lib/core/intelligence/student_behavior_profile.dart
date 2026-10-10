import '../analytics/performance_snapshot.dart';

import 'package:meta/meta.dart';

import '../analytics/consistency_analyzer.dart';

/// Derived student behavior profile from existing data.
/// No fake data. Falls back gracefully when insufficient history.
@immutable
class StudentBehaviorProfile {
  const StudentBehaviorProfile({
    this.averageSessionMinutes = 0,
    this.medianSessionMinutes = 0,
    this.consistency30Day = 0.0,
    this.planCompletionRate30Day = 0.0,
    this.overdueRate = 0.0,
    this.subjectDistribution = const {},
    this.preferredBudgetMinutes = 30,
    this.recentStudyMinutes = 0,
    this.hasSufficientData = false,
    this.recommendationReason = '',
  });

  final int averageSessionMinutes;
  final int medianSessionMinutes;
  final double consistency30Day;
  final double planCompletionRate30Day;
  final double overdueRate;
  final Map<String, int> subjectDistribution;
  final int preferredBudgetMinutes;
  final int recentStudyMinutes;
  final bool hasSufficientData;
  final String recommendationReason;

  factory StudentBehaviorProfile.fromSnapshot(PerformanceSnapshot snapshot) {
    final sessions = snapshot.allSessions.where((s) => s.isCompleted).toList();
    final hasData = sessions.isNotEmpty || snapshot.allTasks.isNotEmpty;

    if (!hasData) {
      return const StudentBehaviorProfile(hasSufficientData: false);
    }

    final durations = sessions.map((s) => s.durationSec ~/ 60).toList()..sort();

    if (durations.length < 2) {
      return StudentBehaviorProfile(
        hasSufficientData: true,
        averageSessionMinutes: durations.isNotEmpty ? durations.first : 0,
        medianSessionMinutes: durations.isNotEmpty ? durations.first : 0,
        recommendationReason: 'Based on ${durations.length} session(s).',
      );
    }
    final avg = durations.isNotEmpty
        ? (durations.reduce((a, b) => a + b) / durations.length).round()
        : 0;
    final median = durations.isNotEmpty ? durations[durations.length ~/ 2] : 0;

    final consistency = const ConsistencyAnalyzer().calculateConsistency(
      snapshot,
      const Duration(days: 30),
    );

    final tasks = snapshot.allTasks;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final planRate = tasks.isNotEmpty ? completedTasks / tasks.length : 0.0;

    final overdue = tasks.where((t) => t.isOverdue && !t.isCompleted).length;
    final overdueRate = tasks.isNotEmpty ? overdue / tasks.length : 0.0;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final recentStudy =
        snapshot.allSessions
            .where((s) => s.isCompleted && s.startedAt.isAfter(cutoff))
            .fold<int>(0, (sum, s) => sum + s.durationSec) ~/
        60;

    // Budget preference: if student consistently completes 30+ min sessions, suggest 30; else 20 or 15
    final preferredBudget = avg >= 25
        ? 30
        : avg >= 15
        ? 20
        : 15;

    return StudentBehaviorProfile(
      averageSessionMinutes: avg,
      medianSessionMinutes: median,
      consistency30Day: consistency,
      planCompletionRate30Day: planRate,
      overdueRate: overdueRate,
      subjectDistribution: const {},
      preferredBudgetMinutes: preferredBudget,
      recentStudyMinutes: recentStudy,
      hasSufficientData: true,
      recommendationReason:
          'Based on ${durations.length} completed session(s). Avg ${avg}m, consistency ${(consistency * 100).round()}%.',
    );
  }
}
