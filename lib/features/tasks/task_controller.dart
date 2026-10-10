import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/notification_coordinator.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/streak_service.dart';
import '../../data/models/task.dart';
import '../auth/auth_service.dart';
import '../progression/progression_controller.dart';
import '../notifications/notification_controller.dart';

/// Sort order for task lists.
enum TaskSortOrder {
  smart('Smart'),
  dueDate('Due date'),
  priority('Priority'),
  created('Recently created'),
  alphabetical('Alphabetical');

  const TaskSortOrder(this.label);
  final String label;
}

/// Active task filter criteria.
///
/// [subjectId] and [examId] scope the list to one academic entity (used for
/// "View all tasks" deep-links from Subject/Exam detail screens). They match
/// the canonical ID relationships on [StudentTask]; legacy free-text
/// [StudentTask.category] is intentionally not matched here.
class TaskFilter {
  const TaskFilter({
    this.priorities = const [],
    this.hasSubtasks,
    this.hasRecurrence,
    this.isOverdue,
    this.isInbox,
    this.searchQuery = '',
    this.subjectId,
    this.examId,
  });

  final List<TaskPriority> priorities;
  final bool? hasSubtasks;
  final bool? hasRecurrence;
  final bool? isOverdue;
  final bool? isInbox;
  final String searchQuery;
  final String? subjectId;
  final String? examId;

  bool get isEmpty =>
      priorities.isEmpty &&
      hasSubtasks == null &&
      hasRecurrence == null &&
      isOverdue == null &&
      isInbox == null &&
      searchQuery.isEmpty &&
      subjectId == null &&
      examId == null;

  /// True when the list is scoped to a single subject or exam workspace.
  bool get isScoped => subjectId != null || examId != null;

  TaskFilter copyWith({
    List<TaskPriority>? priorities,
    bool? hasSubtasks,
    bool? hasRecurrence,
    bool? isOverdue,
    bool? isInbox,
    String? searchQuery,
    String? subjectId,
    String? examId,
    bool clearPriorities = false,
    bool clearHasSubtasks = false,
    bool clearHasRecurrence = false,
    bool clearIsOverdue = false,
    bool clearIsInbox = false,
    bool clearSearch = false,
    bool clearSubjectId = false,
    bool clearExamId = false,
  }) {
    return TaskFilter(
      priorities: clearPriorities ? [] : (priorities ?? this.priorities),
      hasSubtasks: clearHasSubtasks ? null : (hasSubtasks ?? this.hasSubtasks),
      hasRecurrence: clearHasRecurrence
          ? null
          : (hasRecurrence ?? this.hasRecurrence),
      isOverdue: clearIsOverdue ? null : (isOverdue ?? this.isOverdue),
      isInbox: clearIsInbox ? null : (isInbox ?? this.isInbox),
      searchQuery: clearSearch ? '' : (searchQuery ?? this.searchQuery),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      examId: clearExamId ? null : (examId ?? this.examId),
    );
  }
}

/// Manages the student's task list with local persistence and optional
/// Supabase cloud sync.
class TaskController extends ChangeNotifier {
  TaskController._();

  /// Clears in-memory state (not persistent storage).
  void clearData() {
    _tasks.clear();
    notifyListeners();
  }

  static final TaskController instance = TaskController._();

  static const _tasksKey = 'tasks';

  List<StudentTask> _tasks = [];
  bool _loaded = false;
  bool _disposed = false;
  int _counter = 0;

  TaskFilter _filter = const TaskFilter();
  TaskSortOrder _sortOrder = TaskSortOrder.smart;

  List<StudentTask> get tasks => List.unmodifiable(_tasks);
  bool get isLoaded => _loaded;
  TaskFilter get filter => _filter;
  TaskSortOrder get sortOrder => _sortOrder;

  /// Resolved user id, or `null` when unknown (logged out).
  ///
  /// `null` means memory-only: persistence is skipped rather than written to
  /// a shared fallback namespace, so data can never leak across users.
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Derived queries ────────────────────────────────────────────────

