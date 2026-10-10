import '../../data/models/exam.dart';

import 'package:meta/meta.dart';

import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/study/study_controller.dart';
import '../../features/exams/exam_controller.dart';

/// Preparation readiness state for an upcoming exam.
enum ExamReadinessState {
  onTrack('On Track'),
  needsAttention('Needs Attention'),
  atRisk('At Risk'),
  critical('Critical');

  const ExamReadinessState(this.label);
  final String label;
}

/// Academic health status of an active subject.
enum SubjectHealthState {
  healthy('Healthy'),
  needsAttention('Needs Attention'),
  weak('Weak'),
  critical('Critical');

  const SubjectHealthState(this.label);
  final String label;
}

/// Derived exam preparation metrics for a specific exam.
@immutable
class ExamPreparationSummary {
  const ExamPreparationSummary({
    required this.exam,
    required this.daysRemaining,
    required this.syllabusCompletionPercent,
    required this.remainingTopicsCount,
    required this.recentStudyMinutes,
    required this.uncompletedTaskCount,
    required this.state,
    required this.explanation,
  });

  final StudentExam exam;
  final int daysRemaining;
  final double syllabusCompletionPercent; // 0.0 to 1.0
  final int remainingTopicsCount;
  final int recentStudyMinutes;
  final int uncompletedTaskCount;
  final ExamReadinessState state;
  final String explanation;
}

/// Derived academic health summary for an active subject.
@immutable
class SubjectHealthSummary {
  const SubjectHealthSummary({
    required this.subject,
    required this.totalStudyMinutes,
    required this.daysSinceLastStudied,
    required this.activeTaskCount,
    required this.hasUpcomingExam,
    required this.state,
    required this.explanation,
  });

  final Subject subject;
  final int totalStudyMinutes;
  final int daysSinceLastStudied; // 999 if never
  final int activeTaskCount;
  final bool hasUpcomingExam;
  final SubjectHealthState state;
  final String explanation;
}

/// Unified, non-persisted Academic Context reflecting the student's real workload.
@immutable
class AcademicContext {
  const AcademicContext({
    required this.upcomingExams,
    required this.overdueTasks,
    required this.todayTasks,
    required this.activeSubjects,
    required this.examSummaries,
    required this.subjectHealths,
    required this.highPressureSubjectIds,
    required this.neglectedSubjectIds,
    required this.isWorkloadHeavy,
  });

  final List<StudentExam> upcomingExams;
  final List<StudentTask> overdueTasks;
  final List<StudentTask> todayTasks;
  final List<Subject> activeSubjects;
  final List<ExamPreparationSummary> examSummaries;
  final List<SubjectHealthSummary> subjectHealths;
  final Set<String> highPressureSubjectIds;
  final Set<String> neglectedSubjectIds;
  final bool isWorkloadHeavy;

