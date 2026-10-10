import 'package:flutter/foundation.dart';

/// Supported notification event types in Student OS.
enum NotificationType {
  // Tasks
  taskDue('Task Due'),
  taskOverdue('Task Overdue'),
  taskCompleted('Task Completed'),

  // Exams
  examUpcoming('Exam Approaching'),
  examPreparation('Exam Preparation'),
  examCompleted('Exam Completed'),

  // Study & Focus
  studyCompleted('Study Completed'),
  focusCompleted('Focus Completed'),

  // Achievements & Progression
  achievementUnlocked('Achievement Unlocked'),
  levelUp('Level Up'),
  xpMilestone('XP Milestone'),

  // Streaks
  streakMilestone('Streak Milestone'),
  streakRisk('Streak at Risk'),

  // Leaderboard
  leaderboardMovement('Leaderboard Update'),

  // Rewards
  rewardUnlocked('Reward Unlocked'),
  rewardAvailable('Reward Available'),

  // Planning & Goals
  dailyPlan('Daily Plan'),
  goalReached('Goal Reached'),

  // General / Fallback
  system('System');

  const NotificationType(this.label);
  final String label;

  static NotificationType fromString(String? val) {
    if (val == null || val.isEmpty) return NotificationType.system;
    for (final t in NotificationType.values) {
      if (t.name == val) return t;
    }
    return NotificationType.system;
  }
}

/// Notification priority level.
enum NotificationPriority {
  high('High'),
  normal('Normal'),
  low('Low');

  const NotificationPriority(this.label);
  final String label;

  static NotificationPriority fromString(String? val) {
    if (val == null || val.isEmpty) return NotificationPriority.normal;
    for (final p in NotificationPriority.values) {
      if (p.name == val) return p;
    }
    return NotificationPriority.normal;
  }
}

/// User-scoped in-app notification & activity entry.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.userId,
    this.entityId,
    this.route,
    this.priority = NotificationPriority.normal,
    this.metadata,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String userId;
  final String? entityId;
  final String? route;
  final NotificationPriority priority;
  final Map<String, dynamic>? metadata;

  // ─── Helpers ────────────────────────────────────────────────────────────

  bool get isTask =>
      type == NotificationType.taskDue ||
      type == NotificationType.taskOverdue ||
      type == NotificationType.taskCompleted;

  bool get isExam =>
      type == NotificationType.examUpcoming ||
      type == NotificationType.examPreparation ||
      type == NotificationType.examCompleted;

  bool get isStudyOrFocus =>
      type == NotificationType.studyCompleted ||
      type == NotificationType.focusCompleted;

  bool get isAchievement => type == NotificationType.achievementUnlocked;

  bool get isProgression =>
      type == NotificationType.levelUp ||
      type == NotificationType.xpMilestone;

  bool get isStreak =>
      type == NotificationType.streakMilestone ||
      type == NotificationType.streakRisk;

  bool get isLeaderboard => type == NotificationType.leaderboardMovement;

  bool get isReward =>
      type == NotificationType.rewardUnlocked ||
      type == NotificationType.rewardAvailable;

  bool get isPlanOrGoal =>
      type == NotificationType.dailyPlan ||
      type == NotificationType.goalReached;

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? userId,
    String? entityId,
    String? route,
    NotificationPriority? priority,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      userId: userId ?? this.userId,
      entityId: entityId ?? this.entityId,
      route: route ?? this.route,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'userId': userId,
      if (entityId != null) 'entityId': entityId,
      if (route != null) 'route': route,
      'priority': priority.name,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      userId: json['userId'] as String? ?? 'demo',
      entityId: json['entityId'] as String?,
      route: json['route'] as String?,
      priority: NotificationPriority.fromString(json['priority'] as String?),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          body == other.body &&
          createdAt == other.createdAt &&
          isRead == other.isRead &&
          userId == other.userId &&
          entityId == other.entityId &&
          route == other.route &&
          priority == other.priority;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        title,
        body,
        createdAt,
        isRead,
        userId,
        entityId,
        route,
        priority,
      );
}
