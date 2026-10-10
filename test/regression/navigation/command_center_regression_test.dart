import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/app/app_router.dart';

/// Regression: existing routes and navigation helpers remain valid after the
/// Academic Command Center redesign (shell-only change, no routing rewrite).
void main() {
  group('Route preservation', () {
    test('primary destination routes exist', () {
      final routes = AppRouter.routes();
      for (final route in [
        AppRouter.homeRoute,
        AppRouter.planRoute,
        AppRouter.studyRoute,
        AppRouter.focusCenterRoute,
        AppRouter.toolsRoute,
        AppRouter.toolsHubRoute,
        AppRouter.workspaceRoute,
        AppRouter.progressRoute,
        AppRouter.moreRoute,
      ]) {
        expect(routes.containsKey(route), isTrue, reason: route);
      }
    });

    test('feature routes preserved', () {
      final routes = AppRouter.routes();
      for (final route in [
        AppRouter.tasksRoute,
        AppRouter.examsRoute,
        AppRouter.subjectsRoute,
        AppRouter.rewardsRoute,
        AppRouter.leaderboardRoute,
        AppRouter.achievementsRoute,
        AppRouter.notificationsRoute,
        AppRouter.settingsRoute,
        AppRouter.profileRoute,
        AppRouter.calendarRoute,
        AppRouter.quickNotesRoute,
        AppRouter.calculatorRoute,
        AppRouter.wellnessRoute,
        AppRouter.checklistRoute,
        AppRouter.habitsRoute,
        AppRouter.revisionRoute,
        AppRouter.practiceCenterRoute,
        AppRouter.knowledgeCenterRoute,
      ]) {
        expect(routes.containsKey(route), isTrue, reason: route);
      }
    });

    test('focus routes preserved', () {
      final routes = AppRouter.routes();
      for (final route in [
        AppRouter.focusCenterRoute,
        AppRouter.focusMissionRoute,
        AppRouter.focusSessionRoute,
        AppRouter.focusHistoryRoute,
        AppRouter.focusInsightsRoute,
        AppRouter.focusInboxRoute,
      ]) {
        expect(routes.containsKey(route), isTrue, reason: route);
      }
    });

    test('navigation helpers remain callable', () {
      expect(AppRouter.openHome, isA<Function>());
      expect(AppRouter.openPlan, isA<Function>());
      expect(AppRouter.openStudy, isA<Function>());
      expect(AppRouter.openFocusTab, isA<Function>());
      expect(AppRouter.openTools, isA<Function>());
      expect(AppRouter.openWorkspace, isA<Function>());
      expect(AppRouter.openHamburger, isA<Function>());
      expect(AppRouter.openAssistant, isA<Function>());
      expect(AppRouter.openTasks, isA<Function>());
      expect(AppRouter.openExams, isA<Function>());
      expect(AppRouter.openProgress, isA<Function>());
      expect(AppRouter.openRewards, isA<Function>());
      expect(AppRouter.openLeaderboard, isA<Function>());
      expect(AppRouter.openAchievements, isA<Function>());
      expect(AppRouter.openSettings, isA<Function>());
    });
  });
}
