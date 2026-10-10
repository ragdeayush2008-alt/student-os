import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/rewards/theme_manager.dart';
import 'app_theme_mode.dart';
import 'theme_variants.dart';

/// A minimal, single-purpose store for the app shell (theme + navigation) that
/// does not depend on external state-management packages. It persists the theme
/// selection locally and resolves the effective [ThemeMode].
///
/// This is a foundation for the future; advanced state management can layer on
/// top as the feature set grows.
class AppShellController extends ChangeNotifier with WidgetsBindingObserver {
  AppShellController() {
    _attachBindingObserver();
    ThemeManager.instance.addListener(_onThemeManagerChanged);
    _load();
  }

  bool _observingBinding = false;

  void _attachBindingObserver() {
    try {
      WidgetsBinding.instance.addObserver(this);
      _observingBinding = true;
      _platform =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
    } catch (_) {
      // Binding not yet initialized (e.g. constructed before
      // WidgetsFlutterBinding.ensureInitialized()). The platform brightness
      // falls back to light and the observer is skipped instead of crashing
      // the app on the splash screen.
    }
  }

  void _onThemeManagerChanged() {
    notifyListeners();
  }

  static const _themeKey = 'app_theme_mode';

  Brightness _platform = Brightness.light;
  AppThemeMode _themeMode = AppThemeMode.system;
  int _selectedIndex = 0;

  AppThemeMode get themeMode => _themeMode;

  int get selectedIndex => _selectedIndex;

  ThemeVariantId get activeThemeVariant => ThemeManager.instance.activeVariant;

  /// The effective [ThemeMode] after resolving [system] against the platform.
  ThemeMode get effectiveThemeMode {
    if (_themeMode != AppThemeMode.system) return _themeMode.toThemeMode;
    return _platform == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }

  Brightness get effectiveBrightness =>
      effectiveThemeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;

  @override
  void didChangePlatformBrightness() {
    try {
      final next =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (_platform != next) {
        _platform = next;
        if (_themeMode == AppThemeMode.system) notifyListeners();
      }
    } catch (_) {
      // Binding unavailable — ignore brightness change.
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeKey);
      _themeMode = AppThemeMode.fromName(stored);
      notifyListeners();
    } catch (_) {
      // Persistence is best-effort; fall back to system on any failure.
    }
  }

  /// Sets the theme mode and persists it locally.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {
      // Non-fatal; theme still applies for this session.
    }
  }

  void setSelectedIndex(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    ThemeManager.instance.removeListener(_onThemeManagerChanged);
    if (_observingBinding) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {
        // Binding already gone — nothing to detach.
      }
    }
    super.dispose();
  }
}
