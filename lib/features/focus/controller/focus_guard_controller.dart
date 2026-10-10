import 'dart:async';
import 'package:flutter/widgets.dart';

import '../../../core/auth/auth_isolation.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/auth_service.dart';
import '../data/models/focus_guard_models.dart';
import '../data/models/focus_mission.dart';
import '../services/focus_guard_service.dart';
import 'focus_controller.dart';

class FocusGuardController extends ChangeNotifier with WidgetsBindingObserver {
  FocusGuardController({FocusGuardService? service})
      : _service = service ?? FocusGuardService.instance {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // Allow running in environments without binding initialization
    }
    FocusController.instance.addListener(_onFocusControllerChanged);
    load();
  }

  static FocusGuardController instance = FocusGuardController();

  final FocusGuardService _service;

  static const _configKey = 'focus_guard_config';
  static const _attemptsKey = 'focus_guard_attempts';

  static const Set<String> _safePackages = {
    'com.ragdetechnologies.student_os',
    'com.android.systemui',
    'android',
    'com.android.settings',
    'com.google.android.packageinstaller',
    'com.android.packageinstaller',
    'com.google.android.permissioncontroller',
    'com.android.phone',
    'com.android.server.telecom',
    'com.google.android.dialer',
    'com.android.emergency',
    'com.samsung.android.dialer',
    'com.google.android.apps.nexuslauncher',
    'com.android.launcher',
    'com.android.launcher3',
    'com.sec.android.app.launcher',
  };

  FocusGuardPermissionStatus _permissionStatus = FocusGuardPermissionStatus.notReady;
  bool _hasUsageAccess = false;
  bool _hasOverlayPermission = false;
  DetectedApp? _currentForegroundApp;
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  bool _disposed = false;

  Set<String> _blockedPackages = {};
  FocusGuardMode _mode = FocusGuardMode.standard;
  bool _guardEnabled = true;
  List<BlockedAppAttempt> _blockedAttempts = [];
  List<DetectedApp> _installedApps = [];
  bool _isLoadingApps = false;

  String? _lastIntervenedPackage;
  DateTime? _lastInterventionTime;

  void Function(DetectedApp app)? onForegroundAppChanged;
  void Function(DetectedApp app)? onBlockedAppIntervened;

  FocusGuardPermissionStatus get permissionStatus => _permissionStatus;
  bool get hasUsageAccess => _hasUsageAccess;
  bool get hasOverlayPermission => _hasOverlayPermission;
  DetectedApp? get currentForegroundApp => _currentForegroundApp;
  bool get isMonitoring => _isMonitoring;
  bool get isReady => _permissionStatus == FocusGuardPermissionStatus.ready;

  Set<String> get blockedPackages => Set.unmodifiable(_blockedPackages);
  FocusGuardMode get mode => _mode;
  bool get isGuardEnabled => _guardEnabled;
  List<BlockedAppAttempt> get blockedAttempts => List.unmodifiable(_blockedAttempts);
  List<DetectedApp> get installedApps => List.unmodifiable(_installedApps);
  bool get isLoadingApps => _isLoadingApps;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  Future<void> load() async {
    try {
      await refreshPermissions();
    } catch (_) {}

    final uid = _userId;
    if (uid == null) {
      // Side-effect-free: safe from initState/build; memory stays authoritative.
      return;
    }

    final configJson = await StorageService.instance.loadJson(
      userId: uid,
      key: _configKey,
    );
    if (configJson != null) {
      try {
        final config = FocusGuardConfig.fromJson(Map<String, dynamic>.from(configJson));
        _blockedPackages = config.blockedPackages.toSet();
        _mode = config.mode;
        _guardEnabled = config.enabled;
      } catch (_) {
        _blockedPackages = {};
        _mode = FocusGuardMode.standard;
        _guardEnabled = true;
      }
    } else {
      _blockedPackages = {};
      _mode = FocusGuardMode.standard;
      _guardEnabled = true;
    }

    final attemptsJson = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _attemptsKey,
    );
    if (attemptsJson != null) {
      _blockedAttempts = attemptsJson
          .whereType<Map<String, dynamic>>()
          .map((j) {
            try {
              return BlockedAppAttempt.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<BlockedAppAttempt>()
          .toList();
    } else {
      _blockedAttempts = [];
    }

    if (!_disposed) notifyListeners();
  }

  Future<void> _saveConfig() async {
    final config = FocusGuardConfig(
      blockedPackages: _blockedPackages,
      mode: _mode,
      enabled: _guardEnabled,
    );
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJson(
      userId: uid,
      key: _configKey,
      json: config.toJson(),
    );
  }

  Future<void> _saveAttempts() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _attemptsKey,
      list: _blockedAttempts.map((a) => a.toJson()).toList(),
    );
  }

  void clearData() {
    stopMonitoring();
    _service.hideFloatingTimer();
    _service.hideFocusOverlay();
    _blockedPackages.clear();
    _blockedAttempts.clear();
    _installedApps.clear();
    _mode = FocusGuardMode.standard;
    _guardEnabled = true;
    _currentForegroundApp = null;
    _lastIntervenedPackage = null;
    _lastInterventionTime = null;
    if (!_disposed) notifyListeners();
  }

  // ── Blocked App Management ──────────────────────────────────────────

  bool isAppBlocked(String packageName) {
    if (!_guardEnabled) return false;
    if (isSafePackage(packageName)) return false;
    return _blockedPackages.contains(packageName);
  }

  bool isSafePackage(String packageName) {
    if (packageName.isEmpty) return true;
    if (packageName == 'com.ragdetechnologies.student_os') return true;
    if (_safePackages.contains(packageName)) return true;
    return false;
  }

  Future<void> toggleAppBlocked(String packageName) async {
    if (isSafePackage(packageName)) return;
    if (_blockedPackages.contains(packageName)) {
      _blockedPackages.remove(packageName);
    } else {
      _blockedPackages.add(packageName);
    }
    await _saveConfig();
    if (!_disposed) notifyListeners();
  }

  Future<void> setBlockedPackages(Set<String> packages) async {
    _blockedPackages = packages.where((p) => !isSafePackage(p)).toSet();
    await _saveConfig();
    if (!_disposed) notifyListeners();
  }

  Future<void> setMode(FocusGuardMode mode) async {
    _mode = mode;
    await _saveConfig();
    if (!_disposed) notifyListeners();
  }

  Future<void> setGuardEnabled(bool enabled) async {
    _guardEnabled = enabled;
    if (!enabled) {
      _service.hideFocusOverlay();
      _lastIntervenedPackage = null;
    }
    await _saveConfig();
    // Re-evaluate monitoring so mid-session toggles take effect immediately.
    _onFocusControllerChanged();
    if (!_disposed) notifyListeners();
  }

  Future<void> loadInstalledApps() async {
    if (_isLoadingApps) return;
    _isLoadingApps = true;
    if (!_disposed) notifyListeners();

    try {
      final apps = await _service.getInstalledApps();
      _installedApps = apps.where((a) => !isSafePackage(a.packageName)).toList();
    } catch (_) {
      _installedApps = [];
    } finally {
      _isLoadingApps = false;
      if (!_disposed) notifyListeners();
    }
  }

  // ── Permissions ───────────────────────────────────────────────────

  Future<void> refreshPermissions() async {
    final supported = await _service.isSupported();
    if (!supported) {
      _permissionStatus = FocusGuardPermissionStatus.unsupported;
      _hasUsageAccess = false;
      _hasOverlayPermission = false;
      if (!_disposed) notifyListeners();
      return;
    }

    _hasUsageAccess = await _service.hasUsageAccess();
    _hasOverlayPermission = await _service.hasOverlayPermission();

    if (!_hasUsageAccess) {
      _permissionStatus = FocusGuardPermissionStatus.usageAccessRequired;
    } else if (!_hasOverlayPermission) {
      _permissionStatus = FocusGuardPermissionStatus.overlayRequired;
    } else {
      _permissionStatus = FocusGuardPermissionStatus.ready;
    }

    // Permissions may have been granted/revoked outside the app (e.g. the
    // user just returned from system settings): re-evaluate monitoring.
    _onFocusControllerChanged();
    if (!_disposed) notifyListeners();
  }

  Future<bool> requestUsageAccess() async {
    final opened = await _service.openUsageAccessSettings();
    return opened;
  }

  Future<bool> requestOverlayPermission() async {
    final opened = await _service.openOverlaySettings();
    return opened;
  }

  // ── Monitoring & Intervention ──────────────────────────────────────

  void startMonitoring({Duration interval = const Duration(seconds: 1)}) {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(interval, (_) => checkForegroundApp());
    checkForegroundApp();
    if (!_disposed) notifyListeners();
  }

  void stopMonitoring() {
    if (!_isMonitoring && _monitoringTimer == null) return;
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _currentForegroundApp = null;
    _lastIntervenedPackage = null;
    _service.hideFocusOverlay();
    if (!_disposed) notifyListeners();
  }

  Future<DetectedApp?> checkForegroundApp() async {
    if (!_isMonitoring) return null;
    try {
      final app = await _service.getCurrentForegroundApp();
      if (app != null) {
        final changed = _currentForegroundApp?.packageName != app.packageName;
        _currentForegroundApp = app;
        if (changed) {
          onForegroundAppChanged?.call(app);
          if (!_disposed) notifyListeners();
        }

        _evaluateIntervention(app);
      }
      return app;
    } catch (_) {
      return null;
    }
  }

  void _evaluateIntervention(DetectedApp app) {
    final session = FocusController.instance.activeSession;
    // Focus Guard operates ONLY during an active Focus session with granted
    // permissions. Timer/Stopwatch must never trigger interventions.
    if (session == null ||
        !session.isRunning ||
        session.mode != FocusMode.focusGuard) {
      _lastIntervenedPackage = null;
      _service.hideFocusOverlay();
      return;
    }
    if (_permissionStatus != FocusGuardPermissionStatus.ready ||
        !_guardEnabled) {
      // Permissions revoked or guard paused: never fake "Active".
      _lastIntervenedPackage = null;
      _service.hideFocusOverlay();
      return;
    }

    if (app.isStudentOs || app.isLauncher || isSafePackage(app.packageName)) {
      if (_lastIntervenedPackage != null) {
        _lastIntervenedPackage = null;
        _service.hideFocusOverlay();
      }
      return;
    }

    if (isAppBlocked(app.packageName)) {
      final now = DateTime.now();
      if (_lastIntervenedPackage == app.packageName &&
          _lastInterventionTime != null &&
          now.difference(_lastInterventionTime!).inMilliseconds < 2500) {
        // Debounce within 2.5s
        return;
      }

      _lastIntervenedPackage = app.packageName;
      _lastInterventionTime = now;

      // Record blocked attempt locally
      _recordBlockedAttempt(session.id, app);

      // Report distraction to active Focus session
      FocusController.instance.reportDistraction();

      // Trigger intervention
      onBlockedAppIntervened?.call(app);
      _executeIntervention(session, app);
    }
  }

  void _recordBlockedAttempt(String sessionId, DetectedApp app) {
    final attempt = BlockedAppAttempt(
      id: 'block_${DateTime.now().millisecondsSinceEpoch}_${_blockedAttempts.length + 1}',
      sessionId: sessionId,
      packageName: app.packageName,
      appLabel: app.displayName,
      timestamp: DateTime.now(),
    );
    _blockedAttempts.insert(0, attempt);
    _saveAttempts();
  }

  void _executeIntervention(dynamic session, DetectedApp app) {
    final elapsedTotal = session.effectiveElapsed.inSeconds;
    final elMin = (elapsedTotal ~/ 60).toString().padLeft(2, '0');
    final elSec = (elapsedTotal % 60).toString().padLeft(2, '0');
    final elapsedStr = '$elMin:$elSec';

    final remainingTotal = session.remaining.inSeconds;
    final remMin = (remainingTotal ~/ 60).toString().padLeft(2, '0');
    final remSec = (remainingTotal % 60).toString().padLeft(2, '0');
    final remStr = '$remMin:$remSec';

    if (_mode == FocusGuardMode.gentle) {
      _service.bringAppToForeground();
    } else {
      _service.showFocusOverlay(
        title: 'FOCUS MODE',
        objective: session.objective,
        elapsedTime: elapsedStr,
        remainingTime: remStr,
        blockedAppName: app.displayName,
        mode: _mode.name,
      );
    }
  }

  void _showExternalFloatingTimer(dynamic session) {
    if (session.mode != FocusMode.focusGuard) return;
    final elapsedTotal = session.effectiveElapsed.inSeconds;
    final elMin = (elapsedTotal ~/ 60).toString().padLeft(2, '0');
    final elSec = (elapsedTotal % 60).toString().padLeft(2, '0');
    final elapsedStr = '$elMin:$elSec';
    _service.showFloatingTimer(elapsedTime: elapsedStr);
  }

  void _onFocusControllerChanged() {
    final session = FocusController.instance.activeSession;
    // Monitoring runs exclusively for running Focus sessions. Timer and
    // Stopwatch sessions must never activate detection or polling.
    final shouldMonitor = session != null &&
        session.isRunning &&
        session.mode == FocusMode.focusGuard &&
        _permissionStatus == FocusGuardPermissionStatus.ready &&
        _guardEnabled;
    if (shouldMonitor) {
      if (!_isMonitoring) {
        startMonitoring();
      }
    } else {
      if (_isMonitoring) {
        stopMonitoring();
      }
      _service.hideFloatingTimer();
      _service.hideFocusOverlay();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshPermissions();
      _service.hideFloatingTimer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      final session = FocusController.instance.activeSession;
      if (session != null && session.mode == FocusMode.focusGuard && session.isRunning) {
        _showExternalFloatingTimer(session);
      }
    }
  }

  void resetForTest() {
    stopMonitoring();
    _permissionStatus = FocusGuardPermissionStatus.notReady;
    _hasUsageAccess = false;
    _hasOverlayPermission = false;
    _currentForegroundApp = null;
    _blockedPackages.clear();
    _blockedAttempts.clear();
    _installedApps.clear();
    _mode = FocusGuardMode.standard;
    _guardEnabled = true;
    _lastIntervenedPackage = null;
    _lastInterventionTime = null;
    onForegroundAppChanged = null;
    onBlockedAppIntervened = null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopMonitoring();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    FocusController.instance.removeListener(_onFocusControllerChanged);
    super.dispose();
  }
}
