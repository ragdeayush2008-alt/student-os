import 'package:flutter/foundation.dart';

/// State of a topic in the Spaced Repetition / Adaptive Revision cycle.
enum RevisionState {
  notReady('Not Ready'),
  newTopic('New'),
  learning('Learning'),
  due('Due'),
  overdue('Overdue'),
  stable('Stable'),
  strong('Strong'),
  mastered('Mastered');

  const RevisionState(this.label);
  final String label;

  static RevisionState fromString(String? val) {
    if (val == null || val.isEmpty) return RevisionState.newTopic;
    for (final s in RevisionState.values) {
      if (s.name.toLowerCase() == val.toLowerCase()) return s;
    }
    return RevisionState.newTopic;
  }
}

/// Categorization of a topic in the Revision Queue.
enum RevisionDueCategory {
  overdue('Overdue'),
  dueNow('Due Now'),
  dueToday('Due Today'),
  needsAttention('Needs Attention'),
  upcoming('Coming Up'),
  stableStrong('Retained');

  const RevisionDueCategory(this.label);
  final String label;
}

/// Persistent spaced repetition scheduling state for a topic or curriculum entity.
@immutable
class RevisionSchedule {
  RevisionSchedule({
    required this.id,
    this.userId,
    required this.topicId,
    this.chapterId,
    this.subjectId,
    this.examId,
    this.state = RevisionState.newTopic,
    this.intervalDays = 1,
    this.lastRevisionAt,
    this.nextRevisionAt,
    this.revisionCount = 0,
    this.successfulRecallCount = 0,
    this.failedRecallCount = 0,
    this.easeFactor = 2.5,
    this.priorityScore = 0.0,
    this.priorityReasons = const [],
    this.suggestedDurationMinutes = 20,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String? userId;
  final String topicId;
  final String? chapterId;
  final String? subjectId;
  final String? examId;
  final RevisionState state;
  final int intervalDays;
  final DateTime? lastRevisionAt;
  final DateTime? nextRevisionAt;
  final int revisionCount;
  final int successfulRecallCount;
  final int failedRecallCount;
  final double easeFactor;
  final double priorityScore;
  final List<String> priorityReasons;
  final int suggestedDurationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDue {
    if (nextRevisionAt == null) return state == RevisionState.due || state == RevisionState.overdue;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(nextRevisionAt!.year, nextRevisionAt!.month, nextRevisionAt!.day);
    return dueDay.isBefore(today) || dueDay == today;
  }

  bool get isOverdue {
    if (nextRevisionAt == null) return state == RevisionState.overdue;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(nextRevisionAt!.year, nextRevisionAt!.month, nextRevisionAt!.day);
    return dueDay.isBefore(today);
  }

  RevisionSchedule copyWith({
    String? id,
    String? userId,
    String? topicId,
    String? chapterId,
    String? subjectId,
    String? examId,
    RevisionState? state,
    int? intervalDays,
    DateTime? lastRevisionAt,
    DateTime? nextRevisionAt,
    int? revisionCount,
    int? successfulRecallCount,
    int? failedRecallCount,
    double? easeFactor,
    double? priorityScore,
    List<String>? priorityReasons,
    int? suggestedDurationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RevisionSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      chapterId: chapterId ?? this.chapterId,
      subjectId: subjectId ?? this.subjectId,
      examId: examId ?? this.examId,
      state: state ?? this.state,
      intervalDays: intervalDays ?? this.intervalDays,
      lastRevisionAt: lastRevisionAt ?? this.lastRevisionAt,
      nextRevisionAt: nextRevisionAt ?? this.nextRevisionAt,
      revisionCount: revisionCount ?? this.revisionCount,
      successfulRecallCount: successfulRecallCount ?? this.successfulRecallCount,
      failedRecallCount: failedRecallCount ?? this.failedRecallCount,
      easeFactor: easeFactor ?? this.easeFactor,
      priorityScore: priorityScore ?? this.priorityScore,
      priorityReasons: priorityReasons ?? this.priorityReasons,
      suggestedDurationMinutes:
          suggestedDurationMinutes ?? this.suggestedDurationMinutes,
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
        'state': state.name,
        'intervalDays': intervalDays,
        if (lastRevisionAt != null)
          'lastRevisionAt': lastRevisionAt!.toIso8601String(),
        if (nextRevisionAt != null)
          'nextRevisionAt': nextRevisionAt!.toIso8601String(),
        'revisionCount': revisionCount,
        'successfulRecallCount': successfulRecallCount,
        'failedRecallCount': failedRecallCount,
        'easeFactor': easeFactor,
        'priorityScore': priorityScore,
        'priorityReasons': priorityReasons,
        'suggestedDurationMinutes': suggestedDurationMinutes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RevisionSchedule.fromJson(Map<String, dynamic> json) {
    final lastRevisionAt = json['lastRevisionAt'] != null
        ? DateTime.parse(json['lastRevisionAt'] as String)
        : null;
    final nextRevisionAt = json['nextRevisionAt'] != null
        ? DateTime.parse(json['nextRevisionAt'] as String)
        : null;
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;
    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null;

    final rawReasons = json['priorityReasons'];
    List<String> parsedReasons = const [];
    if (rawReasons is List) {
      parsedReasons = rawReasons.map((e) => e.toString()).toList();
    }

    return RevisionSchedule(
      id: (json['id'] as String?) ?? '',
      userId: json['userId'] as String?,
      topicId: (json['topicId'] as String?) ?? '',
      chapterId: json['chapterId'] as String?,
      subjectId: json['subjectId'] as String?,
      examId: json['examId'] as String?,
      state: RevisionState.fromString(json['state'] as String?),
      intervalDays: (json['intervalDays'] as int?) ?? 1,
      lastRevisionAt: lastRevisionAt,
      nextRevisionAt: nextRevisionAt,
      revisionCount: (json['revisionCount'] as int?) ?? 0,
      successfulRecallCount: (json['successfulRecallCount'] as int?) ?? 0,
      failedRecallCount: (json['failedRecallCount'] as int?) ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      priorityScore: (json['priorityScore'] as num?)?.toDouble() ?? 0.0,
      priorityReasons: parsedReasons,
      suggestedDurationMinutes:
          (json['suggestedDurationMinutes'] as int?) ?? 20,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevisionSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          topicId == other.topicId &&
          chapterId == other.chapterId &&
          subjectId == other.subjectId &&
          examId == other.examId &&
          state == other.state &&
          intervalDays == other.intervalDays &&
          revisionCount == other.revisionCount &&
          successfulRecallCount == other.successfulRecallCount &&
          failedRecallCount == other.failedRecallCount &&
          listEquals(priorityReasons, other.priorityReasons);

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        topicId,
        chapterId,
        subjectId,
        examId,
        state,
        intervalDays,
        revisionCount,
        successfulRecallCount,
        failedRecallCount,
        Object.hashAll(priorityReasons),
      );
}
