import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/planning/models/planning_block.dart';

Subject _subject(String id, String name) => Subject(id: id, name: name);

StudentTask _task(String id, String title, {DateTime? dueDate}) {
  return StudentTask(
    id: id,
    title: title,
    status: TaskStatus.active,
    dueDate: dueDate,
  );
}

void main() {
  group('Home 2.0 hero states (CODE 5, engine-driven)', () {
    final ref = DateTime(2026, 9, 15, 9, 0);

    test('A) nothing started: empty state recommends planning, not fake data', () {
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: const [],
        referenceTime: ref,
      );
      expect(action.type, equals(StudentOSActionType.empty));
      expect(action.title, equals('All Caught Up'));
      expect(action.suggestedDurationMinutes, equals(0));
    });

    test('B) day started: current scheduled block is recommended', () {
      final block = PlanningBlock(
        id: 'pb1',
        userId: 'u1',
        subjectId: 's1',
        startAt: DateTime(2026, 9, 15, 8, 30),
        endAt: DateTime(2026, 9, 15, 9, 30),
      );
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [_subject('s1', 'Physics')],
        blocks: [block],
        referenceTime: ref,
      );
      expect(action.type, equals(StudentOSActionType.scheduledBlock));
      expect(action.subjectId, equals('s1'));
      expect(action.suggestedDurationMinutes, greaterThan(0));
    });

    test('C) focus active takes top priority (continue, never duplicate)', () {
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [_subject('s1', 'Physics')],
        tasks: [_task('t1', 'Homework')],
        hasActiveFocus: true,
        activeFocusObjective: 'Physics — Laws of Motion',
        activeFocusRemaining: const Duration(minutes: 20),
        referenceTime: ref,
      );
      expect(action.type, equals(StudentOSActionType.focusActive));
      expect(action.isFocusActive, isTrue);
      expect(action.title, equals('Physics — Laws of Motion'));
    });

    test('D) overloaded day detected via daily state', () {
      final blocks = [
        PlanningBlock(
          id: 'pb1',
          userId: 'u1',
          subjectId: 's1',
          startAt: DateTime(2026, 9, 15, 8, 0),
          endAt: DateTime(2026, 9, 15, 13, 0),
        ),
      ];
      final state = StudentOSIntelligenceEngine.computeDailyStudentState(
        subjects: [_subject('s1', 'Physics')],
        blocks: blocks,
        availableBudgetMinutes: 60,
        referenceTime: ref,
      );
      expect(state.workloadState, equals(WorkloadState.overloaded));
      expect(state.overloadMinutes, greaterThan(0));
      expect(state.plannedMinutes, equals(300));
    });

    test('E) recovery needed: overdue task outranks routine work', () {
      final overdue = _task(
        't_over',
        'Overdue worksheet',
        dueDate: DateTime(2026, 9, 10, 12, 0),
      );
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [_subject('s1', 'Maths')],
        tasks: [overdue],
        referenceTime: ref,
      );
      expect(action.type, equals(StudentOSActionType.completeTask));
      expect(action.taskId, equals('t_over'));
      expect(action.urgency, equals(RecommendationUrgency.critical));
    });

    test('no recommendation: deterministic all-caught-up with plan guidance', () {
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [_subject('s1', 'Art')],
        referenceTime: ref,
      );
      // Either a study recommendation or clean empty state — both valid,
      // but empty guidance must mention planning, never fake content.
      if (action.type == StudentOSActionType.empty) {
        expect(
          action.bulletReasons.join(' ').toLowerCase(),
          contains('plan'),
        );
      } else {
        expect(action.suggestedDurationMinutes, greaterThan(0));
      }
    });

    test('recommendation carries deterministic WHY reasons', () {
      final overdue = _task(
        't_over2',
        'Overdue lab report',
        dueDate: DateTime(2026, 9, 10, 12, 0),
      );
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [_subject('s1', 'Chemistry')],
        tasks: [overdue],
        referenceTime: ref,
      );
      expect(action.reason, isNotEmpty);
      expect(action.bulletReasons, isNotEmpty);
    });

    test('today overview aggregates planned/completed/remaining/overdue', () {
      // Dynamic dates: due-today stays in the future relative to real now
      // (isOverdue uses wall-clock), overdue is fixed in the past.
      final nowReal = DateTime.now();
      final dueToday = nowReal.add(const Duration(hours: 4));
      final refToday =
          DateTime(dueToday.year, dueToday.month, dueToday.day, 9, 0);
      final state = StudentOSIntelligenceEngine.computeDailyStudentState(
        subjects: [_subject('s1', 'Bio')],
        tasks: [
          _task('t1', 'Due today', dueDate: dueToday),
          _task('t2', 'Overdue', dueDate: DateTime(2020, 1, 5, 12, 0)),
        ],
        availableBudgetMinutes: 180,
        referenceTime: refToday,
      );
      expect(state.tasksDueTodayCount, equals(1));
      expect(state.overdueTasksCount, equals(1));
      expect(state.availableMinutes, equals(180));
      expect(state.remainingMinutes, greaterThanOrEqualTo(0));
    });
  });
}
