import 'package:flutter/material.dart';

import '../constants/app_durations.dart';

/// TCC-aligned global page transitions builder.
///
/// Incoming: Fade + subtle 4% vertical slide (easeOutCubic)
/// Outgoing: ~3% horizontal nudge via secondaryAnimation
/// Root '/' unchanged. Reduced-motion bypassed.
/// Duration: 380ms via [AppDurations.pageTransition].
class AppPageTransitions extends PageTransitionsBuilder {
  const AppPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == '/') {
      return child;
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    // Incoming: easeOutCubic 380ms, outgoing: easeInCubic
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppCurves.standard,
      reverseCurve: AppCurves.exit,
    );

    // Outgoing secondary: slight 3% horizontal slide left.
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppCurves.exit,
      reverseCurve: AppCurves.standard,
    );

    // Use FadeTransition + SlideTransition with static child — no AnimatedBuilder
    // rebuilding large subtrees every frame. Child is passed as static child.
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.03, 0),
          ).animate(secondaryCurved),
          child: child,
        ),
      ),
    );
  }
}

/// Standard page-transition duration referenced by navigation — TCC 380ms.
const Duration kPageTransitionDuration = AppDurations.pageTransition;
