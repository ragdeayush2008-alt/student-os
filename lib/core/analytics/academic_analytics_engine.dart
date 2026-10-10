import 'performance_snapshot.dart';

/// Core analytics engine for Student OS.
/// Derives performance metrics from historical study and task data.
class AcademicAnalyticsEngine {
  const AcademicAnalyticsEngine();

  /// Calculates total study minutes in the given duration.
  int calculateTotalStudyMinutes(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final now = DateTime.now();
    final limit = now.subtract(window);

    return snapshot.allSessions
            .where((s) => s.isCompleted && s.startedAt.isAfter(limit))
            .fold(0, (sum, s) => sum + s.durationSec) ~/
        60;
  }

  /// Calculates task completion rate in the window (percentage completed / total).
  double calculateTaskCompletionRate(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final now = DateTime.now();
    final limit = now.subtract(window);
    final relevantTasks = snapshot.allTasks
        .where((t) => t.createdAt.isAfter(limit))
        .toList();

    if (relevantTasks.isEmpty) return 0.0;
    return relevantTasks.where((t) => t.isCompleted).length /
        relevantTasks.length;
  }

  /// Calculates plan completion percentage (tasks done / total in period).
  double calculatePlanCompletionRate(
    PerformanceSnapshot snapshot,
    Duration window,
  ) {
    final now = DateTime.now();
    final limit = now.subtract(window);
    final relevantTasks = snapshot.allTasks
        .where(
          (t) =>
              (t.dueDate != null && t.dueDate!.isAfter(limit)) ||
              (t.scheduledDate != null && t.scheduledDate!.isAfter(limit)),
        )
        .toList();

    if (relevantTasks.isEmpty) return 0.0;
    return relevantTasks.where((t) => t.isCompleted).length /
        relevantTasks.length;
  }

  /// Determines readiness based on completed syllabus progress for upcoming exams.
  String calculateExamReadiness(PerformanceSnapshot snapshot) {
    int totalSyllabusWeight = 0;
    int totalSyllabusCompleted = 0;

    for (final exam in snapshot.allExams) {
      if (exam.isUpcoming) {
        totalSyllabusWeight += exam.syllabusTotal;
        totalSyllabusCompleted += exam.syllabusCompleted;
      }
    }

    if (totalSyllabusWeight == 0) return 'N/A';

    final progress = totalSyllabusCompleted / totalSyllabusWeight;

    if (progress >= 0.8) return 'Strong';
    if (progress >= 0.5) return 'Moderate';
    return 'Weak';
  }

  /// Calculates total notes count.
  int calculateTotalNotes(PerformanceSnapshot snapshot) {
    return snapshot.allNotes.length;
  }

  /// Calculates notes created this week.
  int calculateNotesCreatedThisWeek(PerformanceSnapshot snapshot) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return snapshot.allNotes
        .where((n) => n.createdAt.isAfter(weekStartDay))
        .length;
  }

  /// Calculates notes updated this week.
  int calculateNotesUpdatedThisWeek(PerformanceSnapshot snapshot) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return snapshot.allNotes
        .where((n) => n.updatedAt.isAfter(weekStartDay))
        .length;
  }

  /// Calculates notes by subject.
  Map<String, int> calculateNotesBySubject(PerformanceSnapshot snapshot) {
    final counts = <String, int>{};
    for (final note in snapshot.allNotes) {
      final subject = snapshot.allSubjects
          .where((s) => s.id == note.subjectId)
          .firstOrNull;
      final name = subject?.displayName ?? 'Unlinked';
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }

  /// Calculates notes by topic.
  Map<String, int> calculateNotesByTopic(PerformanceSnapshot snapshot) {
    final counts = <String, int>{};
    for (final note in snapshot.allNotes) {
      if (note.topicId != null) {
        final topic = snapshot.allTopics
            .where((t) => t.id == note.topicId)
            .firstOrNull;
        if (topic != null) {
          counts[topic.title] = (counts[topic.title] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  /// Calculates knowledge coverage for a subject.
  Map<String, dynamic> calculateSubjectKnowledgeCoverage(
    PerformanceSnapshot snapshot,
    String subjectId,
  ) {
    final subjectNotes = snapshot.allNotes.where((n) => n.subjectId == subjectId).toList();
    final subjectTopics = snapshot.allTopics.where((t) => t.subjectId == subjectId).toList();

    if (subjectTopics.isEmpty) {
      return {
        'notesCount': subjectNotes.length,
        'topicsWithNotes': 0,
        'topicsWithoutNotes': 0,
        'coveragePercentage': 0,
      };
    }

    final coveredTopicIds = subjectNotes
        .where((n) => n.hasTopic)
        .map((n) => n.topicId!)
        .toSet();

    final topicsWith = subjectTopics.where((t) => coveredTopicIds.contains(t.id)).length;
    final topicsWithout = subjectTopics.length - topicsWith;
    final coverage = (topicsWith / subjectTopics.length) * 100;

    return {
      'notesCount': subjectNotes.length,
      'topicsWithNotes': topicsWith,
      'topicsWithoutNotes': topicsWithout,
      'coveragePercentage': coverage.round(),
    };
  }
}
