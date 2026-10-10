import '../intelligence/adaptive_priority_engine.dart';
import '../intelligence/academic_context.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/exams/exam_controller.dart';

/// Deterministic Next Best Action recommendation.
/// Uses existing controllers and AdaptivePriorityEngine.
/// Never mutates student data.
class SmartRecommendationEngine {
  const SmartRecommendationEngine();

  /// Produces a single explainable recommendation from real state.
  PrioritizedAction? recommend({
    String? restrictToSubjectId,
    String? restrictToExamId,
  }) {
    final ctx = AcademicContext.fromControllers();

    final all = AdaptivePriorityEngine().derivePrioritizedActions(ctx);
    PrioritizedAction? best;
    double bestScore = -1;

    for (final action in all) {
      if (action.taskId != null) {
        // Safety: deleted tasks must not be recommended
        final taskExists = TaskController.instance.tasks.any(
          (t) => t.id == action.taskId,
        );
        if (!taskExists) continue;
      }
      if (action.examId != null) {
        final examExists = ExamController.instance.upcomingExams.any(
          (e) => e.id == action.examId,
        );
        if (!examExists) continue;
      }
      if (action.subjectId != null) {
        final subjExists = SubjectController.instance.subjects.any(
          (s) => s.id == action.subjectId,
        );
        if (!subjExists) continue;
      }
      if (restrictToSubjectId != null &&
          action.subjectId != restrictToSubjectId) {
        continue;
      }
      if (restrictToExamId != null && action.examId != restrictToExamId) {
        continue;
      }
      if (action.priorityScore > bestScore) {
        bestScore = action.priorityScore;
        best = action;
      }
    }
    return best;
  }

  /// Returns ordered recommendations (e.g., for plan ordering).
  List<PrioritizedAction> orderRecommendations({
    String? restrictToSubjectId,
    String? restrictToExamId,
  }) {
    final ctx = AcademicContext.fromControllers();
    final all = AdaptivePriorityEngine().derivePrioritizedActions(ctx);
    final valid = <PrioritizedAction>[];
    for (final a in all) {
      if (a.taskId != null &&
          !TaskController.instance.tasks.any((t) => t.id == a.taskId)) {
        continue;
      }
      if (a.examId != null &&
          !ExamController.instance.upcomingExams.any((e) => e.id == a.examId)) {
        continue;
      }
      if (a.subjectId != null &&
          !SubjectController.instance.subjects.any((s) => s.id == a.subjectId)) {
        continue;
      }
      if (restrictToSubjectId != null && a.subjectId != restrictToSubjectId) {
        continue;
      }
      if (restrictToExamId != null && a.examId != restrictToExamId) {
        continue;
      }
      valid.add(a);
    }
    valid.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return valid;
  }
}
