import 'package:flutter/foundation.dart';

import '../../features/tasks/task_controller.dart';
import '../../features/study/study_controller.dart';

/// Derives the student's study streak from existing task and study data.
///
/// A day counts toward the streak when the student completes at least one
/// meaningful academic activity:
/// - completing a task (has [completedAt])
/// - completing a study session (isCompleted)
///
/// This service is purely derived — it reads from existing controllers and
/// computes streak values on demand. No additional persistence is needed.
class StreakService extends ChangeNotifier {
  StreakService._();

  static final StreakService instance = StreakService._();

  bool _disposed = false;

  /// Consecutive days (ending today) with task completion OR study session.
  int get currentStreak => _computeCurrentStreak();

  /// The longest-ever consecutive run of activity days.
  int get bestStreak => _computeBestStreak();

  /// Whether the student has completed meaningful activity today.
  bool get activityToday => _hasActivityToday();

  /// Normalized date-only helper.
  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Today at midnight.
  DateTime get _today => _dateOnly(DateTime.now());

  /// Recomputes streak values and notifies listeners.
  ///
  /// Call this after task completion, study session completion, or any
  /// activity that could affect the streak.
  void refresh() {
    if (!_disposed) notifyListeners();
  }

  // ─── Current Streak ──────────────────────────────────────────────────

  int _computeCurrentStreak() {
    final tasks = TaskController.instance.tasks;
    final sessions = StudyController.instance.sessions;
    final today = _today;

    var streak = 0;
    for (var offset = 0; offset < 365; offset++) {
      final day = today.subtract(Duration(days: offset));
      final hasTask = tasks.any(
        (t) =>
            t.isCompleted &&
            t.completedAt != null &&
            _dateOnly(t.completedAt!) == day,
      );
      final hasStudy = sessions.any((s) => s.isCompleted && s.date == day);
      if (hasTask || hasStudy) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── Best Streak ─────────────────────────────────────────────────────

  int _computeBestStreak() {
    final tasks = TaskController.instance.tasks;
    final sessions = StudyController.instance.sessions;

    final activeDates = <DateTime>{};
    for (final t in tasks) {
      if (t.isCompleted && t.completedAt != null) {
        activeDates.add(_dateOnly(t.completedAt!));
      }
    }
    for (final s in sessions) {
      if (s.isCompleted) activeDates.add(s.date);
    }
    if (activeDates.isEmpty) return 0;

    final dates = activeDates.toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  // ─── Activity Today ──────────────────────────────────────────────────

  bool _hasActivityToday() {
    final tasks = TaskController.instance.tasks;
    final sessions = StudyController.instance.sessions;
    final today = _today;

    final hasTask = tasks.any(
      (t) =>
          t.isCompleted &&
          t.completedAt != null &&
          _dateOnly(t.completedAt!) == today,
    );
    final hasStudy = sessions.any((s) => s.isCompleted && s.date == today);
    return hasTask || hasStudy;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
