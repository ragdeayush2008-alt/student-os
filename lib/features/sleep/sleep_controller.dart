import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../auth/auth_service.dart';
import 'models/sleep_schedule.dart';

/// Owns the student's planned sleep window (P1 Sleep Foundation).
///
/// Small, local-first, user-scoped: one [SleepSchedule] per user persisted
/// through the existing [StorageService] (key `sleep_schedule`). Reminders use
/// the existing daily-notification primitive; cloud sync is intentionally
/// local-only in P1 (documented for a later phase).
///
/// Like the other Home-gating controllers, [load] always terminates loaded —
/// a corrupt cache entry starts empty instead of bricking Home.
class SleepController extends ChangeNotifier {
  SleepController._();

  static final SleepController instance = SleepController._();

  static const _scheduleKey = 'sleep_schedule';

  SleepSchedule? _schedule;
  bool _loaded = false;
  bool _disposed = false;

  SleepSchedule? get schedule => _schedule;
  bool get hasSchedule => _schedule != null;
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  /// Clears in-memory state (not persistent storage).
  void clearData() {
    _schedule = null;
    _loaded = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      _schedule = null;
      _loaded = true;
      if (!_disposed) notifyListeners();
      return;
    }
    try {
      final json = await StorageService.instance.loadJson(
        userId: uid,
        key: _scheduleKey,
      );
      _schedule = json == null ? null : SleepSchedule.fromJson(json);
    } catch (_) {
      _schedule = null;
    } finally {
      _loaded = true;
      if (!_disposed) notifyListeners();
    }
    await _reconcileReminders();
  }

  /// Validates and saves a schedule. Returns an error message, or null.
  Future<String?> saveSchedule(SleepSchedule schedule) async {
    final error = SleepScheduleValidation.validate(
      bedtimeMinutes: schedule.bedtimeMinutes,
      wakeMinutes: schedule.wakeMinutes,
      days: schedule.days,
    );
    if (error != null) return error;

    final uid = _userId;
    final stamped = schedule.copyWith(
      createdAt: schedule.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _schedule = stamped;
    if (uid != null) {
      try {
        await StorageService.instance.saveJson(
          userId: uid,
          key: _scheduleKey,
          json: stamped.toJson(),
        );
      } catch (_) {
        // Best-effort persistence; in-memory state still applies.
      }
    }
    if (!_disposed) notifyListeners();
    await _reconcileReminders();
    return null;
  }

  /// Toggles the master switch, preserving the rest of the schedule.
  Future<String?> setEnabled(bool enabled) async {
    final current = _schedule;
    if (current == null) {
      if (!enabled) return null;
      return saveSchedule(const SleepSchedule(enabled: true));
    }
    return saveSchedule(current.copyWith(enabled: enabled));
  }

  /// Deletes the stored schedule and cancels its reminders.
  Future<void> clearSchedule() async {
    final uid = _userId;
    _schedule = null;
    if (uid != null) {
      try {
        await StorageService.instance.remove(userId: uid, key: _scheduleKey);
      } catch (_) {}
    }
    if (!_disposed) notifyListeners();
    await _reconcileReminders();
  }

  // ─── Reminders (existing daily primitive, deterministic ids) ──────────

  Future<void> _reconcileReminders() async {
    try {
      await NotificationService.instance
          .cancel(NotificationIds.studentLifeReminder('sleep_bedtime'));
      await NotificationService.instance
          .cancel(NotificationIds.studentLifeReminder('sleep_winddown'));
    } catch (_) {}

    final s = _schedule;
    if (s == null || !s.enabled) return;
    if (!NotificationService.instance.hasPermission) return;

    try {
      if (s.bedtimeReminderEnabled) {
        final bed = SleepScheduleValidation.normaliseMinutes(
          s.bedtimeMinutes,
        );
        await NotificationService.instance.scheduleDaily(
          id: NotificationIds.studentLifeReminder('sleep_bedtime'),
          title: 'Bedtime',
          body:
              'Your planned sleep window starts at ${SleepScheduleValidation.formatClock12(s.bedtimeMinutes)}.',
          hour: bed ~/ 60,
          minute: bed % 60,
          payload: const NotificationPayload(
            type: 'sleep_schedule',
            entityId: 'bedtime',
          ).encode(),
        );
      }
      if (s.windDownReminderEnabled && s.windDownMinutes > 0) {
        final windDown = SleepScheduleValidation.normaliseMinutes(
          s.bedtimeMinutes - s.windDownMinutes,
        );
        await NotificationService.instance.scheduleDaily(
          id: NotificationIds.studentLifeReminder('sleep_winddown'),
          title: 'Wind down',
          body:
              'Start winding down — bedtime at ${SleepScheduleValidation.formatClock12(s.bedtimeMinutes)}.',
          hour: windDown ~/ 60,
          minute: windDown % 60,
          payload: const NotificationPayload(
            type: 'sleep_schedule',
            entityId: 'winddown',
          ).encode(),
        );
      }
    } catch (_) {
      // Reminders are best-effort; the schedule itself is unaffected.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
