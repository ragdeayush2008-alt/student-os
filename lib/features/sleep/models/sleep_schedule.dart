import 'package:flutter/foundation.dart';

/// A planned sleep window for the student (P1 Sleep Foundation).
///
/// Sleep is intentionally non-medical: this is a *schedule* (planned bedtime,
/// wake time, active days, reminders) used as a planning constraint, not a
/// health record. Actual sleep logging stays in Student Life ([SleepRecord]).
///
/// Times are minutes-since-midnight (0..1439). Overnight windows (bedtime
/// later than wake time, e.g. 23:00 → 07:00) are first-class: see
/// [plannedMinutes].
@immutable
class SleepSchedule {
  const SleepSchedule({
    this.bedtimeMinutes = 1380,
    this.wakeMinutes = 420,
    this.enabled = true,
    this.days = const [1, 2, 3, 4, 5, 6, 7],
    this.bedtimeReminderEnabled = true,
    this.windDownReminderEnabled = true,
    this.windDownMinutes = 30,
    this.createdAt,
    this.updatedAt,
  });

  /// Minutes since midnight, 0..1439.
  final int bedtimeMinutes;

  /// Minutes since midnight, 0..1439.
  final int wakeMinutes;

  /// Master switch. A disabled schedule is kept but ignored by planning,
  /// reminders, and Assistant context.
  final bool enabled;

  /// Weekdays the schedule applies to, 1 = Monday .. 7 = Sunday.
  final List<int> days;

  final bool bedtimeReminderEnabled;
  final bool windDownReminderEnabled;

  /// Minutes before bedtime for the wind-down reminder.
  final int windDownMinutes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// True when the window crosses midnight (e.g. 23:00 → 07:00).
  bool get isOvernight => wakeMinutes <= bedtimeMinutes;

  /// Planned sleep duration in minutes, overnight-aware.
  int get plannedMinutes => SleepScheduleValidation.plannedMinutes(
        bedtimeMinutes: bedtimeMinutes,
        wakeMinutes: wakeMinutes,
      );

  /// e.g. "8h" / "7h 30m".
  String get durationLabel {
    final m = plannedMinutes;
    final h = m ~/ 60;
    final rest = m % 60;
    if (h == 0) return '${m}m';
    if (rest == 0) return '${h}h';
    return '${h}h ${rest}m';
  }

  /// e.g. "11:30 PM → 7:30 AM".
  String get windowLabel =>
      '${SleepScheduleValidation.formatClock12(bedtimeMinutes)} → '
      '${SleepScheduleValidation.formatClock12(wakeMinutes)}';

  /// Whether the schedule applies to [day] (enabled + weekday selected).
  bool appliesTo(DateTime day) =>
      enabled && days.contains(day.weekday);

  SleepSchedule copyWith({
    int? bedtimeMinutes,
    int? wakeMinutes,
    bool? enabled,
    List<int>? days,
    bool? bedtimeReminderEnabled,
    bool? windDownReminderEnabled,
    int? windDownMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepSchedule(
      bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      enabled: enabled ?? this.enabled,
      days: days ?? this.days,
      bedtimeReminderEnabled:
          bedtimeReminderEnabled ?? this.bedtimeReminderEnabled,
      windDownReminderEnabled:
          windDownReminderEnabled ?? this.windDownReminderEnabled,
      windDownMinutes: windDownMinutes ?? this.windDownMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'bedtimeMinutes': bedtimeMinutes,
        'wakeMinutes': wakeMinutes,
        'enabled': enabled,
        'days': days,
        'bedtimeReminderEnabled': bedtimeReminderEnabled,
        'windDownReminderEnabled': windDownReminderEnabled,
        'windDownMinutes': windDownMinutes,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Backward-compatible: every field has a safe default so old/partial
  /// stored data (or a future schema) never throws.
  factory SleepSchedule.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return null;
      }
    }

    final days = (json['days'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .where((d) => d >= 1 && d <= 7)
            .toList() ??
        const [1, 2, 3, 4, 5, 6, 7];

    return SleepSchedule(
      bedtimeMinutes: SleepScheduleValidation.normaliseMinutes(
        (json['bedtimeMinutes'] as num?)?.toInt() ?? 1380,
      ),
      wakeMinutes: SleepScheduleValidation.normaliseMinutes(
        (json['wakeMinutes'] as num?)?.toInt() ?? 420,
      ),
      enabled: (json['enabled'] as bool?) ?? true,
      days: days.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : days,
      bedtimeReminderEnabled:
          (json['bedtimeReminderEnabled'] as bool?) ?? true,
      windDownReminderEnabled:
          (json['windDownReminderEnabled'] as bool?) ?? true,
      windDownMinutes:
          ((json['windDownMinutes'] as num?)?.toInt() ?? 30).clamp(0, 180),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

/// Pure validation + time math for sleep schedules. No UI, no storage.
abstract final class SleepScheduleValidation {
  /// Wraps any integer into 0..1439.
  static int normaliseMinutes(int minutes) =>
      ((minutes % 1440) + 1440) % 1440;

  /// Overnight-aware duration. Never assumes same-day subtraction:
  /// 23:00 → 07:00 = 8h, not −16h.
  static int plannedMinutes({
    required int bedtimeMinutes,
    required int wakeMinutes,
  }) {
    final bed = normaliseMinutes(bedtimeMinutes);
    final wake = normaliseMinutes(wakeMinutes);
    if (wake <= bed) return (1440 - bed) + wake;
    return wake - bed;
  }

  /// Returns an error message for an invalid schedule, or null when valid.
  /// A zero-duration window (bedtime == wake time) is the only hard error;
  /// everything else normalises safely.
  static String? validate({
    required int bedtimeMinutes,
    required int wakeMinutes,
    List<int>? days,
  }) {
    final bed = normaliseMinutes(bedtimeMinutes);
    final wake = normaliseMinutes(wakeMinutes);
    if (bed == wake) {
      return 'Bedtime and wake time can\'t be the same — that would be no sleep at all.';
    }
    if (days != null && days.isEmpty) {
      return 'Pick at least one day for the schedule.';
    }
    return null;
  }

  /// 24h clock, e.g. 23:00. Matches the existing app convention.
  static String formatClock(int minutes) {
    final n = normaliseMinutes(minutes);
    final h = n ~/ 60;
    final m = n % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// 12h clock for friendly UI, e.g. 11:30 PM.
  static String formatClock12(int minutes) {
    final n = normaliseMinutes(minutes);
    final h24 = n ~/ 60;
    final m = n % 60;
    final suffix = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final mStr = m == 0 ? '' : ':${m.toString().padLeft(2, '0')}';
    return '$h12$mStr $suffix';
  }
}
