import 'package:flutter/widgets.dart';

import '../../../core/auth/auth_isolation.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/auth_service.dart';
import '../services/focus_screen_sleep_service.dart';
import 'focus_controller.dart';

class FocusScreenSleepController extends ChangeNotifier
    with WidgetsBindingObserver {
  FocusScreenSleepController({FocusScreenSleepService? service})
      : _service = service ?? FocusScreenSleepService.instance {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // Allow running in environments without binding initialization.
    }
    FocusController.instance.addListener(_syncToSession);
    load();
  }

  static FocusScreenSleepController instance = FocusScreenSleepController();

  final FocusScreenSleepService _service;

  static const _enabledKey = 'focus_screen_sleep_enabled';

  bool _enabled = false;
  bool _keepAwake = false;
  bool _disposed = false;

  bool get isEnabled => _enabled;

  bool get isKeepAwake => _keepAwake;

  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  Future<void> load() async {
    final uid = _userId;
    if (uid != null) {
      try {
        final raw = await StorageService.instance.loadJson(
          userId: uid,
          key: _enabledKey,
        );
        _enabled = raw?['enabled'] as bool? ?? false;
      } catch (_) {
        _enabled = false;
      }
    }
    _syncToSession();
    _notifySafely();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;

    final uid = _userId;
    if (uid != null) {
      try {
        await StorageService.instance.saveJson(
          userId: uid,
          key: _enabledKey,
          json: {'enabled': enabled},
        );
      } catch (_) {}
    }

    _syncToSession();
    _notifySafely();
  }

  Future<void> toggle() => setEnabled(!_enabled);

  void _syncToSession() {
    final active = FocusController.instance.activeSession;
    final shouldKeepAwake =
        active != null && active.isRunning && !active.isPaused && _enabled;

    if (shouldKeepAwake == _keepAwake) return;

    _keepAwake = shouldKeepAwake;
    if (shouldKeepAwake) {
      _service.enable().then((ok) {
        if (_disposed) return;
        _keepAwake = ok;
        _notifySafely();
      }).catchError((_) {
        if (!_disposed) {
          _keepAwake = false;
          _notifySafely();
        }
      });
    } else {
      _service.disable().then((ok) {
        if (_disposed) return;
        _keepAwake = !ok && false;
        _notifySafely();
      }).catchError((_) {
        if (!_disposed) {
          _keepAwake = false;
          _notifySafely();
        }
      });
    }
  }

  void clearData() {
    _enabled = false;
    _syncToSession();
    _notifySafely();
  }

  /// The OS may release the wakelock while the app is backgrounded; force a
  /// re-sync on return so a running session never ends up awake-claimed but
  /// actually asleep (or vice versa).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _keepAwake = false;
      _syncToSession();
    }
  }

  void _notifySafely() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    FocusController.instance.removeListener(_syncToSession);
    _keepAwake = false;
    _service.disable();
    super.dispose();
  }
}
