import 'package:flutter/material.dart';

import '../constants/app_durations.dart';
import '../theme/app_theme.dart';

/// A premium, restrained task-completion toggle.
///
/// Renders a circular check control that fills with the active color and
/// reveals a checkmark (scale + fade) once [completed]. The fill and check
/// transition smoothly without an exaggerated celebration, giving clear
/// confirmation of completion. Reduced-motion preferences are respected.
class AppCompletionCheck extends StatelessWidget {
  const AppCompletionCheck({
    super.key,
    required this.completed,
    required this.onTap,
    this.size = 24,
    this.color,
  });

  final bool completed;
  final VoidCallback onTap;

  /// Outer diameter in logical pixels.
  final double size;

  /// Completed/checkmark color; defaults to the palette success color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final fill = color ?? palette.success;
    final border = color ?? palette.onSurfaceMuted;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppDurations.fast;

    final control = AnimatedContainer(
      duration: duration,
      curve: AppCurves.standard,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: completed ? fill : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: completed ? fill : border.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: completed
            ? [
                BoxShadow(
                  color: fill.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppCurves.standard,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: Tween(begin: 0.6, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: completed
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey('checked'),
                size: size * 0.68,
                color: Colors.white,
              )
            : const SizedBox.shrink(key: ValueKey('unchecked')),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: control,
    );
  }
}
