import 'package:flutter/foundation.dart';

import '../../core/utils/app_week_utils.dart';
import '../../data/models/task.dart';
import '../exams/exam_controller.dart';
import '../preferences/user_preferences_controller.dart';
import '../subjects/subject_controller.dart';
import '../tasks/task_controller.dart';
import 'controllers/planning_block_controller.dart';
import 'models/planning_block.dart';
import 'services/planning_engine.dart';

/// Lightweight planning state for the Plan destination.
///
/// Holds the selected day and derives per-day and per-week aggregation from the
/// app-wide [TaskController], [PlanningBlockController], [SubjectController], and [ExamController]
/// so the Plan screen reflects real task state without duplicating task storage.
/// Respects the user's week-start preference.
class PlanController extends ChangeNotifier {
  PlanController._();

  /// Clears in-memory state without touching persistent storage.
  void clearData() {
    _selectedDay = AppWeekUtils.dateOnly(DateTime.now());
    _dailyBudgetMinutes = PlanningEngine.defaultDailyBudgetMinutes;
    if (!_disposed) notifyListeners();
  }

  static final PlanController instance = PlanController._();

  DateTime _selectedDay = AppWeekUtils.dateOnly(DateTime.now());
  int _dailyBudgetMinutes = PlanningEngine.defaultDailyBudgetMinutes;
  bool _disposed = false;

  /// The currently selected day (time normalized to midnight).
  DateTime get selectedDay => _selectedDay;

  /// Daily available study/planning budget in minutes.
  int get dailyBudgetMinutes => _dailyBudgetMinutes;

  bool get isTodaySelected =>
      _selectedDay == AppWeekUtils.dateOnly(DateTime.now());

  bool get _startsMonday =>
      UserPreferencesController.instance.weekStartDay == WeekStartDay.monday;

  void selectDay(DateTime day) {
    final normal = AppWeekUtils.dateOnly(day);
    if (normal == _selectedDay) return;
    _selectedDay = normal;
    notifyListeners();
  }

  void selectToday() => selectDay(DateTime.now());

  void setDailyBudgetMinutes(int minutes) {
    if (minutes <= 0 || _dailyBudgetMinutes == minutes) return;
    _dailyBudgetMinutes = minutes;
    notifyListeners();
  }

  /// The seven dates of the week containing [selectedDay], respecting
  /// the user's week-start preference.
  List<DateTime> get week =>
      AppWeekUtils.weekDates(_selectedDay, startsMonday: _startsMonday);

  /// Whether [day] (time ignored) is the currently selected day.
  bool isSelected(DateTime day) => AppWeekUtils.dateOnly(day) == _selectedDay;

  /// Whether [day] (time ignored) is today.
  bool isToday(DateTime day) =>
      AppWeekUtils.dateOnly(day) == AppWeekUtils.dateOnly(DateTime.now());

  /// Returns the single best currently actionable recommendation (task or subject).
  PlanningRecommendation? get whatShouldIDoNow {
    return PlanningEngine.getWhatShouldIDoNow(
      tasks: TaskController.instance.tasks,
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.exams,
      blocks: PlanningBlockController.instance.blocks,
    );
  }

  /// Evaluates current active blocks, upcoming blocks, or recommendations
  /// to produce the primary actionable state for the student.
  CurrentOrNextAction get currentOrNextAction {
    return PlanningEngine.getCurrentOrNextAction(
      tasks: TaskController.instance.tasks,
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.exams,
      blocks: PlanningBlockController.instance.blocks,
    );
  }

  /// Missed planning blocks from earlier today that ended without being completed.
  List<MissedSession> get missedSessionsToday {
    return PlanningEngine.getMissedSessions(
      blocks: PlanningBlockController.instance.blocks,
      tasks: TaskController.instance.tasks,
      subjects: SubjectController.instance.activeSubjects,
    );
  }

  /// Reschedules a missed session to a new start time today.
  Future<PlanningBlock?> rescheduleMissedSession(MissedSession session, {DateTime? newStartTime}) async {
    final block = await PlanningEngine.rescheduleMissedSession(session, newStartTime: newStartTime);
    if (block != null) notifyListeners();
    return block;
  }

  /// Workload metrics for the currently selected day.
  DayWorkload get selectedDayWorkload => workloadFor(_selectedDay);

  /// Workload metrics for today.
  DayWorkload get todayWorkload => workloadFor(DateTime.now());

  /// Workload metrics for any specific [day].
  DayWorkload workloadFor(DateTime day) {
    return PlanningEngine.calculateDayWorkload(
      day,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
      availableMinutes: _dailyBudgetMinutes,
    );
  }

