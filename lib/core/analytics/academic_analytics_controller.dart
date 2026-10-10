import 'performance_snapshot.dart';
import 'academic_analytics_engine.dart';
import 'analytics_insight_engine.dart';
import 'consistency_analyzer.dart';
import 'exam_readiness_analyzer.dart';
import 'performance_trend_analyzer.dart';

import 'package:flutter/foundation.dart';

class AcademicAnalyticsController extends ChangeNotifier {
  AcademicAnalyticsController._();
  static final AcademicAnalyticsController instance =
      AcademicAnalyticsController._();

  final AcademicAnalyticsEngine _engine = const AcademicAnalyticsEngine();
  final AnalyticsInsightEngine _insightEngine = const AnalyticsInsightEngine();
  final ConsistencyAnalyzer _consistency = const ConsistencyAnalyzer();
  final ExamReadinessAnalyzer _examReadiness = const ExamReadinessAnalyzer();
  final PerformanceTrendAnalyzer _trend = const PerformanceTrendAnalyzer();

  Duration _window = const Duration(days: 30);
  Duration get window => _window;
  set window(Duration value) {
    _window = value;
    notifyListeners();
  }

  PerformanceSnapshot get _snapshot => PerformanceSnapshot.fromControllers();

  int get totalStudyMinutes =>
      _engine.calculateTotalStudyMinutes(_snapshot, _window);

  double get consistency =>
      _consistency.calculateConsistency(_snapshot, _window);

  List<String> get dailyInsights => _insightEngine.generateInsights(_snapshot);

  List<ExamReadinessResult> get examReadinessResults {
    final exams = _snapshot.allExams.where((e) => e.isUpcoming).toList();
    return exams
        .map((exam) => _examReadiness.calculateReadiness(exam, _snapshot))
        .toList();
  }

  PerformanceTrendResult get studyTrend =>
      _trend.calculateTrend(_snapshot, _window);

  StudyTimeTrend get studyTimeTrend =>
      _trend.analyzeStudyTimeTrend(_snapshot, _window);

  CompletionTrend get completionTrend =>
      _trend.analyzeCompletionTrend(_snapshot, _window);

  Map<String, int> get subjectStudyDistribution =>
      _trend.calculateSubjectStudyTimeDistribution(_snapshot, _window);

  double get workloadBalance =>
      _trend.calculateWorkloadBalance(_snapshot, _window);

  int get totalExamsUpcoming =>
      _snapshot.allExams.where((e) => e.isUpcoming).length;

  int get totalExamsCompleted =>
      _snapshot.allExams.where((e) => e.isCompleted).length;

  int get overdueTaskCount =>
      _snapshot.allTasks.where((t) => t.isOverdue && !t.isCompleted).length;

  double get taskCompletionRate =>
      _engine.calculateTaskCompletionRate(_snapshot, _window);

  double get planCompletionRate =>
      _engine.calculatePlanCompletionRate(_snapshot, _window);

  int get totalSessionsInWindow {
    final now = DateTime.now();
    final limit = now.subtract(_window);
    return _snapshot.allSessions
        .where((s) => s.isCompleted && s.startedAt.isAfter(limit))
        .length;
  }

  void refresh() => notifyListeners();
}
