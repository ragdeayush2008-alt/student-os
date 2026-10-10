import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/analytics/performance_snapshot.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/notification_service.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Calendar Edge Cases & System Hardening Regression Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_edge_user');
      AcademicScheduleController.instance.clearData();
    });

    tearDown(() {
      AcademicScheduleController.instance.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('1. Multi-day events appear in eventsForDay across all active days', () async {
      await AcademicScheduleController.instance.createEvent(
        title: '3-Day Academic Conference',
        type: AcademicEventType.collegeEvent,
        startAt: DateTime(2026, 9, 22, 9, 0),
        endAt: DateTime(2026, 9, 24, 17, 0),
      );

      expect(AcademicScheduleController.instance.eventsForDay(DateTime(2026, 9, 21)), isEmpty);
      expect(AcademicScheduleController.instance.eventsForDay(DateTime(2026, 9, 22)).length, 1);
      expect(AcademicScheduleController.instance.eventsForDay(DateTime(2026, 9, 23)).length, 1);
      expect(AcademicScheduleController.instance.eventsForDay(DateTime(2026, 9, 24)).length, 1);
      expect(AcademicScheduleController.instance.eventsForDay(DateTime(2026, 9, 25)), isEmpty);
    });

    test('2. Deleting a recurring base event removes all its virtual occurrences from range queries', () async {
      final baseEvent = await AcademicScheduleController.instance.createEvent(
        title: 'Weekly Lecture',
        startAt: DateTime(2026, 9, 21, 10, 0),
        endAt: DateTime(2026, 9, 21, 11, 0),
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.weekly,
        ),
      );

      // Verify occurrences present before deletion
      final occurrencesBefore = AcademicScheduleController.instance
          .eventsForRange(DateTime(2026, 9, 20), DateTime(2026, 10, 15));
      expect(occurrencesBefore.length, 4);

      // Delete base event
      await AcademicScheduleController.instance.deleteEvent(baseEvent.id);

      // Verify all virtual occurrences are removed
      final occurrencesAfter = AcademicScheduleController.instance
          .eventsForRange(DateTime(2026, 9, 20), DateTime(2026, 10, 15));
      expect(occurrencesAfter, isEmpty);
    });

    test('3. PerformanceSnapshot incorporates allCalendarEvents from controller', () async {
      await AcademicScheduleController.instance.createEvent(
        title: 'Analytical Chemistry',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
      );

      final snapshot = PerformanceSnapshot.fromControllers();
      expect(snapshot.allCalendarEvents.length, 1);
      expect(snapshot.allCalendarEvents.first.title, 'Analytical Chemistry');
    });

    test('4. NotificationIds for calendar events generates stable, deterministic integer IDs', () {
      final id1 = NotificationIds.calendarEventReminder('event_xyz_123');
      final id2 = NotificationIds.calendarEventReminder('event_xyz_123');
      final id3 = NotificationIds.calendarEventReminder('event_abc_456');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
      expect(id1, isPositive);
    });
  });
}
