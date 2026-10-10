import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Central layout breakpoints for Student OS.
abstract final class LiquidBreakpoints {
  /// Compact / phone layout (< 600px).
  static const double compact = 600;

  /// Medium layout (large phones / small tablets: 600–840px).
  static const double medium = 840;

  /// Expanded layout (tablets / desktop: 840–1200px).
  static const double expanded = 1200;

  /// Large layout (widescreen / large monitors: >= 1200px).
  static const double large = 1200;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < medium;
  static bool isExpanded(double width) => width >= medium && width < expanded;
  static bool isLarge(double width) => width >= expanded;
}

/// Screen size category enum for adaptive layouts.
enum ScreenSizeCategory {
  compact,
  medium,
  expanded,
  large,
}

/// Adaptive layout builder providing current [ScreenSizeCategory].
class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ScreenSizeCategory category, BoxConstraints constraints) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final category = width < LiquidBreakpoints.compact
            ? ScreenSizeCategory.compact
            : width < LiquidBreakpoints.medium
            ? ScreenSizeCategory.medium
            : width < LiquidBreakpoints.expanded
            ? ScreenSizeCategory.expanded
            : ScreenSizeCategory.large;

        return builder(context, category, constraints);
      },
    );
  }
}

/// Centers and constrains content width on larger screens to prevent awkward wide stretches.
class LiquidResponsiveContent extends StatelessWidget {
  const LiquidResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = LiquidSpacing.maxContentWidth,
    this.padding = LiquidSpacing.screenPadding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= LiquidBreakpoints.medium) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
    }
    return Padding(padding: padding, child: child);
  }
}

/// Two-column layout on wide screens, vertical stack on compact mobile.
class LiquidResponsiveTwoColumn extends StatelessWidget {
  const LiquidResponsiveTwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = LiquidBreakpoints.medium,
    this.gap = LiquidSpacing.cardGap,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;
  final double gap;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              SizedBox(width: gap),
              Expanded(flex: rightFlex, child: right),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            SizedBox(height: gap),
            right,
          ],
        );
      },
    );
  }
}

/// Responsive grid that automatically adjusts column count based on available width.
class LiquidResponsiveGrid extends StatelessWidget {
  const LiquidResponsiveGrid({
    super.key,
    required this.children,
    this.itemMinWidth = 160,
    this.mainAxisSpacing = LiquidSpacing.md,
    this.crossAxisSpacing = LiquidSpacing.md,
  });

  final List<Widget> children;
  final double itemMinWidth;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / itemMinWidth).floor().clamp(1, 4);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
          ),
          itemCount: children.length,
          itemBuilder: (_, index) => children[index],
        );
      },
    );
  }
}
