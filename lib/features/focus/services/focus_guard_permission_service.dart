import 'package:flutter/foundation.dart';
import '../data/models/focus_guard_models.dart';
import 'focus_guard_service.dart';

enum PermissionCheckState {
  unknown,
  granted,
  notGranted,
  restrictedOrUnavailable,
  error,
}

class FocusGuardPermissionService {
  FocusGuardPermissionService({FocusGuardService? service})
      : _service = service ?? FocusGuardService.instance;

  static FocusGuardPermissionService instance = FocusGuardPermissionService();

  final FocusGuardService _service;

  Future<bool> isSupported() async {
    try {
      return await _service.isSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isUsageAccessGranted() async {
    try {
      return await _service.hasUsageAccess();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isOverlayPermissionGranted() async {
    try {
      return await _service.hasOverlayPermission();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openUsageAccessSettings() async {
    try {
      return await _service.openUsageAccessSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openOverlaySettings() async {
    try {
      return await _service.openOverlaySettings();
    } catch (_) {
      return false;
    }
  }

  Future<FocusGuardPermissionStatus> checkPermissionStatus() async {
    try {
      final supported = await isSupported();
      if (!supported) {
        return FocusGuardPermissionStatus.unsupported;
      }

      final hasUsage = await isUsageAccessGranted();
      if (!hasUsage) {
        return FocusGuardPermissionStatus.usageAccessRequired;
      }

      final hasOverlay = await isOverlayPermissionGranted();
      if (!hasOverlay) {
        return FocusGuardPermissionStatus.overlayRequired;
      }

      return FocusGuardPermissionStatus.ready;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FocusGuardPermissionService] Error checking permissions: $e');
      }
      return FocusGuardPermissionStatus.notReady;
    }
  }
}