  List<StudentTask> get activeTasks =>
      _tasks.where((t) => !t.isCompleted).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<StudentTask> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList()..sort((a, b) {
        final aDate = a.completedAt ?? a.createdAt;
        final bDate = b.completedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

  List<StudentTask> get todayTasks =>
      activeTasks.where((t) => t.isDueToday || t.isScheduledToday).toList();

  List<StudentTask> get upcomingTasks =>
      activeTasks.where((t) => t.isUpcoming && !t.isDueToday).toList();

  List<StudentTask> get overdueTasks =>
      activeTasks.where((t) => t.isOverdue).toList();

  List<StudentTask> get inboxTasks =>
      activeTasks.where((t) => t.isInbox).toList();

  /// Centralized query for today/upcoming/overdue/completed.
  List<StudentTask> getTasksByStatus({
    bool? overdue,
    bool? today,
    bool? upcoming,
    bool? completed,
  }) {
    if (completed == true) return completedTasks;
    if (overdue == true) return overdueTasks;
    if (today == true) return todayTasks;
    if (upcoming == true) return upcomingTasks;
    return activeTasks;
  }

  List<StudentTask> get laterTasks {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    return activeTasks.where((t) {
      if (t.dueDate == null && t.scheduledDate == null) return true;
      final date = t.dueDate ?? t.scheduledDate!;
      return date.isAfter(weekEnd);
    }).toList();
  }

  int get todayCompletedCount =>
      _tasks.where((t) => t.isCompleted && t.isDueToday).length;

  int get todayTotalCount => todayTasks.length + todayCompletedCount;

  double get todayProgress =>
      todayTotalCount > 0 ? todayCompletedCount / todayTotalCount : 0;

  int get activeCount => activeTasks.length;
  int get completedCount => completedTasks.length;
  int get inboxCount => inboxTasks.length;

  int get totalStreakDays {
    final completedDates =
        _tasks
            .where((t) => t.completedAt != null)
            .map((t) => t.completedAt!)
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (completedDates.isEmpty) return 0;

    var streak = 0;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    for (final date in completedDates) {
      if (date == todayNorm.subtract(Duration(days: streak))) {
        streak++;
      } else if (date.isBefore(todayNorm.subtract(Duration(days: streak)))) {
        break;
      }
    }
    return streak;
  }

  // ─── Filtered / sorted views ────────────────────────────────────────

  /// Returns tasks matching the current [filter] and [sortOrder].
  List<StudentTask> get filteredTasks => applyFilter(activeTasks);

  /// Applies the current [filter] (search, priorities, flags, subject/exam
  /// scope) and [sortOrder] to any [base] list.
  ///
  /// Used by workspace views (Today/Upcoming/Overdue/Inbox/Completed) so
  /// search and filters behave consistently everywhere instead of only in
  /// the "All" view. Completed tasks passed in stay completable-filterable
  /// (only the caller decides the base).
  List<StudentTask> applyFilter(List<StudentTask> base) {
    var result = List<StudentTask>.from(base);

    // Apply search
    if (_filter.searchQuery.isNotEmpty) {
      final q = _filter.searchQuery.toLowerCase();
      result = result.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q);
      }).toList();
    }

    // Apply subject scope (canonical subjectId relationship).
    if (_filter.subjectId != null) {
      result = result.where((t) => t.subjectId == _filter.subjectId).toList();
    }

    // Apply exam scope (canonical examId relationship).
    if (_filter.examId != null) {
      result = result.where((t) => t.examId == _filter.examId).toList();
    }

    // Apply priority filter
    if (_filter.priorities.isNotEmpty) {
      result = result
          .where((t) => _filter.priorities.contains(t.priority))
          .toList();
    }

    // Apply subtask filter
    if (_filter.hasSubtasks != null) {
      result = result
          .where((t) => t.hasSubtasks == _filter.hasSubtasks)
          .toList();
    }

    // Apply recurrence filter
    if (_filter.hasRecurrence != null) {
      result = result
          .where((t) => t.hasRecurrence == _filter.hasRecurrence)
          .toList();
    }

    // Apply overdue filter
    if (_filter.isOverdue != null) {
      result = result.where((t) => t.isOverdue == _filter.isOverdue).toList();
    }

    // Apply inbox filter
    if (_filter.isInbox != null) {
      result = result.where((t) => t.isInbox == _filter.isInbox).toList();
    }

    // Sort
    result = _sortTasks(result);

