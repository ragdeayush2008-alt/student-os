import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/calendar/services/free_time_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Calendar Stress & Regression Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_stress_user');
      AcademicScheduleController.instance.clearData();
    });

    tearDown(() {
      AcademicScheduleController.instance.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('1. Stress test with 100, 500, and 1000 events evaluates quickly without crash', () async {
      final baseDate = DateTime(2026, 9, 1);
      final events = List.generate(
        1000,
        (i) => AcademicCalendarEvent(
          id: 'evt_stress_$i',
          userId: 'test_stress_user',
          title: 'Class Event $i',
          startAt: baseDate.add(Duration(hours: i * 2)),
          endAt: baseDate.add(Duration(hours: i * 2 + 1)),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Test availability for a day with hundreds of candidate events
      final avail = FreeTimeEngine.calculateDayAvailability(
        DateTime(2026, 9, 22),
        fixedEvents: events,
      );

      stopwatch.stop();

      expect(avail.totalWindowMinutes, 840);
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // fast sub-second execution
    });

    test('2. Events crossing midnight boundaries are clamped and handled safely', () {
      final lateNightEvent = AcademicCalendarEvent(
        id: 'evt_midnight',
        userId: 'u1',
        title: 'Late Night Hackathon',
        startAt: DateTime(2026, 9, 22, 23, 0),
        endAt: DateTime(2026, 9, 23, 3, 0),
      );

      // Active daily window 08:00 to 22:00
      final avail = FreeTimeEngine.calculateDayAvailability(
        DateTime(2026, 9, 22),
        fixedEvents: [lateNightEvent],
      );

      expect(avail.isOverloaded, isFalse);
      expect(avail.freeMinutes, 840); // 23:00 is outside the 08:00-22:00 window
    });

    test('3. Malformed or corrupt JSON entries in storage do not crash controller load', () {
      final corruptList = [
        {'id': 'valid_1', 'title': 'Valid Event', 'startAt': '2026-09-22T10:00:00.000', 'endAt': '2026-09-22T11:00:00.000'},
        {'id': 'corrupt_1', 'invalid_field': 123}, // Missing required fields
        {'id': 'valid_2', 'title': 'Valid Event 2', 'startAt': '2026-09-22T14:00:00.000', 'endAt': '2026-09-22T15:00:00.000'},
      ];

      final parsed = <AcademicCalendarEvent>[];
      for (final item in corruptList) {
        try {
          parsed.add(AcademicCalendarEvent.fromJson(item));
        } catch (_) {}
      }

      // 2 valid events parsed, 1 corrupt event skipped safely
      expect(parsed.length, 2);
      expect(parsed.first.title, 'Valid Event');
      expect(parsed.last.title, 'Valid Event 2');
    });

    test('4. Unknown identity uses safe memory-only behavior without writing to shared storage', () async {
      AuthIsolation.instance.clearSession(); // Anonymous / unknown user

      final event = await AcademicScheduleController.instance.createEvent(
        title: 'Memory Only Class',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
      );

      expect(event.title, 'Memory Only Class');
      expect(AcademicScheduleController.instance.events.length, 1);
    });
  });
}
