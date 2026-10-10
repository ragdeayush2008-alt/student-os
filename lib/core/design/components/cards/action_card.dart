import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_surface.dart';

/// Interactive Action Card with leading icon, title, description, and chevron.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.level = GlassLevel.standard,
    this.padding = LiquidSpacing.cardPadding,
    this.margin,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final GlassLevel level;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = iconColor ?? theme.colorScheme.primary;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && icon != null) {
      leadingWidget = Container(
        padding: const EdgeInsets.all(LiquidSpacing.xs),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: LiquidRadius.smAll,
        ),
        child: Icon(icon, size: 20, color: primary),
      );
    }

    return GlassSurface(
      level: level,
      radius: LiquidRadius.lg,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: Row(
        children: [
          if (leadingWidget != null) ...[
            leadingWidget,
            const SizedBox(width: LiquidSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? LiquidColors.textSecondaryDark
                          : LiquidColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: LiquidSpacing.sm),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: LiquidSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? LiquidColors.textTertiaryDark
                  : LiquidColors.textTertiaryLight,
            ),
          ],
        ],
      ),
    );
  }
}
