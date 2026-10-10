import 'package:flutter/foundation.dart';

import '../../data/models/focus_mission.dart';

/// Single source of truth for the Focus destination's selected mode.
///
/// Center and Session share it so that “back from active Timer → Focus”
/// can preserve the Timer session while showing the Focus landing.
/// No duplicate controllers, no extra navigation stack.
class FocusModeHolder extends ChangeNotifier {
  FocusModeHolder._();
  static final FocusModeHolder instance = FocusModeHolder._();

  FocusMode _mode = FocusMode.focusGuard;
  FocusMode get mode => _mode;

  void setMode(FocusMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// Signals the Focus Center to leave a running session's auto-shown HUD and
  /// return to the landing, WITHOUT changing the selected mode. Used by the
  /// embedded HUD back button: the running session is preserved, but the tab
  /// flips back to the Focus landing.
  void requestLanding() {
    notifyListeners();
  }
}
