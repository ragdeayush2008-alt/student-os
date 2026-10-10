import 'package:meta/meta.dart';

/// Type of activity that can generate XP.
enum XpEventType {
  taskCompleted('Task Completed'),
  studySessionCompleted('Study Session Completed'),
  syllabusTopicCompleted('Syllabus Topic Completed'),
  examCompleted('Exam Completed'),
  goalMilestone('Goal Milestone Reached'),
  weeklyConsistency('Weekly Consistency'),
  streakMilestone('Streak Milestone');

  const XpEventType(this.label);
  final String label;
}

/// A single immutable XP earning event.
///
/// The ledger is append-only: events are never modified after creation.
/// Each event captures exactly what happened and why XP was awarded.
@immutable
class XpEvent {
  const XpEvent({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.reason,
    this.taskId,
    this.examId,
    this.subjectId,
    this.metadata,
  });

  /// Unique event ID (prevents duplicate processing).
  final String id;

  /// Type of activity that triggered this XP award.
  final XpEventType type;

  /// XP amount awarded (always positive).
  final int amount;

  /// When this event occurred.
  final DateTime timestamp;

  /// Human-readable explanation shown in XP history.
  final String reason;

  /// Related task ID (if applicable).
  final String? taskId;

  /// Related exam ID (if applicable).
  final String? examId;

  /// Related subject ID (if applicable).
  final String? subjectId;

  /// Optional metadata for special cases.
  final Map<String, dynamic>? metadata;

  // ─── JSON serialization ──────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'reason': reason,
    if (taskId != null) 'taskId': taskId,
    if (examId != null) 'examId': examId,
    if (subjectId != null) 'subjectId': subjectId,
    if (metadata != null) 'metadata': metadata,
  };

  factory XpEvent.fromJson(Map<String, dynamic> json) {
    return XpEvent(
      id: json['id'] as String,
      type: XpEventType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => XpEventType.taskCompleted,
      ),
      amount: json['amount'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      reason: json['reason'] as String? ?? '',
      taskId: json['taskId'] as String?,
      examId: json['examId'] as String?,
      subjectId: json['subjectId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  XpEvent copyWith({
    String? id,
    XpEventType? type,
    int? amount,
    DateTime? timestamp,
    String? reason,
    String? taskId,
    String? examId,
    String? subjectId,
    Map<String, dynamic>? metadata,
  }) {
    return XpEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      reason: reason ?? this.reason,
      taskId: taskId ?? this.taskId,
      examId: examId ?? this.examId,
      subjectId: subjectId ?? this.subjectId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XpEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
