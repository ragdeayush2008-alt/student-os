import 'package:flutter/material.dart';

import '../../../core/design/tokens/student_os_tokens.dart';

/// Design tokens for Student OS Authentication — Modern Academic Command Center.
///
/// Solid surfaces, bright clean values. Dark mode is handled by Theme
/// (see AppTheme); these constants describe the light Command Center system
/// and are kept for backwards compatibility with existing tests/callers.
/// New code should prefer Theme.of(context).colorScheme directly.
abstract final class AuthColors {
  static const Color background = StudentOSColors.background;
  static const Color surface = StudentOSColors.surface;
  static const Color elevatedSurface = StudentOSColors.surface;
  static const Color inputBackground = StudentOSColors.surface;

  /// Auth card panel — solid white on light background.
  static const Color panelSurface = StudentOSColors.surface;

  /// Small chips/badges — secondary surface.
  static const Color chipSurface = StudentOSColors.surfaceSecondary;

  static const Color border = StudentOSColors.border;
  static const Color borderFocused = StudentOSColors.primary;
  static const Color borderError = StudentOSColors.danger;

  static const Color textPrimary = StudentOSColors.textMain;
  static const Color textSecondary = StudentOSColors.textSecondary;
  static const Color textMuted = StudentOSColors.textMuted;

  static const Color errorSurface = Color(0xFFFEE4E2);
  static const Color errorBorder = Color(0xFFFECDC2);
  static const Color errorText = Color(0xFFB42318);

  // Button tokens
  static const Color buttonPrimaryBg = StudentOSColors.primary;
  static const Color buttonPrimaryFg = Colors.white;
  static const Color buttonDisabledBg = Color(0xFFE4E7EC);
  static const Color buttonDisabledFg = Color(0xFF98A2B3);
}
