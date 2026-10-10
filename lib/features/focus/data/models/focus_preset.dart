import 'package:flutter/material.dart';

import 'focus_guard_models.dart';
import 'focus_mission.dart';

enum FocusPresetType {
  sprint,
  pomodoro,
  study,
  deepFocus,
  deepWork,
  examPrep,
  custom,
}

class FocusPreset {
  const FocusPreset({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.defaultDuration,
    required this.focusMode,
    required this.guardMode,
    this.guardEnabled = true,
  });

  final FocusPresetType type;
  final String title;
  final String subtitle;
  final Duration defaultDuration;
  final FocusMode focusMode;
  final FocusGuardMode guardMode;
  final bool guardEnabled;

  String get label => title;
  Duration get duration => defaultDuration;
  int get durationMinutes => defaultDuration.inMinutes;

  /// Legacy emoji symbol (retained for compatibility only — UI must use
  /// [iconData] so Quick Start stays monochromatic emerald).
  String get icon {
    switch (type) {
      case FocusPresetType.sprint:
        return '⚡';
      case FocusPresetType.pomodoro:
      case FocusPresetType.study:
        return '📚';
      case FocusPresetType.deepFocus:
        return '🔥';
      case FocusPresetType.deepWork:
        return '🧠';
      case FocusPresetType.examPrep:
        return '🎯';
      case FocusPresetType.custom:
        return '🌙';
    }
  }

  /// Monochromatic Student OS icon for Quick Start chips and menus.
  /// Render in deep emerald / forest — never recoloured per-preset.
  IconData get iconData {
    switch (type) {
      case FocusPresetType.sprint:
        return Icons.bolt_rounded;
      case FocusPresetType.pomodoro:
      case FocusPresetType.study:
        return Icons.menu_book_rounded;
      case FocusPresetType.deepFocus:
        return Icons.center_focus_strong_rounded;
      case FocusPresetType.deepWork:
        return Icons.work_history_rounded;
      case FocusPresetType.examPrep:
        return Icons.track_changes_rounded;
      case FocusPresetType.custom:
        return Icons.tune_rounded;
    }
  }

  static const sprint = FocusPreset(
    type: FocusPresetType.sprint,
    title: 'Sprint',
    subtitle: '15m high-intensity focus sprint',
    defaultDuration: Duration(minutes: 15),
    focusMode: FocusMode.timer,
    guardMode: FocusGuardMode.gentle,
    guardEnabled: true,
  );

  static const pomodoro = FocusPreset(
    type: FocusPresetType.pomodoro,
    title: 'Focus',
    subtitle: '25m classic pomodoro focus',
    defaultDuration: Duration(minutes: 25),
    focusMode: FocusMode.timer,
    guardMode: FocusGuardMode.standard,
    guardEnabled: true,
  );

  static const study = FocusPreset(
    type: FocusPresetType.study,
    title: 'Study',
    subtitle: '35m structured study with standard guard',
    defaultDuration: Duration(minutes: 35),
    focusMode: FocusMode.timer,
    guardMode: FocusGuardMode.standard,
    guardEnabled: true,
  );

  static const deepFocus = FocusPreset(
    type: FocusPresetType.deepFocus,
    title: 'Deep Focus',
    subtitle: '45m structured study with distraction blocking',
    defaultDuration: Duration(minutes: 45),
    focusMode: FocusMode.focusGuard,
    guardMode: FocusGuardMode.standard,
    guardEnabled: true,
  );

  static const deepWork = FocusPreset(
    type: FocusPresetType.deepWork,
    title: 'Deep Work',
    subtitle: '60m uninterrupted flow with strict guard',
    defaultDuration: Duration(minutes: 60),
    focusMode: FocusMode.focusGuard,
    guardMode: FocusGuardMode.strict,
    guardEnabled: true,
  );

  static const examPrep = FocusPreset(
    type: FocusPresetType.examPrep,
    title: 'Exam Prep',
    subtitle: '90m intense sprint linked to exams',
    defaultDuration: Duration(minutes: 90),
    focusMode: FocusMode.timer,
    guardMode: FocusGuardMode.standard,
    guardEnabled: true,
  );

  static const custom = FocusPreset(
    type: FocusPresetType.custom,
    title: 'Custom',
    subtitle: 'Personalized duration, context & protection',
    defaultDuration: Duration(minutes: 25),
    focusMode: FocusMode.timer,
    guardMode: FocusGuardMode.gentle,
    guardEnabled: true,
  );

  static const List<FocusPreset> presets = [
    sprint,
    pomodoro,
    deepFocus,
    deepWork,
    examPrep,
    custom,
  ];
}
