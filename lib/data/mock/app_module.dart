import 'package:flutter/material.dart';

/// A module descriptor used by the app shell, "More/Explore" browser, and
/// placeholder screens. It is a blueprint of future modules (see
/// docs/APP_MODULES.md) — a visual identity only, not implemented features.
@immutable
class AppModule {
  const AppModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    this.status = 'Planned',
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// Category grouping in the Explore / navigation browser.
  final ModuleCategory category;

  /// Short status label ("Planned", "Foundation", "Active").
  final String status;
}

enum ModuleCategory {
  organize('Organize'),
  focus('Focus'),
  grow('Grow'),
  explore('Explore'),
  personal('Personal');

  const ModuleCategory(this.label);
  final String label;
}
