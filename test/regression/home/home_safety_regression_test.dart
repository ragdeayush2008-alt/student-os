import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/intelligence/adaptive_priority_engine.dart';
import 'package:student_os/core/intelligence/daily_academic_snapshot.dart';
import 'package:student_os/core/intelligence/daily_os_coordinator.dart';
import 'package:student_os/core/intelligence/smart_recommendation_engine.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/home/home_navigation.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 4 — Home data-safety regression.
///
/// Deleted tasks / exams / subjects must never produce invalid NOW/NEXT
/// recommendations, and a user switch must clear derived Daily OS state.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DailyOsCoordinator.instance.init();
    await _clean();
  });

  tearDown(() async {
    await _clean();
  });

  group('deleted entities never leak into recommendations', () {
    test('deleted task is not recommended and does not resolve', () async {
      final task = await TaskController.instance.createTask(
        title: 'Doomed task',
        priority: TaskPriority.critical,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(const SmartRecommendationEngine().recommend()?.taskId, task.id);

      await TaskController.instance.deleteTask(task.id);

      const engine = SmartRecommendationEngine();
      final ordered = engine.orderRecommendations();
      expect(ordered.any((a) => a.taskId == task.id), isFalse);
      expect(engine.recommend()?.taskId, isNot(task.id));

      final stale = PrioritizedAction(
        id: 'task_${task.id}',
        title: 'Doomed task',
        reason: 'stale',
        estimatedMinutes: 25,
        type: AcademicActionType.completeTask,
        priorityScore: 140,
        taskId: task.id,
      );
      expect(HomeNavigation.resolveDestination(stale), isNull);
    });

    test('deleted exam is not recommended and does not resolve', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Doomed exam',
        subject: 'Chemistry',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );
      await ExamController.instance.deleteExam(exam.id);

      const engine = SmartRecommendationEngine();
      expect(
        engine.orderRecommendations().any((a) => a.examId == exam.id),
        isFalse,
      );

      final stale = PrioritizedAction(
        id: 'exam_${exam.id}',
        title: 'Revise',
        reason: 'stale',
        estimatedMinutes: 35,
        type: AcademicActionType.examPreparation,
        priorityScore: 200,
        examId: exam.id,
      );
      expect(HomeNavigation.resolveDestination(stale), isNull);
    });

    test('deleted subject is not recommended and does not resolve', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'DoomedSubject',
      );
      final stale = PrioritizedAction(
        id: 'neglected_${subject.id}',
        title: 'Study ${subject.name}',
        reason: 'stale',
        estimatedMinutes: 30,
        type: AcademicActionType.studySession,
        priorityScore: 65,
        subjectId: subject.id,
        subjectName: subject.name,
      );
      await SubjectController.instance.deleteSubject(subject.id);

      expect(HomeNavigation.resolveDestination(stale), isNull);
      expect(
        const SmartRecommendationEngine().orderRecommendations().any(
          (a) => a.subjectId == subject.id,
        ),
        isFalse,
      );
    });

    test('snapshot survives entity deletion without dangling ids', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'SnapshotSubject',
      );
      final exam = await ExamController.instance.createExam(
        title: 'Snapshot exam',
        subject: 'SnapshotSubject',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );
      final task = await TaskController.instance.createTask(
        title: 'Snapshot task',
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        subjectId: subject.id,
        examId: exam.id,
      );

      await SubjectController.instance.deleteSubject(subject.id);
      await ExamController.instance.deleteExam(exam.id);
      await TaskController.instance.deleteTask(task.id);

      final snapshot = DailyAcademicSnapshot.fromControllers();
      final validTaskIds = TaskController.instance.tasks
          .map((t) => t.id)
          .toSet();
      final validExamIds = ExamController.instance.exams
          .map((e) => e.id)
          .toSet();
      for (final action in [snapshot.nowAction, snapshot.nextAction]) {
        if (action?.taskId != null) {
          expect(validTaskIds.contains(action!.taskId), isTrue);
        }
        if (action?.examId != null) {
          expect(validExamIds.contains(action!.examId), isTrue);
        }
      }
    });
  });

  group('user isolation of derived Daily OS state', () {
    test('clearOnLogout drops the snapshot without deleting data', () async {
      final task = await TaskController.instance.createTask(
        title: 'Isolation task',
      );

      expect(DailyOsCoordinator.instance.snapshot, isNotNull);

      DailyOsCoordinator.instance.clearOnLogout();
      expect(DailyOsCoordinator.instance.snapshot, isNull);

      // Stored data is untouched; only derived state was cleared.
      expect(TaskController.instance.tasks.any((t) => t.id == task.id), isTrue);

      DailyOsCoordinator.instance.init();
      await TaskController.instance.deleteTask(task.id);
    });
  });
}

Future<void> _clean() async {
  for (final task in List.of(TaskController.instance.tasks)) {
    await TaskController.instance.deleteTask(task.id);
  }
  for (final exam in List.of(ExamController.instance.exams)) {
    await ExamController.instance.deleteExam(exam.id);
  }
  for (final subject in List.of(SubjectController.instance.subjects)) {
    await SubjectController.instance.deleteSubject(subject.id);
  }
  DailyOsCoordinator.instance.refresh();
}
