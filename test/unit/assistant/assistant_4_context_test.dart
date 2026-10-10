import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_context.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_result.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() async {
    ControllerIsolation.instance.clearAllControllers();
  });

  group('AssistantContextSnapshot', () {
    test('captures a valid zero-safe snapshot for a brand-new user', () {
      final snapshot = AssistantContextSnapshot.capture(
        referenceTime: DateTime(2026, 9, 12, 10, 0),
      );

      expect(snapshot.hasCourse, isFalse);
      expect(snapshot.todayBlockCount, 0);
      expect(snapshot.overdueTaskCount, 0);
      expect(snapshot.summaryLine, contains('No plan yet today'));
    });

    test('captures real block, subject and task counts', () async {
      final now = DateTime(2026, 9, 12, 10, 0);
      final sc = SubjectController.instance;
      final pbc = PlanningBlockController.instance;
      final tc = TaskController.instance;

      final subject = await sc.createSubject(name: 'Accountancy');
      await pbc.scheduleBlock(
        null,
        DateTime(2026, 9, 12, 11, 0),
        DateTime(2026, 9, 12, 12, 0),
        subjectId: subject.id,
        customTitle: 'Accountancy Study',
      );
      await tc.createTask(
        title: 'Overdue Assignment',
        dueDate: DateTime(2026, 9, 10),
      );

      final snapshot = AssistantContextSnapshot.capture(referenceTime: now);

      expect(snapshot.hasCourse, isTrue);
      expect(snapshot.todayBlockCount, 1);
      expect(snapshot.todayPlannedMinutes, 60);
      expect(snapshot.overdueTaskCount, 1);
      expect(snapshot.summaryLine, contains('Today'));
      expect(snapshot.summaryLine, contains('1 overdue'));
    });

    test('reports active focus state', () {
      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'Economics',
        objective: 'Microeconomics',
      );

      final snapshot = AssistantContextSnapshot.capture(
        referenceTime: DateTime.now(),
      );

      expect(snapshot.hasActiveFocus, isTrue);
      expect(snapshot.activeFocusObjective, 'Microeconomics');
      expect(snapshot.summaryLine, contains('Focusing on'));
    });
  });

  group('AssistantConversationContext', () {
    test('starts empty and advances a turn with steps', () {
      const empty = AssistantConversationContext.empty;
      expect(empty.isEmpty, isTrue);
      expect(empty.turn, 0);

      final next = empty.nextTurn(
        query: 'What should I do?',
        steps: const [
          AssistantResultStep(label: 'Admission of a Partner', topicId: 't1'),
        ],
      );

      expect(next.turn, 1);
      expect(next.lastQuery, 'What should I do?');
      expect(next.lastSteps.length, 1);
      expect(next.pendingIntent, isNull);
    });

    test('withPendingDuration keeps pending intent and clears on nextTurn', () {
      final pending = const AssistantConversationContext().withPendingDuration(
        const StudentAssistantIntent(
          rawText: 'Plan my day',
          intentType: AssistantIntentType.planTime,
        ),
      );
      expect(pending.pendingIntent, isNotNull);
      expect(pending.pendingIntent?.intentType, AssistantIntentType.planTime);

      final resolved = pending.nextTurn(query: '45 minutes', steps: const []);
      expect(resolved.pendingIntent, isNull);
      expect(resolved.turn, pending.turn + 1);
    });
  });
}
