import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_week_utils.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../academic_schedule_controller.dart';
import '../../models/schedule_models.dart';

/// Month calendar grid showing high-level academic commitments, exams, and deadlines.
class MonthScheduleView extends StatelessWidget {
  const MonthScheduleView({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onSwitchToDayView,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onSwitchToDayView;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final monthSummaries =
        AcademicScheduleController.instance.getScheduleForMonth(selectedDay);

    return Column(
      children: [
        // Month Navigation Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => onDaySelected(
                  DateTime(selectedDay.year, selectedDay.month - 1, 1),
                ),
              ),
              Text(
                '${AppWeekUtils.monthName(selectedDay.month)} ${selectedDay.year}',
                style: context.text.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => onDaySelected(
                  DateTime(selectedDay.year, selectedDay.month + 1, 1),
                ),
              ),
            ],
          ),
        ),

        // Weekday Column Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Month Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthSummaries.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.05,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final summary = monthSummaries[index];
                final isSelected =
                    AppWeekUtils.dateOnly(summary.date) ==
                    AppWeekUtils.dateOnly(selectedDay);

                return _MonthDayCell(
                  summary: summary,
                  isSelected: isSelected,
                  onTap: () {
                    onDaySelected(summary.date);
                  },
                );
              },
            ),
          ),
        ),

        // Selected Day Compact Inspector
        _MonthSelectedDayInspector(
          selectedDay: selectedDay,
          onViewDay: onSwitchToDayView,
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });

  final MonthDaySummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? palette.primary.withValues(alpha: 0.2)
              : (summary.isToday
                  ? palette.primary.withValues(alpha: 0.08)
                  : (summary.isCurrentMonth
                      ? palette.surface
                      : palette.surface.withValues(alpha: 0.3))),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected
                ? palette.primary
                : (summary.isToday
                    ? palette.primary.withValues(alpha: 0.4)
                    : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${summary.date.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected || summary.isToday ? FontWeight.w800 : FontWeight.w500,
                color: summary.isCurrentMonth
                    ? (isSelected ? palette.primary : palette.onSurface)
                    : palette.onSurfaceMuted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (summary.hasExams)
                  const _SmallDot(color: Color(0xFFE53935))
                else if (summary.hasDeadlines)
                  const _SmallDot(color: Color(0xFFFF7043))
                else if (summary.hasClasses)
                  _SmallDot(color: palette.primary)
                else if (summary.hasPlanning)
                  const _SmallDot(color: Color(0xFF3B82F6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallDot extends StatelessWidget {
  const _SmallDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MonthSelectedDayInspector extends StatelessWidget {
  const _MonthSelectedDayInspector({
    required this.selectedDay,
    required this.onViewDay,
  });

  final DateTime selectedDay;
  final VoidCallback onViewDay;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final schedule =
        AcademicScheduleController.instance.getScheduleForDay(selectedDay);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppWeekUtils.formatDateHeader(selectedDay),
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  schedule.items.isEmpty
                      ? 'No commitments scheduled'
                      : '${schedule.items.length} ${schedule.items.length == 1 ? "item" : "items"} · ${schedule.availability.freeMinutes ~/ 60}h free',
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.view_agenda_rounded, size: 16),
            label: const Text('Day View'),
            onPressed: onViewDay,
          ),
        ],
      ),
    );
  }
}
