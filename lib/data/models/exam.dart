import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Status of an exam.
enum ExamStatus {
  upcoming('Upcoming'),
  completed('Completed'),
  cancelled('Cancelled');

  const ExamStatus(this.label);
  final String label;
}

/// A single syllabus topic/item linked to an exam.
@immutable
class SyllabusItem {
  SyllabusItem({
    required this.id,
    required this.title,
    this.completed = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;

  SyllabusItem copyWith({
    String? title,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return SyllabusItem(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory SyllabusItem.fromJson(Map<String, dynamic> json) {
    return SyllabusItem(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      completed: (json['completed'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

/// An academic exam with optional syllabus tracking.
@immutable
class StudentExam {
  StudentExam({
    required this.id,
    required this.title,
    this.subject = '',
    this.examDateTime,
    this.notes = '',
    this.status = ExamStatus.upcoming,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syllabusItems = const [],
    this.reminder7Days = false,
    this.reminder3Days = false,
    this.reminder1Day = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String subject;
  final DateTime? examDateTime;
  final String notes;
  final ExamStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SyllabusItem> syllabusItems;
  final bool reminder7Days;
  final bool reminder3Days;
  final bool reminder1Day;

  // ─── Convenience getters ───────────────────────────────────────────

  bool get isUpcoming => status == ExamStatus.upcoming;
  bool get isCompleted => status == ExamStatus.completed;
  bool get isCancelled => status == ExamStatus.cancelled;

  /// Days until the exam (negative if past).
  int? get daysUntilExam {
    if (examDateTime == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDay = DateTime(
      examDateTime!.year,
      examDateTime!.month,
      examDateTime!.day,
    );
    return examDay.difference(today).inDays;
  }

  /// Human-readable countdown string.
  String? get countdown {
    final days = daysUntilExam;
    if (days == null) return null;
    if (days < 0) return 'Past due';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days < 7) return '$days days';
    if (days < 14) return '1 week';
    final weeks = days ~/ 7;
    if (days % 7 == 0) return '$weeks weeks';
    return '$weeks weeks, ${days % 7} days';
  }

  /// Inclusive preparation window in calendar days: today through the exam
  /// day. E.g. 1 Oct → 10 Oct is 9 days left but a 10-day window. Null when
  /// no date is set, 0 when the exam is past.
  int? get preparationWindowDays {
    if (examDateTime == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDay = DateTime(
      examDateTime!.year,
      examDateTime!.month,
      examDateTime!.day,
    );
    if (examDay.isBefore(today)) return 0;
    return examDay.difference(today).inDays + 1;
  }

  /// First calendar date of the preparation window (today, or the exam day
  /// itself when today is past it). Null when no date is set.
  DateTime? get preparationStart {
    if (examDateTime == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDay = DateTime(
      examDateTime!.year,
      examDateTime!.month,
      examDateTime!.day,
    );
    return examDay.isBefore(today) ? examDay : today;
  }

  /// Syllabus completion progress (0.0–1.0).
  double get syllabusProgress {
    if (syllabusItems.isEmpty) return 0;
    final completed = syllabusItems.where((s) => s.completed).length;
    return completed / syllabusItems.length;
  }

  int get syllabusCompleted => syllabusItems.where((s) => s.completed).length;

  int get syllabusTotal => syllabusItems.length;

  bool get hasSyllabus => syllabusItems.isNotEmpty;

  bool get allSyllabusComplete =>
      hasSyllabus && syllabusItems.every((s) => s.completed);

  // ─── copyWith ──────────────────────────────────────────────────────

  StudentExam copyWith({
    String? title,
    String? subject,
    DateTime? examDateTime,
    String? notes,
    ExamStatus? status,
    List<SyllabusItem>? syllabusItems,
    bool? reminder7Days,
    bool? reminder3Days,
    bool? reminder1Day,
    bool clearExamDateTime = false,
  }) {
    return StudentExam(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      examDateTime: clearExamDateTime
          ? null
          : (examDateTime ?? this.examDateTime),
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      syllabusItems: syllabusItems ?? this.syllabusItems,
      reminder7Days: reminder7Days ?? this.reminder7Days,
      reminder3Days: reminder3Days ?? this.reminder3Days,
      reminder1Day: reminder1Day ?? this.reminder1Day,
    );
  }

  // ─── Serialization ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'examDateTime': examDateTime?.toIso8601String(),
    'notes': notes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'syllabusItems': syllabusItems.map((s) => s.toJson()).toList(),
    'reminder7Days': reminder7Days,
    'reminder3Days': reminder3Days,
    'reminder1Day': reminder1Day,
  };

  factory StudentExam.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;

    return StudentExam(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: (json['subject'] as String?) ?? '',
      examDateTime: json['examDateTime'] != null
          ? DateTime.parse(json['examDateTime'] as String)
          : null,
      notes: (json['notes'] as String?) ?? '',
      status: ExamStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ExamStatus.upcoming,
      ),
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      syllabusItems:
          (json['syllabusItems'] as List<dynamic>?)
              ?.map((s) => SyllabusItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      reminder7Days: (json['reminder7Days'] as bool?) ?? false,
      reminder3Days: (json['reminder3Days'] as bool?) ?? false,
      reminder1Day: (json['reminder1Day'] as bool?) ?? false,
    );
  }
}
