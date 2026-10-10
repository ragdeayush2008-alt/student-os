import 'performance_snapshot.dart';
import '../../data/models/exam.dart';

enum ExamReadinessLevel {
  strong,
  onTrack,
  needsAttention,
  critical,
  insufficientData,
}

class ExamReadinessResult {
  final double score;
  final ExamReadinessLevel level;
  final String explanation;
  final List<String> reasons;

  const ExamReadinessResult({
    required this.score,
    required this.level,
    required this.explanation,
    this.reasons = const [],
  });
}

class ExamReadinessAnalyzer {
  const ExamReadinessAnalyzer();

  ExamReadinessResult calculateReadiness(
    StudentExam exam,
    PerformanceSnapshot snapshot,
  ) {
    if (exam.examDateTime == null || exam.isCompleted) {
      return const ExamReadinessResult(
        score: 1.0,
        level: ExamReadinessLevel.strong,
        explanation: 'Exam not scheduled or already completed.',
        reasons: ['No upcoming exam date or exam already completed.'],
      );
    }

    final daysUntil = exam.daysUntilExam ?? 0;
    final syllabusProgress = exam.syllabusProgress;
    final syllabusCompleted = exam.syllabusCompleted;
    final syllabusTotal = exam.syllabusTotal;

    final reasons = <String>[];

    if (syllabusTotal > 0) {
      reasons.add(
        '$syllabusCompleted of $syllabusTotal syllabus items complete (${(syllabusProgress * 100).round()}%).',
      );
    } else {
      reasons.add('No syllabus items defined.');
    }

    final linkedTasks = snapshot.allTasks
        .where((t) => t.examId == exam.id && !t.isCompleted)
        .toList();
    final completedLinkedTasks = snapshot.allTasks
        .where((t) => t.examId == exam.id && t.isCompleted)
        .toList();

    if (linkedTasks.isNotEmpty) {
      reasons.add(
        '${linkedTasks.length} linked preparation task(s) remaining.',
      );
    }
    if (completedLinkedTasks.isNotEmpty) {
      reasons.add(
        '${completedLinkedTasks.length} preparation task(s) completed.',
      );
    }

    final subjectSessions = snapshot.allSessions
        .where(
          (s) =>
              s.isCompleted &&
              s.subject.toLowerCase() == exam.subject.toLowerCase(),
        )
        .toList();
    final recentCutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentStudyMinutes =
        subjectSessions
            .where((s) => s.startedAt.isAfter(recentCutoff))
            .fold<int>(0, (sum, s) => sum + s.durationSec) ~/
        60;

    if (recentStudyMinutes > 0) {
      reasons.add(
        '$recentStudyMinutes minutes studied recently for ${exam.subject}.',
      );
    } else {
      reasons.add(
        'No recent study activity for ${exam.subject} in the last 7 days.',
      );
    }

    double score = syllabusProgress;

    if (linkedTasks.isNotEmpty) {
      final taskProgress =
          1.0 -
          (linkedTasks.length /
              (linkedTasks.length + completedLinkedTasks.length));
      score = (score + taskProgress) / 2.0;
    }

    if (daysUntil < 0) {
      reasons.add('Exam was scheduled in the past.');
      return ExamReadinessResult(
        score: score.clamp(0.0, 1.0),
        level: ExamReadinessLevel.critical,
        explanation: 'Exam date has passed without completion.',
        reasons: reasons,
      );
    }

    if (syllabusTotal == 0 && linkedTasks.isEmpty) {
      return ExamReadinessResult(
        score: 0.0,
        level: ExamReadinessLevel.insufficientData,
        explanation: 'No syllabus or preparation tasks defined for this exam.',
        reasons: [
          'Add syllabus items or linked preparation tasks to assess readiness.',
        ],
      );
    }

    if (daysUntil <= 3 && syllabusProgress < 0.5) {
      score *= 0.5;
      reasons.add('Only $daysUntil days remaining with low syllabus progress.');
    } else if (daysUntil <= 7 && syllabusProgress < 0.7) {
      score *= 0.75;
      reasons.add('$daysUntil days remaining with moderate syllabus progress.');
    } else if (daysUntil <= 14 && syllabusProgress < 0.5) {
      score *= 0.85;
      reasons.add('$daysUntil days remaining but syllabus is below 50%.');
    } else if (daysUntil > 14 && syllabusProgress >= 0.8) {
      score = (score + 0.1).clamp(0.0, 1.0);
      reasons.add('Ample time with strong syllabus progress.');
    }

    if (recentStudyMinutes == 0 && daysUntil <= 7) {
      score *= 0.8;
      reasons.add('No recent study activity with a near-term exam.');
    }

    final level = _classifyLevel(score, daysUntil, syllabusProgress);
    String stateLabel = _levelToString(level);

    return ExamReadinessResult(
      score: score.clamp(0.0, 1.0),
      level: level,
      explanation: '$stateLabel. ${reasons.isNotEmpty ? reasons.first : ''}',
      reasons: reasons,
    );
  }

  ExamReadinessLevel _classifyLevel(
    double score,
    int daysUntil,
    double syllabusProgress,
  ) {
    if (score >= 0.8) return ExamReadinessLevel.strong;
    if (score >= 0.6) return ExamReadinessLevel.onTrack;
    if (score >= 0.4) return ExamReadinessLevel.needsAttention;
    return ExamReadinessLevel.critical;
  }

  String _levelToString(ExamReadinessLevel level) {
    switch (level) {
      case ExamReadinessLevel.strong:
        return 'Strong';
      case ExamReadinessLevel.onTrack:
        return 'On Track';
      case ExamReadinessLevel.needsAttention:
        return 'Needs Attention';
      case ExamReadinessLevel.critical:
        return 'Critical';
      case ExamReadinessLevel.insufficientData:
        return 'Insufficient Data';
    }
  }
}
