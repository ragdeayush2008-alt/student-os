import 'package:flutter/foundation.dart';

/// A single practice attempt on an academic topic.
///
/// Local-first, offline-safe, and user-isolated. Represents structured practice
/// (e.g. flashcards, questions, problems, or self-quizzing) with optional question counts,
/// accuracy scores, and notes.
@immutable
class TopicPracticeAttempt {
  TopicPracticeAttempt({
    required this.id,
    this.userId,
    required this.topicId,
    this.subjectId,
    this.chapterId,
    DateTime? startedAt,
    this.completedAt,
    this.durationSec = 0,
    this.totalQuestions,
    this.correctAnswers,
    this.incorrectAnswers,
    this.score,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : startedAt = startedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String? userId;
  final String topicId;
  final String? subjectId;
  final String? chapterId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSec;
  final int? totalQuestions;
  final int? correctAnswers;
  final int? incorrectAnswers;
  final double? score;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => completedAt != null || durationSec > 0;

  Duration get duration => Duration(seconds: durationSec);

  /// Accuracy percentage (0-100) if questions were tracked.
  int? get accuracyPercentage {
    if (totalQuestions == null || totalQuestions! <= 0) return null;
    if (correctAnswers == null) return null;
    return ((correctAnswers! / totalQuestions!) * 100).round().clamp(0, 100);
  }

  TopicPracticeAttempt copyWith({
    String? id,
    String? userId,
    String? topicId,
    String? subjectId,
    String? chapterId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSec,
    int? totalQuestions,
    int? correctAnswers,
    int? incorrectAnswers,
    double? score,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearCompletedAt = false,
    bool clearTotalQuestions = false,
    bool clearCorrectAnswers = false,
    bool clearIncorrectAnswers = false,
    bool clearScore = false,
    bool clearNotes = false,
  }) {
    return TopicPracticeAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      subjectId: subjectId ?? this.subjectId,
      chapterId: chapterId ?? this.chapterId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      durationSec: durationSec ?? this.durationSec,
      totalQuestions:
          clearTotalQuestions ? null : (totalQuestions ?? this.totalQuestions),
      correctAnswers:
          clearCorrectAnswers ? null : (correctAnswers ?? this.correctAnswers),
      incorrectAnswers: clearIncorrectAnswers
          ? null
          : (incorrectAnswers ?? this.incorrectAnswers),
      score: clearScore ? null : (score ?? this.score),
      notes: clearNotes ? '' : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'userId': userId,
        'topicId': topicId,
        if (subjectId != null) 'subjectId': subjectId,
        if (chapterId != null) 'chapterId': chapterId,
        'startedAt': startedAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'durationSec': durationSec,
        if (totalQuestions != null) 'totalQuestions': totalQuestions,
        if (correctAnswers != null) 'correctAnswers': correctAnswers,
        if (incorrectAnswers != null) 'incorrectAnswers': incorrectAnswers,
        if (score != null) 'score': score,
        if (notes.isNotEmpty) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TopicPracticeAttempt.fromJson(Map<String, dynamic> json) {
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

    return TopicPracticeAttempt(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      topicId: (json['topicId'] as String?) ?? '',
      subjectId: json['subjectId'] as String?,
      chapterId: json['chapterId'] as String?,
      startedAt: startedAt,
      completedAt: completedAt,
      durationSec: (json['durationSec'] as int?) ?? 0,
      totalQuestions: json['totalQuestions'] as int?,
      correctAnswers: json['correctAnswers'] as int?,
      incorrectAnswers: json['incorrectAnswers'] as int?,
      score: (json['score'] as num?)?.toDouble(),
      notes: (json['notes'] as String?) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicPracticeAttempt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          topicId == other.topicId &&
          subjectId == other.subjectId &&
          chapterId == other.chapterId &&
          durationSec == other.durationSec &&
          totalQuestions == other.totalQuestions &&
          correctAnswers == other.correctAnswers &&
          incorrectAnswers == other.incorrectAnswers &&
          score == other.score &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        topicId,
        subjectId,
        chapterId,
        durationSec,
        totalQuestions,
        correctAnswers,
        incorrectAnswers,
        score,
        notes,
      );
}
