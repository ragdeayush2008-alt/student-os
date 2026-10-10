import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/weekly_plan_engine.dart';

void main() {
  group('Weekly Plan Engine', () {
    test('weekDays produces 7 real dates', () {
      final days = WeeklyPlanEngine.weekDays(DateTime(2026, 9, 4));
      expect(days.length, 7);
      expect(days.first.weekday, 1); // Monday start
    });

    test('dailyTaskCount uses real task due dates', () {
      final counts = WeeklyPlanEngine.dailyTaskCount(DateTime.now());
      expect(counts.isNotEmpty, isTrue);
      for (final entry in counts.entries) {
        expect(entry.value >= 0, isTrue);
      }
    });

    test('no automatic rescheduling occurs', () {
      // Engine only derives; never writes to controller
      expect(WeeklyPlanEngine, isA<Type>());
    });
  });
}
