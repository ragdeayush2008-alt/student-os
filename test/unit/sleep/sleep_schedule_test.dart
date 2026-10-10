import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';

/// P1 — SleepSchedule model: overnight math, validation, serialization.
void main() {
  group('plannedMinutes (overnight-aware)', () {
    test('11:00 PM → 7:00 AM = 8h', () {
      expect(
        SleepScheduleValidation.plannedMinutes(
          bedtimeMinutes: 1380,
          wakeMinutes: 420,
        ),
        480,
      );
    });

    test('11:30 PM → 7:30 AM = 8h', () {
      expect(
        SleepScheduleValidation.plannedMinutes(
          bedtimeMinutes: 1410,
          wakeMinutes: 450,
        ),
        480,
      );
    });

    test('same-evening window subtracts normally', () {
      expect(
        SleepScheduleValidation.plannedMinutes(
          bedtimeMinutes: 1320,
          wakeMinutes: 1380,
        ),
        60,
      );
    });

    test('model exposes duration + labels', () {
      const s = SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420);
      expect(s.isOvernight, isTrue);
      expect(s.plannedMinutes, 480);
      expect(s.durationLabel, '8h');
      expect(s.windowLabel, '11 PM → 7 AM');
    });
  });

  group('validation', () {
    test('bedtime == wake time is invalid', () {
      expect(
        SleepScheduleValidation.validate(
          bedtimeMinutes: 420,
          wakeMinutes: 420,
        ),
        isNotNull,
      );
    });

    test('overnight window is valid', () {
      expect(
        SleepScheduleValidation.validate(
          bedtimeMinutes: 1380,
          wakeMinutes: 420,
        ),
        isNull,
      );
    });

    test('empty days rejected', () {
      expect(
        SleepScheduleValidation.validate(
          bedtimeMinutes: 1380,
          wakeMinutes: 420,
          days: [],
        ),
        isNotNull,
      );
    });
  });

  group('appliesTo', () {
    test('respects enabled + weekday selection', () {
      const s = SleepSchedule(days: [1, 2, 3, 4, 5]);
      // 2026-10-05 is a Monday.
      expect(s.appliesTo(DateTime(2026, 10, 5)), isTrue);
      // 2026-10-10 is a Saturday.
      expect(s.appliesTo(DateTime(2026, 10, 10)), isFalse);
      expect(
        s.copyWith(enabled: false).appliesTo(DateTime(2026, 10, 5)),
        isFalse,
      );
    });
  });

  group('serialization', () {
    test('toJson/fromJson roundtrip preserves all fields', () {
      const original = SleepSchedule(
        bedtimeMinutes: 1410,
        wakeMinutes: 450,
        enabled: false,
        days: [1, 3, 5],
        bedtimeReminderEnabled: false,
        windDownReminderEnabled: true,
        windDownMinutes: 45,
      );
      final restored = SleepSchedule.fromJson(original.toJson());
      expect(restored.bedtimeMinutes, 1410);
      expect(restored.wakeMinutes, 450);
      expect(restored.enabled, isFalse);
      expect(restored.days, [1, 3, 5]);
      expect(restored.bedtimeReminderEnabled, isFalse);
      expect(restored.windDownMinutes, 45);
    });

    test('partial/corrupt JSON degrades to safe defaults', () {
      final restored = SleepSchedule.fromJson({'foo': 'bar'});
      expect(restored.bedtimeMinutes, 1380);
      expect(restored.wakeMinutes, 420);
      expect(restored.enabled, isTrue);
      expect(restored.days.length, 7);
    });
  });
}
