import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/controller/focus_music_controller.dart';
import 'package:student_os/features/focus/controller/focus_screen_sleep_controller.dart';
import 'package:student_os/features/focus/data/models/focus_guard_models.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';
import 'package:student_os/features/focus/services/focus_music_service.dart';
import 'package:student_os/features/focus/services/focus_screen_sleep_service.dart';
import 'package:student_os/features/notifications/notification_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/study/study_controller.dart';

const _guardChannel =
    MethodChannel('com.ragdetechnologies.student_os/focus_guard');

/// Records native calls and serves controllable permission/foreground state.
class _GuardHarness {
  bool supported = true;
  bool usageAccess = true;
  bool overlayPermission = true;
  String? foregroundPackage;
  String? foregroundLabel;
  final List<String> nativeCalls = [];

  Future<dynamic> handler(MethodCall call) async {
    nativeCalls.add(call.method);
    switch (call.method) {
      case 'isSupported':
        return supported;
      case 'hasUsageAccess':
        return usageAccess;
      case 'hasOverlayPermission':
        return overlayPermission;
      case 'getForegroundApp':
        if (foregroundPackage == null) return null;
        return {
          'packageName': foregroundPackage,
          'label': foregroundLabel ?? foregroundPackage,
        };
      case 'getInstalledApps':
        return [];
      default:
        return true;
    }
  }
}

class _FakeSleepService extends FocusScreenSleepService {
  int enableCalls = 0;
  int disableCalls = 0;
  bool enabledState = false;

  @override
  Future<bool> enable() async {
    enableCalls++;
    enabledState = true;
    return true;
  }

  @override
  Future<bool> disable() async {
    disableCalls++;
    enabledState = false;
    return true;
  }
}

class _FailingMusicService extends FocusMusicService {
  @override
  Future<bool> play(String assetPath) async => false;

