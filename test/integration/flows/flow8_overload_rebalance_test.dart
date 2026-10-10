import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// PART27 FLOW 8: Overloaded day → rebalance → safe rescheduling.
///
/// Anchored on an explicit target day with an explicit reference time, so the
/// flow is deterministic at any wall-clock hour (including near midnight).
/// Verifies [PlanningEngine.rebalanceOverloadedDay] only moves future blocks,
/// preserves durations/context/ids, never touches past blocks, and clears
/// the overload state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime targetDay;
  late DateTime ref;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('flow8_user');
    await StorageService.instance.clearUser(userId: 'flow8_user');
    ControllerIsolation.instance.clearAllControllers();

    final now = DateTime.now();
    targetDay =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    ref = DateTime(targetDay.year, targetDay.month, targetDay.day, 7, 0);
  });

  tearDown(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  DateTime at(int hour, [int minute = 0]) =>
      DateTime(targetDay.year, targetDay.month, targetDay.day, hour, minute);

  test('rebalance moves only future blocks and clears overload', () async {
    final sub = await SubjectController.instance.createSubject(name: 'Maths');

    final blocks = <PlanningBlock>[];
    for (var i = 0; i < 5; i++) {
      final s = at(8 + i);
      blocks.add(
        await PlanningBlockController.instance.scheduleSubjectBlock(
          sub.id,
          s,
          s.add(const Duration(hours: 1)),
          customTitle: 'Block $i',
        ),
      );
    }
    final originalIds = blocks.map((b) => b.id).toSet();

    // 300 planned vs 60 budget → overloaded.
    var state = StudentOSIntelligenceEngine.computeDailyStudentState(
      subjects: SubjectController.instance.activeSubjects,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocksForDay(targetDay),
      availableBudgetMinutes: 60,
      referenceTime: ref,
    );
    expect(state.workloadState, WorkloadState.overloaded);

    final moved = await PlanningEngine.rebalanceOverloadedDay(
      targetDay,
      tasks: TaskController.instance.tasks,
      availableMinutes: 60,
      referenceTime: ref,
    );
    expect(moved, greaterThan(0));

    // Same blocks (ids preserved), durations + context intact.
    final after = PlanningBlockController.instance.blocks;
    expect(after.map((b) => b.id).toSet(), originalIds);
    for (final b in after) {
      expect(b.endAt.difference(b.startAt).inMinutes, 60);
      expect(b.subjectId, sub.id);
    }

    // Target day is no longer overloaded.
    state = StudentOSIntelligenceEngine.computeDailyStudentState(
      subjects: SubjectController.instance.activeSubjects,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocksForDay(targetDay),
      availableBudgetMinutes: 60,
      referenceTime: ref,
    );
    expect(state.workloadState, isNot(WorkloadState.overloaded));
  });

  test('rebalance never moves blocks that already started', () async {
    final sub =
        await SubjectController.instance.createSubject(name: 'Science');

    final pastStart = ref.subtract(const Duration(hours: 2));
    final past = await PlanningBlockController.instance.scheduleSubjectBlock(
      sub.id,
      pastStart,
      pastStart.add(const Duration(hours: 1)),
      customTitle: 'Past block',
    );
    final futureStart = ref.add(const Duration(hours: 1));
    await PlanningBlockController.instance.scheduleSubjectBlock(
      sub.id,
      futureStart,
      futureStart.add(const Duration(hours: 3)),
      customTitle: 'Future block',
    );

    await PlanningEngine.rebalanceOverloadedDay(
      targetDay,
      tasks: TaskController.instance.tasks,
      availableMinutes: 60,
      referenceTime: ref,
    );

    final pastAfter = PlanningBlockController.instance.blocks
        .firstWhere((b) => b.id == past.id);
    expect(pastAfter.startAt, past.startAt);
    expect(pastAfter.endAt, past.endAt);
  });
}
