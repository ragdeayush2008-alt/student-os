import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/sync/sync_engine.dart';
import '../../data/models/achievement.dart';
import '../../data/models/xp_event.dart';
import '../auth/auth_service.dart';
import '../exams/exam_controller.dart';
import '../focus/controller/focus_controller.dart';
import '../focus/data/models/focus_mission.dart';
import '../progression/progression_controller.dart';
import '../resources/resource_controller.dart';
import '../study/study_controller.dart';
import '../subjects/subject_controller.dart';
import '../tasks/task_controller.dart';
import '../notifications/notification_controller.dart';

/// Central controller for evaluating, unlocking, and presenting Student OS achievements.
///
/// Features:
/// - Pure derived progress calculation from real controller data.
/// - Deterministic, idempotent unlocking (cannot unlock the same achievement twice).
/// - Automatic XP reward integration with the existing XP engine.
/// - User-scoped local persistence via [StorageService] and cloud sync via [SyncQueue].
class AchievementController extends ChangeNotifier {
  AchievementController._();

  static final AchievementController instance = AchievementController._();

  static const String _earnedKey = 'earned_achievements_v2';
  static const String _tableName = 'student_achievements';

  final Map<String, DateTime> _earnedMap = {};
  bool _loaded = false;
  bool _disposed = false;
  bool _isEvaluating = false;

  /// Optional callback for newly unlocked achievements (used to trigger celebrations).
  ValueChanged<Achievement>? onAchievementUnlocked;

  // ─── Getters ────────────────────────────────────────────────────────────

  /// All earned achievement IDs.
  Set<String> get earnedIds => Set.unmodifiable(_earnedMap.keys);

  /// Whether controller data has been restored from storage.
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  /// Total count of unlocked achievements.
  int get earnedCount => _earnedMap.length;

  /// Total count of all catalog achievements.
  int get totalCount => AchievementCatalog.achievements.length;

  /// Overall completion ratio 0.0–1.0.
  double get completionRatio =>
      totalCount > 0 ? (earnedCount / totalCount).clamp(0.0, 1.0) : 0.0;

  /// Returns live presentation entries for all catalog achievements.
  List<AchievementEntry> get entries {
    return AchievementCatalog.achievements.map((achievement) {
      final isUnlocked = _earnedMap.containsKey(achievement.id);
      final unlockedAt = _earnedMap[achievement.id];
      final currentProgress = _computeProgress(achievement);

      return AchievementEntry(
        achievement: achievement,
        isUnlocked: isUnlocked,
        currentProgress: currentProgress,
        unlockedAt: unlockedAt,
      );
    }).toList();
  }

  /// Returns only earned/unlocked achievement entries.
  List<AchievementEntry> get earnedEntries =>
      entries.where((e) => e.isUnlocked).toList();

  /// Returns only locked achievement entries.
  List<AchievementEntry> get lockedEntries =>
      entries.where((e) => !e.isUnlocked).toList();

