import 'package:flutter/foundation.dart';

enum QuestionType {
  multipleChoice('Multiple Choice'),
  singleChoice('Single Choice'),
  trueFalse('True/False');

  const QuestionType(this.label);
  final String label;

  static QuestionType fromString(String? val) {
    if (val == null || val.isEmpty) return QuestionType.multipleChoice;
    for (final t in QuestionType.values) {
      if (t.name.toLowerCase() == val.toLowerCase()) return t;
    }
    return QuestionType.multipleChoice;
  }
}

enum QuestionDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const QuestionDifficulty(this.label);
  final String label;

  static QuestionDifficulty fromString(String? val) {
    if (val == null || val.isEmpty) return QuestionDifficulty.medium;
    for (final d in QuestionDifficulty.values) {
      if (d.name.toLowerCase() == val.toLowerCase()) return d;
    }
    return QuestionDifficulty.medium;
  }
}

/// A practice question associated with a topic/chapter/subject.
@immutable
class Question {
  Question({
    required this.id,
    required this.topicId,
    this.chapterId,
    required this.subjectId,
    required this.questionText,
    this.type = QuestionType.multipleChoice,
    this.options = const [],
    required this.correctAnswer,
    this.explanation,
    this.difficulty = QuestionDifficulty.medium,
    this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String topicId;
  final String? chapterId;
  final String subjectId;
  final String questionText;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final QuestionDifficulty difficulty;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isOptionCorrect(String option) {
    return option.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }

  Question copyWith({
    String? id,
    String? topicId,
    String? chapterId,
    String? subjectId,
    String? questionText,
    QuestionType? type,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    QuestionDifficulty? difficulty,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearExplanation = false,
  }) {
    return Question(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      chapterId: chapterId ?? this.chapterId,
      subjectId: subjectId ?? this.subjectId,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: clearExplanation ? null : (explanation ?? this.explanation),
      difficulty: difficulty ?? this.difficulty,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topicId': topicId,
        if (chapterId != null) 'chapterId': chapterId,
        'subjectId': subjectId,
        'questionText': questionText,
        'type': type.name,
        'options': options,
        'correctAnswer': correctAnswer,
        if (explanation != null) 'explanation': explanation,
        'difficulty': difficulty.name,
        if (userId != null) 'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Question.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;
    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null;

    final rawOptions = json['options'];
    List<String> parsedOptions = const [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    return Question(
      id: (json['id'] as String?) ?? '',
      topicId: (json['topicId'] as String?) ?? '',
      chapterId: json['chapterId'] as String?,
      subjectId: (json['subjectId'] as String?) ?? '',
      questionText: (json['questionText'] as String?) ?? '',
      type: QuestionType.fromString(json['type'] as String?),
      options: parsedOptions,
      correctAnswer: (json['correctAnswer'] as String?) ?? '',
      explanation: json['explanation'] as String?,
      difficulty: QuestionDifficulty.fromString(json['difficulty'] as String?),
      userId: json['userId'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          topicId == other.topicId &&
          chapterId == other.chapterId &&
          subjectId == other.subjectId &&
          questionText == other.questionText &&
          type == other.type &&
          listEquals(options, other.options) &&
          correctAnswer == other.correctAnswer &&
          explanation == other.explanation &&
          difficulty == other.difficulty;

  @override
  int get hashCode => Object.hash(
        id,
        topicId,
        chapterId,
        subjectId,
        questionText,
        type,
        Object.hashAll(options),
        correctAnswer,
        explanation,
        difficulty,
      );
}
