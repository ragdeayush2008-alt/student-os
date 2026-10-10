import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/widgets/models/widget_snapshot.dart';

/// Snapshot models: tolerant decode, compact encode, empty states.
void main() {
  group('WidgetSnapshot', () {
    test('roundtrip preserves sections', () {
      final snap = WidgetSnapshot(
        userId: 'u1',
        generatedAt: DateTime(2026, 1, 1),
        nextExam: ExamWidgetData(
          id: 'e1',
          title: 'Accounts',
          subject: 'Acc',
          dateLabel: '10 Oct · 10:00 AM',
          daysLeft: 9,
          windowDays: 10,
        ),
        todayTasks: TasksWidgetData(
          remaining: 3,
          completed: 2,
          topTitle: 'Revision',
          topPriority: 'High',
        ),
        sleep: SleepWidgetData(
          bedtimeLabel: '11 PM',
          wakeLabel: '7 AM',
          durationLabel: '8h',
        ),
        lockedWidgetIds: ['daily_brief'],
      );
      final restored = WidgetSnapshot.fromJson(snap.toJson());
      expect(restored.userId, 'u1');
      expect(restored.nextExam?.daysLeft, 9);
      expect(restored.todayTasks?.remaining, 3);
      expect(restored.sleep?.durationLabel, '8h');
      expect(restored.isLocked('daily_brief'), isTrue);
      expect(restored.isLocked('exam_countdown'), isFalse);
    });

    test('malformed JSON degrades to empty, never throws', () {
      final restored = WidgetSnapshot.fromJson({
        'userId': 123,
        'generatedAt': 'not-a-date',
        'nextExam': 'garbage',
        'upcomingExams': [42, 'x'],
        'todayTasks': {'remaining': 'many'},
        'lockedWidgetIds': 'nope',
      });
      expect(restored.nextExam, isNull);
      expect(restored.upcomingExams, isEmpty);
      expect(restored.todayTasks?.remaining, 0);
      expect(restored.lockedWidgetIds, isEmpty);
    });

    test('empty snapshot is logged-out safe', () {
      final empty = WidgetSnapshot.empty();
      expect(empty.loggedOut, isTrue);
      expect(empty.nextExam, isNull);
      expect(empty.upcomingExams, isEmpty);
    });

    test('upcoming list caps at 4', () {
      final snap = WidgetSnapshot.fromJson({
        'userId': 'u',
        'generatedAt': DateTime.now().toIso8601String(),
        'upcomingExams': List.generate(
          9,
          (i) => {'id': 'e$i', 'title': 'Exam $i'},
        ),
      });
      expect(snap.upcomingExams.length, 4);
    });

    test('study remaining never negative', () {
      const study =
          StudyWidgetData(plannedMinutes: 30, completedMinutes: 90);
      expect(study.remainingMinutes, 0);
    });

    test('plan items cap at 6, lines cap at 6', () {
      final snap = WidgetSnapshot.fromJson({
        'userId': 'u',
        'generatedAt': DateTime.now().toIso8601String(),
        'todayPlan': {
          'items': List.generate(
            12,
            (i) => {'time': '09:00', 'title': 'Item $i'},
          ),
        },
        'brief': {
          'greeting': 'Hi',
          'lines': List.generate(10, (i) => 'line $i'),
        },
      });
      expect(snap.todayPlan?.items.length, 6);
      expect(snap.brief?.lines.length, 6);
    });
  });
}
