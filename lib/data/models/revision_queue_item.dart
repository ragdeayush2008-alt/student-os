import 'package:flutter/foundation.dart';

import '../../core/intelligence/academic_intelligence_engine.dart';
import 'academic_resource.dart';
import 'chapter.dart';
import 'exam.dart';
import 'revision_schedule.dart';
import 'subject.dart';
import 'topic.dart';

/// A prioritized item inside the unified Adaptive Revision Queue.
@immutable
class RevisionQueueItem {
  const RevisionQueueItem({
    this.topic,
    this.resource,
    this.subject,
    this.chapter,
    this.exam,
    required this.schedule,
    required this.state,
    required this.dueCategory,
    required this.priorityScore,
    required this.urgency,
    required this.title,
    required this.subjectName,
    required this.reasons,
    required this.suggestedDurationMinutes,
    required this.daysSinceLastRevision,
    required this.daysUntilNextRevision,
    this.practiceAccuracy,
    this.isWeak = false,
  });

  final Topic? topic;
  final AcademicResource? resource;
  final Subject? subject;
  final Chapter? chapter;
  final StudentExam? exam;
  final RevisionSchedule schedule;
  final RevisionState state;
  final RevisionDueCategory dueCategory;
  final double priorityScore;
  final RecommendationUrgency urgency;
  final String title;
  final String subjectName;
  final List<String> reasons;
  final int suggestedDurationMinutes;
  final int daysSinceLastRevision;
  final int daysUntilNextRevision;
  final int? practiceAccuracy;
  final bool isWeak;

  String get primaryReason =>
      reasons.isNotEmpty ? reasons.first : 'Scheduled spaced revision';

  bool get isOverdue => dueCategory == RevisionDueCategory.overdue;
  bool get isDueNow =>
      dueCategory == RevisionDueCategory.dueNow ||
      dueCategory == RevisionDueCategory.overdue ||
      dueCategory == RevisionDueCategory.dueToday;

  String? get topicId => topic?.id ?? schedule.topicId;
  String? get subjectId => subject?.id ?? schedule.subjectId;
  String? get chapterId => chapter?.id ?? schedule.chapterId;
  String? get examId => exam?.id ?? schedule.examId;
}
