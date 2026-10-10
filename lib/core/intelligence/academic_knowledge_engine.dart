import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import '../../data/models/academic_resource.dart';
import '../../data/models/chapter.dart';
import '../../data/models/exam.dart';
import '../../data/models/revision_queue_item.dart';
import '../../data/models/revision_record.dart';
import '../../data/models/revision_schedule.dart';
import '../../data/models/student_note.dart';
import '../../data/models/study_session.dart';
import '../../data/models/subject.dart';
import '../../data/models/topic.dart';
import '../../data/models/topic_practice_attempt.dart';
import 'academic_intelligence_engine.dart';

enum TopicKnowledgeState {
  noNotes('No Notes'),
  hasNotes('Notes Exist'),
  recentlyUpdated('Recently Updated'),
  needsReview('Needs Review');

  const TopicKnowledgeState(this.label);
  final String label;
}

@immutable
class SubjectKnowledgeCoverage {
  const SubjectKnowledgeCoverage({
    required this.subject,
    required this.notesCount,
    required this.topicsWithNotes,
    required this.topicsWithoutNotes,
    required this.coverageFraction,
    required this.recentlyUpdatedCount,
    required this.needsReviewCount,
  });

  final Subject subject;
  final int notesCount;
  final int topicsWithNotes;
  final int topicsWithoutNotes;
  final double coverageFraction;
  final int recentlyUpdatedCount;
  final int needsReviewCount;

  int get coveragePercentage => (coverageFraction * 100).round().clamp(0, 100);
}

enum SubjectHealthState {
  onTrack('On Track'),
  needsAttention('Needs Attention'),
  atRisk('At Risk');

  const SubjectHealthState(this.label);
  final String label;
}

enum AcademicPriorityLevel {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  const AcademicPriorityLevel(this.label);
  final String label;
}

@immutable
class TopicMasteryBreakdown {
  const TopicMasteryBreakdown({
    required this.learningFraction,
    required this.practiceFraction,
    required this.revisionFraction,
    required this.overallMastery,
  });

  final double learningFraction;
  final double practiceFraction;
  final double revisionFraction;
  final TopicMasteryState overallMastery;

  int get learningPercentage => (learningFraction * 100).round().clamp(0, 100);
  int get practicePercentage => (practiceFraction * 100).round().clamp(0, 100);
  int get revisionPercentage => (revisionFraction * 100).round().clamp(0, 100);
}

@immutable
class TopicProgress {
  const TopicProgress({
    required this.topic,
    required this.status,
    required this.mastery,
    required this.totalStudyMinutes,
    required this.sessionsCount,
    this.lastStudiedAt,
    required this.daysSinceStudied,
    required this.isRevisionDue,
    required this.revisionCount,
    this.practiceAttemptsCount = 0,
    this.totalPracticeMinutes = 0,
    this.lastPracticedAt,
    this.practiceAccuracyPercentage,
    this.bestAccuracyPercentage,
    this.recentAccuracyPercentage,
    this.isWeakTopic = false,
    this.weakTopicReason,
    this.lastRevisedAt,
    this.daysSinceRevised = 999,
    this.nextRevisionAt,
    this.daysUntilNextRevision,
    this.revisionIntervalDays = 1,
    this.revisionState,
    this.isRevisionOverdue = false,
    this.whyReviseReasons = const [],
    this.masteryBreakdown,
    this.recommendationReason,
  });

  final Topic topic;
  final TopicStatus status;
  final TopicMasteryState mastery;
  final int totalStudyMinutes;
  final int sessionsCount;
  final DateTime? lastStudiedAt;
  final int daysSinceStudied;
  final bool isRevisionDue;
  final int revisionCount;
  final int practiceAttemptsCount;
  final int totalPracticeMinutes;
  final DateTime? lastPracticedAt;
  final int? practiceAccuracyPercentage;
  final int? bestAccuracyPercentage;
  final int? recentAccuracyPercentage;
  final bool isWeakTopic;
  final String? weakTopicReason;
  final DateTime? lastRevisedAt;
  final int daysSinceRevised;
  final DateTime? nextRevisionAt;
  final int? daysUntilNextRevision;
  final int revisionIntervalDays;
  final RevisionState? revisionState;
  final bool isRevisionOverdue;
  final List<String> whyReviseReasons;
  final TopicMasteryBreakdown? masteryBreakdown;
  final String? recommendationReason;

  bool get isStudied =>
      status == TopicStatus.studied ||
      status == TopicStatus.needsRevision ||
      status == TopicStatus.mastered;

  String get recommendedActionLabel {
    if (status == TopicStatus.notStarted) return 'Start Learning';
    if (status == TopicStatus.inProgress) return 'Continue Learning';
    if (isRevisionDue || status == TopicStatus.needsRevision) return 'Revise Now';
    if (status == TopicStatus.mastered) return 'Practice';
    return 'Study Topic';
  }
}

@immutable
class ChapterProgress {
  const ChapterProgress({
    required this.chapter,
    required this.totalTopics,
    required this.studiedTopics,
    required this.needsRevisionTopics,
    required this.totalStudyMinutes,
    required this.completionFraction,
  });

  final Chapter chapter;
  final int totalTopics;
  final int studiedTopics;
  final int needsRevisionTopics;
  final int totalStudyMinutes;
  final double completionFraction;

  int get completionPercentage => (completionFraction * 100).round();
}

@immutable
class SubjectKnowledgeProgress {
  const SubjectKnowledgeProgress({
    required this.subject,
    required this.totalChapters,
    required this.totalTopics,
    required this.studiedTopics,
    required this.needsRevisionTopics,
    required this.totalStudyMinutes,
    required this.syllabusFraction,
    required this.revisionFraction,
    required this.health,
    required this.learningDebtCount,
    required this.chapterProgresses,
  });

  final Subject subject;
  final int totalChapters;
  final int totalTopics;
  final int studiedTopics;
  final int needsRevisionTopics;
  final int totalStudyMinutes;
  final double syllabusFraction;
  final double revisionFraction;
  final SubjectHealthState health;
  final int learningDebtCount;
  final List<ChapterProgress> chapterProgresses;

