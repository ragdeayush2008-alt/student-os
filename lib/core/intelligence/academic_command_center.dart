import 'package:flutter/foundation.dart';

import '../../features/tasks/task_controller.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/subjects/subject_controller.dart';

/// Derived academic workspace overview.
/// Uses existing controllers; never duplicates persistent state.
@immutable
class AcademicCommandCenter {
  const AcademicCommandCenter();

  /// Derive subject workspace statistics from real controller state.
  static Map<String, int> deriveSubjectStats(String subjectId) {
    final tasks = TaskController.instance.activeTasks
        .where((t) => t.subjectId == subjectId)
        .toList();
    final completed = tasks.where((t) => t.isCompleted).length;
    final overdue = tasks.where((t) => t.isOverdue && !t.isCompleted).length;
    final exams = ExamController.instance.upcomingExams
        .where(
          (e) =>
              e.subject.toLowerCase() == _subjectName(subjectId)?.toLowerCase(),
        )
        .toList();
    return {
      'activeTasks': tasks.where((t) => !t.isCompleted).length,
      'completedTasks': completed,
      'overdueTasks': overdue,
      'upcomingExams': exams.length,
    };
  }

  static String? _subjectName(String subjectId) {
    try {
      final s = SubjectController.instance.subjects.firstWhere(
        (sub) => sub.id == subjectId,
      );
      return s.name;
    } catch (_) {
      return null;
    }
  }

  /// Derive exam preparation context from real exam + tasks.
  static Map<String, dynamic> deriveExamContext(String examId) {
    final exam = ExamController.instance.upcomingExams
        .cast<dynamic>()
        .firstWhere((e) => e.id == examId, orElse: () => null);
    if (exam == null) return {};
    final tasks = TaskController.instance.activeTasks
        .where((t) => t.examId == examId && !t.isCompleted)
        .toList();
    final completed = TaskController.instance.activeTasks
        .where((t) => t.examId == examId && t.isCompleted)
        .length;
    return {
      'daysRemaining': exam.daysUntilExam,
      'prepTasks': tasks.length,
      'prepCompleted': completed,
      'readinessAvailable': true,
    };
  }
}
