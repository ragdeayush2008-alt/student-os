import 'package:flutter/foundation.dart';

enum TopicImportance {
  low('Low', 0.8),
  normal('Normal', 1.0),
  high('High', 1.3),
  critical('Critical', 1.6);

  const TopicImportance(this.label, this.weightMultiplier);
  final String label;
  final double weightMultiplier;

  static TopicImportance fromString(String? val) {
    if (val == null || val.isEmpty) return TopicImportance.normal;
    for (final t in TopicImportance.values) {
      if (t.name.toLowerCase() == val.toLowerCase()) return t;
    }
    return TopicImportance.normal;
  }
}

enum TopicStatus {
  notStarted('Not Started'),
  inProgress('In Progress'),
  studied('Studied'),
  needsRevision('Needs Revision'),
  mastered('Mastered');

  const TopicStatus(this.label);
  final String label;
}

enum TopicMasteryState {
  unknown('Unknown'),
  notStarted('Not Started'),
  learning('Learning'),
  familiar('Familiar'),
  strong('Strong');

  const TopicMasteryState(this.label);
  final String label;
}

@immutable
class Topic {
  Topic({
    required this.id,
    required this.chapterId,
    required this.subjectId,
    required this.title,
    this.description = '',
    this.order = 0,
    this.estimatedMinutes = 35,
    this.importance = TopicImportance.normal,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String chapterId;
  final String subjectId;
  final String title;
  final String description;
  final int order;
  final int estimatedMinutes;
  final TopicImportance importance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;

  Topic copyWith({
    String? chapterId,
    String? subjectId,
    String? title,
    String? description,
    int? order,
    int? estimatedMinutes,
    TopicImportance? importance,
    String? userId,
    bool clearDescription = false,
  }) {
    return Topic(
      id: id,
      chapterId: chapterId ?? this.chapterId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description:
          clearDescription ? '' : (description ?? this.description),
      order: order ?? this.order,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      importance: importance ?? this.importance,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterId': chapterId,
        'subjectId': subjectId,
        'title': title,
        'description': description,
        'order': order,
        'estimatedMinutes': estimatedMinutes,
        'importance': importance.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (userId != null) 'userId': userId,
      };

  factory Topic.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;
    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null;

    return Topic(
      id: json['id'] as String,
      chapterId: (json['chapterId'] as String?) ?? '',
      subjectId: (json['subjectId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      order: (json['order'] as int?) ?? 0,
      estimatedMinutes: (json['estimatedMinutes'] as int?) ?? 35,
      importance: TopicImportance.fromString(json['importance'] as String?),
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: json['userId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topic &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          chapterId == other.chapterId &&
          subjectId == other.subjectId &&
          title == other.title &&
          description == other.description &&
          order == other.order &&
          estimatedMinutes == other.estimatedMinutes &&
          importance == other.importance;

  @override
  int get hashCode => Object.hash(
        id,
        chapterId,
        subjectId,
        title,
        description,
        order,
        estimatedMinutes,
        importance,
      );
}
