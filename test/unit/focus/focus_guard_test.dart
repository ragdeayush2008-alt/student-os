import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/data/models/focus_guard_models.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ragdetechnologies.student_os/focus_guard');
  final List<FocusGuardController> testControllers = [];

  FocusGuardController createController({FocusGuardService? service}) {
    FocusGuardController.instance.dispose();
    final c = FocusGuardController(service: service ?? FocusGuardService(isAndroidOverride: true));
    testControllers.add(c);
    FocusGuardController.instance = c;
    return c;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_focus_guard');
    await StorageService.instance.clearUser(userId: 'test_focus_guard');
    await StorageService.instance.clearUser(userId: 'demo');
    FocusController.instance.clearData();
    for (final c in testControllers) {
      c.dispose();
    }
    testControllers.clear();
    FocusGuardController.instance.dispose();
    final initial = FocusGuardController();
    testControllers.add(initial);
    FocusGuardController.instance = initial;
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    for (final c in testControllers) {
      c.dispose();
    }
    testControllers.clear();
    FocusGuardController.instance.dispose();
  });

  group('DetectedApp Model', () {
    test('parses from map correctly and classifies app types', () {
      final studentOsApp = DetectedApp.fromMap({
        'packageName': 'com.ragdetechnologies.student_os',
        'label': 'Student OS',
        'isStudentOs': true,
        'isLauncher': false,
        'isSystemApp': false,
      });
      expect(studentOsApp.appType, DetectedAppType.studentOs);
      expect(studentOsApp.displayName, 'Student OS');

      final launcherApp = DetectedApp.fromMap({
        'packageName': 'com.google.android.apps.nexuslauncher',
        'label': 'Pixel Launcher',
        'isStudentOs': false,
        'isLauncher': true,
        'isSystemApp': true,
      });
      expect(launcherApp.appType, DetectedAppType.launcher);

      final systemApp = DetectedApp.fromMap({
        'packageName': 'com.android.settings',
        'label': 'Settings',
        'isStudentOs': false,
        'isLauncher': false,
        'isSystemApp': true,
      });
      expect(systemApp.appType, DetectedAppType.system);

      final userApp = DetectedApp.fromMap({
        'packageName': 'com.instagram.android',
        'label': 'Instagram',
        'isStudentOs': false,
        'isLauncher': false,
        'isSystemApp': false,
      });
      expect(userApp.appType, DetectedAppType.userApp);

      final unknownApp = DetectedApp.fromMap({});
      expect(unknownApp.appType, DetectedAppType.unknown);
    });

    test('serializes toMap correctly', () {
      final app = DetectedApp(
        packageName: 'com.example.app',
        label: 'Example',
        isStudentOs: false,
        isLauncher: false,
        isSystemApp: false,
      );
      final map = app.toMap();
      expect(map['packageName'], 'com.example.app');
      expect(map['label'], 'Example');
      expect(map['appType'], 'userApp');
    });
  });

  group('FocusGuardService', () {
    test('returns unsupported on non-Android platform override', () async {
      final service = FocusGuardService(isAndroidOverride: false);
      expect(await service.isSupported(), false);
      expect(await service.hasUsageAccess(), false);
      expect(await service.hasOverlayPermission(), false);
      expect(await service.getCurrentForegroundApp(), isNull);
      expect(await service.checkPermissionStatus(), FocusGuardPermissionStatus.unsupported);
    });

    test('checks permissions and foreground app over platform channel', () async {
      final methodCalls = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call.method);
        switch (call.method) {
          case 'isSupported':
            return true;
          case 'hasUsageAccess':
            return true;
          case 'hasOverlayPermission':
            return true;
          case 'openUsageAccessSettings':
            return true;
          case 'openOverlaySettings':
            return true;
          case 'getForegroundApp':
            return {
              'packageName': 'com.instagram.android',
              'label': 'Instagram',
              'isStudentOs': false,
              'isLauncher': false,
              'isSystemApp': false,
            };
          default:
            return null;
        }
      });

      final service = FocusGuardService(isAndroidOverride: true);

      expect(await service.isSupported(), true);
      expect(await service.hasUsageAccess(), true);
      expect(await service.hasOverlayPermission(), true);
      expect(await service.openUsageAccessSettings(), true);
      expect(await service.openOverlaySettings(), true);

      final status = await service.checkPermissionStatus();
      expect(status, FocusGuardPermissionStatus.ready);

      final fgApp = await service.getCurrentForegroundApp();
      expect(fgApp, isNotNull);
      expect(fgApp?.packageName, 'com.instagram.android');
      expect(fgApp?.displayName, 'Instagram');

      final fgPackage = await service.getCurrentForegroundPackage();
      expect(fgPackage, 'com.instagram.android');

      expect(methodCalls, containsAll([
        'isSupported',
        'hasUsageAccess',
        'hasOverlayPermission',
        'openUsageAccessSettings',
        'openOverlaySettings',
        'getForegroundApp',
      ]));
    });

    test('reports usageAccessRequired and overlayRequired appropriately', () async {
      var usageAccess = false;
      var overlay = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return usageAccess;
        if (call.method == 'hasOverlayPermission') return overlay;
        return null;
      });

      final service = FocusGuardService(isAndroidOverride: true);

      // Both missing
      expect(await service.checkPermissionStatus(), FocusGuardPermissionStatus.usageAccessRequired);

      // Usage granted, overlay missing
      usageAccess = true;
      expect(await service.checkPermissionStatus(), FocusGuardPermissionStatus.overlayRequired);

      // Both granted
      overlay = true;
      expect(await service.checkPermissionStatus(), FocusGuardPermissionStatus.ready);
    });

    test('gracefully handles channel exceptions without crashing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'ERROR', message: 'Failed');
      });

      final service = FocusGuardService(isAndroidOverride: true);
      expect(await service.isSupported(), false);
      expect(await service.hasUsageAccess(), false);
      expect(await service.hasOverlayPermission(), false);
      expect(await service.openUsageAccessSettings(), false);
      expect(await service.openOverlaySettings(), false);
      expect(await service.getCurrentForegroundApp(), isNull);
    });
  });

  group('FocusGuardController Lifecycle & Monitoring', () {
    test('updates permission state and handles settings requests', () async {
      var usage = false;
      var overlay = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return usage;
        if (call.method == 'hasOverlayPermission') return overlay;
        if (call.method == 'openUsageAccessSettings') {
          usage = true;
          return true;
        }
        if (call.method == 'openOverlaySettings') {
          overlay = true;
          return true;
        }
        return null;
      });

      final service = FocusGuardService(isAndroidOverride: true);
      final controller = createController(service: service);

      await controller.refreshPermissions();
      expect(controller.permissionStatus, FocusGuardPermissionStatus.usageAccessRequired);
      expect(controller.hasUsageAccess, false);
      expect(controller.isReady, false);

      await controller.requestUsageAccess();
      await controller.refreshPermissions();
      expect(controller.permissionStatus, FocusGuardPermissionStatus.overlayRequired);
      expect(controller.hasUsageAccess, true);
      expect(controller.hasOverlayPermission, false);

      await controller.requestOverlayPermission();
      await controller.refreshPermissions();
      expect(controller.permissionStatus, FocusGuardPermissionStatus.ready);
      expect(controller.isReady, true);
    });

    test('rechecks permissions on AppLifecycleState.resumed', () async {
      var usage = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return usage;
        if (call.method == 'hasOverlayPermission') return true;
        return null;
      });

      final service = FocusGuardService(isAndroidOverride: true);
      final controller = createController(service: service);
      await controller.refreshPermissions();
      expect(controller.permissionStatus, FocusGuardPermissionStatus.usageAccessRequired);

      // Student returns from Settings
      usage = true;
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.permissionStatus, FocusGuardPermissionStatus.ready);
    });

    test('monitoring starts when Focus is active and stops when paused or ended', () async {
      DetectedApp? detectedApp;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return true;
        if (call.method == 'hasOverlayPermission') return true;
        if (call.method == 'getForegroundApp') {
          return {
            'packageName': 'com.google.android.youtube',
            'label': 'YouTube',
            'isStudentOs': false,
            'isLauncher': false,
            'isSystemApp': false,
          };
        }
        return null;
      });

      final service = FocusGuardService(isAndroidOverride: true);
      final controller = createController(service: service);
      await controller.load();
      controller.onForegroundAppChanged = (app) {
        detectedApp = app;
      };

      // Initially no session -> not monitoring
      expect(controller.isMonitoring, false);

      // Start focus session (Focus Guard operates in Focus mode only)
      FocusController.instance.startFocusGuard(duration: const Duration(minutes: 25));
      FocusController.instance.setPhase(FocusPhase.focusing);

      // Monitoring should start
      expect(controller.isMonitoring, true);

      await controller.checkForegroundApp();
      expect(detectedApp?.packageName, 'com.google.android.youtube');
      expect(controller.currentForegroundApp?.displayName, 'YouTube');

      // Pause session -> monitoring should stop
      FocusController.instance.pauseSession();
      expect(controller.isMonitoring, false);
      expect(controller.currentForegroundApp, isNull);

      // Resume session -> monitoring restarts
      FocusController.instance.resumeSession();
      expect(controller.isMonitoring, true);

      // Complete session -> monitoring stops
      FocusController.instance.completeSession();
      expect(controller.isMonitoring, false);
    });
  });

  group('Phase 8 — Focus Guard App Blocking Engine', () {
    test('recognizes blocked packages and allows unblocked packages', () async {
      final service = FocusGuardService(isAndroidOverride: true);
      final controller = createController(service: service);

      await controller.setBlockedPackages({'com.instagram.android', 'com.google.android.youtube'});

      expect(controller.isAppBlocked('com.instagram.android'), true);
      expect(controller.isAppBlocked('com.google.android.youtube'), true);
      expect(controller.isAppBlocked('com.spotify.music'), false);
      expect(controller.isAppBlocked('com.example.calculator'), false);
    });

    test('never blocks Student OS, System UI, Dialers, Launchers, or Settings', () async {
      final service = FocusGuardService(isAndroidOverride: true);
      final controller = createController(service: service);

      // Even if accidentally added
      await controller.setBlockedPackages({
        'com.ragdetechnologies.student_os',
        'com.android.systemui',
        'com.android.settings',
        'com.android.phone',
        'com.android.emergency',
      });

      expect(controller.isAppBlocked('com.ragdetechnologies.student_os'), false);
      expect(controller.isAppBlocked('com.android.systemui'), false);
      expect(controller.isAppBlocked('com.android.settings'), false);
      expect(controller.isAppBlocked('com.android.phone'), false);
      expect(controller.isAppBlocked('com.android.emergency'), false);
    });

    test('triggers intervention, records attempt, and debounces repeated foreground events', () async {
      final calls = <String>[];
      Map<String, dynamic>? overlayArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call.method);
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return true;
        if (call.method == 'hasOverlayPermission') return true;
        if (call.method == 'showFocusOverlay') {
          overlayArgs = Map<String, dynamic>.from(call.arguments as Map);
          return true;
        }
        if (call.method == 'getForegroundApp') {
          return {
            'packageName': 'com.instagram.android',
            'label': 'Instagram',
            'isStudentOs': false,
            'isLauncher': false,
            'isSystemApp': false,
          };
        }
        return null;
      });

      final service = FocusGuardService(isAndroidOverride: true);
      final controller = createController(service: service);
      await controller.load();
      await controller.setBlockedPackages({'com.instagram.android'});

      // Start active Focus session (Guard operates in Focus mode only)
      FocusController.instance.startFocusGuard(duration: const Duration(minutes: 25));
      FocusController.instance.setPhase(FocusPhase.focusing);

      expect(controller.blockedAttempts.length, 0);

      // First detection of blocked app
      await controller.checkForegroundApp();
      expect(controller.blockedAttempts.length, 1);
      expect(controller.blockedAttempts.first.packageName, 'com.instagram.android');
      expect(overlayArgs?['blockedAppName'], 'Instagram');
      expect(overlayArgs?['title'], 'FOCUS MODE');
      expect(calls, contains('showFocusOverlay'));

      // Second immediate detection of same blocked app -> debounced (no second attempt)
      await controller.checkForegroundApp();
      expect(controller.blockedAttempts.length, 1);

      FocusController.instance.clearData();
    });

    test('gentle mode brings app to foreground instead of full overlay', () async {
      FocusController.instance.clearData();
      final calls = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call.method);
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return true;
        if (call.method == 'hasOverlayPermission') return true;
        if (call.method == 'bringAppToForeground') return true;
        if (call.method == 'getForegroundApp') {
          return {
            'packageName': 'com.instagram.android',
            'label': 'Instagram',
            'isStudentOs': false,
            'isLauncher': false,
            'isSystemApp': false,
          };
        }
        return null;
      });

      final service = FocusGuardService(isAndroidOverride: true);
      final controller = createController(service: service);
      await controller.load();
      await controller.setMode(FocusGuardMode.gentle);
      await controller.setBlockedPackages({'com.instagram.android'});

      FocusController.instance.startFocusGuard(duration: const Duration(minutes: 25));
      FocusController.instance.setPhase(FocusPhase.focusing);

      calls.clear();
      await controller.checkForegroundApp();
      expect(calls, contains('bringAppToForeground'));
      expect(calls, isNot(contains('showFocusOverlay')));

      FocusController.instance.clearData();
    });

    test('hides overlay and disables blocking when Focus is paused or ended', () async {
      final calls = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call.method);
        if (call.method == 'isSupported') return true;
        if (call.method == 'hasUsageAccess') return true;
        if (call.method == 'hasOverlayPermission') return true;
        if (call.method == 'hideFocusOverlay') return true;
        if (call.method == 'showFocusOverlay') return true;
        if (call.method == 'getForegroundApp') {
          return {
            'packageName': 'com.instagram.android',
            'label': 'Instagram',
            'isStudentOs': false,
            'isLauncher': false,
            'isSystemApp': false,
          };
        }
        return null;
      });

      final service = FocusGuardService(isAndroidOverride: true);
      final controller = createController(service: service);
      await controller.load();
      await controller.setBlockedPackages({'com.instagram.android'});

      FocusController.instance.startFocusGuard(duration: const Duration(minutes: 25));
      FocusController.instance.setPhase(FocusPhase.focusing);

      await controller.checkForegroundApp();
      expect(controller.blockedAttempts.length, 1);

      // Pause session
      FocusController.instance.pauseSession();
      expect(controller.isMonitoring, false);
      expect(calls, contains('hideFocusOverlay'));

      // Check while paused -> no new intervention
      await controller.checkForegroundApp();
      expect(controller.blockedAttempts.length, 1);

      // End session
      FocusController.instance.completeSession();
      expect(controller.isMonitoring, false);
    });

    test('persists configuration and supports user isolation', () async {
      // User A setup
      final service = FocusGuardService(isAndroidOverride: true);
      final controller = createController(service: service);
      await controller.setBlockedPackages({'com.instagram.android', 'com.tiktok.android'});
      await controller.setMode(FocusGuardMode.strict);

      // Verify stored under the current (test) user namespace — never a
      // shared fallback namespace.
      final savedConfig = await StorageService.instance.loadJson(
        userId: 'test_focus_guard',
        key: 'focus_guard_config',
      );
      expect(savedConfig, isNotNull);
      expect(savedConfig!['mode'], 'strict');
      expect((savedConfig['blockedPackages'] as List).contains('com.instagram.android'), true);

      // User B isolation check: User B has separate storage key
      final userBConfig = await StorageService.instance.loadJson(
        userId: 'user_B',
        key: 'focus_guard_config',
      );
      expect(userBConfig, isNull);
    });
  });
}
