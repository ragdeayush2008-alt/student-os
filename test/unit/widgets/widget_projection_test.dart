import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';
import 'package:student_os/features/widgets/services/widget_data_service.dart';

/// Projection: real controller data lands in the snapshot; empty domains
/// degrade to nulls (native empty states), never invented values.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
    await SleepController.instance.clearSchedule();
    AuthIsolation.instance.clearSession();
    SleepController.instance.clearData();
  });

  WidgetDataService service() => WidgetDataService.instance;

  group('exam projections', () {
    test('next exam carries countdown + window', () async {
      AuthIsolation.instance.setAuthenticatedUser('w_proj_exam');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await ExamController.instance.createExam(
        title: 'Accounts Final',
        subject: 'Accounts',
        examDateTime: today.add(const Duration(days: 9)),
      );

      final snap = service().buildSnapshot('w_proj_exam', now);
      expect(snap.nextExam?.title, 'Accounts Final');
      expect(snap.nextExam?.daysLeft, 9);
      expect(snap.nextExam?.windowDays, 10);
      expect(snap.upcomingExams.length, 1);
    });

    test('no exams projects nulls (native empty state)', () async {
      AuthIsolation.instance.setAuthenticatedUser('w_proj_empty');
      final snap = service().buildSnapshot('w_proj_empty', DateTime.now());
      expect(snap.nextExam, isNull);
      expect(snap.upcomingExams, isEmpty);
      expect(snap.examPrep, isNull);
    });

    test('exam prep surfaces nearest exam task target', () async {
      AuthIsolation.instance.setAuthenticatedUser('w_proj_prep');
      final exam = await ExamController.instance.createExam(
        title: 'Physics Final',
        examDateTime: DateTime.now().add(const Duration(days: 6)),
      );
      await TaskController.instance.createTask(
        title: 'Revise chapters',
        examId: exam.id,
        estimatedMinutes: 45,
      );

      final snap = service().buildSnapshot('w_proj_prep', DateTime.now());
      expect(snap.examPrep?.examId, exam.id);
      expect(snap.examPrep?.daysLeft, 6);
      expect(snap.examPrep?.targetTitle, 'Revise chapters');
      expect(snap.examPrep?.targetMinutes, 45);
    });
  });

  group('task projections', () {
    test('today counts + top priority from real ranking', () async {
      AuthIsolation.instance.setAuthenticatedUser('w_proj_tasks');
      await TaskController.instance.createTask(
        title: 'Overdue essay',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        priority: TaskPriority.high,
      );
      await TaskController.instance.createTask(title: 'Inbox note');

      final snap = service().buildSnapshot('w_proj_tasks', DateTime.now());
      expect(snap.todayTasks, isNotNull);
      expect(snap.todayTasks!.remaining, greaterThanOrEqualTo(1));
      expect(snap.todayTasks!.topTitle, isNotNull);
      expect(snap.nextAction, isNotNull);
      expect(snap.nextAction!.title, isNotEmpty);
      expect(snap.backlog!.overdue, greaterThanOrEqualTo(1));
    });

    test('empty tasks degrade cleanly', () async {
      AuthIsolation.instance.setAuthenticatedUser('w_proj_tasks_empty');
      final snap =
          service().buildSnapshot('w_proj_tasks_empty', DateTime.now());
      expect(snap.todayTasks!.remaining, 0);
      expect(snap.nextAction, isNull);
      expect(snap.assistant, isNull);
    });
  });

  group('sleep projection', () {
    test('enabled schedule projects labels', () async {
      AuthIsolation.instance.setAuthenticatedUser('w_proj_sleep');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      final snap = service().buildSnapshot('w_proj_sleep', DateTime.now());
      expect(snap.sleep?.bedtimeLabel, '11 PM');
      expect(snap.sleep?.wakeLabel, '7 AM');
      expect(snap.sleep?.durationLabel, '8h');
      expect(snap.dayBalance?.sleepLabel, contains('11 PM'));
    });

    test('missing schedule projects null', () async {
      AuthIsolation.instance.setAuthenticatedUser('w_proj_nosleep');
      final snap =
          service().buildSnapshot('w_proj_nosleep', DateTime.now());
      expect(snap.sleep, isNull);
    });
  });

  group('malformed domains never blank the snapshot', () {
    test('buildSnapshot survives empty identity', () {
      final snap = service().buildSnapshot('', DateTime.now());
      expect(snap.userId, '');
    });
  });
}
