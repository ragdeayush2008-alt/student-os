import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/xp_engine.dart';
import '../../core/sync/sync_engine.dart';
import '../../data/models/level.dart';
import '../../data/models/xp_event.dart';
import '../../data/models/task.dart';
import '../auth/auth_service.dart';
import '../notifications/notification_controller.dart';
import 'achievement_controller.dart';

import 'package:flutter/foundation.dart';

/// Central controller for student XP, levels, and progression.
///
/// Follows the established Student OS architecture pattern:
/// - Singleton ChangeNotifier pattern
/// - User-scoped persistence via StorageService
/// - Deterministic event ledger preventing duplicate rewards
/// - Pure derived level calculations
///
/// Anti-gaming safeguards:
/// - Event ID deduplication (same action cannot award XP twice)
/// - Idempotent event appending
/// - Meaningful activity validation before awarding XP
class ProgressionController extends ChangeNotifier {
  ProgressionController._();

  /// Clears in-memory state without touching persistent storage.
  void clearData() {
    _events.clear();
    _eventIds.clear();
    _spentXp = 0;
    _loaded = false;
    onLevelUp = null;
    onAchievementsUnlocked = null;
    notifyListeners();
  }

  static final ProgressionController instance = ProgressionController._();

  static const _xpEventsKey = 'xp_events';
  static const _spentXpKey = 'spent_xp';

  List<XpEvent> _events = [];
  final Set<String> _eventIds = {};
  int _spentXp = 0;
  bool _loaded = false;
  bool _disposed = false;

  /// Optional callback fired when a level-up occurs.
  /// Wired by the UI layer to show the level-up dialog.
  Function(StudentLevel newLevel)? onLevelUp;

  /// Optional callback fired when achievements are newly unlocked.
  /// Wired by the UI layer to show achievement notifications.
  Function(List<String> achievementTitles)? onAchievementsUnlocked;

  /// All recorded XP events in chronological order (oldest first).
  List<XpEvent> get events => List.unmodifiable(_events);

  /// Recent XP events in reverse chronological order (newest first).
  List<XpEvent> get recentEvents => List.unmodifiable(_events.reversed);

  /// Whether XP data has been loaded from storage.
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  /// Total lifetime XP earned across all events (never decreases, drives Level).
  int get totalXp => _events.fold<int>(0, (sum, event) => sum + event.amount);

  /// Total XP spent on rewards and redemptions.
  int get spentXp => _spentXp;

  /// Current spendable XP available for reward redemption.
  int get spendableXp => (totalXp - _spentXp).clamp(0, 999999999);

  /// Current level derived from total lifetime XP (not spendable XP).
  StudentLevel get currentLevel => LevelCurve.forXp(totalXp);

  /// XP earned today (midnight to midnight).
  int get todayXp {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _events
        .where((e) => e.timestamp.isAfter(todayStart))
        .fold<int>(0, (sum, event) => sum + event.amount);
  }

  /// XP earned this week (Monday to Sunday).
  int get weekXp {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    return _events
        .where((e) => e.timestamp.isAfter(weekStart))
        .fold<int>(0, (sum, event) => sum + event.amount);
  }

  // ─── Loading / Persistence ───────────────────────────────────────────

