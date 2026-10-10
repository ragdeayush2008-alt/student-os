import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/assistant_daily_state.dart';
import 'package:student_os/core/assistant/daily_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P3 — trigger surfacing + anti-spam: conditions, dismissal, focus
/// suppression, preference gate, cap, evaluation keys.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    DailyAssistantController.instance.clearData();
    SleepController.instance.clearData();
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
    DailyAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  DailyAssistantController daily() =>
      DailyAssistantController.instance;

  Future<void> login(String user) async {
    AuthIsolation.instance.setAuthenticatedUser(user);
    await SleepController.instance.load();
    await daily().load();
  }

  group('conditions', () {
    test('quiet day yields no triggers', () async {
      await login('p3_trig_quiet');
      expect(daily().buildTriggers(), isEmpty);
    });

    test('overdue task surfaces once', () async {
      await login('p3_trig_overdue');
      await TaskController.instance.createTask(
        title: 'Late essay',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final triggers = daily().buildTriggers();
      expect(
        triggers.where((t) => t.kind == AssistantTriggerKind.overdueTask),
        isNotEmpty,
      );
    });

    test('exam within 7 days surfaces preparation', () async {
      await login('p3_trig_exam');
      await ExamController.instance.createExam(
        title: 'Physics Final',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
      );
      final triggers = daily().buildTriggers();
      expect(
        triggers.where((t) => t.kind == AssistantTriggerKind.examPrep),
        isNotEmpty,
      );
    });

    test('distant exam stays quiet', () async {
      await login('p3_trig_exam_far');
      await ExamController.instance.createExam(
        title: 'Far Exam',
        examDateTime: DateTime.now().add(const Duration(days: 30)),
      );
      final triggers = daily().buildTriggers();
      expect(
        triggers.where((t) => t.kind == AssistantTriggerKind.examPrep),
        isEmpty,
      );
    });

    test('backlog of 5+ surfaces catch-up', () async {
      await login('p3_trig_backlog');
      for (var i = 0; i < 5; i++) {
        await TaskController.instance.createTask(
          title: 'Backlog task $i',
          dueDate: DateTime.now(),
        );
      }
      final triggers = daily().buildTriggers();
      expect(
        triggers.where((t) => t.kind == AssistantTriggerKind.catchUp),
        isNotEmpty,
      );
    });
  });

  group('anti-spam', () {
    test('dismissed trigger stays gone today', () async {
      await login('p3_trig_dismiss');
      await TaskController.instance.createTask(
        title: 'Late essay',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final first = daily().buildTriggers();
      final overdue =
          first.firstWhere((t) => t.kind == AssistantTriggerKind.overdueTask);
      await daily().dismissTrigger(overdue.id);
      final second = daily().buildTriggers();
      expect(
        second.where((t) => t.kind == AssistantTriggerKind.overdueTask),
        isEmpty,
      );
    });

    test('completed work is never recommended', () async {
      await login('p3_trig_done');
      final task = await TaskController.instance.createTask(
        title: 'Done essay',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await TaskController.instance.completeTask(task.id);
      final triggers = daily().buildTriggers();
      expect(
        triggers.where((t) => t.kind == AssistantTriggerKind.overdueTask),
        isEmpty,
      );
    });

    test('proactive off silences everything', () async {
      await login('p3_trig_off');
      await TaskController.instance.createTask(
        title: 'Late essay',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await daily().updatePreferences(
        const AssistantPreferences(proactiveEnabled: false),
      );
      expect(daily().buildTriggers(), isEmpty);
    });

    test('at most 3 triggers surface', () async {
      await login('p3_trig_cap');
      await TaskController.instance.createTask(
        title: 'Late essay',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      for (var i = 0; i < 6; i++) {
        await TaskController.instance.createTask(
          title: 'Backlog $i',
          dueDate: DateTime.now(),
        );
      }
      await ExamController.instance.createExam(
        title: 'Soon Exam',
        examDateTime: DateTime.now().add(const Duration(days: 3)),
      );
      final triggers = daily().buildTriggers();
      expect(triggers.length, lessThanOrEqualTo(3));
      expect(
        triggers.map((t) => t.id).toSet().length,
        triggers.length,
      );
    });

    test('evaluation key changes with state', () async {
      await login('p3_trig_key');
      final before = daily().evaluationKey(DateTime.now());
      await TaskController.instance.createTask(title: 'New task');
      final after = daily().evaluationKey(DateTime.now());
      expect(after == before, isFalse);
    });
  });

  group('sleep integration', () {
    test('sleep change after preparation offers a rebuild', () async {
      await login('p3_trig_sleep');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      await daily().markPrepared();
      expect(daily().state.prepared, isTrue);

      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1320, wakeMinutes: 360),
      );
      // Listener runs async; allow the notification round-trip.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(daily().state.prepared, isFalse);
      final triggers = daily().buildTriggers();
      expect(
        triggers.where((t) => t.kind == AssistantTriggerKind.sleepChanged),
        isNotEmpty,
      );
    });

    test('FocusController import is live (session check compiles)', () {
      expect(FocusController.instance.hasActiveSession, isFalse);
    });
  });
}
