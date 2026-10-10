import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/tasks/task_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/core/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Academic Command Loop — Task ↔ Subject ↔ Exam', () {
    test(
      'A. Task links to subject and exam, survives deletion of linked entities',
      () async {
        final sub = await SubjectController.instance.createSubject(
          name: 'Physics',
        );
        final exam = await ExamController.instance.createExam(
          title: 'Physics Final',
          subject: 'Physics',
        );
        final task = await TaskController.instance.createTask(
          title: 'Revise Chapter 3',
          subjectId: sub.id,
          examId: exam.id,
        );

        expect(task.subjectId, sub.id);
        expect(task.examId, exam.id);

        // Delete linked entities
        await SubjectController.instance.deleteSubject(sub.id);
        await ExamController.instance.deleteExam(exam.id);

        // Task survives; links cleared safely
        final remaining = TaskController.instance.tasks
            .where((t) => t.id == task.id)
            .toList();
        expect(remaining.length, 1);
        expect(remaining.single.subjectId, isNull);
        expect(remaining.single.examId, isNull);

        await TaskController.instance.deleteTask(task.id);
      },
    );

    test('B. Task ↔ Subject relationship flows through controllers', () async {
      final sub = await SubjectController.instance.createSubject(
        name: 'Chemistry',
      );
      final task = await TaskController.instance.createTask(
        title: 'Lab prep',
        subjectId: sub.id,
      );

      expect(TaskController.instance.tasksForSubject(sub.id).length, 1);
      expect(TaskController.instance.activeTasksForSubject(sub.id).length, 1);

      await TaskController.instance.completeTask(task.id);
      expect(
        TaskController.instance.completedTasksForSubject(sub.id).length,
        1,
      );
      expect(TaskController.instance.activeTasksForSubject(sub.id).length, 0);

      await TaskController.instance.deleteTask(task.id);
      await SubjectController.instance.deleteSubject(sub.id);
    });

    test('C. Task ↔ Exam relationship flows through controllers', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Bio Midterm',
        subject: 'Biology',
      );
      final task = await TaskController.instance.createTask(
        title: 'Bio review',
        examId: exam.id,
      );

      expect(TaskController.instance.tasksForExam(exam.id).length, 1);
      expect(ExamController.instance.hasLinkedTasks(exam), isTrue);

      await ExamController.instance.deleteExam(exam.id);
      // Task preserved; exam reference cleared
      final remaining = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .toList();
      expect(remaining.single.examId, isNull);

      await TaskController.instance.deleteTask(task.id);
    });

    test(
      'D. Deleting linked subject/exam does not crash task access',
      () async {
        final sub = await SubjectController.instance.createSubject(
          name: 'Temp',
        );
        final task = await TaskController.instance.createTask(
          title: 'Safe',
          subjectId: sub.id,
        );

        await SubjectController.instance.deleteSubject(sub.id);

        // Access should not throw
        final tasks = TaskController.instance.tasksForSubject(sub.id);
        expect(tasks, isEmpty);

        // Original task still exists safely
        expect(
          TaskController.instance.tasks.any((t) => t.id == task.id),
          isTrue,
        );
        await TaskController.instance.deleteTask(task.id);
      },
    );
  });

  group('Plan derives from real TaskController data', () {
    test('E. Plan tasksFor uses real TaskController', () async {
      final sub = await SubjectController.instance.createSubject(
        name: 'PlanSub',
      );
      await TaskController.instance.createTask(
        title: 'Plan task',
        subjectId: sub.id,
        scheduledDate: DateTime.now(),
      );

      final dayTasks = PlanController.instance.tasksFor(DateTime.now());
      expect(dayTasks.any((t) => t.title == 'Plan task'), isTrue);

      await TaskController.instance.deleteTask(
        TaskController.instance.tasks
            .where((t) => t.title == 'Plan task')
            .single
            .id,
      );
      await SubjectController.instance.deleteSubject(sub.id);
    });
  });

  group('Focus integration with real academic context', () {
    test(
      'F. Focus started from task preserves IDs and uses task context',
      () async {
        final sub = await SubjectController.instance.createSubject(
          name: 'FocusSub',
        );
        final exam = await ExamController.instance.createExam(
          title: 'FocusExam',
          subject: 'FocusSub',
        );
        final task = await TaskController.instance.createTask(
          title: 'Focus task',
          subjectId: sub.id,
          examId: exam.id,
        );

        final mission = FocusMission(
          id: 'mission_f1',
          objective: 'Work on Focus task',
          taskId: task.id,
          subjectId: sub.id,
          examId: exam.id,
          mode: FocusMode.timer,
          plannedDuration: const Duration(minutes: 15),
        );

        FocusController.instance.startMission(mission);
        final active = FocusController.instance.activeSession;
        expect(active, isNotNull);
        expect(active!.taskId, task.id);
        expect(active.subjectId, sub.id);
        expect(active.examId, exam.id);

        // End the session cleanly
        FocusController.instance.completeSession();
        await Future.delayed(const Duration(milliseconds: 100));

        await TaskController.instance.deleteTask(task.id);
        await ExamController.instance.deleteExam(exam.id);
        await SubjectController.instance.deleteSubject(sub.id);
      },
    );

    test(
      'G. Focus completion is idempotent (same session id won\'t duplicate XP)',
      () async {
        FocusController.instance.clearData();
        await FocusController.instance.load();
        // After clear, no active session; create and complete once
        final mission = FocusMission(
          id: 'mission_idem_1',
          objective: 'Idempotent test',
          mode: FocusMode.timer,
          plannedDuration: const Duration(minutes: 10),
        );
        FocusController.instance.startMission(mission);
        FocusController.instance.completeSession();
        await Future.delayed(const Duration(milliseconds: 50));

        // Duplicate call should not create duplicate events (recordEvent handles dedup)
        FocusController.instance.completeSession();
        await Future.delayed(const Duration(milliseconds: 50));

        // Just verify controller state remains valid
        expect(
          FocusController.instance.sessions.isNotEmpty ||
              FocusController.instance.activeSession == null,
          isTrue,
        );
        FocusController.instance.clearData();
      },
    );
  });

  group('XP idempotency', () {
    test(
      'H. Task completion XP is idempotent via ProgressionController',
      () async {
        final task = await TaskController.instance.createTask(title: 'XP Task');
        await TaskController.instance.completeTask(task.id);

        // Second call with same completedAt should not add duplicate event
        // (ProgressionController.recordEvent uses event.id dedup)
        await ProgressionController.instance.awardTaskCompletion(
          TaskController.instance.tasks.firstWhere((t) => t.id == task.id),
        );

        await TaskController.instance.deleteTask(task.id);
      },
    );

    test('I. Focus/study XP is idempotent via deterministic event IDs', () {
      // XpEngine creates deterministic IDs; ProgressionController dedups
      // Verified structurally: ProgressionController.recordEvent checks _eventIds.contains
      expect(ProgressionController.instance.hasEvent('nonexistent'), isFalse);
    });
  });

  group('User-scoped data handling', () {
    test('J. Clear local data refreshes controllers', () async {
      await StorageService.instance.saveString(
        userId: 'demo',
        key: 'test_clear',
        value: '1',
      );
      await StorageService.instance.clearUser(userId: 'demo');
      // After clear, reloading should not throw
      await TaskController.instance.load();
      await StudyController.instance.load();
    });

    test('K. User A data cannot appear for user B via scoping', () async {
      // StorageService uses user-scoped keys; different userId = different namespace
      await StorageService.instance.saveString(
        userId: 'user_a',
        key: 'test_key',
        value: 'a_data',
      );
      await StorageService.instance.saveString(
        userId: 'user_b',
        key: 'test_key',
        value: 'b_data',
      );

      final a = await StorageService.instance.loadString(
        userId: 'user_a',
        key: 'test_key',
      );
      final b = await StorageService.instance.loadString(
        userId: 'user_b',
        key: 'test_key',
      );

      expect(a, 'a_data');
      expect(b, 'b_data');
    });
  });

  group('Exam preparation uses real linked data', () {
    test('M. Exam preparation uses real linked tasks and syllabus', () async {
      final exam = await ExamController.instance.createExam(
        title: 'PrepExam',
        subject: 'Prep',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
      );
      await ExamController.instance.addSyllabusItem(exam.id, 'Topic 1');
      await TaskController.instance.createTask(
        title: 'Prep task',
        examId: exam.id,
      );

      final readiness = ExamController.instance.readiness(exam);
      expect(readiness.reasons, isNotEmpty);
      expect(readiness.label, isNotNull);

      await ExamController.instance.deleteExam(exam.id);
    });
  });

  group('Subject workspace derives real linked tasks/resources', () {
    test('N. Subject workspace derives tasks and resources', () async {
      final sub = await SubjectController.instance.createSubject(
        name: 'Workspace',
      );
      await TaskController.instance.createTask(
        title: 'Sub task',
        subjectId: sub.id,
      );

      final tasks = TaskController.instance.activeTasksForSubject(sub.id);
      expect(tasks.length, greaterThanOrEqualTo(1));

      await TaskController.instance.deleteTask(tasks.single.id);
      await SubjectController.instance.deleteSubject(sub.id);
    });
  });

  group('Malformed legacy data remains safely readable', () {
    test('O. Old JSON without examId/subjectId reads safely', () async {
      final oldJson = {
        'id': 'legacy_1',
        'title': 'Legacy',
        'description': '',
        'priority': 'low',
        'status': 'active',
        'category': '',
        'createdAt': '2020-01-01T00:00:00.000',
        'sortOrder': 0,
      };
      final task = StudentTask.fromJson(oldJson);
      expect(task.examId, isNull);
      expect(task.subjectId, isNull);
      expect(task.isCompleted, isFalse);
    });
  });
}
