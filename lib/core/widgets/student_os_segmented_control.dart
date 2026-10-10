import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';

/// Neutral-background segmented control with obvious solid selection.
/// Used for PLAN | STUDY and FOCUS | TIMER | STOPWATCH.
///
/// The selection indicator is a single shared pill that slides smoothly
/// between segments (rather than each segment cross-fading its own fill).
class StudentOSSegmentedControl<T> extends StatelessWidget {
  const StudentOSSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
  });

  final List<StudentOSSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final count = segments.length;
    final selectedIndex = segments.indexWhere((s) => s.value == selected);

    return Semantics(
      label: semanticLabel ?? 'Mode selector',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? StudentOSColors.darkSecondary
              : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(StudentOSRadius.large),
          border: Border.all(color: scheme.outline, width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth - 8;
            final itemWidth = trackWidth / count;
            // Alignment ranges -1..1; guard against a single segment.
            final alignX = count <= 1
                ? -1.0
                : selectedIndex * 2.0 / (count - 1) - 1.0;
            return Stack(
              children: [
                Row(
                  children: [
                    for (final s in segments)
                      Expanded(
                        child: _Segment<T>(
                          segment: s,
                          selected: s.value == selected,
                          onTap: () => onChanged(s.value),
                        ),
                      ),
                  ],
                ),
                Positioned.fill(
                  child: AnimatedAlign(
                    duration: reduceMotion
                        ? Duration.zero
                        : StudentOSMotion.standard,
                    curve: StudentOSMotion.easeOut,
                    alignment: Alignment(alignX, 0),
                    child: FractionallySizedBox(
                      widthFactor: 1 / count,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(
                            StudentOSRadius.standard,
                          ),
                          border:
                              Border.all(color: scheme.outline, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class StudentOSSegment<T> {
  const StudentOSSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  final StudentOSSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(StudentOSRadius.standard),
        child: InkWell(
          borderRadius: BorderRadius.circular(StudentOSRadius.standard),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (segment.icon != null) ...[
                  Icon(
                    segment.icon,
                    size: 16,
                    color: selected
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    segment.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}