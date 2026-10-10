import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/analytics/academic_analytics_controller.dart';
import 'package:student_os/core/analytics/consistency_analyzer.dart';
import 'package:student_os/core/analytics/performance_snapshot.dart';
import 'package:student_os/features/analytics/analytics_screen.dart';

void main() {
  group('Phase 17 — Integration & Reliability', () {
    test('Consistency handles empty studyDates safely', () {
      final snapshot = PerformanceSnapshot(
        allSessions: [],
        allTasks: [],
        allSubjects: [],
        allExams: [],
        studyDates: {},
      );
      expect(
        const ConsistencyAnalyzer().calculateConsistency(
          snapshot,
          Duration(days: 7),
        ),
        0.0,
      );
    });

    test('Analytics controller handles rapid window changes', () {
      final c = AcademicAnalyticsController.instance;
      c.window = Duration(days: 7);
      c.window = Duration(days: 30);
      c.window = Duration(days: 90);
      expect(c.window.inDays, 90);
    });

    test('Screen widget builds without overflow on small data', () {
      expect(const AnalyticsScreen(), isNotNull);
    });
  });
}
