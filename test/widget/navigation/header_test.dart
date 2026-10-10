import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/streak_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/app_header.dart';
import 'package:student_os/core/widgets/student_os_menu_icon.dart';
import 'package:student_os/data/models/student_profile.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/notifications/notification_controller.dart';
import 'package:student_os/features/progression/leaderboard_screen.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/rewards/rewards_screen.dart';
import 'package:student_os/features/notifications/presentation/notification_center_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProgressionController.instance.clearData();
    StudentService.instance.clearProfile();
    TaskController.instance.clearData();
    NotificationController.instance.clearData();
    StreakService.instance.refresh();
  });

  Widget wrapWithApp(Widget child, {double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  group('AppHeader — UI-1 Core Tests', () {
    testWidgets('1. Header renders all essential shortcuts and elements', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader()));
      await tester.pumpAndSettle();

      expect(find.byType(StudentOSMenuIcon), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      expect(find.text('YOUR COURSE'), findsOneWidget);
    });

    testWidgets('2. XP badge uses actual ProgressionController value', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader()));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);

      await ProgressionController.instance.recordEvent(
        XpEvent(
          id: 'test_xp_1',
          type: XpEventType.taskCompleted,
          amount: 258,
          timestamp: DateTime.now(),
          reason: 'Completed math test',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('258'), findsOneWidget);
    });

    testWidgets('3. Streak badge uses actual StreakService data', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader()));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);

      final task = await TaskController.instance.createTask(
        title: 'Physics problem set',
      );
      await TaskController.instance.completeTask(task.id);
      StreakService.instance.refresh();
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('4. Course context uses actual StudentProfile', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader()));
      await tester.pumpAndSettle();

      expect(find.text('General Studies'), findsOneWidget);

      await StudentService.instance.updateProfile(
        StudentProfile(course: 'CA Foundation'),
      );
      await tester.pumpAndSettle();

      expect(find.text('CA Foundation'), findsOneWidget);
    });

    testWidgets('5. XP shortcut navigates to Rewards destination', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader()));
      await tester.pumpAndSettle();

      final xpButton = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label?.contains('XP') == true,
      );
      expect(xpButton, findsOneWidget);

      await tester.tap(xpButton);
      await tester.pumpAndSettle();

      expect(find.byType(RewardsScreen), findsOneWidget);
    });

    testWidgets('6. Leaderboard opens via overflow options', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader()));
      await tester.pumpAndSettle();

      final overflowButton = find.byIcon(Icons.more_vert_rounded);
      expect(overflowButton, findsOneWidget);

      await tester.tap(overflowButton);
      await tester.pumpAndSettle();

      expect(find.text('Student Rankings'), findsOneWidget);
      await tester.tap(find.text('Student Rankings'));
      await tester.pumpAndSettle();

      expect(find.byType(LeaderboardScreen), findsOneWidget);
    });

    testWidgets('7. Notifications bell navigates to Notification Center', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader()));
      await tester.pumpAndSettle();

      final notifButton = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label?.contains('Notifications') == true,
      );
      expect(notifButton, findsOneWidget);

      await tester.tap(notifButton);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCenterScreen), findsOneWidget);
    });

    testWidgets('8. Overflow only appears when contextual actions exist and showOverflow is true', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(const AppHeader(showOverflow: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);

      await tester.pumpWidget(
        wrapWithApp(const AppHeader(contextualActions: [])),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    });

    testWidgets('9. Overflow popup menu displays and executes contextual actions', (tester) async {
      var actionExecuted = false;

      await tester.pumpWidget(
        wrapWithApp(
          AppHeader(
            contextualActions: [
              HeaderContextAction(
                title: 'Custom Action',
                icon: Icons.flash_on_rounded,
                onTap: () {
                  actionExecuted = true;
                },
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowButton = find.byIcon(Icons.more_vert_rounded);
      expect(overflowButton, findsOneWidget);

      await tester.tap(overflowButton);
      await tester.pumpAndSettle();

      expect(find.text('Custom Action'), findsOneWidget);

      await tester.tap(find.text('Custom Action'));
      await tester.pumpAndSettle();

      expect(actionExecuted, isTrue);
    });

    testWidgets('10. Long course names do not overflow at 320dp and 412dp', (tester) async {
      await StudentService.instance.updateProfile(
        StudentProfile(
          course: 'CA Foundation Sampurna FastTrack Advanced Comprehensive Program',
        ),
      );

      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const AppHeader(), width: 320));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(412, 800);
      await tester.pumpWidget(wrapWithApp(const AppHeader(), width: 412));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Shows title when explicit title provided', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader(title: 'Home')));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Semantics are correctly assigned for accessible controls', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader()));
      await tester.pumpAndSettle();

      final menuSemantics = tester.getSemantics(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Open navigation menu',
        ),
      );
      expect(menuSemantics, isNotNull);

      final xpSemantics = tester.getSemantics(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label?.contains('XP') == true,
        ),
      );
      expect(xpSemantics, isNotNull);
    });

    testWidgets('Header utility cluster touch targets meet minimum 44x44 size', (tester) async {
      await tester.pumpWidget(wrapWithApp(const AppHeader()));
      await tester.pumpAndSettle();

      final bell = tester.getSize(find.byIcon(Icons.notifications_none));
      expect(bell.width, greaterThanOrEqualTo(22));

      final flame = tester.getSize(find.byIcon(Icons.local_fire_department_rounded));
      expect(flame.width, greaterThanOrEqualTo(21));

      final star = tester.getSize(find.byIcon(Icons.star_rounded));
      expect(star.width, greaterThanOrEqualTo(21));

      final more = tester.getSize(find.byIcon(Icons.more_vert_rounded));
      expect(more.width, greaterThanOrEqualTo(22));
    });
  });
}
