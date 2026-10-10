import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// Shared formatting helpers for the Progress destination.
abstract final class ProgressFormat {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _weekdaysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String weekday(int weekday) => _weekdays[weekday - 1];
  static String weekdayFull(int weekday) => _weekdaysFull[weekday - 1];

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String month(int m) => _months[m - 1];

  /// Formats a [Duration] into a compact "5h 20m"-style string.
  static String duration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    if (hours > 0) return '$hours${mins > 0 ? 'h $mins' : ''}m';
    if (mins > 0) return '${mins}m';
    return '${d.inSeconds}s';
  }

  /// Compact minutes (e.g. "120m").
  static String minutes(Duration d) {
    final mins = d.inMinutes;
    return mins < 1 ? '0m' : '${mins}m';
  }

  /// A human date like "Tue, 24 Aug".
  static String shortDate(DateTime d) =>
      '${weekday(d.weekday)}, ${d.day} ${month(d.month)}';

  /// A short weekday initial (e.g. "M", "T", "W").
  static String dayMarker(DateTime d) => weekday(d.weekday).substring(0, 1);
}

/// A small reusable pill chip used for progress context/date labels.
class ProgressChip extends StatelessWidget {
  const ProgressChip({super.key, required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final fill = color ?? palette.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: fill.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(1000),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: fill),
            const SizedBox(width: 5),
          ],
          Text(label, style: context.text.labelMedium!.copyWith(color: fill)),
        ],
      ),
    );
  }
}

/// Wraps a section so it fades + slides in only during the coordinated entrance
/// sequence. Data-driven rebuilds (from source controllers) do not replay this
/// animation because section children are cached. Reduced-motion is respected.
class ProgressEntrance extends StatelessWidget {
  const ProgressEntrance({
    super.key,
    required this.animation,
    required this.child,
    this.offset = 26,
  });

  final Animation<double> animation;
  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    // TCC: Fade + 4% vertical slide with static child.
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Builds a coordinated entrance animation with staggered sections — TCC 450ms.
class ProgressEntranceSequence {
  ProgressEntranceSequence(TickerProvider vsync) {
    controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 450),
    )..forward();
    header = _stagger(0.00, 0.20);
    hero = _stagger(0.10, 0.34);
    selector = _stagger(0.22, 0.46);
    chart = _stagger(0.34, 0.58);
    performance = _stagger(0.46, 0.70);
    insights = _stagger(0.58, 0.82);
    milestones = _stagger(0.70, 0.96);
  }

  late final AnimationController controller;
  late final Animation<double> header;
  late final Animation<double> hero;
  late final Animation<double> selector;
  late final Animation<double> chart;
  late final Animation<double> performance;
  late final Animation<double> insights;
  late final Animation<double> milestones;

  Animation<double> _stagger(double begin, double end) {
    return controller.drive(
      CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic)),
    );
  }

  void dispose() => controller.dispose();
}
