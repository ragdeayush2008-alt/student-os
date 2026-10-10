import 'dart:math' as math;

/// A single completed (or cancelled-while-tracked) study session.
///
/// Mirrors the [StudentTask] data pattern: immutable fields, [copyWith],
/// [toJson]/[fromJson] for persistence via [StorageService]. A session records
/// what was studied, when it started and ended, and how long it lasted.
class StudySession {
  StudySession({
    required this.id,
    required this.subject,
    this.taskId,
    this.subjectId,
    this.topicId,
    this.chapterId,
    this.examId,
    this.focusSessionId,
    DateTime? startedAt,
    this.endedAt,
    this.durationSec = 0,
    this.completed = true,
    this.note = '',
  }) : startedAt = startedAt ?? DateTime.now();

  final String id;

  /// The academic subject / category studied during the session.
  final String subject;

  /// Optional link to a [StudentTask] this session focused on.
  final String? taskId;

  /// Optional subject reference ID.
  final String? subjectId;

  /// Optional topic reference ID.
  final String? topicId;

  /// Optional chapter reference ID.
  final String? chapterId;

  /// Optional exam reference ID.
  final String? examId;

  /// Source Focus session id when this record was bridged from a Focus
  /// completion. Nullable for backward compatibility; used for idempotent
  /// bridging so restarts/recovery never double-count the same session.
  final String? focusSessionId;

  final DateTime startedAt;
  final DateTime? endedAt;

  /// Length of the session, in whole seconds.
  final int durationSec;

  /// Whether the session reached a completed/ended state (vs cancelled).
  final bool completed;

  final String note;

  /// The calendar date the session began on (time ignored).
  DateTime get date => DateTime(startedAt.year, startedAt.month, startedAt.day);

  /// The session length as a [Duration].
  Duration get duration => Duration(seconds: durationSec);

  /// Total elapsed, counting from [startedAt] to [endedAt] when available.
  Duration get totalElapsed {
    if (endedAt == null) return duration;
    final span = endedAt!.difference(startedAt);
    final secs = math.max(0, span.inSeconds);
    return Duration(seconds: secs);
  }

  bool get isCompleted => completed;

  StudySession copyWith({
    String? subject,
    String? taskId,
    String? subjectId,
    String? topicId,
    String? chapterId,
    String? examId,
    String? focusSessionId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSec,
    bool? completed,
    String? note,
    bool clearTaskId = false,
    bool clearSubjectId = false,
    bool clearTopicId = false,
    bool clearChapterId = false,
    bool clearExamId = false,
    bool clearFocusSessionId = false,
  }) {
    return StudySession(
      id: id,
      subject: subject ?? this.subject,
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      chapterId: clearChapterId ? null : (chapterId ?? this.chapterId),
      examId: clearExamId ? null : (examId ?? this.examId),
      focusSessionId: clearFocusSessionId
          ? null
          : (focusSessionId ?? this.focusSessionId),
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSec: durationSec ?? this.durationSec,
      completed: completed ?? this.completed,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    if (taskId != null) 'taskId': taskId,
    if (subjectId != null) 'subjectId': subjectId,
    if (topicId != null) 'topicId': topicId,
    if (chapterId != null) 'chapterId': chapterId,
    if (examId != null) 'examId': examId,
    if (focusSessionId != null) 'focusSessionId': focusSessionId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'durationSec': durationSec,
    'completed': completed,
    'note': note,
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['id'] as String,
    subject: (json['subject'] as String?) ?? '',
    taskId: json['taskId'] as String?,
    subjectId: json['subjectId'] as String?,
    topicId: json['topicId'] as String?,
    chapterId: json['chapterId'] as String?,
    examId: json['examId'] as String?,
    focusSessionId: json['focusSessionId'] as String?,
    startedAt: json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : null,
    endedAt: json['endedAt'] != null
        ? DateTime.parse(json['endedAt'] as String)
        : null,
    durationSec: (json['durationSec'] as int?) ?? 0,
    completed: (json['completed'] as bool?) ?? true,
    note: (json['note'] as String?) ?? '',
  );
}
