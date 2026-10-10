import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime currentTime;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_focus_correction');
    await StorageService.instance.clearUser(userId: 'test_focus_correction');
    await StorageService.instance.clearUser(userId: 'demo');
    currentTime = DateTime(2026, 9, 11, 10, 0, 0);
    FocusController.instance.setClockForTesting(() => currentTime);
    FocusController.instance.clearData();
    FocusGuardController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    FocusController.instance.resetClockForTesting();
    FocusController.instance.clearData();
    FocusGuardController.instance.clearData();
  });

  group('Focus Correction Pass — Unit & Architecture Tests', () {
    test('1. No active session when cleared or initial load with empty storage', () async {
      final fc = FocusController.instance;
      await fc.load();
      expect(fc.hasActiveSession, isFalse);
      expect(fc.activeSession, isNull);
    });

    test('2. Timer mode session is created directly in focusing phase', () {
      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'Mathematics',
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.mode, equals(FocusMode.timer));
      expect(fc.activeSession?.phase, equals(FocusPhase.focusing));
      expect(fc.activeRemaining, equals(const Duration(minutes: 25)));
    });

    test('3. Stopwatch mode session is created directly in focusing phase without duration', () {
      final fc = FocusController.instance;
      fc.startStopwatch(subjectName: 'Physics');

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.mode, equals(FocusMode.stopwatch));
      expect(fc.activeSession?.phase, equals(FocusPhase.focusing));
      expect(fc.activeSession?.durationSeconds, isNull);
      expect(fc.activeElapsed, equals(Duration.zero));
    });

    test('4. Focus Guard session preserves blocked packages and focusing phase', () {
      final fc = FocusController.instance;
      final blocked = {'com.instagram.android', 'com.tiktok.android'};

      fc.startFocusGuard(
        duration: const Duration(minutes: 45),
        blockedPackages: blocked,
        subjectName: 'Chemistry',
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.mode, equals(FocusMode.focusGuard));
      expect(fc.activeSession?.phase, equals(FocusPhase.focusing));
      expect(fc.activeSession?.blockedPackages, equals(blocked));
    });

    test('5. Active session recovery restores mode-specific session accurately', () async {
      final fc = FocusController.instance;

      fc.startFocusGuard(
        duration: const Duration(minutes: 30),
        blockedPackages: {'com.reddit.frontpage'},
        subjectName: 'Biology',
      );
      await fc.persistActiveSession();

      fc.clearData();
      expect(fc.hasActiveSession, isFalse);

      await fc.load();
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.mode, equals(FocusMode.focusGuard));
      expect(fc.activeSession?.subjectName, equals('Biology'));
      expect(fc.activeSession?.blockedPackages, contains('com.reddit.frontpage'));
    });
  });
}
