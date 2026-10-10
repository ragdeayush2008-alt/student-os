import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/core/services/streak_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// PART27 FLOW 1: Task → Schedule → PlanningBlock → Focus → complete Focus
/// → StudySession → Analytics.
///
/// Verifies the Code 6 Focus→Study bridge: one underlying event produces
/// consistent Focus history, study ledger, daily progress, streak, and XP
/// with no double-counting, and the task is NOT auto-completed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('flow1_user');
    await StorageService.instance.clearUser(userId: 'flow1_user');
    ControllerIsolation.instance.clearAllControllers();
    FocusController.instance.resetClockForTesting();
  });

  tearDown(() {
    FocusController.instance.resetClockForTesting();
    FocusController.instance.clearData();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  test('task to analytics chain stays consistent', () async {
    // 1. Task with full academic context.
    final sub =
        await SubjectController.instance.createSubject(name: 'Physics');
    final task = await TaskController.instance.createTask(
      title: 'Laws of Motion worksheet',
      subjectId: sub.id,
      estimatedMinutes: 45,
    );

    // 2. Schedule → PlanningBlock preserves context + duration.
    final start = DateTime.now().add(const Duration(minutes: 5));
    final block = await PlanningBlockController.instance.scheduleBlock(
      task.id,
      start,
      start.add(const Duration(minutes: 45)),
      subjectId: sub.id,
      topicId: 'topic_laws',
      chapterId: 'ch_mech',
    );
    expect(block.taskId, task.id);
    expect(block.topicId, 'topic_laws');
    expect(block.endAt.difference(block.startAt).inMinutes, 45);

    // 3. Focus with the block's full context (mirrors startPlanningBlockFocus).
    final fc = FocusController.instance;
    var now = DateTime.now();
    fc.setClockForTesting(() => now);
    fc.startTimer(
      duration: const Duration(minutes: 45),
      subjectId: block.subjectId,
      subjectName: sub.displayName,
      taskId: block.taskId,
      topicId: block.topicId,
      chapterId: block.chapterId,
      planningBlockId: block.id,
      objective: task.title,
    );
    expect(fc.hasActiveSession, isTrue);
    final sessionId = fc.activeSession!.id;

    // 4. Complete after the full duration.
    now = now.add(const Duration(minutes: 45));
    fc.completeSession();
    expect(fc.hasActiveSession, isFalse);
    expect(
      fc.sessions.where((s) => s.id == sessionId).single.outcome,
      SessionOutcome.completed,
    );

    // 5. ONE bridged StudySession carries the full context.
    final bridged = StudyController.instance.sessions
        .where((s) => s.focusSessionId == sessionId)
        .toList();
    expect(bridged.length, 1);
    final study = bridged.single;
    expect(study.taskId, task.id);
    expect(study.subjectId, sub.id);
    expect(study.topicId, 'topic_laws');
    expect(study.chapterId, 'ch_mech');
    expect(study.isCompleted, isTrue);
    expect(study.durationSec, 45 * 60);

    // 6. Re-bridging the same focus session never duplicates.
    final again = await StudyController.instance.recordFocusCompletion(
      focusSessionId: sessionId,
      subject: 'Physics',
      durationSec: 45 * 60,
    );
    expect(again.id, study.id);
    expect(
      StudyController.instance.sessions
          .where((s) => s.focusSessionId == sessionId)
          .length,
      1,
    );

    // 7. Daily analytics reflect the 45 completed minutes.
    final state = StudentOSIntelligenceEngine.computeDailyStudentState(
      subjects: SubjectController.instance.activeSubjects,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
    );
    expect(state.completedMinutes, 45);

    // 8. Streak counts today via the bridged session.
    expect(StreakService.instance.activityToday, isTrue);
    expect(StreakService.instance.currentStreak, greaterThanOrEqualTo(1));

    // 9. XP awarded exactly once for the focus session.
    final xpEvents = ProgressionController.instance.events
        .where((e) => e.id.contains(sessionId))
        .toList();
    expect(xpEvents.length, 1);

    // 10. Task was NOT auto-completed by Focus completion.
    final taskAfter = TaskController.instance.tasks
        .firstWhere((t) => t.id == task.id);
    expect(taskAfter.isCompleted, isFalse);
  });

  test('abandoned focus is recorded but excluded from study metrics',
      () async {
    final fc = FocusController.instance;
    var now = DateTime.now();
    fc.setClockForTesting(() => now);
    fc.startTimer(
      duration: const Duration(minutes: 30),
      subjectName: 'Chemistry',
      objective: 'Abandoned run',
    );
    final sessionId = fc.activeSession!.id;
    now = now.add(const Duration(minutes: 5));
    fc.cancelSession();

    final bridged = StudyController.instance.sessions
        .where((s) => s.focusSessionId == sessionId)
        .toList();
    expect(bridged.length, 1);
    expect(bridged.single.isCompleted, isFalse);

    final state = StudentOSIntelligenceEngine.computeDailyStudentState(
      subjects: const [],
      sessions: StudyController.instance.sessions,
    );
    expect(state.completedMinutes, 0);
  });
}
