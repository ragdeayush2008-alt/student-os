import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/intelligence/adaptive_priority_engine.dart';
import 'package:student_os/core/intelligence/daily_academic_snapshot.dart';
import 'package:student_os/core/intelligence/smart_recommendation_engine.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/home/home_navigation.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 4 — Home navigation resolution.
///
/// Verifies NOW/NEXT routing is deterministic, truthful (never references
/// deleted entities), and never falls back to Home.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  PrioritizedAction taskAction(String taskId) => PrioritizedAction(
    id: 'task_$taskId',
    title: 'Test task',
    reason: 'Overdue task with high academic priority',
    estimatedMinutes: 25,
    type: AcademicActionType.completeTask,
    priorityScore: 125,
    taskId: taskId,
  );

  group('HomeNavigation.resolveDestination', () {
    test('stale task reference resolves to null (never invalid)', () {
      final dest = HomeNavigation.resolveDestination(
        taskAction('missing_task_id'),
      );
      expect(dest, isNull);
    });

    test('existing task resolves to taskDetail with label', () async {
      final task = await TaskController.instance.createTask(
        title: 'Nav task unit',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      addTearDown(() => TaskController.instance.deleteTask(task.id));

      final dest = HomeNavigation.resolveDestination(taskAction(task.id));
      expect(dest, HomeActionDestination.taskDetail);
      expect(HomeNavigation.primaryLabel(taskAction(task.id)), 'Open task');
    });

    test('same controller state produces same destination', () async {
      final task = await TaskController.instance.createTask(
        title: 'Deterministic nav task',
      );
      addTearDown(() => TaskController.instance.deleteTask(task.id));

      final first = HomeNavigation.resolveDestination(taskAction(task.id));
      final second = HomeNavigation.resolveDestination(taskAction(task.id));
      expect(first, second);
    });

    test('existing exam resolves to examDetail', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Nav exam unit',
        subject: 'Physics',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );
      addTearDown(() => ExamController.instance.deleteExam(exam.id));

      const action = PrioritizedAction(
        id: 'exam_x',
        title: 'Revise topic',
        reason: 'Exam soon',
        estimatedMinutes: 35,
        type: AcademicActionType.examPreparation,
        priorityScore: 130,
        examId: 'placeholder',
      );
      final dest = HomeNavigation.resolveDestination(
        PrioritizedAction(
          id: action.id,
          title: action.title,
          reason: action.reason,
          estimatedMinutes: action.estimatedMinutes,
          type: action.type,
          priorityScore: action.priorityScore,
          examId: exam.id,
        ),
      );
      expect(dest, HomeActionDestination.examDetail);
    });

    test('deleted exam no longer resolves', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Temp exam unit',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );
      final action = PrioritizedAction(
        id: 'exam_${exam.id}',
        title: 'Revise',
        reason: 'Exam soon',
        estimatedMinutes: 35,
        type: AcademicActionType.examPreparation,
        priorityScore: 130,
        examId: exam.id,
      );
      await ExamController.instance.deleteExam(exam.id);

      expect(HomeNavigation.resolveDestination(action), isNull);
    });

    test('existing subject resolves to subjectDetail', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'NavSubjectUnit',
      );
      addTearDown(() => SubjectController.instance.deleteSubject(subject.id));

      final dest = HomeNavigation.resolveDestination(
        PrioritizedAction(
          id: 'neglected_${subject.id}',
          title: 'Study ${subject.name}',
          reason: 'Not studied recently',
          estimatedMinutes: 30,
          type: AcademicActionType.studySession,
          priorityScore: 65,
          subjectId: subject.id,
          subjectName: subject.name,
        ),
      );
      expect(dest, HomeActionDestination.subjectDetail);
    });

    test('deleted subject no longer resolves', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'TempSubjectUnit',
      );
      final action = PrioritizedAction(
        id: 'neglected_${subject.id}',
        title: 'Study ${subject.name}',
        reason: 'Not studied recently',
        estimatedMinutes: 30,
        type: AcademicActionType.studySession,
        priorityScore: 65,
        subjectId: subject.id,
        subjectName: subject.name,
      );
      await SubjectController.instance.deleteSubject(subject.id);

      expect(HomeNavigation.resolveDestination(action), isNull);
    });

    test('generic study action resolves to study', () {
      const action = PrioritizedAction(
        id: 'study_generic',
        title: 'Study session',
        reason: 'Keep momentum',
        estimatedMinutes: 30,
        type: AcademicActionType.studySession,
        priorityScore: 40,
      );
      expect(
        HomeNavigation.resolveDestination(action),
        HomeActionDestination.study,
      );
      expect(HomeNavigation.primaryLabel(action), 'Open study');
    });
  });

  group('Recommendation determinism (same state, same NOW/NEXT)', () {
    test('engine recommend is deterministic', () async {
      final task = await TaskController.instance.createTask(
        title: 'Deterministic engine task',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      addTearDown(() => TaskController.instance.deleteTask(task.id));

      const engine = SmartRecommendationEngine();
      final first = engine.recommend();
      final second = engine.recommend();
      expect(first?.id, second?.id);
    });

    test('snapshot NOW/NEXT stable for same state', () async {
      final task = await TaskController.instance.createTask(
        title: 'Deterministic snapshot task',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      addTearDown(() => TaskController.instance.deleteTask(task.id));

      final snap1 = DailyAcademicSnapshot.fromControllers();
      final snap2 = DailyAcademicSnapshot.fromControllers();
      expect(snap1.nowAction?.id, snap2.nowAction?.id);
      expect(snap1.nextAction?.id, snap2.nextAction?.id);
    });
  });
}
