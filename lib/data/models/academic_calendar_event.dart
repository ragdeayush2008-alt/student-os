import 'package:flutter/material.dart';

/// The category of an academic calendar event.
enum AcademicEventType {
  classSession('Class', Icons.school_rounded, Color(0xFF4A90E2)),
  lecture('Lecture', Icons.cast_for_education_rounded, Color(0xFF5C6BC0)),
  lab('Lab', Icons.science_rounded, Color(0xFF26A69A)),
  exam('Exam', Icons.assignment_late_rounded, Color(0xFFE53935)),
  deadline('Deadline', Icons.timer_outlined, Color(0xFFFF7043)),
  collegeEvent('College Event', Icons.celebration_rounded, Color(0xFFAB47BC)),
  appointment('Appointment', Icons.people_outline_rounded, Color(0xFF29B6F6)),
  blockedTime('Blocked Time', Icons.block_rounded, Color(0xFF78909C)),
  other('Other', Icons.event_note_rounded, Color(0xFF8D6E63));

  const AcademicEventType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static AcademicEventType fromString(String? val) {
    if (val == null || val.isEmpty) return AcademicEventType.classSession;
    for (final t in AcademicEventType.values) {
      if (t.name.toLowerCase() == val.toLowerCase() ||
          t.label.toLowerCase() == val.toLowerCase()) {
        return t;
      }
    }
    return AcademicEventType.other;
  }
}

/// Frequency for recurring academic commitments.
enum AcademicRecurrenceFrequency {
  none('None'),
  daily('Daily'),
  weekdays('Weekdays (Mon-Fri)'),
  weekly('Weekly'),
  biweekly('Every 2 Weeks'),
  monthly('Monthly');

  const AcademicRecurrenceFrequency(this.label);
  final String label;

  static AcademicRecurrenceFrequency fromString(String? val) {
    if (val == null || val.isEmpty) return AcademicRecurrenceFrequency.none;
    for (final f in AcademicRecurrenceFrequency.values) {
      if (f.name.toLowerCase() == val.toLowerCase() ||
          f.label.toLowerCase() == val.toLowerCase()) {
        return f;
      }
    }
    return AcademicRecurrenceFrequency.none;
  }
}

/// Recurrence rule for repeating academic events.
@immutable
class AcademicRecurrenceRule {
  const AcademicRecurrenceRule({
    this.frequency = AcademicRecurrenceFrequency.none,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.until,
    this.count,
  });

  final AcademicRecurrenceFrequency frequency;
  final int interval;
  final List<int> daysOfWeek; // 1 = Monday, ..., 7 = Sunday
  final DateTime? until;
  final int? count;

  bool get isActive => frequency != AcademicRecurrenceFrequency.none;

  AcademicRecurrenceRule copyWith({
    AcademicRecurrenceFrequency? frequency,
    int? interval,
    List<int>? daysOfWeek,
    DateTime? until,
    int? count,
    bool clearUntil = false,
    bool clearCount = false,
  }) {
    return AcademicRecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      until: clearUntil ? null : (until ?? this.until),
      count: clearCount ? null : (count ?? this.count),
    );
  }

  Map<String, dynamic> toJson() => {
        'frequency': frequency.name,
        'interval': interval,
        'daysOfWeek': daysOfWeek,
        if (until != null) 'until': until!.toIso8601String(),
        if (count != null) 'count': count,
      };

  factory AcademicRecurrenceRule.fromJson(Map<String, dynamic> json) {
    return AcademicRecurrenceRule(
      frequency: AcademicRecurrenceFrequency.fromString(
          json['frequency'] as String?),
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      until: json['until'] != null
          ? DateTime.tryParse(json['until'] as String)
          : null,
      count: (json['count'] as num?)?.toInt(),
    );
  }
}

/// An academic calendar event representing a fixed or structured commitment.
///
/// Distinct from a [PlanningBlock] (which represents planned study/revision work).
@immutable
class AcademicCalendarEvent {
  AcademicCalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.type = AcademicEventType.classSession,
    required this.startAt,
    required this.endAt,
    this.allDay = false,
    this.location,
    this.subjectId,
    this.examId,
    this.taskId,
    this.isFixed = true,
    this.colorValue,
    this.recurrence,
    this.reminderMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.baseEventId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now() {
    assert(
      allDay || endAt.isAfter(startAt) || endAt.isAtSameMomentAs(startAt),
      'AcademicCalendarEvent endAt must be >= startAt',
    );
  }

  final String id;
  final String userId;
  final String title;
  final String description;
  final AcademicEventType type;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;
  final String? location;
  final String? subjectId;
  final String? examId;
  final String? taskId;
  final bool isFixed;
  final int? colorValue;
  final AcademicRecurrenceRule? recurrence;
  final int? reminderMinutesBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// If this instance was virtually generated from a recurring base event,
  /// [baseEventId] points to that root event.
  final String? baseEventId;

  bool get isVirtualOccurrence =>
      baseEventId != null && baseEventId!.isNotEmpty;

  Duration get duration => endAt.difference(startAt);
  int get durationMinutes => duration.inMinutes;

  Color get displayColor =>
      colorValue != null ? Color(colorValue!) : type.color;

  AcademicCalendarEvent copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    AcademicEventType? type,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    String? location,
    String? subjectId,
    String? examId,
    String? taskId,
    bool? isFixed,
    int? colorValue,
    AcademicRecurrenceRule? recurrence,
    int? reminderMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? baseEventId,
    bool clearLocation = false,
    bool clearSubjectId = false,
    bool clearExamId = false,
    bool clearTaskId = false,
    bool clearColorValue = false,
    bool clearRecurrence = false,
    bool clearReminder = false,
  }) {
    return AcademicCalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      allDay: allDay ?? this.allDay,
      location: clearLocation ? null : (location ?? this.location),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      examId: clearExamId ? null : (examId ?? this.examId),
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      isFixed: isFixed ?? this.isFixed,
      colorValue: clearColorValue ? null : (colorValue ?? this.colorValue),
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      reminderMinutesBefore: clearReminder
          ? null
          : (reminderMinutesBefore ?? this.reminderMinutesBefore),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      baseEventId: baseEventId ?? this.baseEventId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'type': type.name,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'allDay': allDay,
        if (location != null) 'location': location,
        if (subjectId != null) 'subjectId': subjectId,
        if (examId != null) 'examId': examId,
        if (taskId != null) 'taskId': taskId,
        'isFixed': isFixed,
        if (colorValue != null) 'colorValue': colorValue,
        if (recurrence != null) 'recurrence': recurrence!.toJson(),
        if (reminderMinutesBefore != null)
          'reminderMinutesBefore': reminderMinutesBefore,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AcademicCalendarEvent.fromJson(Map<String, dynamic> json) {
    return AcademicCalendarEvent(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Untitled Event',
      description: (json['description'] as String?) ?? '',
      type: AcademicEventType.fromString(json['type'] as String?),
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      allDay: (json['allDay'] as bool?) ?? false,
      location: json['location'] as String?,
      subjectId: json['subjectId'] as String?,
      examId: json['examId'] as String?,
      taskId: json['taskId'] as String?,
      isFixed: (json['isFixed'] as bool?) ?? true,
      colorValue: (json['colorValue'] as num?)?.toInt(),
      recurrence: json['recurrence'] != null
          ? AcademicRecurrenceRule.fromJson(
              json['recurrence'] as Map<String, dynamic>)
          : null,
      reminderMinutesBefore:
          (json['reminderMinutesBefore'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
