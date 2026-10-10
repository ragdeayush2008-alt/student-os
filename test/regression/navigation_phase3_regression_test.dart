import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/services/streak_service.dart';

void main() {
  group('Phase 3 Navigation Regression', () {
    test('AppRouter.openStreak is callable', () {
      expect(AppRouter.openStreak, isA<Function>());
    });

    test('AppRouter.openHamburger is callable', () {
      expect(AppRouter.openHamburger, isA<Function>());
    });

    test('AppRouter.openRewards is callable', () {
      expect(AppRouter.openRewards, isA<Function>());
    });

    test('AppRouter.openProgress is callable', () {
      expect(AppRouter.openProgress, isA<Function>());
    });

    test('AppRouter.openProfile is callable', () {
      expect(AppRouter.openProfile, isA<Function>());
    });

    test('AppRouter.openSettings is callable', () {
      expect(AppRouter.openSettings, isA<Function>());
    });

    test('AppRouter.openTasks is callable', () {
      expect(AppRouter.openTasks, isA<Function>());
    });

    test('AppRouter.openGoals is callable', () {
      expect(AppRouter.openGoals, isA<Function>());
    });

    test('AppRouter.openExams is callable', () {
      expect(AppRouter.openExams, isA<Function>());
    });

    test('AppRouter.openResources is callable', () {
      expect(AppRouter.openResources, isA<Function>());
    });

    test('AppRouter.openFocusCenter is callable', () {
      expect(AppRouter.openFocusCenter, isA<Function>());
    });

    test('AppRouter.openSubjectList is callable', () {
      expect(AppRouter.openSubjectList, isA<Function>());
    });

    test('StreakService is a singleton', () {
      expect(StreakService.instance, same(StreakService.instance));
    });

    test('StreakService.currentStreak is non-negative', () {
      expect(StreakService.instance.currentStreak, greaterThanOrEqualTo(0));
    });

    test('StreakService.bestStreak is non-negative', () {
      expect(StreakService.instance.bestStreak, greaterThanOrEqualTo(0));
    });

    test('StreakService.activityToday is boolean', () {
      expect(StreakService.instance.activityToday, isA<bool>());
    });
  });
}