  int get syllabusPercentage => (syllabusFraction * 100).round();
  int get revisionPercentage => (revisionFraction * 100).round();
  bool get hasSyllabus => totalTopics > 0 || totalChapters > 0;
}

@immutable
class TopicPriorityAssessment {
  const TopicPriorityAssessment({
    required this.topic,
    required this.level,
    required this.score,
    required this.reasons,
    required this.isRevision,
  });

  final Topic topic;
  final AcademicPriorityLevel level;
  final double score;
  final List<String> reasons;
  final bool isRevision;

  String get primaryReason =>
      reasons.isNotEmpty ? reasons.first : 'Regular curriculum progression';
}

/// Deterministic, offline Academic Knowledge Engine.
///
/// Evaluates curriculum hierarchy (Course -> Subject -> Chapter -> Topic),
/// derives progress, priority, mastery, revision due status, and subject health
/// strictly from actual study evidence without hallucination.
abstract final class AcademicKnowledgeEngine {
  /// Evaluates progress and state for a single topic from actual study sessions and practice attempts.
  static TopicProgress assessTopicProgress(
    Topic topic, {
    List<StudySession> sessions = const [],
    List<TopicPracticeAttempt> practiceAttempts = const [],
    List<RevisionRecord> revisionRecords = const [],
    List<RevisionSchedule> revisionSchedules = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final topicSessions = sessions
        .where((s) => s.isCompleted && s.topicId == topic.id)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    int totalSec = 0;
    for (final s in topicSessions) {
      totalSec += s.durationSec;
    }
    final totalMinutes = totalSec ~/ 60;
    final sessionsCount = topicSessions.length;

    DateTime? latest = topicSessions.firstOrNull?.startedAt;
    final daysSince = latest != null
        ? math.max(0, today.difference(DateTime(latest.year, latest.month, latest.day)).inDays)
        : 999;

    // Practice aggregation
    final topicPractices = practiceAttempts
        .where((p) => p.topicId == topic.id)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final practiceCount = topicPractices.length;
    final totalPracticeSec =
        topicPractices.fold<int>(0, (sum, p) => sum + p.durationSec);
    final totalPracticeMinutes = totalPracticeSec ~/ 60;
    final lastPracticedAt = topicPractices.firstOrNull?.startedAt;

    int totalQuestions = 0;
    int totalCorrect = 0;
    int? bestAccuracy;
    int? recentAccuracy;
    for (int i = 0; i < topicPractices.length; i++) {
      final p = topicPractices[i];
      if (p.totalQuestions != null && p.totalQuestions! > 0) {
        totalQuestions += p.totalQuestions!;
        totalCorrect += (p.correctAnswers ?? 0);
      }
      final acc = p.accuracyPercentage;
      if (acc != null) {
        if (recentAccuracy == null && i == 0) {
          recentAccuracy = acc;
        }
        if (bestAccuracy == null || acc > bestAccuracy) {
          bestAccuracy = acc;
        }
      }
    }
    final int? practiceAccuracy = totalQuestions > 0
        ? ((totalCorrect / totalQuestions) * 100).round().clamp(0, 100)
        : null;

    bool isWeakTopic = false;
    String? weakReason;
    if (practiceCount > 0 && practiceAccuracy != null && practiceAccuracy < 65) {
      isWeakTopic = true;
      weakReason = 'Practice accuracy is $practiceAccuracy% (target: 70%+)';
    } else if (practiceCount >= 2 && recentAccuracy != null && bestAccuracy != null && recentAccuracy < bestAccuracy - 15) {
      isWeakTopic = true;
      weakReason = 'Recent practice accuracy fell to $recentAccuracy% (best: $bestAccuracy%)';
    } else if (sessionsCount > 0 && practiceCount == 0 && daysSince >= 5 && daysSince < 900) {
      isWeakTopic = true;
      weakReason = 'Studied $daysSince days ago with no practice recorded yet';
    }

    // Revision records & schedule aggregation
    final topicRevisions = revisionRecords
        .where((r) => r.topicId == topic.id)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final topicSchedule = revisionSchedules
        .where((s) => s.topicId == topic.id)
        .firstOrNull;

    int revisionCount = topicRevisions.isNotEmpty
        ? topicRevisions.length
        : (topicSessions.length > 1
            ? math.max(0, topicSessions.map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day)).toSet().length - 1)
            : 0);

    final lastRevisedAt = topicRevisions.firstOrNull?.completedAt ?? topicSchedule?.lastRevisionAt;
    final int daysSinceRevised = lastRevisedAt != null
        ? math.max(0, today.difference(DateTime(lastRevisedAt.year, lastRevisedAt.month, lastRevisedAt.day)).inDays)
        : 999;

    final nextRevisionAt = topicSchedule?.nextRevisionAt;
    final int? daysUntilNextRevision = nextRevisionAt != null
        ? DateTime(nextRevisionAt.year, nextRevisionAt.month, nextRevisionAt.day).difference(today).inDays
        : null;

    final int revisionIntervalDays = topicSchedule?.intervalDays ??
        (revisionCount == 0 ? 3 : (revisionCount == 1 ? 7 : (revisionCount == 2 ? 14 : 30)));

    // Determine TopicStatus
    TopicStatus status;
    if (sessionsCount == 0 && totalMinutes == 0 && revisionCount == 0 && practiceCount == 0) {
      status = TopicStatus.notStarted;
    } else if (totalMinutes < 15 && sessionsCount == 1 && revisionCount == 0) {
      status = TopicStatus.inProgress;
    } else if (topicSchedule?.isDue == true || daysSince >= 4 || (daysSinceRevised >= revisionIntervalDays && daysSinceRevised < 900)) {
      status = TopicStatus.needsRevision;
    } else if (revisionCount >= 2 && totalMinutes >= 45) {
      status = TopicStatus.mastered;
    } else {
      status = TopicStatus.studied;
    }