  /// Loads the XP event ledger from persistent storage.
  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    final uid = _userId;
    if (uid == null) return;
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _xpEventsKey,
    );

    _events = [];
    _eventIds.clear();

    final spentRaw = await StorageService.instance.loadString(
      userId: uid,
      key: _spentXpKey,
    );
    _spentXp = spentRaw != null ? int.tryParse(spentRaw) ?? 0 : 0;

    if (list != null) {
      for (final item in list) {
        try {
          final event = XpEvent.fromJson(item);
          if (_eventIds.add(event.id)) {
            _events.add(event);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[Progression] Error parsing XP event: $e');
          }
        }
      }
      // Sort chronologically
      _events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    _loaded = true;
    if (!_disposed) notifyListeners();
  }

  /// Persists the full event ledger to storage.
  Future<void> _saveEvents() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _xpEventsKey,
      list: _events.map((e) => e.toJson()).toList(),
    );
  }

  /// Persists the spent XP total to storage.
  Future<void> _saveSpentXp() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveString(
      userId: uid,
      key: _spentXpKey,
      value: _spentXp.toString(),
    );
  }

  // ─── XP Spending (Reward Redemption) ─────────────────────────────────

  /// Spends XP for reward redemption.
  ///
  /// Returns true if spending succeeded, false if insufficient spendable XP.
  /// This is called by the RedemptionController during reward redemption.
  /// The spent amount is tracked separately and never reduces the student's level.
  Future<bool> spendXp(int amount) async {
    if (amount <= 0) return false;
    if (spendableXp < amount) return false;

    _spentXp += amount;
    await _saveSpentXp();

    if (!_disposed) {
      notifyListeners();
    }

    return true;
  }

  /// Refunds XP (e.g., if a redemption fails or is cancelled).
  ///
  /// This is a safety mechanism and should rarely be needed in normal flow.
  Future<void> refundXp(int amount) async {
    if (amount <= 0) return;

    _spentXp = (_spentXp - amount).clamp(0, 999999999);
    await _saveSpentXp();

    if (!_disposed) {
      notifyListeners();
    }
  }

  // ─── Core XP Awarding (Anti-Gaming Protected) ─────────────────────────

  /// Appends an XP event to the ledger if not already processed.
  ///
  /// Returns `true` if the event was newly added, `false` if it was a duplicate.
  /// This is the single entry point for all XP awards, ensuring deduplication.
  Future<bool> recordEvent(XpEvent event) async {
    // Anti-gaming check: prevent duplicate event processing
    if (_eventIds.contains(event.id)) {
      return false;
    }

    final previousXp = totalXp;
    _eventIds.add(event.id);
    _events.add(event);
    _events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    await _saveEvents();

    // Queue immutable XP event for cloud sync
    await SyncQueue.instance.enqueue(
      table: 'xp_events',
      recordId: event.id,
      type: SyncOperationType.upsert,
      payload: event.toJson(),
    );
    SyncEngine.instance.synchronize();

    if (!_disposed) {
      notifyListeners();
    }

    // Check for level-up
    final newLevel = currentLevel;
    if (newLevel.justLeveledUp(previousXp)) {
      _onLevelUp(newLevel);
    }

    // Evaluate achievements after XP award
    try {
      final newlyEarned = await AchievementController.instance.evaluate();
      if (newlyEarned.isNotEmpty) {
        onAchievementsUnlocked?.call(newlyEarned.map((a) => a.title).toList());
      }
    } catch (_) {
      // Achievement evaluation should not block XP recording
    }

    // Check weekly consistency (safe from recursion: event ID dedup prevents loops)
    try {
      await _checkWeeklyConsistency();
    } catch (_) {}

    return true;
  }

  /// Hook for level-up handling (notifications, celebrations, etc.).
  void _onLevelUp(StudentLevel newLevel) {
    if (kDebugMode) {
      debugPrint('[Progression] Level up! Reached Level ${newLevel.level}');
    }
    NotificationController.instance.onLevelUp(newLevel);
    onLevelUp?.call(newLevel);
  }

  // ─── High-Level Convenience Methods ──────────────────────────────────

  /// Awards XP for completing a task (idempotent).
  Future<bool> awardTaskCompletion(StudentTask task) async {
    if (!task.isCompleted) return false;
    final event = XpEngine.createTaskCompletionEvent(task);
    return recordEvent(event);
  }

  /// Awards XP for a completed study session (idempotent).
  Future<bool> awardStudySession({
    required String sessionId,
    required int durationSeconds,
    required DateTime startedAt,
    String? subjectId,
  }) async {
    if (durationSeconds < XpEngine.minStudyDurationSeconds) {
      return false; // Too short for XP
    }

    final event = XpEngine.createStudySessionEvent(
      sessionId: sessionId,
      durationSeconds: durationSeconds,
      startedAt: startedAt,
      subjectId: subjectId,
    );
    return recordEvent(event);
  }

  /// Awards XP for completing a syllabus topic (idempotent).
  Future<bool> awardSyllabusTopic({
    required String examId,
    required int topicIndex,
    required String topicTitle,
    required String examTitle,
  }) async {
    final event = XpEngine.createSyllabusCompletionEvent(
      examId: examId,
      topicIndex: topicIndex,
      topicTitle: topicTitle,
      examTitle: examTitle,
    );
    return recordEvent(event);
  }

  /// Awards XP for completing an exam (idempotent).
  Future<bool> awardExamCompletion({
    required String examId,
    required String examTitle,
  }) async {
    final event = XpEngine.createExamCompletionEvent(
      examId: examId,
      examTitle: examTitle,
    );
    return recordEvent(event);
  }

  /// Awards XP for streak milestones (idempotent).
  Future<bool> awardStreakMilestone(int streakDays) async {
    try {
      final event = XpEngine.createStreakMilestoneEvent(streakDays);
      return await recordEvent(event);
    } catch (_) {
      return false; // Not a qualifying streak milestone
    }
  }

  /// Awards XP for weekly consistency (idempotent).
  Future<bool> awardWeeklyConsistency(DateTime weekStart) async {
    final event = XpEngine.createWeeklyConsistencyEvent(weekStart);
    return recordEvent(event);
  }

  /// Checks if the current week qualifies for weekly consistency XP.
  ///
  /// A week qualifies when the student has completed meaningful activity
  /// on at least 5 different days within the current Mon-Sun window.
  Future<void> _checkWeeklyConsistency() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    // Count unique activity days this week from events
    final activityDays = <DateTime>{};
    for (final event in _events) {
      final eventDay = DateTime(
        event.timestamp.year,
        event.timestamp.month,
        event.timestamp.day,
      );
      if (!eventDay.isBefore(weekStart)) {
        activityDays.add(eventDay);
      }
    }

    if (activityDays.length >= 5) {
      await awardWeeklyConsistency(weekStart);
    }
  }

  // ─── Query Helpers ───────────────────────────────────────────────────

  /// Checks if an event has already been recorded.
  bool hasEvent(String eventId) => _eventIds.contains(eventId);

  /// Checks if a task has already been rewarded.
  bool hasTaskReward(String taskId, DateTime? completedAt) {
    final eventId = XpEngine.taskCompletionEventId(taskId, completedAt);
    return _eventIds.contains(eventId);
  }

  /// Checks if a syllabus topic has already been rewarded.
  bool hasSyllabusReward(String examId, int topicIndex) {
    final eventId = XpEngine.syllabusCompletionEventId(examId, topicIndex);
    return _eventIds.contains(eventId);
  }

  /// Checks if an exam completion has already been rewarded.
  bool hasExamReward(String examId) {
    final eventId = XpEngine.examCompletionEventId(examId);
    return _eventIds.contains(eventId);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
