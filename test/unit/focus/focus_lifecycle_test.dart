import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';

import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_focus_lifecycle');
    await StorageService.instance.clearUser(userId: 'test_focus_lifecycle');
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    FocusController.instance.clearData();
    ProgressionController.instance.clearData();
    TaskController.instance.clearData();
  });

  group('FocusController — Session Lifecycle', () {
    test('startQuickFocus creates session in focusing phase and active state', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));

      expect(fc.hasActiveSession, true);
      expect(fc.state, FocusState.active);
      expect(fc.activeSession?.phase, FocusPhase.focusing);
      expect(fc.activeSession?.mode, FocusMode.timer);
      expect(fc.activeSession?.plannedDuration, const Duration(minutes: 25));
    });

    test('startMission preserves task/subject/exam context', () {
      final mission = FocusMission(
        id: 'm1',
        objective: 'Study Physics',
        subjectId: 'sub_123',
        subjectName: 'Physics',
        taskId: 'task_456',
        examId: 'exam_789',
        mode: FocusMode.timer,
        plannedDuration: const Duration(minutes: 45),
      );

      FocusController.instance.startMission(mission);
      final session = FocusController.instance.activeSession;

      expect(session, isNotNull);
      expect(session!.subjectId, 'sub_123');
      expect(session.subjectName, 'Physics');
      expect(session.taskId, 'task_456');
      expect(session.examId, 'exam_789');
      expect(session.mode, FocusMode.timer);
    });

    test('pauseSession transitions to paused and stops countdown', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.pauseSession();
      expect(fc.activeSession?.isPaused, true);
      expect(fc.state, FocusState.paused);
      expect(fc.activeSession?.phase, FocusPhase.paused);
    });

    test('resumeSession transitions back to focusing', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);
      fc.pauseSession();

      fc.resumeSession();
      expect(fc.activeSession?.isRunning, true);
      expect(fc.state, FocusState.active);
      expect(fc.activeSession?.phase, FocusPhase.focusing);
    });

    test('completeSession ends with completed outcome and records history', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.completeSession(note: 'Great session');

      expect(fc.hasActiveSession, false);
      expect(fc.state, FocusState.idle);
      expect(fc.sessions.length, 1);
      expect(fc.sessions.first.outcome, SessionOutcome.completed);
      expect(fc.sessions.first.note, 'Great session');
      expect(fc.sessions.first.sessionScore, greaterThan(0));
    });

    test('endSessionEarly creates partial session with actual duration', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.endSessionEarly();

      expect(fc.hasActiveSession, false);
      expect(fc.state, FocusState.idle);
      expect(fc.sessions.length, 1);
      expect(fc.sessions.first.outcome, SessionOutcome.partial);
      expect(fc.sessions.first.actualDuration, isNotNull);
    });

    test('cancelSession creates cancelled session', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.cancelSession();

      expect(fc.hasActiveSession, false);
      expect(fc.state, FocusState.idle);
      expect(fc.sessions.length, 1);
      expect(fc.sessions.first.outcome, SessionOutcome.cancelled);
    });

    test('interruptSession creates interrupted session', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.interruptSession();

      expect(fc.hasActiveSession, false);
      expect(fc.sessions.length, 1);
      expect(fc.sessions.first.outcome, SessionOutcome.interrupted);
    });

    test('starting new session ends existing one cleanly', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.startQuickFocus(duration: const Duration(minutes: 15));

      expect(fc.sessions.length, 1);
      expect(fc.sessions.first.outcome, SessionOutcome.interrupted);
      expect(fc.activeSession?.mode, FocusMode.timer);
      expect(fc.activeSession?.plannedDuration, const Duration(minutes: 15));
    });

    test('activeElapsed accounts for pauses accurately without drift', () async {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      final beforePause = fc.activeElapsed;
      expect(beforePause.inMilliseconds, greaterThan(0));

      fc.pauseSession();
      final duringPause = fc.activeElapsed;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fc.activeElapsed, duringPause);

      fc.resumeSession();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        fc.activeElapsed.inMilliseconds,
        greaterThan(duringPause.inMilliseconds),
      );
    });

    test('clearData resets all state', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);
      fc.captureDistraction('test thought');

      fc.clearData();

      expect(fc.hasActiveSession, false);
      expect(fc.state, FocusState.idle);
      expect(fc.sessions.isEmpty, true);
      expect(fc.distractions.isEmpty, true);
    });
  });

  group('FocusController — Edge Cases & Idempotency', () {
    test('pause while already paused is a no-op', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.pauseSession();
      final pausedAtFirst = fc.activeSession?.pausedAt;
      fc.pauseSession();
      expect(fc.activeSession?.pausedAt, pausedAtFirst);
    });

    test('resume while already active is a no-op', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.resumeSession();
      expect(fc.activeSession?.isRunning, true);
    });

    test('complete or end while idle is safe no-op', () {
      final fc = FocusController.instance;
      expect(() => fc.completeSession(), returnsNormally);
      expect(() => fc.endSessionEarly(), returnsNormally);
      expect(() => fc.cancelSession(), returnsNormally);
      expect(() => fc.pauseSession(), returnsNormally);
      expect(() => fc.resumeSession(), returnsNormally);
      expect(fc.state, FocusState.idle);
    });

    test('duplicate complete cannot award rewards twice', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.completeSession();
      expect(fc.sessions.length, 1);

      fc.completeSession();
      expect(fc.sessions.length, 1);
    });
  });

  group('FocusController — Persistence & Recovery', () {
    test('active session survives reload / app restart', () async {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 30));
      fc.setPhase(FocusPhase.focusing);
      await fc.persistActiveSession();

      // Simulate app restart by clearing memory and reloading
      final savedId = fc.activeSession?.id;
      fc.clearData();
      expect(fc.hasActiveSession, false);

      await fc.load();
      expect(fc.hasActiveSession, true);
      expect(fc.activeSession?.id, savedId);
      expect(fc.activeSession?.plannedDuration, const Duration(minutes: 30));
    });

    test('expired session on reload resolves automatically as completed', () async {
      final fc = FocusController.instance;
      // Create a session started in the past that has already expired
      final expiredSession = FocusSession(
        id: 'fs_expired',
        missionId: 'm_expired',
        objective: 'Old Session',
        mode: FocusMode.timer,
        startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
        focusDuration: const Duration(minutes: 25),
        phase: FocusPhase.focusing,
      );

      await StorageService.instance.saveJson(
        userId: 'test_focus_lifecycle',
        key: 'focus_active_session',
        json: expiredSession.toJson(),
      );

      await fc.load();
      // Should not have active session; should be in sessions history as completed
      expect(fc.hasActiveSession, false);
      expect(fc.sessions.any((s) => s.id == 'fs_expired'), true);
      final completed = fc.sessions.firstWhere((s) => s.id == 'fs_expired');
      expect(completed.outcome, SessionOutcome.completed);
      expect(completed.actualDuration, const Duration(minutes: 25));
    });
  });

  group('FocusController — User Isolation', () {
    test('User A session and history are not accessible to User B', () async {
      // User A creates a session
      await StorageService.instance.saveJsonList(
        userId: 'user_A',
        key: 'focus_sessions',
        list: [
          FocusSession(
            id: 'session_A',
            userId: 'user_A',
            missionId: 'm_A',
            objective: 'User A Math',
            mode: FocusMode.timer,
            startedAt: DateTime.now(),
            outcome: SessionOutcome.completed,
          ).toJson(),
        ],
      );

      // User B creates a session
      await StorageService.instance.saveJsonList(
        userId: 'user_B',
        key: 'focus_sessions',
        list: [
          FocusSession(
            id: 'session_B',
            userId: 'user_B',
            missionId: 'm_B',
            objective: 'User B Physics',
            mode: FocusMode.timer,
            startedAt: DateTime.now(),
            outcome: SessionOutcome.completed,
          ).toJson(),
        ],
      );

      final userAList = await StorageService.instance.loadJsonList(
        userId: 'user_A',
        key: 'focus_sessions',
      );
      final userBList = await StorageService.instance.loadJsonList(
        userId: 'user_B',
        key: 'focus_sessions',
      );

      expect(userAList?.length, 1);
      expect(userAList?.first['id'], 'session_A');
      expect(userBList?.length, 1);
      expect(userBList?.first['id'], 'session_B');
    });
  });

  group('FocusController — Task Integration', () {
    test('completing session with linked task marks task complete', () async {
      final task = await TaskController.instance.createTask(
        title: 'Study for exam',
      );

      final mission = FocusMission(
        id: 'm1',
        objective: 'Study for exam',
        taskId: task.id,
      );
      FocusController.instance.startMission(mission);
      FocusController.instance.setPhase(FocusPhase.focusing);
      FocusController.instance.completeSession();

      final updatedTask = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .firstOrNull;
      expect(updatedTask?.isCompleted, true);
    });

    test('ending session early does NOT mark linked task complete', () async {
      final task = await TaskController.instance.createTask(
        title: 'Unfinished study task',
      );

      final mission = FocusMission(
        id: 'm2',
        objective: 'Unfinished study task',
        taskId: task.id,
      );
      FocusController.instance.startMission(mission);
      FocusController.instance.setPhase(FocusPhase.focusing);
      FocusController.instance.endSessionEarly();

      final updatedTask = TaskController.instance.tasks
          .where((t) => t.id == task.id)
          .firstOrNull;
      expect(updatedTask?.isCompleted, false);
    });
  });
}
