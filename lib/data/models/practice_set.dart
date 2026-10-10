import 'package:flutter/foundation.dart';
import 'question.dart';

/// A curated or generated collection of practice questions for a topic/subject.
@immutable
class PracticeSet {
  PracticeSet({
    required this.id,
    required this.title,
    this.topicId,
    this.chapterId,
    this.subjectId,
    this.questionIds = const [],
    this.estimatedMinutes = 15,
    this.difficulty = QuestionDifficulty.medium,
    this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String? topicId;
  final String? chapterId;
  final String? subjectId;
  final List<String> questionIds;
  final int estimatedMinutes;
  final QuestionDifficulty difficulty;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get questionCount => questionIds.length;

  PracticeSet copyWith({
    String? id,
    String? title,
    String? topicId,
    String? chapterId,
    String? subjectId,
    List<String>? questionIds,
    int? estimatedMinutes,
    QuestionDifficulty? difficulty,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PracticeSet(
      id: id ?? this.id,
      title: title ?? this.title,
      topicId: topicId ?? this.topicId,
      chapterId: chapterId ?? this.chapterId,
      subjectId: subjectId ?? this.subjectId,
      questionIds: questionIds ?? this.questionIds,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      difficulty: difficulty ?? this.difficulty,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (topicId != null) 'topicId': topicId,
        if (chapterId != null) 'chapterId': chapterId,
        if (subjectId != null) 'subjectId': subjectId,
        'questionIds': questionIds,
        'estimatedMinutes': estimatedMinutes,
        'difficulty': difficulty.name,
        if (userId != null) 'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PracticeSet.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;
    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null;

    final rawIds = json['questionIds'];
    List<String> parsedIds = const [];
    if (rawIds is List) {
      parsedIds = rawIds.map((e) => e.toString()).toList();
    }

    return PracticeSet(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      topicId: json['topicId'] as String?,
      chapterId: json['chapterId'] as String?,
      subjectId: json['subjectId'] as String?,
      questionIds: parsedIds,
      estimatedMinutes: (json['estimatedMinutes'] as int?) ?? 15,
      difficulty: QuestionDifficulty.fromString(json['difficulty'] as String?),
      userId: json['userId'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeSet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          topicId == other.topicId &&
          chapterId == other.chapterId &&
          subjectId == other.subjectId &&
          listEquals(questionIds, other.questionIds) &&
          estimatedMinutes == other.estimatedMinutes &&
          difficulty == other.difficulty;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        topicId,
        chapterId,
        subjectId,
        Object.hashAll(questionIds),
        estimatedMinutes,
        difficulty,
      );
}
