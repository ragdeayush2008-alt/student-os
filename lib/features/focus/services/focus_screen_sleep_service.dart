import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FocusScreenSleepService {
  static FocusScreenSleepService instance = FocusScreenSleepService();

  bool _disposed = false;

  Future<bool> enable() async {
    if (_disposed) return false;
    try {
      if (kIsWeb) {
        try {
          await WakelockPlus.enable();
          return true;
        } catch (_) {
          return false;
        }
      }
      await WakelockPlus.enable();
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> disable() async {
    if (_disposed) return false;
    try {
      await WakelockPlus.disable();
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    if (_disposed) return false;
    try {
      return await WakelockPlus.enabled;
    } on Exception {
      return false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await disable();
  }
}
