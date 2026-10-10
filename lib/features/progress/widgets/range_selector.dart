import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../progress_controller.dart';

/// Section — animated time-range selector (Today / Week / Month).
///
/// The selected indicator animates smoothly between options, there are no
/// layout jumps (fixed-width cells), rapid switching is safe, and reduced-motion
/// is respected. Range changes recompute real data via [ProgressController].
class RangeSelector extends StatelessWidget {
  const RangeSelector({super.key, required this.range, required this.onSelect});

  final ProgressRange range;
  final ValueChanged<ProgressRange> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(1000),
      ),
      child: Row(
        children: [
          for (final r in ProgressRange.values) ...[
            Expanded(
              child: _RangeCell(
                range: r,
                selected: r == range,
                onTap: () => onSelect(r),
              ),
            ),
            if (r != ProgressRange.values.last) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

class _RangeCell extends StatelessWidget {
  const _RangeCell({
    required this.range,
    required this.selected,
    required this.onTap,
  });

  final ProgressRange range;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 280);

    final labelColor = selected ? palette.onPrimary : palette.onSurfaceMuted;
    const height = 38.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(1000),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: duration,
          curve: Curves.easeOutCubic,
          style: context.text.labelMedium!.copyWith(
            color: labelColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(range.label),
        ),
      ),
    );
  }
}
