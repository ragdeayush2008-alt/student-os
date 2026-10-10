import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_music_controller.dart';
import 'package:student_os/features/focus/controller/focus_screen_sleep_controller.dart';
import 'package:student_os/features/focus/services/focus_music_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_audio_sleep_user');
    FocusMusicService.instance = FocusMusicService(isTest: true);
    FocusMusicController.instance = FocusMusicController(
      service: FocusMusicService.instance,
    );
    FocusController.instance.clearData();
    FocusMusicController.instance.clearData();
    FocusScreenSleepController.instance.clearData();
  });

  tearDown(() {
    FocusController.instance.clearData();
    FocusMusicController.instance.clearData();
    FocusScreenSleepController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('Focus 3.0 — Background Music Tests', () {
    test('1. Default music selection is OFF (-1)', () {
      final mc = FocusMusicController.instance;
      expect(mc.selectedTrackIndex, equals(-1));
      expect(mc.selectedTrack, isNull);
      expect(mc.isEnabled, isFalse);
      expect(mc.isPlaying, isFalse);
    });

    test('2. Setting track index selects corresponding track', () async {
      final mc = FocusMusicController.instance;

      await mc.setTrack(0); // Calm
      expect(mc.selectedTrackIndex, equals(0));
      expect(mc.selectedTrack?.id, equals('calm'));
      expect(mc.isEnabled, isTrue);

      await mc.setTrack(1); // Ambient
      expect(mc.selectedTrackIndex, equals(1));
      expect(mc.selectedTrack?.id, equals('ambient'));

      await mc.setTrack(2); // Energy
      expect(mc.selectedTrackIndex, equals(2));
      expect(mc.selectedTrack?.id, equals('energy'));

      await mc.setTrack(-1); // OFF
      expect(mc.selectedTrackIndex, equals(-1));
      expect(mc.selectedTrack, isNull);
      expect(mc.isEnabled, isFalse);
    });

    test('3. Cycling track advances OFF -> Calm -> Ambient -> Energy -> OFF', () async {
      final mc = FocusMusicController.instance;

      expect(mc.selectedTrackIndex, equals(-1));

      await mc.cycleTrack();
      expect(mc.selectedTrackIndex, equals(0)); // Calm

      await mc.cycleTrack();
      expect(mc.selectedTrackIndex, equals(1)); // Ambient

      await mc.cycleTrack();
      expect(mc.selectedTrackIndex, equals(2)); // Energy

      await mc.cycleTrack();
      expect(mc.selectedTrackIndex, equals(-1)); // OFF
    });

    test('4. Music automatically stops when session ends or is cleared', () async {
      final mc = FocusMusicController.instance;
      final fc = FocusController.instance;

      await mc.setTrack(0);
      fc.startFocusGuard(duration: const Duration(minutes: 25));

      expect(fc.hasActiveSession, isTrue);
      expect(mc.selectedTrackIndex, equals(0));

      fc.endSessionEarly();
      expect(fc.hasActiveSession, isFalse);
    });
  });

  group('Focus 3.0 — Screen Sleep Prevention Tests', () {
    test('1. Default screen sleep prevention is OFF', () {
      final sc = FocusScreenSleepController.instance;
      expect(sc.isEnabled, isFalse);
      expect(sc.isKeepAwake, isFalse);
    });

    test('2. Enabling screen sleep toggles preference', () async {
      final sc = FocusScreenSleepController.instance;

      await sc.setEnabled(true);
      expect(sc.isEnabled, isTrue);

      await sc.setEnabled(false);
      expect(sc.isEnabled, isFalse);
    });

    test('3. Toggle flips between ON and OFF', () async {
      final sc = FocusScreenSleepController.instance;

      expect(sc.isEnabled, isFalse);

      await sc.toggle();
      expect(sc.isEnabled, isTrue);

      await sc.toggle();
      expect(sc.isEnabled, isFalse);
    });

    test('4. Screen sleep state syncs with active session lifecycle', () async {
      final sc = FocusScreenSleepController.instance;
      final fc = FocusController.instance;

      await sc.setEnabled(true);
      expect(sc.isEnabled, isTrue);

      // Start session
      fc.startTimer(duration: const Duration(minutes: 25));
      expect(fc.hasActiveSession, isTrue);

      // Pause session
      fc.pauseSession();
      expect(fc.activeSession?.isPaused, isTrue);

      // Resume session
      fc.resumeSession();
      expect(fc.activeSession?.isPaused, isFalse);

      // End session
      fc.completeSession();
      expect(fc.hasActiveSession, isFalse);
    });
  });
}
