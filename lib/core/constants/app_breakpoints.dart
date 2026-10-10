/// Central layout breakpoints for Student OS adaptive foundation.
///
/// Primary target is mobile (Android first). These breakpoints enable a clean
/// adaptive layout (sensible max width and grid adaptation) on larger screens
/// without over-investing in desktop UI during Phase 3.
abstract final class AppBreakpoints {
  /// Compact / phone layout.
  static const double compact = 600;

  /// Medium layout (large phones / small tablets).
  static const double medium = 840;

  /// Expanded layout (tablets / desktop).
  static const double expanded = 1200;

  /// Whether the given width should use the compact (mobile) layout.
  static bool isCompact(double width) => width < compact;

  /// Whether the given width should use an expanded (tablet/desktop) layout.
  static bool isExpanded(double width) => width >= medium;
}
