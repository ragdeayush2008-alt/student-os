import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/app_notification.dart';
import 'package:student_os/features/notifications/notification_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Notification User Isolation & Persistence Regression', () {
    test('User A notifications are never visible to User B', () async {
      // 1. User A logs in and receives notifications
      AuthIsolation.instance.setAuthenticatedUser('user_alpha');
      NotificationController.instance.clearData();
      await NotificationController.instance.load();

      await NotificationController.instance.addNotification(
        AppNotification(
          id: 'alpha_task_done',
          type: NotificationType.taskCompleted,
          title: 'Alpha Task',
          body: 'Alpha completed work',
          createdAt: DateTime.now(),
          userId: 'user_alpha',
        ),
      );

      expect(NotificationController.instance.notifications.length, 1);
      expect(
        NotificationController.instance.notifications.first.userId,
        'user_alpha',
      );

      // 2. User A logs out -> ControllerIsolation clears all controllers
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();

      expect(NotificationController.instance.notifications, isEmpty);
      expect(NotificationController.instance.unreadCount, 0);

      // 3. User B logs in -> Reload controllers for User B
      AuthIsolation.instance.setAuthenticatedUser('user_beta');
      ControllerIsolation.instance.reloadAllControllers('user_beta');
      await NotificationController.instance.load();

      expect(NotificationController.instance.notifications, isEmpty);

      // 4. User B receives their own notification
      await NotificationController.instance.addNotification(
        AppNotification(
          id: 'beta_task_done',
          type: NotificationType.taskCompleted,
          title: 'Beta Task',
          body: 'Beta completed work',
          createdAt: DateTime.now(),
          userId: 'user_beta',
        ),
      );

      expect(NotificationController.instance.notifications.length, 1);
      expect(
        NotificationController.instance.notifications.first.userId,
        'user_beta',
      );

      // 5. Switch back to User A -> User A's notifications are restored
      AuthIsolation.instance.setAuthenticatedUser('user_alpha');
      ControllerIsolation.instance.clearAllControllers();
      ControllerIsolation.instance.reloadAllControllers('user_alpha');
      await NotificationController.instance.load();

      expect(NotificationController.instance.notifications.length, 1);
      expect(
        NotificationController.instance.notifications.first.id,
        'alpha_task_done',
      );
    });

    test('Read state persists across reload / restart', () async {
      AuthIsolation.instance.setAuthenticatedUser('user_persisted');
      NotificationController.instance.clearData();
      await NotificationController.instance.load();

      await NotificationController.instance.addNotification(
        AppNotification(
          id: 'persistent_notif',
          type: NotificationType.achievementUnlocked,
          title: 'Mastery',
          body: 'Unlocked',
          createdAt: DateTime.now(),
          userId: 'user_persisted',
        ),
      );

      expect(NotificationController.instance.unreadCount, 1);

      // Mark as read
      await NotificationController.instance.markAsRead('persistent_notif');
      expect(NotificationController.instance.unreadCount, 0);

      // Simulate app restart / controller reload
      NotificationController.instance.clearData();
      await NotificationController.instance.load();

      expect(NotificationController.instance.notifications.length, 1);
      expect(NotificationController.instance.notifications.first.isRead, isTrue);
      expect(NotificationController.instance.unreadCount, 0);
    });
  });
}
