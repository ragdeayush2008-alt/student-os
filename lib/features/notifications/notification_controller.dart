import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/task.dart';
import '../../data/models/exam.dart';
import '../../data/models/achievement.dart';
import '../../data/models/level.dart';
import '../../data/models/study_session.dart';
import '../../data/models/leaderboard_entry.dart';
import '../auth/auth_service.dart';
import '../preferences/user_preferences_controller.dart';
import '../focus/data/models/focus_mission.dart';

/// Available filter categories for Notification Center.
enum NotificationFilter {
  all('All'),
  unread('Unread'),
  tasks('Tasks'),
  exams('Exams'),
  focus('Focus & Study'),
  progression('Progression');

  const NotificationFilter(this.label);
  final String label;
}

/// Central controller for Student OS Notification & Activity Center 2.0.
///
/// Features:
/// - Singleton ChangeNotifier pattern following Student OS architecture.
/// - Offline-first user-scoped persistence via [StorageService].
/// - Deterministic notification IDs preventing duplicate entries.
/// - Respects user notification category preferences.
/// - Full user isolation on auth session changes.
/// - Unread state tracking and batch actions (mark read, mark all read, delete).
class NotificationController extends ChangeNotifier {
  NotificationController._();

  static final NotificationController instance = NotificationController._();

  static const String _notificationsKey = 'notifications_v2';

  List<AppNotification> _notifications = [];
  final Set<String> _seenIds = {};
  NotificationFilter _selectedFilter = NotificationFilter.all;
  bool _loaded = false;
  bool _isLoading = false;
  bool _disposed = false;
  String? _errorMessage;

  // ─── Getters ────────────────────────────────────────────────────────────

