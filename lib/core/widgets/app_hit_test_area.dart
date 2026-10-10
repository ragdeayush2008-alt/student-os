import 'package:flutter/widgets.dart';
import '../design/density_controller.dart';
import '../design/density_profile.dart';

class AppHitTestArea extends StatelessWidget {
  final Widget child;
  final double minSize;

  const AppHitTestArea({
    super.key,
    required this.child,
    this.minSize = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final density = StudentOSDensityScope.of(context);

    // Adjust hit test target based on density if needed,
    // but default to 48dp for accessibility.
    final effectiveMinSize = density == DensityProfile.compact ? 44.0 : minSize;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: effectiveMinSize,
        minHeight: effectiveMinSize,
      ),
      child: Center(child: child),
    );
  }
}
