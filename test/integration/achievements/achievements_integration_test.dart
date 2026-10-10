import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/progression/achievement_controller.dart';
import 'package:student_os/features/progression/achievements_screen.dart';
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
                onPressed: () => AppRouter.openAchievements(ctx),
                child: const Text('Go to Achievements'),
              ),
            ),
          ),
      AppRouter.achievementsRoute: (_) => const AchievementsScreen(),
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
    await AchievementController.instance.load();
  });

  group('Achievements Integration Tests', () {
    testWidgets('Complete academic flow: Task completion -> Achievement unlock -> XP Award', (tester) async {
      final ac = AchievementController.instance;
      final pc = ProgressionController.instance;

      expect(ac.earnedIds.contains('first_task'), isFalse);
      expect(pc.totalXp, 0);

      // Create and complete task (which triggers task XP + achievement evaluation)
      final task = await TaskController.instance.createTask(title: 'Integrate Physics Notes');
      await TaskController.instance.completeTask(task.id);
      final updated = TaskController.instance.tasks.firstWhere((t) => t.id == task.id);
      await ProgressionController.instance.awardTaskCompletion(updated);

      expect(ac.earnedIds.contains('first_task'), isTrue);
      // XP includes task completion XP + achievement XP bonus
      expect(pc.totalXp, greaterThan(0));
    });

    testWidgets('Session isolation: User A unlock does not leak to User B on logout', (tester) async {
      // 1. User A Session
      AuthIsolation.instance.setAuthenticatedUser('user_alpha');
      ControllerIsolation.instance.reloadAllControllers('user_alpha');
      final taskA = await TaskController.instance.createTask(title: 'Alpha Task');
      await TaskController.instance.completeTask(taskA.id);
      final updatedA = TaskController.instance.tasks.firstWhere((t) => t.id == taskA.id);
      await ProgressionController.instance.awardTaskCompletion(updatedA);

      expect(AchievementController.instance.earnedIds.contains('first_task'), isTrue);

      // 2. User A Logout
      AuthIsolation.instance.clearSession();
      ControllerIsolation.instance.clearAllControllers();

      expect(AchievementController.instance.isLoaded, isFalse);
      expect(AchievementController.instance.earnedCount, 0);

      // 3. User B Session
      AuthIsolation.instance.setAuthenticatedUser('user_beta');
      ControllerIsolation.instance.reloadAllControllers('user_beta');
      await AchievementController.instance.load();

      // User B has no completed tasks and no unlocked achievements
      expect(AchievementController.instance.earnedIds.contains('first_task'), isFalse);
      expect(AchievementController.instance.earnedCount, 0);
    });

    testWidgets('Persistence: Unlocked achievements survive app restart', (tester) async {
      // Unlock achievement
      final task = await TaskController.instance.createTask(title: 'Persist Task');
      await TaskController.instance.completeTask(task.id);
      final updated = TaskController.instance.tasks.firstWhere((t) => t.id == task.id);
      await ProgressionController.instance.awardTaskCompletion(updated);

      expect(AchievementController.instance.earnedIds.contains('first_task'), isTrue);

      // Simulate app restart / controller re-instantiation
      AchievementController.instance.clearData();
      expect(AchievementController.instance.isLoaded, isFalse);

      await AchievementController.instance.load();
      expect(AchievementController.instance.earnedIds.contains('first_task'), isTrue);
      expect(AchievementController.instance.entries.firstWhere((e) => e.achievement.id == 'first_task').isUnlocked, isTrue);
    });

    testWidgets('Navigation opens AchievementsScreen cleanly', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Go to Achievements'), findsOneWidget);

      await tester.tap(find.text('Go to Achievements'));
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
    });
  });
}
