import 'package:flutter/material.dart';

import '../../core/auth/auth_isolation.dart';
import '../auth/auth_service.dart';
import '../../core/services/notification_coordinator.dart';
import '../../core/services/storage_service.dart';

/// The day the week starts on.
enum WeekStartDay {
  monday('Monday', 1),
  sunday('Sunday', 7);

  const WeekStartDay(this.label, this.weekday);
  final String label;
  final int weekday;
}

/// Autopilot mode for Student OS intelligence and automation.
enum AutopilotMode {
  off('Off', 'Manual decisions only'),
  suggest('Suggest', 'Recommendations with 1-tap confirmation'),
  autopilot('Autopilot', 'Automate safe planning and study organization');

  const AutopilotMode(this.label, this.description);
  final String label;
  final String description;
}

/// A persistent store for user-level preferences that affect the Student OS
/// experience.
///
/// Each preference here has a real architectural purpose:
/// - [defaultFocusDuration]: preselects the duration when a focus session opens.
/// - [weekStartDay]: determines week boundaries in Plan, Progress and goals.
/// - [studyReminderEnabled/Time]: the reminder layer is architecture-ready;
///   actual notification delivery requires a notification package (not wired yet).
class UserPreferencesController extends ChangeNotifier {
  UserPreferencesController._();

  /// Clears in-memory prefs without touching storage.
  void clearData() {
    notifyListeners();
  }

  static final UserPreferencesController instance =
      UserPreferencesController._();

  static const _prefsKey = 'user_preferences';

  Duration _defaultFocusDuration = const Duration(minutes: 25);
  WeekStartDay _weekStartDay = WeekStartDay.monday;
  AutopilotMode _autopilotMode = AutopilotMode.suggest;
  bool _studyReminderEnabled = false;
  TimeOfDay _studyReminderTime = const TimeOfDay(hour: 18, minute: 0);
  bool _planningReminderEnabled = false;
  TimeOfDay _planningReminderTime = const TimeOfDay(hour: 8, minute: 0);

  // Notification category preferences
  bool _taskNotificationsEnabled = true;
  bool _examNotificationsEnabled = true;
  bool _studyNotificationsEnabled = true;
  bool _focusNotificationsEnabled = true;
  bool _achievementNotificationsEnabled = true;
  bool _progressionNotificationsEnabled = true;
  bool _leaderboardNotificationsEnabled = true;
  bool _streakNotificationsEnabled = true;

  bool _loaded = false;
  bool _disposed = false;

  Duration get defaultFocusDuration => _defaultFocusDuration;
  WeekStartDay get weekStartDay => _weekStartDay;
  AutopilotMode get autopilotMode => _autopilotMode;
  bool get studyReminderEnabled => _studyReminderEnabled;
  TimeOfDay get studyReminderTime => _studyReminderTime;
  bool get planningReminderEnabled => _planningReminderEnabled;
  TimeOfDay get planningReminderTime => _planningReminderTime;

