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

  late DateTime currentTime;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_focus_p1');
    await StorageService.instance.clearUser(userId: 'test_focus_p1');
    await StorageService.instance.clearUser(userId: 'demo');
    await StorageService.instance.clearUser(userId: 'user_1');
    await StorageService.instance.clearUser(userId: 'user_2');

    FocusController.instance.clearData();
    ProgressionController.instance.clearData();
    TaskController.instance.clearData();

    currentTime = DateTime(2026, 9, 11, 10, 0, 0);
    FocusController.instance.setClockForTesting(() => currentTime);
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    FocusController.instance.resetClockForTesting();
    FocusController.instance.clearData();
  });

  group('Focus P1 — Timing Engine & Modes', () {
    test('1. Timer starts correctly with specified duration and countdown mode', () {
      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'Mathematics',
        objective: 'Calculus Exercises',
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.state, equals(FocusState.active));
      expect(fc.activeSession?.mode, equals(FocusMode.timer));
      expect(fc.activeSession?.plannedDuration, equals(const Duration(minutes: 25)));
      expect(fc.activeSession?.durationSeconds, equals(1500));
      expect(fc.activeElapsed, equals(Duration.zero));
      expect(fc.activeRemaining, equals(const Duration(minutes: 25)));
      expect(fc.activeProgress, equals(0.0));
    });

    test('2. Timer calculates remaining time and elapsed time accurately from timestamps', () {
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 10));

      currentTime = currentTime.add(const Duration(minutes: 3, seconds: 30));

      expect(fc.activeElapsed, equals(const Duration(minutes: 3, seconds: 30)));
      expect(fc.activeRemaining, equals(const Duration(minutes: 6, seconds: 30)));
      expect(fc.activeProgress, closeTo(0.35, 0.001));
    });

    test('3. Timer reaches zero and completes without negative remaining time', () {
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 5));

      currentTime = currentTime.add(const Duration(minutes: 6));

      expect(fc.activeRemaining, equals(Duration.zero));

      fc.complete();

      expect(fc.hasActiveSession, isFalse);
      expect(fc.state, equals(FocusState.idle));
      expect(fc.sessions.length, equals(1));
      final completed = fc.sessions.first;
      expect(completed.status, equals(FocusState.completed));
      expect(completed.outcome, equals(SessionOutcome.completed));
      expect(completed.completedAt, isNotNull);
      expect(completed.cancelledAt, isNull);
    });

    test('4. Stopwatch starts at zero and has count-up semantics', () {
      final fc = FocusController.instance;
      fc.startStopwatch(objective: 'Open-ended study');

      expect(fc.hasActiveSession, isTrue);
      expect(fc.state, equals(FocusState.active));
      expect(fc.activeSession?.mode, equals(FocusMode.stopwatch));
      expect(fc.activeSession?.durationSeconds, isNull);
      expect(fc.activeSession?.plannedDuration, equals(Duration.zero));
      expect(fc.activeElapsed, equals(Duration.zero));
      expect(fc.activeRemaining, equals(Duration.zero));
      expect(fc.activeProgress, equals(0.0));
    });

    test('5. Stopwatch calculates elapsed time correctly from timestamps as time advances', () {
      final fc = FocusController.instance;
      fc.startStopwatch();

      currentTime = currentTime.add(const Duration(minutes: 14, seconds: 22));

      expect(fc.activeElapsed, equals(const Duration(minutes: 14, seconds: 22)));
      expect(fc.activeRemaining, equals(Duration.zero));

      currentTime = currentTime.add(const Duration(minutes: 10));
      expect(fc.activeElapsed, equals(const Duration(minutes: 24, seconds: 22)));
    });

    test('6. Pause accurately freezes active time and excludes paused duration', () {
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 20));

      currentTime = currentTime.add(const Duration(minutes: 5));
      expect(fc.activeElapsed, equals(const Duration(minutes: 5)));

      fc.pause();
      expect(fc.state, equals(FocusState.paused));
      expect(fc.activeSession?.isPaused, isTrue);
      expect(fc.activeElapsed, equals(const Duration(minutes: 5)));

      currentTime = currentTime.add(const Duration(minutes: 10));
      expect(fc.activeElapsed, equals(const Duration(minutes: 5)));
      expect(fc.activeRemaining, equals(const Duration(minutes: 15)));
    });

    test('7. Resume resumes counting from previous elapsed time without drift', () {
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 20));

      currentTime = currentTime.add(const Duration(minutes: 5));
      fc.pause();

      currentTime = currentTime.add(const Duration(minutes: 10));
      fc.resume();

      expect(fc.state, equals(FocusState.active));
      expect(fc.activeSession?.isPaused, isFalse);
      expect(fc.activeElapsed, equals(const Duration(minutes: 5)));

      currentTime = currentTime.add(const Duration(minutes: 3));
      expect(fc.activeElapsed, equals(const Duration(minutes: 8)));
      expect(fc.activeRemaining, equals(const Duration(minutes: 12)));
    });

    test('8. Focus Guard behaves as a timed Focus session with future package support', () {
      final fc = FocusController.instance;
      final blocked = {'com.instagram.android', 'com.tiktok.android'};

      fc.startFocusGuard(
        duration: const Duration(minutes: 45),
        blockedPackages: blocked,
        subjectName: 'Physics',
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.state, equals(FocusState.active));
      expect(fc.activeSession?.mode, equals(FocusMode.focusGuard));
      expect(fc.activeSession?.plannedDuration, equals(const Duration(minutes: 45)));
      expect(fc.activeSession?.blockedPackages, equals(blocked));

      currentTime = currentTime.add(const Duration(minutes: 15));
      expect(fc.activeElapsed, equals(const Duration(minutes: 15)));
      expect(fc.activeRemaining, equals(const Duration(minutes: 30)));
      expect(fc.activeProgress, closeTo(0.333, 0.01));
    });

    test('9. Session recovery restores active session or marks expired session completed', () async {
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 25));

      currentTime = currentTime.add(const Duration(minutes: 10));
      await fc.persistActiveSession();

      final activeId = fc.activeSession!.id;

      fc.clearData();
      expect(fc.hasActiveSession, isFalse);

      await fc.load();
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.id, equals(activeId));
      expect(fc.activeElapsed, equals(const Duration(minutes: 10)));
      expect(fc.activeRemaining, equals(const Duration(minutes: 15)));

      currentTime = currentTime.add(const Duration(minutes: 20));
      await fc.load();

      expect(fc.hasActiveSession, isFalse);
      expect(fc.sessions.length, equals(1));
      expect(fc.sessions.first.id, equals(activeId));
      expect(fc.sessions.first.outcome, equals(SessionOutcome.completed));
      expect(fc.sessions.first.status, equals(FocusState.completed));
    });

    test('10. Legacy Focus data without mode or with old enum names deserializes safely', () {
      final legacyJson1 = {
        'id': 'legacy_1',
        'objective': 'Old quick session',
        'mode': 'quick',
        'startedAt': '2026-09-01T10:00:00.000Z',
        'focusDuration': 1500,
        'phase': 'focusing',
      };

      final session1 = FocusSession.fromJson(legacyJson1);
      expect(session1.id, equals('legacy_1'));
      expect(session1.mode, equals(FocusMode.timer));
      expect(session1.plannedDuration, equals(const Duration(minutes: 25)));
      expect(session1.status, equals(FocusState.active));

      final legacyJson2 = {
        'id': 'legacy_2',
        'objective': 'Old pomodoro',
        'mode': 'pomodoro',
        'startedAt': '2026-09-01T10:00:00.000Z',
      };
      final session2 = FocusSession.fromJson(legacyJson2);
      expect(session2.mode, equals(FocusMode.timer));

      final legacyJson3 = {
        'id': 'legacy_3',
        'startedAt': '2026-09-01T10:00:00.000Z',
      };
      final session3 = FocusSession.fromJson(legacyJson3);
      expect(session3.mode, equals(FocusMode.timer));
    });

    test('11. Corrupt Focus data does not crash initialization or leave broken state', () async {
      final fc = FocusController.instance;

      await StorageService.instance.saveJson(
        userId: 'test_focus_p1',
        key: 'focus_active_session',
        json: {
          'id': null,
          'startedAt': 'invalid_date_format',
          'mode': 12345,
        },
      );

      await StorageService.instance.saveJsonList(
        userId: 'test_focus_p1',
        key: 'focus_sessions',
        list: [
          {'id': 'valid_1', 'startedAt': '2026-09-01T10:00:00.000Z', 'mode': 'timer'},
          {'corrupt': true},
        ],
      );

      await expectLater(fc.load(), completes);
      expect(fc.isLoaded, isTrue);
      expect(fc.hasActiveSession, isFalse);
      expect(fc.sessions.length, equals(1));
      expect(fc.sessions.first.id, equals('valid_1'));
    });

    test('12. User isolation ensures sessions belong strictly to authenticated user', () async {
      await StorageService.instance.saveJsonList(
        userId: 'user_A',
        key: 'focus_sessions',
        list: [
          FocusSession(
            id: 'session_A',
            userId: 'user_A',
            mode: FocusMode.timer,
            startedAt: DateTime(2026, 9, 1, 10),
            outcome: SessionOutcome.completed,
          ).toJson(),
        ],
      );

      await StorageService.instance.saveJsonList(
        userId: 'user_B',
        key: 'focus_sessions',
        list: [
          FocusSession(
            id: 'session_B',
            userId: 'user_B',
            mode: FocusMode.stopwatch,
            startedAt: DateTime(2026, 9, 2, 11),
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

      expect(userAList?.length, equals(1));
      expect(userAList?.first['id'], equals('session_A'));
      expect(userAList?.first['mode'], equals('timer'));

      expect(userBList?.length, equals(1));
      expect(userBList?.first['id'], equals('session_B'));
      expect(userBList?.first['mode'], equals('stopwatch'));
    });

    test('13. Duplicate completion calls are idempotent and do not duplicate XP or history', () {
      final fc = FocusController.instance;
      fc.startTimer(duration: const Duration(minutes: 25));

      currentTime = currentTime.add(const Duration(minutes: 25));

      final initialXp = ProgressionController.instance.totalXp;

      fc.complete(note: 'Finished');
      expect(fc.sessions.length, equals(1));
      expect(fc.hasActiveSession, isFalse);

      final xpAfterFirstComplete = ProgressionController.instance.totalXp;
      expect(xpAfterFirstComplete, greaterThanOrEqualTo(initialXp));

      fc.complete(note: 'Finished again');
      expect(fc.sessions.length, equals(1));
      expect(ProgressionController.instance.totalXp, equals(xpAfterFirstComplete));
    });
  });
}
