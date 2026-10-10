import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/intelligence/academic_context.dart';
import 'package:student_os/core/intelligence/adaptive_priority_engine.dart';
import 'package:student_os/core/intelligence/today_plan_engine.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TaskController.instance.load();
    await ExamController.instance.load();
    await SubjectController.instance.load();
    await StudyController.instance.load();
  });

  group('Phase 12 — Academic Context & Intelligence Engines', () {
    test('AcademicContext accurately aggregates overdue tasks, exam status, and subject health', () async {
      final taskCtrl = TaskController.instance;
      final examCtrl = ExamController.instance;
      final subjectCtrl = SubjectController.instance;

      // 1. Setup a Subject
      final subject = await subjectCtrl.createSubject(
        name: 'Organic Chemistry',
        color: 0xFF4A90E2,
      );

      // 2. Setup an Overdue Task
      await taskCtrl.createTask(
        title: 'Review Reaction Mechanisms',
        subjectId: subject.id,
        priority: TaskPriority.critical,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      // 3. Setup an upcoming exam with low syllabus completion
      await examCtrl.createExam(
        title: 'Midterm Exam',
        subject: subject.name,
        examDateTime: DateTime.now().add(const Duration(days: 3)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Alkanes', completed: true),
          SyllabusItem(id: 's2', title: 'Alkenes', completed: false),
          SyllabusItem(id: 's3', title: 'Aromatics', completed: false),
        ],
      );

      // 4. Derive Academic Context
      final context = AcademicContext.fromControllers();

      expect(context.overdueTasks.length, greaterThanOrEqualTo(1));
      expect(context.upcomingExams.length, greaterThanOrEqualTo(1));
      expect(context.examSummaries.isNotEmpty, isTrue);

      final examSummary = context.examSummaries.first;
      expect(examSummary.daysRemaining, lessThanOrEqualTo(3));
      expect(examSummary.state, ExamReadinessState.critical);
      expect(examSummary.remainingTopicsCount, 2);
    });

    test('AdaptivePriorityEngine prioritizes urgent overdue tasks and near-term exams', () {
      const priorityEngine = AdaptivePriorityEngine();

      final now = DateTime.now();
      final context = AcademicContext(
        upcomingExams: [
          StudentExam(
            id: 'exam-1',
            title: 'Physics Finals',
            subject: 'Physics',
            examDateTime: now.add(const Duration(days: 2)),
            syllabusItems: [
              SyllabusItem(id: 's1', title: 'Thermodynamics', completed: false),
            ],
          ),
        ],
        overdueTasks: [
          StudentTask(
            id: 'task-1',
            title: 'Urgent Lab Report',
            priority: TaskPriority.critical,
            dueDate: now.subtract(const Duration(days: 1)),
          ),
        ],
        todayTasks: [],
        activeSubjects: [
          Subject(id: 'sub-1', name: 'Physics', color: 0xFF123456),
        ],
        examSummaries: [
          ExamPreparationSummary(
            exam: StudentExam(
              id: 'exam-1',
              title: 'Physics Finals',
              subject: 'Physics',
              examDateTime: now.add(const Duration(days: 2)),
            ),
            daysRemaining: 2,
            syllabusCompletionPercent: 0.20,
            remainingTopicsCount: 4,
            recentStudyMinutes: 0,
            uncompletedTaskCount: 2,
            state: ExamReadinessState.critical,
            explanation: 'Exam in 2 days with low syllabus completion.',
          ),
        ],
        subjectHealths: [],
        highPressureSubjectIds: {'sub-1'},
        neglectedSubjectIds: {},
        isWorkloadHeavy: false,
      );

      final actions = priorityEngine.derivePrioritizedActions(context);

      expect(actions.isNotEmpty, isTrue);
      // First action should either be the urgent overdue task or critical exam
      expect(actions.first.priorityScore, greaterThan(100.0));
      expect(
        actions.any((a) => a.type == AcademicActionType.completeTask),
        isTrue,
      );
      expect(
        actions.any((a) => a.type == AcademicActionType.examPreparation),
        isTrue,
      );
    });

    test('TodayPlanEngine respects time budgets and gentle recovery mode', () {
      final context = AcademicContext(
        upcomingExams: [],
        overdueTasks: [
          StudentTask(
            id: 'task-1',
            title: 'Problem Set 1',
            priority: TaskPriority.high,
          ),
          StudentTask(
            id: 'task-2',
            title: 'Problem Set 2',
            priority: TaskPriority.medium,
          ),
          StudentTask(
            id: 'task-3',
            title: 'Problem Set 3',
            priority: TaskPriority.low,
          ),
        ],
        todayTasks: [],
        activeSubjects: [],
        examSummaries: [],
        subjectHealths: [],
        highPressureSubjectIds: {},
        neglectedSubjectIds: {},
        isWorkloadHeavy: true,
      );

      const planEngine = TodayPlanEngine();

      // 1. Quick Burst budget (30 min) should fit at most 1 task (25 mins) without exceeding budget
      final burstPlan = planEngine.generatePlan(
        context: context,
        budget: AvailableTimeBudget.thirtyMinutes,
      );
      expect(burstPlan.actions.length, 1);
      expect(burstPlan.plannedMinutes, 25);
      expect(burstPlan.deferredActionsCount, 2);

      // 2. Standard 1-hour budget should fit more tasks (2 x 25 = 50 mins <= 60 mins)
      final standardPlan = planEngine.generatePlan(
        context: context,
        budget: AvailableTimeBudget.oneHour,
      );
      expect(standardPlan.actions.length, 2);
      expect(standardPlan.plannedMinutes, 50);

      // 3. Gentle Recovery Mode should constrain actions to protect mental health
      final gentlePlan = planEngine.generatePlan(
        context: context,
        budget: AvailableTimeBudget.twoHours,
        gentleRecoveryMode: true,
      );
      expect(gentlePlan.actions.length, lessThanOrEqualTo(2));
      expect(gentlePlan.isGentleRecovery, isTrue);
    });
  });
}
