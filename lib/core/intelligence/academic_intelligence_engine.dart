import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/exam.dart';
import '../../data/models/study_session.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/academic_resource.dart';
import '../../data/models/revision_record.dart';
import '../../data/models/revision_schedule.dart';
import '../../data/models/topic.dart';
import '../../data/models/topic_practice_attempt.dart';
import '../../features/knowledge/academic_knowledge_controller.dart';
import '../../features/knowledge/topic_practice_controller.dart';
import '../../features/revision/revision_controller.dart';
import 'academic_knowledge_engine.dart';

/// Pressure level for an upcoming exam.
enum ExamPressureLevel {
  low('Low exam pressure', Color(0xFF6F967F)),
  moderate('Moderate exam pressure', Color(0xFF4F7D68)),
  high('High exam pressure', Color(0xFF7A8450)),
  critical('Critical exam pressure', Color(0xFF1F5C44));

  const ExamPressureLevel(this.label, this.color);
  final String label;
  final Color color;
}

/// Assessment result for an exam's pressure.
@immutable
class ExamPressureAssessment {
  const ExamPressureAssessment({
    required this.exam,
    required this.level,
    required this.score,
    required this.reasons,
    required this.daysRemaining,
    required this.syllabusRemainingCount,
    required this.pendingTasksCount,
    required this.recentStudyMinutes,
  });

  final StudentExam exam;
  final ExamPressureLevel level;
  final double score; // 0.0 to 100.0+
  final List<String> reasons;
  final int daysRemaining;
  final int syllabusRemainingCount;
  final int pendingTasksCount;
  final int recentStudyMinutes;

  String get primaryReason =>
      reasons.isNotEmpty ? reasons.first : 'Exam approaching';
}

/// Urgency level for recommendations.
enum RecommendationUrgency {
  critical('Critical', Color(0xFF1F5C44)),
  high('High', Color(0xFF7A8450)),
  medium('Medium', Color(0xFF285C4D)),
  low('Low', Color(0xFF6F967F));

  const RecommendationUrgency(this.label, this.color);
  final String label;
  final Color color;
}

/// Type of recommended academic activity.
enum AcademicRecommendationType {
  studySubject('Subject Study'),
  reviseTopic('Revision'),
  practiceTopic('Practice'),
  examPrep('Exam Preparation'),
  completeTask('Task Execution');

  const AcademicRecommendationType(this.label);
  final String label;
}

/// A structured recommendation for studying a subject or preparing for an exam.
@immutable
class StudyRecommendation {
  const StudyRecommendation({
    required this.id,
    required this.title,
    required this.subjectName,
    this.subjectId,
    this.subject,
    this.exam,
    this.task,
    this.topicTitle,
    this.topicId,
    this.chapterId,
    required this.suggestedDurationMinutes,
    required this.urgency,
    required this.type,
    required this.primaryReason,
    required this.reasons,
    required this.score,
  });

  final String id;
  final String title;
  final String subjectName;
  final String? subjectId;
  final Subject? subject;
  final StudentExam? exam;
  final StudentTask? task;
  final String? topicTitle;
  final String? topicId;
  final String? chapterId;
  final int suggestedDurationMinutes;
  final RecommendationUrgency urgency;
  final AcademicRecommendationType type;
  final String primaryReason;
  final List<String> reasons;
  final double score;
}

/// A structured recommendation for revision.
@immutable
class RevisionRecommendation {
  const RevisionRecommendation({
    required this.id,
    required this.title,
    required this.subjectName,
    this.subjectId,
    this.examId,
    this.topicTitle,
    this.topicId,
    this.chapterId,
    this.resourceId,
    required this.urgency,
    required this.reasons,
    required this.score,
    required this.daysSinceStudiedOrRevised,
    this.isOverdue = false,
  });

  final String id;
  final String title;
  final String subjectName;
  final String? subjectId;
  final String? examId;
  final String? topicTitle;
  final String? topicId;
  final String? chapterId;
  final String? resourceId;
  final RecommendationUrgency urgency;
  final List<String> reasons;
  final double score;
  final int daysSinceStudiedOrRevised;
  final bool isOverdue;

  String get primaryReason =>
      reasons.isNotEmpty ? reasons.first : 'Scheduled revision';
}

/// A structured recommendation for practicing a topic.
@immutable
class PracticeRecommendation {
  const PracticeRecommendation({
    required this.id,
    required this.title,
    required this.subjectName,
    this.subjectId,
    this.chapterId,
    this.topicTitle,
    this.topicId,
    required this.suggestedDurationMinutes,
    required this.urgency,
    required this.reasons,
    required this.score,
    this.accuracyPercentage,
    this.attemptsCount = 0,
    this.isWeak = false,
  });

  final String id;
  final String title;
  final String subjectName;
  final String? subjectId;
  final String? chapterId;
  final String? topicTitle;
  final String? topicId;
  final int suggestedDurationMinutes;
  final RecommendationUrgency urgency;
  final List<String> reasons;
  final double score;
  final int? accuracyPercentage;
  final int attemptsCount;
  final bool isWeak;

  String get primaryReason =>
      reasons.isNotEmpty ? reasons.first : 'Targeted topic practice';
}

/// A block in an available-time aware study allocation schedule.
@immutable
class StudyAllocationBlock {
  const StudyAllocationBlock({
    required this.title,
    required this.subjectName,
    this.subjectId,
    this.examId,
    this.topicTitle,
    this.topicId,
    this.chapterId,
    required this.durationMinutes,
    required this.isBreak,
    required this.reason,
    required this.type,
  });