  /// Returns recently unlocked achievement entries (most recent first).
  List<AchievementEntry> get recentlyUnlocked {
    final earned = earnedEntries;
    earned.sort((a, b) {
      final aTime = a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return earned;
  }

  /// Filter entries by category.
  List<AchievementEntry> entriesForCategory(AchievementCategory category) {
    if (category == AchievementCategory.all) return entries;
    return entries.where((e) => e.achievement.category == category).toList();
  }

  // ─── Progress Computation ────────────────────────────────────────────────

  int _computeProgress(Achievement achievement) {
    switch (achievement.id) {
      // Tasks
      case 'first_task':
      case 'tasks_10':
      case 'tasks_50':
        return TaskController.instance.completedTasks.length;

      // Study
      case 'first_study':
      case 'study_10':
      case 'study_50':
        return StudyController.instance.completedSessions.length;

      // Exams
      case 'first_exam':
        return ExamController.instance.exams.where((e) => e.isCompleted).length;

      // Focus
      case 'first_focus':
      case 'focus_10':
      case 'focus_50':
        return FocusController.instance.sessions
            .where((s) => s.outcome == SessionOutcome.completed)
            .length;

      case 'focus_60_mins':
        return FocusController.instance.sessions
            .fold<int>(0, (sum, s) => sum + s.focusDuration.inMinutes);

      // Streak
      case 'streak_3':
      case 'streak_7':
      case 'streak_14':
      case 'streak_30':
        return StreakService.instance.currentStreak;

      // Progression
      case 'level_5':
      case 'level_10':
      case 'level_25':
        return ProgressionController.instance.currentLevel.level;

      case 'xp_1000':
        return ProgressionController.instance.totalXp;

      // Goals
      case 'daily_task_goal':
        return TaskController.instance.todayCompletedCount >= 1 ? 1 : 0;

      // Exploration
      case 'first_subject':
        return SubjectController.instance.subjects.length;

      case 'first_resource':
        return ResourceController.instance.resources.length;

      default:
        return 0;
    }
  }

  // ─── Loading & Persistence ───────────────────────────────────────────────

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      // Side-effect-free: safe from initState/build; memory stays authoritative.
      _loaded = true;
      return;
    }
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _earnedKey,
    );

    _earnedMap.clear();
    if (list != null) {
      for (final item in list) {
        final id = item['id'] as String?;
        final unlockedAtStr = item['unlockedAt'] as String?;
        if (id != null) {
          _earnedMap[id] = unlockedAtStr != null
              ? DateTime.tryParse(unlockedAtStr) ?? DateTime.now()
              : DateTime.now();
        }
      }
    }

    _loaded = true;
    if (!_disposed) notifyListeners();

    // Evaluate live progress on load
    await evaluate();
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    final list = _earnedMap.entries
        .map((e) => {'id': e.key, 'unlockedAt': e.value.toIso8601String()})
        .toList();

    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _earnedKey,
      list: list,
    );
  }

  /// Clears in-memory achievement state on logout.
  void clearData() {
    _earnedMap.clear();
    _loaded = false;
    _isEvaluating = false;
    if (!_disposed) notifyListeners();
  }

  // ─── Evaluation Engine ───────────────────────────────────────────────────

  /// Evaluates all achievement conditions against live controller data.
  ///
  /// Idempotent: already unlocked achievements are never re-evaluated or re-awarded.
  /// Newly unlocked achievements award XP through [ProgressionController] if configured.
  Future<List<Achievement>> evaluate() async {
    if (_isEvaluating) return const [];
    _isEvaluating = true;

    final newlyEarned = <Achievement>[];

    try {
      for (final achievement in AchievementCatalog.achievements) {
        if (_earnedMap.containsKey(achievement.id)) continue;

        final currentProgress = _computeProgress(achievement);
        if (currentProgress >= achievement.targetValue) {
          final now = DateTime.now();
          _earnedMap[achievement.id] = now;
          newlyEarned.add(achievement);

          // Award XP bonus via existing ProgressionController
          if (achievement.xpReward > 0) {
            final xpEvent = XpEvent(
              id: 'achievement_reward_${achievement.id}',
              type: XpEventType.goalMilestone,
              amount: achievement.xpReward,
              timestamp: now,
              reason: 'Achievement Unlocked: ${achievement.title}',
            );
            await ProgressionController.instance.recordEvent(xpEvent);
          }

          // Queue sync to cloud
          await SyncQueue.instance.enqueue(
            table: _tableName,
            recordId: achievement.id,
            type: SyncOperationType.upsert,
            payload: {
              'achievement_id': achievement.id,
              'unlocked_at': now.toIso8601String(),
            },
          );
        }
      }

      if (newlyEarned.isNotEmpty) {
        await _save();
        SyncEngine.instance.synchronize();
        if (!_disposed) notifyListeners();

        // Fire callback for celebrations & notification
        for (final achievement in newlyEarned) {
          NotificationController.instance.onAchievementUnlocked(achievement);
          onAchievementUnlocked?.call(achievement);
        }
      }
    } finally {
      _isEvaluating = false;
    }

    return newlyEarned;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
