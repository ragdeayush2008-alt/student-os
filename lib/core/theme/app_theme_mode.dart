import 'package:flutter/material.dart';

/// The user's theme selection.
///
/// [system] follows the device setting.
enum AppThemeMode {
  light,
  dark,
  system;

  bool get isLight => this == AppThemeMode.light;
  bool get isDark => this == AppThemeMode.dark;
  bool get isSystem => this == AppThemeMode.system;

  /// Convenience label for UI display.
  String get label => switch (this) {
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
    AppThemeMode.system => 'System',
  };

  /// Maps an enum mode to an actual [ThemeMode] for the MaterialApp.
  ThemeMode get toThemeMode => switch (this) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };

  static AppThemeMode fromName(String? name) {
    return AppThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => AppThemeMode.system,
    );
  }
}