  /// Weekly aggregated workload for the current [week].
  WeekWorkload get weekWorkload {
    return PlanningEngine.calculateWeekWorkload(
      week,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
      availableMinutes: _dailyBudgetMinutes,
    );
  }

  /// Generates a deterministic daily plan for [day] (or [selectedDay] by default).
  DailyPlanResult generateDailyPlan({DateTime? day, int? budgetMinutes}) {
    return PlanningEngine.generateDailyPlan(
      day ?? _selectedDay,
      tasks: TaskController.instance.tasks,
      subjects: SubjectController.instance.activeSubjects,
      exams: ExamController.instance.exams,
      blocks: PlanningBlockController.instance.blocks,
      availableBudgetMinutes: budgetMinutes ?? _dailyBudgetMinutes,
    );
  }

  /// Updates an individual plan item's duration in a preview.
  DailyPlanResult updatePlanItemDuration(
    DailyPlanResult currentPlan,
    int itemIndex,
    int newDurationMinutes,
  ) {
    return PlanningEngine.updatePlanItemDuration(
      currentPlan,
      itemIndex,
      newDurationMinutes,
    );
  }

  /// Removes an item from the plan preview.
  DailyPlanResult removePlanItem(
    DailyPlanResult currentPlan,
    int itemIndex,
  ) {
    return PlanningEngine.removePlanItem(currentPlan, itemIndex);
  }

  /// Safely applies a generated daily plan by scheduling missing planning blocks.
  Future<List<PlanningBlock>> applyDailyPlan(DailyPlanResult plan) async {
    final blocks = await PlanningEngine.applyDailyPlan(plan);
    notifyListeners();
    return blocks;
  }

  /// Rebalances an overloaded day by moving eligible future blocks forward safely.
  Future<int> rebalanceSelectedDay() async {
    final count = await PlanningEngine.rebalanceOverloadedDay(
      _selectedDay,
      tasks: TaskController.instance.tasks,
      availableMinutes: _dailyBudgetMinutes,
    );
    if (count > 0) notifyListeners();
    return count;
  }

  /// Tasks that compose [day]'s agenda.
  List<StudentTask> tasksFor(DateTime day) {
    final date = AppWeekUtils.dateOnly(day);

    final scheduledIds = PlanningBlockController.instance.blocks
        .where((b) => AppWeekUtils.dateOnly(b.startAt) == date && b.taskId != null)
        .map((b) => b.taskId!)
        .toSet();

    final tasks = TaskController.instance.tasks.where((t) {
      if (scheduledIds.contains(t.id)) return true;
      final scheduled = AppWeekUtils.dateOnlyOrNull(t.scheduledDate);
      if (scheduled == date) return true;
      final due = AppWeekUtils.dateOnlyOrNull(t.dueDate);
      return due == date;
    }).toList();

    int priorityRank(TaskPriority p) => switch (p) {
      TaskPriority.critical => 0,
      TaskPriority.high => 1,
      TaskPriority.medium => 2,
      TaskPriority.low => 3,
    };

    bool isOverdue(StudentTask t) =>
        t.dueDate != null &&
        !t.isCompleted &&
        t.dueDate!.isBefore(DateTime.now());

    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.isCompleted) return (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt);
      final aOverdue = isOverdue(a) ? 0 : 1;
      final bOverdue = isOverdue(b) ? 0 : 1;
      if (aOverdue != bOverdue) return aOverdue.compareTo(bOverdue);
      final rank = priorityRank(a.priority).compareTo(priorityRank(b.priority));
      if (rank != 0) return rank;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return tasks;
  }

  /// Progress metrics for one day.
  ({int total, int completed, double progress}) metricsFor(DateTime day) {
    final tasks = tasksFor(day);
    final dayBlocks = PlanningBlockController.instance.blocksForDay(day);
    final subjectBlocks = dayBlocks.where((b) => b.isSubjectBlock).toList();

    final total = tasks.length + subjectBlocks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    return (
      total: total,
      completed: completed,
      progress: total == 0 ? 0 : completed / total,
    );
  }

  /// Number of active (planned, not yet completed) tasks on [selectedDay].
  int get selectedDayActiveCount =>
      tasksFor(_selectedDay).where((t) => !t.isCompleted).length;

  /// Creates a task scheduled on the selected day.
  Future<StudentTask> planTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    int estimatedMinutes = 0,
    String? subjectId,
    String? examId,
    String? goalId,
  }) {
    return TaskController.instance.createTask(
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      scheduledDate: _selectedDay,
      estimatedMinutes: estimatedMinutes,
      subjectId: subjectId,
      examId: examId,
      goalId: goalId,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