    // Determine TopicMasteryState
    TopicMasteryState mastery;
    if (sessionsCount == 0 && totalMinutes == 0 && revisionCount == 0 && practiceCount == 0) {
      mastery = TopicMasteryState.notStarted;
    } else if (totalMinutes < 20 && revisionCount == 0 && practiceCount == 0) {
      mastery = TopicMasteryState.learning;
    } else if (totalMinutes >= 20 && (revisionCount >= 1 || totalMinutes >= 30)) {
      if (revisionCount >= 2 && totalMinutes >= 60 && (daysSince <= 7 || daysSinceRevised <= 7)) {
        mastery = TopicMasteryState.strong;
      } else {
        mastery = TopicMasteryState.familiar;
      }
    } else {
      mastery = TopicMasteryState.learning;
    }

    final isRevisionDue = topicSchedule != null
        ? topicSchedule.isDue
        : ((status == TopicStatus.needsRevision) || (sessionsCount > 0 && daysSince >= 4));

    final isRevisionOverdue = topicSchedule != null
        ? topicSchedule.isOverdue
        : (sessionsCount > 0 && daysSince >= 7 && daysSince < 900);

    // Mastery fractions for 3-bar visual breakdown
    final targetMins = math.max(20, topic.estimatedMinutes);
    final learningFraction = (totalMinutes / targetMins).clamp(0.0, 1.0);
    final practiceFraction = (practiceCount / 3.0).clamp(0.0, 1.0);
    final revisionFraction = isRevisionDue
        ? 0.35
        : (revisionCount >= 2
            ? 1.0
            : (revisionCount == 1 ? 0.75 : (sessionsCount > 0 ? 0.5 : 0.0)));

    final breakdown = TopicMasteryBreakdown(
      learningFraction: learningFraction,
      practiceFraction: practiceFraction,
      revisionFraction: revisionFraction,
      overallMastery: mastery,
    );

    // Deterministic explainable reason
    String recommendationReason;
    final whyReasons = <String>[];

    if (daysSinceRevised < 900) {
      whyReasons.add('Last revised $daysSinceRevised days ago (interval: ${revisionIntervalDays}d)');
    } else if (daysSince < 900 && sessionsCount > 0) {
      whyReasons.add('Last studied $daysSince days ago');
    }
    if (isWeakTopic && weakReason != null) {
      whyReasons.add(weakReason);
    }
    if (practiceAccuracy != null) {
      whyReasons.add('Practice accuracy: $practiceAccuracy%');
    }

    if (status == TopicStatus.notStarted) {
      recommendationReason = 'Not yet studied. Recommended starting duration is ${topic.estimatedMinutes}m.';
    } else if (status == TopicStatus.inProgress) {
      recommendationReason = 'In progress with ${totalMinutes}m studied. Continue to build concept mastery.';
    } else if (isRevisionDue) {
      if (daysSinceRevised < 900) {
        recommendationReason = 'Revision is due (last revised $daysSinceRevised days ago).';
      } else if (daysSince < 900) {
        recommendationReason = 'Revision is due because you last studied this $daysSince days ago.';
      } else {
        recommendationReason = 'Revision is due to reinforce recall.';
      }
    } else if (status == TopicStatus.mastered) {
      recommendationReason = 'Mastered! Great opportunity for practice questions or spaced maintenance.';
    } else {
      recommendationReason = 'Studied recently — retention is strong.';
    }

