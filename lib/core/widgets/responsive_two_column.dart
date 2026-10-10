import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

/// An adaptive 2-column grid that collapses to 1-column on narrow screens (< 360dp).
class ResponsiveTwoColumn extends StatelessWidget {
  const ResponsiveTwoColumn({
    super.key,
    required this.children,
    this.spacing = AppSpacing.sm,
    this.runSpacing = AppSpacing.sm,
    this.breakpoint = 360.0,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isNarrow = width < breakpoint;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }

        // 2-column layout with paired rows
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += 2) {
          final first = children[i];
          final second = i + 1 < children.length ? children[i + 1] : null;

          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: first),
                SizedBox(width: spacing),
                Expanded(child: second ?? const SizedBox.shrink()),
              ],
            ),
          );
          if (i + 2 < children.length) {
            rows.add(SizedBox(height: runSpacing));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
