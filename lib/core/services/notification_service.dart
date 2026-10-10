import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

/// Structured notification payload for tap handling.
class NotificationPayload {
  const NotificationPayload({required this.type, this.entityId});

  final String type;
  final String? entityId;

  /// Encodes the payload as a string for storage.
  String encode() {
    if (entityId != null) return '$type:$entityId';
    return type;
  }

  /// Decodes a payload string. Returns null if malformed.
  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final colonIndex = raw.indexOf(':');
    if (colonIndex < 0) return NotificationPayload(type: raw);
    return NotificationPayload(
      type: raw.substring(0, colonIndex),
      entityId: raw.substring(colonIndex + 1),
    );
  }

  bool get isTask => type == 'task';
  bool get isExam => type == 'exam';
  bool get isStudyReminder => type == 'study';
  bool get isPlanningReminder => type == 'planning';
  bool get isLevelUp => type == 'level_up';
  bool get isMilestone => type == 'milestone';
  bool get isRewardUnlocked => type == 'reward_unlocked';
  bool get isRewardAvailable => type == 'reward_available';
  bool get isCalendarEvent => type == 'calendar_event';
  bool get isStudentLife => type == 'student_life';
  bool get isSleepSchedule => type == 'sleep_schedule';
  bool get isBriefing => type == 'briefing';
  bool get isReview => type == 'review';
}