  final String title;
  final String subjectName;
  final String? subjectId;
  final String? examId;
  final String? topicTitle;
  final String? topicId;
  final String? chapterId;
  final int durationMinutes;
  final bool isBreak;
  final String reason;
  final AcademicRecommendationType type;
}

/// Result of distributing available study time across subjects and revision.
@immutable
class StudyTimeAllocation {
  const StudyTimeAllocation({
    required this.totalAvailableMinutes,
    required this.allocatedStudyMinutes,
    required this.allocatedBreakMinutes,
    required this.blocks,
    required this.summary,
  });

  final int totalAvailableMinutes;
  final int allocatedStudyMinutes;
  final int allocatedBreakMinutes;
  final List<StudyAllocationBlock> blocks;
  final String summary;

  bool get hasBlocks => blocks.isNotEmpty;
  List<StudyAllocationBlock> get studyBlocks =>
      blocks.where((b) => !b.isBreak).toList();
}

/// Comprehensive preparation summary for an upcoming exam.
@immutable
class ExamPreparationBreakdown {
  const ExamPreparationBreakdown({
    required this.exam,
    required this.pressure,
    required this.todayTasks,
    required this.thisWeekTasks,
    required this.atRiskItems,
    required this.unrevisedTopics,
    required this.recentStudyMinutes,
  });

  final StudentExam exam;
  final ExamPressureAssessment pressure;
  final List<StudentTask> todayTasks;
  final List<StudentTask> thisWeekTasks;
  final List<String> atRiskItems;
  final List<SyllabusItem> unrevisedTopics;
  final int recentStudyMinutes;
}

/// Unified academic recommendation output.
@immutable
class UnifiedRecommendationResult {
  const UnifiedRecommendationResult({
    required this.primary,
    required this.alternatives,
    required this.revisionItems,
    required this.activeExamsWithPressure,
  });

  final StudyRecommendation? primary;
  final List<StudyRecommendation> alternatives;
  final List<RevisionRecommendation> revisionItems;
  final List<ExamPressureAssessment> activeExamsWithPressure;

  bool get hasRecommendation => primary != null;
}

