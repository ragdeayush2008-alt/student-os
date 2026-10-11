import 'package:flutter/material.dart';

/// Central elevation/opacity tokens used to create premium surfaces.
///
/// True shadow blur/offset values are tuned per surface; these tokens provide a
/// consistent vocabulary. Elevation here combines a soft shadow with a subtle
/// tint to feel more refined on both light and dark themes.
abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
  static const double high = 8;

  static List<BoxShadow> soft(Color shadow, {bool isDark = false}) => [
    BoxShadow(
      color: shadow.withValues(alpha: isDark ? 0.25 : 0.06), // Softer, more diffuse
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: isDark ? 0.15 : 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> stronger(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.12),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ];
}
