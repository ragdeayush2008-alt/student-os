import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/student_life/models/life_routine_item.dart';
import 'package:student_os/features/student_life/models/sleep_record.dart';
import 'package:student_os/features/student_life/models/student_life_preferences.dart';

void main() {
  group('StudentLifePreferences', () {
    test('F1. round-trips through JSON', () {
      const prefs = StudentLifePreferences(
        enabled: true,
        notificationsEnabled: false,
        targetSleepMinutes: 450,
        targetBedtimeMinutes: 1335,
        targetWakeMinutes: 400,
        consistencyGoalEnabled: true,
        windDownMinutes: 45,
        napEnabled: true,
        napDurationMinutes: 20,
        dailyStudyTargetMinutes: 180,
        breakRemindersEnabled: false,
        hydration: HydrationFrequency.frequent,
        mealRemindersEnabled: true,
        breakfastMinutes: 490,
        lunchMinutes: 785,
        dinnerMinutes: 1150,
        exerciseEnabled: true,
        exerciseMinutes: 25,
        exerciseAtMinutes: 1050,
      );

      final restored = StudentLifePreferences.fromJson(prefs.toJson());

      expect(restored.toJson(), prefs.toJson());
      expect(restored.hydration, HydrationFrequency.frequent);
    });

    test('F2. falls back to safe defaults for unknown or missing values', () {
      final restored = StudentLifePreferences.fromJson({
        'hydration': 'not-a-mode',
        'targetSleepMinutes': 'oops',
      });

      expect(restored.hydration, HydrationFrequency.normal);
      expect(restored.targetSleepMinutes, 480);
    });

    test('F3. copyWith overrides only the requested fields', () {
      const prefs = StudentLifePreferences();
      final updated = prefs.copyWith(hydration: HydrationFrequency.off);

      expect(updated.hydration, HydrationFrequency.off);
      expect(updated.targetSleepMinutes, prefs.targetSleepMinutes);
      expect(updated.enabled, prefs.enabled);
    });

    test('F4. formats clock times and wraps past midnight', () {
      expect(StudentLifePreferences.formatClock(0), '00:00');
      expect(StudentLifePreferences.formatClock(1380), '23:00');
      expect(StudentLifePreferences.formatClock(1440), '00:00');
      expect(StudentLifePreferences.formatClock(-60), '23:00');
      expect(StudentLifePreferences.formatClock(400), '06:40');
    });
  });

  group('SleepRecord', () {
    SleepRecord sample() => SleepRecord(
      id: 'sl_1',
      bedtime: DateTime(2026, 9, 29, 23, 30),
      wakeTime: DateTime(2026, 9, 30, 7, 15),
      quality: 4,
      note: 'woke once',
      source: SleepRecordSource.manual,
      createdAt: DateTime(2026, 9, 30, 8),
    );

    test('F5. round-trips through JSON', () {
      final restored = SleepRecord.fromJson(sample().toJson());

      expect(restored.id, 'sl_1');
      expect(restored.durationMinutes, 465);
      expect(restored.quality, 4);
      expect(restored.note, 'woke once');
      expect(restored.isNightSleep, isTrue);
    });

    test('F6. never reports a negative duration', () {
      final record = SleepRecord(
        id: 'sl_bad',
        bedtime: DateTime(2026, 9, 30, 8),
        wakeTime: DateTime(2026, 9, 30, 7),
      );

      expect(record.durationMinutes, 0);
    });

    test('F7. clearQuality removes a recorded quality', () {
      expect(sample().copyWith(clearQuality: true).quality, isNull);
    });

    test('F8. derives the calendar date from the bedtime', () {
      expect(sample().date, DateTime(2026, 9, 29));
    });
  });

  group('LifeRoutineItem', () {
    test('F9. computes duration and copies completion state', () {
      final item = LifeRoutineItem(
        id: 'sl_20260930_wake',
        kind: LifeRoutineKind.wake,
        title: 'Wake up',
        startAt: DateTime(2026, 9, 30, 7),
        endAt: DateTime(2026, 9, 30, 7, 5),
      );

      expect(item.durationMinutes, 5);
      expect(item.copyWith(isCompleted: true).isCompleted, isTrue);
      expect(item.copyWith(isCompleted: true).title, 'Wake up');
      expect(item.copyWith(isCompleted: true).isOptional, isFalse);
    });
  });
}
