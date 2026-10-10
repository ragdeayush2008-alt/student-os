import 'package:flutter/foundation.dart';

/// Immutable navigation context preserved across Subject → Topic → Study → Focus,
/// Task → Planning → Focus, Exam → Revision → Focus, PlanningBlock → Focus,
/// and Assistant → Focus flows.
///
/// All fields are nullable so any entry point can provide partial context
/// without losing what is already known. Backward compatible: existing callers
/// that pass individual IDs keep working; new callers should prefer this object.
@immutable
class FocusLaunchContext {
  const FocusLaunchContext({
    this.subjectId,
    this.subjectName,
    this.chapterId,
    this.topicId,
    this.topicName,
    this.taskId,
    this.taskTitle,
    this.examId,
    this.examTitle,
    this.planningBlockId,
    this.focusTitle,
    this.duration,
  });

  final String? subjectId;
  final String? subjectName;
  final String? chapterId;
  final String? topicId;
  final String? topicName;
  final String? taskId;
  final String? taskTitle;
  final String? examId;
  final String? examTitle;
  final String? planningBlockId;
  final String? focusTitle;
  final Duration? duration;

  bool get hasSubject => subjectId != null && subjectId!.isNotEmpty;
  bool get hasTopic => topicId != null && topicId!.isNotEmpty;
  bool get hasTask => taskId != null && taskId!.isNotEmpty;
  bool get hasExam => examId != null && examId!.isNotEmpty;
  bool get hasPlanningBlock =>
      planningBlockId != null && planningBlockId!.isNotEmpty;

  /// Returns a copy with the given fields replaced. Null arguments keep the
  /// existing value; use [clearPlanningBlock] to explicitly drop the block id.
  FocusLaunchContext copyWith({
    String? subjectId,
    String? subjectName,
    String? chapterId,
    String? topicId,
    String? topicName,
    String? taskId,
    String? taskTitle,
    String? examId,
    String? examTitle,
    String? planningBlockId,
    String? focusTitle,
    Duration? duration,
    bool clearPlanningBlock = false,
  }) {
    return FocusLaunchContext(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      chapterId: chapterId ?? this.chapterId,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      examId: examId ?? this.examId,
      examTitle: examTitle ?? this.examTitle,
      planningBlockId: clearPlanningBlock
          ? null
          : (planningBlockId ?? this.planningBlockId),
      focusTitle: focusTitle ?? this.focusTitle,
      duration: duration ?? this.duration,
    );
  }

  /// Merges [other] into this context, preferring non-null values from [other].
  FocusLaunchContext merge(FocusLaunchContext other) {
    return FocusLaunchContext(
      subjectId: other.subjectId ?? subjectId,
      subjectName: other.subjectName ?? subjectName,
      chapterId: other.chapterId ?? chapterId,
      topicId: other.topicId ?? topicId,
      topicName: other.topicName ?? topicName,
      taskId: other.taskId ?? taskId,
      taskTitle: other.taskTitle ?? taskTitle,
      examId: other.examId ?? examId,
      examTitle: other.examTitle ?? examTitle,
      planningBlockId: other.planningBlockId ?? planningBlockId,
      focusTitle: other.focusTitle ?? focusTitle,
      duration: other.duration ?? duration,
    );
  }

  Map<String, dynamic> toJson() => {
        if (subjectId != null) 'subjectId': subjectId,
        if (subjectName != null) 'subjectName': subjectName,
        if (chapterId != null) 'chapterId': chapterId,
        if (topicId != null) 'topicId': topicId,
        if (topicName != null) 'topicName': topicName,
        if (taskId != null) 'taskId': taskId,
        if (taskTitle != null) 'taskTitle': taskTitle,
        if (examId != null) 'examId': examId,
        if (examTitle != null) 'examTitle': examTitle,
        if (planningBlockId != null) 'planningBlockId': planningBlockId,
        if (focusTitle != null) 'focusTitle': focusTitle,
        if (duration != null) 'durationSeconds': duration!.inSeconds,
      };

  factory FocusLaunchContext.fromJson(Map<String, dynamic> json) {
    return FocusLaunchContext(
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String?,
      chapterId: json['chapterId'] as String?,
      topicId: json['topicId'] as String?,
      topicName: json['topicName'] as String?,
      taskId: json['taskId'] as String?,
      taskTitle: json['taskTitle'] as String?,
      examId: json['examId'] as String?,
      examTitle: json['examTitle'] as String?,
      planningBlockId: json['planningBlockId'] as String?,
      focusTitle: json['focusTitle'] as String?,
      duration: json['durationSeconds'] != null
          ? Duration(seconds: (json['durationSeconds'] as int))
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FocusLaunchContext &&
        other.subjectId == subjectId &&
        other.subjectName == subjectName &&
        other.chapterId == chapterId &&
        other.topicId == topicId &&
        other.topicName == topicName &&
        other.taskId == taskId &&
        other.taskTitle == taskTitle &&
        other.examId == examId &&
        other.examTitle == examTitle &&
        other.planningBlockId == planningBlockId &&
        other.focusTitle == focusTitle &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(
        subjectId,
        subjectName,
        chapterId,
        topicId,
        topicName,
        taskId,
        taskTitle,
        examId,
        examTitle,
        planningBlockId,
        focusTitle,
        duration,
      );

  @override
  String toString() =>
      'FocusLaunchContext(subject:$subjectId topic:$topicId chapter:$chapterId '
      'task:$taskId exam:$examId block:$planningBlockId)';
}