/// Deterministic notification ID generator.
///
/// Ensures the same task always maps to the same notification ID,
/// preventing duplicates and enabling clean rescheduling.
abstract final class NotificationIds {
  /// Generates a stable integer ID from a string key.
  ///
  /// Uses a simple hash that fits in 31 bits (safe for Android notification IDs).
  static int fromString(String key) {
    var hash = 0;
    for (var i = 0; i < key.length; i++) {
      hash = ((hash << 5) - hash + key.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  /// Notification ID for an academic calendar event reminder.
  static int calendarEventReminder(String eventId) =>
      fromString('calendar_event_$eventId');

  /// Notification ID for a task reminder.
  static int taskReminder(String taskId) => fromString('task_reminder_$taskId');

  /// Notification ID for the daily study reminder.
  static int studyReminder() => fromString('study_reminder_daily');

  /// Notification ID for the daily planning reminder.
  static int planningReminder() => fromString('planning_reminder_daily');

  /// Notification ID for an exam reminder with a day offset.
  static int examReminder(String examId, int daysBefore) =>
      fromString('exam_reminder_${examId}_$daysBefore');

  /// Notification ID for level up.
  static int levelUp(int level) => fromString('level_up_$level');

  /// Notification ID for milestone unlock.
  static int milestone(String milestoneId) =>
      fromString('milestone_$milestoneId');

  /// Notification ID for reward unlock.
  static int rewardUnlocked(String rewardId) =>
      fromString('reward_unlocked_$rewardId');

  /// Notification ID for reward available.
  static int rewardAvailable(String rewardId) =>
      fromString('reward_available_$rewardId');

  /// Notification ID for a planned session end / transition.
  static int planningBlockEnd(String blockId) =>
      fromString('plan_block_end_$blockId');

  /// Notification ID for a Student Life routine reminder (hydration, meal,
  /// wind-down, bedtime, nap, exercise).
  static int studentLifeReminder(String key) =>
      fromString('student_life_$key');

  // ─── Deterministic String IDs for Activity Center ───────────────────

  static String taskCompletedKey(String taskId) => 'task_completed_$taskId';
  static String taskDueKey(String taskId, String dateStr) =>
      'task_due_${taskId}_$dateStr';
  static String taskOverdueKey(String taskId, String dateStr) =>
      'task_overdue_${taskId}_$dateStr';
  static String examUpcomingKey(String examId, int days) =>
      'exam_upcoming_${examId}_${days}d';
  static String examPrepKey(String examId) => 'exam_prep_$examId';
  static String examCompletedKey(String examId) => 'exam_completed_$examId';
  static String studyCompletedKey(String sessionId) =>
      'study_completed_$sessionId';
  static String focusCompletedKey(String sessionId) =>
      'focus_completed_$sessionId';
  static String achievementUnlockedKey(String achievementId) =>
      'achievement_unlocked_$achievementId';
  static String levelUpKey(int level) => 'level_up_$level';
  static String xpMilestoneKey(int milestone) => 'xp_milestone_$milestone';
  static String streakMilestoneKey(int days) => 'streak_milestone_$days';
  static String streakRiskKey(String dateStr) => 'streak_risk_$dateStr';
  static String leaderboardMovementKey(String period, int rank, String dateStr) =>
      'leaderboard_move_${period}_${rank}_$dateStr';
  static String rewardUnlockedKey(String rewardId) =>
      'reward_unlocked_$rewardId';
  static String rewardAvailableKey(String rewardId) =>
      'reward_available_$rewardId';
  static String dailyPlanKey(String dateStr) => 'daily_plan_$dateStr';
  static String goalReachedKey(String goalId, String dateStr) =>
      'goal_reached_${goalId}_$dateStr';
}

/// Manages local notification scheduling, permissions, and lifecycle.
///
/// Uses `flutter_local_notifications` for real notification delivery.
/// All methods are safe to call even when initialization fails.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionGranted = false;
  bool _initializationFailed = false;

  bool get isInitialized => _initialized;
  bool get hasPermission => _permissionGranted;
  bool get initializationFailed => _initializationFailed;

  /// Initializes the notification service with the real plugin.
  ///
  /// Must be called once at app startup. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone database.
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      // Android initialization settings.
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initSettings = InitializationSettings(android: androidSettings);

      // Initialize the plugin.
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _permissionGranted = await _checkPermission();
      _initialized = true;

      // Check existing permission status.
      _permissionGranted = await _checkPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Initialization failed: $e');
      }
      _initializationFailed = true;
    }
  }

  /// Handles notification tap events.
  void _onNotificationTapped(NotificationResponse response) {
    _dispatchPayload(response.payload);
  }

  /// Central navigation callback for notification taps.
  ///
  /// Registered by the app during initialization so taps can navigate to the
  /// relevant screen without the service depending on app UI code.
  static void Function(NotificationPayload payload)? onNotificationTap;

  void _dispatchPayload(String? raw) {
    final payload = NotificationPayload.decode(raw);
    if (payload == null) return;
    if (kDebugMode) {
      debugPrint(
        '[NotificationService] Notification tapped: ${payload.type}:'
        '${payload.entityId}',
      );
    }
    onNotificationTap?.call(payload);
  }

  /// Reads and dispatches the notification that launched the app, if any.
  ///
  /// Safe to call after widget tree is ready. Returns null if none found.
  Future<void> handleInitialNotification() async {
    if (_initializationFailed) return;
    try {
      final response = await _plugin.getNotificationAppLaunchDetails();
      if (response?.didNotificationLaunchApp ?? false) {
        _dispatchPayload(response!.notificationResponse?.payload);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Launch details failed: $e');
      }
    }
  }

  /// Requests notification permission from the user.
  ///
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    if (_permissionGranted) return true;
    if (_initializationFailed) return false;

    try {
      final status = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _permissionGranted = status ?? false;
      return _permissionGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Permission request failed: $e');
      }
      return false;
    }
  }

  /// Checks the current notification permission status.
  Future<bool> _checkPermission() async {
    try {
      final status = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return status ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Schedules a one-shot notification at [scheduledTime].
  ///
  /// [id] should be deterministic (use [NotificationIds]).
  /// Returns true if scheduling succeeded.
  Future<bool> scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_permissionGranted || _initializationFailed) return false;

    // Don't schedule in the past.
    if (scheduledTime.isBefore(DateTime.now())) return false;

    try {
      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'student_os_reminders',
            'Task & Study Reminders',
            channelDescription:
                'Reminders for tasks, study sessions, and exams',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Schedule one-shot failed: $e');
      }
      return false;
    }
  }

  /// Schedules a daily repeating notification.
  ///
  /// [id] should be deterministic (use [NotificationIds]).
  /// [hour] and [minute] specify the daily trigger time.
  Future<bool> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_permissionGranted || _initializationFailed) return false;

    try {
      // Calculate next occurrence of this time.
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has already passed today, schedule for tomorrow.
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'student_os_reminders',
            'Task & Study Reminders',
            channelDescription:
                'Reminders for tasks, study sessions, and exams',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Schedule daily failed: $e');
      }
      return false;
    }
  }

  /// Cancels a specific notification by [id].
  Future<void> cancel(int id) async {
    if (!_initialized || _initializationFailed) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Cancel failed: $e');
      }
    }
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    if (!_initialized || _initializationFailed) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Cancel all failed: $e');
      }
    }
  }

  /// Cancels all notifications for a specific task.
  Future<void> cancelForTask(String taskId) async {
    await cancel(NotificationIds.taskReminder(taskId));
  }

  /// Cancels all notifications for a specific exam.
  Future<void> cancelForExam(String examId) async {
    // Cancel reminders for 7, 3, and 1 days before.
    for (final days in [7, 3, 1]) {
      await cancel(NotificationIds.examReminder(examId, days));
    }
  }
}
