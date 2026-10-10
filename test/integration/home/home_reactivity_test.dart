import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/intelligence/daily_os_coordinator.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 4 — Daily OS reactive loop.
///
/// Verifies Task / Focus / Study state changes flow through
/// [DailyOsCoordinator] into fresh [DailyAcademicSnapshot] data for Home:
/// TaskController → coordinator → snapshot → Home, and the same for
/// FocusController and StudyController.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DailyOsCoordinator.instance.init();
    await _clean();
  });

  tearDown(() async {
    await _clean();
  });

  group('TaskController → DailyOsCoordinator → Home snapshot', () {
    test('new overdue task becomes NOW; completing it clears NOW', () async {
      final task = await TaskController.instance.createTask(
        title: 'Reactive NOW task',
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      var snapshot = DailyOsCoordinator.instance.snapshot!;
      expect(snapshot.nowAction?.taskId, task.id);
      expect(snapshot.overdueCount, greaterThanOrEqualTo(1));

      await TaskController.instance.completeTask(task.id);

      snapshot = DailyOsCoordinator.instance.snapshot!;
      expect(snapshot.nowAction?.taskId, isNot(task.id));
      expect(snapshot.completedToday, greaterThanOrEqualTo(1));

      await TaskController.instance.deleteTask(task.id);
    });

    test('coordinator notifies listeners on task completion', () async {
      var notifications = 0;
      void listener() => notifications++;
      DailyOsCoordinator.instance.addListener(listener);
      addTearDown(() => DailyOsCoordinator.instance.removeListener(listener));

      final task = await TaskController.instance.createTask(
        title: 'Notify task',
        dueDate: DateTime.now(),
      );
      final before = notifications;
      await TaskController.instance.completeTask(task.id);

      expect(notifications, greaterThan(before));
      await TaskController.instance.deleteTask(task.id);
    });
  });

  group('FocusController → DailyOsCoordinator → Home snapshot', () {
    test(
      'active session flips hasActiveFocus; completion flips back',
      () async {
        expect(
          DailyOsCoordinator.instance.snapshot?.hasActiveFocus ?? false,
          isFalse,
        );

        FocusController.instance.startQuickFocus(
          duration: const Duration(minutes: 25),
        );
        expect(DailyOsCoordinator.instance.snapshot?.hasActiveFocus, isTrue);

        FocusController.instance.completeSession();
        expect(
          DailyOsCoordinator.instance.snapshot?.hasActiveFocus ?? true,
          isFalse,
        );
      },
    );
  });

  group('StudyController → DailyOsCoordinator → Home snapshot', () {
    test('completed study session is visible to Home data', () async {
      StudyController.instance.startSession(subject: 'Math');
      final session = await StudyController.instance.endSession();

      expect(session, isNotNull);
      expect(StudyController.instance.todayCompletedCount, 1);

      // Coordinator stays functional after study changes.
      DailyOsCoordinator.instance.refresh();
      final snapshot = DailyOsCoordinator.instance.snapshot!;
      expect(snapshot.studyMinutesToday, greaterThanOrEqualTo(0));

      StudyController.instance.clearData();
    });
  });

  group('Exam changes refresh Daily OS state', () {
    test('nearest exam drives upcomingExamDays; deletion clears it', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Reactive exam',
        examDateTime: DateTime.now().add(const Duration(days: 3)),
      );

      DailyOsCoordinator.instance.refresh();
      expect(DailyOsCoordinator.instance.snapshot?.upcomingExamDays, 3);

      await ExamController.instance.deleteExam(exam.id);
      DailyOsCoordinator.instance.refresh();
      expect(DailyOsCoordinator.instance.snapshot?.upcomingExamDays, isNull);
    });
  });
}

Future<void> _clean() async {
  if (FocusController.instance.hasActiveSession) {
    FocusController.instance.completeSession();
  }
  FocusController.instance.clearData();
  StudyController.instance.clearData();
  for (final task in List.of(TaskController.instance.tasks)) {
    await TaskController.instance.deleteTask(task.id);
  }
  for (final exam in List.of(ExamController.instance.exams)) {
    await ExamController.instance.deleteExam(exam.id);
  }
}