    return result;
  }

  List<StudentTask> _sortTasks(List<StudentTask> tasks) {
    return switch (_sortOrder) {
      TaskSortOrder.smart => _sortSmart(tasks),
      TaskSortOrder.dueDate => _sortDueDate(tasks),
      TaskSortOrder.priority => _sortPriority(tasks),
      TaskSortOrder.created => _sortCreated(tasks),
      TaskSortOrder.alphabetical => _sortAlphabetical(tasks),
    };
  }

  List<StudentTask> _sortSmart(List<StudentTask> tasks) {
    return List.of(tasks)..sort((a, b) {
      // Overdue first
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      // Due today
      if (a.isDueToday && !b.isDueToday) return -1;
      if (!a.isDueToday && b.isDueToday) return 1;
      // Priority
      if (a.priority.index != b.priority.index) {
        return a.priority.index.compareTo(b.priority.index);
      }
      // Due date proximity
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
  }

  List<StudentTask> _sortDueDate(List<StudentTask> tasks) {
    return List.of(tasks)..sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
  }

  List<StudentTask> _sortPriority(List<StudentTask> tasks) {
    return List.of(tasks)..sort((a, b) {
      final cmp = a.priority.index.compareTo(b.priority.index);
      if (cmp != 0) return cmp;
      return a.sortOrder.compareTo(b.sortOrder);
    });
  }

  List<StudentTask> _sortCreated(List<StudentTask> tasks) {
    return List.of(tasks)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<StudentTask> _sortAlphabetical(List<StudentTask> tasks) {
    return List.of(tasks)
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  // ─── Filter / sort mutations ────────────────────────────────────────

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSortOrder(TaskSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void clearFilters() {
    _filter = const TaskFilter();
    notifyListeners();
  }

  // ─── Search ─────────────────────────────────────────────────────────

  void search(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  void clearSearch() {
    _filter = _filter.copyWith(clearSearch: true);
    notifyListeners();
  }

  // ─── Loading ────────────────────────────────────────────────────────

  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    try {
      await _loadLocal();
    } catch (_) {
      // A corrupt cache entry must never leave the controller permanently
      // "not loaded" (Home gates on [isLoaded] and would spin forever).
      // Start empty; cloud sync heals from the server when available.
      _tasks = [];
    } finally {
      _loaded = true;
      if (!_disposed) notifyListeners();
    }
    _attemptCloudLoad();
  }

  Future<void> _loadLocal() async {
    final uid = _userId;
    if (uid == null) return;
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _tasksKey,
    );
    if (list != null) {
      _tasks = list.map((j) => StudentTask.fromJson(j)).toList();
      _counter = _tasks.length;
    }
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;

    try {
      final response = await client
          .from('tasks')
          .select()
          .eq('user_id', uid)
          .order('created_at');
      if (response.isNotEmpty) {
        _tasks = response.map((j) => StudentTask.fromJson(j)).toList();
        _counter = _tasks.length;
        await _saveLocal();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TaskController] Cloud load failed: $e');
    }
  }

  // ─── Saving ─────────────────────────────────────────────────────────

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _tasksKey,
      list: _tasks.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> _attemptCloudSave() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;

    try {
      await client
          .from('tasks')
          .upsert(
            _tasks.map((t) => {...t.toJson(), 'user_id': uid}).toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('[TaskController] Cloud save failed: $e');
    }
  }

  // ─── CRUD ───────────────────────────────────────────────────────────

  Future<StudentTask> createTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? scheduledDate,
    String category = '',
    List<StudentSubtask> subtasks = const [],
    TaskRecurrence? recurrence,
    bool reminderEnabled = false,
    DateTime? reminderDateTime,
    String? examId,
    String? subjectId,
    String? goalId,
    int estimatedMinutes = 0,
  }) async {
    _counter++;
    final task = StudentTask(
      id: '${DateTime.now().millisecondsSinceEpoch}_$_counter',
      title: title.trim(),
      description: description.trim(),
      priority: priority,
      dueDate: dueDate,
      scheduledDate: scheduledDate,
      category: category,
      sortOrder: _counter,
      subtasks: subtasks,
      recurrence: recurrence,
      reminderEnabled: reminderEnabled,
      reminderDateTime: reminderDateTime,
      examId: examId,
      subjectId: subjectId,
      goalId: goalId,
      estimatedMinutes: estimatedMinutes,
    );
    _tasks.add(task);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Schedule notification reminder if enabled.
    if (task.reminderEnabled && task.reminderDateTime != null) {
      await NotificationCoordinator.instance.scheduleTaskReminder(
        task.id,
        task.title,
        task.reminderDateTime!,
      );
    }

    return task;
  }

  Future<void> updateTask(StudentTask updated) async {
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index < 0) return;
    _tasks[index] = updated;
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Update notification reminder.
    if (updated.reminderEnabled && updated.reminderDateTime != null) {
      await NotificationCoordinator.instance.scheduleTaskReminder(
        updated.id,
        updated.title,
        updated.reminderDateTime!,
      );
    } else {
      await NotificationCoordinator.instance.cancelTaskReminder(updated.id);
    }
  }

  Future<void> completeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final task = _tasks[index];
    _tasks[index] = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Cancel notification reminder for completed task.
    await NotificationCoordinator.instance.cancelTaskReminder(taskId);

    // Handle recurring task: generate next occurrence if applicable.
    if (task.hasRecurrence) {
      _generateNextOccurrence(task);
    }

    // Award XP for completing task. Re-resolve by id: the list may have
    // changed across the async gaps above (e.g. task deleted while the
    // completion was in flight, such as Focus auto-completing a task the
    // student just deleted). Never crash — just skip the award.
    final completed = _tasks.where((t) => t.id == taskId).firstOrNull;
    if (completed != null) {
      await ProgressionController.instance.awardTaskCompletion(completed);
      await NotificationController.instance.onTaskCompleted(completed);
    }

    // Refresh streak and check for streak milestones
    StreakService.instance.refresh();
    await ProgressionController.instance.awardStreakMilestone(
      StreakService.instance.currentStreak,
    );
    if (StreakService.instance.currentStreak >= 3) {
      await NotificationController.instance.onStreakMilestone(
        StreakService.instance.currentStreak,
      );
    }
  }

  Future<void> reopenTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    _tasks[index] = _tasks[index].copyWith(
      status: TaskStatus.active,
      clearCompletedAt: true,
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Cancel notification reminder for deleted task.
    await NotificationCoordinator.instance.cancelTaskReminder(taskId);
  }

  Future<void> changePriority(String taskId, TaskPriority priority) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    _tasks[index] = _tasks[index].copyWith(priority: priority);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  // ─── Subtask management ─────────────────────────────────────────────

  Future<void> addSubtask(String taskId, String title) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final task = _tasks[index];
    final subtask = StudentSubtask(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
    );
    _tasks[index] = task.copyWith(subtasks: [...task.subtasks, subtask]);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final task = _tasks[index];
    final subIndex = task.subtasks.indexWhere((s) => s.id == subtaskId);
    if (subIndex < 0) return;

    final sub = task.subtasks[subIndex];
    final updated = sub.copyWith(
      completed: !sub.completed,
      completedAt: !sub.completed ? DateTime.now() : null,
      clearCompletedAt: sub.completed,
    );

    final newSubtasks = List<StudentSubtask>.from(task.subtasks);
    newSubtasks[subIndex] = updated;
    _tasks[index] = task.copyWith(subtasks: newSubtasks);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final task = _tasks[index];
    _tasks[index] = task.copyWith(
      subtasks: task.subtasks.where((s) => s.id != subtaskId).toList(),
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> renameSubtask(
    String taskId,
    String subtaskId,
    String newTitle,
  ) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final task = _tasks[index];
    final subIndex = task.subtasks.indexWhere((s) => s.id == subtaskId);
    if (subIndex < 0) return;

    final newSubtasks = List<StudentSubtask>.from(task.subtasks);
    newSubtasks[subIndex] = newSubtasks[subIndex].copyWith(title: newTitle);
    _tasks[index] = task.copyWith(subtasks: newSubtasks);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  // ─── Bulk actions ───────────────────────────────────────────────────

  Future<void> completeTasks(List<String> taskIds) async {
    for (final id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index < 0) continue;
      _tasks[index] = _tasks[index].copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
    }
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> deleteTasks(List<String> taskIds) async {
    _tasks.removeWhere((t) => taskIds.contains(t.id));
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Cancel notification reminders for all deleted tasks.
    for (final id in taskIds) {
      await NotificationCoordinator.instance.cancelTaskReminder(id);
    }
  }

  Future<void> changePriorityBatch(
    List<String> taskIds,
    TaskPriority priority,
  ) async {
    for (final id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index < 0) continue;
      _tasks[index] = _tasks[index].copyWith(priority: priority);
    }
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  // ─── Exam linkage ────────────────────────────────────────────────────

  /// Clears all exam references for tasks linked to the given exam.
  ///
  /// Called when an exam is deleted — does NOT delete the tasks themselves.
  Future<void> clearExamReference(String examId) async {
    var changed = false;
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].examId == examId) {
        _tasks[i] = _tasks[i].copyWith(clearExamId: true);
        changed = true;
      }
    }
    if (changed) {
      await _saveLocal();
      if (!_disposed) notifyListeners();
      _attemptCloudSave();
    }
  }

  /// Returns tasks linked to a specific exam.
  List<StudentTask> tasksForExam(String examId) =>
      _tasks.where((t) => t.examId == examId).toList();

  /// Returns active preparation tasks for a specific exam.
  List<StudentTask> activePreparationTasks(String examId) =>
      tasksForExam(examId).where((t) => !t.isCompleted).toList();

  /// Returns completed preparation tasks for a specific exam.
  List<StudentTask> completedPreparationTasks(String examId) =>
      tasksForExam(examId).where((t) => t.isCompleted).toList();

  // ─── Subject linkage ──────────────────────────────────────────

  /// Returns tasks linked to a specific subject.
  List<StudentTask> tasksForSubject(String subjectId) =>
      _tasks.where((t) => t.subjectId == subjectId).toList();

  /// Returns active tasks for a specific subject.
  List<StudentTask> activeTasksForSubject(String subjectId) =>
      tasksForSubject(subjectId).where((t) => !t.isCompleted).toList();

  /// Returns completed tasks for a specific subject.
  List<StudentTask> completedTasksForSubject(String subjectId) =>
      tasksForSubject(subjectId).where((t) => t.isCompleted).toList();

  /// Clears subject references for all tasks linked to the given subject.
  /// Called when a subject is deleted — does NOT delete the tasks themselves.
  Future<void> clearSubjectReference(String subjectId) async {
    var changed = false;
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].subjectId == subjectId) {
        _tasks[i] = _tasks[i].clearSubjectId();
        changed = true;
      }
    }
    if (changed) {
      await _saveLocal();
      if (!_disposed) notifyListeners();
      _attemptCloudSave();
    }
  }

  // ─── Recurrence generation ──────────────────────────────────────────

  void _generateNextOccurrence(StudentTask completedTask) {
    final recurrence = completedTask.recurrence;
    if (recurrence == null ||
        recurrence.frequency == RecurrenceFrequency.none) {
      return;
    }

    final baseDate = completedTask.dueDate ?? completedTask.scheduledDate;
    if (baseDate == null) return;

    DateTime? nextDate;

    switch (recurrence.frequency) {
      case RecurrenceFrequency.daily:
        nextDate = baseDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekdays:
        var candidate = baseDate.add(const Duration(days: 1));
        // Skip weekends
        while (candidate.weekday > 5) {
          candidate = candidate.add(const Duration(days: 1));
        }
        nextDate = candidate;
      case RecurrenceFrequency.weekly:
        nextDate = baseDate.add(const Duration(days: 7));
      case RecurrenceFrequency.none:
        return;
    }

    // Check for duplicate: don't create if a task with same title + nextDate already exists.
    final exists = _tasks.any(
      (t) =>
          !t.isCompleted &&
          t.title == completedTask.title &&
          (t.dueDate == nextDate || t.scheduledDate == nextDate),
    );
    if (exists) return;

    // Create next occurrence.
    _counter++;
    final nextTask = StudentTask(
      id: '${DateTime.now().millisecondsSinceEpoch}_$_counter',
      title: completedTask.title,
      description: completedTask.description,
      priority: completedTask.priority,
      dueDate: completedTask.dueDate != null ? nextDate : null,
      scheduledDate: completedTask.scheduledDate != null ? nextDate : null,
      category: completedTask.category,
      sortOrder: _counter,
      recurrence: completedTask.recurrence,
    );
    _tasks.add(nextTask);
  }

  /// Ensures recurring tasks have their next occurrence scheduled.
  /// Called at startup to reconcile any missed recurring task generations.
  ///
  /// For each active recurring task, ensures the next occurrence exists.
  void reconcileRecurring() {
    final recurring = _tasks.where((t) => t.hasRecurrence && !t.isCompleted);
    for (final task in recurring) {
      final baseDate = task.dueDate ?? task.scheduledDate;
      if (baseDate == null) continue;

      // Check if there's already a future occurrence for this title.
      final hasFuture = _tasks.any(
        (t) =>
            t.id != task.id &&
            !t.isCompleted &&
            t.title == task.title &&
            t.hasRecurrence,
      );
      // If no future occurrence exists and the base date is in the past,
      // generate the next occurrence.
      if (!hasFuture && baseDate.isBefore(DateTime.now())) {
        _generateNextOccurrence(task);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