    return TopicProgress(
      topic: topic,
      status: status,
      mastery: mastery,
      totalStudyMinutes: totalMinutes,
      sessionsCount: sessionsCount,
      lastStudiedAt: latest,
      daysSinceStudied: daysSince,
      isRevisionDue: isRevisionDue,
      revisionCount: revisionCount,
      practiceAttemptsCount: practiceCount,
      totalPracticeMinutes: totalPracticeMinutes,
      lastPracticedAt: lastPracticedAt,
      practiceAccuracyPercentage: practiceAccuracy,
      bestAccuracyPercentage: bestAccuracy,
      recentAccuracyPercentage: recentAccuracy,
      isWeakTopic: isWeakTopic,
      weakTopicReason: weakReason,
      lastRevisedAt: lastRevisedAt,
      daysSinceRevised: daysSinceRevised,
      nextRevisionAt: nextRevisionAt,
      daysUntilNextRevision: daysUntilNextRevision,
      revisionIntervalDays: revisionIntervalDays,
      revisionState: topicSchedule?.state,
      isRevisionOverdue: isRevisionOverdue,
      whyReviseReasons: whyReasons,
      masteryBreakdown: breakdown,
      recommendationReason: recommendationReason,
    );
  }

  /// Evaluates progress for a chapter based on its topics.
  static ChapterProgress assessChapterProgress(
    Chapter chapter,
    List<Topic> topics, {
    List<StudySession> sessions = const [],
    DateTime? referenceTime,
  }) {
    final chapterTopics = topics.where((t) => t.chapterId == chapter.id).toList();

    if (chapterTopics.isEmpty) {
      final chSessions = sessions.where((s) => s.isCompleted && s.chapterId == chapter.id);
      final chMins = chSessions.fold<int>(0, (sum, s) => sum + s.durationSec) ~/ 60;
      return ChapterProgress(
        chapter: chapter,
        totalTopics: 0,
        studiedTopics: 0,
        needsRevisionTopics: 0,
        totalStudyMinutes: chMins,
        completionFraction: 0.0,
      );
    }

    int studied = 0;
    int needsRevision = 0;
    int totalMins = 0;

    for (final topic in chapterTopics) {
      final prog = assessTopicProgress(topic, sessions: sessions, referenceTime: referenceTime);
      if (prog.isStudied) {
        studied++;
      }
      if (prog.isRevisionDue) {
        needsRevision++;
      }
      totalMins += prog.totalStudyMinutes;
    }

    final fraction = (studied / chapterTopics.length).clamp(0.0, 1.0);

    return ChapterProgress(
      chapter: chapter,
      totalTopics: chapterTopics.length,
      studiedTopics: studied,
      needsRevisionTopics: needsRevision,
      totalStudyMinutes: totalMins,
      completionFraction: fraction,
    );
  }

  /// Evaluates comprehensive subject knowledge progress.
  static SubjectKnowledgeProgress assessSubjectProgress(
    Subject subject, {
    List<Chapter> chapters = const [],
    List<Topic> topics = const [],
    List<StudySession> sessions = const [],
    List<StudentExam> exams = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final subjectChapters = chapters.where((c) => c.subjectId == subject.id).toList();
    final subjectTopics = topics.where((t) => t.subjectId == subject.id).toList();

    final chapterProgresses = subjectChapters.map((ch) {
      return assessChapterProgress(
        ch,
        subjectTopics,
        sessions: sessions,
        referenceTime: now,
      );
    }).toList();

    int totalMins = 0;
    for (final s in sessions) {
      if (!s.isCompleted) continue;
      if (s.subjectId == subject.id ||
          s.subject.trim().toLowerCase() == subject.name.trim().toLowerCase() ||
          s.subject.trim().toLowerCase() == subject.displayName.trim().toLowerCase()) {
        totalMins += s.durationSec;
      }
    }
    final totalStudyMinutes = totalMins ~/ 60;

    if (subjectTopics.isEmpty) {
      // No topics defined: graceful fallback
      final upcomingExams = exams.where((e) =>
          e.isUpcoming &&
          (e.subject.trim().toLowerCase() == subject.name.trim().toLowerCase() ||
           e.subject.trim().toLowerCase() == subject.displayName.trim().toLowerCase())).toList();

      final nextExam = upcomingExams.firstOrNull;
      final daysToExam = nextExam?.daysUntilExam ?? 999;

      SubjectHealthState health;
      if (daysToExam <= 3 && totalStudyMinutes < 30) {
        health = SubjectHealthState.atRisk;
      } else if (daysToExam <= 7 && totalStudyMinutes < 60) {
        health = SubjectHealthState.needsAttention;
      } else {
        health = SubjectHealthState.onTrack;
      }

      return SubjectKnowledgeProgress(
        subject: subject,
        totalChapters: subjectChapters.length,
        totalTopics: 0,
        studiedTopics: 0,
        needsRevisionTopics: 0,
        totalStudyMinutes: totalStudyMinutes,
        syllabusFraction: 0.0,
        revisionFraction: 1.0,
        health: health,
        learningDebtCount: 0,
        chapterProgresses: chapterProgresses,
      );
    }

    int studiedTopics = 0;
    int needsRevisionTopics = 0;

    for (final topic in subjectTopics) {
      final prog = assessTopicProgress(topic, sessions: sessions, referenceTime: now);
      if (prog.isStudied) {
        studiedTopics++;
      }
      if (prog.isRevisionDue) {
        needsRevisionTopics++;
      }
    }

    final syllabusFraction = (studiedTopics / subjectTopics.length).clamp(0.0, 1.0);
    final revisionFraction = studiedTopics > 0
        ? ((studiedTopics - needsRevisionTopics) / studiedTopics).clamp(0.0, 1.0)
        : 1.0;

    final unstudiedCount = subjectTopics.length - studiedTopics;
    final learningDebt = unstudiedCount + needsRevisionTopics;

    // Exam proximity check
    final upcomingExams = exams.where((e) =>
        e.isUpcoming &&
        (e.subject.trim().toLowerCase() == subject.name.trim().toLowerCase() ||
         e.subject.trim().toLowerCase() == subject.displayName.trim().toLowerCase())).toList()
      ..sort((a, b) => (a.daysUntilExam ?? 999).compareTo(b.daysUntilExam ?? 999));

    final nextExam = upcomingExams.firstOrNull;
    final daysToExam = nextExam?.daysUntilExam ?? 999;

    SubjectHealthState health;
    if (daysToExam <= 5 && (unstudiedCount > 0 || needsRevisionTopics > 0)) {
      health = SubjectHealthState.atRisk;
    } else if (daysToExam <= 10 && (unstudiedCount > 2 || needsRevisionTopics > 2)) {
      health = SubjectHealthState.needsAttention;
    } else if (unstudiedCount > 0 && totalStudyMinutes == 0) {
      health = SubjectHealthState.needsAttention;
    } else {
      health = SubjectHealthState.onTrack;
    }

    return SubjectKnowledgeProgress(
      subject: subject,
      totalChapters: subjectChapters.length,
      totalTopics: subjectTopics.length,
      studiedTopics: studiedTopics,
      needsRevisionTopics: needsRevisionTopics,
      totalStudyMinutes: totalStudyMinutes,
      syllabusFraction: syllabusFraction,
      revisionFraction: revisionFraction,
      health: health,
      learningDebtCount: learningDebt,
      chapterProgresses: chapterProgresses,
    );
  }

  /// Calculates deterministic priority score and explanation for a topic.
  static TopicPriorityAssessment assessTopicPriority(
    Topic topic, {
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    SubjectPreference preference = SubjectPreference.normal,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final progress = assessTopicProgress(topic, sessions: sessions, referenceTime: now);

    double score = 30.0;
    final reasons = <String>[];

    // 1. Importance multiplier
    score *= topic.importance.weightMultiplier;
    if (topic.importance == TopicImportance.critical) {
      reasons.add('Critical syllabus importance');
    } else if (topic.importance == TopicImportance.high) {
      reasons.add('High importance topic');
    }

    // 2. Preference multiplier
    score *= preference.weightMultiplier;

    // 3. Exam proximity
    final subjectExams = exams.where((e) => e.isUpcoming).toList();
    StudentExam? matchedExam;
    for (final e in subjectExams) {
      if (e.subject.trim().toLowerCase() == topic.subjectId.toLowerCase()) {
        matchedExam = e;
        break;
      }
    }

    if (matchedExam != null && matchedExam.daysUntilExam != null) {
      final days = matchedExam.daysUntilExam!;
      if (days <= 2) {
        score += 50.0;
        reasons.add('Exam in $days ${days == 1 ? "day" : "days"}: ${matchedExam.title}');
      } else if (days <= 5) {
        score += 35.0;
        reasons.add('Exam in $days days: ${matchedExam.title}');
      } else if (days <= 10) {
        score += 20.0;
        reasons.add('Exam in $days days');
      }
    }

    // 4. Topic Completion / Revision Status
    final isRevision = progress.isRevisionDue;
    if (progress.status == TopicStatus.notStarted) {
      score += 25.0;
      reasons.add('Not yet studied');
    } else if (progress.status == TopicStatus.inProgress) {
      score += 20.0;
      reasons.add('Study in progress (${progress.totalStudyMinutes}m recorded)');
    } else if (progress.status == TopicStatus.needsRevision) {
      score += 30.0;
      if (progress.daysSinceStudied < 900) {
        reasons.add('Revision due (last studied ${progress.daysSinceStudied} days ago)');
      } else {
        reasons.add('Revision due');
      }
    } else if (progress.status == TopicStatus.mastered) {
      score -= 15.0;
    }

    AcademicPriorityLevel level;
    if (score >= 65.0) {
      level = AcademicPriorityLevel.critical;
    } else if (score >= 42.0) {
      level = AcademicPriorityLevel.high;
    } else if (score >= 25.0) {
      level = AcademicPriorityLevel.medium;
    } else {
      level = AcademicPriorityLevel.low;
    }

    if (reasons.isEmpty) {
      reasons.add('Curriculum topic ready for study');
    }

    return TopicPriorityAssessment(
      topic: topic,
      level: level,
      score: score,
      reasons: reasons,
      isRevision: isRevision,
    );
  }

  /// Selects unstudied or in-progress topics for a subject.
  static List<Topic> remainingTopics(
    String subjectId, {
    required List<Topic> topics,
    List<StudySession> sessions = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    return topics
        .where((t) => t.subjectId == subjectId)
        .where((t) {
          final p = assessTopicProgress(t, sessions: sessions, referenceTime: now);
          return p.status == TopicStatus.notStarted || p.status == TopicStatus.inProgress;
        })
        .toList();
  }

  /// Selects topics studied previously but neglected (>7 days without study/revision).
  static List<Topic> neglectedTopics(
    String subjectId, {
    required List<Topic> topics,
    List<StudySession> sessions = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    return topics
        .where((t) => t.subjectId == subjectId)
        .where((t) {
          final p = assessTopicProgress(t, sessions: sessions, referenceTime: now);
          return p.isStudied && p.daysSinceStudied >= 7 && p.daysSinceStudied < 900;
        })
        .toList();
  }

  /// Returns the top topics that need immediate attention or revision for a subject.
  static List<TopicProgress> getNeedsAttentionTopics(
    String subjectId, {
    required List<Topic> topics,
    List<StudySession> sessions = const [],
    List<TopicPracticeAttempt> practiceAttempts = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final subjectTopics = topics.where((t) => t.subjectId == subjectId).toList();
    final list = <TopicProgress>[];

    for (final t in subjectTopics) {
      final prog = assessTopicProgress(
        t,
        sessions: sessions,
        practiceAttempts: practiceAttempts,
        referenceTime: now,
      );
      if (prog.isRevisionDue ||
          prog.status == TopicStatus.inProgress ||
          (prog.daysSinceStudied >= 5 && prog.daysSinceStudied < 900)) {
        list.add(prog);
      }
    }

    list.sort((a, b) {
      if (a.isRevisionDue != b.isRevisionDue) {
        return a.isRevisionDue ? -1 : 1;
      }
      return b.daysSinceStudied.compareTo(a.daysSinceStudied);
    });

    return list;
  }

  /// Finds the next best recommended topic to learn or revise for a subject.
  static Topic? getRecommendedTopicForSubject(
    Subject subject, {
    required List<Chapter> chapters,
    required List<Topic> topics,
    List<StudySession> sessions = const [],
    List<StudentExam> exams = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final subjectTopics = topics.where((t) => t.subjectId == subject.id).toList();
    if (subjectTopics.isEmpty) return null;

    final assessments = subjectTopics.map((t) {
      return assessTopicPriority(
        t,
        exams: exams,
        sessions: sessions,
        preference: subject.preference,
        referenceTime: now,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return assessments.firstOrNull?.topic;
  }

  /// Finds the next best recommended topic to learn or revise within a chapter.
  static Topic? getRecommendedTopicForChapter(
    Chapter chapter, {
    required List<Topic> topics,
    List<StudySession> sessions = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final chapterTopics = topics.where((t) => t.chapterId == chapter.id).toList();
    if (chapterTopics.isEmpty) return null;

    // 1. Revision due in this chapter
    for (final t in chapterTopics) {
      final p = assessTopicProgress(t, sessions: sessions, referenceTime: now);
      if (p.isRevisionDue) return t;
    }

    // 2. In progress topic in this chapter
    for (final t in chapterTopics) {
      final p = assessTopicProgress(t, sessions: sessions, referenceTime: now);
      if (p.status == TopicStatus.inProgress) return t;
    }

    // 3. First not started topic in this chapter
    for (final t in chapterTopics) {
      final p = assessTopicProgress(t, sessions: sessions, referenceTime: now);
      if (p.status == TopicStatus.notStarted) return t;
    }

    return chapterTopics.firstOrNull;
  }

  /// Identifies all topics exhibiting weak retention or low practice accuracy.
  static List<TopicProgress> getWeakTopics({
    required List<Topic> topics,
    List<StudySession> sessions = const [],
    List<TopicPracticeAttempt> practiceAttempts = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final list = <TopicProgress>[];

    for (final t in topics) {
      final prog = assessTopicProgress(
        t,
        sessions: sessions,
        practiceAttempts: practiceAttempts,
        referenceTime: now,
      );
      if (prog.isWeakTopic) {
        list.add(prog);
      }
    }

    list.sort((a, b) {
      final accA = a.practiceAccuracyPercentage ?? 999;
      final accB = b.practiceAccuracyPercentage ?? 999;
      if (accA != accB) {
        return accA.compareTo(accB);
      }
      return b.daysSinceStudied.compareTo(a.daysSinceStudied);
    });

    return list;
  }

  /// Prioritizes topics needing active practice (weakest or unpracticed studied topics first).
  static List<TopicProgress> getRecommendedPracticeTopics({
    required List<Topic> topics,
    List<StudySession> sessions = const [],
    List<TopicPracticeAttempt> practiceAttempts = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final list = <TopicProgress>[];

    for (final t in topics) {
      final prog = assessTopicProgress(
        t,
        sessions: sessions,
        practiceAttempts: practiceAttempts,
        referenceTime: now,
      );
      if (prog.isStudied || prog.practiceAttemptsCount > 0) {
        list.add(prog);
      }
    }

    list.sort((a, b) {
      if (a.isWeakTopic != b.isWeakTopic) {
        return a.isWeakTopic ? -1 : 1;
      }
      final accA = a.practiceAccuracyPercentage ?? -1;
      final accB = b.practiceAccuracyPercentage ?? -1;
      if (accA != accB) {
        return accA.compareTo(accB);
      }
      return b.daysSinceStudied.compareTo(a.daysSinceStudied);
    });

    return list;
  }

  /// Derives or updates a deterministic [RevisionSchedule] for a topic from all available academic evidence.
  static RevisionSchedule deriveOrUpdateSchedule(
    Topic topic, {
    List<StudySession> sessions = const [],
    List<RevisionRecord> records = const [],
    List<TopicPracticeAttempt> practiceAttempts = const [],
    List<StudentExam> exams = const [],
    RevisionSchedule? existingSchedule,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final prog = assessTopicProgress(
      topic,
      sessions: sessions,
      practiceAttempts: practiceAttempts,
      revisionRecords: records,
      referenceTime: now,
    );

    final topicRecords = records
        .where((r) => r.topicId == topic.id)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final lastRev = topicRecords.firstOrNull?.completedAt ?? existingSchedule?.lastRevisionAt;
    final revCount = topicRecords.isNotEmpty ? topicRecords.length : (existingSchedule?.revisionCount ?? prog.revisionCount);

    int successes = existingSchedule?.successfulRecallCount ?? 0;
    int fails = existingSchedule?.failedRecallCount ?? 0;
    if (existingSchedule == null && topicRecords.isNotEmpty) {
      for (final r in topicRecords) {
        if (r.isSuccessfulRecall) {
          successes++;
        } else if (r.recallOutcome == RevisionRecallOutcome.forgot) {
          fails++;
        }
      }
    }

    double ease = existingSchedule?.easeFactor ?? 2.5;
    int interval;
    if (existingSchedule != null) {
      interval = existingSchedule.intervalDays;
    } else {
      if (revCount == 0) {
        interval = 3;
      } else if (revCount == 1) {
        interval = 7;
      } else if (revCount == 2) {
        interval = 14;
      } else {
        interval = 30;
      }
    }

    // Check practice influence
    final acc = prog.practiceAccuracyPercentage;
    if (acc != null) {
      if (acc < 60) {
        interval = 1;
        ease = math.max(1.3, ease - 0.2);
      } else if (acc >= 85 && interval == 1 && revCount > 0) {
        interval = 3;
      }
    }

    DateTime nextRev;
    if (lastRev != null) {
      nextRev = DateTime(lastRev.year, lastRev.month, lastRev.day).add(Duration(days: interval));
    } else if (prog.lastStudiedAt != null) {
      nextRev = DateTime(prog.lastStudiedAt!.year, prog.lastStudiedAt!.month, prog.lastStudiedAt!.day).add(Duration(days: interval));
    } else {
      nextRev = today.add(Duration(days: interval));
    }

    final nextRevDay = DateTime(nextRev.year, nextRev.month, nextRev.day);
    final daysUntil = nextRevDay.difference(today).inDays;

    RevisionState state;
    if (prog.status == TopicStatus.notStarted && revCount == 0) {
      state = RevisionState.notReady;
    } else if (daysUntil < 0) {
      state = RevisionState.overdue;
    } else if (daysUntil == 0) {
      state = RevisionState.due;
    } else if (revCount == 0) {
      state = RevisionState.newTopic;
    } else if (revCount < 2 || prog.isWeakTopic) {
      state = RevisionState.learning;
    } else if (revCount >= 3 && acc != null && acc >= 80) {
      state = RevisionState.strong;
    } else if (revCount >= 2) {
      state = RevisionState.stable;
    } else {
      state = RevisionState.learning;
    }

    // Exam proximity influence
    StudentExam? matchedExam;
    for (final e in exams.where((e) => e.isUpcoming)) {
      if (e.subject.trim().toLowerCase() == topic.subjectId.toLowerCase() ||
          e.id == topic.subjectId) {
        matchedExam = e;
        break;
      }
    }

    int? daysRemaining;
    if (matchedExam != null) {
      if (matchedExam.examDateTime != null) {
        daysRemaining = DateTime(
          matchedExam.examDateTime!.year,
          matchedExam.examDateTime!.month,
          matchedExam.examDateTime!.day,
        ).difference(today).inDays;
      } else {
        daysRemaining = matchedExam.daysUntilExam;
      }
    }

    double priorityScore = 20.0;
    final reasons = <String>[];

    if (state == RevisionState.overdue) {
      priorityScore += 50.0 + math.min(30.0, (-daysUntil) * 5.0);
      reasons.add('Overdue by ${-daysUntil} day(s)');
    } else if (state == RevisionState.due) {
      priorityScore += 35.0;
      reasons.add('Spaced repetition due today');
    }

    if (prog.isWeakTopic) {
      priorityScore += 30.0;
      if (prog.weakTopicReason != null) reasons.add(prog.weakTopicReason!);
    }

    if (daysRemaining != null) {
      final d = daysRemaining;
      if (d <= 3 && d >= 0) {
        priorityScore += 45.0;
        reasons.add('Exam in $d day(s): ${matchedExam!.title}');
      } else if (d <= 7 && d >= 0) {
        priorityScore += 25.0;
        reasons.add('Exam in $d days');
      }
    }

    if (topic.importance == TopicImportance.critical) {
      priorityScore += 15.0;
      reasons.add('Critical syllabus importance');
    }

    return (existingSchedule ?? RevisionSchedule(
      id: 'rev_sched_${topic.id}',
      userId: topic.userId,
      topicId: topic.id,
      chapterId: topic.chapterId,
      subjectId: topic.subjectId,
      examId: matchedExam?.id,
    )).copyWith(
      state: state,
      intervalDays: interval,
      lastRevisionAt: lastRev,
      nextRevisionAt: nextRev,
      revisionCount: revCount,
      successfulRecallCount: successes,
      failedRecallCount: fails,
      easeFactor: ease,
      priorityScore: priorityScore,
      priorityReasons: reasons.isNotEmpty ? reasons : ['Regular spaced learning review'],
      suggestedDurationMinutes: math.max(15, (topic.estimatedMinutes * 0.5).round()),
    );
  }

  /// Builds the complete prioritized Adaptive Revision Queue.
  static List<RevisionQueueItem> buildRevisionQueue({
    required List<Topic> topics,
    List<AcademicResource> resources = const [],
    List<Subject> subjects = const [],
    List<Chapter> chapters = const [],
    List<StudentExam> exams = const [],
    List<StudySession> sessions = const [],
    List<RevisionRecord> records = const [],
    List<RevisionSchedule> schedules = const [],
    List<TopicPracticeAttempt> practiceAttempts = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = <RevisionQueueItem>[];

    // 1. Process Curriculum Topics
    for (final topic in topics) {
      final prog = assessTopicProgress(
        topic,
        sessions: sessions,
        practiceAttempts: practiceAttempts,
        revisionRecords: records,
        revisionSchedules: schedules,
        referenceTime: now,
      );

      if (prog.sessionsCount == 0 && !prog.isStudied && prog.revisionCount == 0 && prog.practiceAttemptsCount == 0) {
        continue; // Unstudied topic without any revision or practice is not in active revision queue
      }

      final existingSched = schedules.where((s) => s.topicId == topic.id).firstOrNull;
      final schedule = deriveOrUpdateSchedule(
        topic,
        sessions: sessions,
        records: records,
        practiceAttempts: practiceAttempts,
        exams: exams,
        existingSchedule: existingSched,
        referenceTime: now,
      );

      final matchedSubj = subjects.where((s) => s.id == topic.subjectId).firstOrNull;
      final matchedCh = chapters.where((c) => c.id == topic.chapterId).firstOrNull;
      final matchedExam = exams.where((e) => e.isUpcoming && e.subject.toLowerCase() == topic.subjectId.toLowerCase()).firstOrNull;

      final daysUntil = schedule.nextRevisionAt != null
          ? DateTime(schedule.nextRevisionAt!.year, schedule.nextRevisionAt!.month, schedule.nextRevisionAt!.day).difference(today).inDays
          : 0;

      RevisionDueCategory category;
      if (schedule.state == RevisionState.overdue || daysUntil < 0) {
        category = RevisionDueCategory.overdue;
      } else if (schedule.state == RevisionState.due || daysUntil == 0) {
        category = RevisionDueCategory.dueToday;
      } else if (prog.isWeakTopic) {
        category = RevisionDueCategory.needsAttention;
      } else if (daysUntil <= 3) {
        category = RevisionDueCategory.upcoming;
      } else {
        category = RevisionDueCategory.stableStrong;
      }

      RecommendationUrgency urgency;
      if (schedule.priorityScore >= 70) {
        urgency = RecommendationUrgency.critical;
      } else if (schedule.priorityScore >= 45) {
        urgency = RecommendationUrgency.high;
      } else if (schedule.priorityScore >= 25) {
        urgency = RecommendationUrgency.medium;
      } else {
        urgency = RecommendationUrgency.low;
      }

      items.add(
        RevisionQueueItem(
          topic: topic,
          subject: matchedSubj,
          chapter: matchedCh,
          exam: matchedExam,
          schedule: schedule,
          state: schedule.state,
          dueCategory: category,
          priorityScore: schedule.priorityScore,
          urgency: urgency,
          title: topic.title,
          subjectName: matchedSubj?.displayName ?? 'Curriculum',
          reasons: schedule.priorityReasons,
          suggestedDurationMinutes: schedule.suggestedDurationMinutes,
          daysSinceLastRevision: prog.daysSinceRevised,
          daysUntilNextRevision: daysUntil,
          practiceAccuracy: prog.practiceAccuracyPercentage,
          isWeak: prog.isWeakTopic,
        ),
      );
    }

    // 2. Process Revision-Tagged Resources
    final revResources = resources.where((r) => r.isRevision || r.tags.any((t) => t.toLowerCase() == 'revision')).toList();
    for (final res in revResources) {
      if (items.any((i) => i.title.toLowerCase() == res.title.toLowerCase())) {
        continue; // Deduplicate
      }

      final matchedSubj = subjects.where((s) => s.id == res.subjectId).firstOrNull;
      final daysSinceAccess = res.lastAccessedAt != null
          ? math.max(0, today.difference(DateTime(res.lastAccessedAt!.year, res.lastAccessedAt!.month, res.lastAccessedAt!.day)).inDays)
          : 999;

      final isDue = daysSinceAccess >= 5;
      final reasons = <String>[];
      if (daysSinceAccess < 900) {
        reasons.add('Last reviewed $daysSinceAccess days ago');
      } else {
        reasons.add('Saved revision resource');
      }

      final sched = RevisionSchedule(
        id: 'rev_res_${res.id}',
        topicId: res.id,
        subjectId: res.subjectId,
        examId: res.examId,
        state: isDue ? RevisionState.due : RevisionState.learning,
        intervalDays: 7,
        priorityScore: isDue ? 40.0 : 20.0,
        priorityReasons: reasons,
        suggestedDurationMinutes: 15,
      );

      items.add(
        RevisionQueueItem(
          resource: res,
          subject: matchedSubj,
          schedule: sched,
          state: sched.state,
          dueCategory: isDue ? RevisionDueCategory.dueToday : RevisionDueCategory.upcoming,
          priorityScore: sched.priorityScore,
          urgency: isDue ? RecommendationUrgency.medium : RecommendationUrgency.low,
          title: res.title,
          subjectName: matchedSubj?.displayName ?? 'Resource',
          reasons: reasons,
          suggestedDurationMinutes: 15,
          daysSinceLastRevision: daysSinceAccess,
          daysUntilNextRevision: isDue ? 0 : 7,
        ),
      );
    }

    // 3. Sort deterministically
    items.sort((a, b) {
      if (a.isOverdue != b.isOverdue) {
        return a.isOverdue ? -1 : 1;
      }
      if (a.isDueNow != b.isDueNow) {
        return a.isDueNow ? -1 : 1;
      }
      final cmp = b.priorityScore.compareTo(a.priorityScore);
      if (cmp != 0) return cmp;
      return a.daysUntilNextRevision.compareTo(b.daysUntilNextRevision);
    });

    return items;
  }

  /// Generates a bulleted, student-friendly explanation of why a topic requires revision.
  static List<String> generateWhyReviseExplanation(
    Topic topic, {
    List<StudySession> sessions = const [],
    List<RevisionRecord> records = const [],
    List<TopicPracticeAttempt> practiceAttempts = const [],
    List<StudentExam> exams = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final prog = assessTopicProgress(
      topic,
      sessions: sessions,
      practiceAttempts: practiceAttempts,
      revisionRecords: records,
      referenceTime: now,
    );

    final reasons = <String>[];

    if (prog.isWeakTopic && prog.weakTopicReason != null) {
      reasons.add(prog.weakTopicReason!);
    }

    if (prog.daysSinceRevised < 900) {
      reasons.add('Last revised ${prog.daysSinceRevised} days ago (scheduled interval: ${prog.revisionIntervalDays}d)');
    } else if (prog.daysSinceStudied < 900) {
      reasons.add('Last studied ${prog.daysSinceStudied} days ago with no revision yet');
    }

    if (prog.practiceAccuracyPercentage != null) {
      if (prog.practiceAccuracyPercentage! < 65) {
        reasons.add('Practice accuracy is ${prog.practiceAccuracyPercentage}% (target: 70%+)');
      } else {
        reasons.add('Recent practice accuracy: ${prog.practiceAccuracyPercentage}%');
      }
    }

    for (final e in exams.where((e) => e.isUpcoming)) {
      if ((e.subject.trim().toLowerCase() == topic.subjectId.toLowerCase() || e.id == topic.subjectId)) {
        int? d;
        if (e.examDateTime != null) {
          d = DateTime(e.examDateTime!.year, e.examDateTime!.month, e.examDateTime!.day).difference(today).inDays;
        } else {
          d = e.daysUntilExam;
        }
        if (d != null && d <= 7 && d >= 0) {
          reasons.add('Upcoming exam in $d ${d == 1 ? "day" : "days"}: ${e.title}');
        }
      }
    }

    if (topic.importance == TopicImportance.critical) {
      reasons.add('Critical syllabus topic with high exam weighting');
    }

    if (reasons.isEmpty) {
      reasons.add('Spaced repetition maintenance to prevent forgetting curve decay');
    }

    return reasons;
  }

  /// Assesses the personal note/knowledge signal for a topic.
  /// Note: These are knowledge signals, NOT mastery.
  static TopicKnowledgeState assessTopicKnowledgeState(
    Topic topic, {
    List<StudentNote> notes = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final topicNotes = notes
        .where((n) => n.isActive && n.topicId == topic.id)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (topicNotes.isEmpty) {
      return TopicKnowledgeState.noNotes;
    }

    final latest = topicNotes.first;
    final latestDay = DateTime(latest.updatedAt.year, latest.updatedAt.month, latest.updatedAt.day);
    final daysSinceUpdate = today.difference(latestDay).inDays;

    if (daysSinceUpdate <= 2) {
      return TopicKnowledgeState.recentlyUpdated;
    } else if (daysSinceUpdate >= 14) {
      return TopicKnowledgeState.needsReview;
    } else {
      return TopicKnowledgeState.hasNotes;
    }
  }

  /// Evaluates personal knowledge coverage for a subject across its topics.
  /// Clearly distinguished from Mastery.
  static SubjectKnowledgeCoverage assessSubjectKnowledgeCoverage(
    Subject subject, {
    List<Topic> topics = const [],
    List<StudentNote> notes = const [],
    DateTime? referenceTime,
  }) {
    final subjectTopics = topics.where((t) => t.subjectId == subject.id).toList();
    final subjectNotes = notes.where((n) => n.isActive && n.subjectId == subject.id).toList();

    if (subjectTopics.isEmpty) {
      return SubjectKnowledgeCoverage(
        subject: subject,
        notesCount: subjectNotes.length,
        topicsWithNotes: 0,
        topicsWithoutNotes: 0,
        coverageFraction: subjectNotes.isNotEmpty ? 1.0 : 0.0,
        recentlyUpdatedCount: 0,
        needsReviewCount: 0,
      );
    }

    final coveredTopicIds = subjectNotes
        .where((n) => n.hasTopic)
        .map((n) => n.topicId!)
        .toSet();

    final topicsWith = subjectTopics.where((t) => coveredTopicIds.contains(t.id)).length;
    final topicsWithout = subjectTopics.length - topicsWith;
    final fraction = (topicsWith / subjectTopics.length).clamp(0.0, 1.0);

    int recentCount = 0;
    int reviewCount = 0;

    for (final topic in subjectTopics) {
      final state = assessTopicKnowledgeState(
        topic,
        notes: subjectNotes,
        referenceTime: referenceTime,
      );
      if (state == TopicKnowledgeState.recentlyUpdated) {
        recentCount++;
      } else if (state == TopicKnowledgeState.needsReview) {
        reviewCount++;
      }
    }

    return SubjectKnowledgeCoverage(
      subject: subject,
      notesCount: subjectNotes.length,
      topicsWithNotes: topicsWith,
      topicsWithoutNotes: topicsWithout,
      coverageFraction: fraction,
      recentlyUpdatedCount: recentCount,
      needsReviewCount: reviewCount,
    );
  }
}