  bool get taskNotificationsEnabled => _taskNotificationsEnabled;
  bool get examNotificationsEnabled => _examNotificationsEnabled;
  bool get studyNotificationsEnabled => _studyNotificationsEnabled;
  bool get focusNotificationsEnabled => _focusNotificationsEnabled;
  bool get achievementNotificationsEnabled => _achievementNotificationsEnabled;
  bool get progressionNotificationsEnabled => _progressionNotificationsEnabled;
  bool get leaderboardNotificationsEnabled => _leaderboardNotificationsEnabled;
  bool get streakNotificationsEnabled => _streakNotificationsEnabled;
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Loading / persistence ───────────────────────────────────────────

  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    final uid = _userId;
    if (uid == null) return;
    final json = await StorageService.instance.loadJson(
      userId: uid,
      key: _prefsKey,
    );
    if (json != null) {
      _defaultFocusDuration = Duration(
        minutes: (json['defaultFocusMinutes'] as int?) ?? 25,
      );
      _weekStartDay = WeekStartDay.values.firstWhere(
        (d) => d.name == json['weekStartDay'],
        orElse: () => WeekStartDay.monday,
      );
      _autopilotMode = AutopilotMode.values.firstWhere(
        (m) => m.name == json['autopilotMode'],
        orElse: () => AutopilotMode.suggest,
      );
      _studyReminderEnabled = (json['studyReminderEnabled'] as bool?) ?? false;
      _planningReminderEnabled =
          (json['planningReminderEnabled'] as bool?) ?? false;

      if (json['studyReminderHour'] != null &&
          json['studyReminderMinute'] != null) {
        _studyReminderTime = TimeOfDay(
          hour: json['studyReminderHour'] as int,
          minute: json['studyReminderMinute'] as int,
        );
      }
      if (json['planningReminderHour'] != null &&
          json['planningReminderMinute'] != null) {
        _planningReminderTime = TimeOfDay(
          hour: json['planningReminderHour'] as int,
          minute: json['planningReminderMinute'] as int,
        );
      }

      _taskNotificationsEnabled =
          (json['taskNotificationsEnabled'] as bool?) ?? true;
      _examNotificationsEnabled =
          (json['examNotificationsEnabled'] as bool?) ?? true;
      _studyNotificationsEnabled =
          (json['studyNotificationsEnabled'] as bool?) ?? true;
      _focusNotificationsEnabled =
          (json['focusNotificationsEnabled'] as bool?) ?? true;
      _achievementNotificationsEnabled =
          (json['achievementNotificationsEnabled'] as bool?) ?? true;
      _progressionNotificationsEnabled =
          (json['progressionNotificationsEnabled'] as bool?) ?? true;
      _leaderboardNotificationsEnabled =
          (json['leaderboardNotificationsEnabled'] as bool?) ?? true;
      _streakNotificationsEnabled =
          (json['streakNotificationsEnabled'] as bool?) ?? true;
    }
    _loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJson(
      userId: uid,
      key: _prefsKey,
      json: {
        'defaultFocusMinutes': _defaultFocusDuration.inMinutes,
        'weekStartDay': _weekStartDay.name,
        'autopilotMode': _autopilotMode.name,
        'studyReminderEnabled': _studyReminderEnabled,
        'studyReminderHour': _studyReminderTime.hour,
        'studyReminderMinute': _studyReminderTime.minute,
        'planningReminderEnabled': _planningReminderEnabled,
        'planningReminderHour': _planningReminderTime.hour,
        'planningReminderMinute': _planningReminderTime.minute,
        'taskNotificationsEnabled': _taskNotificationsEnabled,
        'examNotificationsEnabled': _examNotificationsEnabled,
        'studyNotificationsEnabled': _studyNotificationsEnabled,
        'focusNotificationsEnabled': _focusNotificationsEnabled,
        'achievementNotificationsEnabled': _achievementNotificationsEnabled,
        'progressionNotificationsEnabled': _progressionNotificationsEnabled,
        'leaderboardNotificationsEnabled': _leaderboardNotificationsEnabled,
        'streakNotificationsEnabled': _streakNotificationsEnabled,
      },
    );
  }

  // ─── Mutations ───────────────────────────────────────────────────────

  Future<void> setNotificationCategoryEnabled({
    required String category,
    required bool enabled,
  }) async {
    switch (category) {
      case 'tasks':
        _taskNotificationsEnabled = enabled;
        break;
      case 'exams':
        _examNotificationsEnabled = enabled;
        break;
      case 'study':
        _studyNotificationsEnabled = enabled;
        break;
      case 'focus':
        _focusNotificationsEnabled = enabled;
        break;
      case 'achievements':
        _achievementNotificationsEnabled = enabled;
        break;
      case 'progression':
        _progressionNotificationsEnabled = enabled;
        break;
      case 'leaderboard':
        _leaderboardNotificationsEnabled = enabled;
        break;
      case 'streak':
        _streakNotificationsEnabled = enabled;
        break;
    }
    notifyListeners();
    await _save();
  }

  Future<void> setDefaultFocusDuration(Duration duration) async {
    if (duration == _defaultFocusDuration) return;
    _defaultFocusDuration = duration;
    notifyListeners();
    await _save();
  }

  Future<void> setAutopilotMode(AutopilotMode mode) async {
    if (mode == _autopilotMode) return;
    _autopilotMode = mode;
    notifyListeners();
    await _save();
  }

  Future<void> setWeekStartDay(WeekStartDay day) async {
    if (day == _weekStartDay) return;
    _weekStartDay = day;
    notifyListeners();
    await _save();
  }

  Future<void> setStudyReminder({
    required bool enabled,
    TimeOfDay? time,
  }) async {
    _studyReminderEnabled = enabled;
    if (time != null) _studyReminderTime = time;
    notifyListeners();
    await _save();
    await NotificationCoordinator.instance.onStudyReminderChanged();
  }

  Future<void> setPlanningReminder({
    required bool enabled,
    TimeOfDay? time,
  }) async {
    _planningReminderEnabled = enabled;
    if (time != null) _planningReminderTime = time;
    notifyListeners();
    await _save();
    await NotificationCoordinator.instance.onPlanningReminderChanged();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Helper to format a [TimeOfDay] as "8:00 AM".
String formatTimeOfDay(TimeOfDay t) {
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
