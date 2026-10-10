import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/progression/progression_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_focus_unit_user');
    FocusController.instance.clearData();
    ProgressionController.instance.clearData();
  });

  tearDown(() {
    FocusController.instance.clearData();
    ProgressionController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('Focus 3.0 P2 — Mode Selection & Engine Unit Tests', () {
    test('1. Starting Focus mode (Timer/FocusGuard) sets planned duration and context', () {
      final fc = FocusController.instance;

      fc.startFocusGuard(
        duration: const Duration(minutes: 35),
        subjectId: 'sub_tax',
        subjectName: 'Taxation',
        topicId: 'top_deductions',
        chapterId: 'ch_income_tax',
        taskId: 'task_practice_1',
        examId: 'exam_final',
        objective: 'Practice Section 80C Deductions',
      );

      expect(fc.hasActiveSession, isTrue);
      final session = fc.activeSession!;
      expect(session.mode, FocusMode.focusGuard);
      expect(session.plannedDuration, const Duration(minutes: 35));
      expect(session.subjectId, 'sub_tax');
      expect(session.subjectName, 'Taxation');
      expect(session.topicId, 'top_deductions');
      expect(session.chapterId, 'ch_income_tax');
      expect(session.taskId, 'task_practice_1');
      expect(session.examId, 'exam_final');
      expect(session.objective, 'Practice Section 80C Deductions');
    });

    test('2. Starting Stopwatch mode has zero planned duration and tracks open-ended time', () {
      final fc = FocusController.instance;

      fc.startStopwatch(
        subjectId: 'sub_law',
        subjectName: 'Business Law',
        objective: 'Reading Case Laws',
      );

      expect(fc.hasActiveSession, isTrue);
      final session = fc.activeSession!;
      expect(session.mode, FocusMode.stopwatch);
      expect(session.plannedDuration, Duration.zero);
      expect(session.subjectId, 'sub_law');
      expect(session.subjectName, 'Business Law');
      expect(session.objective, 'Reading Case Laws');
    });

    test('3. Pause and Resume transitions state accurately without losing elapsed duration', () {
      final fc = FocusController.instance;

      var fakeTime = DateTime(2026, 9, 12, 10, 0);
      fc.setClockForTesting(() => fakeTime);

      fc.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'Costing',
      );

      // Advance 5 minutes
      fakeTime = fakeTime.add(const Duration(minutes: 5));
      expect(fc.activeElapsed.inMinutes, 5);

      // Pause session
      fc.pauseSession();
      expect(fc.activeSession!.isPaused, isTrue);
      expect(fc.activeSession!.status, FocusState.paused);

      // Advance 10 minutes while paused
      fakeTime = fakeTime.add(const Duration(minutes: 10));
      expect(fc.activeElapsed.inMinutes, 5); // Still 5 minutes elapsed

      // Resume session
      fc.resumeSession();
      expect(fc.activeSession!.isPaused, isFalse);
      expect(fc.activeSession!.status, FocusState.active);

      // Advance another 5 minutes of study
      fakeTime = fakeTime.add(const Duration(minutes: 5));
      expect(fc.activeElapsed.inMinutes, 10);
      expect(fc.activeSession!.totalPausedDuration.inMinutes, 10);

      fc.resetClockForTesting();
    });

    test('4. End session early marks partial outcome and calculates score based on actual time', () {
      final fc = FocusController.instance;

      var fakeTime = DateTime(2026, 9, 12, 14, 0);
      fc.setClockForTesting(() => fakeTime);

      fc.startTimer(
        duration: const Duration(minutes: 40),
        subjectName: 'Auditing',
      );

      // Advance 20 minutes (50% completion)
      fakeTime = fakeTime.add(const Duration(minutes: 20));
      fc.endSessionEarly();

      expect(fc.hasActiveSession, isFalse);
      expect(fc.sessions.length, 1);
      final completed = fc.sessions.first;
      expect(completed.outcome, SessionOutcome.partial);
      expect(completed.actualDuration?.inMinutes, 20);
      expect(completed.sessionScore, greaterThan(0));

      fc.resetClockForTesting();
    });
  });
}
