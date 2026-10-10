import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/data/models/focus_models.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    FocusController.instance.clearData();
    ProgressionController.instance.clearData();
    TaskController.instance.clearData();
  });

  group('FocusMission & Models', () {
    test('FocusMission serialization and deserialization', () {
      final mission = FocusMission(
        id: 'mission_1',
        objective: 'Finish Chapter 3',
        subjectName: 'Mathematics',
        mode: FocusMode.timer,
        plannedDuration: const Duration(minutes: 50),
        distractionProtection: DistractionProtectionLevel.strict,
      );

      final json = mission.toJson();
      final fromJson = FocusMission.fromJson(json);

      expect(fromJson.id, 'mission_1');
      expect(fromJson.objective, 'Finish Chapter 3');
      expect(fromJson.subjectName, 'Mathematics');
      expect(fromJson.mode, FocusMode.timer);
      expect(fromJson.plannedDuration, const Duration(minutes: 50));
      expect(fromJson.distractionProtection, DistractionProtectionLevel.strict);
    });

    test('FocusSession duration and progress calculations', () {
      final session = FocusSession(
        id: 'session_1',
        missionId: 'mission_1',
        objective: 'Revise formulas',
        mode: FocusMode.timer,
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        focusDuration: const Duration(minutes: 25),
        phase: FocusPhase.focusing,
      );

      expect(session.plannedDuration, const Duration(minutes: 25));
      expect(session.effectiveElapsed.inMinutes, closeTo(10, 1));
      expect(session.remaining.inMinutes, closeTo(15, 1));
      expect(session.progress, closeTo(0.4, 0.05));
    });

    test('DistractionCapture model works correctly', () {
      final capture = DistractionCapture(
        id: 'dist_1',
        thought: 'Check my email later',
        capturedAt: DateTime.now(),
        category: 'Email',
      );

      final json = capture.toJson();
      final fromJson = DistractionCapture.fromJson(json);

      expect(fromJson.id, 'dist_1');
      expect(fromJson.thought, 'Check my email later');
      expect(fromJson.category, 'Email');
      expect(fromJson.resolved, false);

      fromJson.resolved = true;
      expect(fromJson.resolved, true);
    });
  });

  group('FocusController Lifecycle & Session Management', () {
    test('Start quick focus session', () async {
      final controller = FocusController.instance;
      expect(controller.hasActiveSession, false);

      controller.startQuickFocus(duration: const Duration(minutes: 25));

      expect(controller.hasActiveSession, true);
      expect(controller.activeSession?.mode, FocusMode.timer);
      expect(controller.activeSession?.objective, 'Quick Focus');
    });

    test('Start focus mission linked to subject', () async {
      final controller = FocusController.instance;
      final mission = FocusMission(
        id: 'm1',
        objective: 'Learn Physics Laws',
        subjectName: 'Physics',
        mode: FocusMode.timer,
        plannedDuration: const Duration(minutes: 45),
      );

      controller.startMission(mission);

      expect(controller.hasActiveSession, true);
      expect(controller.activeSession?.mode, FocusMode.timer);
      expect(controller.activeSession?.subjectName, 'Physics');
    });

    test('Pause and resume active session accurately', () async {
      final controller = FocusController.instance;
      controller.startQuickFocus(duration: const Duration(minutes: 25));
      controller.setPhase(FocusPhase.focusing);

      expect(controller.activeSession?.isPaused, false);
      expect(controller.activeSession?.isRunning, true);

      controller.pauseSession();
      expect(controller.activeSession?.isPaused, true);
      expect(controller.activeSession?.isRunning, false);

      controller.resumeSession();
      expect(controller.activeSession?.isPaused, false);
      expect(controller.activeSession?.isRunning, true);
    });

    test('Complete session calculates score and persists', () async {
      final controller = FocusController.instance;
      controller.startQuickFocus(duration: const Duration(minutes: 25));
      controller.setPhase(FocusPhase.focusing);

      controller.completeSession(note: 'Great productive focus!');

      expect(controller.hasActiveSession, false);
      expect(controller.sessions.length, 1);
      expect(controller.sessions.first.outcome, SessionOutcome.completed);
      expect(controller.sessions.first.note, 'Great productive focus!');
      expect(controller.sessions.first.sessionScore, greaterThan(0));
    });

    test('End session early creates partial session record', () async {
      final controller = FocusController.instance;
      controller.startQuickFocus(duration: const Duration(minutes: 25));
      controller.setPhase(FocusPhase.focusing);

      controller.endSessionEarly();

      expect(controller.hasActiveSession, false);
      expect(controller.sessions.length, 1);
      expect(controller.sessions.first.outcome, SessionOutcome.partial);
    });

    test('Capture thought during active focus and resolve in inbox', () async {
      final controller = FocusController.instance;
      controller.startQuickFocus(duration: const Duration(minutes: 25));

      controller.captureDistraction(
        'Look up calculus video',
        category: 'Entertainment',
      );

      expect(controller.distractions.length, 1);
      expect(controller.unresolvedDistractions.length, 1);
      expect(controller.activeSession?.distractionsCaptured, 1);

      controller.resolveDistraction(controller.distractions.first.id);

      expect(controller.unresolvedDistractions.length, 0);
    });

    test('Report distraction increments attempts and persists', () async {
      final controller = FocusController.instance;
      controller.startQuickFocus(duration: const Duration(minutes: 25));

      controller.reportDistraction();
      expect(controller.activeSession?.distractionAttempts, 1);

      controller.reportDistraction();
      expect(controller.activeSession?.distractionAttempts, 2);
    });
  });
}
