/// Application-level clock seam.
///
/// Production reads [AppClock.current] instead of calling `DateTime.now()`
/// directly so time-sensitive flows can be driven with a fixed timestamp in
/// widget/integration tests. The default factory returns the real wall clock,
/// so production behavior is unchanged unless a test freezes the clock.
///
/// Tests that control time MUST restore the real clock in `tearDown` via
/// [reset], so later tests in the same isolate are not affected.
class AppClock {
  AppClock._();

  static DateTime Function() _now = DateTime.now;

  /// Current application time (defaults to the real wall clock).
  static DateTime get current => _now();

  /// Freezes the application clock at [time] (test use only).
  static void freezeAt(DateTime time) => _now = () => time;

  /// Restores the real wall clock (test use only).
  static void reset() => _now = DateTime.now;
}