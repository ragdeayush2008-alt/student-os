import 'package:flutter/material.dart';

/// Central accessibility utilities for Student OS.
abstract final class LiquidAccessibility {
  /// Minimum touch target size (48x48 dp per WCAG 2.1 AA / Material / Apple guidelines).
  static const double minTouchTargetSize = 48.0;

  /// Minimum compact touch target size (44x44 dp).
  static const double minCompactTouchTargetSize = 44.0;
}

/// Enforces minimum 48x48 touch target area around interactive elements.
class LiquidTouchTarget extends StatelessWidget {
  const LiquidTouchTarget({
    super.key,
    required this.child,
    this.minSize = LiquidAccessibility.minTouchTargetSize,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double minSize;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }
}
