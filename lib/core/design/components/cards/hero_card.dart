import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_surface.dart';

/// Prominent Hero Card for key callouts and major daily priorities.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.icon,
    this.iconColor,
    this.child,
    this.primaryAction,
    this.secondaryAction,
    this.gradient,
    this.onTap,
    this.level = GlassLevel.elevated,
    this.padding = LiquidSpacing.heroCardPadding,
  });

  final String title;
  final String? subtitle;
  final Widget? badge;
  final IconData? icon;
  final Color? iconColor;
  final Widget? child;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final List<Color>? gradient;
  final VoidCallback? onTap;
  final GlassLevel level;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = iconColor ?? theme.colorScheme.primary;

    return GlassSurface(
      level: level,
      radius: LiquidRadius.xl,
      padding: padding,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(LiquidSpacing.xs),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: LiquidRadius.smAll,
                  ),
                  child: Icon(icon, size: 20, color: primary),
                ),
                const SizedBox(width: LiquidSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...?badge != null ? [badge!] : null,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: LiquidSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? LiquidColors.textSecondaryDark
                    : LiquidColors.textSecondaryLight,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: LiquidSpacing.md),
            child!,
          ],
          if (primaryAction != null || secondaryAction != null) ...[
            const SizedBox(height: LiquidSpacing.lg),
            Row(
              children: [
                if (secondaryAction != null) ...[
                  Flexible(child: secondaryAction!),
                  const SizedBox(width: LiquidSpacing.sm),
                ],
                ...?primaryAction != null ? [Flexible(child: primaryAction!)] : null,
              ],
            ),
          ],
        ],
      ),
    );
  }
}
