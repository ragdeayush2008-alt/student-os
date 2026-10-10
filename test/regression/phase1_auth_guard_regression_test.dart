import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/goals/goal_controller.dart';
import 'package:student_os/features/preferences/user_preferences_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/resources/resource_controller.dart';
import 'package:student_os/features/rewards/redemption_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadJson(userId: 'test', key: 'dummy');
    FocusController.instance.clearData();
    ProgressionController.instance.clearData();
    TaskController.instance.clearData();
    SubjectController.instance.clearData();
    ExamController.instance.clearData();
    StudyController.instance.clearData();
    GoalController.instance.clearData();
    ResourceController.instance.clearData();
    RedemptionController.instance.clearData();
    UserPreferencesController.instance.clearData();
  });

  group('Phase 1 — Auth Guard on Controller Load', () {
    test('AuthService starts unauthenticated', () {
      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(AuthService.instance.user, isNull);
    });

    test('ControllerIsolation clears all controllers on logout', () {
      // Populate some data first
      FocusController.instance.startQuickFocus(
        duration: const Duration(minutes: 25),
      );
      expect(FocusController.instance.hasActiveSession, isTrue);

      // Clear on logout
      ControllerIsolation.instance.clearAllControllers();
      expect(FocusController.instance.hasActiveSession, isFalse);
      expect(FocusController.instance.sessions, isEmpty);
    });

    test('AuthIsolation resets on logout', () {
      AuthIsolation.instance.setAuthenticatedUser('user_a');
      expect(AuthIsolation.instance.isAuthenticated, isTrue);
      expect(AuthIsolation.instance.currentUserId, 'user_a');

      AuthIsolation.instance.clearSession();
      expect(AuthIsolation.instance.isAuthenticated, isFalse);
      expect(AuthIsolation.instance.currentUserId, isNull);
    });

    test('AuthIsolation detects user switch', () {
      AuthIsolation.instance.setAuthenticatedUser('user_a');
      expect(AuthIsolation.instance.isDifferentUser('user_b'), isTrue);
      expect(AuthIsolation.instance.isDifferentUser('user_a'), isFalse);

      AuthIsolation.instance.clearSession();
      expect(AuthIsolation.instance.isDifferentUser('user_a'), isTrue);
    });

    test('ControllerIsolation clearAllControllers resets _cleared flag', () {
      ControllerIsolation.instance.clearAllControllers();
      expect(ControllerIsolation.instance.isCleared, isTrue);

      ControllerIsolation.instance.reloadAllControllers('test_user');
      expect(ControllerIsolation.instance.isCleared, isFalse);
    });
  });

  group('Phase 1 — Focus Session Lifecycle', () {
    test('Start quick focus creates active session', () {
      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isFalse);

      fc.startQuickFocus(duration: const Duration(minutes: 25));

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.mode, isNotNull);
      expect(fc.activeSession?.focusDuration, const Duration(minutes: 25));
    });

    test('Pause and resume maintains session', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.pauseSession();
      expect(fc.activeSession?.isPaused, isTrue);

      fc.resumeSession();
      expect(fc.activeSession?.isPaused, isFalse);
      expect(fc.activeSession?.isRunning, isTrue);
    });

    test('Complete session ends and records history', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.completeSession();
      expect(fc.hasActiveSession, isFalse);
      expect(fc.sessions.length, greaterThanOrEqualTo(1));
    });

    test('End session early records partial outcome', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.endSessionEarly();
      expect(fc.hasActiveSession, isFalse);
      expect(fc.sessions.last.outcome, SessionOutcome.partial);
    });

    test('ClearData stops active session and clears history', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);

      fc.clearData();
      expect(fc.hasActiveSession, isFalse);
      expect(fc.sessions, isEmpty);
    });

    test('Start mission preserves subject and task context', () {
      final fc = FocusController.instance;
      final mission = FocusMission(
        id: 'test_mission',
        objective: 'Study Physics',
        subjectName: 'Physics',
        taskId: 'task_123',
        examId: 'exam_456',
        mode: FocusMode.timer,
        plannedDuration: const Duration(minutes: 45),
      );

      fc.startMission(mission);

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.subjectName, 'Physics');
      expect(fc.activeSession?.taskId, 'task_123');
      expect(fc.activeSession?.examId, 'exam_456');
    });
  });

  group('Phase 1 — User Data Isolation', () {
    test('Controller isolation: user A data not visible after clear', () {
      final fc = FocusController.instance;
      fc.startQuickFocus(duration: const Duration(minutes: 25));
      fc.setPhase(FocusPhase.focusing);
      fc.completeSession();

      expect(fc.sessions.isNotEmpty, isTrue);

      ControllerIsolation.instance.clearAllControllers();
      expect(fc.sessions, isEmpty);
      expect(fc.hasActiveSession, isFalse);
    });

    test('SubjectController clears on logout', () async {
      final sc = SubjectController.instance;
      // Can't easily create subjects without auth, but clearData should work
      sc.clearData();
      expect(sc.subjects, isEmpty);
    });

    test('TaskController clears on logout', () {
      final tc = TaskController.instance;
      tc.clearData();
      expect(tc.tasks, isEmpty);
      expect(tc.activeTasks, isEmpty);
    });

    test('ExamController clears on logout', () {
      final ec = ExamController.instance;
      ec.clearData();
      expect(ec.exams, isEmpty);
    });

    test('GoalController clears on logout', () {
      final gc = GoalController.instance;
      gc.clearData();
      expect(gc.dailyStudyTarget, Duration.zero);
    });

    test('ProgressionController clears on logout', () {
      final pc = ProgressionController.instance;
      pc.clearData();
      expect(pc.totalXp, 0);
    });
  });

  group('Phase 1 — StorageService User Scoping', () {
    test('Keys are scoped by userId prefix', () async {
      await StorageService.instance.saveString(
        userId: 'user_a',
        key: 'test_key',
        value: 'value_a',
      );

      final resultA = await StorageService.instance.loadString(
        userId: 'user_a',
        key: 'test_key',
      );
      expect(resultA, 'value_a');

      final resultB = await StorageService.instance.loadString(
        userId: 'user_b',
        key: 'test_key',
      );
      expect(resultB, isNull);
    });

    test('clearUser only removes that user keys', () async {
      await StorageService.instance.saveString(
        userId: 'user_x',
        key: 'keep',
        value: 'keep_value',
      );
      await StorageService.instance.saveString(
        userId: 'user_y',
        key: 'remove',
        value: 'remove_value',
      );

      await StorageService.instance.clearUser(userId: 'user_x');

      final kept = await StorageService.instance.loadString(
        userId: 'user_y',
        key: 'remove',
      );
      expect(kept, 'remove_value');

      final removed = await StorageService.instance.loadString(
        userId: 'user_x',
        key: 'keep',
      );
      expect(removed, isNull);
    });
  });
}
