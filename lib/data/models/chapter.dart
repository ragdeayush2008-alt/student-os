import 'package:flutter/foundation.dart';

@immutable
class Chapter {
  Chapter({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description = '',
    this.order = 0,
    this.estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String subjectId;
  final String title;
  final String description;
  final int order;
  final int? estimatedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;

  Chapter copyWith({
    String? title,
    String? description,
    int? order,
    int? estimatedMinutes,
    String? userId,
    bool clearDescription = false,
    bool clearEstimatedMinutes = false,
  }) {
    return Chapter(
      id: id,
      subjectId: subjectId,
      title: title ?? this.title,
      description:
          clearDescription ? '' : (description ?? this.description),
      order: order ?? this.order,
      estimatedMinutes: clearEstimatedMinutes
          ? null
          : (estimatedMinutes ?? this.estimatedMinutes),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'description': description,
        'order': order,
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (userId != null) 'userId': userId,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;
    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null;

    return Chapter(
      id: json['id'] as String,
      subjectId: (json['subjectId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      order: (json['order'] as int?) ?? 0,
      estimatedMinutes: json['estimatedMinutes'] as int?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: json['userId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subjectId == other.subjectId &&
          title == other.title &&
          description == other.description &&
          order == other.order &&
          estimatedMinutes == other.estimatedMinutes;

  @override
  int get hashCode => Object.hash(
        id,
        subjectId,
        title,
        description,
        order,
        estimatedMinutes,
      );
}
