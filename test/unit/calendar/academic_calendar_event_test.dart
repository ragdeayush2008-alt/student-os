import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';

void main() {
  group('AcademicCalendarEvent Model & Serialization Tests', () {
    test('1. Creates event with all required and default fields', () {
      final start = DateTime(2026, 9, 22, 10, 0);
      final end = DateTime(2026, 9, 22, 11, 0);
      final event = AcademicCalendarEvent(
        id: 'evt_1',
        userId: 'user_123',
        title: 'Accountancy Class',
        startAt: start,
        endAt: end,
      );

      expect(event.id, 'evt_1');
      expect(event.userId, 'user_123');
      expect(event.title, 'Accountancy Class');
      expect(event.description, '');
      expect(event.type, AcademicEventType.classSession);
      expect(event.startAt, start);
      expect(event.endAt, end);
      expect(event.allDay, isFalse);
      expect(event.isFixed, isTrue);
      expect(event.durationMinutes, 60);
      expect(event.isVirtualOccurrence, isFalse);
      expect(event.displayColor, AcademicEventType.classSession.color);
    });

    test('2. Event type parsing handles various strings safely', () {
      expect(AcademicEventType.fromString('classSession'),
          AcademicEventType.classSession);
      expect(AcademicEventType.fromString('Lecture'), AcademicEventType.lecture);
      expect(AcademicEventType.fromString('lab'), AcademicEventType.lab);
      expect(AcademicEventType.fromString('Exam'), AcademicEventType.exam);
      expect(AcademicEventType.fromString('deadline'), AcademicEventType.deadline);
      expect(AcademicEventType.fromString('collegeEvent'),
          AcademicEventType.collegeEvent);
      expect(AcademicEventType.fromString('appointment'),
          AcademicEventType.appointment);
      expect(AcademicEventType.fromString('blockedTime'),
          AcademicEventType.blockedTime);
      expect(AcademicEventType.fromString('other'), AcademicEventType.other);
      expect(AcademicEventType.fromString('unknown_value'),
          AcademicEventType.other);
      expect(AcademicEventType.fromString(null), AcademicEventType.classSession);
    });

    test('3. Recurrence frequency parsing handles strings safely', () {
      expect(AcademicRecurrenceFrequency.fromString('none'),
          AcademicRecurrenceFrequency.none);
      expect(AcademicRecurrenceFrequency.fromString('daily'),
          AcademicRecurrenceFrequency.daily);
      expect(AcademicRecurrenceFrequency.fromString('weekdays'),
          AcademicRecurrenceFrequency.weekdays);
      expect(AcademicRecurrenceFrequency.fromString('weekly'),
          AcademicRecurrenceFrequency.weekly);
      expect(AcademicRecurrenceFrequency.fromString('biweekly'),
          AcademicRecurrenceFrequency.biweekly);
      expect(AcademicRecurrenceFrequency.fromString('monthly'),
          AcademicRecurrenceFrequency.monthly);
      expect(AcademicRecurrenceFrequency.fromString('invalid'),
          AcademicRecurrenceFrequency.none);
      expect(AcademicRecurrenceFrequency.fromString(null),
          AcademicRecurrenceFrequency.none);
    });

    test('4. AcademicRecurrenceRule toJson and fromJson roundtrip', () {
      final until = DateTime(2026, 12, 31, 23, 59);
      const rule = AcademicRecurrenceRule(
        frequency: AcademicRecurrenceFrequency.weekly,
        interval: 2,
        daysOfWeek: [1, 3, 5],
        until: null,
        count: 10,
      );

      final json = rule.toJson();
      expect(json['frequency'], 'weekly');
      expect(json['interval'], 2);
      expect(json['daysOfWeek'], [1, 3, 5]);
      expect(json['count'], 10);

      final restored = AcademicRecurrenceRule.fromJson(json);
      expect(restored.frequency, AcademicRecurrenceFrequency.weekly);
      expect(restored.interval, 2);
      expect(restored.daysOfWeek, [1, 3, 5]);
      expect(restored.count, 10);
      expect(restored.isActive, isTrue);

      final ruleWithUntil = rule.copyWith(until: until, clearCount: true);
      final jsonUntil = ruleWithUntil.toJson();
      final restoredUntil = AcademicRecurrenceRule.fromJson(jsonUntil);
      expect(restoredUntil.until, until);
      expect(restoredUntil.count, isNull);
    });

    test('5. AcademicCalendarEvent toJson and fromJson roundtrip', () {
      final start = DateTime(2026, 9, 22, 14, 0);
      final end = DateTime(2026, 9, 22, 15, 30);
      final event = AcademicCalendarEvent(
        id: 'evt_physics_lab',
        userId: 'user_456',
        title: 'Physics Lab Session',
        description: 'Bring lab coat and calculation notebook',
        type: AcademicEventType.lab,
        startAt: start,
        endAt: end,
        allDay: false,
        location: 'Hall B, Science Block',
        subjectId: 'sub_physics',
        examId: 'exam_term1',
        taskId: 'task_report',
        isFixed: true,
        colorValue: 0xFF26A69A,
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.weekly,
          daysOfWeek: [2],
        ),
        reminderMinutesBefore: 15,
      );

      final json = event.toJson();
      expect(json['id'], 'evt_physics_lab');
      expect(json['title'], 'Physics Lab Session');
      expect(json['type'], 'lab');
      expect(json['location'], 'Hall B, Science Block');
      expect(json['reminderMinutesBefore'], 15);

      final restored = AcademicCalendarEvent.fromJson(json);
      expect(restored.id, event.id);
      expect(restored.userId, event.userId);
      expect(restored.title, event.title);
      expect(restored.description, event.description);
      expect(restored.type, AcademicEventType.lab);
      expect(restored.startAt, start);
      expect(restored.endAt, end);
      expect(restored.location, 'Hall B, Science Block');
      expect(restored.subjectId, 'sub_physics');
      expect(restored.examId, 'exam_term1');
      expect(restored.taskId, 'task_report');
      expect(restored.isFixed, isTrue);
      expect(restored.colorValue, 0xFF26A69A);
      expect(restored.recurrence?.frequency, AcademicRecurrenceFrequency.weekly);
      expect(restored.recurrence?.daysOfWeek, [2]);
      expect(restored.reminderMinutesBefore, 15);
      expect(restored.durationMinutes, 90);
    });

    test('6. Backward compatibility with minimal legacy JSON', () {
      final legacyJson = {
        'id': 'legacy_1',
        'title': 'Lecture 1',
        'startAt': '2026-09-22T09:00:00.000',
        'endAt': '2026-09-22T10:00:00.000',
      };

      final event = AcademicCalendarEvent.fromJson(legacyJson);
      expect(event.id, 'legacy_1');
      expect(event.userId, '');
      expect(event.title, 'Lecture 1');
      expect(event.type, AcademicEventType.classSession);
      expect(event.allDay, isFalse);
      expect(event.isFixed, isTrue);
      expect(event.location, isNull);
      expect(event.recurrence, isNull);
    });

    test('7. copyWith properly updates fields and respects clear flags', () {
      final event = AcademicCalendarEvent(
        id: 'evt_1',
        userId: 'u1',
        title: 'Original Title',
        type: AcademicEventType.lecture,
        startAt: DateTime(2026, 9, 22, 10, 0),
        endAt: DateTime(2026, 9, 22, 11, 0),
        location: 'Room 101',
        subjectId: 'sub_1',
        reminderMinutesBefore: 30,
        recurrence: const AcademicRecurrenceRule(
          frequency: AcademicRecurrenceFrequency.daily,
        ),
      );

      final updated = event.copyWith(
        title: 'Updated Title',
        clearLocation: true,
        clearSubjectId: true,
        clearReminder: true,
        clearRecurrence: true,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.location, isNull);
      expect(updated.subjectId, isNull);
      expect(updated.reminderMinutesBefore, isNull);
      expect(updated.recurrence, isNull);
      expect(updated.startAt, event.startAt);
    });
  });
}
