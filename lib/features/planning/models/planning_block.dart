import 'package:flutter/foundation.dart';

/// A minimal, flexible model for scheduling work blocks (tasks, subject study, or focus sessions).
@immutable
class PlanningBlock {
  PlanningBlock({
    required this.id,
    required this.userId,
    this.taskId,
    this.subjectId,
    this.topicId,
    this.chapterId,
    this.examId,
    this.customTitle,
    required this.startAt,
    required this.endAt,
    this.createdAt,
    this.updatedAt,
  }) {
    assert(
      taskId != null || subjectId != null || topicId != null || (customTitle != null && customTitle!.isNotEmpty),
      'PlanningBlock: must have taskId, subjectId, topicId, or customTitle',
    );
    assert(endAt.isAfter(startAt), 'PlanningBlock: endAt must be after startAt');
  }

  final String id;
  final String userId;
  final String? taskId;
  final String? subjectId;
  final String? topicId;
  final String? chapterId;
  final String? examId;
  final String? customTitle;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isTaskBlock => taskId != null && taskId!.isNotEmpty;
  bool get isSubjectBlock => subjectId != null && subjectId!.isNotEmpty && !isTaskBlock;
  bool get isTopicBlock => topicId != null && topicId!.isNotEmpty;

  PlanningBlock copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? subjectId,
    String? topicId,
    String? chapterId,
    String? examId,
    String? customTitle,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearTaskId = false,
    bool clearSubjectId = false,
    bool clearTopicId = false,
    bool clearChapterId = false,
    bool clearExamId = false,
    bool clearCustomTitle = false,
  }) {
    return PlanningBlock(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      chapterId: clearChapterId ? null : (chapterId ?? this.chapterId),
      examId: clearExamId ? null : (examId ?? this.examId),
      customTitle: clearCustomTitle ? null : (customTitle ?? this.customTitle),
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        if (taskId != null) 'taskId': taskId,
        if (subjectId != null) 'subjectId': subjectId,
        if (topicId != null) 'topicId': topicId,
        if (chapterId != null) 'chapterId': chapterId,
        if (examId != null) 'examId': examId,
        if (customTitle != null) 'customTitle': customTitle,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory PlanningBlock.fromJson(Map<String, dynamic> json) => PlanningBlock(
        id: json['id'] as String,
        userId: json['userId'] as String,
        taskId: json['taskId'] as String?,
        subjectId: json['subjectId'] as String?,
        topicId: json['topicId'] as String?,
        chapterId: json['chapterId'] as String?,
        examId: json['examId'] as String?,
        customTitle: json['customTitle'] as String?,
        startAt: DateTime.parse(json['startAt'] as String),
        endAt: DateTime.parse(json['endAt'] as String),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}