  @override
  Future<bool> resume() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final harness = _GuardHarness();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('sprintx_p5_unit_user');
    await StorageService.instance.clearUser(userId: 'sprintx_p5_unit_user');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_guardChannel, harness.handler);
    harness
      ..supported = true
      ..usageAccess = true
      ..overlayPermission = true
      ..foregroundPackage = null
      ..foregroundLabel = null
      ..nativeCalls.clear();

    FocusGuardService.instance =
        FocusGuardService(isAndroidOverride: true);
    try {
      FocusGuardController.instance.dispose();
    } catch (_) {}
    FocusGuardController.instance =
        FocusGuardController(service: FocusGuardService.instance);
    try {
      FocusMusicController.instance.dispose();
    } catch (_) {}
    FocusMusicService.instance = FocusMusicService(isTest: true);
    FocusMusicController.instance =
        FocusMusicController(service: FocusMusicService.instance);
    try {
      FocusScreenSleepController.instance.dispose();
    } catch (_) {}
    FocusScreenSleepController.instance = FocusScreenSleepController();
    await FocusMusicController.instance.load();
    await FocusScreenSleepController.instance.load();

    FocusController.instance.clearData();
    FocusMusicController.instance.clearData();
    FocusScreenSleepController.instance.clearData();
    FocusGuardController.instance.clearData();
    StudyController.instance.clearData();
    ProgressionController.instance.clearData();
    NotificationController.instance.clearData();

    await FocusGuardController.instance.load();
    await FocusGuardController.instance.refreshPermissions();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_guardChannel, null);
    FocusController.instance.clearData();
    FocusMusicController.instance.clearData();
    FocusScreenSleepController.instance.clearData();
    FocusGuardController.instance.clearData();
    StudyController.instance.clearData();
    ProgressionController.instance.clearData();
    NotificationController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('Phase 5 — Focus Guard states', () {
    test('unsupported platform reports unsupported, never ready', () async {
      harness.supported = false;
      await FocusGuardController.instance.refreshPermissions();
      final guard = FocusGuardController.instance;
      expect(guard.permissionStatus, FocusGuardPermissionStatus.unsupported);
      expect(guard.isReady, isFalse);
    });

    test('missing usage access reports setup-required state', () async {
      harness.usageAccess = false;
      await FocusGuardController.instance.refreshPermissions();
      final guard = FocusGuardController.instance;
      expect(
        guard.permissionStatus,
        FocusGuardPermissionStatus.usageAccessRequired,
      );
      expect(guard.isReady, isFalse);
    });

    test('missing overlay reports setup-required state', () async {
      harness.overlayPermission = false;
      await FocusGuardController.instance.refreshPermissions();
      final guard = FocusGuardController.instance;
      expect(
        guard.permissionStatus,
        FocusGuardPermissionStatus.overlayRequired,
      );
      expect(guard.isReady, isFalse);
    });

    test('granted permissions report ready with persisted config', () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.example.game'});
      await guard.setMode(FocusGuardMode.strict);
      expect(guard.permissionStatus, FocusGuardPermissionStatus.ready);
      expect(guard.isReady, isTrue);
      expect(guard.blockedPackages, contains('com.example.game'));
      expect(guard.mode, FocusGuardMode.strict);
    });
  });

  group('Phase 5 — Focus Guard monitoring scope', () {
    test('Focus session activates monitoring', () async {
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);
      expect(FocusGuardController.instance.isMonitoring, isTrue);
    });

    test('Timer session never activates monitoring', () async {
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);
      expect(FocusGuardController.instance.isMonitoring, isFalse);
    });

    test('Stopwatch session never activates monitoring', () async {
      FocusController.instance.startStopwatch();
      await Future<void>.delayed(Duration.zero);
      expect(FocusGuardController.instance.isMonitoring, isFalse);
    });

    test('pause stops monitoring, resume restarts it', () async {
      final guard = FocusGuardController.instance;
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);
      expect(guard.isMonitoring, isTrue);

      FocusController.instance.pauseSession();
      await Future<void>.delayed(Duration.zero);
      expect(guard.isMonitoring, isFalse);

      FocusController.instance.resumeSession();
      await Future<void>.delayed(Duration.zero);
      expect(guard.isMonitoring, isTrue);
    });

    test('stop ends monitoring', () async {
      final guard = FocusGuardController.instance;
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);
      expect(guard.isMonitoring, isTrue);

      FocusController.instance.stopSession();
      await Future<void>.delayed(Duration.zero);
      expect(guard.isMonitoring, isFalse);
    });

    test('revoked permission stops monitoring and blocks intervention',
        () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.example.game'});
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);
      expect(guard.isMonitoring, isTrue);

      harness.usageAccess = false;
      await guard.refreshPermissions();
      expect(guard.isReady, isFalse);
      expect(guard.isMonitoring, isFalse);

      harness.foregroundPackage = 'com.example.game';
      await guard.checkForegroundApp();
      expect(guard.blockedAttempts, isEmpty);
    });

    test('Focus → Timer transition drops monitoring without stale state',
        () async {
      final guard = FocusGuardController.instance;
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);
      expect(guard.isMonitoring, isTrue);

      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);
      expect(guard.isMonitoring, isFalse);
      expect(
        FocusController.instance.activeSession!.mode,
        FocusMode.timer,
      );
    });
  });

  group('Phase 5 — Focus Guard intervention', () {
    test('blocked app during Focus records attempt and intervenes',
        () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.example.game'});
      await guard.setMode(FocusGuardMode.standard);
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);

      harness.foregroundPackage = 'com.example.game';
      harness.foregroundLabel = 'Example Game';
      await guard.checkForegroundApp();

      expect(guard.blockedAttempts, hasLength(1));
      expect(guard.blockedAttempts.first.packageName, 'com.example.game');
      expect(
        guard.blockedAttempts.first.sessionId,
        FocusController.instance.activeSession!.id,
      );
      expect(harness.nativeCalls, contains('showFocusOverlay'));
      expect(
        FocusController.instance.activeSession!.distractionAttempts,
        1,
      );
    });

    test('rapid repeat checks debounce to a single attempt', () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.example.game'});
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);

      harness.foregroundPackage = 'com.example.game';
      await guard.checkForegroundApp();
      await guard.checkForegroundApp();
      await guard.checkForegroundApp();

      expect(guard.blockedAttempts, hasLength(1));
    });

    test('gentle mode brings app forward instead of overlay', () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.example.game'});
      await guard.setMode(FocusGuardMode.gentle);
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);

      harness.foregroundPackage = 'com.example.game';
      await guard.checkForegroundApp();

      expect(guard.blockedAttempts, hasLength(1));
      expect(harness.nativeCalls, contains('bringAppToForeground'));
      expect(harness.nativeCalls, isNot(contains('showFocusOverlay')));
    });

    test('unblocked and safe apps never intervene', () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.example.game'});
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await Future<void>.delayed(Duration.zero);

      harness.foregroundPackage = 'com.example.other';
      await guard.checkForegroundApp();
      harness.foregroundPackage = 'com.ragdetechnologies.student_os';
      await guard.checkForegroundApp();

      expect(guard.blockedAttempts, isEmpty);
      expect(harness.nativeCalls, isNot(contains('showFocusOverlay')));
    });

    test('guard config survives controller recovery', () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.example.game'});
      await guard.setMode(FocusGuardMode.strict);
      await guard.setGuardEnabled(false);

      final recovered =
          FocusGuardController(service: FocusGuardService.instance);
      await recovered.load();

      expect(recovered.blockedPackages, contains('com.example.game'));
      expect(recovered.mode, FocusGuardMode.strict);
      expect(recovered.isGuardEnabled, isFalse);
      recovered.dispose();
    });
  });

  group('Phase 5 — Background Music real playback', () {
    Future<void> settle() => Future<void>.delayed(
          const Duration(milliseconds: 20),
        );

    test('selection OFF by default with silence', () async {
      final music = FocusMusicController.instance;
      expect(music.selectedTrackIndex, -1);
      expect(music.isEnabled, isFalse);
      expect(music.isPlaying, isFalse);
    });

    test('play on session start, single player across switches', () async {
      final music = FocusMusicController.instance;
      final service = FocusMusicService.instance;
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );

      await music.setTrack(0);
      await settle();
      expect(music.isPlaying, isTrue);
      expect(service.isPlaying, isTrue);
      expect(service.currentTrack?.id, 'calm');

      await music.setTrack(1);
      await settle();
      expect(music.isPlaying, isTrue);
      expect(service.isPlaying, isTrue);
      expect(service.currentTrack?.id, 'ambient');
      expect(identical(service, FocusMusicService.instance), isTrue);
    });

    test('pause keeps position, resume continues same track', () async {
      final music = FocusMusicController.instance;
      final service = FocusMusicService.instance;
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await music.setTrack(2);
      await settle();
      expect(service.isPlaying, isTrue);

      FocusController.instance.pauseSession();
      await settle();
      expect(music.isPlaying, isFalse);
      expect(service.isPlaying, isFalse);
      expect(service.currentTrack?.id, 'energy');

      FocusController.instance.resumeSession();
      await settle();
      expect(music.isPlaying, isTrue);
      expect(service.isPlaying, isTrue);
      expect(service.currentTrack?.id, 'energy');
    });

    test('stop and OFF end playback with cleanup', () async {
      final music = FocusMusicController.instance;
      final service = FocusMusicService.instance;
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await music.setTrack(0);
      await settle();
      expect(service.isPlaying, isTrue);

      await music.setTrack(-1);
      await settle();
      expect(music.isEnabled, isFalse);
      expect(service.isPlaying, isFalse);

      await music.setTrack(0);
      await settle();
      FocusController.instance.stopSession();
      await settle();
      expect(service.isPlaying, isFalse);
      expect(service.currentTrack, isNull);
    });

    test('failed playback never fakes ON', () async {
      try {
        FocusMusicController.instance.dispose();
      } catch (_) {}
      FocusMusicController.instance = FocusMusicController(
        service: _FailingMusicService(),
      );
      final music = FocusMusicController.instance;
      await music.load();
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );

      await music.setTrack(0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(music.isPlaying, isFalse);
      expect(music.isEnabled, isFalse);
      expect(music.selectedTrackIndex, -1);
    });
  });

  group('Phase 5 — Screen Sleep real behavior', () {
    test('toggle ON with running session enables wakelock', () async {
      final fake = _FakeSleepService();
      try {
        FocusScreenSleepController.instance.dispose();
      } catch (_) {}
      FocusScreenSleepController.instance =
          FocusScreenSleepController(service: fake);
      final sleep = FocusScreenSleepController.instance;
      await sleep.load();
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );

      await sleep.setEnabled(true);
      expect(fake.enableCalls, 1);
      expect(fake.enabledState, isTrue);
      expect(sleep.isKeepAwake, isTrue);
    });

    test('pause/resume/stop drive enable/disable correctly', () async {
      final fake = _FakeSleepService();
      try {
        FocusScreenSleepController.instance.dispose();
      } catch (_) {}
      FocusScreenSleepController.instance =
          FocusScreenSleepController(service: fake);
      final sleep = FocusScreenSleepController.instance;
      await sleep.load();
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await sleep.setEnabled(true);
      final enables = fake.enableCalls;

      FocusController.instance.pauseSession();
      await Future<void>.delayed(Duration.zero);
      expect(fake.enabledState, isFalse);
      expect(sleep.isKeepAwake, isFalse);

      FocusController.instance.resumeSession();
      await Future<void>.delayed(Duration.zero);
      expect(fake.enableCalls, greaterThan(enables));
      expect(fake.enabledState, isTrue);

      FocusController.instance.stopSession();
      await Future<void>.delayed(Duration.zero);
      expect(fake.enabledState, isFalse);
      expect(sleep.isKeepAwake, isFalse);
      expect(fake.disableCalls, greaterThan(0));
    });

    test('toggle ON without a session never enables globally', () async {
      final fake = _FakeSleepService();
      try {
        FocusScreenSleepController.instance.dispose();
      } catch (_) {}
      FocusScreenSleepController.instance =
          FocusScreenSleepController(service: fake);
      final sleep = FocusScreenSleepController.instance;
      await sleep.load();

      await sleep.setEnabled(true);
      expect(fake.enableCalls, 0);
      expect(fake.enabledState, isFalse);

      // A later session start picks the preference up.
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 10),
      );
      await Future<void>.delayed(Duration.zero);
      expect(fake.enableCalls, 1);
    });

    test('dispose releases the wakelock (no leak)', () async {
      final fake = _FakeSleepService();
      final controller = FocusScreenSleepController(service: fake);
      await controller.load();
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await controller.setEnabled(true);
      expect(fake.enabledState, isTrue);

      controller.dispose();
      expect(fake.enabledState, isFalse);
      expect(fake.disableCalls, greaterThan(0));
    });

    test('foreground return forces a re-sync', () async {
      final fake = _FakeSleepService();
      try {
        FocusScreenSleepController.instance.dispose();
      } catch (_) {}
      FocusScreenSleepController.instance =
          FocusScreenSleepController(service: fake);
      final sleep = FocusScreenSleepController.instance;
      await sleep.load();
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      await sleep.setEnabled(true);
      final enables = fake.enableCalls;

      sleep.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(fake.enableCalls, greaterThan(enables));
      expect(fake.enabledState, isTrue);
    });
  });

  group('Phase 5 — XP safety', () {
    test('one completion awards XP exactly once', () async {
      final progression = ProgressionController.instance;
      await progression.load();
      final before = progression.totalXp;
      final startedAt = DateTime.now().subtract(const Duration(minutes: 25));

      final awarded = await progression.awardStudySession(
        sessionId: 'xp_once_1',
        durationSeconds: 1500,
        startedAt: startedAt,
      );
      expect(awarded, isTrue);
      final afterFirst = progression.totalXp;
      expect(afterFirst, greaterThan(before));

      final duplicate = await progression.awardStudySession(
        sessionId: 'xp_once_1',
        durationSeconds: 1500,
        startedAt: startedAt,
      );
      expect(duplicate, isFalse);
      expect(progression.totalXp, afterFirst);
    });

    test('short sessions earn no XP', () async {
      final progression = ProgressionController.instance;
      await progression.load();
      final awarded = await progression.awardStudySession(
        sessionId: 'xp_short_1',
        durationSeconds: 60,
        startedAt: DateTime.now(),
      );
      expect(awarded, isFalse);
    });

    test('completing twice records a single completion', () async {
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      FocusController.instance.completeSession();
      FocusController.instance.completeSession();
      final completed = FocusController.instance.sessions
          .where((s) => s.isComplete)
          .toList();
      expect(completed, hasLength(1));
    });

    test('abandoned Timer records partial with no completion', () async {
      final base = DateTime.now();
      FocusController.instance.setClockForTesting(() => base);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
      );
      final id = FocusController.instance.activeSession!.id;
      FocusController.instance.setClockForTesting(
        () => base.add(const Duration(minutes: 10)),
      );
      FocusController.instance.stopSession();
      FocusController.instance.resetClockForTesting();

      final ended = FocusController.instance.sessions
          .where((s) => s.id == id)
          .single;
      expect(ended.outcome, SessionOutcome.partial);
      expect(
        FocusController.instance.sessions
            .where((s) => s.isComplete)
            .isEmpty,
        isTrue,
      );
      final study = StudyController.instance.sessions
          .where((s) => s.focusSessionId == id)
          .single;
      expect(study.isCompleted, isFalse);
    });
  });

  group('Phase 5 — analytics isolation', () {
    test('only Focus completions count as focus time', () async {
      Future<void> completeAfter(
        Duration elapsed,
        void Function() start,
      ) async {
        final base = DateTime.now();
        FocusController.instance.setClockForTesting(() => base);
        start();
        FocusController.instance.setClockForTesting(
          () => base.add(elapsed),
        );
        FocusController.instance.completeSession();
        FocusController.instance.resetClockForTesting();
      }

      await completeAfter(
        const Duration(minutes: 25),
        () => FocusController.instance.startFocusGuard(
          duration: const Duration(minutes: 25),
          objective: 'Focus',
        ),
      );
      await completeAfter(
        const Duration(minutes: 25),
        () => FocusController.instance.startTimer(
          duration: const Duration(minutes: 25),
          objective: 'Timer',
        ),
      );
      await completeAfter(
        const Duration(minutes: 10),
        () => FocusController.instance.startStopwatch(
          objective: 'Stopwatch',
        ),
      );

      final all =
          FocusController.instance.sessions.where((s) => s.isComplete);
      expect(all.length, 3);
      expect(
        all.where((s) => s.mode == FocusMode.focusGuard).length,
        1,
      );
      final studyCompleted = StudyController.instance.completedSessions;
      expect(
        studyCompleted
            .where((s) => (s.focusSessionId ?? '').isNotEmpty)
            .length,
        3,
      );
      // Partial/abandoned timer work never counts as completed study.
      final abandonBase = DateTime.now();
      FocusController.instance.setClockForTesting(() => abandonBase);
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        objective: 'Abandoned',
      );
      final abandonedId = FocusController.instance.activeSession!.id;
      FocusController.instance.setClockForTesting(
        () => abandonBase.add(const Duration(minutes: 10)),
      );
      FocusController.instance.stopSession();
      FocusController.instance.resetClockForTesting();
      final abandoned = StudyController.instance.sessions
          .where((s) => s.focusSessionId == abandonedId)
          .single;
      expect(abandoned.isCompleted, isFalse);
    });
  });

  group('Phase 5 — notifications idempotency', () {
    test('repeat completion events notify exactly once', () async {
      final notifications = NotificationController.instance;
      await notifications.load();
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      final session = FocusController.instance.activeSession!;
      FocusController.instance.completeSession();

      await notifications.onFocusCompleted(session);
      await notifications.onFocusCompleted(session);

      final matches = notifications.notifications
          .where((n) => n.entityId == session.id)
          .toList();
      expect(matches, hasLength(1));
    });
  });

  group('Phase 5 — session recovery', () {
    test('persisted session restores without duplicates', () async {
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
        subjectName: 'Recovery Subject',
      );
      final id = FocusController.instance.activeSession!.id;
      await FocusController.instance.persistActiveSession();

      // Simulate process restart: memory cleared, storage intact.
      FocusController.instance.clearData();
      expect(FocusController.instance.hasActiveSession, isFalse);
      await FocusController.instance.load();

      expect(FocusController.instance.hasActiveSession, isTrue);
      expect(FocusController.instance.activeSession!.id, id);
      expect(
        FocusController.instance.activeSession!.subjectName,
        'Recovery Subject',
      );
      final actives = FocusController.instance.sessions
          .where((s) => s.id == id)
          .toList();
      expect(actives, isEmpty);
    });

    test('overdue countdown completes once on recovery', () async {
      FocusController.instance.startFocusGuard(
        duration: const Duration(minutes: 25),
      );
      final id = FocusController.instance.activeSession!.id;
      await FocusController.instance.persistActiveSession();

      FocusController.instance.setClockForTesting(
        () => DateTime.now().add(const Duration(minutes: 40)),
      );
      FocusController.instance.clearData();
      await FocusController.instance.load();
      FocusController.instance.resetClockForTesting();

      expect(FocusController.instance.hasActiveSession, isFalse);
      final ended = FocusController.instance.sessions
          .where((s) => s.id == id)
          .single;
      expect(ended.outcome, SessionOutcome.completed);
    });
  });

  group('Phase 5 — user isolation', () {
    test('User A → User B → User A keeps preferences separate', () async {
      AuthIsolation.instance.setAuthenticatedUser('iso_user_a');
      final music = FocusMusicController.instance;
      final sleep = FocusScreenSleepController.instance;
      final guard = FocusGuardController.instance;
      await music.load();
      await sleep.load();
      await guard.load();
      await music.setTrack(1);
      await sleep.setEnabled(true);
      await guard.setBlockedPackages({'com.example.game'});

      AuthIsolation.instance.setAuthenticatedUser('iso_user_b');
      await music.load();
      await sleep.load();
      await guard.load();
      expect(music.selectedTrackIndex, -1);
      expect(sleep.isEnabled, isFalse);
      expect(guard.blockedPackages, isEmpty);

      AuthIsolation.instance.setAuthenticatedUser('iso_user_a');
      await music.load();
      await sleep.load();
      await guard.load();
      expect(music.selectedTrackIndex, 1);
      expect(sleep.isEnabled, isTrue);
      expect(guard.blockedPackages, contains('com.example.game'));

      AuthIsolation.instance.setAuthenticatedUser('sprintx_p5_unit_user');
    });
  });
}
