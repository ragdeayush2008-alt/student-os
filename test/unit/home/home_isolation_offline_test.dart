import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/planning/models/planning_block.dart';

StudentTask _task(String id, String title) => StudentTask(
      id: id,
      title: title,
      status: TaskStatus.active,
    );

void main() {
  group('Home 2.0 isolation / budget / offline (CODE 5)', () {
    final ref = DateTime(2026, 9, 15, 9, 0);

    test('available-time changes flip overload state deterministically', () {
      final blocks = [
        PlanningBlock(
          id: 'pb1',
          userId: 'u1',
          subjectId: 's1',
          startAt: DateTime(2026, 9, 15, 8, 0),
          endAt: DateTime(2026, 9, 15, 11, 0),
        ),
      ];
      final tight = StudentOSIntelligenceEngine.computeDailyStudentState(
        subjects: [Subject(id: 's1', name: 'Physics')],
        blocks: blocks,
        availableBudgetMinutes: 60,
        referenceTime: ref,
      );
      final roomy = StudentOSIntelligenceEngine.computeDailyStudentState(
        subjects: [Subject(id: 's1', name: 'Physics')],
        blocks: blocks,
        availableBudgetMinutes: 300,
        referenceTime: ref,
      );
      expect(tight.workloadState, equals(WorkloadState.overloaded));
      expect(roomy.workloadState, isNot(equals(WorkloadState.overloaded)));
      expect(tight.plannedMinutes, equals(roomy.plannedMinutes));
    });

    test('user isolation: User A tasks never leak into User B recommendation', () {
      final actionA = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 's_bio', name: 'Biology')],
        tasks: [_task('t_a', 'User A Biology Research')],
        referenceTime: ref,
      );
      expect(actionA.title, contains('User A'));

      final actionB = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 's_chem', name: 'Chemistry')],
        tasks: [_task('t_b', 'User B Chemistry Notes')],
        referenceTime: ref,
      );
      expect(actionB.title, isNot(contains('User A')));
      expect(actionB.title, contains('User B'));
    });

    test('offline / empty inputs never throw and yield safe defaults', () {
      expect(
        () => StudentOSIntelligenceEngine.computeDailyStudentState(
          subjects: const [],
          referenceTime: ref,
        ),
        returnsNormally,
      );
      final state = StudentOSIntelligenceEngine.computeDailyStudentState(
        subjects: const [],
        referenceTime: ref,
      );
      expect(state.plannedMinutes, equals(0));
      expect(state.overdueTasksCount, equals(0));

      expect(
        () => StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
          subjects: const [],
          referenceTime: ref,
        ),
        returnsNormally,
      );
      expect(
        () => StudentOSIntelligenceEngine.detectAcademicRisks(
          subjects: const [],
          referenceTime: ref,
        ),
        returnsNormally,
      );
    });

    test('overdue + completed mix counts only active overdue', () {
      final done = StudentTask(
        id: 't_done',
        title: 'Done',
        status: TaskStatus.completed,
        dueDate: DateTime(2026, 9, 10),
      );
      final state = StudentOSIntelligenceEngine.computeDailyStudentState(
        subjects: [Subject(id: 's1', name: 'Maths')],
        tasks: [done],
        referenceTime: ref,
      );
      expect(state.overdueTasksCount, equals(0));
    });
  });
}
