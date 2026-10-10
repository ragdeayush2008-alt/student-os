import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/intelligence/daily_os_coordinator.dart';
import 'package:student_os/core/intelligence/weekly_plan_engine.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 5 — Academic workspaces end-to-end integration.
///
/// Verifies Subject ↔ Task ↔ Exam flows as one connected system and that
/// every change feeds Daily OS, Focus context, and planning derivation
/// without destabilizing Home intelligence.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DailyOsCoordinator.instance.init();
    await _clean();
  });

  tearDown(() async {
    await _clean();
  });

  group('Subject → Task → Exam connected flow', () {
    test('full chain links by id and resolves both directions', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'IntegrationSub',
      );
      final exam = await ExamController.instance.createExam(
        title: 'Integration exam',
        subject: 'IntegrationSub',
        examDateTime: DateTime.now().add(const Duration(days: 7)),
      );
      final task = await TaskController.instance.createTask(
        title: 'Integration task',
        subjectId: subject.id,
        examId: exam.id,
        dueDate: DateTime.now(),
      );

      // Forward links.
      expect(task.subjectId, subject.id);
      expect(task.examId, exam.id);

      // Reverse lookups.
      expect(
        TaskController.instance.tasksForSubject(subject.id).map((t) => t.id),
        contains(task.id),
      );
      expect(
        TaskController.instance.tasksForExam(exam.id).map((t) => t.id),
        contains(task.id),
      );
      expect(
        ExamController.instance
            .examsForSubjectName('integrationsub')
            .map((e) => e.id),
        contains(exam.id),
      );
      expect(ExamController.instance.hasLinkedTasks(exam), isTrue);
    });

    test(
      'urgent linked task surfaces in Daily OS; completion clears it',
      () async {
        // Distant exam: its prep action scores below the overdue task, so the
        // task itself becomes NOW (engine semantics, deterministic).
        final exam = await ExamController.instance.createExam(
          title: 'Urgent exam',
          examDateTime: DateTime.now().add(const Duration(days: 30)),
        );
        final task = await TaskController.instance.createTask(
          title: 'Urgent linked task',
          priority: TaskPriority.critical,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          examId: exam.id,
        );

        expect(
          DailyOsCoordinator.instance.snapshot?.nowAction?.taskId,
          task.id,
        );

        await TaskController.instance.completeTask(task.id);
        expect(
          DailyOsCoordinator.instance.snapshot?.nowAction?.taskId,
          isNot(task.id),
        );
      },
    );

    test('upcoming exam feeds Home snapshot; deletion removes it', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Snapshot exam',
        examDateTime: DateTime.now().add(const Duration(days: 4)),
      );
      DailyOsCoordinator.instance.refresh();
      expect(DailyOsCoordinator.instance.snapshot?.upcomingExamDays, 4);

      await ExamController.instance.deleteExam(exam.id);
      DailyOsCoordinator.instance.refresh();
      expect(DailyOsCoordinator.instance.snapshot?.upcomingExamDays, isNull);
    });
  });

  group('Focus context across workspaces', () {
    test('mission retains task + subject + exam ids end to end', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'FocusSub',
      );
      final exam = await ExamController.instance.createExam(
        title: 'Focus exam',
      );
      final task = await TaskController.instance.createTask(
        title: 'Focus task',
        subjectId: subject.id,
        examId: exam.id,
      );

      final mission = FocusMission(
        id: 'mission_test_focus',
        objective: task.title,
        subjectId: subject.id,
        subjectName: subject.name,
        taskId: task.id,
        examId: exam.id,
      );
      FocusController.instance.startMission(mission);

      final session = FocusController.instance.activeSession!;
      expect(session.taskId, task.id);
      expect(session.subjectId, subject.id);
      expect(session.examId, exam.id);

      FocusController.instance.completeSession();
      expect(FocusController.instance.hasActiveSession, isFalse);
    });
  });

  group('Planning derivation follows workspace changes', () {
    test(
      'created task appears in weekly counts; deletion removes it',
      () async {
        final anchor = DateTime.now();
        final before =
            WeeklyPlanEngine.dailyTaskCount(anchor)[DateTime(
              anchor.year,
              anchor.month,
              anchor.day,
            )] ??
            0;

        final task = await TaskController.instance.createTask(
          title: 'Planned task',
          dueDate: anchor,
        );
        final after =
            WeeklyPlanEngine.dailyTaskCount(anchor)[DateTime(
              anchor.year,
              anchor.month,
              anchor.day,
            )] ??
            0;
        expect(after, before + 1);

        await TaskController.instance.deleteTask(task.id);
        final cleaned =
            WeeklyPlanEngine.dailyTaskCount(anchor)[DateTime(
              anchor.year,
              anchor.month,
              anchor.day,
            )] ??
            0;
        expect(cleaned, before);
      },
    );
  });

  group('Study changes stay visible to workspaces', () {
    test('completed study session registers for the day', () async {
      StudyController.instance.startSession(subject: 'IntegrationSub');
      final session = await StudyController.instance.endSession();

      expect(session, isNotNull);
      expect(StudyController.instance.todayCompletedCount, 1);

      StudyController.instance.clearData();
    });
  });
}

Future<void> _clean() async {
  if (FocusController.instance.hasActiveSession) {
    FocusController.instance.completeSession();
  }
  FocusController.instance.clearData();
  StudyController.instance.clearData();
  TaskController.instance.clearFilters();
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
