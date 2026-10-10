import 'performance_snapshot.dart';
import '../../data/models/exam.dart';

/// Revision priority engine — deterministic, explainable.
/// Uses exam proximity, syllabus state, last study, tasks, resources.
class RevisionPriorityEngine {
  const RevisionPriorityEngine();

  RevisionPriorityResult assessRevision(
    StudentExam exam,
    PerformanceSnapshot snapshot,
  ) {
    final days = exam.daysUntilExam ?? 999;
    final syllabusTotal = exam.syllabusTotal;
    final syllabusCompleted = exam.syllabusCompleted;
    final remainingTopics = syllabusTotal - syllabusCompleted;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final recentStudy =
        snapshot.allSessions
            .where(
              (s) =>
                  s.isCompleted &&
                  s.startedAt.isAfter(cutoff) &&
                  s.subject.toLowerCase() == exam.subject.toLowerCase(),
            )
            .fold<int>(0, (sum, s) => sum + s.durationSec) ~/
        60;

    // Revision needed if topic not recently studied or incomplete
    final needsRevision =
        remainingTopics > 0 ||
        recentStudy < 30 ||
        (days <= 7 && syllabusCompleted < syllabusTotal);

    String priorityLabel;
    if (days <= 3 && remainingTopics > 0) {
      priorityLabel = 'Critical';
    } else if (days <= 7 && (remainingTopics > 0 || recentStudy < 30)) {
      priorityLabel = 'High';
    } else if (days <= 14 && remainingTopics > 0) {
      priorityLabel = 'Medium';
    } else {
      priorityLabel = 'Scheduled';
    }

    final recommendations = <String>[];
    if (remainingTopics > 0) {
      recommendations.add(
        'Complete $remainingTopics remaining syllabus topic(s).',
      );
    }
    if (recentStudy < 30 && days <= 7) {
      recommendations.add('Add focused revision study for ${exam.subject}.');
    }
    if (exam.syllabusItems.isNotEmpty) {
      final uncompleted = exam.syllabusItems
          .where((s) => !s.completed)
          .toList();
      if (uncompleted.isNotEmpty) {
        recommendations.add(
          'Revise: ${uncompleted.length} topic(s) incomplete.',
        );
      }
    }
    if (recommendations.isEmpty) {
      recommendations.add('Maintain preparation consistency.');
    }

    final explanation =
        '${days == 999 ? "No date" : "$days days"} until exam. '
        '$syllabusCompleted/$syllabusTotal topics complete. '
        '${recentStudy}m recent study. ${needsRevision ? "Revision needed." : "On track."}';

    return RevisionPriorityResult(
      exam: exam,
      priorityLabel: priorityLabel,
      needsRevision: needsRevision,
      remainingTopics: remainingTopics,
      recentStudyMinutes: recentStudy,
      explanation: explanation,
      recommendations: recommendations,
    );
  }
}

class RevisionPriorityResult {
  final StudentExam exam;
  final String priorityLabel;
  final bool needsRevision;
  final int remainingTopics;
  final int recentStudyMinutes;
  final String explanation;
  final List<String> recommendations;

  const RevisionPriorityResult({
    required this.exam,
    required this.priorityLabel,
    required this.needsRevision,
    required this.remainingTopics,
    required this.recentStudyMinutes,
    required this.explanation,
    required this.recommendations,
  });
}
