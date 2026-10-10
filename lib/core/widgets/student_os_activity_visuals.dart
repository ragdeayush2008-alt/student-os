import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';

/// Seven-day activity bars for the Analytics phase.
///
/// Values are normalized against the week maximum with a floor so small
/// differences are not exaggerated. Bars use the Student OS blue identity
/// with an optional sage accent for consistency metrics. Static rendering
/// (no animation) keeps scrolling at 60fps.
class StudentOSWeeklyBars extends StatelessWidget {
  const StudentOSWeeklyBars({
    super.key,
    required this.values,
    this.dayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    this.accent,
    this.highlightedIndex,
    this.maxValue,
    this.barValueLabel,
    this.semanticLabel = 'Weekly activity',
  });

  final List<double> values;
  final List<String> dayLabels;
  final Color? accent;
  final int? highlightedIndex;
  final double? maxValue;
  final String Function(double value)? barValueLabel;
  final String semanticLabel;

  /// Exactly 7 normalized values (padded with zeros when short).
  List<double> get week =>
      List<double>.generate(7, (i) => i < values.length ? values[i] : 0);

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final base = accent ?? palette.primary;
    final weekValues = week;
    final dataMax = weekValues.fold<double>(0, (m, v) => v > m ? v : m);
    // Floor the scale so tiny values don't render as full bars and zeros
    // stay visibly empty.
    final scale = (maxValue ?? dataMax).clamp(1.0, double.infinity);

    return Semantics(
      label: semanticLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: i == 0 || i == 6 ? 2 : 4,
                ),
                child: Semantics(
                  label:
                      '${dayLabels[i]}: ${barValueLabel?.call(weekValues[i]) ?? weekValues[i].toStringAsFixed(1)}',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 96,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 28),
                          height: (96 * (weekValues[i] / scale))
                              .clamp(4.0, 96.0),
                          decoration: BoxDecoration(
                            color: weekValues[i] <= 0
                                ? palette.surfaceVariant
                                : (highlightedIndex == i
                                    ? base
                                    : base.withValues(alpha: 0.55)),
                            borderRadius: BorderRadius.circular(
                              AppRadius.sm,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        dayLabels[i],
                        style: context.text.labelSmall?.copyWith(
                          color: highlightedIndex == i
                              ? palette.textPrimary
                              : palette.onSurfaceMuted,
                          fontWeight: highlightedIndex == i
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Consistency heatmap for the Analytics phase (GitHub-style weeks grid).
///
/// Uses the Sage/Forest tonal progression — never rainbow colors. Each cell
/// carries an accessible label and a tooltip where supported. Static,
/// const-friendly rendering.
class StudentOSHeatmap extends StatelessWidget {
  const StudentOSHeatmap({
    super.key,
    required this.weeks,
    this.maxValue,
    this.cellSize = 14,
    this.cellGap = 4,
    this.cellLabel,
    this.semanticLabel = 'Activity consistency',
  });

  /// Rows of 7 daily intensity values (oldest week first).
  final List<List<double>> weeks;
  final double? maxValue;
  final double cellSize;
  final double cellGap;
  final String Function(int week, int day, double value)? cellLabel;
  final String semanticLabel;

  /// Sage tonal progression for a normalized intensity in 0..1.
  static Color colorFor(double t, AppPalette palette) {
    final clamped = t.clamp(0.0, 1.0);
    if (clamped <= 0) return palette.surfaceVariant;
    if (clamped < 0.25) return palette.paleSage;
    if (clamped < 0.5) return palette.softSage;
    if (clamped < 0.75) return palette.sage;
    return palette.forest;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    if (weeks.isEmpty) {
      return const SizedBox.shrink();
    }
    final dataMax = weeks
        .expand((w) => w)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final scale = (maxValue ?? dataMax).clamp(1.0, double.infinity);

    return Semantics(
      label: semanticLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var w = 0; w < weeks.length; w++)
              Padding(
                padding: EdgeInsets.only(
                  right: w == weeks.length - 1 ? 0 : cellGap,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var d = 0; d < weeks[w].length; d++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: d == weeks[w].length - 1 ? 0 : cellGap,
                        ),
                        child: Tooltip(
                          message: cellLabel?.call(w, d, weeks[w][d]) ??
                              'Week ${w + 1}, day ${d + 1}: ${weeks[w][d].toStringAsFixed(1)}',
                          child: Semantics(
                            label: cellLabel?.call(w, d, weeks[w][d]),
                            child: Container(
                              width: cellSize,
                              height: cellSize,
                              decoration: BoxDecoration(
                                color: colorFor(
                                  weeks[w][d] / scale,
                                  palette,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: palette.outline.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
