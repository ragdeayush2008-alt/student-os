import 'package:flutter/foundation.dart';

/// Self-reported or practice-derived recall outcome of a revision session.
enum RevisionRecallOutcome {
  /// Student successfully recalled all key concepts ("I Knew It").
  knew('I Knew It', 1.0),

  /// Student struggled or only recalled some concepts ("Partly Knew It").
  partial('Partly Knew It', 0.5),

  /// Student could not recall the core concepts ("Didn't Know It").
  forgot('Didn\'t Know It', 0.0),

  /// Derived from an objective quiz/practice session.
  fromPractice('Derived from Practice', 0.8),

  /// Completed without explicit self-assessment.
  unassessed('Standard Review', 0.7);

  const RevisionRecallOutcome(this.label, this.scoreMultiplier);
  final String label;
  final double scoreMultiplier;

  static RevisionRecallOutcome fromString(String? val) {
    if (val == null || val.isEmpty) return RevisionRecallOutcome.unassessed;
    for (final o in RevisionRecallOutcome.values) {
      if (o.name.toLowerCase() == val.toLowerCase()) return o;
    }
    return RevisionRecallOutcome.unassessed;
  }
}

/// A single completed revision record on an academic topic or resource.
///
/// Local-first, offline-safe, and user-isolated. Represents the authoritative
/// historical record of spaced learning.
@immutable
class RevisionRecord {
  RevisionRecord({
    required this.id,
    this.userId,
    required this.topicId,
    this.chapterId,
    this.subjectId,
    this.examId,
    DateTime? startedAt,
    DateTime? completedAt,
    this.durationSec = 0,
    this.recallOutcome = RevisionRecallOutcome.unassessed,
    this.notes = '',
    this.source = 'session',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : startedAt = startedAt ?? DateTime.now(),
        completedAt = completedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String? userId;
  final String topicId;
  final String? chapterId;
  final String? subjectId;
  final String? examId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSec;
  final RevisionRecallOutcome? recallOutcome;
  final String notes;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get durationMinutes => durationSec ~/ 60;
  bool get isSuccessfulRecall =>
      recallOutcome == RevisionRecallOutcome.knew ||
      recallOutcome == RevisionRecallOutcome.fromPractice;

  RevisionRecord copyWith({
    String? id,
    String? userId,
    String? topicId,
    String? chapterId,
    String? subjectId,
    String? examId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSec,
    RevisionRecallOutcome? recallOutcome,
    String? notes,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RevisionRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      chapterId: chapterId ?? this.chapterId,
      subjectId: subjectId ?? this.subjectId,
      examId: examId ?? this.examId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSec: durationSec ?? this.durationSec,
      recallOutcome: recallOutcome ?? this.recallOutcome,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'userId': userId,
        'topicId': topicId,
        if (chapterId != null) 'chapterId': chapterId,
        if (subjectId != null) 'subjectId': subjectId,
        if (examId != null) 'examId': examId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'durationSec': durationSec,
        if (recallOutcome != null) 'recallOutcome': recallOutcome!.name,
        if (notes.isNotEmpty) 'notes': notes,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RevisionRecord.fromJson(Map<String, dynamic> json) {
    final startedAt = json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : null;
    final completedAt = json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null;
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;
    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null;

    return RevisionRecord(
      id: (json['id'] as String?) ?? '',
      userId: json['userId'] as String?,
      topicId: (json['topicId'] as String?) ?? '',
      chapterId: json['chapterId'] as String?,
      subjectId: json['subjectId'] as String?,
      examId: json['examId'] as String?,
      startedAt: startedAt,
      completedAt: completedAt,
      durationSec: (json['durationSec'] as int?) ?? 0,
      recallOutcome: RevisionRecallOutcome.fromString(
        json['recallOutcome'] as String?,
      ),
      notes: (json['notes'] as String?) ?? '',
      source: (json['source'] as String?) ?? 'session',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevisionRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          topicId == other.topicId &&
          chapterId == other.chapterId &&
          subjectId == other.subjectId &&
          examId == other.examId &&
          durationSec == other.durationSec &&
          recallOutcome == other.recallOutcome &&
          notes == other.notes &&
          source == other.source;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        topicId,
        chapterId,
        subjectId,
        examId,
        durationSec,
        recallOutcome,
        notes,
        source,
      );
}
