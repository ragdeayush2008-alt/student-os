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
import 'schedule_conflict_dialog.dart';

/// Interactive daily agenda view rendering the unified academic schedule for a single day.
class DayScheduleView extends StatelessWidget {
  const DayScheduleView({
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
    final schedule = AcademicScheduleController.instance.getScheduleForDay(selectedDay);
    final now = DateTime.now();
    final isToday = AppWeekUtils.dateOnly(selectedDay) == AppWeekUtils.dateOnly(now);

    return Column(
      children: [
        // Day Navigation Strip
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
                  selectedDay.subtract(const Duration(days: 1)),
                ),
              ),
              Column(
                children: [
                  Text(
                    AppWeekUtils.formatDateHeader(selectedDay),
                    style: context.text.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isToday)
                    Text(
                      'TODAY',
                      style: context.text.labelSmall!.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => onDaySelected(
                  selectedDay.add(const Duration(days: 1)),
                ),
              ),
            ],
          ),
        ),

        // Conflicts Banner (if any)
        if (schedule.hasConflicts)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: AppPressable(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => ScheduleConflictDialog(
                    conflict: schedule.conflicts.first,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: const Color(0xFFE53935).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE53935), size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${schedule.conflicts.length} Schedule ${schedule.conflicts.length == 1 ? 'Conflict' : 'Conflicts'} Detected',
                        style: context.text.bodyMedium!.copyWith(
                          color: const Color(0xFFE53935),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'Resolve',
                      style: TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Availability Summary Strip
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
                _StatItem(
                  label: 'Committed',
                  value: _formatDuration(schedule.availability.committedMinutes),
                  color: palette.primary,
                  icon: Icons.school_rounded,
                ),
                _StatItem(
                  label: 'Planned',
                  value: _formatDuration(schedule.availability.plannedMinutes),
                  color: const Color(0xFF3B82F6),
                  icon: Icons.timer_outlined,
                ),
                _StatItem(
                  label: 'Free Time',
                  value: _formatDuration(schedule.availability.freeMinutes),
                  color: palette.success,
                  icon: Icons.hourglass_bottom_rounded,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Agenda Timeline List
        Expanded(
          child: schedule.items.isEmpty
              ? _EmptyScheduleDay(
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
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: schedule.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = schedule.items[index];
                    return _DayScheduleItemCard(
                      item: item,
                      onTap: () => _handleItemTap(context, item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _handleItemTap(BuildContext context, UnifiedScheduleItem item) {
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
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
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

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: context.text.labelLarge!.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.onSurface,
              ),
            ),
            Text(
              label,
              style: context.text.bodySmall!.copyWith(
                fontSize: 10,
                color: palette.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayScheduleItemCard extends StatelessWidget {
  const _DayScheduleItemCard({
    required this.item,
    required this.onTap,
  });

  final UnifiedScheduleItem item;
  final VoidCallback onTap;

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppPressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Time Axis Column
            SizedBox(
              width: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.allDay)
                    Text(
                      'ALL DAY',
                      style: context.text.labelSmall!.copyWith(
                        fontWeight: FontWeight.w800,
                        color: item.color,
                        fontSize: 10,
                      ),
                    )
                  else ...[
                    Text(
                      _formatTime(item.startAt),
                      style: context.text.labelLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.onSurface,
                      ),
                    ),
                    Text(
                      _formatTime(item.endAt),
                      style: context.text.bodySmall!.copyWith(
                        fontSize: 11,
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.durationMinutes}m',
                      style: context.text.bodySmall!.copyWith(
                        fontSize: 10,
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Color bar indicator
            Container(
              width: 4,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.statusLabel ?? 'EVENT',
                          style: TextStyle(
                            color: item.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item.hasConflict) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CONFLICT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                  if (item.location != null && item.location!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: palette.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Text(
                          item.location!,
                          style: context.text.bodySmall!.copyWith(
                            fontSize: 11,
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Button
            if (item.isPlanningBlock)
              IconButton.filledTonal(
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                tooltip: 'Start Focus',
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
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _EmptyScheduleDay extends StatelessWidget {
  const _EmptyScheduleDay({required this.onAddEvent});

  final VoidCallback onAddEvent;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded,
                size: 56, color: palette.primary.withValues(alpha: 0.6)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your schedule is clear',
              style: context.text.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No classes, exams, or study blocks scheduled for this day.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Commitment'),
              onPressed: onAddEvent,
            ),
          ],
        ),
      ),
    );
  }
}
