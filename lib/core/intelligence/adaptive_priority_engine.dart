import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import 'academic_context.dart';

import 'package:meta/meta.dart';

/// Type of recommended academic action.
enum AcademicActionType {
  completeTask('Complete Task'),
  examPreparation('Exam Preparation'),
  studySession('Study Session'),
  syllabusRevision('Syllabus Revision'),
  backlogRecovery('Backlog Recovery');

  const AcademicActionType(this.label);
  final String label;
}

/// A prioritized, explainable academic action.
@immutable
class PrioritizedAction {
  const PrioritizedAction({
    required this.id,
    required this.title,
    required this.reason,
    required this.estimatedMinutes,
    required this.type,
    required this.priorityScore,
    this.taskId,
    this.examId,
    this.subjectId,
    this.subjectName,
    this.topicTitle,
  });

  final String id;
  final String title;
  final String reason;
  final int estimatedMinutes;
  final AcademicActionType type;
  final double priorityScore; // Higher score = higher priority
  final String? taskId;
  final String? examId;
  final String? subjectId;
  final String? subjectName;
  final String? topicTitle;
}

/// Explainable, deterministic priority scoring engine.
class AdaptivePriorityEngine {
  const AdaptivePriorityEngine();

  /// Ranks all potential academic actions from highest to lowest priority.
  List<PrioritizedAction> derivePrioritizedActions(AcademicContext context) {
    final actions = <PrioritizedAction>[];

    // 1. Overdue and Urgent Tasks
    for (final task in context.overdueTasks) {
      double score = 100.0;
      if (task.priority == TaskPriority.critical) score += 40;
      if (task.priority == TaskPriority.high) score += 25;
      if (task.examId != null) score += 30;

      actions.add(
        PrioritizedAction(
          id: 'task_${task.id}',
          title: task.title,
          reason: 'Overdue task with high academic priority',
          estimatedMinutes: 25,
          type: AcademicActionType.completeTask,
          priorityScore: score,
          taskId: task.id,
          subjectId: task.subjectId,
          examId: task.examId,
        ),
      );
    }

    // 2. High-Pressure / Approaching Exam Preparation
    for (final summary in context.examSummaries) {
      final exam = summary.exam;
      final days = summary.daysRemaining;

      double score = 50.0;
      if (days <= 3) {
        score += 80.0;
      } else if (days <= 7) {
        score += 50.0;
      } else if (days <= 14) {
        score += 25.0;
      }

      if (summary.syllabusCompletionPercent < 0.50) score += 35.0;
      if (summary.state == ExamReadinessState.critical) score += 40.0;

      // Unfinished syllabus topic suggestion
      String? nextTopic;
      for (final item in exam.syllabusItems) {
        if (!item.completed) {
          nextTopic = item.title;
          break;
        }
      }

      final title = nextTopic != null
          ? 'Revise $nextTopic (${exam.title})'
          : 'Review Syllabus for ${exam.title}';

      actions.add(
        PrioritizedAction(
          id: 'exam_${exam.id}',
          title: title,
          reason: summary.explanation,
          estimatedMinutes: 35,
          type: AcademicActionType.examPreparation,
          priorityScore: score,
          examId: exam.id,
          subjectName: exam.subject,
          topicTitle: nextTopic,
        ),
      );
    }

    // 3. Neglected Subject Study Session
    for (final health in context.subjectHealths) {
      if (context.neglectedSubjectIds.contains(health.subject.id)) {
        actions.add(
          PrioritizedAction(
            id: 'neglected_${health.subject.id}',
            title: 'Study ${health.subject.name}',
            reason:
                'Subject has not been studied in ${health.daysSinceLastStudied} days',
            estimatedMinutes: 30,
            type: AcademicActionType.studySession,
            priorityScore: 65.0,
            subjectId: health.subject.id,
            subjectName: health.subject.name,
          ),
        );
      }
    }

    // 4. Today Tasks
    for (final task in context.todayTasks) {
      if (context.overdueTasks.any((t) => t.id == task.id)) continue;

      double score = 40.0;
      if (task.priority == TaskPriority.critical) score += 30;
      if (task.priority == TaskPriority.high) score += 20;

      actions.add(
        PrioritizedAction(
          id: 'today_task_${task.id}',
          title: task.title,
          reason: 'Scheduled due today',
          estimatedMinutes: 25,
          type: AcademicActionType.completeTask,
          priorityScore: score,
          taskId: task.id,
          subjectId: task.subjectId,
          examId: task.examId,
        ),
      );
    }

    // Sort descending by priority score
    actions.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return actions;
  }
}
