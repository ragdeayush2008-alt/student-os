import '../../data/models/exam.dart';

import 'package:meta/meta.dart';

import 'performance_snapshot.dart';

/// Deterministic exam preparation assessment.
/// Derives remaining work, urgency, and recommended actions from real data.
@immutable
class ExamPreparationResult {
  final int daysRemaining;
  final int syllabusTotal;
  final int syllabusCompleted;
  final int remainingTopics;
  final int linkedTaskCount;
  final int completedLinkedTasks;
  final int uncompletedLinkedTasks;
  final int recentStudyMinutes;
  final String urgencyLabel;
  final String explanation;
  final List<String> recommendations;

  const ExamPreparationResult({
    required this.daysRemaining,
    required this.syllabusTotal,
    required this.syllabusCompleted,
    required this.remainingTopics,
    required this.linkedTaskCount,
    required this.completedLinkedTasks,
    required this.uncompletedLinkedTasks,
    required this.recentStudyMinutes,
    required this.urgencyLabel,
    required this.explanation,
    required this.recommendations,
  });
}

/// Exam Preparation Engine — deterministic, explainable.
class ExamPreparationEngine {
  const ExamPreparationEngine();

  ExamPreparationResult assessExam(
    StudentExam exam,
    PerformanceSnapshot snapshot,
  ) {
    final days = exam.daysUntilExam ?? 999;
    final syllabusTotal = exam.syllabusTotal;
    final syllabusCompleted = exam.syllabusCompleted;
    final remainingTopics = syllabusTotal - syllabusCompleted;

    final linkedTasks = snapshot.allTasks
        .where((t) => t.examId == exam.id)
        .toList();
    final completedLinked = linkedTasks.where((t) => t.isCompleted).length;
    final uncompletedLinked = linkedTasks.length - completedLinked;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final recentStudyMinutes =
        snapshot.allSessions
            .where(
              (s) =>
                  s.isCompleted &&
                  s.startedAt.isAfter(cutoff) &&
                  s.subject.toLowerCase() == exam.subject.toLowerCase(),
            )
            .fold<int>(0, (sum, s) => sum + s.durationSec) ~/
        60;

    String urgencyLabel;
    if (days <= 3 && remainingTopics > 0) {
      urgencyLabel = 'Critical';
    } else if (days <= 7 && (remainingTopics > 2 || uncompletedLinked > 0)) {
      urgencyLabel = 'High';
    } else if (days <= 14 && (remainingTopics > 0 || uncompletedLinked > 0)) {
      urgencyLabel = 'Medium';
    } else {
      urgencyLabel = 'Scheduled';
    }

    final recommendations = <String>[];
    if (remainingTopics > 0) {
      recommendations.add(
        'Complete $remainingTopics remaining syllabus topic(s).',
      );
    }
    if (uncompletedLinked > 0) {
      recommendations.add('Finish $uncompletedLinked preparation task(s).');
    }
    if (recentStudyMinutes < 30 && days <= 7) {
      recommendations.add('Add focused study time for ${exam.subject}.');
    }
    if (days <= 3 && remainingTopics > 0) {
      recommendations.add('Prioritize near-term topics immediately.');
    }
    if (recommendations.isEmpty) {
      recommendations.add('Maintain preparation consistency.');
    }

    final explanation =
        '${days == 999 ? "No exam date" : "$days day(s) remaining"}. '
        '$syllabusCompleted/$syllabusTotal syllabus complete. '
        '$uncompletedLinked linked task(s) pending. '
        '${recentStudyMinutes}m recent study.';

    return ExamPreparationResult(
      daysRemaining: days,
      syllabusTotal: syllabusTotal,
      syllabusCompleted: syllabusCompleted,
      remainingTopics: remainingTopics,
      linkedTaskCount: linkedTasks.length,
      completedLinkedTasks: completedLinked,
      uncompletedLinkedTasks: uncompletedLinked,
      recentStudyMinutes: recentStudyMinutes,
      urgencyLabel: urgencyLabel,
      explanation: explanation,
      recommendations: recommendations,
    );
  }

  /// Recommended next action for exam preparation.
  String recommendedNextAction(StudentExam exam) {
    final result = assessExam(
      exam,
      const PerformanceSnapshot(
        allSessions: [],
        allTasks: [],
        allSubjects: [],
        allExams: [],
        studyDates: {},
      ),
    );
    if (result.remainingTopics > 0) {
      return 'Complete syllabus topic: ${exam.title}';
    }
    if (result.uncompletedLinkedTasks > 0) return 'Finish preparation task';
    if (result.recentStudyMinutes < 30) return 'Start study session';
    return 'Maintain preparation';
  }
}
