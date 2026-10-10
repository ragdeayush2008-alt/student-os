import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';

void main() {
  group('AcademicCalendarEvent Validation & Property Unit Tests', () {
    test('1. Valid event with start < end constructs without exception', () {
      final start = DateTime(2026, 9, 22, 10, 0);
      final end = DateTime(2026, 9, 22, 11, 0);

      final event = AcademicCalendarEvent(
        id: 'evt_1',
        userId: 'u1',
        title: 'Valid Class',
        startAt: start,
        endAt: end,
      );

      expect(event.durationMinutes, 60);
      expect(event.duration, const Duration(hours: 1));
    });

    test('2. Assertion error if start is after end for timed event', () {
      final start = DateTime(2026, 9, 22, 12, 0);
      final end = DateTime(2026, 9, 22, 11, 0);

      expect(
        () => AcademicCalendarEvent(
          id: 'evt_err',
          userId: 'u1',
          title: 'Invalid Time',
          startAt: start,
          endAt: end,
          allDay: false,
        ),
        throwsAssertionError,
      );
    });

    test('3. Zero-duration event is allowed (startAt == endAt)', () {
      final time = DateTime(2026, 9, 22, 10, 0);
      final event = AcademicCalendarEvent(
        id: 'evt_zero',
        userId: 'u1',
        title: 'Instant Milestone',
        startAt: time,
        endAt: time,
      );

      expect(event.durationMinutes, 0);
      expect(event.duration, Duration.zero);
    });

    test('4. All-day event ignores time component in duration check', () {
      final start = DateTime(2026, 9, 22, 0, 0);
      final end = DateTime(2026, 9, 22, 23, 59);

      final event = AcademicCalendarEvent(
        id: 'evt_allday',
        userId: 'u1',
        title: 'Sports Day',
        startAt: start,
        endAt: end,
        allDay: true,
      );

      expect(event.allDay, isTrue);
      expect(event.isFixed, isTrue);
    });

    test('5. Custom colorValue overrides type default color', () {
      const customColor = 0xFF9C27B0;
      final eventWithCustomColor = AcademicCalendarEvent(
        id: 'evt_color',
        userId: 'u1',
        title: 'Purple Lecture',
        type: AcademicEventType.lecture,
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
        colorValue: customColor,
      );

      expect(eventWithCustomColor.displayColor, const Color(customColor));

      final eventDefaultColor = AcademicCalendarEvent(
        id: 'evt_def',
        userId: 'u1',
        title: 'Default Lecture',
        type: AcademicEventType.lecture,
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
      );

      expect(eventDefaultColor.displayColor, AcademicEventType.lecture.color);
    });

    test('6. isVirtualOccurrence is true only when baseEventId is populated', () {
      final baseEvent = AcademicCalendarEvent(
        id: 'evt_base',
        userId: 'u1',
        title: 'Base Event',
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
      );
      expect(baseEvent.isVirtualOccurrence, isFalse);

      final occurrence = baseEvent.copyWith(
        id: 'evt_base_occ_2026_09_23',
        baseEventId: 'evt_base',
      );
      expect(occurrence.isVirtualOccurrence, isTrue);
      expect(occurrence.baseEventId, 'evt_base');
    });

    test('7. fromJson handles null and missing fields safely with clean defaults', () {
      final json = <String, dynamic>{
        'id': 'evt_minimal',
        'startAt': '2026-09-22T08:00:00.000',
        'endAt': '2026-09-22T09:00:00.000',
      };

      final event = AcademicCalendarEvent.fromJson(json);
      expect(event.id, 'evt_minimal');
      expect(event.title, 'Untitled Event');
      expect(event.description, '');
      expect(event.userId, '');
      expect(event.type, AcademicEventType.classSession);
      expect(event.allDay, isFalse);
      expect(event.isFixed, isTrue);
      expect(event.location, isNull);
      expect(event.subjectId, isNull);
      expect(event.examId, isNull);
      expect(event.taskId, isNull);
      expect(event.recurrence, isNull);
      expect(event.reminderMinutesBefore, isNull);
    });
  });
}
