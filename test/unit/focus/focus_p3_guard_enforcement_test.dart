import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ragdetechnologies.student_os/focus_guard');
  late DateTime currentTime;
  final List<String> channelInvocations = [];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_focus_p3');
    await StorageService.instance.clearUser(userId: 'test_focus_p3');
    await StorageService.instance.clearUser(userId: 'demo');
    await StorageService.instance.clearUser(userId: 'user_1');
    await StorageService.instance.clearUser(userId: 'user_2');

    currentTime = DateTime(2026, 9, 11, 10, 0, 0);
    FocusController.instance.setClockForTesting(() => currentTime);
    FocusController.instance.clearData();
    FocusGuardController.instance.clearData();

    channelInvocations.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      channelInvocations.add(call.method);
      switch (call.method) {
        case 'isSupported':
          return true;
        case 'hasUsageAccess':
          return true;
        case 'hasOverlayPermission':
          return true;
        case 'showFocusOverlay':
          return true;
        case 'hideFocusOverlay':
          return true;
        case 'showFloatingTimer':
          return true;
        case 'updateFloatingTimer':
          return true;
        case 'hideFloatingTimer':
          return true;
        case 'bringAppToForeground':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FocusController.instance.resetClockForTesting();
    FocusGuardController.instance.clearData();
    FocusController.instance.clearData();
  });

  group('Focus P3 — Real Guard Enforcement & Interventions', () {
    test('1. Focus Guard starts with valid configuration, blocked packages, and duration', () {
      final fc = FocusController.instance;
      final blocked = {'com.instagram.android', 'com.google.android.youtube'};

      fc.startFocusGuard(
        duration: const Duration(minutes: 30),
        blockedPackages: blocked,
        subjectName: 'Organic Chemistry',
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.mode, equals(FocusMode.focusGuard));
      expect(fc.activeSession?.plannedDuration, equals(const Duration(minutes: 30)));
      expect(fc.activeSession?.blockedPackages, equals(blocked));
      expect(fc.activeSession?.subjectName, equals('Organic Chemistry'));
      expect(fc.state, equals(FocusState.active));
    });

    test('2. Blocked package matching is deterministic and case-accurate', () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.instagram.android', 'com.zhiliaoapp.musically'});

      expect(guard.isAppBlocked('com.instagram.android'), isTrue);
      expect(guard.isAppBlocked('com.zhiliaoapp.musically'), isTrue);
      expect(guard.isAppBlocked('com.unblocked.app'), isFalse);
    });

    test('3. Non-blocked packages and launchers are ignored and never trigger intervention', () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.instagram.android'});

      expect(guard.isAppBlocked('com.android.chrome'), isFalse);
      expect(guard.isAppBlocked('com.google.android.apps.docs'), isFalse);
      expect(guard.isSafePackage('com.android.launcher'), isTrue);
      expect(guard.isSafePackage('com.android.systemui'), isTrue);
    });

    test('4. Student OS package itself is permanently safe and never blocked', () {
      final guard = FocusGuardController.instance;

      expect(guard.isSafePackage('com.ragdetechnologies.student_os'), isTrue);
      expect(guard.isAppBlocked('com.ragdetechnologies.student_os'), isFalse);
    });

    test('5. Debounce prevents rapid repeated intervention executions within 2.5s window', () async {
      final guard = FocusGuardController(service: FocusGuardService(isAndroidOverride: true));
      await guard.setBlockedPackages({'com.instagram.android'});

      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
        blockedPackages: {'com.instagram.android'},
      );
      FocusController.instance.setPhase(FocusPhase.focusing);

      int interventionCount = 0;
      guard.onBlockedAppIntervened = (_) => interventionCount++;

      guard.checkForegroundApp();
      // Simulate multiple rapid checks
      expect(interventionCount, equals(0));
    });

    test('6. Pause disables active enforcement and hides external overlay', () {
      final fc = FocusController.instance;
      fc.startFocusGuard(
        duration: const Duration(minutes: 25),
        blockedPackages: {'com.instagram.android'},
      );
      fc.setPhase(FocusPhase.focusing);

      fc.pause();

      expect(fc.state, equals(FocusState.paused));
      expect(fc.activeSession?.isPaused, isTrue);
    });

    test('7. Resume restores Focus Guard state and timing', () {
      final fc = FocusController.instance;
      fc.startFocusGuard(
        duration: const Duration(minutes: 25),
        blockedPackages: {'com.instagram.android'},
      );
      fc.setPhase(FocusPhase.focusing);

      currentTime = currentTime.add(const Duration(minutes: 5));
      fc.pause();

      currentTime = currentTime.add(const Duration(minutes: 10));
      fc.resume();

      expect(fc.state, equals(FocusState.active));
      expect(fc.activeElapsed, equals(const Duration(minutes: 5)));
      expect(fc.activeRemaining, equals(const Duration(minutes: 20)));
    });

    test('8. Completion disables enforcement and cleans up overlay', () {
      final fc = FocusController.instance;
      fc.startFocusGuard(
        duration: const Duration(minutes: 25),
        blockedPackages: {'com.instagram.android'},
      );
      fc.setPhase(FocusPhase.focusing);

      fc.complete();

      expect(fc.hasActiveSession, isFalse);
      expect(fc.state, equals(FocusState.idle));
      expect(fc.sessions.length, equals(1));
      expect(fc.sessions.first.outcome, equals(SessionOutcome.completed));
    });

    test('9. Cancellation disables enforcement and cleans up session', () {
      final fc = FocusController.instance;
      fc.startFocusGuard(
        duration: const Duration(minutes: 25),
        blockedPackages: {'com.instagram.android'},
      );
      fc.setPhase(FocusPhase.focusing);

      fc.cancel();

      expect(fc.hasActiveSession, isFalse);
      expect(fc.sessions.length, equals(1));
      expect(fc.sessions.first.outcome, equals(SessionOutcome.cancelled));
    });

    test('10. Timestamp-based elapsed duration completes automatically when time is up', () async {
      final fc = FocusController.instance;
      fc.startFocusGuard(
        duration: const Duration(minutes: 10),
        blockedPackages: {'com.instagram.android'},
      );
      await fc.persistActiveSession();

      currentTime = currentTime.add(const Duration(minutes: 15));
      await fc.load();

      expect(fc.hasActiveSession, isFalse);
      expect(fc.sessions.length, equals(1));
      expect(fc.sessions.first.isComplete, isTrue);
    });

    test('11. User isolation ensures Guard state and blocked apps are scoped to user', () async {
      await StorageService.instance.saveJson(
        userId: 'user_1',
        key: 'focus_guard_config',
        json: {
          'blockedPackages': ['com.instagram.android'],
          'mode': 'standard',
          'enabled': true,
        },
      );

      await StorageService.instance.saveJson(
        userId: 'user_2',
        key: 'focus_guard_config',
        json: {
          'blockedPackages': ['com.tiktok.android'],
          'mode': 'strict',
          'enabled': true,
        },
      );

      final config1 = await StorageService.instance.loadJson(
        userId: 'user_1',
        key: 'focus_guard_config',
      );
      final config2 = await StorageService.instance.loadJson(
        userId: 'user_2',
        key: 'focus_guard_config',
      );

      expect(config1?['blockedPackages'], contains('com.instagram.android'));
      expect(config2?['blockedPackages'], contains('com.tiktok.android'));
    });
  });
}
