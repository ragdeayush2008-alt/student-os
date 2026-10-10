import 'package:flutter/material.dart';

import '../constants/app_durations.dart';

/// A text value that counts smoothly toward its target whenever [value]
/// changes.
///
/// Uses [TweenAnimationBuilder] so it animates from the *current* displayed
/// value to the new one — it never restarts from zero on ordinary rebuilds, and
/// only moves when the number actually changes. The rendered string is produced
/// by [format] so callers control rounding and prefixes/suffixes exactly.
/// Reduced-motion preferences are respected by rendering the final value
/// directly.
class AppAnimatedNumberText extends StatelessWidget {
  const AppAnimatedNumberText({
    super.key,
    required this.value,
    required this.format,
    this.duration = AppDurations.slow,
    this.style,
  });

  /// The target numeric value to display.
  final double value;

  /// Converts the animated numeric value into the final [String].
  final String Function(double value) format;

  /// How long the count transition takes.
  final Duration duration;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(format(value), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: AppCurves.standard,
      builder: (context, animated, _) => Text(format(animated), style: style),
    );
  }
}
