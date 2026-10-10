import 'package:flutter/foundation.dart';

enum HydrationFrequency {
  off('Off'),
  normal('Normal'),
  frequent('Frequent');

  const HydrationFrequency(this.label);
  final String label;
}

@immutable
class StudentLifePreferences {
  const StudentLifePreferences({
    this.enabled = true,
    this.notificationsEnabled = true,
    this.targetSleepMinutes = 480,
    this.targetBedtimeMinutes = 1380,
    this.targetWakeMinutes = 420,
    this.consistencyGoalEnabled = false,
    this.windDownMinutes = 30,
    this.napEnabled = false,
    this.napDurationMinutes = 25,
    this.dailyStudyTargetMinutes = 120,
    this.breakRemindersEnabled = true,
    this.hydration = HydrationFrequency.normal,
    this.mealRemindersEnabled = false,
    this.breakfastMinutes = 480,
    this.lunchMinutes = 780,
    this.dinnerMinutes = 1140,
    this.exerciseEnabled = false,
    this.exerciseMinutes = 30,
    this.exerciseAtMinutes = 1080,
  });

  final bool enabled;
  final bool notificationsEnabled;
  final int targetSleepMinutes;
  final int targetBedtimeMinutes;
  final int targetWakeMinutes;
  final bool consistencyGoalEnabled;
  final int windDownMinutes;
  final bool napEnabled;
  final int napDurationMinutes;
  final int dailyStudyTargetMinutes;
  final bool breakRemindersEnabled;
  final HydrationFrequency hydration;
  final bool mealRemindersEnabled;
  final int breakfastMinutes;
  final int lunchMinutes;
  final int dinnerMinutes;
  final bool exerciseEnabled;
  final int exerciseMinutes;
  final int exerciseAtMinutes;

  StudentLifePreferences copyWith({
    bool? enabled,
    bool? notificationsEnabled,
    int? targetSleepMinutes,
    int? targetBedtimeMinutes,
    int? targetWakeMinutes,
    bool? consistencyGoalEnabled,
    int? windDownMinutes,
    bool? napEnabled,
    int? napDurationMinutes,
    int? dailyStudyTargetMinutes,
    bool? breakRemindersEnabled,
    HydrationFrequency? hydration,
    bool? mealRemindersEnabled,
    int? breakfastMinutes,
    int? lunchMinutes,
    int? dinnerMinutes,
    bool? exerciseEnabled,
    int? exerciseMinutes,
    int? exerciseAtMinutes,
  }) {
    return StudentLifePreferences(
      enabled: enabled ?? this.enabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      targetSleepMinutes: targetSleepMinutes ?? this.targetSleepMinutes,
      targetBedtimeMinutes: targetBedtimeMinutes ?? this.targetBedtimeMinutes,
      targetWakeMinutes: targetWakeMinutes ?? this.targetWakeMinutes,
      consistencyGoalEnabled:
          consistencyGoalEnabled ?? this.consistencyGoalEnabled,
      windDownMinutes: windDownMinutes ?? this.windDownMinutes,
      napEnabled: napEnabled ?? this.napEnabled,
      napDurationMinutes: napDurationMinutes ?? this.napDurationMinutes,
      dailyStudyTargetMinutes:
          dailyStudyTargetMinutes ?? this.dailyStudyTargetMinutes,
      breakRemindersEnabled:
          breakRemindersEnabled ?? this.breakRemindersEnabled,
      hydration: hydration ?? this.hydration,
      mealRemindersEnabled: mealRemindersEnabled ?? this.mealRemindersEnabled,
      breakfastMinutes: breakfastMinutes ?? this.breakfastMinutes,
      lunchMinutes: lunchMinutes ?? this.lunchMinutes,
      dinnerMinutes: dinnerMinutes ?? this.dinnerMinutes,
      exerciseEnabled: exerciseEnabled ?? this.exerciseEnabled,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      exerciseAtMinutes: exerciseAtMinutes ?? this.exerciseAtMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'notificationsEnabled': notificationsEnabled,
    'targetSleepMinutes': targetSleepMinutes,
    'targetBedtimeMinutes': targetBedtimeMinutes,
    'targetWakeMinutes': targetWakeMinutes,
    'consistencyGoalEnabled': consistencyGoalEnabled,
    'windDownMinutes': windDownMinutes,
    'napEnabled': napEnabled,
    'napDurationMinutes': napDurationMinutes,
    'dailyStudyTargetMinutes': dailyStudyTargetMinutes,
    'breakRemindersEnabled': breakRemindersEnabled,
    'hydration': hydration.name,
    'mealRemindersEnabled': mealRemindersEnabled,
    'breakfastMinutes': breakfastMinutes,
    'lunchMinutes': lunchMinutes,
    'dinnerMinutes': dinnerMinutes,
    'exerciseEnabled': exerciseEnabled,
    'exerciseMinutes': exerciseMinutes,
    'exerciseAtMinutes': exerciseAtMinutes,
  };

  factory StudentLifePreferences.fromJson(Map<String, dynamic> json) {
    return StudentLifePreferences(
      enabled: (json['enabled'] as bool?) ?? true,
      notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
      targetSleepMinutes: _intOr(json['targetSleepMinutes'], 480),
      targetBedtimeMinutes: _intOr(json['targetBedtimeMinutes'], 1380),
      targetWakeMinutes: _intOr(json['targetWakeMinutes'], 420),
      consistencyGoalEnabled: (json['consistencyGoalEnabled'] as bool?) ?? false,
      windDownMinutes: _intOr(json['windDownMinutes'], 30),
      napEnabled: (json['napEnabled'] as bool?) ?? false,
      napDurationMinutes: _intOr(json['napDurationMinutes'], 25),
      dailyStudyTargetMinutes: _intOr(json['dailyStudyTargetMinutes'], 120),
      breakRemindersEnabled: (json['breakRemindersEnabled'] as bool?) ?? true,
      hydration: HydrationFrequency.values.firstWhere(
        (h) => h.name == json['hydration'],
        orElse: () => HydrationFrequency.normal,
      ),
      mealRemindersEnabled: (json['mealRemindersEnabled'] as bool?) ?? false,
      breakfastMinutes: _intOr(json['breakfastMinutes'], 480),
      lunchMinutes: _intOr(json['lunchMinutes'], 780),
      dinnerMinutes: _intOr(json['dinnerMinutes'], 1140),
      exerciseEnabled: (json['exerciseEnabled'] as bool?) ?? false,
      exerciseMinutes: _intOr(json['exerciseMinutes'], 30),
      exerciseAtMinutes: _intOr(json['exerciseAtMinutes'], 1080),
    );
  }

  static int _intOr(Object? value, int fallback) =>
      value is int ? value : fallback;

  static String formatClock(int minutes) {
    final normalised = ((minutes % 1440) + 1440) % 1440;
    final h = normalised ~/ 60;
    final m = normalised % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
