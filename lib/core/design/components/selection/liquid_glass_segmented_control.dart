import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_surface.dart';

/// Translucent Liquid Glass Segmented Control for tabs, modes, and filters.
class LiquidGlassSegmentedControl<T> extends StatelessWidget {
  const LiquidGlassSegmentedControl({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.all(4),
  });

  final Map<T, String> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassSurface(
      level: GlassLevel.standard,
      radius: LiquidRadius.pill,
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.entries.map((entry) {
          final isSelected = entry.key == selected;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: LiquidSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? LiquidColors.primary.withValues(alpha: 0.35)
                          : Colors.white)
                      : Colors.transparent,
                  borderRadius: LiquidRadius.pillAll,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: isDark
                                ? LiquidColors.primary.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : LiquidColors.primary)
                        : (isDark
                            ? LiquidColors.textSecondaryDark
                            : LiquidColors.textSecondaryLight),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
