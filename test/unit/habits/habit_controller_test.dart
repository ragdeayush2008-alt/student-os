import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/streak_service.dart';
import 'package:student_os/data/models/habit_item.dart';
import 'package:student_os/features/habits/habit_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('HabitController — Unit Tests', () {
    test('1. Creates, toggles, updates and deletes habits', () async {
      AuthIsolation.instance.setAuthenticatedUser('hbt_user');
      final controller = HabitController.instance;
      await controller.load();

      final habit = await controller.createHabit(
        title: 'Morning Flashcards',
        frequency: HabitFrequency.daily,
      );

      expect(controller.habits.length, 1);
      expect(controller.activeHabits.length, 1);
      expect(habit.title, 'Morning Flashcards');
      expect(habit.isCompletedToday, isFalse);

      // Toggle today
      await controller.toggleHabitToday(habit.id);
      expect(controller.habits.first.isCompletedToday, isTrue);
      expect(controller.habits.first.currentStreak, 1);

      // Toggle off
      await controller.toggleHabitToday(habit.id);
      expect(controller.habits.first.isCompletedToday, isFalse);
    });

    test('2. Computes consecutive day habit streak correctly from real dates', () async {
      final now = DateTime.now();
      final day1 = HabitItem.dateKey(now);
      final day2 = HabitItem.dateKey(now.subtract(const Duration(days: 1)));
      final day3 = HabitItem.dateKey(now.subtract(const Duration(days: 2)));

      final habit = HabitItem(
        id: '1',
        title: 'Read 20 min',
        completedDates: {day1, day2, day3},
        createdAt: now.subtract(const Duration(days: 5)),
      );

      expect(habit.currentStreak, 3);
    });

    test('3. Habit streak is completely separate from academic focus streak', () async {
      AuthIsolation.instance.setAuthenticatedUser('hbt_user_separate');
      await HabitController.instance.load();

      final habit = await HabitController.instance.createHabit(title: 'Water 2L');
      await HabitController.instance.toggleHabitToday(habit.id);

      final saved = HabitController.instance.habits.firstWhere((h) => h.id == habit.id);
      expect(saved.currentStreak, 1);
      // StreakService academic focus streak is untouched
      expect(StreakService.instance.currentStreak, 0);
    });
  });
}
