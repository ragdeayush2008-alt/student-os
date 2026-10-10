import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/notification_service.dart';
import 'package:student_os/data/models/app_notification.dart';

void main() {
  group('AppNotification Model & Serialization', () {
    test('creates with standard fields and defaults', () {
      final now = DateTime(2026, 9, 10, 10, 30);
      final notif = AppNotification(
        id: 'test_1',
        type: NotificationType.taskCompleted,
        title: 'Task Completed',
        body: 'Great job completing your task!',
        createdAt: now,
        userId: 'user_123',
        entityId: 'task_abc',
        route: '/tasks',
        priority: NotificationPriority.normal,
        metadata: {'score': 100},
      );

      expect(notif.id, 'test_1');
      expect(notif.type, NotificationType.taskCompleted);
      expect(notif.title, 'Task Completed');
      expect(notif.body, 'Great job completing your task!');
      expect(notif.createdAt, now);
      expect(notif.isRead, isFalse);
      expect(notif.userId, 'user_123');
      expect(notif.entityId, 'task_abc');
      expect(notif.route, '/tasks');
      expect(notif.priority, NotificationPriority.normal);
      expect(notif.metadata?['score'], 100);
      expect(notif.isTask, isTrue);
      expect(notif.isExam, isFalse);
      expect(notif.isStudyOrFocus, isFalse);
      expect(notif.isAchievement, isFalse);
    });

    test('toJson and fromJson roundtrip preserves all fields', () {
      final now = DateTime(2026, 9, 10, 10, 30);
      final original = AppNotification(
        id: 'notif_exam_1',
        type: NotificationType.examUpcoming,
        title: 'Exam in 3 days',
        body: 'Physics exam is approaching.',
        createdAt: now,
        isRead: true,
        userId: 'student_42',
        entityId: 'exam_99',
        route: '/exams',
        priority: NotificationPriority.high,
        metadata: {'daysUntil': 3},
      );

      final json = original.toJson();
      final restored = AppNotification.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.createdAt, original.createdAt);
      expect(restored.isRead, original.isRead);
      expect(restored.userId, original.userId);
      expect(restored.entityId, original.entityId);
      expect(restored.route, original.route);
      expect(restored.priority, original.priority);
      expect(restored.metadata, original.metadata);
      expect(restored, equals(original));
    });

    test('fromJson handles fallback defaults on missing or corrupted fields', () {
      final corruptedJson = <String, dynamic>{
        'type': 'non_existent_type',
        'priority': 'unknown_priority',
      };

      final parsed = AppNotification.fromJson(corruptedJson);

      expect(parsed.type, NotificationType.system);
      expect(parsed.priority, NotificationPriority.normal);
      expect(parsed.isRead, isFalse);
      expect(parsed.userId, 'demo');
      expect(parsed.id, isNotEmpty);
    });

    test('copyWith works correctly', () {
      final notif = AppNotification(
        id: 'n1',
        type: NotificationType.achievementUnlocked,
        title: 'Badge Earned',
        body: 'Unlocked Night Owl',
        createdAt: DateTime.now(),
        userId: 'u1',
      );

      final readNotif = notif.copyWith(isRead: true);
      expect(readNotif.isRead, isTrue);
      expect(readNotif.id, notif.id);
      expect(readNotif.title, notif.title);
      expect(notif.isRead, isFalse);
    });

    test('type helpers identify categories correctly', () {
      final now = DateTime.now();

      final task = AppNotification(
        id: '1',
        type: NotificationType.taskDue,
        title: 'T',
        body: 'B',
        createdAt: now,
        userId: 'u',
      );
      expect(task.isTask, isTrue);

      final exam = AppNotification(
        id: '2',
        type: NotificationType.examPreparation,
        title: 'E',
        body: 'B',
        createdAt: now,
        userId: 'u',
      );
      expect(exam.isExam, isTrue);

      final focus = AppNotification(
        id: '3',
        type: NotificationType.focusCompleted,
        title: 'F',
        body: 'B',
        createdAt: now,
        userId: 'u',
      );
      expect(focus.isStudyOrFocus, isTrue);

      final ach = AppNotification(
        id: '4',
        type: NotificationType.achievementUnlocked,
        title: 'A',
        body: 'B',
        createdAt: now,
        userId: 'u',
      );
      expect(ach.isAchievement, isTrue);

      final lvl = AppNotification(
        id: '5',
        type: NotificationType.levelUp,
        title: 'L',
        body: 'B',
        createdAt: now,
        userId: 'u',
      );
      expect(lvl.isProgression, isTrue);

      final streak = AppNotification(
        id: '6',
        type: NotificationType.streakMilestone,
        title: 'S',
        body: 'B',
        createdAt: now,
        userId: 'u',
      );
      expect(streak.isStreak, isTrue);

      final lboard = AppNotification(
        id: '7',
        type: NotificationType.leaderboardMovement,
        title: 'LB',
        body: 'B',
        createdAt: now,
        userId: 'u',
      );
      expect(lboard.isLeaderboard, isTrue);

      final reward = AppNotification(
        id: '8',
        type: NotificationType.rewardUnlocked,
        title: 'R',
        body: 'B',
        createdAt: now,
        userId: 'u',
      );
      expect(reward.isReward, isTrue);

      final plan = AppNotification(
        id: '9',
        type: NotificationType.dailyPlan,
        title: 'P',
        body: 'B',
        createdAt: now,
        userId: 'u',
      );
      expect(plan.isPlanOrGoal, isTrue);
    });
  });

  group('Deterministic NotificationIds String Keys', () {
    test('produces stable string keys for same inputs', () {
      expect(
        NotificationIds.taskCompletedKey('task_101'),
        'task_completed_task_101',
      );
      expect(
        NotificationIds.taskDueKey('task_101', '2026-9-10'),
        'task_due_task_101_2026-9-10',
      );
      expect(
        NotificationIds.taskOverdueKey('task_101', '2026-9-10'),
        'task_overdue_task_101_2026-9-10',
      );
      expect(
        NotificationIds.examUpcomingKey('exam_5', 3),
        'exam_upcoming_exam_5_3d',
      );
      expect(
        NotificationIds.achievementUnlockedKey('first_task'),
        'achievement_unlocked_first_task',
      );
      expect(
        NotificationIds.levelUpKey(5),
        'level_up_5',
      );
      expect(
        NotificationIds.streakMilestoneKey(7),
        'streak_milestone_7',
      );
      expect(
        NotificationIds.leaderboardMovementKey('thisWeek', 3, '2026-9-10'),
        'leaderboard_move_thisWeek_3_2026-9-10',
      );
    });
  });
}
