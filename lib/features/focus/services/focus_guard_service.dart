import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/models/focus_guard_models.dart';

class FocusGuardService {
  FocusGuardService({
    MethodChannel? channel,
    this.isAndroidOverride,
  }) : _channel = channel ?? const MethodChannel('com.ragdetechnologies.student_os/focus_guard');

  static FocusGuardService instance = FocusGuardService();

  final MethodChannel _channel;
  final bool? isAndroidOverride;

  bool get _isAndroid => isAndroidOverride ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  Future<bool> isSupported() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isSupported');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasUsageAccess() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('hasUsageAccess');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openUsageAccessSettings() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('openUsageAccessSettings');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasOverlayPermission() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openOverlaySettings() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('openOverlaySettings');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<DetectedApp?> getCurrentForegroundApp() async {
    if (!_isAndroid) return null;
    try {
      final res = await _channel.invokeMapMethod<dynamic, dynamic>('getForegroundApp');
      if (res == null) return null;
      return DetectedApp.fromMap(res);
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getCurrentForegroundPackage() async {
    final app = await getCurrentForegroundApp();
    return app?.packageName;
  }

  Future<List<DetectedApp>> getInstalledApps() async {
    if (!_isAndroid) return [];
    try {
      final res = await _channel.invokeListMethod<dynamic>('getInstalledApps');
      if (res == null) return [];
      return res
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => DetectedApp.fromMap(m))
          .toList();
    } on MissingPluginException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> bringAppToForeground() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('bringAppToForeground');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> showFloatingTimer({required String elapsedTime}) async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('showFloatingTimer', {
        'elapsedTime': elapsedTime,
      });
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateFloatingTimer({required String elapsedTime}) async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('updateFloatingTimer', {
        'elapsedTime': elapsedTime,
      });
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hideFloatingTimer() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('hideFloatingTimer');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> showFocusOverlay({
    required String title,
    required String objective,
    String elapsedTime = '',
    required String remainingTime,
    required String blockedAppName,
    required String mode,
  }) async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('showFocusOverlay', {
        'title': title,
        'objective': objective,
        'elapsedTime': elapsedTime,
        'remainingTime': remainingTime,
        'blockedAppName': blockedAppName,
        'mode': mode,
      });
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hideFocusOverlay() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('hideFocusOverlay');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<FocusGuardPermissionStatus> checkPermissionStatus() async {
    if (!_isAndroid) {
      return FocusGuardPermissionStatus.unsupported;
    }

    final usageGranted = await hasUsageAccess();
    if (!usageGranted) {
      return FocusGuardPermissionStatus.usageAccessRequired;
    }

    final overlayGranted = await hasOverlayPermission();
    if (!overlayGranted) {
      return FocusGuardPermissionStatus.overlayRequired;
    }

    return FocusGuardPermissionStatus.ready;
  }
}
