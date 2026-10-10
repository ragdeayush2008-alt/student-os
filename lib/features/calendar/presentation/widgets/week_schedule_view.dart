import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/navigation/universal_action_executor.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_week_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../academic_schedule_controller.dart';
import '../../models/schedule_models.dart';
import 'add_edit_event_sheet.dart';

/// Weekly academic schedule overview showing a compact 7-day strip and detailed agenda.
class WeekScheduleView extends StatelessWidget {
  const WeekScheduleView({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.onAddEventPressed,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback? onAddEventPressed;

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final weekSchedule =
        AcademicScheduleController.instance.getScheduleForWeek(selectedDay);
    final startOfWeek = weekSchedule.startOfWeek;
    final endOfWeek = weekSchedule.endOfWeek;
    final now = DateTime.now();
    final today = AppWeekUtils.dateOnly(now);

    return Column(
      children: [
        // Week Navigator Header
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
                  selectedDay.subtract(const Duration(days: 7)),
                ),
              ),
              Text(
                '${AppWeekUtils.monthAbbr(startOfWeek.month)} ${startOfWeek.day} – ${AppWeekUtils.monthAbbr(endOfWeek.month)} ${endOfWeek.day}, ${endOfWeek.year}',
                style: context.text.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => onDaySelected(
                  selectedDay.add(const Duration(days: 7)),
                ),
              ),
            ],
          ),
        ),

        // Weekly Summary Metrics Bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeekMetric(
                  label: 'Committed',
                  value: _formatDuration(weekSchedule.totalCommittedMinutes),
                  color: palette.primary,
                  icon: Icons.school_rounded,
                ),
                _WeekMetric(
                  label: 'Planned',
                  value: _formatDuration(weekSchedule.totalPlannedMinutes),
                  color: const Color(0xFF3B82F6),
                  icon: Icons.timer_outlined,
                ),
                _WeekMetric(
                  label: 'Free Time',
                  value: _formatDuration(weekSchedule.totalFreeMinutes),
                  color: palette.success,
                  icon: Icons.hourglass_bottom_rounded,
                ),
                if (weekSchedule.examsCount > 0)
                  _WeekMetric(
                    label: 'Exams',
                    value: '${weekSchedule.examsCount}',
                    color: const Color(0xFFE53935),
                    icon: Icons.assignment_late_rounded,
                  ),
              ],
            ),
          ),
        ),

        // 7-Day Selector Strip
        Container(
          height: 84,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: weekSchedule.daySchedules.map((daySched) {
              final isSelected =
                  AppWeekUtils.dateOnly(daySched.date) ==
                  AppWeekUtils.dateOnly(selectedDay);
              final isDayToday =
                  AppWeekUtils.dateOnly(daySched.date) == today;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AppPressable(
                    onTap: () => onDaySelected(daySched.date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.primary.withValues(alpha: 0.18)
                            : (isDayToday
                                ? palette.primary.withValues(alpha: 0.08)
                                : palette.surface),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? palette.primary
                              : (isDayToday
                                  ? palette.primary.withValues(alpha: 0.4)
                                  : Colors.transparent),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ['M', 'T', 'W', 'T', 'F', 'S', 'S'][daySched.date.weekday - 1],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? palette.primary
                                  : palette.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${daySched.date.day}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? palette.primary
                                  : palette.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Activity Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (daySched.hasClasses)
                                _Dot(color: palette.primary),
                              if (daySched.hasExams)
                                const _Dot(color: Color(0xFFE53935)),
                              if (daySched.hasDeadlines)
                                const _Dot(color: Color(0xFFFF7043)),
                              if (daySched.planningBlocks.isNotEmpty)
                                const _Dot(color: Color(0xFF3B82F6)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(height: 1),

        // Selected Day Agenda in Week View
        Expanded(
          child: _SelectedDayAgendaInWeek(
            daySchedule: weekSchedule.daySchedules.firstWhere(
              (d) =>
                  AppWeekUtils.dateOnly(d.date) ==
                  AppWeekUtils.dateOnly(selectedDay),
              orElse: () => weekSchedule.daySchedules.first,
            ),
            onAddEvent: onAddEventPressed ??
                () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddEditEventSheet(
                      initialDate: selectedDay,
                    ),
                  );
                },
          ),
        ),
      ],
    );
  }
}

class _WeekMetric extends StatelessWidget {
  const _WeekMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: context.text.labelMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.onSurface,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: context.text.bodySmall!.copyWith(
            fontSize: 10,
            color: palette.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SelectedDayAgendaInWeek extends StatelessWidget {
  const _SelectedDayAgendaInWeek({
    required this.daySchedule,
    required this.onAddEvent,
  });

  final UnifiedDaySchedule daySchedule;
  final VoidCallback onAddEvent;

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    if (daySchedule.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available_rounded,
                  size: 44, color: palette.primary.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No commitments for ${AppWeekUtils.weekdayName(daySchedule.date.weekday)}',
                style: context.text.titleSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${daySchedule.availability.freeMinutes ~/ 60}h of free time available for study or revision.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Commitment'),
                onPressed: onAddEvent,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: daySchedule.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = daySchedule.items[index];

        return AppPressable(
          onTap: () {
            if (item.rawEvent != null) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddEditEventSheet(
                  initialEvent: item.rawEvent,
                ),
              );
            } else if (item.rawExam != null) {
              AppRouter.openExamDetail(context, item.rawExam!.id);
            } else if (item.rawTask != null) {
              AppRouter.openTaskDetail(context, item.rawTask!.id);
            } else if (item.rawPlanningBlock != null) {
              UniversalActionExecutor.startQuickFocus(
                context,
                subjectId: item.rawPlanningBlock!.subjectId,
                taskId: item.rawPlanningBlock!.taskId,
                topicId: item.rawPlanningBlock!.topicId,
                chapterId: item.rawPlanningBlock!.chapterId,
                planningBlockId: item.rawPlanningBlock!.id,
                focusTitle: item.title,
                duration: item.duration,
              );
            }
          },
          child: AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Time
                SizedBox(
                  width: 52,
                  child: item.allDay
                      ? Text(
                          'ALL DAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(item.startAt),
                              style: context.text.labelMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${item.durationMinutes}m',
                              style: context.text.bodySmall!.copyWith(
                                fontSize: 10,
                                color: palette.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                ),
                Container(
                  width: 3,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              item.statusLabel ?? 'EVENT',
                              style: TextStyle(
                                color: item.color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.hasConflict) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'CONFLICT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        style: context.text.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (item.isPlanningBlock)
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded,
                        color: Color(0xFF3B82F6)),
                    onPressed: () {
                      UniversalActionExecutor.startQuickFocus(
                        context,
                        subjectId: item.rawPlanningBlock!.subjectId,
                        taskId: item.rawPlanningBlock!.taskId,
                        topicId: item.rawPlanningBlock!.topicId,
                        chapterId: item.rawPlanningBlock!.chapterId,
                        planningBlockId: item.rawPlanningBlock!.id,
                        focusTitle: item.title,
                        duration: item.duration,
                      );
                    },
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
