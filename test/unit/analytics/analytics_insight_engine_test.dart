import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/analytics/analytics_insight_engine.dart';
import 'package:student_os/core/analytics/performance_snapshot.dart';
import 'package:student_os/data/models/task.dart';

void main() {
  group('AnalyticsInsightEngine', () {
    test('produces deterministic insights with real overdue data', () {
      const engine = AnalyticsInsightEngine();
      final snapshot = PerformanceSnapshot(
        allSessions: const [],
        allTasks: [
          StudentTask(
            id: 't1',
            title: 'a',
            status: TaskStatus.active,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            dueDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
        allSubjects: const [],
        allExams: const [],
        studyDates: const {},
      );
      final insights = engine.generateInsights(snapshot);
      expect(insights.any((i) => i.contains('overdue')), isTrue);
    });

    test('handles insufficient data honestly (empty)', () {
      const engine = AnalyticsInsightEngine();
      final snapshot = PerformanceSnapshot(
        allSessions: const [],
        allTasks: const [],
        allSubjects: const [],
        allExams: const [],
        studyDates: const {},
      );
      final insights = engine.generateInsights(snapshot);
      expect(insights, isEmpty);
    });
  });
}
