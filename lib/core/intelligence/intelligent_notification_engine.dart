import 'package:meta/meta.dart';

/// Intelligent notification prioritization and category model.
/// Deterministic, explainable, respects user preferences.
enum NotificationCategory {
  examApproaching('Exam'),
  preparationGap('Preparation'),
  todayPlan('Plan'),
  overdueTask('Task'),
  studySession('Study'),
  revisionDue('Revision'),
  progressSummary('Progress'),
  rewardMilestone('Milestone');

  const NotificationCategory(this.label);
  final String label;
}

/// Prioritization level — only high-value notifications fire.
enum NotificationPriority { low, medium, high, critical }

@immutable
class IntelligentNotification {
  final NotificationCategory category;
  final NotificationPriority priority;
  final String title;
  final String message;
  final String? navigationRoute;
  final String? entityId;
  final bool isActionable;
  final DateTime createdAt;

  const IntelligentNotification({
    required this.category,
    required this.priority,
    required this.title,
    required this.message,
    this.navigationRoute,
    this.entityId,
    this.isActionable = false,
    required this.createdAt,
  });

  String get deterministicId =>
      '${category.name}_${entityId ?? 'none'}_${createdAt.millisecondsSinceEpoch}';
}

/// Factory for intelligent notifications using real app data.
class IntelligentNotificationEngine {
  const IntelligentNotificationEngine();

  List<IntelligentNotification> generateNotifications({
    required int daysUntilExam,
    required bool hasPreparationGap,
    required bool hasOverdueTask,
    required bool hasTodayPlan,
    required int consistencyScore,
    required bool hasRecentStudy,
  }) {
    final notifications = <IntelligentNotification>[];
    final now = DateTime.now();

    if (daysUntilExam <= 3 && hasPreparationGap) {
      notifications.add(
        IntelligentNotification(
          category: NotificationCategory.examApproaching,
          priority: NotificationPriority.critical,
          title: 'Exam approaching',
          message:
              'Your exam is in $daysUntilExam days and preparation is incomplete.',
          navigationRoute: '/exam-detail',
          isActionable: true,
          createdAt: now,
        ),
      );
    }

    if (hasPreparationGap && daysUntilExam <= 7) {
      notifications.add(
        IntelligentNotification(
          category: NotificationCategory.preparationGap,
          priority: NotificationPriority.high,
          title: 'Preparation needed',
          message: 'Some syllabus topics remain unfinished.',
          navigationRoute: '/exam-detail',
          isActionable: true,
          createdAt: now,
        ),
      );
    }

    if (hasOverdueTask) {
      notifications.add(
        IntelligentNotification(
          category: NotificationCategory.overdueTask,
          priority: NotificationPriority.high,
          title: 'Overdue task',
          message: 'You have an overdue task that needs attention.',
          navigationRoute: '/tasks',
          isActionable: true,
          createdAt: now,
        ),
      );
    }

    if (hasTodayPlan && !hasRecentStudy) {
      notifications.add(
        IntelligentNotification(
          category: NotificationCategory.todayPlan,
          priority: NotificationPriority.medium,
          title: "Today's plan ready",
          message: 'Your daily study plan is ready.',
          navigationRoute: '/plan',
          isActionable: true,
          createdAt: now,
        ),
      );
    }

    if (consistencyScore < 0.5 && hasRecentStudy) {
      notifications.add(
        IntelligentNotification(
          category: NotificationCategory.progressSummary,
          priority: NotificationPriority.low,
          title: 'Consistency update',
          message: 'Your study consistency is lower than usual.',
          navigationRoute: '/analytics',
          isActionable: false,
          createdAt: now,
        ),
      );
    }

    return notifications;
  }
}
