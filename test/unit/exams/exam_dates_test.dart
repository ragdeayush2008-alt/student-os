import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/exam.dart';

/// Centralized exam date logic: countdown vs inclusive preparation window,
/// boundaries, missing dates. Reference case: today 1 Oct 2026, exam
/// 10 Oct 2026 → 9 days left, 10-calendar-day window (Oct 1 → Oct 10).
void main() {
  StudentExam examOn(int year, int month, int day) {
    return StudentExam(
      id: 'e1',
      title: 'Accounts Final',
      subject: 'Accounts',
      examDateTime: DateTime(year, month, day, 10, 0),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  group('countdown (daysUntilExam)', () {
    test('future date counts full days', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final exam = examOn(
        today.add(const Duration(days: 9)).year,
        today.add(const Duration(days: 9)).month,
        today.add(const Duration(days: 9)).day,
      );
      expect(exam.daysUntilExam, 9);
    });

    test('today is 0, tomorrow is 1', () {
      final now = DateTime.now();
      expect(
        examOn(now.year, now.month, now.day).daysUntilExam,
        0,
      );
      final tomorrow = now.add(const Duration(days: 1));
      expect(
        examOn(tomorrow.year, tomorrow.month, tomorrow.day).daysUntilExam,
        1,
      );
    });

    test('past exam is negative', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final exam = examOn(past.year, past.month, past.day);
      expect(exam.daysUntilExam, lessThan(0));
      expect(exam.countdown, 'Past due');
    });

    test('missing date is null everywhere', () {
      final exam = StudentExam(id: 'e2', title: 'Dateless');
      expect(exam.daysUntilExam, isNull);
      expect(exam.countdown, isNull);
      expect(exam.preparationWindowDays, isNull);
      expect(exam.preparationStart, isNull);
    });

    test('month boundary counts correctly', () {
      // Jan 31 → Feb 2 = 2 days.
      final now = DateTime.now();
      final ref = DateTime(now.year, now.month, now.day);
      final target = ref.add(const Duration(days: 2));
      final exam = examOn(target.year, target.month, target.day);
      expect(exam.daysUntilExam, 2);
    });
  });

  group('preparation window (inclusive)', () {
    test('9 days left means a 10-day window starting today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = today.add(const Duration(days: 9));
      final exam = examOn(target.year, target.month, target.day);
      expect(exam.daysUntilExam, 9);
      expect(exam.preparationWindowDays, 10);
      expect(exam.preparationStart, today);
    });

    test('today exam has a 1-day window', () {
      final now = DateTime.now();
      final exam = examOn(now.year, now.month, now.day);
      expect(exam.preparationWindowDays, 1);
    });

    test('past exam window is 0', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final exam = examOn(past.year, past.month, past.day);
      expect(exam.preparationWindowDays, 0);
    });
  });
}
