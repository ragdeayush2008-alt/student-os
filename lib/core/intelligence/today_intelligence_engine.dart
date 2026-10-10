import 'package:flutter/material.dart';

import '../../data/models/academic_resource.dart';
import '../../data/models/task.dart';
import '../../features/resources/resource_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/exams/exam_controller.dart';
import 'student_snapshot.dart';

/// Focus urgency level derived from real student data.
enum FocusUrgency {
  critical('Critical', Color(0xFF1F5C44), Icons.priority_high_rounded),
  high('High Priority', Color(0xFF285C4D), Icons.arrow_upward_rounded),
  medium('Attention', Color(0xFF7A8450), Icons.remove_rounded),
  low('Optional', Color(0xFF6F967F), Icons.arrow_downward_rounded);

  const FocusUrgency(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

/// A deterministic, explainable item representing something the student
/// should care about right now.
@immutable
class FocusItem {
  const FocusItem({
    required this.id,
    required this.title,
    required this.reason,
    required this.urgency,
    required this.icon,
    this.taskId,
    this.examId,
    this.resourceId,
    this.subjectId,
    this.actionLabel,
  });

  final String id;
  final String title;
  final String reason;
  final FocusUrgency urgency;
  final IconData icon;
  final String? taskId;
  final String? examId;
  final String? resourceId;
  final String? subjectId;
  final String? actionLabel;
}

/// Deterministic, explainable intelligence engine for Student OS.
///
/// Answers:
/// - What is urgent?
/// - What is overdue?
/// - What exam is approaching?
/// - Which subject requires attention?
/// - What task should be prioritized?
/// - What learning material is relevant?
///
/// All outputs are derived from real stored data. No fake AI scores or arbitrary
/// rankings. Every item includes a transparent reason.
class TodayIntelligenceEngine {
  const TodayIntelligenceEngine();

  /// Derives an academic status summary string.
  String deriveDailyStatus(StudentSnapshot snapshot) {
    if (snapshot.overdueTasks.isNotEmpty) {
      return 'You have overdue tasks that need attention.';
    }
    if (snapshot.hasUpcomingExams) {
      final nextExam = snapshot.nextExam!;
      final days = nextExam.daysUntilExam;
      if (days != null && days <= 3) {
        return 'Exam pressure is rising for ${nextExam.subject}.';
      }
    }
    if (snapshot.todayTasks.isNotEmpty) {
      return 'You have ${snapshot.todayTasks.length} high-priority actions today.';
    }
    return 'Your day is under control.';
  }

  /// Derives the top 1–3 focus items for the student right now.
  List<FocusItem> deriveFocusItems(StudentSnapshot snapshot) {
    final items = <FocusItem>[];

    // 1. Overdue tasks are highest priority
    if (snapshot.hasOverdueTasks) {
      final overdue = snapshot.overdueTasks.first;
      items.add(
        FocusItem(
          id: 'overdue_${overdue.id}',
          title: overdue.title,
          reason: 'Overdue since ${_formatDate(overdue.dueDate)}',
          urgency: FocusUrgency.critical,
          icon: Icons.warning_amber_rounded,
          taskId: overdue.id,
          actionLabel: 'Complete task',
        ),
      );
    }

    // 2. Urgent upcoming exams (within 3 days)
    if (snapshot.hasUpcomingExams) {
      final nextExam = snapshot.nextExam!;
      final days = nextExam.daysUntilExam;
      if (days != null && days <= 3 && !nextExam.isCompleted) {
        final readiness = ExamController.instance.readiness(nextExam);
        final reason = days == 0
            ? 'Exam is today!'
            : days == 1
            ? 'Exam is tomorrow!'
            : 'Exam in $days days (${readiness.label})';

        items.add(
          FocusItem(
            id: 'exam_${nextExam.id}',
            title: nextExam.title,
            reason: reason,
            urgency: days <= 1 ? FocusUrgency.critical : FocusUrgency.high,
            icon: Icons.school_rounded,
            examId: nextExam.id,
            actionLabel: 'View exam',
          ),
        );
      }
    }

    // 3. High-priority or critical tasks due today
    final criticalToday = snapshot.todayTasks
        .where(
          (t) =>
              !t.isCompleted &&
              (t.priority == TaskPriority.critical ||
                  t.priority == TaskPriority.high),
        )
        .toList();

    if (criticalToday.isNotEmpty && items.length < 3) {
      final topTask = criticalToday.first;
      items.add(
        FocusItem(
          id: 'task_${topTask.id}',
          title: topTask.title,
          reason: '${topTask.priority.label} priority task scheduled for today',
          urgency: topTask.priority == TaskPriority.critical
              ? FocusUrgency.high
              : FocusUrgency.medium,
          icon: Icons.assignment_late_outlined,
          taskId: topTask.id,
          actionLabel: 'Work on task',
        ),
      );
    }

    // 4. Relevant study recommendation if we still have space
    if (items.length < 3 && snapshot.hasUpcomingExams) {
      final nextExam = snapshot.nextExam!;
      final linkedTasks = TaskController.instance.tasksForExam(nextExam.id);
      final remainingTasks = linkedTasks.where((t) => !t.isCompleted).length;

      if (remainingTasks > 0) {
        items.add(
          FocusItem(
            id: 'prep_${nextExam.id}',
            title: 'Prepare for ${nextExam.title}',
            reason:
                '$remainingTasks preparation task${remainingTasks > 1 ? "s" : ""} remaining',
            urgency: FocusUrgency.medium,
            icon: Icons.checklist_rounded,
            examId: nextExam.id,
            actionLabel: 'Open preparation',
          ),
        );
      }
    }

    // 5. If no other items, show today's remaining tasks
    if (items.isEmpty && snapshot.hasTodayTasks) {
      final remaining = snapshot.todayTasks
          .where((t) => !t.isCompleted)
          .toList();
      if (remaining.isNotEmpty) {
        final task = remaining.first;
        items.add(
          FocusItem(
            id: 'today_${task.id}',
            title: task.title,
            reason: 'Scheduled for today',
            urgency: FocusUrgency.low,
            icon: Icons.check_circle_outline_rounded,
            taskId: task.id,
            actionLabel: 'Complete task',
          ),
        );
      }
    }

    return items.take(3).toList();
  }

  /// Intelligently selects relevant resources to continue learning.
  List<SmartResourceRecommendation> deriveSmartResources(
    StudentSnapshot snapshot,
  ) {
    final rc = ResourceController.instance;
    final results = <SmartResourceRecommendation>[];
    final seenIds = <String>{};

    // 1. Resources linked to the next upcoming exam
    if (snapshot.hasUpcomingExams) {
      final nextExam = snapshot.nextExam!;
      final examResources = rc.resourcesForExam(nextExam.id);
      for (final res in examResources) {
        if (seenIds.add(res.id)) {
          final days = nextExam.daysUntilExam;
          final timeContext = days == null
              ? ''
              : days == 0
              ? 'today'
              : days == 1
              ? 'tomorrow'
              : 'in $days days';
          results.add(
            SmartResourceRecommendation(
              resource: res,
              reason: 'Linked to ${nextExam.title} ($timeContext)',
              priority: 1,
            ),
          );
        }
      }
    }

    // 2. Resources linked to subjects with today's tasks
    final todaySubjectIds = snapshot.todayTasks
        .where((t) => t.subjectId != null && !t.isCompleted)
        .map((t) => t.subjectId!)
        .toSet();

    for (final subId in todaySubjectIds) {
      final subResources = rc.resourcesForSubject(subId);
      for (final res in subResources) {
        if (seenIds.add(res.id)) {
          results.add(
            SmartResourceRecommendation(
              resource: res,
              reason: 'Matches a subject with tasks due today',
              priority: 2,
            ),
          );
        }
      }
    }

    // 3. Recently accessed resources (last opened)
    for (final res in snapshot.recentResources) {
      if (seenIds.add(res.id)) {
        results.add(
          SmartResourceRecommendation(
            resource: res,
            reason: 'Recently opened material',
            priority: 3,
          ),
        );
      }
    }

    // 4. Favorite resources
    for (final res in snapshot.favoriteResources) {
      if (seenIds.add(res.id)) {
        results.add(
          SmartResourceRecommendation(
            resource: res,
            reason: 'Starred resource',
            priority: 4,
          ),
        );
      }
    }

    // Sort by priority (lower number = higher priority)
    results.sort((a, b) => a.priority.compareTo(b.priority));

    return results.take(5).toList();
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff > 1) return '$diff days ago';
    return '${date.day}/${date.month}';
  }
}

/// A resource recommendation paired with an explainable reason.
@immutable
class SmartResourceRecommendation {
  const SmartResourceRecommendation({
    required this.resource,
    required this.reason,
    required this.priority,
  });

  final AcademicResource resource;
  final String reason;
  final int priority;
}
