import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'glass_surface.dart';

/// Translucent Liquid Glass Chip / Pill.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.isSelected = false,
    this.onTap,
    this.trailing,
    this.padding,
    this.radius = LiquidRadius.pill,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? theme.colorScheme.primary;

    final bg = isSelected
        ? effectiveColor.withValues(alpha: isDark ? 0.35 : 0.20)
        : (color != null
            ? effectiveColor.withValues(alpha: isDark ? 0.12 : 0.08)
            : null);

    final border = isSelected
        ? effectiveColor.withValues(alpha: isDark ? 0.8 : 0.6)
        : (color != null
            ? effectiveColor.withValues(alpha: isDark ? 0.3 : 0.2)
            : null);

    final textColor = isSelected
        ? effectiveColor
        : (color ??
            (isDark ? theme.colorScheme.onSurface : theme.colorScheme.onSurface));

    return GlassSurface(
      level: isSelected ? GlassLevel.elevated : GlassLevel.standard,
      radius: radius,
      backgroundColor: bg,
      borderColor: border,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: LiquidSpacing.sm,
            vertical: 6,
          ),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 5),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Convenience typedef for GlassPill
typedef GlassPill = GlassChip;