/// Pure, deterministic, offline-first Academic Intelligence Engine.
///
/// Combines Subjects, Exams, Study History, Revision, and Tasks into
/// prioritized, explainable recommendations without external API dependencies.
abstract final class AcademicIntelligenceEngine {
  /// Matches a subject by name or id against a list of subjects case-insensitively.
  static Subject? findSubjectMatch(String nameOrId, List<Subject> subjects) {
    final needle = nameOrId.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final s in subjects) {
      if (s.id.toLowerCase() == needle ||
          s.name.trim().toLowerCase() == needle ||
          s.displayName.trim().toLowerCase() == needle) {
        return s;
      }
    }
    return null;
  }

  /// Calculates total completed study minutes for a given subject in the last [days] days.
  static int studyMinutesForSubject(
    String subjectNameOrId,
    List<StudySession> sessions, {
    int days = 7,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final needle = subjectNameOrId.trim().toLowerCase();

    int totalSec = 0;
    for (final s in sessions) {
      if (!s.isCompleted) continue;
      if (s.startedAt.isBefore(cutoff)) continue;
      final sessionSubj = s.subject.trim().toLowerCase();
      if (sessionSubj == needle || s.taskId == subjectNameOrId) {
        totalSec += s.durationSec;
      }
    }
    return totalSec ~/ 60;
  }

  /// Days since the last completed study session for a given subject. Returns 999 if never studied.
  static int daysSinceLastStudied(
    String subjectNameOrId,
    List<StudySession> sessions, {
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final needle = subjectNameOrId.trim().toLowerCase();

    DateTime? latest;
    for (final s in sessions) {
      if (!s.isCompleted) continue;
      final sessionSubj = s.subject.trim().toLowerCase();
      if (sessionSubj == needle) {
        if (latest == null || s.startedAt.isAfter(latest)) {
          latest = s.startedAt;
        }
      }
    }

    if (latest == null) return 999;
    final latestDay = DateTime(latest.year, latest.month, latest.day);
    return math.max(0, today.difference(latestDay).inDays);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. EXAM PRESSURE ENGINE
  // ══════════════════════════════════════════════════════════════════════════

  /// Deterministically evaluates the pressure level of a [StudentExam].
  static ExamPressureAssessment assessExamPressure(
    StudentExam exam, {
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<Subject> subjects = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = exam.examDateTime != null
        ? DateTime(exam.examDateTime!.year, exam.examDateTime!.month, exam.examDateTime!.day)
            .difference(today)
            .inDays
        : (exam.daysUntilExam ?? 999);

    final syllabusTotal = exam.syllabusTotal;
    final syllabusCompleted = exam.syllabusCompleted;
    final remainingTopics = syllabusTotal - syllabusCompleted;

    final linkedTasks = tasks.where((t) => t.examId == exam.id).toList();
    final pendingTasks = linkedTasks.where((t) => !t.isCompleted).length;

    final recentStudy = studyMinutesForSubject(
      exam.subject,
      sessions,
      days: 7,
      referenceTime: now,
    );

    // Deterministic Pressure Score Calculation
    double score = 0.0;
    final reasons = <String>[];

    // 1. Proximity Urgency
    if (days <= 0) {
      score += 55.0;
      reasons.add('Exam is today!');
    } else if (days == 1) {
      score += 48.0;
      reasons.add('Exam is tomorrow');
    } else if (days <= 3) {
      score += 40.0;
      reasons.add('Exam in $days days');
    } else if (days <= 7) {
      score += 25.0;
      reasons.add('Exam in $days days');
    } else if (days <= 14) {
      score += 15.0;
      reasons.add('Exam in $days days');
    } else if (days <= 30) {
      score += 8.0;
      reasons.add('Exam in $days days');
    }

    // 2. Incomplete Syllabus
    if (syllabusTotal > 0) {
      final incompleteRatio = remainingTopics / syllabusTotal;
      if (incompleteRatio > 0) {
        final topicPoints = (incompleteRatio * 25.0).clamp(0.0, 25.0);
        score += topicPoints;
        reasons.add('$remainingTopics of $syllabusTotal topics remaining');
      }
    } else if (days <= 7 && days >= 0) {
      score += 10.0;
      reasons.add('No syllabus outline defined');
    }

    // 3. Pending Preparation Tasks
    if (pendingTasks > 0) {
      score += math.min(20.0, pendingTasks * 6.0);
      reasons.add('$pendingTasks preparation ${pendingTasks == 1 ? "task" : "tasks"} pending');
    }

    // 4. Study Deficit in Past 7 Days
    if (days <= 7 && days >= 0) {
      if (recentStudy == 0) {
        score += 18.0;
        reasons.add('No study recorded in the past 7 days');
      } else if (recentStudy < 30) {
        score += 12.0;
        reasons.add('Only ${recentStudy}m studied this week');
      } else if (recentStudy < 60 && days <= 3) {
        score += 8.0;
        reasons.add('${recentStudy}m studied this week');
      }
    }

    // 5. Subject Preference Weight
    final matchedSubject = findSubjectMatch(exam.subject, subjects);
    if (matchedSubject != null) {
      if (matchedSubject.preference == SubjectPreference.high) {
        score += 10.0;
      } else if (matchedSubject.preference == SubjectPreference.low) {
        score -= 5.0;
      }
    }

    score = score.clamp(0.0, 150.0);

    // Classify Level
    ExamPressureLevel level;
    if (score >= 60.0 || (days <= 2 && remainingTopics > 0)) {
      level = ExamPressureLevel.critical;
    } else if (score >= 38.0 || (days <= 7 && (remainingTopics > 0 || recentStudy < 30))) {
      level = ExamPressureLevel.high;
    } else if (score >= 20.0 || (days <= 14 && remainingTopics > 0)) {
      level = ExamPressureLevel.moderate;
    } else {
      level = ExamPressureLevel.low;
    }

    if (reasons.isEmpty) {
      reasons.add('Preparation on track');
    }

    return ExamPressureAssessment(
      exam: exam,
      level: level,
      score: score,
      reasons: reasons,
      daysRemaining: days,
      syllabusRemainingCount: remainingTopics,
      pendingTasksCount: pendingTasks,
      recentStudyMinutes: recentStudy,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. STUDY & REVISION INTELLIGENCE
  // ══════════════════════════════════════════════════════════════════════════

  /// Generates a prioritized list of study recommendations.
  static List<StudyRecommendation> generateStudyRecommendations({
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<Topic>? topics,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final activeSubjects = subjects.where((s) => s.isActive).toList();
    final upcomingExams = exams.where((e) => e.isUpcoming).toList();
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final allTopics = topics ?? AcademicKnowledgeController.instance.topics;

    final recommendations = <StudyRecommendation>[];

    // Evaluate each subject
    for (final subject in activeSubjects) {
      final subjectName = subject.name.isNotEmpty ? subject.name : subject.displayName;
      final recentStudyMins = studyMinutesForSubject(
        subject.name,
        sessions,
        days: 7,
        referenceTime: now,
      );
      final daysSinceStudy = daysSinceLastStudied(
        subject.name,
        sessions,
        referenceTime: now,
      );

      // Match linked upcoming exams
      final subjectExams = upcomingExams.where((e) {
        final examSubj = e.subject.trim().toLowerCase();
        return examSubj == subject.name.trim().toLowerCase() ||
            examSubj == subject.displayName.trim().toLowerCase() ||
            examSubj == subject.id.toLowerCase();
      }).toList()
        ..sort((a, b) => (a.daysUntilExam ?? 999).compareTo(b.daysUntilExam ?? 999));

      final nextExam = subjectExams.firstOrNull;
      ExamPressureAssessment? examPressure;
      if (nextExam != null) {
        examPressure = assessExamPressure(
          nextExam,
          sessions: sessions,
          tasks: tasks,
          subjects: subjects,
          referenceTime: now,
        );
      }

      // Match linked tasks
      final subjectTasks = activeTasks.where((t) =>
          t.subjectId == subject.id ||
          t.category.trim().toLowerCase() == subject.name.trim().toLowerCase()).toList();

      final criticalTasks = subjectTasks.where((t) =>
          t.priority == TaskPriority.critical || t.isOverdue).toList();

      // Check for structured curriculum topics
      final subjectTopics = allTopics.where((t) => t.subjectId == subject.id).toList();
      Topic? recommendedTopic;
      TopicPriorityAssessment? topicAssessment;

      if (subjectTopics.isNotEmpty) {
        final assessments = subjectTopics.map((t) {
          return AcademicKnowledgeEngine.assessTopicPriority(
            t,
            exams: exams,
            sessions: sessions,
            preference: subject.preference,
            referenceTime: now,
          );
        }).toList()
          ..sort((a, b) => b.score.compareTo(a.score));

        topicAssessment = assessments.firstOrNull;
        recommendedTopic = topicAssessment?.topic;
      }

      // Find next uncompleted topic if exam exists and no structured topic was found
      String? nextTopicTitle = recommendedTopic?.title;
      if (nextTopicTitle == null && nextExam != null && nextExam.syllabusItems.isNotEmpty) {
        for (final item in nextExam.syllabusItems) {
          if (!item.completed) {
            nextTopicTitle = item.title;
            break;
          }
        }
      }

      // Score Subject Priority
      double score = 20.0;
      final reasons = <String>[];

      // Subject Preference Multiplier
      score *= subject.preference.weightMultiplier;
      if (subject.preference == SubjectPreference.high) {
        reasons.add('High priority subject');
      }

      // Topic priority score contribution
      if (topicAssessment != null) {
        score += topicAssessment.score * 0.5;
        for (final r in topicAssessment.reasons) {
          if (!reasons.contains(r)) reasons.add(r);
        }
      }

      // Exam pressure influence
      if (examPressure != null) {
        score += examPressure.score * 0.8;
        if (examPressure.daysRemaining == 0) {
          reasons.add('Exam is today: ${nextExam!.title}');
        } else if (examPressure.daysRemaining == 1) {
          reasons.add('Exam is tomorrow: ${nextExam!.title}');
        } else if (examPressure.daysRemaining <= 7) {
          reasons.add('Exam in ${examPressure.daysRemaining} days: ${nextExam!.title}');
        } else if (examPressure.daysRemaining <= 14) {
          reasons.add('Exam in ${examPressure.daysRemaining} days');
        }

        if (examPressure.syllabusRemainingCount > 0) {
          reasons.add('${examPressure.syllabusRemainingCount} topics to cover');
        }
      }

      // Neglected subject scoring
      if (daysSinceStudy >= 7 && activeSubjects.length > 1) {
        score += 25.0;
        reasons.add('Not studied in $daysSinceStudy days');
      } else if (daysSinceStudy >= 4 && nextExam != null) {
        score += 15.0;
        reasons.add('Not studied in $daysSinceStudy days');
      }

      // Study time deficit this week
      if (recentStudyMins == 0) {
        score += 15.0;
        reasons.add('0m studied this week');
      } else if (recentStudyMins < 30) {
        score += 8.0;
        reasons.add('Only ${recentStudyMins}m studied this week');
      }

      // Task urgency
      if (criticalTasks.isNotEmpty) {
        score += math.min(25.0, criticalTasks.length * 10.0);
        reasons.add('${criticalTasks.length} urgent/overdue task(s)');
      } else if (subjectTasks.isNotEmpty) {
        score += math.min(12.0, subjectTasks.length * 3.0);
      }

      // Determine duration & urgency
      int duration = 45;
      if (recommendedTopic != null && recommendedTopic.estimatedMinutes > 0) {
        duration = recommendedTopic.estimatedMinutes;
      } else if (examPressure != null && examPressure.level == ExamPressureLevel.critical) {
        duration = 50;
      } else if (recentStudyMins < 20) {
        duration = 35;
      }

      RecommendationUrgency urgency;
      if (score >= 65.0) {
        urgency = RecommendationUrgency.critical;
      } else if (score >= 40.0) {
        urgency = RecommendationUrgency.high;
      } else if (score >= 25.0) {
        urgency = RecommendationUrgency.medium;
      } else {
        urgency = RecommendationUrgency.low;
      }

      final primaryReason = reasons.isNotEmpty ? reasons.first : 'Regular study schedule';

      String title;
      AcademicRecommendationType recType;
      if (recommendedTopic != null) {
        title = 'Study ${recommendedTopic.title}';
        recType = AcademicRecommendationType.studySubject;
      } else if (nextTopicTitle != null) {
        title = 'Study $nextTopicTitle';
        recType = AcademicRecommendationType.examPrep;
      } else if (nextExam != null) {
        title = 'Prepare for ${nextExam.title}';
        recType = AcademicRecommendationType.examPrep;
      } else {
        title = 'Study $subjectName';
        recType = AcademicRecommendationType.studySubject;
      }

      recommendations.add(
        StudyRecommendation(
          id: recommendedTopic != null ? 'rec_top_${recommendedTopic.id}' : 'rec_subj_${subject.id}',
          title: title,
          subjectName: subjectName,
          subjectId: subject.id,
          subject: subject,
          exam: nextExam,
          task: criticalTasks.firstOrNull ?? subjectTasks.firstOrNull,
          topicTitle: nextTopicTitle,
          topicId: recommendedTopic?.id,
          chapterId: recommendedTopic?.chapterId,
          suggestedDurationMinutes: duration,
          urgency: urgency,
          type: recType,
          primaryReason: primaryReason,
          reasons: reasons,
          score: score,
        ),
      );
    }

    // Also consider orphan upcoming exams not matched to a Subject entity
    for (final exam in upcomingExams) {
      final isCovered = recommendations.any((r) => r.exam?.id == exam.id);
      if (!isCovered && exam.subject.isNotEmpty) {
        final examPressure = assessExamPressure(
          exam,
          sessions: sessions,
          tasks: tasks,
          subjects: subjects,
          referenceTime: now,
        );

        final reasons = List<String>.from(examPressure.reasons);
        recommendations.add(
          StudyRecommendation(
            id: 'rec_exam_${exam.id}',
            title: 'Prepare for ${exam.title}',
            subjectName: exam.subject,
            subjectId: null,
            exam: exam,
            topicTitle: exam.syllabusItems.where((s) => !s.completed).firstOrNull?.title,
            suggestedDurationMinutes: 40,
            urgency: examPressure.level == ExamPressureLevel.critical
                ? RecommendationUrgency.critical
                : RecommendationUrgency.high,
            type: AcademicRecommendationType.examPrep,
            primaryReason: examPressure.primaryReason,
            reasons: reasons,
            score: examPressure.score + 10.0,
          ),
        );
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations;
  }

  /// Generates deterministic revision recommendations from curriculum topics, syllabus items and resources.
  static List<RevisionRecommendation> generateRevisionRecommendations({
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<AcademicResource> resources = const [],
    List<Topic>? topics,
    List<RevisionRecord> revisionRecords = const [],
    List<RevisionSchedule> revisionSchedules = const [],
    List<TopicPracticeAttempt> practiceAttempts = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final upcomingExams = exams.where((e) => e.isUpcoming).toList();
    final allTopics = topics ?? AcademicKnowledgeController.instance.topics;
    final allRecords = revisionRecords.isNotEmpty ? revisionRecords : RevisionController.instance.records;
    final allSchedules = revisionSchedules.isNotEmpty ? revisionSchedules : RevisionController.instance.schedules;
    final allPractices = practiceAttempts.isNotEmpty ? practiceAttempts : TopicPracticeController.instance.attempts;
    final revisionItems = <RevisionRecommendation>[];

    // 1. Revision from Structured Curriculum Topics
    for (final topic in allTopics) {
      final prog = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: sessions,
        practiceAttempts: allPractices,
        revisionRecords: allRecords,
        revisionSchedules: allSchedules,
        referenceTime: now,
      );

      if (prog.isRevisionDue || prog.isRevisionOverdue || prog.isWeakTopic) {
        final matchedSubj = findSubjectMatch(topic.subjectId, subjects);
        final subjectExams = upcomingExams.where((e) =>
            e.subject.trim().toLowerCase() == topic.subjectId.toLowerCase() ||
            (matchedSubj != null && e.subject.trim().toLowerCase() == matchedSubj.name.trim().toLowerCase())).toList()
          ..sort((a, b) => (a.daysUntilExam ?? 999).compareTo(b.daysUntilExam ?? 999));

        final nextExam = subjectExams.firstOrNull;
        final days = nextExam?.daysUntilExam ?? 999;

        double score = 40.0;
        final reasons = <String>[];

        if (prog.whyReviseReasons.isNotEmpty) {
          reasons.addAll(prog.whyReviseReasons);
        }

        if (days <= 3 && days >= 0) {
          score += 45.0;
          reasons.add('Exam in $days ${days == 1 ? "day" : "days"}: ${nextExam!.title}');
        } else if (days <= 7 && days >= 0) {
          score += 30.0;
          reasons.add('Exam in $days days');
        } else if (days <= 14 && days >= 0) {
          score += 15.0;
          reasons.add('Exam in $days days');
        }

        if (prog.isRevisionOverdue) {
          score += 30.0;
          if (!reasons.any((r) => r.toLowerCase().contains('overdue'))) {
            reasons.add('Spaced revision overdue');
          }
        }

        if (prog.daysSinceStudied < 900 && reasons.isEmpty) {
          if (prog.daysSinceStudied >= 7) {
            score += 25.0;
            reasons.add('Last studied ${prog.daysSinceStudied} days ago');
          } else {
            score += 15.0;
            reasons.add('Last studied ${prog.daysSinceStudied} days ago — ready for recall');
          }
        }

        if (topic.importance == TopicImportance.critical) {
          score += 15.0;
          reasons.add('Critical syllabus importance');
        } else if (topic.importance == TopicImportance.high) {
          score += 8.0;
        }

        RecommendationUrgency urgency;
        if (score >= 65.0 || prog.isRevisionOverdue) {
          urgency = RecommendationUrgency.critical;
        } else if (score >= 42.0) {
          urgency = RecommendationUrgency.high;
        } else {
          urgency = RecommendationUrgency.medium;
        }

        final effectiveDays = prog.daysSinceRevised < 900 ? prog.daysSinceRevised : prog.daysSinceStudied;

        revisionItems.add(
          RevisionRecommendation(
            id: 'rev_top_${topic.id}',
            title: 'Revise ${topic.title}',
            subjectName: matchedSubj?.displayName ?? 'Curriculum',
            subjectId: topic.subjectId,
            examId: nextExam?.id,
            topicTitle: topic.title,
            topicId: topic.id,
            chapterId: topic.chapterId,
            urgency: urgency,
            reasons: reasons.isNotEmpty ? reasons : ['Spaced revision due'],
            score: score,
            daysSinceStudiedOrRevised: effectiveDays,
            isOverdue: prog.isRevisionOverdue || prog.daysSinceStudied >= 7 || (days <= 3 && days >= 0),
          ),
        );
      }
    }

    // 2. Revision from Exam Syllabus Items
    for (final exam in upcomingExams) {
      final days = exam.examDateTime != null
          ? DateTime(exam.examDateTime!.year, exam.examDateTime!.month, exam.examDateTime!.day)
              .difference(DateTime(now.year, now.month, now.day))
              .inDays
          : (exam.daysUntilExam ?? 999);
      final daysSinceStudy = daysSinceLastStudied(
        exam.subject,
        sessions,
        referenceTime: now,
      );

      for (final topic in exam.syllabusItems) {
        // Skip if already represented by a structured topic
        if (revisionItems.any((r) => r.topicTitle?.toLowerCase() == topic.title.toLowerCase())) {
          continue;
        }

        final reasons = <String>[];
        double score = 30.0;

        if (days <= 3 && days >= 0) {
          score += 45.0;
          reasons.add('Exam in $days ${days == 1 ? "day" : "days"}');
        } else if (days <= 7 && days >= 0) {
          score += 30.0;
          reasons.add('Exam in $days days');
        } else if (days <= 14 && days >= 0) {
          score += 15.0;
          reasons.add('Exam in $days days');
        }

        if (topic.completed && topic.completedAt != null) {
          final daysSinceCompleted = math.max(0, now.difference(topic.completedAt!).inDays);
          if (daysSinceCompleted >= 5) {
            score += 20.0;
            reasons.add('Completed $daysSinceCompleted days ago — ready for revision');
          } else if (daysSinceCompleted >= 2 && days <= 7) {
            score += 15.0;
            reasons.add('Exam approaching — review completed topic');
          }
        } else if (!topic.completed) {
          reasons.add('Topic not yet mastered');
          score += 10.0;
        }

        if (daysSinceStudy >= 5) {
          score += 15.0;
          reasons.add('No study in $daysSinceStudy days');
        }

        final isOverdue = days <= 3 || (topic.completed && daysSinceStudy >= 7);

        RecommendationUrgency urgency;
        if (score >= 60.0) {
          urgency = RecommendationUrgency.critical;
        } else if (score >= 40.0) {
          urgency = RecommendationUrgency.high;
        } else {
          urgency = RecommendationUrgency.medium;
        }

        revisionItems.add(
          RevisionRecommendation(
            id: 'rev_topic_${exam.id}_${topic.id}',
            title: 'Revise ${topic.title}',
            subjectName: exam.subject.isNotEmpty ? exam.subject : exam.title,
            examId: exam.id,
            topicTitle: topic.title,
            urgency: urgency,
            reasons: reasons,
            score: score,
            daysSinceStudiedOrRevised: daysSinceStudy,
            isOverdue: isOverdue,
          ),
        );
      }
    }

    // 2. Revision from Revision-Tagged Resources
    final revisionResources = resources
        .where((r) => r.isRevision || r.tags.any((t) => t.toLowerCase() == 'revision'))
        .toList();
    for (final res in revisionResources) {
      final daysSinceAccess = res.lastAccessedAt != null
          ? math.max(0, now.difference(res.lastAccessedAt!).inDays)
          : 999;

      final reasons = <String>[];
      double score = 35.0;

      if (daysSinceAccess >= 7 && daysSinceAccess < 900) {
        score += 20.0;
        reasons.add('Last reviewed $daysSinceAccess days ago');
      } else if (daysSinceAccess == 999) {
        reasons.add('Saved for revision');
      }

      if (res.examId != null) {
        final matchedExam = upcomingExams.where((e) => e.id == res.examId).firstOrNull;
        if (matchedExam != null) {
          final days = matchedExam.examDateTime != null
              ? DateTime(matchedExam.examDateTime!.year, matchedExam.examDateTime!.month, matchedExam.examDateTime!.day)
                  .difference(DateTime(now.year, now.month, now.day))
                  .inDays
              : (matchedExam.daysUntilExam ?? 999);
          if (days <= 7 && days >= 0) {
            score += 30.0;
            reasons.add('Linked to ${matchedExam.title} (in $days days)');
          }
        }
      }

      revisionItems.add(
        RevisionRecommendation(
          id: 'rev_res_${res.id}',
          title: 'Review ${res.title}',
          subjectName: res.subjectId ?? 'General',
          subjectId: res.subjectId,
          examId: res.examId,
          resourceId: res.id,
          urgency: score >= 55.0 ? RecommendationUrgency.high : RecommendationUrgency.medium,
          reasons: reasons,
          score: score,
          daysSinceStudiedOrRevised: daysSinceAccess,
          isOverdue: daysSinceAccess >= 7,
        ),
      );
    }

    revisionItems.sort((a, b) => b.score.compareTo(a.score));
    return revisionItems;
  }

  /// Generates prioritized practice recommendations based on real attempt evidence and topic curriculum.
  static List<PracticeRecommendation> generatePracticeRecommendations({
    required List<Subject> subjects,
    List<Topic>? topics,
    List<StudySession> sessions = const [],
    List<TopicPracticeAttempt> practiceAttempts = const [],
    List<StudentExam> exams = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final allTopics = topics ?? AcademicKnowledgeController.instance.topics;
    final allAttempts = practiceAttempts.isNotEmpty
        ? practiceAttempts
        : TopicPracticeController.instance.attempts;
    final recs = <PracticeRecommendation>[];

    for (final topic in allTopics) {
      final prog = AcademicKnowledgeEngine.assessTopicProgress(
        topic,
        sessions: sessions,
        practiceAttempts: allAttempts,
        referenceTime: now,
      );

      final matchedSubj = findSubjectMatch(topic.subjectId, subjects);
      final subjName = matchedSubj?.displayName ?? 'Subject';

      double score = 25.0;
      final reasons = <String>[];

      if (prog.isWeakTopic) {
        score += 35.0;
        if (prog.weakTopicReason != null) {
          reasons.add(prog.weakTopicReason!);
        } else {
          reasons.add('Identified as weak topic needing practice');
        }
      }

      if (prog.practiceAccuracyPercentage != null) {
        if (prog.practiceAccuracyPercentage! < 60) {
          score += 25.0;
          reasons.add('Low practice accuracy: ${prog.practiceAccuracyPercentage}%');
        } else if (prog.practiceAccuracyPercentage! < 75) {
          score += 15.0;
          reasons.add('Accuracy ${prog.practiceAccuracyPercentage}% — reinforcement recommended');
        }
      } else if (prog.isStudied) {
        score += 20.0;
        reasons.add('Studied but no practice questions completed yet');
      }

      if (topic.importance == TopicImportance.critical) {
        score += 15.0;
        reasons.add('Critical syllabus importance');
      } else if (topic.importance == TopicImportance.high) {
        score += 8.0;
      }

      RecommendationUrgency urgency;
      if (score >= 60.0) {
        urgency = RecommendationUrgency.critical;
      } else if (score >= 40.0) {
        urgency = RecommendationUrgency.high;
      } else if (score >= 25.0) {
        urgency = RecommendationUrgency.medium;
      } else {
        urgency = RecommendationUrgency.low;
      }

      recs.add(
        PracticeRecommendation(
          id: 'rec_prac_${topic.id}',
          title: 'Practice ${topic.title}',
          subjectName: subjName,
          subjectId: topic.subjectId,
          chapterId: topic.chapterId,
          topicTitle: topic.title,
          topicId: topic.id,
          suggestedDurationMinutes: 15,
          urgency: urgency,
          reasons: reasons.isNotEmpty ? reasons : ['Regular practice recommendation'],
          score: score,
          accuracyPercentage: prog.practiceAccuracyPercentage,
          attemptsCount: prog.practiceAttemptsCount,
          isWeak: prog.isWeakTopic,
        ),
      );
    }

    recs.sort((a, b) => b.score.compareTo(a.score));
    return recs;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. UNIFIED "WHAT SHOULD I STUDY?" RECOMMENDATION
  // ══════════════════════════════════════════════════════════════════════════

  /// Combines all academic intelligence into ONE primary recommendation with alternatives.
  static UnifiedRecommendationResult generateUnifiedRecommendation({
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<AcademicResource> resources = const [],
    List<Topic>? topics,
    DateTime? referenceTime,
  }) {
    final studyRecs = generateStudyRecommendations(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      topics: topics,
      referenceTime: referenceTime,
    );

    final revRecs = generateRevisionRecommendations(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      resources: resources,
      topics: topics,
      referenceTime: referenceTime,
    );

    final examPressures = exams
        .where((e) => e.isUpcoming)
        .map((e) => assessExamPressure(
              e,
              sessions: sessions,
              tasks: tasks,
              subjects: subjects,
              referenceTime: referenceTime,
            ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final primary = studyRecs.firstOrNull;
    final alternatives = studyRecs.length > 1 ? studyRecs.sublist(1) : <StudyRecommendation>[];

    return UnifiedRecommendationResult(
      primary: primary,
      alternatives: alternatives,
      revisionItems: revRecs,
      activeExamsWithPressure: examPressures,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. AVAILABLE-TIME AWARE ALLOCATION ENGINE
  // ══════════════════════════════════════════════════════════════════════════

  /// Distributes a given [availableMinutes] study budget across prioritized subjects
  /// and revisions with healthy breaks (e.g. 2h => 45m Subject A, 10m break, 35m Subject B, 10m break, 20m Subject C).
  static StudyTimeAllocation allocateStudyTime({
    required int availableMinutes,
    required List<Subject> subjects,
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<Topic>? topics,
    DateTime? referenceTime,
  }) {
    if (availableMinutes <= 0) {
      return const StudyTimeAllocation(
        totalAvailableMinutes: 0,
        allocatedStudyMinutes: 0,
        allocatedBreakMinutes: 0,
        blocks: [],
        summary: 'No available time specified',
      );
    }

    final studyRecs = generateStudyRecommendations(
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
      topics: topics,
      referenceTime: referenceTime,
    );

    if (studyRecs.isEmpty) {
      return StudyTimeAllocation(
        totalAvailableMinutes: availableMinutes,
        allocatedStudyMinutes: 0,
        allocatedBreakMinutes: 0,
        blocks: [],
        summary: 'No active subjects found to allocate study time.',
      );
    }

    final blocks = <StudyAllocationBlock>[];
    int totalStudy = 0;
    int totalBreak = 0;

    // Pattern 1: Short burst (<= 35 mins) -> 1 single block
    if (availableMinutes <= 35) {
      final top = studyRecs.first;
      blocks.add(
        StudyAllocationBlock(
          title: top.title,
          subjectName: top.subjectName,
          subjectId: top.subjectId,
          examId: top.exam?.id,
          topicTitle: top.topicTitle,
          topicId: top.topicId,
          chapterId: top.chapterId,
          durationMinutes: availableMinutes,
          isBreak: false,
          reason: top.primaryReason,
          type: top.type,
        ),
      );
      totalStudy = availableMinutes;
    }
    // Pattern 2: Standard hour (36 to 75 mins, e.g. 60 min) -> 1 focused block + 10m wrap-up, or 2x25m blocks
    else if (availableMinutes <= 75) {
      if (studyRecs.length == 1 || availableMinutes <= 50) {
        final top = studyRecs.first;
        final studyDur = availableMinutes <= 50 ? availableMinutes : availableMinutes - 10;
        blocks.add(
          StudyAllocationBlock(
            title: top.title,
            subjectName: top.subjectName,
            subjectId: top.subjectId,
            examId: top.exam?.id,
            topicTitle: top.topicTitle,
            topicId: top.topicId,
            chapterId: top.chapterId,
            durationMinutes: studyDur,
            isBreak: false,
            reason: top.primaryReason,
            type: top.type,
          ),
        );
        totalStudy += studyDur;

        if (availableMinutes > 50) {
          blocks.add(
            const StudyAllocationBlock(
              title: 'Break & Recall',
              subjectName: 'Break',
              durationMinutes: 10,
              isBreak: true,
              reason: 'Rest & review key takeaways',
              type: AcademicRecommendationType.studySubject,
            ),
          );
          totalBreak += 10;
        }
      } else {
        // 2 subjects: 25m Subj A, 10m break, 25m Subj B
        final first = studyRecs[0];
        final second = studyRecs[1];
        final firstDur = ((availableMinutes - 10) * 0.55).round();
        final secondDur = availableMinutes - 10 - firstDur;

        blocks.add(
          StudyAllocationBlock(
            title: first.title,
            subjectName: first.subjectName,
            subjectId: first.subjectId,
            examId: first.exam?.id,
            topicTitle: first.topicTitle,
            topicId: first.topicId,
            chapterId: first.chapterId,
            durationMinutes: firstDur,
            isBreak: false,
            reason: first.primaryReason,
            type: first.type,
          ),
        );
        totalStudy += firstDur;

        blocks.add(
          const StudyAllocationBlock(
            title: 'Break',
            subjectName: 'Break',
            durationMinutes: 10,
            isBreak: true,
            reason: 'Rest & re-energize',
            type: AcademicRecommendationType.studySubject,
          ),
        );
        totalBreak += 10;

        blocks.add(
          StudyAllocationBlock(
            title: second.title,
            subjectName: second.subjectName,
            subjectId: second.subjectId,
            examId: second.exam?.id,
            topicTitle: second.topicTitle,
            topicId: second.topicId,
            chapterId: second.chapterId,
            durationMinutes: secondDur,
            isBreak: false,
            reason: second.primaryReason,
            type: second.type,
          ),
        );
        totalStudy += secondDur;
      }
    }
    // Pattern 3: Deep study / Intensive (e.g. 120 min, 180 min)
    else {
      // Pick top 2-4 subjects based on budget
      final count = availableMinutes >= 150
          ? math.min(4, studyRecs.length)
          : math.min(3, studyRecs.length);

      final selectedRecs = studyRecs.take(count).toList();
      final totalScore = selectedRecs.fold<double>(0.0, (s, r) => s + r.score);
      final breakMinutesTotal = (count - 1) * 10;
      final netStudyMinutes = availableMinutes - breakMinutesTotal;

      int allocatedSoFar = 0;
      for (int i = 0; i < selectedRecs.length; i++) {
        final rec = selectedRecs[i];
        final proportion = totalScore > 0 ? (rec.score / totalScore) : (1.0 / selectedRecs.length);
        int blockDur = ((netStudyMinutes * proportion) / 5).round() * 5;
        blockDur = blockDur.clamp(20, 60);

        if (i == selectedRecs.length - 1) {
          final diff = netStudyMinutes - allocatedSoFar;
          if (diff >= 15) blockDur = diff;
        }

        allocatedSoFar += blockDur;
        totalStudy += blockDur;

        blocks.add(
          StudyAllocationBlock(
            title: rec.title,
            subjectName: rec.subjectName,
            subjectId: rec.subjectId,
            examId: rec.exam?.id,
            topicTitle: rec.topicTitle,
            topicId: rec.topicId,
            chapterId: rec.chapterId,
            durationMinutes: blockDur,
            isBreak: false,
            reason: rec.primaryReason,
            type: rec.type,
          ),
        );

        if (i < selectedRecs.length - 1) {
          blocks.add(
            const StudyAllocationBlock(
              title: 'Break',
              subjectName: 'Break',
              durationMinutes: 10,
              isBreak: true,
              reason: 'Rest between subjects',
              type: AcademicRecommendationType.studySubject,
            ),
          );
          totalBreak += 10;
        }
      }
    }

    final studyBlockCount = blocks.where((b) => !b.isBreak).length;
    final summary =
        '$studyBlockCount study sessions totaling ${totalStudy}m with ${totalBreak}m break in ${availableMinutes}m budget.';

    return StudyTimeAllocation(
      totalAvailableMinutes: availableMinutes,
      allocatedStudyMinutes: totalStudy,
      allocatedBreakMinutes: totalBreak,
      blocks: blocks,
      summary: summary,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. EXAM PREPARATION BREAKDOWN
  // ══════════════════════════════════════════════════════════════════════════

  /// Generates a comprehensive preparation breakdown for a specific exam.
  static ExamPreparationBreakdown getExamPreparationBreakdown(
    StudentExam exam, {
    List<StudySession> sessions = const [],
    List<StudentTask> tasks = const [],
    List<Subject> subjects = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    final pressure = assessExamPressure(
      exam,
      sessions: sessions,
      tasks: tasks,
      subjects: subjects,
      referenceTime: now,
    );

    final linkedTasks = tasks.where((t) => t.examId == exam.id).toList();

    final todayTasks = linkedTasks.where((t) {
      if (t.isCompleted) return false;
      if (t.dueDate != null) {
        final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return d == today || d.isBefore(today);
      }
      return false;
    }).toList();

    final thisWeekTasks = linkedTasks.where((t) {
      if (t.isCompleted) return false;
      if (t.dueDate != null) {
        return t.dueDate!.isAfter(today) && t.dueDate!.isBefore(weekEnd);
      }
      return true; // Scheduled in preparation
    }).toList();

    final atRisk = <String>[];
    if (pressure.daysRemaining <= 3 && pressure.syllabusRemainingCount > 0) {
      atRisk.add('${pressure.syllabusRemainingCount} syllabus topics incomplete with ${pressure.daysRemaining} days left');
    }
    if (pressure.recentStudyMinutes < 30 && pressure.daysRemaining <= 7) {
      atRisk.add('Only ${pressure.recentStudyMinutes}m study recorded this week');
    }
    final overdueLinked = linkedTasks.where((t) => t.isOverdue && !t.isCompleted).length;
    if (overdueLinked > 0) {
      atRisk.add('$overdueLinked overdue preparation task(s)');
    }

    final unrevised = exam.syllabusItems.where((s) => !s.completed).toList();

    return ExamPreparationBreakdown(
      exam: exam,
      pressure: pressure,
      todayTasks: todayTasks,
      thisWeekTasks: thisWeekTasks,
      atRiskItems: atRisk,
      unrevisedTopics: unrevised,
      recentStudyMinutes: pressure.recentStudyMinutes,
    );
  }
}
