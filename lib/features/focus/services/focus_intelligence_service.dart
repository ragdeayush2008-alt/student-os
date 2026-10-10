import '../../../core/services/streak_service.dart';
import '../../tasks/task_controller.dart';
import '../controller/focus_controller.dart';
import '../controller/focus_guard_controller.dart';
import '../data/models/focus_guard_models.dart';
import '../data/models/focus_mission.dart';

class FocusStatistics {
  const FocusStatistics({
    required this.todayFocusedMinutes,
    required this.totalFocusedMinutes,
    required this.completedSessionsCount,
    required this.interruptedSessionsCount,
    required this.totalBlockedAttempts,
    this.mostFrequentlyBlockedApp,
    required this.averageSessionDurationMinutes,
    required this.currentStreak,
  });

  final int todayFocusedMinutes;
  final int totalFocusedMinutes;
  final int completedSessionsCount;
  final int interruptedSessionsCount;
  final int totalBlockedAttempts;
  final String? mostFrequentlyBlockedApp;
  final int averageSessionDurationMinutes;
  final int currentStreak;
}

class FocusIntelligenceService {
  FocusIntelligenceService._();
  static final FocusIntelligenceService instance = FocusIntelligenceService._();

  FocusStatistics computeStatistics({
    List<FocusSession>? sessions,
    List<BlockedAppAttempt>? blockedAttempts,
    int? currentStreak,
  }) {
    // Focus analytics count Focus Guard (protected/focusDim) sessions only;
    // plain Timer/Stopwatch sessions are excluded from the analytics surface.
    final sList = (sessions ?? FocusController.instance.sessions)
        .where((s) => s.mode == FocusMode.focusGuard)
        .toList();
    final bList = blockedAttempts ?? FocusGuardController.instance.blockedAttempts;
    final streak = currentStreak ?? StreakService.instance.currentStreak;

    final now = DateTime.now();
    var todayMinutes = 0;
    var totalMinutes = 0;
    var completed = 0;
    var interrupted = 0;
    var totalCompletedDurationMinutes = 0;

    for (final s in sList) {
      final dur = s.actualFocusedDuration.inMinutes;
      totalMinutes += dur;

      if (s.startedAt.year == now.year &&
          s.startedAt.month == now.month &&
          s.startedAt.day == now.day) {
        todayMinutes += dur;
      }

      if (s.isComplete) {
        completed++;
        totalCompletedDurationMinutes += dur;
      } else if (s.outcome == SessionOutcome.interrupted ||
          s.outcome == SessionOutcome.partial ||
          s.outcome == SessionOutcome.cancelled) {
        interrupted++;
      }
    }

    final avgDuration = completed > 0 ? (totalCompletedDurationMinutes ~/ completed) : 0;

    // Determine most frequently blocked app
    String? topApp;
    if (bList.isNotEmpty) {
      final counts = <String, int>{};
      for (final a in bList) {
        final key = a.appLabel ?? a.packageName;
        counts[key] = (counts[key] ?? 0) + 1;
      }
      if (counts.isNotEmpty) {
        topApp = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }
    }

    return FocusStatistics(
      todayFocusedMinutes: todayMinutes,
      totalFocusedMinutes: totalMinutes,
      completedSessionsCount: completed,
      interruptedSessionsCount: interrupted,
      totalBlockedAttempts: bList.length,
      mostFrequentlyBlockedApp: topApp,
      averageSessionDurationMinutes: avgDuration,
      currentStreak: streak,
    );
  }

  List<String> generateSuggestions() {
    final stats = computeStatistics();
    final suggestions = <String>[];

    // 1. Task due suggestion
    final activeTasks = TaskController.instance.activeTasks;
    if (activeTasks.isNotEmpty) {
      final todayTask = activeTasks.first;
      suggestions.add(
        'Work on "${todayTask.title}" with a 25-minute Study session.',
      );
    }

    // 2. Today's progress suggestion
    if (stats.todayFocusedMinutes > 0) {
      suggestions.add(
        "You've focused for ${stats.todayFocusedMinutes}m today. Keep the momentum going!",
      );
    } else {
      suggestions.add(
        'Start your first focus session today to build your streak.',
      );
    }

    // 3. Productivity pattern suggestion
    if (stats.completedSessionsCount >= 3 && stats.averageSessionDurationMinutes > 0) {
      suggestions.add(
        'Your most productive sessions average ${stats.averageSessionDurationMinutes} minutes.',
      );
    }

    // 4. Distraction protection reminder
    if (stats.totalBlockedAttempts > 0 && stats.mostFrequentlyBlockedApp != null) {
      suggestions.add(
        'Focus Guard protected you from ${stats.mostFrequentlyBlockedApp} ${stats.totalBlockedAttempts} times.',
      );
    }

    // 5. Streak reminder
    if (stats.currentStreak > 1) {
      suggestions.add(
        'Current focus streak: ${stats.currentStreak} days! Stay consistent.',
      );
    }

    return suggestions;
  }
}
