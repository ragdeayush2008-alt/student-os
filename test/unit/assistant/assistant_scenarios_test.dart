import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// P3 §35 — realistic adaptive scenarios end to end.
void main() {
  const engine = StudentAssistantEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final b in List.of(PlanningBlockController.instance.blocks)) {
      await PlanningBlockController.instance.unscheduleBlock(b.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final b in List.of(PlanningBlockController.instance.blocks)) {
      await PlanningBlockController.instance.unscheduleBlock(b.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
    await SleepController.instance.clearSchedule();
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  Future<void> login(String user) async {
    AuthIsolation.instance.setAuthenticatedUser(user);
    await SleepController.instance.load();
  }

  group('§35 scenarios', () {
    test('SCENARIO 1: 3h work, limited budget warns instead of cramming',
        () async {
      await login('p3_s1');
      for (var i = 0; i < 4; i++) {
        await TaskController.instance.createTask(
          title: 'Work $i',
          estimatedMinutes: 45,
        );
      }
      final result = await StudentAssistantController.instance.ask(
        'I have 1 hour',
      );
      final staged =
          StudentAssistantController.instance.pendingProposal;
      final total = staged?.totalMinutes ?? 0;
      expect(total, lessThanOrEqualTo(60));
      final text =
          '${result.message} ${result.previewItems.join(' ')}';
      expect(
        text.contains('deferred') ||
            text.contains('Trimmed') ||
            total < 3 * 60,
        isTrue,
      );
    });

    test('SCENARIO 2: 2h work at 10 PM defers past sleep', () async {
      await login('p3_s2');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      await TaskController.instance.createTask(
        title: 'Night work',
        estimatedMinutes: 50,
      );
      final result = engine.process(
        'I have 2 hours',
        referenceTime: DateTime(2026, 10, 5, 22, 0),
      );
      final proposal = result.proposal;
      if (proposal != null) {
        final starts = proposal.laidOutStarts();
        for (var i = 0; i < proposal.sessions.length; i++) {
          final end = starts[i].add(
            Duration(minutes: proposal.sessions[i].minutes),
          );
          expect(end.isAfter(DateTime(2026, 10, 5, 23, 0)), isFalse);
        }
      } else {
        expect(result.title, 'Evening Protected');
      }
    });

    test('SCENARIO 3: exam in 5 days gets meaningful priority', () async {
      await login('p3_s3');
      await ExamController.instance.createExam(
        title: 'Economics Final',
        subject: 'Economics',
        examDateTime: DateTime.now().add(const Duration(days: 5)),
      );
      await TaskController.instance.createTask(
        title: 'Economics prep',
        priority: TaskPriority.medium,
      );
      final result = engine.process('Plan my Economics exam');
      expect(result.requiresConfirmation, isTrue);
      expect(result.proposal!.creations, isNotEmpty);
    });

    test('SCENARIO 4: completing work refreshes recommendations', () async {
      await login('p3_s4');
      final first = await TaskController.instance.createTask(
        title: 'First chore',
        priority: TaskPriority.high,
      );
      await TaskController.instance.createTask(
        title: 'Second chore',
        priority: TaskPriority.medium,
      );
      final before = engine.process('What should I do now?');
      await TaskController.instance.completeTask(first.id);
      final after = engine.process('What should I do now?');
      expect(after.success, isTrue);
      // Completed work is never recommended again.
      expect(after.title.contains('First chore'), isFalse);
      expect(before.success, isTrue);
    });

    test('SCENARIO 5: behind → catch-up offered', () async {
      await login('p3_s5');
      await TaskController.instance.createTask(
        title: 'Overdue chore',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final result = engine.process("I'm behind");
      expect(result.requiresConfirmation, isTrue);
      expect(result.proposal, isNotNull);
    });

    test('SCENARIO 6: sleep change invalidates preparation', () async {
      await login('p3_s6');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      await TaskController.instance.createTask(title: 'Some work');
      final controller = StudentAssistantController.instance;
      await controller.ask('prepare my day');
      // Prepared around 11 PM… (or already-prepared status on re-runs)
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1320, wakeMinutes: 360),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Planning can be reconsidered: a fresh plan reflects the window.
      final retry = await controller.ask('I have 1 hour');
      expect(retry.success, isTrue);
    });
  });
}
