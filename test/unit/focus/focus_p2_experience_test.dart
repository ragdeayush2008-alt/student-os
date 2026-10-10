import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/data/models/focus_guard_models.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/services/focus_guard_permission_service.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ragdetechnologies.student_os/focus_guard');

  late DateTime currentTime;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_focus_p2');
    await StorageService.instance.clearUser(userId: 'test_focus_p2');
    await StorageService.instance.clearUser(userId: 'demo');
    await StorageService.instance.clearUser(userId: 'user_A');
    await StorageService.instance.clearUser(userId: 'user_B');

    currentTime = DateTime(2026, 9, 11, 10, 0, 0);
    FocusController.instance.setClockForTesting(() => currentTime);
    FocusController.instance.clearData();
    FocusGuardController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FocusController.instance.resetClockForTesting();
    FocusGuardController.instance.clearData();
    FocusController.instance.clearData();
  });

  group('Focus P2 — Mode Setup & Architecture', () {
    test('1. Focus mode selection maps cleanly to timer, stopwatch, and focusGuard', () {
      final fc = FocusController.instance;

      fc.startTimer(duration: const Duration(minutes: 25));
      expect(fc.activeSession?.mode, equals(FocusMode.timer));
      fc.endSessionEarly();

      fc.startStopwatch();
      expect(fc.activeSession?.mode, equals(FocusMode.stopwatch));
      fc.endSessionEarly();

      fc.startFocusGuard(duration: const Duration(minutes: 45));
      expect(fc.activeSession?.mode, equals(FocusMode.focusGuard));
      fc.endSessionEarly();
    });

    test('2. Timer duration selection is accurate for presets and custom durations', () {
      final fc = FocusController.instance;

      fc.startTimer(duration: const Duration(minutes: 15));
      expect(fc.activeSession?.plannedDuration, equals(const Duration(minutes: 15)));
      expect(fc.activeSession?.durationSeconds, equals(900));
      fc.endSessionEarly();

      fc.startTimer(duration: const Duration(minutes: 53));
      expect(fc.activeSession?.plannedDuration, equals(const Duration(minutes: 53)));
      expect(fc.activeSession?.durationSeconds, equals(3180));
      fc.endSessionEarly();
    });

    test('3. Stopwatch has no required duration and starts from zero', () {
      final fc = FocusController.instance;
      fc.startStopwatch();

      expect(fc.activeSession?.durationSeconds, isNull);
      expect(fc.activeSession?.plannedDuration, equals(Duration.zero));
      expect(fc.activeElapsed, equals(Duration.zero));
      expect(fc.activeRemaining, equals(Duration.zero));
      expect(fc.activeProgress, equals(0.0));
      fc.endSessionEarly();
    });

    test('4. Focus Guard stores selected blocked package IDs in active session', () {
      final fc = FocusController.instance;
      final selectedPackages = {'com.instagram.android', 'com.google.android.youtube'};

      fc.startFocusGuard(
        duration: const Duration(minutes: 30),
        blockedPackages: selectedPackages,
      );

      expect(fc.activeSession?.mode, equals(FocusMode.focusGuard));
      expect(fc.activeSession?.blockedPackages, equals(selectedPackages));
      expect(fc.activeSession?.plannedDuration, equals(const Duration(minutes: 30)));
      fc.endSessionEarly();
    });

    test('5. Focus Guard configuration persists safely in StorageService', () async {
      final guard = FocusGuardController.instance;
      await guard.setBlockedPackages({'com.twitter.android', 'com.reddit.frontpage'});

      expect(guard.blockedPackages.contains('com.twitter.android'), isTrue);
      expect(guard.blockedPackages.contains('com.reddit.frontpage'), isTrue);

      guard.clearData();
      expect(guard.blockedPackages.isEmpty, isTrue);

      await guard.load();
      expect(guard.blockedPackages.contains('com.twitter.android'), isTrue);
      expect(guard.blockedPackages.contains('com.reddit.frontpage'), isTrue);
    });

    test('6. Existing FocusSession recovery preserves Focus Guard mode and configuration', () async {
      final fc = FocusController.instance;
      final blocked = {'com.snapchat.android', 'com.zhiliaoapp.musically'};

      fc.startFocusGuard(
        duration: const Duration(minutes: 25),
        blockedPackages: blocked,
        subjectName: 'Chemistry',
      );
      await fc.persistActiveSession();

      final activeId = fc.activeSession!.id;

      fc.clearData();
      expect(fc.hasActiveSession, isFalse);

      await fc.load();
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.id, equals(activeId));
      expect(fc.activeSession?.mode, equals(FocusMode.focusGuard));
      expect(fc.activeSession?.blockedPackages, equals(blocked));
      expect(fc.activeSession?.subjectName, equals('Chemistry'));
    });
  });

  group('Focus P2 — Permission Abstraction & Android Bridge', () {
    test('7. Permission-state mapping handles granted, missing usage, and missing overlay', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'isSupported':
            return true;
          case 'hasUsageAccess':
            return true;
          case 'hasOverlayPermission':
            return false;
          default:
            return null;
        }
      });

      final permissionService = FocusGuardPermissionService(
        service: FocusGuardService(isAndroidOverride: true),
      );

      final status = await permissionService.checkPermissionStatus();
      expect(status, equals(FocusGuardPermissionStatus.overlayRequired));
    });

    test('8. Platform bridge failure returns safe defaults and does not throw into UI', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'ERROR', message: 'Channel failed');
      });

      final permissionService = FocusGuardPermissionService(
        service: FocusGuardService(isAndroidOverride: true),
      );

      final isSupported = await permissionService.isSupported();
      expect(isSupported, isFalse);

      final status = await permissionService.checkPermissionStatus();
      expect(status, equals(FocusGuardPermissionStatus.unsupported));
    });

    test('9. Missing permissions produce recoverable setup state without crashing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'isSupported':
            return true;
          case 'hasUsageAccess':
            return false;
          case 'hasOverlayPermission':
            return false;
          default:
            return null;
        }
      });

      final guard = FocusGuardController(
        service: FocusGuardService(isAndroidOverride: true),
      );
      await guard.refreshPermissions();

      expect(guard.permissionStatus, equals(FocusGuardPermissionStatus.usageAccessRequired));
      expect(guard.hasUsageAccess, isFalse);
      expect(guard.isReady, isFalse);
    });

    test('10. Student OS package and core system packages are excluded from selectable apps', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getInstalledApps') {
          return [
            {'packageName': 'com.ragdetechnologies.student_os', 'label': 'Student OS', 'isSystemApp': false},
            {'packageName': 'com.android.systemui', 'label': 'System UI', 'isSystemApp': true},
            {'packageName': 'com.instagram.android', 'label': 'Instagram', 'isSystemApp': false},
            {'packageName': 'com.google.android.youtube', 'label': 'YouTube', 'isSystemApp': false},
          ];
        }
        return null;
      });

      final guard = FocusGuardController(
        service: FocusGuardService(isAndroidOverride: true),
      );
      await guard.loadInstalledApps();

      expect(guard.installedApps.length, equals(2));
      expect(guard.installedApps.any((a) => a.packageName == 'com.ragdetechnologies.student_os'), isFalse);
      expect(guard.installedApps.any((a) => a.packageName == 'com.android.systemui'), isFalse);
      expect(guard.installedApps.any((a) => a.packageName == 'com.instagram.android'), isTrue);
      expect(guard.installedApps.any((a) => a.packageName == 'com.google.android.youtube'), isTrue);
    });

    test('11. Invalid or missing package metadata does not crash app discovery', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getInstalledApps') {
          return [
            {'packageName': '', 'label': null},
            {'packageName': 'com.valid.app', 'label': 'Valid App'},
          ];
        }
        return null;
      });

      final guard = FocusGuardController(
        service: FocusGuardService(isAndroidOverride: true),
      );
      await guard.loadInstalledApps();

      expect(guard.installedApps.length, equals(1));
      expect(guard.installedApps.first.packageName, equals('com.valid.app'));
      expect(guard.installedApps.first.displayName, equals('Valid App'));
    });

    test('12. User isolation ensures blocked packages list is scoped per user', () async {
      await StorageService.instance.saveJson(
        userId: 'user_A',
        key: 'focus_guard_config',
        json: {
          'blockedPackages': ['com.instagram.android'],
          'mode': 'standard',
          'enabled': true,
        },
      );

      await StorageService.instance.saveJson(
        userId: 'user_B',
        key: 'focus_guard_config',
        json: {
          'blockedPackages': ['com.reddit.frontpage'],
          'mode': 'strict',
          'enabled': true,
        },
      );

      final userAConfig = await StorageService.instance.loadJson(
        userId: 'user_A',
        key: 'focus_guard_config',
      );
      final userBConfig = await StorageService.instance.loadJson(
        userId: 'user_B',
        key: 'focus_guard_config',
      );

      expect(userAConfig?['blockedPackages'], contains('com.instagram.android'));
      expect(userAConfig?['blockedPackages'], isNot(contains('com.reddit.frontpage')));

      expect(userBConfig?['blockedPackages'], contains('com.reddit.frontpage'));
      expect(userBConfig?['blockedPackages'], isNot(contains('com.instagram.android')));
    });
  });
}
