import 'package:flutter/material.dart';

/// Priority level for a student task.
enum TaskPriority {
  low('Low', Icons.arrow_downward_rounded, Color(0xFF6F967F)),
  medium('Medium', Icons.remove_rounded, Color(0xFF285C4D)),
  high('High', Icons.arrow_upward_rounded, Color(0xFF7A8450)),
  critical('Critical', Icons.priority_high_rounded, Color(0xFF1F5C44));

  const TaskPriority(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Lifecycle status of a task.
enum TaskStatus {
  active('Active'),
  completed('Completed');

  const TaskStatus(this.label);
  final String label;
}

/// Recurrence frequency for a task.
enum RecurrenceFrequency {
  none('None'),
  daily('Daily'),
  weekdays('Weekdays'),
  weekly('Weekly');

  const RecurrenceFrequency(this.label);
  final String label;
}

/// Defines how a task repeats.
@immutable
class TaskRecurrence {
  const TaskRecurrence({
    required this.frequency,
    this.customWeekdays = const [],
  });

  final RecurrenceFrequency frequency;

  /// For weekly recurrence: the specific weekday numbers (1=Mon..7=Sun).
  final List<int> customWeekdays;

  /// Whether this recurrence has any active rule.
  bool get isActive => frequency != RecurrenceFrequency.none;

  Map<String, dynamic> toJson() => {
    'frequency': frequency.name,
    'customWeekdays': customWeekdays,
  };

  factory TaskRecurrence.fromJson(Map<String, dynamic> json) {
    return TaskRecurrence(
      frequency: RecurrenceFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => RecurrenceFrequency.none,
      ),
      customWeekdays:
          (json['customWeekdays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }
}

/// A lightweight subtask/checklist item.
@immutable
class StudentSubtask {
  StudentSubtask({
    required this.id,
    required this.title,
    this.completed = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;

  StudentSubtask copyWith({
    String? title,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return StudentSubtask(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory StudentSubtask.fromJson(Map<String, dynamic> json) {
    return StudentSubtask(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      completed: (json['completed'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

/// Foundational task model for Student OS.
///
/// Supports title, description, priority, dates, category, status,
/// subtasks, recurrence, reminders, and optional exam linkage.
/// Backward-compatible with existing persisted data.
class StudentTask {
  StudentTask({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.active,
    this.dueDate,
    this.scheduledDate,
    this.category = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
    this.sortOrder = 0,
    this.subtasks = const [],
    this.recurrence,
    this.reminderEnabled = false,
    this.reminderDateTime,
    this.examId,
    this.subjectId,
    this.goalId,
    this.estimatedMinutes = 0,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? scheduledDate;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int sortOrder;
  final List<StudentSubtask> subtasks;
  final TaskRecurrence? recurrence;
  final bool reminderEnabled;
  final DateTime? reminderDateTime;

  /// Optional link to an exam. When set, this task is a preparation task
  /// for the linked exam.
  final String? examId;

  /// Optional link to a real subject. When set, this task belongs to the
  /// subject's workspace. Independent from [category] (legacy) and [examId].
  final String? subjectId;

  /// Optional link to a personal goal.
  final String? goalId;

  /// Estimated effort for this task in minutes.
  final int estimatedMinutes;

  // ─── Convenience getters ───────────────────────────────────────────

  bool get isCompleted => status == TaskStatus.completed;

  bool get isOverdue =>
      !isCompleted && dueDate != null && dueDate!.isBefore(DateTime.now());

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isScheduledToday {
    if (scheduledDate == null) return false;
    final now = DateTime.now();
    return scheduledDate!.year == now.year &&
        scheduledDate!.month == now.month &&
        scheduledDate!.day == now.day;
  }

  bool get isUpcoming {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isAfter(today) &&
        due.isBefore(today.add(const Duration(days: 7)));
  }

  bool get hasSubtasks => subtasks.isNotEmpty;

  int get subtaskCount => subtasks.length;

  int get subtasksCompleted => subtasks.where((s) => s.completed).length;

  double get subtaskProgress =>
      subtaskCount == 0 ? 0 : subtasksCompleted / subtaskCount;

  bool get allSubtasksComplete =>
      hasSubtasks && subtasks.every((s) => s.completed);

  bool get hasRecurrence =>
      recurrence != null && recurrence!.frequency != RecurrenceFrequency.none;

  bool get isRecurringInstance => false;

  /// Whether the task is in the inbox (active, no scheduled or due date).
  bool get isInbox => !isCompleted && scheduledDate == null && dueDate == null;

  // ─── copyWith ──────────────────────────────────────────────────────

  StudentTask copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? scheduledDate,
    String? category,
    DateTime? completedAt,
    int? sortOrder,
    List<StudentSubtask>? subtasks,
    TaskRecurrence? recurrence,
    bool? reminderEnabled,
    DateTime? reminderDateTime,
    String? examId,
    String? subjectId,
    String? goalId,
    int? estimatedMinutes,
    bool clearDueDate = false,
    bool clearScheduledDate = false,
    bool clearCompletedAt = false,
    bool clearRecurrence = false,
    bool clearReminderDateTime = false,
    bool clearExamId = false,
    bool clearSubjectId = false,
    bool clearGoalId = false,
  }) {
    return StudentTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      scheduledDate: clearScheduledDate
          ? null
          : (scheduledDate ?? this.scheduledDate),
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      sortOrder: sortOrder ?? this.sortOrder,
      subtasks: subtasks ?? this.subtasks,
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDateTime: clearReminderDateTime
          ? null
          : (reminderDateTime ?? this.reminderDateTime),
      examId: clearExamId ? null : (examId ?? this.examId),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      goalId: clearGoalId ? null : (goalId ?? this.goalId),
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  /// Returns a copy with [subjectId] cleared.
  StudentTask clearSubjectId() => copyWith(clearSubjectId: true);

  // ─── Serialization ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority.name,
    'status': status.name,
    'dueDate': dueDate?.toIso8601String(),
    'scheduledDate': scheduledDate?.toIso8601String(),
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'sortOrder': sortOrder,
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'recurrence': recurrence?.toJson(),
    'reminderEnabled': reminderEnabled,
    'reminderDateTime': reminderDateTime?.toIso8601String(),
    'examId': examId,
    'subjectId': subjectId,
    'goalId': goalId,
    'estimatedMinutes': estimatedMinutes,
  };

  /// Backward-compatible factory — safely deserializes old tasks
  /// that lack the new fields (subtasks, recurrence, reminder, updatedAt).
  factory StudentTask.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;

    return StudentTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.active,
      ),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      category: (json['category'] as String?) ?? '',
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      sortOrder: (json['sortOrder'] as int?) ?? 0,
      subtasks:
          (json['subtasks'] as List<dynamic>?)
              ?.map((s) => StudentSubtask.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      recurrence: json['recurrence'] != null
          ? TaskRecurrence.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
      reminderDateTime: json['reminderDateTime'] != null
          ? DateTime.parse(json['reminderDateTime'] as String)
          : null,
      examId: json['examId'] as String?,
      subjectId: json['subjectId'] as String?,
      goalId: json['goalId'] as String?,
      estimatedMinutes: (json['estimatedMinutes'] as int?) ?? 0,
    );
  }
}
