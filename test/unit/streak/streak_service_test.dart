import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/streak_service.dart';

void main() {
  group('StreakService', () {
    test('instance is singleton', () {
      expect(StreakService.instance, same(StreakService.instance));
    });

    test('currentStreak returns a non-negative integer', () {
      final streak = StreakService.instance.currentStreak;
      expect(streak, isA<int>());
      expect(streak, greaterThanOrEqualTo(0));
    });

    test('bestStreak returns a non-negative integer', () {
      final best = StreakService.instance.bestStreak;
      expect(best, isA<int>());
      expect(best, greaterThanOrEqualTo(0));
    });

    test('bestStreak is >= currentStreak', () {
      final current = StreakService.instance.currentStreak;
      final best = StreakService.instance.bestStreak;
      expect(best, greaterThanOrEqualTo(current));
    });

    test('activityToday returns a boolean', () {
      final today = StreakService.instance.activityToday;
      expect(today, isA<bool>());
    });

    test('refresh does not throw', () {
      expect(() => StreakService.instance.refresh(), returnsNormally);
    });
  });
}
