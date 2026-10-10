import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Academic Recurrence Engine Unit Tests', () {
    late AcademicScheduleController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_recurrence_user');
      controller = AcademicScheduleController.instance;
      controller.clearData();
    });

    tearDown(() {
      controller.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('1. Non-recurring event only appears on its specific date', () async {
      final start = DateTime(2026, 9, 22, 10, 0);
      await controller.createEvent(
        title: 'One-off Workshop',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
      );

      expect(controller.eventsForDay(DateTime(2026, 9, 22)).length, 1);
      expect(controller.eventsForDay(DateTime(2026, 9, 21)), isEmpty);
      expect(controller.eventsForDay(DateTime(2026, 9, 23)), isEmpty);
    });

    test('2. Daily recurrence with interval=1 occurs every single day', () async {
      final start = DateTime(2026, 9, 21, 8, 0);
      await controller.createEvent(
        title: 'Daily Standup',
        startAt: start,
        endAt: start.add(const Duration(minutes: 30)),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.daily,
          interval: 1,
        ),
      );

      for (int i = 0; i < 7; i++) {
        final day = DateTime(2026, 9, 21).add(Duration(days: i));
        final events = controller.eventsForDay(day);
        expect(events.length, 1, reason: 'Failed on day offset $i');
        expect(events.first.title, 'Daily Standup');
      }
    });

    test('3. Daily recurrence with interval=2 occurs every other day', () async {
      final start = DateTime(2026, 9, 21, 9, 0); // Day 0
      await controller.createEvent(
        title: 'Alternate Day Study',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.daily,
          interval: 2,
        ),
      );

      // Day 0 (Sep 21) -> Yes
      expect(controller.eventsForDay(DateTime(2026, 9, 21)).length, 1);
      // Day 1 (Sep 22) -> No
      expect(controller.eventsForDay(DateTime(2026, 9, 22)), isEmpty);
      // Day 2 (Sep 23) -> Yes
      expect(controller.eventsForDay(DateTime(2026, 9, 23)).length, 1);
      // Day 3 (Sep 24) -> No
      expect(controller.eventsForDay(DateTime(2026, 9, 24)), isEmpty);
      // Day 4 (Sep 25) -> Yes
      expect(controller.eventsForDay(DateTime(2026, 9, 25)).length, 1);
    });

    test('4. Weekdays recurrence excludes Saturday and Sunday', () async {
      final start = DateTime(2026, 9, 21, 10, 0); // Mon
      await controller.createEvent(
        title: 'School Hours',
        startAt: start,
        endAt: start.add(const Duration(hours: 4)),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.weekdays,
        ),
      );

      // Mon (Sep 21) to Fri (Sep 25)
      for (int i = 21; i <= 25; i++) {
        expect(controller.eventsForDay(DateTime(2026, 9, i)).length, 1);
      }
      // Sat (Sep 26) & Sun (Sep 27)
      expect(controller.eventsForDay(DateTime(2026, 9, 26)), isEmpty);
      expect(controller.eventsForDay(DateTime(2026, 9, 27)), isEmpty);
    });

    test('5. Weekly recurrence on Tue & Thu occurs accurately for 4 weeks', () async {
      final start = DateTime(2026, 9, 22, 11, 0); // Tuesday (Sep 22)
      await controller.createEvent(
        title: 'Chemistry Lab',
        startAt: start,
        endAt: start.add(const Duration(hours: 2)),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.weekly,
          daysOfWeek: [2, 4], // Tuesday, Thursday
        ),
      );

      // Week 1: Tue Sep 22, Thu Sep 24
      expect(controller.eventsForDay(DateTime(2026, 9, 22)).length, 1);
      expect(controller.eventsForDay(DateTime(2026, 9, 23)), isEmpty);
      expect(controller.eventsForDay(DateTime(2026, 9, 24)).length, 1);
      expect(controller.eventsForDay(DateTime(2026, 9, 25)), isEmpty);

      // Week 2: Tue Sep 29, Thu Oct 1
      expect(controller.eventsForDay(DateTime(2026, 9, 29)).length, 1);
      expect(controller.eventsForDay(DateTime(2026, 10, 1)).length, 1);
    });

    test('6. Biweekly recurrence skips alternate weeks', () async {
      final start = DateTime(2026, 9, 21, 15, 0); // Monday (Week 1)
      await controller.createEvent(
        title: 'Biweekly Faculty Review',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.biweekly,
          interval: 1,
          daysOfWeek: [1],
        ),
      );

      // Week 1 (Sep 21) -> Yes
      expect(controller.eventsForDay(DateTime(2026, 9, 21)).length, 1);
      // Week 2 (Sep 28) -> No
      expect(controller.eventsForDay(DateTime(2026, 9, 28)), isEmpty);
      // Week 3 (Oct 5) -> Yes
      expect(controller.eventsForDay(DateTime(2026, 10, 5)).length, 1);
      // Week 4 (Oct 12) -> No
      expect(controller.eventsForDay(DateTime(2026, 10, 12)), isEmpty);
    });

    test('7. Monthly recurrence recurs on the exact day of month', () async {
      final start = DateTime(2026, 9, 15, 14, 0);
      await controller.createEvent(
        title: 'Monthly Progress Meeting',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.monthly,
          interval: 1,
        ),
      );

      // Sep 15 -> Yes
      expect(controller.eventsForDay(DateTime(2026, 9, 15)).length, 1);
      // Sep 16 -> No
      expect(controller.eventsForDay(DateTime(2026, 9, 16)), isEmpty);
      // Oct 15 -> Yes
      expect(controller.eventsForDay(DateTime(2026, 10, 15)).length, 1);
      // Nov 15 -> Yes
      expect(controller.eventsForDay(DateTime(2026, 11, 15)).length, 1);
    });

    test('8. Recurrence stops after "until" date boundary', () async {
      final start = DateTime(2026, 9, 21, 8, 0);
      final untilDate = DateTime(2026, 9, 23, 23, 59);

      await controller.createEvent(
        title: '3-Day Orientation',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        recurrence: AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.daily,
          until: untilDate,
        ),
      );

      expect(controller.eventsForDay(DateTime(2026, 9, 21)).length, 1);
      expect(controller.eventsForDay(DateTime(2026, 9, 22)).length, 1);
      expect(controller.eventsForDay(DateTime(2026, 9, 23)).length, 1);
      // Day 4 (Sep 24) is past until date
      expect(controller.eventsForDay(DateTime(2026, 9, 24)), isEmpty);
    });
  });
}
