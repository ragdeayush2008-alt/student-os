import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'glass_surface.dart';

/// Reusable Glass Panel with optional header, action, and body content.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.level = GlassLevel.standard,
    this.padding = LiquidSpacing.cardPadding,
    this.margin,
    this.radius = LiquidRadius.xl,
    this.useBlur = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final GlassLevel level;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool useBlur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHeader = title != null || leading != null || trailing != null;

    return GlassSurface(
      level: level,
      radius: radius,
      padding: padding,
      margin: margin,
      useBlur: useBlur,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: LiquidSpacing.xs),
                ],
                if (title != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ...?trailing != null ? [trailing!] : null,
              ],
            ),
            const SizedBox(height: LiquidSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}
