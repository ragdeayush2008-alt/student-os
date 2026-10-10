import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/leaderboard_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/leaderboard_entry.dart';
import 'package:student_os/data/models/student_profile.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/leaderboard_controller.dart';
import 'package:student_os/features/progression/leaderboard_screen.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

Widget _buildApp() {
  return MaterialApp(
    navigatorKey: AppRouter.navigatorKey,
    theme: AppTheme.light(),
    routes: {
      '/': (_) => Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppRouter.openLeaderboard(ctx),
                child: const Text('Go to Leaderboard'),
              ),
            ),
          ),
      AppRouter.leaderboardRoute: (_) => const LeaderboardScreen(),
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ControllerIsolation.instance.clearAllControllers();
    await TaskController.instance.load();
    await ProgressionController.instance.load();
    await StudentService.instance.load();
    await LeaderboardController.instance.load();
  });

  group('Leaderboard Integration Tests', () {
    testWidgets('Task completion awards XP and updates Leaderboard in real-time', (tester) async {
      final task = await TaskController.instance.createTask(
        title: 'Complete Research Paper',
        priority: TaskPriority.critical,
      );

      // Verify initial XP is 0
      expect(ProgressionController.instance.totalXp, 0);
      expect(LeaderboardController.instance.currentUserEntry?.xp, 0);

      // Complete task
      await TaskController.instance.completeTask(task.id);
      final updated = TaskController.instance.tasks.firstWhere((t) => t.id == task.id);
      await ProgressionController.instance.awardTaskCompletion(updated);

      // Verify XP awarded and Leaderboard updated immediately
      // 30 XP task completion + 10 XP First Steps achievement unlock = 40 XP
      expect(ProgressionController.instance.totalXp, 40);
      expect(LeaderboardController.instance.currentUserEntry?.xp, 40);
    });

    testWidgets('Session isolation: User A -> logout -> User B prevents state leakage', (tester) async {
      // 1. User A session
      AuthIsolation.instance.setAuthenticatedUser('user_alpha');
      await StudentService.instance.updateProfile(
        StudentProfile(id: 'user_alpha', displayName: 'Alpha User'),
      );
      await ProgressionController.instance.recordEvent(
        XpEvent(
          id: 'ev_alpha_1',
          type: XpEventType.taskCompleted,
          amount: 500,
          timestamp: DateTime.now(),
          reason: 'Alpha Task',
        ),
      );
      await LeaderboardController.instance.refresh();

      // 500 XP + 50 XP Rising Star level 5 achievement = 550 XP
      expect(LeaderboardController.instance.currentUserEntry?.displayName, 'Alpha User');
      expect(LeaderboardController.instance.currentUserEntry?.xp, 550);

      // 2. User A Logout
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();

      expect(LeaderboardController.instance.isLoaded, isFalse);
      expect(LeaderboardController.instance.entries, isEmpty);

      // 3. User B session
      AuthIsolation.instance.setAuthenticatedUser('user_beta');
      await StudentService.instance.updateProfile(
        StudentProfile(id: 'user_beta', displayName: 'Beta User'),
      );
      await LeaderboardController.instance.load();

      // Verify User B does not see User A's name or XP
      expect(LeaderboardController.instance.currentUserEntry?.displayName, 'Beta User');
      expect(LeaderboardController.instance.currentUserEntry?.xp, 0);
    });

    testWidgets('Offline caching loads stored rankings gracefully without crash', (tester) async {
      // Seed cached entries
      final cachedEntries = [
        LeaderboardEntry(
          userId: 'top_peer',
          displayName: 'Champion Peer',
          xp: 2000,
          level: 6,
          rank: 1,
        ),
        LeaderboardEntry(
          userId: 'demo',
          displayName: 'You',
          xp: 100,
          level: 1,
          rank: 2,
          isCurrentUser: true,
        ),
      ];

      await LeaderboardService.instance.saveCachedEntries(
        LeaderboardPeriod.thisWeek,
        cachedEntries,
      );

      // Load controller
      await LeaderboardController.instance.load();

      expect(LeaderboardController.instance.entries.isNotEmpty, isTrue);
      expect(LeaderboardController.instance.entries.any((e) => e.displayName == 'Champion Peer'), isTrue);
    });

    testWidgets('Navigation opens LeaderboardScreen seamlessly', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Go to Leaderboard'), findsOneWidget);

      await tester.tap(find.text('Go to Leaderboard'));
      await tester.pumpAndSettle();

      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);
    });
  });
}
