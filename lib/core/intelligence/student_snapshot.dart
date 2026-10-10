import '../../data/models/academic_resource.dart';

import 'package:meta/meta.dart';

import '../../data/models/exam.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/study_session.dart';
import '../../features/goals/goal_controller.dart';
import '../../features/resources/resource_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/study/study_controller.dart';
import '../../features/exams/exam_controller.dart';

/// A lightweight, derived in-memory snapshot of the student's current state.
///
/// Does NOT duplicate persistent storage. Reads from existing controllers and
/// provides a unified view for intelligence layers. Recomputes on-demand when
/// source controllers notify changes.
///
/// All data here is either a reference to existing objects or a cheap derived
/// summary. Heavy computations should remain in their respective controllers.
@immutable
class StudentSnapshot {
  const StudentSnapshot({
    required this.todayTasks,
    required this.overdueTasks,
    required this.upcomingTasks,
    required this.inboxTasks,
    required this.activeTaskCount,
    required this.completedTaskCount,
    required this.todayCompletedCount,
    required this.todayProgress,
    required this.currentStreak,
    required this.upcomingExams,
    required this.activeSubjects,
    required this.recentResources,
    required this.favoriteResources,
    required this.totalResourceCount,
    required this.todayStudySessions,
    required this.todayStudyMinutes,
    required this.weekStudyMinutes,
    required this.hasGoals,
  });

  // ─── Tasks ─────────────────────────────────────────────────────────────

  final List<StudentTask> todayTasks;
  final List<StudentTask> overdueTasks;
  final List<StudentTask> upcomingTasks;
  final List<StudentTask> inboxTasks;
  final int activeTaskCount;
  final int completedTaskCount;
  final int todayCompletedCount;
  final double todayProgress;
  final int currentStreak;

  // ─── Exams ─────────────────────────────────────────────────────────────

  final List<StudentExam> upcomingExams;

  // ─── Subjects ──────────────────────────────────────────────────────────

  final List<Subject> activeSubjects;

  // ─── Resources ─────────────────────────────────────────────────────────

  final List<AcademicResource> recentResources;
  final List<AcademicResource> favoriteResources;
  final int totalResourceCount;

  // ─── Study ─────────────────────────────────────────────────────────────

  final List<StudySession> todayStudySessions;
  final int todayStudyMinutes;
  final int weekStudyMinutes;

  // ─── Goals ─────────────────────────────────────────────────────────────

  final bool hasGoals;

  // ─── Convenience getters ───────────────────────────────────────────────

  bool get hasOverdueTasks => overdueTasks.isNotEmpty;
  bool get hasTodayTasks => todayTasks.isNotEmpty;
  bool get hasUpcomingExams => upcomingExams.isNotEmpty;
  bool get hasRecentResources => recentResources.isNotEmpty;
  bool get hasFavorites => favoriteResources.isNotEmpty;
  bool get hasActiveSubjects => activeSubjects.isNotEmpty;
  bool get hasStudyToday => todayStudySessions.isNotEmpty;
  bool get hasStreak => currentStreak > 0;

  int get todayRemainingCount => todayTasks.length - todayCompletedCount;

  /// Returns the most urgent exam (soonest upcoming exam), if any.
  StudentExam? get nextExam =>
      upcomingExams.isNotEmpty ? upcomingExams.first : null;

  /// Factory that derives a snapshot from current controller state.
  ///
  /// This is cheap to call — it references existing lists rather than copying
  /// entire datasets. Controllers remain the source of truth.
  factory StudentSnapshot.fromControllers() {
    final tc = TaskController.instance;
    final ec = ExamController.instance;
    final sc = SubjectController.instance;
    final rc = ResourceController.instance;
    final stc = StudyController.instance;
    final gc = GoalController.instance;

    // Study time calculations
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    final todaySessions = stc.sessions.where((s) {
      return s.startedAt.isAfter(todayStart) && s.startedAt.isBefore(todayEnd);
    }).toList();

    final todayStudySeconds = todaySessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSec,
    );

    final weekSessions = stc.sessions.where((s) {
      return s.startedAt.isAfter(weekStart) && s.startedAt.isBefore(todayEnd);
    }).toList();

    final weekStudySeconds = weekSessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSec,
    );

    return StudentSnapshot(
      todayTasks: tc.todayTasks,
      overdueTasks: tc.overdueTasks,
      upcomingTasks: tc.upcomingTasks,
      inboxTasks: tc.inboxTasks,
      activeTaskCount: tc.activeCount,
      completedTaskCount: tc.completedCount,
      todayCompletedCount: tc.todayCompletedCount,
      todayProgress: tc.todayProgress,
      currentStreak: tc.totalStreakDays,
      upcomingExams: ec.upcomingExams,
      activeSubjects: sc.activeSubjects,
      recentResources: rc.recentResources,
      favoriteResources: rc.favoriteResources,
      totalResourceCount: rc.activeCount,
      todayStudySessions: todaySessions,
      todayStudyMinutes: (todayStudySeconds / 60).round(),
      weekStudyMinutes: (weekStudySeconds / 60).round(),
      hasGoals:
          gc.personalGoal.isNotEmpty ||
          gc.dailyStudyTarget.inMinutes > 0 ||
          gc.weeklyStudyTarget.inMinutes > 0 ||
          gc.weeklyTaskTarget > 0,
    );
  }

  /// Returns a copy with updated values. Used for testing or derived states.
  StudentSnapshot copyWith({
    List<StudentTask>? todayTasks,
    List<StudentTask>? overdueTasks,
    List<StudentTask>? upcomingTasks,
    List<StudentTask>? inboxTasks,
    int? activeTaskCount,
    int? completedTaskCount,
    int? todayCompletedCount,
    double? todayProgress,
    int? currentStreak,
    List<StudentExam>? upcomingExams,
    List<Subject>? activeSubjects,
    List<AcademicResource>? recentResources,
    List<AcademicResource>? favoriteResources,
    int? totalResourceCount,
    List<StudySession>? todayStudySessions,
    int? todayStudyMinutes,
    int? weekStudyMinutes,
    bool? hasGoals,
  }) {
    return StudentSnapshot(
      todayTasks: todayTasks ?? this.todayTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      upcomingTasks: upcomingTasks ?? this.upcomingTasks,
      inboxTasks: inboxTasks ?? this.inboxTasks,
      activeTaskCount: activeTaskCount ?? this.activeTaskCount,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      todayCompletedCount: todayCompletedCount ?? this.todayCompletedCount,
      todayProgress: todayProgress ?? this.todayProgress,
      currentStreak: currentStreak ?? this.currentStreak,
      upcomingExams: upcomingExams ?? this.upcomingExams,
      activeSubjects: activeSubjects ?? this.activeSubjects,
      recentResources: recentResources ?? this.recentResources,
      favoriteResources: favoriteResources ?? this.favoriteResources,
      totalResourceCount: totalResourceCount ?? this.totalResourceCount,
      todayStudySessions: todayStudySessions ?? this.todayStudySessions,
      todayStudyMinutes: todayStudyMinutes ?? this.todayStudyMinutes,
      weekStudyMinutes: weekStudyMinutes ?? this.weekStudyMinutes,
      hasGoals: hasGoals ?? this.hasGoals,
    );
  }
}
