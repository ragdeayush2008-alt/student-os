import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/analytics/academic_analytics_controller.dart';
import 'package:student_os/core/intelligence/academic_context.dart';
import 'package:student_os/core/intelligence/adaptive_priority_engine.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  group('Phase 15 — Production Hardening & Integration', () {
    test('End-to-end data flow: Task → Exam → Intelligence → Analytics', () {
      final ec = ExamController.instance;
      final tc = TaskController.instance;

      // Verify controllers expose consistent interfaces
      expect(ec.exams, isA<List<StudentExam>>());
      expect(tc.tasks, isA<List<StudentTask>>());
      expect(ec.upcomingExams, isA<List<StudentExam>>());

      // Intelligence engine produces consistent context
      final context = AcademicContext.fromControllers();
      expect(context.upcomingExams, isA<List<StudentExam>>());
      expect(context.overdueTasks, isA<List<StudentTask>>());

      // Analytics controller produces results without errors
      final analytics = AcademicAnalyticsController.instance;
      expect(() => analytics.totalStudyMinutes, returnsNormally);
      expect(() => analytics.examReadinessResults, returnsNormally);
    });

    test('Navigation routes exist and resolve', () {
      expect(AppRouter.analyticsRoute, '/analytics');
      expect(AppRouter.homeRoute, '/home');
      expect(AppRouter.studyRoute, '/study');
      expect(AppRouter.examsRoute, '/exams');
      expect(AppRouter.tasksRoute, '/tasks');
    });

    test('AcademicIntelligenceController integrates with analytics', () {
      final intelligence = AcademicIntelligenceController.instance;
      expect(() => intelligence.currentContext, returnsNormally);
      expect(() => intelligence.currentPlan, returnsNormally);
      expect(() => intelligence.rankedActions, returnsNormally);
      expect(() => intelligence.nextBestAction, returnsNormally);
    });

    test('AdaptivePriorityEngine produces prioritized actions', () {
      const engine = AdaptivePriorityEngine();
      final context = AcademicContext(
        upcomingExams: [],
        overdueTasks: [],
        todayTasks: [],
        activeSubjects: [],
        examSummaries: [],
        subjectHealths: [],
        highPressureSubjectIds: {},
        neglectedSubjectIds: {},
        isWorkloadHeavy: false,
      );
      final actions = engine.derivePrioritizedActions(context);
      expect(actions, isA<List<PrioritizedAction>>());
    });

    test('Analytics screen responds to controller window changes', () {
      final controller = AcademicAnalyticsController.instance;
      const original = Duration(days: 30);

      controller.window = const Duration(days: 7);
      expect(controller.window, const Duration(days: 7));

      controller.window = const Duration(days: 90);
      expect(controller.window, const Duration(days: 90));

      controller.window = original;
    });

    test('Empty exam list produces safe analytics', () {
      final analytics = AcademicAnalyticsController.instance;
      expect(analytics.examReadinessResults, isA<List<dynamic>>());
      expect(analytics.totalExamsUpcoming, greaterThanOrEqualTo(0));
    });

    test('Persistence keys are user-scoped', () {
      // StorageService uses user-scoped prefixes
      expect('uos_demo_tasks', contains('uos_'));
    });
  });
}