  /// All notifications sorted newest first.
  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);

  /// Active filter.
  NotificationFilter get selectedFilter => _selectedFilter;

  /// Whether data has loaded from local storage.
  bool get isLoaded => _loaded;

  /// Whether data is currently loading.
  bool get isLoading => _isLoading;

  /// Error message if any operation failed.
  String? get errorMessage => _errorMessage;

  /// Total count of unread notifications.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Whether there are any unread notifications.
  bool get hasUnread => unreadCount > 0;

  /// Total notification count.
  int get totalCount => _notifications.length;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  /// Notifications filtered by the currently selected filter.
  List<AppNotification> get filteredNotifications {
    return _notifications.where((n) {
      switch (_selectedFilter) {
        case NotificationFilter.all:
          return true;
        case NotificationFilter.unread:
          return !n.isRead;
        case NotificationFilter.tasks:
          return n.isTask;
        case NotificationFilter.exams:
          return n.isExam;
        case NotificationFilter.focus:
          return n.isStudyOrFocus;
        case NotificationFilter.progression:
          return n.isAchievement ||
              n.isProgression ||
              n.isStreak ||
              n.isLeaderboard ||
              n.isReward;
      }
    }).toList();
  }

  // ─── Grouped by Date (for UI grouping) ──────────────────────────────────

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Notifications from today.
  List<AppNotification> get todayNotifications {
    final today = _dateOnly(DateTime.now());
    return filteredNotifications
        .where((n) => _dateOnly(n.createdAt) == today)
        .toList();
  }

  /// Notifications from yesterday.
  List<AppNotification> get yesterdayNotifications {
    final yesterday =
        _dateOnly(DateTime.now().subtract(const Duration(days: 1)));
    return filteredNotifications
        .where((n) => _dateOnly(n.createdAt) == yesterday)
        .toList();
  }

  /// Notifications older than yesterday.
  List<AppNotification> get olderNotifications {
    final yesterday =
        _dateOnly(DateTime.now().subtract(const Duration(days: 1)));
    return filteredNotifications
        .where((n) => _dateOnly(n.createdAt).isBefore(yesterday))
        .toList();
  }

  // ─── Lifecycle & Storage ────────────────────────────────────────────────

  /// Resets in-memory state on user logout or session switch.
  void clearData() {
    _notifications.clear();
    _seenIds.clear();
    _selectedFilter = NotificationFilter.all;
    _loaded = false;
    _isLoading = false;
    _errorMessage = null;
    if (!_disposed) notifyListeners();
  }

  /// Loads notifications from user-scoped local storage.
  Future<void> load() async {
    if (_isLoading) return;
    final uid = _userId;
    if (uid == null) {
      // Unknown identity: stay side-effect-free (no flags, no notify) so
      // this is safe to call from initState/build. Memory state remains
      // authoritative until login; listeners rebuild on the next real event.
      return;
    }
    _isLoading = true;
    _errorMessage = null;

    try {
      final list = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _notificationsKey,
      );

      _notifications.clear();
      _seenIds.clear();

      if (list != null) {
        for (final raw in list) {
          try {
            final notif = AppNotification.fromJson(raw);
            if (!_seenIds.contains(notif.id)) {
              _notifications.add(notif);
              _seenIds.add(notif.id);
            }
          } catch (e) {
            // Ignore corrupted record
          }
        }
        // Sort descending by createdAt
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _loaded = true;
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Persists current notifications to storage.
  Future<void> _save() async {
    try {
      final uid = _userId;
      if (uid == null) return;
      await StorageService.instance.saveJsonList(
        userId: uid,
        key: _notificationsKey,
        list: _notifications.map((n) => n.toJson()).toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationController] Save error: $e');
      }
    }
  }

  // ─── Filter Selection ───────────────────────────────────────────────────

  void setFilter(NotificationFilter filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    if (!_disposed) notifyListeners();
  }

  // ─── Core Mutations ─────────────────────────────────────────────────────

  /// Adds a notification idempotently.
  ///
  /// Returns `true` if added, `false` if rejected due to deduplication or preferences.
  Future<bool> addNotification(AppNotification notification) async {
    // 1. Preference check
    if (!_isTypeEnabled(notification.type)) {
      return false;
    }

    // 2. Deterministic deduplication check
    if (_seenIds.contains(notification.id)) {
      return false;
    }

    _seenIds.add(notification.id);
    _notifications.insert(0, notification);

    // Keep max 200 items in activity history
    if (_notifications.length > 200) {
      final removed = _notifications.removeLast();
      _seenIds.remove(removed.id);
    }

    if (!_disposed) notifyListeners();
    await _save();
    return true;
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0) return;
    if (_notifications[index].isRead) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    if (!_disposed) notifyListeners();
    await _save();
  }

  /// Marks all unread notifications as read.
  Future<void> markAllAsRead() async {
    if (!hasUnread) return;

    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();

    if (!_disposed) notifyListeners();
    await _save();
  }

  /// Deletes a specific notification.
  Future<void> deleteNotification(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0) return;

    _notifications.removeAt(index);
    _seenIds.remove(notificationId);

    if (!_disposed) notifyListeners();
    await _save();
  }

  /// Clears all notifications for the current user.
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _seenIds.clear();

    if (!_disposed) notifyListeners();
    await _save();
  }

  // ─── Preference Verification ────────────────────────────────────────────

  bool _isTypeEnabled(NotificationType type) {
    final prefs = UserPreferencesController.instance;
    switch (type) {
      case NotificationType.taskDue:
      case NotificationType.taskOverdue:
      case NotificationType.taskCompleted:
        return prefs.taskNotificationsEnabled;
      case NotificationType.examUpcoming:
      case NotificationType.examPreparation:
      case NotificationType.examCompleted:
        return prefs.examNotificationsEnabled;
      case NotificationType.studyCompleted:
        return prefs.studyNotificationsEnabled;
      case NotificationType.focusCompleted:
        return prefs.focusNotificationsEnabled;
      case NotificationType.achievementUnlocked:
        return prefs.achievementNotificationsEnabled;
      case NotificationType.levelUp:
      case NotificationType.xpMilestone:
        return prefs.progressionNotificationsEnabled;
      case NotificationType.streakMilestone:
      case NotificationType.streakRisk:
        return prefs.streakNotificationsEnabled;
      case NotificationType.leaderboardMovement:
        return prefs.leaderboardNotificationsEnabled;
      case NotificationType.rewardUnlocked:
      case NotificationType.rewardAvailable:
      case NotificationType.dailyPlan:
      case NotificationType.goalReached:
      case NotificationType.system:
        return true;
    }
  }

  // ─── Event Producers & Handlers ─────────────────────────────────────────

  /// Task completed event.
  Future<void> onTaskCompleted(StudentTask task) async {
    final id = NotificationIds.taskCompletedKey(task.id);
    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.taskCompleted,
        title: 'Task Completed',
        body: 'Completed "${task.title}". Great work!',
        createdAt: DateTime.now(),
        userId: _userId ?? '',
        entityId: task.id,
        route: '/tasks',
        priority: NotificationPriority.normal,
        metadata: {'taskId': task.id, 'title': task.title},
      ),
    );
  }

  /// Evaluates tasks for overdue or due-today notifications.
  Future<void> evaluateTasks(List<StudentTask> tasks) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    for (final task in tasks) {
      if (task.isCompleted) continue;

      if (task.isOverdue) {
        final id = NotificationIds.taskOverdueKey(task.id, todayStr);
        await addNotification(
          AppNotification(
            id: id,
            type: NotificationType.taskOverdue,
            title: 'Task Overdue',
            body: '"${task.title}" is overdue and needs your attention.',
            createdAt: now,
            userId: _userId ?? '',
            entityId: task.id,
            route: '/tasks',
            priority: NotificationPriority.high,
            metadata: {'taskId': task.id, 'title': task.title},
          ),
        );
      } else if (task.isDueToday) {
        final id = NotificationIds.taskDueKey(task.id, todayStr);
        await addNotification(
          AppNotification(
            id: id,
            type: NotificationType.taskDue,
            title: 'Task Due Today',
            body: '"${task.title}" is due today.',
            createdAt: now,
            userId: _userId ?? '',
            entityId: task.id,
            route: '/tasks',
            priority: NotificationPriority.normal,
            metadata: {'taskId': task.id, 'title': task.title},
          ),
        );
      }
    }
  }

  /// Evaluates exams for upcoming milestones.
  Future<void> evaluateUpcomingExams(List<StudentExam> exams) async {
    final now = DateTime.now();
    final today = _dateOnly(now);

    for (final exam in exams) {
      if (!exam.isUpcoming || exam.examDateTime == null) continue;

      final examDay = _dateOnly(exam.examDateTime!);
      final daysUntil = examDay.difference(today).inDays;

      if (daysUntil <= 7 && daysUntil >= 0) {
        final id = NotificationIds.examUpcomingKey(exam.id, daysUntil);
        final title = daysUntil == 0
            ? 'Exam Today: ${exam.title}'
            : daysUntil == 1
                ? 'Exam Tomorrow: ${exam.title}'
                : 'Exam in $daysUntil Days: ${exam.title}';
        final priority = daysUntil <= 2
            ? NotificationPriority.high
            : NotificationPriority.normal;

        await addNotification(
          AppNotification(
            id: id,
            type: NotificationType.examUpcoming,
            title: title,
            body: 'Preparation review for ${exam.title}. Stay focused!',
            createdAt: now,
            userId: _userId ?? '',
            entityId: exam.id,
            route: '/exams',
            priority: priority,
            metadata: {'examId': exam.id, 'daysUntil': daysUntil},
          ),
        );
      }
    }
  }

  /// Exam completed event.
  Future<void> onExamCompleted(StudentExam exam) async {
    final id = NotificationIds.examCompletedKey(exam.id);
    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.examCompleted,
        title: 'Exam Completed',
        body: 'Finished "${exam.title}". Congratulations on completing it!',
        createdAt: DateTime.now(),
        userId: _userId ?? '',
        entityId: exam.id,
        route: '/exams',
        priority: NotificationPriority.normal,
        metadata: {'examId': exam.id},
      ),
    );
  }

  /// Study session completed event.
  Future<void> onStudyCompleted(StudySession session) async {
    final id = NotificationIds.studyCompletedKey(session.id);
    final minutes = session.duration.inMinutes;
    final durationStr =
        minutes > 0 ? '${minutes}m' : '${session.duration.inSeconds}s';
    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.studyCompleted,
        title: 'Study Session Complete',
        body: 'Completed $durationStr of study in ${session.subject}.',
        createdAt: DateTime.now(),
        userId: _userId ?? '',
        entityId: session.id,
        route: '/study',
        priority: NotificationPriority.normal,
        metadata: {
          'sessionId': session.id,
          'duration': session.duration.inMinutes,
        },
      ),
    );
  }

  /// Focus session completed event.
  Future<void> onFocusCompleted(FocusSession session) async {
    final id = NotificationIds.focusCompletedKey(session.id);
    final minutes = session.effectiveElapsed.inMinutes;
    final durationStr =
        minutes > 0 ? '${minutes}m' : '${session.effectiveElapsed.inSeconds}s';
    final subject = session.subjectName ?? 'Focus';
    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.focusCompleted,
        title: 'Focus Mission Complete',
        body: 'Logged $durationStr of deep focus on $subject.',
        createdAt: DateTime.now(),
        userId: _userId ?? '',
        entityId: session.id,
        route: '/focus-center',
        priority: NotificationPriority.normal,
        metadata: {'sessionId': session.id, 'minutes': minutes},
      ),
    );
  }

  /// Achievement unlocked event.
  Future<void> onAchievementUnlocked(Achievement achievement) async {
    final id = NotificationIds.achievementUnlockedKey(achievement.id);
    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.achievementUnlocked,
        title: 'Achievement Unlocked!',
        body: '${achievement.title} — ${achievement.description}',
        createdAt: DateTime.now(),
        userId: _userId ?? '',
        entityId: achievement.id,
        route: '/achievements',
        priority: NotificationPriority.normal,
        metadata: {'achievementId': achievement.id, 'xp': achievement.xpReward},
      ),
    );
  }

  /// Level up event.
  Future<void> onLevelUp(StudentLevel level) async {
    final id = NotificationIds.levelUpKey(level.level);
    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.levelUp,
        title: 'Level Up! Reached Level ${level.level}',
        body: 'You reached Level ${level.level}. Keep progressing!',
        createdAt: DateTime.now(),
        userId: _userId ?? '',
        entityId: level.level.toString(),
        route: '/progress',
        priority: NotificationPriority.normal,
        metadata: {'level': level.level},
      ),
    );
  }

  /// Streak milestone event.
  Future<void> onStreakMilestone(int days) async {
    final id = NotificationIds.streakMilestoneKey(days);
    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.streakMilestone,
        title: '$days-Day Streak Reached!',
        body:
            'Incredible dedication! You have maintained a $days-day active streak.',
        createdAt: DateTime.now(),
        userId: _userId ?? '',
        entityId: days.toString(),
        route: '/streak',
        priority: NotificationPriority.normal,
        metadata: {'days': days},
      ),
    );
  }

  /// Streak at risk event.
  Future<void> evaluateStreakRisk(int currentStreak, bool activityToday) async {
    if (currentStreak < 1 || activityToday) return;

    final now = DateTime.now();
    // Only warn in late afternoon/evening
    if (now.hour < 18) return;

    final todayStr = '${now.year}-${now.month}-${now.day}';
    final id = NotificationIds.streakRiskKey(todayStr);

    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.streakRisk,
        title: 'Streak at Risk!',
        body:
            'Complete a task or study session today to preserve your $currentStreak-day streak.',
        createdAt: now,
        userId: _userId ?? '',
        entityId: currentStreak.toString(),
        route: '/streak',
        priority: NotificationPriority.high,
        metadata: {'currentStreak': currentStreak},
      ),
    );
  }

  /// Leaderboard rank movement event.
  Future<void> onLeaderboardRankChanged(
    LeaderboardPeriod period,
    int oldRank,
    int newRank,
  ) async {
    if (oldRank <= newRank || oldRank <= 0 || newRank <= 0) return;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final id = NotificationIds.leaderboardMovementKey(
      period.name,
      newRank,
      todayStr,
    );

    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.leaderboardMovement,
        title: 'Leaderboard Rank Up!',
        body:
            'You moved up from #$oldRank to #$newRank in ${period.label}!',
        createdAt: now,
        userId: _userId ?? '',
        entityId: newRank.toString(),
        route: '/leaderboard',
        priority: NotificationPriority.normal,
        metadata: {
          'period': period.name,
          'oldRank': oldRank,
          'newRank': newRank,
        },
      ),
    );
  }

  /// Reward unlocked event.
  Future<void> onRewardUnlocked(String rewardId, String rewardTitle) async {
    final id = NotificationIds.rewardUnlockedKey(rewardId);
    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.rewardUnlocked,
        title: 'Reward Unlocked',
        body: 'You unlocked "$rewardTitle"! View it in your rewards inventory.',
        createdAt: DateTime.now(),
        userId: _userId ?? '',
        entityId: rewardId,
        route: '/rewards',
        priority: NotificationPriority.normal,
        metadata: {'rewardId': rewardId},
      ),
    );
  }

  /// Daily plan ready event.
  Future<void> onDailyPlanReady() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final id = NotificationIds.dailyPlanKey(todayStr);

    await addNotification(
      AppNotification(
        id: id,
        type: NotificationType.dailyPlan,
        title: "Today's Plan Ready",
        body: 'Your study plan and priorities are ready for today.',
        createdAt: now,
        userId: _userId ?? '',
        route: '/plan',
        priority: NotificationPriority.normal,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
