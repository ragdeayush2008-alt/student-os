import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/app_notification.dart';
import 'package:student_os/features/notifications/notification_controller.dart';
import 'package:student_os/features/preferences/user_preferences_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_student');
    NotificationController.instance.clearData();
    await UserPreferencesController.instance.load();
  });

  group('NotificationController Unit Tests', () {
    test('initial state is empty and unreadCount is 0', () {
      final controller = NotificationController.instance;
      expect(controller.notifications, isEmpty);
      expect(controller.unreadCount, 0);
      expect(controller.hasUnread, isFalse);
      expect(controller.selectedFilter, NotificationFilter.all);
    });

    test('addNotification adds notification and marks unread', () async {
      final controller = NotificationController.instance;
      final notif = AppNotification(
        id: 'n_1',
        type: NotificationType.taskCompleted,
        title: 'Task Done',
        body: 'You finished a task',
        createdAt: DateTime.now(),
        userId: 'test_student',
      );

      final added = await controller.addNotification(notif);
      expect(added, isTrue);
      expect(controller.notifications.length, 1);
      expect(controller.unreadCount, 1);
      expect(controller.hasUnread, isTrue);
      expect(controller.notifications.first.id, 'n_1');
    });

    test('addNotification deduplicates by id (idempotency)', () async {
      final controller = NotificationController.instance;
      final notif = AppNotification(
        id: 'n_same_id',
        type: NotificationType.achievementUnlocked,
        title: 'Achievement',
        body: 'Earned badge',
        createdAt: DateTime.now(),
        userId: 'test_student',
      );

      final firstAdd = await controller.addNotification(notif);
      final secondAdd = await controller.addNotification(notif);

      expect(firstAdd, isTrue);
      expect(secondAdd, isFalse);
      expect(controller.notifications.length, 1);
    });

    test('markAsRead updates isRead state and decreases unreadCount', () async {
      final controller = NotificationController.instance;
      final notif = AppNotification(
        id: 'n_read_test',
        type: NotificationType.levelUp,
        title: 'Level Up',
        body: 'Reached Level 2',
        createdAt: DateTime.now(),
        userId: 'test_student',
      );

      await controller.addNotification(notif);
      expect(controller.unreadCount, 1);

      await controller.markAsRead('n_read_test');
      expect(controller.unreadCount, 0);
      expect(controller.hasUnread, isFalse);
      expect(controller.notifications.first.isRead, isTrue);
    });

    test('markAllAsRead marks all unread items as read', () async {
      final controller = NotificationController.instance;
      for (var i = 1; i <= 3; i++) {
        await controller.addNotification(
          AppNotification(
            id: 'n_multi_$i',
            type: NotificationType.taskCompleted,
            title: 'Task $i',
            body: 'Done',
            createdAt: DateTime.now(),
            userId: 'test_student',
          ),
        );
      }

      expect(controller.unreadCount, 3);

      await controller.markAllAsRead();
      expect(controller.unreadCount, 0);
      expect(controller.notifications.every((n) => n.isRead), isTrue);
    });

    test('deleteNotification removes specific item', () async {
      final controller = NotificationController.instance;
      await controller.addNotification(
        AppNotification(
          id: 'n_del_1',
          type: NotificationType.taskCompleted,
          title: 'T1',
          body: 'B',
          createdAt: DateTime.now(),
          userId: 'test_student',
        ),
      );
      await controller.addNotification(
        AppNotification(
          id: 'n_del_2',
          type: NotificationType.taskCompleted,
          title: 'T2',
          body: 'B',
          createdAt: DateTime.now(),
          userId: 'test_student',
        ),
      );

      expect(controller.notifications.length, 2);
      await controller.deleteNotification('n_del_1');
      expect(controller.notifications.length, 1);
      expect(controller.notifications.first.id, 'n_del_2');
    });

    test('clearAllNotifications clears all items', () async {
      final controller = NotificationController.instance;
      await controller.addNotification(
        AppNotification(
          id: 'n_c1',
          type: NotificationType.taskCompleted,
          title: 'T1',
          body: 'B',
          createdAt: DateTime.now(),
          userId: 'test_student',
        ),
      );

      await controller.clearAllNotifications();
      expect(controller.notifications, isEmpty);
      expect(controller.unreadCount, 0);
    });

    test('filters return appropriate items', () async {
      final controller = NotificationController.instance;
      final now = DateTime.now();

      await controller.addNotification(
        AppNotification(
          id: 'f_task',
          type: NotificationType.taskCompleted,
          title: 'Task',
          body: 'B',
          createdAt: now,
          userId: 'test_student',
        ),
      );
      await controller.addNotification(
        AppNotification(
          id: 'f_exam',
          type: NotificationType.examUpcoming,
          title: 'Exam',
          body: 'B',
          createdAt: now,
          userId: 'test_student',
        ),
      );
      await controller.addNotification(
        AppNotification(
          id: 'f_focus',
          type: NotificationType.focusCompleted,
          title: 'Focus',
          body: 'B',
          createdAt: now,
          userId: 'test_student',
        ),
      );
      await controller.addNotification(
        AppNotification(
          id: 'f_ach',
          type: NotificationType.achievementUnlocked,
          title: 'Ach',
          body: 'B',
          createdAt: now,
          userId: 'test_student',
        ),
      );

      controller.setFilter(NotificationFilter.all);
      expect(controller.filteredNotifications.length, 4);

      controller.setFilter(NotificationFilter.tasks);
      expect(controller.filteredNotifications.length, 1);
      expect(controller.filteredNotifications.first.id, 'f_task');

      controller.setFilter(NotificationFilter.exams);
      expect(controller.filteredNotifications.length, 1);
      expect(controller.filteredNotifications.first.id, 'f_exam');

      controller.setFilter(NotificationFilter.focus);
      expect(controller.filteredNotifications.length, 1);
      expect(controller.filteredNotifications.first.id, 'f_focus');

      controller.setFilter(NotificationFilter.progression);
      expect(controller.filteredNotifications.length, 1);
      expect(controller.filteredNotifications.first.id, 'f_ach');
    });

    test('respects disabled category preferences', () async {
      final controller = NotificationController.instance;
      final prefs = UserPreferencesController.instance;

      await prefs.setNotificationCategoryEnabled(category: 'tasks', enabled: false);

      final taskNotif = AppNotification(
        id: 'task_rejected',
        type: NotificationType.taskCompleted,
        title: 'Task',
        body: 'B',
        createdAt: DateTime.now(),
        userId: 'test_student',
      );

      final added = await controller.addNotification(taskNotif);
      expect(added, isFalse);
      expect(controller.notifications, isEmpty);
    });
  });
}
