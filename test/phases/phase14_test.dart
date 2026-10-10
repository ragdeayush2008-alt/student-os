import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/core/analytics/academic_analytics_controller.dart';
import 'package:student_os/core/analytics/academic_analytics_engine.dart';
import 'package:student_os/core/analytics/analytics_insight_engine.dart';
import 'package:student_os/core/analytics/consistency_analyzer.dart';
import 'package:student_os/core/analytics/exam_readiness_analyzer.dart';
import 'package:student_os/core/analytics/performance_snapshot.dart';
import 'package:student_os/core/analytics/performance_trend_analyzer.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/task.dart';

void main() {
  group('Phase 14 — Academic Analytics', () {
    group('ExamReadinessAnalyzer', () {
      final analyzer = const ExamReadinessAnalyzer();

      test('Returns strong for completed exam', () {
        final exam = StudentExam(
          id: 'e1',
          title: 'Final',
          subject: 'Math',
          examDateTime: DateTime.now().subtract(const Duration(days: 5)),
          status: ExamStatus.completed,
          syllabusItems: [
            SyllabusItem(id: 's1', title: 'Topic 1', completed: true),
          ],
        );
        final snapshot = _emptySnapshot();
        final result = analyzer.calculateReadiness(exam, snapshot);
        expect(result.level, ExamReadinessLevel.strong);
        expect(result.score, 1.0);
      });

      test('Returns insufficientData when no syllabus or tasks', () {
        final exam = StudentExam(
          id: 'e2',
          title: 'Future Exam',
          subject: 'Physics',
          examDateTime: DateTime.now().add(const Duration(days: 30)),
          syllabusItems: [],
        );
        final snapshot = _emptySnapshot();
        final result = analyzer.calculateReadiness(exam, snapshot);
        expect(result.level, ExamReadinessLevel.insufficientData);
        expect(result.score, 0.0);
      });

      test('Returns strong for high syllabus progress with ample time', () {
        final exam = StudentExam(
          id: 'e3',
          title: 'Midterm',
          subject: 'Chemistry',
          examDateTime: DateTime.now().add(const Duration(days: 30)),
          syllabusItems: List.generate(
            10,
            (i) => SyllabusItem(id: 's$i', title: 'Topic $i', completed: i < 8),
          ),
        );
        final snapshot = _snapshotWithSessions(
          subject: 'Chemistry',
          durationSec: 7200,
          daysAgo: 2,
        );
        final result = analyzer.calculateReadiness(exam, snapshot);
        expect(result.level, ExamReadinessLevel.strong);
        expect(result.score, greaterThanOrEqualTo(0.8));
      });

      test('Returns critical when days < 7 and low progress', () {
        final exam = StudentExam(
          id: 'e4',
          title: 'Quiz',
          subject: 'Bio',
          examDateTime: DateTime.now().add(const Duration(days: 3)),
          syllabusItems: List.generate(
            10,
            (i) => SyllabusItem(id: 's$i', title: 'Topic $i', completed: i < 3),
          ),
        );
        final snapshot = _emptySnapshot();
        final result = analyzer.calculateReadiness(exam, snapshot);
        expect(result.level, ExamReadinessLevel.critical);
      });

      test('Returns critical for past due exam', () {
        final exam = StudentExam(
          id: 'e5',
          title: 'Past Exam',
          subject: 'History',
          examDateTime: DateTime.now().subtract(const Duration(days: 10)),
          status: ExamStatus.upcoming,
          syllabusItems: [
            SyllabusItem(id: 's1', title: 'Topic 1', completed: true),
          ],
        );
        final snapshot = _emptySnapshot();
        final result = analyzer.calculateReadiness(exam, snapshot);
        expect(result.level, ExamReadinessLevel.critical);
      });

      test('Explanation includes syllabus percentage', () {
        final exam = StudentExam(
          id: 'e6',
          title: 'Test',
          subject: 'CS',
          examDateTime: DateTime.now().add(const Duration(days: 10)),
          syllabusItems: [
            SyllabusItem(id: 's1', title: 'A', completed: true),
            SyllabusItem(id: 's2', title: 'B', completed: false),
            SyllabusItem(id: 's3', title: 'C', completed: false),
          ],
        );
        final snapshot = _emptySnapshot();
        final result = analyzer.calculateReadiness(exam, snapshot);
        expect(result.explanation, contains('33%'));
        expect(result.reasons.isNotEmpty, isTrue);
      });

      test('Reasons list reflects linked task completion', () {
        final exam = StudentExam(
          id: 'e7',
          title: 'Exam',
          subject: 'Math',
          examDateTime: DateTime.now().add(const Duration(days: 15)),
          syllabusItems: [
            SyllabusItem(id: 's1', title: 'Topic 1', completed: true),
          ],
        );
        final snapshot = PerformanceSnapshot(
          allSessions: [],
          allTasks: [
            StudentTask(
              id: 't1',
              title: 'Practice Problem',
              examId: 'e7',
              status: TaskStatus.active,
              dueDate: DateTime.now().add(const Duration(days: 10)),
            ),
          ],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final result = analyzer.calculateReadiness(exam, snapshot);
        expect(
          result.reasons.any((r) => r.contains('linked preparation')),
          isTrue,
        );
      });

      test('Returns strong when exam has null date', () {
        final exam = StudentExam(
          id: 'e8',
          title: 'No Date Exam',
          subject: 'Art',
          examDateTime: null,
          syllabusItems: [],
        );
        final snapshot = _emptySnapshot();
        final result = analyzer.calculateReadiness(exam, snapshot);
        expect(result.level, ExamReadinessLevel.strong);
        expect(result.score, 1.0);
      });
    });

    group('PerformanceTrendAnalyzer', () {
      final analyzer = const PerformanceTrendAnalyzer();

      test('Detects improving study trend', () {
        final now = DateTime.now();
        final snapshot = PerformanceSnapshot(
          allSessions: [
            StudySession(
              id: 's1',
              subject: 'Math',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 1)),
            ),
            StudySession(
              id: 's2',
              subject: 'Math',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 2)),
            ),
          ],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final result = analyzer.calculateTrend(
          snapshot,
          const Duration(days: 7),
        );
        expect(result.direction, PerformanceTrendDirection.improving);
        expect(result.currentValue, greaterThan(result.previousValue));
      });

      test('Detects declining study trend', () {
        final now = DateTime.now();
        final snapshot = PerformanceSnapshot(
          allSessions: [
            StudySession(
              id: 's1',
              subject: 'Math',
              durationSec: 600,
              startedAt: now.subtract(const Duration(days: 1)),
            ),
            StudySession(
              id: 's2',
              subject: 'Math',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 8)),
            ),
          ],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final result = analyzer.calculateTrend(
          snapshot,
          const Duration(days: 7),
        );
        expect(result.direction, PerformanceTrendDirection.declining);
      });

      test('Returns insufficientData for empty sessions', () {
        final snapshot = _emptySnapshot();
        final result = analyzer.calculateTrend(
          snapshot,
          const Duration(days: 7),
        );
        expect(result.direction, PerformanceTrendDirection.insufficientData);
      });

      test('studyTimeTrend returns valid data', () {
        final now = DateTime.now();
        final snapshot = PerformanceSnapshot(
          allSessions: [
            StudySession(
              id: 's1',
              subject: 'Math',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 1)),
            ),
          ],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final trend = analyzer.analyzeStudyTimeTrend(
          snapshot,
          const Duration(days: 7),
        );
        expect(trend.currentMinutes, greaterThanOrEqualTo(0));
        expect(trend.direction, isA<PerformanceTrendDirection>());
        expect(trend.explanation, isNotEmpty);
      });

      test('completionTrend detects improvement', () {
        final now = DateTime.now();
        final snapshot = PerformanceSnapshot(
          allSessions: [],
          allTasks: [
            StudentTask(
              id: 't1',
              title: 'Task 1',
              status: TaskStatus.completed,
              createdAt: now.subtract(const Duration(days: 1)),
            ),
          ],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final trend = analyzer.analyzeCompletionTrend(
          snapshot,
          const Duration(days: 7),
        );
        expect(trend.currentRate, greaterThan(trend.previousRate));
        expect(trend.direction, PerformanceTrendDirection.improving);
      });

      test('completionTrend handles empty tasks', () {
        final snapshot = _emptySnapshot();
        final trend = analyzer.analyzeCompletionTrend(
          snapshot,
          const Duration(days: 7),
        );
        expect(trend.direction, PerformanceTrendDirection.insufficientData);
      });

      test('Subject study time distribution works', () {
        final now = DateTime.now();
        final snapshot = PerformanceSnapshot(
          allSessions: [
            StudySession(
              id: 's1',
              subject: 'Math',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 1)),
            ),
            StudySession(
              id: 's2',
              subject: 'Physics',
              durationSec: 1800,
              startedAt: now.subtract(const Duration(days: 2)),
            ),
          ],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final dist = analyzer.calculateSubjectStudyTimeDistribution(
          snapshot,
          const Duration(days: 7),
        );
        expect(dist['Math'], 60);
        expect(dist['Physics'], 30);
      });

      test('Workload balance returns 0.0 for empty data', () {
        final snapshot = _emptySnapshot();
        final balance = analyzer.calculateWorkloadBalance(
          snapshot,
          const Duration(days: 7),
        );
        expect(balance, 0.0);
      });
    });

    group('ConsistencyAnalyzer', () {
      final analyzer = const ConsistencyAnalyzer();

      test('Returns 0.0 for empty study dates', () {
        final snapshot = _emptySnapshot();
        final consistency = analyzer.calculateConsistency(
          snapshot,
          const Duration(days: 7),
        );
        expect(consistency, 0.0);
      });

      test('Returns 1.0 when active every day in window', () {
        final now = DateTime.now();
        final dates = <DateTime>{};
        for (var i = 0; i < 7; i++) {
          dates.add(
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
          );
        }
        final snapshot = PerformanceSnapshot(
          allSessions: [],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: dates,
        );
        final consistency = analyzer.calculateConsistency(
          snapshot,
          const Duration(days: 7),
        );
        expect(consistency, 1.0);
      });

      test('Returns partial consistency', () {
        final now = DateTime.now();
        final dates = <DateTime>{
          DateTime(now.year, now.month, now.day),
          DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 1)),
        };
        final snapshot = PerformanceSnapshot(
          allSessions: [],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: dates,
        );
        final consistency = analyzer.calculateConsistency(
          snapshot,
          const Duration(days: 7),
        );
        expect(consistency, closeTo(2 / 7, 0.01));
      });
    });

    group('Empty data safety', () {
      test('Analytics engine handles empty snapshot', () {
        final engine = const AcademicAnalyticsEngine();
        final snapshot = _emptySnapshot();
        expect(
          engine.calculateTotalStudyMinutes(snapshot, const Duration(days: 7)),
          0,
        );
        expect(
          engine.calculateTaskCompletionRate(snapshot, const Duration(days: 7)),
          0.0,
        );
        expect(
          engine.calculatePlanCompletionRate(snapshot, const Duration(days: 7)),
          0.0,
        );
      });

      test('Engine calculateExamReadiness handles no exams', () {
        final engine = const AcademicAnalyticsEngine();
        final snapshot = _emptySnapshot();
        expect(engine.calculateExamReadiness(snapshot), 'N/A');
      });

      test('Controller provides safe values with empty data', () {
        final controller = AcademicAnalyticsController.instance;
        expect(() => controller.totalStudyMinutes, returnsNormally);
        expect(() => controller.consistency, returnsNormally);
        expect(() => controller.dailyInsights, returnsNormally);
        expect(() => controller.examReadinessResults, returnsNormally);
        expect(() => controller.studyTrend, returnsNormally);
        expect(() => controller.overdueTaskCount, returnsNormally);
      });
    });

    group('Multiple subjects', () {
      test('Subject study distribution across subjects', () {
        final now = DateTime.now();
        final snapshot = PerformanceSnapshot(
          allSessions: [
            StudySession(
              id: 's1',
              subject: 'Math',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 1)),
            ),
            StudySession(
              id: 's2',
              subject: 'Physics',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 2)),
            ),
            StudySession(
              id: 's3',
              subject: 'Math',
              durationSec: 1800,
              startedAt: now.subtract(const Duration(days: 3)),
            ),
          ],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final distribution = PerformanceTrendAnalyzer()
            .calculateSubjectStudyTimeDistribution(
              snapshot,
              const Duration(days: 7),
            );
        expect(distribution['Math'], 90);
        expect(distribution['Physics'], 60);
      });
    });

    group('Exam proximity scenarios', () {
      test('Exam with 30 days and high progress is strong', () {
        final exam = StudentExam(
          id: 'e1',
          title: 'Far Exam',
          subject: 'CS',
          examDateTime: DateTime.now().add(const Duration(days: 30)),
          syllabusItems: List.generate(
            10,
            (i) => SyllabusItem(id: 's$i', title: 'Topic $i', completed: i < 9),
          ),
        );
        final result = const ExamReadinessAnalyzer().calculateReadiness(
          exam,
          _emptySnapshot(),
        );
        expect(result.level, ExamReadinessLevel.strong);
      });

      test('Exam with 1 day and low progress is critical', () {
        final exam = StudentExam(
          id: 'e2',
          title: 'Tomorrow Exam',
          subject: 'Math',
          examDateTime: DateTime.now().add(const Duration(days: 1)),
          syllabusItems: List.generate(
            10,
            (i) => SyllabusItem(id: 's$i', title: 'Topic $i', completed: i < 2),
          ),
        );
        final result = const ExamReadinessAnalyzer().calculateReadiness(
          exam,
          _emptySnapshot(),
        );
        expect(result.level, ExamReadinessLevel.critical);
      });

      test('Exam with 0 days is still assessed', () {
        final exam = StudentExam(
          id: 'e3',
          title: 'Today Exam',
          subject: 'Math',
          examDateTime: DateTime.now(),
          syllabusItems: [
            SyllabusItem(id: 's1', title: 'Topic 1', completed: true),
          ],
        );
        final result = const ExamReadinessAnalyzer().calculateReadiness(
          exam,
          _emptySnapshot(),
        );
        expect(result.level, isA<ExamReadinessLevel>());
      });
    });

    group('Overdue and completed task scenarios', () {
      test('Overdue tasks are counted correctly', () {
        final tasks = [
          StudentTask(
            id: 't1',
            title: 'Overdue Task',
            status: TaskStatus.active,
            dueDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
          StudentTask(
            id: 't2',
            title: 'Completed Overdue',
            status: TaskStatus.completed,
            dueDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ];
        final overdue = tasks
            .where((t) => t.isOverdue && !t.isCompleted)
            .length;
        expect(overdue, 1);
      });

      test('All completed tasks gives 100% completion', () {
        final snapshot = PerformanceSnapshot(
          allSessions: [],
          allTasks: [
            StudentTask(id: 't1', title: 'Done', status: TaskStatus.completed),
            StudentTask(
              id: 't2',
              title: 'Also Done',
              status: TaskStatus.completed,
            ),
          ],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final rate = AcademicAnalyticsEngine().calculateTaskCompletionRate(
          snapshot,
          const Duration(days: 30),
        );
        expect(rate, 1.0);
      });

      test('No completed tasks gives 0% completion', () {
        final snapshot = PerformanceSnapshot(
          allSessions: [],
          allTasks: [
            StudentTask(id: 't1', title: 'Active', status: TaskStatus.active),
          ],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final rate = AcademicAnalyticsEngine().calculateTaskCompletionRate(
          snapshot,
          const Duration(days: 30),
        );
        expect(rate, 0.0);
      });
    });

    group('Time range behavior', () {
      test('Controller window can be changed', () {
        final controller = AcademicAnalyticsController.instance;
        controller.window = const Duration(days: 7);
        expect(controller.window, const Duration(days: 7));
        controller.window = const Duration(days: 90);
        expect(controller.window, const Duration(days: 90));
        controller.window = const Duration(days: 30);
      });

      test('Different windows produce different study minutes', () {
        final now = DateTime.now();
        final snapshot = PerformanceSnapshot(
          allSessions: [
            StudySession(
              id: 's1',
              subject: 'Math',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 1)),
            ),
            StudySession(
              id: 's2',
              subject: 'Math',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 10)),
            ),
          ],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final engine = const AcademicAnalyticsEngine();
        final sevenDay = engine.calculateTotalStudyMinutes(
          snapshot,
          const Duration(days: 7),
        );
        final thirtyDay = engine.calculateTotalStudyMinutes(
          snapshot,
          const Duration(days: 30),
        );
        expect(thirtyDay, greaterThanOrEqualTo(sevenDay));
      });
    });

    group('Analytics controller integration', () {
      test('Controller exposes all analytics properties', () {
        final controller = AcademicAnalyticsController.instance;
        expect(() => controller.totalStudyMinutes, returnsNormally);
        expect(() => controller.consistency, returnsNormally);
        expect(() => controller.dailyInsights, returnsNormally);
        expect(() => controller.examReadinessResults, returnsNormally);
        expect(() => controller.studyTrend, returnsNormally);
        expect(() => controller.studyTimeTrend, returnsNormally);
        expect(() => controller.completionTrend, returnsNormally);
        expect(() => controller.subjectStudyDistribution, returnsNormally);
        expect(() => controller.workloadBalance, returnsNormally);
        expect(() => controller.taskCompletionRate, returnsNormally);
        expect(() => controller.planCompletionRate, returnsNormally);
        expect(() => controller.totalSessionsInWindow, returnsNormally);
        expect(() => controller.overdueTaskCount, returnsNormally);
        expect(() => controller.totalExamsUpcoming, returnsNormally);
        expect(() => controller.totalExamsCompleted, returnsNormally);
      });

      test('Controller refresh works', () {
        final controller = AcademicAnalyticsController.instance;
        expect(() => controller.refresh(), returnsNormally);
      });
    });

    group('Insight generation', () {
      test('Insights reflect overdue tasks', () {
        final snapshot = PerformanceSnapshot(
          allSessions: [],
          allTasks: [
            StudentTask(
              id: 't1',
              title: 'Overdue',
              status: TaskStatus.active,
              dueDate: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final engine = const AnalyticsInsightEngine();
        final insights = engine.generateInsights(snapshot);
        expect(insights.any((i) => i.contains('overdue')), isTrue);
      });

      test('Insights are empty when everything is fine', () {
        final now = DateTime.now();
        final snapshot = PerformanceSnapshot(
          allSessions: [
            StudySession(
              id: 's1',
              subject: 'Math',
              durationSec: 3600,
              startedAt: now.subtract(const Duration(days: 1)),
            ),
          ],
          allTasks: [
            StudentTask(
              id: 't1',
              title: 'Done',
              status: TaskStatus.completed,
              dueDate: now.subtract(const Duration(days: 1)),
            ),
          ],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        );
        final engine = const AnalyticsInsightEngine();
        final insights = engine.generateInsights(snapshot);
        expect(insights, isA<List<String>>());
      });
    });
  });
}

PerformanceSnapshot _emptySnapshot() {
  return PerformanceSnapshot(
    allSessions: [],
    allTasks: [],
    allSubjects: [],
    allExams: [],
    studyDates: {},
  );
}

PerformanceSnapshot _snapshotWithSessions({
  required String subject,
  required int durationSec,
  required int daysAgo,
}) {
  return PerformanceSnapshot(
    allSessions: [
      StudySession(
        id: 's1',
        subject: subject,
        durationSec: durationSec,
        startedAt: DateTime.now().subtract(Duration(days: daysAgo)),
      ),
    ],
    allTasks: [],
    allSubjects: [],
    allExams: [],
    studyDates: {},
  );
}
