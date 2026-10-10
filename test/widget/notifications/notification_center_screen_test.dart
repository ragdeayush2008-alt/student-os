import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_header.dart';
import 'package:student_os/data/models/app_notification.dart';
import 'package:student_os/features/notifications/notification_controller.dart';
import 'package:student_os/features/notifications/presentation/notification_center_screen.dart';

Widget _buildTestWidget(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('widget_student');
    NotificationController.instance.clearData();
  });

  group('NotificationCenterScreen & AppHeader Widget Tests', () {
    testWidgets('renders empty state when no notifications exist', (tester) async {
      await tester.pumpWidget(_buildTestWidget(const NotificationCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('No notifications'), findsOneWidget);
      expect(find.text('0 unread'), findsOneWidget);
    });

    testWidgets('renders notifications grouped with unread count and chips', (tester) async {
      final now = DateTime.now();
      await NotificationController.instance.addNotification(
        AppNotification(
          id: 'w_task_1',
          type: NotificationType.taskCompleted,
          title: 'Calculus Assignment Completed',
          body: 'You finished the Calculus problem set.',
          createdAt: now,
          userId: 'widget_student',
        ),
      );
      await NotificationController.instance.addNotification(
        AppNotification(
          id: 'w_exam_1',
          type: NotificationType.examUpcoming,
          title: 'Physics Midterm in 2 Days',
          body: 'Make sure to review formula sheet.',
          createdAt: now,
          userId: 'widget_student',
          priority: NotificationPriority.high,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(const NotificationCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('2 unread'), findsOneWidget);
      expect(find.text('Calculus Assignment Completed'), findsOneWidget);
      expect(find.text('Physics Midterm in 2 Days'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
    });

    testWidgets('tapping Mark all read updates unread count', (tester) async {
      final now = DateTime.now();
      await NotificationController.instance.addNotification(
        AppNotification(
          id: 'w_item_1',
          type: NotificationType.achievementUnlocked,
          title: 'Night Owl Unlocked',
          body: 'Studied past 10 PM',
          createdAt: now,
          userId: 'widget_student',
        ),
      );

      await tester.pumpWidget(_buildTestWidget(const NotificationCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('1 unread'), findsOneWidget);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(find.text('0 unread'), findsOneWidget);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('filter chips filter notification items', (tester) async {
      final now = DateTime.now();
      await NotificationController.instance.addNotification(
        AppNotification(
          id: 'w_task_filter',
          type: NotificationType.taskCompleted,
          title: 'Task Done',
          body: 'Done',
          createdAt: now,
          userId: 'widget_student',
        ),
      );
      await NotificationController.instance.addNotification(
        AppNotification(
          id: 'w_exam_filter',
          type: NotificationType.examUpcoming,
          title: 'Upcoming Exam',
          body: 'Prep',
          createdAt: now,
          userId: 'widget_student',
        ),
      );

      await tester.pumpWidget(_buildTestWidget(const NotificationCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Task Done'), findsOneWidget);
      expect(find.text('Upcoming Exam'), findsOneWidget);

      // Tap Tasks filter
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      expect(find.text('Task Done'), findsOneWidget);
      expect(find.text('Upcoming Exam'), findsNothing);
    });

    testWidgets('AppHeader notification bell displays unread badge reacting to state', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: AppHeader(title: 'Home'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 0 unread -> no badge number
      expect(find.text('1'), findsNothing);

      // Add unread notification
      await NotificationController.instance.addNotification(
        AppNotification(
          id: 'bell_notif',
          type: NotificationType.levelUp,
          title: 'Level Up',
          body: 'Level 3 reached',
          createdAt: DateTime.now(),
          userId: 'widget_student',
        ),
      );
      await tester.pumpAndSettle();

      // Badge renders count '1'
      expect(find.text('1'), findsOneWidget);
    });
  });
}