  /// Builds the current AcademicContext directly from controller states.
  factory AcademicContext.fromControllers() {
    final ec = ExamController.instance;
    final tc = TaskController.instance;
    final sc = SubjectController.instance;
    final stc = StudyController.instance;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));

    final upcomingExams = ec.upcomingExams
        .where((e) => !e.isCompleted)
        .toList();
    final allTasks = tc.tasks;
    final overdueTasks = allTasks
        .where((t) => t.isOverdue && !t.isCompleted)
        .toList();
    final todayTasks = allTasks.where((t) {
      if (t.isCompleted) return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.isAfter(today.subtract(const Duration(seconds: 1))) &&
          t.dueDate!.isBefore(todayEnd);
    }).toList();

    final activeSubjects = sc.activeSubjects;

    // 1. Derive Exam Preparation Summaries
    final examSummaries = <ExamPreparationSummary>[];
    final highPressureSubjects = <String>{};

    for (final exam in upcomingExams) {
      final days = exam.daysUntilExam ?? 999;
      final syllabusTotal = exam.syllabusTotal;
      final syllabusCompleted = exam.syllabusCompleted;
      final completionRatio = syllabusTotal > 0
          ? (syllabusCompleted / syllabusTotal)
          : 0.0;
      final remainingTopics = syllabusTotal - syllabusCompleted;

      // Calculate recent study for this exam / subject in last 7 days
      final cutoff = now.subtract(const Duration(days: 7));
      final recentStudySec = stc.sessions
          .where(
            (s) =>
                s.startedAt.isAfter(cutoff) &&
                s.subject.toLowerCase() == exam.subject.toLowerCase(),
          )
          .fold<int>(0, (sum, s) => sum + s.durationSec);
      final recentStudyMins = recentStudySec ~/ 60;

      final uncompletedTasks = tc.tasks
          .where((t) => t.examId == exam.id && !t.isCompleted)
          .length;

      // Classify Readiness
      ExamReadinessState state;
      String explanation;

      if (days <= 3) {
        if (completionRatio < 0.50 || recentStudyMins < 30) {
          state = ExamReadinessState.critical;
          explanation =
              'Exam in $days days with low preparation and recent activity.';
        } else if (completionRatio < 0.80) {
          state = ExamReadinessState.atRisk;
          explanation = 'Exam in $days days with topics remaining to revise.';
        } else {
          state = ExamReadinessState.onTrack;
          explanation = 'Exam in $days days, syllabus well prepared.';
        }
      } else if (days <= 7) {
        if (completionRatio < 0.35) {
          state = ExamReadinessState.atRisk;
          explanation =
              'Exam in $days days with only ${(completionRatio * 100).round()}% syllabus complete.';
        } else if (completionRatio < 0.65) {
          state = ExamReadinessState.needsAttention;
          explanation = 'Exam in $days days; recommend consistent study.';
        } else {
          state = ExamReadinessState.onTrack;
          explanation = 'Preparation on track for upcoming exam.';
        }
      } else {
        state = ExamReadinessState.onTrack;
        explanation = 'Exam scheduled in $days days.';
      }

      if (state == ExamReadinessState.critical ||
          state == ExamReadinessState.atRisk) {
        highPressureSubjects.add(exam.subject);
      }

      examSummaries.add(
        ExamPreparationSummary(
          exam: exam,
          daysRemaining: days,
          syllabusCompletionPercent: completionRatio,
          remainingTopicsCount: remainingTopics,
          recentStudyMinutes: recentStudyMins,
          uncompletedTaskCount: uncompletedTasks,
          state: state,
          explanation: explanation,
        ),
      );
    }

    // 2. Derive Subject Health Summaries
    final subjectHealths = <SubjectHealthSummary>[];
    final neglectedSubjects = <String>{};

    for (final subject in activeSubjects) {
      final subjectSessions =
          stc.sessions
              .where(
                (s) =>
                    s.subject.toLowerCase() == subject.name.toLowerCase() ||
                    s.subject == subject.id,
              )
              .toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

      final totalStudySec = subjectSessions.fold<int>(
        0,
        (sum, s) => sum + s.durationSec,
      );
      final totalStudyMins = totalStudySec ~/ 60;

      final daysSinceLastStudied = subjectSessions.isNotEmpty
          ? now.difference(subjectSessions.first.startedAt).inDays
          : 999;

      final activeTaskCount = tc.tasks
          .where(
            (t) =>
                (t.subjectId == subject.id ||
                    t.category.toLowerCase() == subject.name.toLowerCase()) &&
                !t.isCompleted,
          )
          .length;
      final hasExam = upcomingExams.any(
        (e) => e.subject.toLowerCase() == subject.name.toLowerCase(),
      );

      SubjectHealthState healthState;
      String healthExplanation;

      if (daysSinceLastStudied >= 7 && activeSubjects.length > 1) {
        neglectedSubjects.add(subject.id);
        if (hasExam) {
          healthState = SubjectHealthState.critical;
          healthExplanation =
              'Exam coming up and no study in $daysSinceLastStudied days.';
        } else {
          healthState = SubjectHealthState.needsAttention;
          healthExplanation = 'Not studied in over a week.';
        }
      } else if (hasExam &&
          (highPressureSubjects.contains(subject.name) ||
              highPressureSubjects.contains(subject.id))) {
        healthState = SubjectHealthState.needsAttention;
        healthExplanation = 'High exam pressure subject.';
      } else {
        healthState = SubjectHealthState.healthy;
        healthExplanation = 'Active and maintained.';
      }

      subjectHealths.add(
        SubjectHealthSummary(
          subject: subject,
          totalStudyMinutes: totalStudyMins,
          daysSinceLastStudied: daysSinceLastStudied,
          activeTaskCount: activeTaskCount,
          hasUpcomingExam: hasExam,
          state: healthState,
          explanation: healthExplanation,
        ),
      );
    }

    final isHeavy =
        overdueTasks.length >= 3 ||
        (todayTasks.length + overdueTasks.length) >= 6;

    return AcademicContext(
      upcomingExams: upcomingExams,
      overdueTasks: overdueTasks,
      todayTasks: todayTasks,
      activeSubjects: activeSubjects,
      examSummaries: examSummaries,
      subjectHealths: subjectHealths,
      highPressureSubjectIds: highPressureSubjects,
      neglectedSubjectIds: neglectedSubjects,
      isWorkloadHeavy: isHeavy,
    );
  }
}
