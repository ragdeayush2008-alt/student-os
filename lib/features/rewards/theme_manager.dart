import 'package:flutter/material.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/theme_variants.dart';
import '../auth/auth_service.dart';
import 'entitlement_manager.dart';

import 'package:flutter/foundation.dart';

/// Manages active theme selection and ensures cosmetic theme entitlements are respected.
class ThemeManager extends ChangeNotifier {
  ThemeManager._();

  static final ThemeManager instance = ThemeManager._();

  static const _activeThemeVariantKey = 'active_theme_variant';

  ThemeVariantId _activeVariant = ThemeVariantId.defaultTheme;
  bool _loaded = false;
  bool _disposed = false;

  ThemeVariantId get activeVariant => _activeVariant;
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  /// Loads the active theme variant from storage.
  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    final uid = _userId;
    if (uid == null) return;
    final raw = await StorageService.instance.loadString(
      userId: uid,
      key: _activeThemeVariantKey,
    );

    if (raw != null) {
      final variant = ThemeVariantId.fromId(raw);
      // Validate that the user still has entitlement for this theme
      if (variant == ThemeVariantId.defaultTheme ||
          EntitlementManager.instance.isThemeUnlocked(variant.id)) {
        _activeVariant = variant;
      } else {
        _activeVariant = ThemeVariantId.defaultTheme;
      }
    } else {
      _activeVariant = ThemeVariantId.defaultTheme;
    }

    _loaded = true;
    if (!_disposed) notifyListeners();
  }

  /// Sets and persists the active theme variant if unlocked.
  Future<bool> setThemeVariant(ThemeVariantId variant) async {
    if (variant != ThemeVariantId.defaultTheme &&
        !EntitlementManager.instance.isThemeUnlocked(variant.id)) {
      return false; // Theme not unlocked
    }

    _activeVariant = variant;
    final uid = _userId;
    if (uid == null) {
      if (!_disposed) notifyListeners();
      return true;
    }
    await StorageService.instance.saveString(
      userId: uid,
      key: _activeThemeVariantKey,
      value: variant.id,
    );

    if (!_disposed) notifyListeners();
    return true;
  }

  /// Checks if a theme variant is unlocked by the student.
  bool isThemeUnlocked(ThemeVariantId variant) {
    if (variant == ThemeVariantId.defaultTheme) return true;
    return EntitlementManager.instance.isThemeUnlocked(variant.id);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
