import 'package:flutter/material.dart';

import '../constants/app_breakpoints.dart';
import '../constants/app_spacing.dart';

/// A responsive content wrapper.
///
/// On compact (mobile) layouts the child takes the full width with standard
/// screen padding. On larger layouts the child is centered and constrained to
/// [AppSpacing.maxContentWidth] so cards never stretch absurdly wide.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (_isWide(width)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: child,
        ),
      );
    }
    return Padding(padding: AppSpacing.screenPadding, child: child);
  }

  static bool _isWide(double width) => width >= AppBreakpoints.medium;
}
