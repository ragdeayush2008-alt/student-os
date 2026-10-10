import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/autopilot_engine.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/models/planning_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudentOSAutopilotEngine Unit Tests', () {
    final now = DateTime(2026, 9, 12, 10, 0); // 10:00 AM
    final today = DateTime(now.year, now.month, now.day);

    final subAccounts = Subject(id: 'sub_acc', name: 'Accountancy');
    final subLaw = Subject(id: 'sub_law', name: 'Business Law');

    tearDown(() {
      if (FocusController.instance.hasActiveSession) {
        FocusController.instance.cancelSession();
      }
      FocusController.instance.clearData();
    });

    test('1. Empty schedule evaluates to DayHealthState.clear', () {
      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: today,
        subjects: [subAccounts, subLaw],
        tasks: const [],
        blocks: const [],
        sessions: const [],
        availableBudgetMinutes: 180,
        referenceTime: now,
      );

      expect(state.healthState, DayHealthState.clear);
      expect(state.plannedMinutes, 0);
      expect(state.completedMinutes, 0);
      expect(state.isOverloaded, isFalse);
    });

    test('2. Planned work within budget evaluates to DayHealthState.onTrack', () {
      final block = PlanningBlock(
        id: 'b1',
        userId: 'test_user',
        subjectId: subAccounts.id,
        startAt: DateTime(today.year, today.month, today.day, 11, 0),
        endAt: DateTime(today.year, today.month, today.day, 11, 45), // 45 min
      );

      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: today,
        subjects: [subAccounts],
        tasks: const [],
        blocks: [block],
        sessions: const [],
        availableBudgetMinutes: 180,
        referenceTime: now,
      );

      expect(state.healthState, DayHealthState.onTrack);
      expect(state.plannedMinutes, 45);
      expect(state.remainingMinutes, 45);
      expect(state.isOverloaded, isFalse);
    });

    test('3. Planned work >= 75% of budget evaluates to DayHealthState.busy', () {
      final block = PlanningBlock(
        id: 'b1',
        userId: 'test_user',
        subjectId: subAccounts.id,
        startAt: DateTime(today.year, today.month, today.day, 11, 0),
        endAt: DateTime(today.year, today.month, today.day, 13, 30), // 150 min in 180m budget (>75%)
      );

      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: today,
        subjects: [subAccounts],
        tasks: const [],
        blocks: [block],
        sessions: const [],
        availableBudgetMinutes: 180,
        referenceTime: now,
      );

      expect(state.healthState, DayHealthState.busy);
      expect(state.plannedMinutes, 150);
      expect(state.isOverloaded, isFalse);
    });

    test('4. Planned work exceeding budget evaluates to DayHealthState.overloaded', () {
      final block = PlanningBlock(
        id: 'b1',
        userId: 'test_user',
        subjectId: subAccounts.id,
        startAt: DateTime(today.year, today.month, today.day, 11, 0),
        endAt: DateTime(today.year, today.month, today.day, 15, 0), // 240 min in 180m budget
      );

      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: today,
        subjects: [subAccounts],
        tasks: const [],
        blocks: [block],
        sessions: const [],
        availableBudgetMinutes: 180,
        referenceTime: now,
      );

      expect(state.healthState, DayHealthState.overloaded);
      expect(state.plannedMinutes, 240);
      expect(state.isOverloaded, isTrue);
      expect(state.overloadMinutes, 60);
    });

    test('5. Missed planning blocks evaluate to DayHealthState.recoveryNeeded', () {
      final pastBlock = PlanningBlock(
        id: 'b_past',
        userId: 'test_user',
        subjectId: subAccounts.id,
        startAt: DateTime(today.year, today.month, today.day, 8, 0),
        endAt: DateTime(today.year, today.month, today.day, 8, 45), // passed at 10:00
      );

      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: today,
        subjects: [subAccounts],
        tasks: const [],
        blocks: [pastBlock],
        sessions: const [],
        availableBudgetMinutes: 180,
        referenceTime: now,
      );

      expect(state.healthState, DayHealthState.recoveryNeeded);
      expect(state.recoverySessions.length, 1);
      expect(state.recoverySessions.first.block.id, pastBlock.id);
    });

    test('6. "Start My Day" selects first uncompleted planned block with assigned duration', () {
      final block1 = PlanningBlock(
        id: 'b1',
        userId: 'test_user',
        subjectId: subAccounts.id,
        startAt: DateTime(today.year, today.month, today.day, 10, 30),
        endAt: DateTime(today.year, today.month, today.day, 11, 15), // 45 min
        customTitle: 'Accountancy Prep',
      );

      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: today,
        subjects: [subAccounts],
        tasks: const [],
        blocks: [block1],
        sessions: const [],
        availableBudgetMinutes: 180,
        referenceTime: now,
      );

      final startAction = state.startMyDayAction;
      expect(startAction.title, 'Accountancy Prep');
      expect(startAction.suggestedDurationMinutes, 45);
      expect(startAction.type, StudentOSActionType.scheduledBlock);
    });

    test('7. "Continue My Day" derives next upcoming scheduled block', () {
      final blockUpcoming = PlanningBlock(
        id: 'b2',
        userId: 'test_user',
        subjectId: subLaw.id,
        startAt: DateTime(today.year, today.month, today.day, 11, 30),
        endAt: DateTime(today.year, today.month, today.day, 12, 5), // 35 min
        customTitle: 'Business Law',
      );

      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: today,
        subjects: [subAccounts, subLaw],
        tasks: const [],
        blocks: [blockUpcoming],
        sessions: const [],
        availableBudgetMinutes: 180,
        referenceTime: now,
      );

      expect(state.continueMyDayAction, isNotNull);
      expect(state.continueMyDayAction!.title, 'Business Law');
      expect(state.continueMyDayAction!.suggestedDurationMinutes, 35);
    });

    test('8. Done for Today state marks day clear and stops generating work items', () {
      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: today,
        subjects: [subAccounts],
        tasks: const [],
        blocks: const [],
        sessions: const [],
        isDoneForToday: true,
        referenceTime: now,
      );

      expect(state.isDoneForToday, isTrue);
      expect(state.healthState, DayHealthState.clear);
      expect(state.nextAction.type, StudentOSActionType.doneForToday);
    });

    test('9. Early completion Opportunity detected when finished earlier than planned benchmark', () {
      final finishedSession = StudySession(
        id: 's1',
        subject: 'Accountancy',
        startedAt: DateTime(today.year, today.month, today.day, 9, 0),
        durationSec: 1200, // 20 min actual in 35 min slot (15m freed)
        completed: true,
      );

      final state = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: today,
        subjects: [subAccounts],
        tasks: const [],
        blocks: const [],
        sessions: [finishedSession],
        referenceTime: now,
      );

      expect(state.hasEarlyCompletion, isTrue);
      expect(state.earlyCompletion!.freedMinutes, 15);
      expect(state.earlyCompletion!.completedSubjectName, 'Accountancy');
    });
  });
}
