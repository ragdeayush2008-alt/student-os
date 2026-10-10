import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/navigation/universal_action_executor.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../academic_schedule_controller.dart';
import '../../models/schedule_models.dart';
import 'add_edit_event_sheet.dart';

/// Compact Today's Agenda signal card for Home 2.0.
class HomeTodayAgendaCard extends StatelessWidget {
  const HomeTodayAgendaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final now = DateTime.now();
    final schedule =
        AcademicScheduleController.instance.getScheduleForDay(now);

    // Filter to items that are either upcoming today or currently in progress
    final activeOrUpcoming = schedule.items
        .where((item) =>
            item.allDay ||
            item.endAt.isAfter(now) ||
            item.endAt.isAtSameMomentAs(now))
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: "Today's Schedule",
          icon: Icons.calendar_today_rounded,
          trailing: TextButton(
            onPressed: () => AppRouter.openCalendar(context),
            child: const Text('Schedule'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activeOrUpcoming.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: palette.success,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    schedule.items.isEmpty
                        ? 'Your schedule is clear today.'
                        : 'All commitments completed for today!',
                    style: context.text.bodyMedium!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddEditEventSheet(),
                    );
                  },
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                for (int i = 0; i < activeOrUpcoming.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 12,
                      color: palette.onSurface.withValues(alpha: 0.06),
                    ),
                  _AgendaRow(
                    item: activeOrUpcoming[i],
                    now: now,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.item,
    required this.now,
  });

  final UnifiedScheduleItem item;
  final DateTime now;

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final isCurrent = !item.allDay &&
        now.isAfter(item.startAt) &&
        now.isBefore(item.endAt);

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
        } else {
          AppRouter.openCalendar(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Time Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isCurrent
                    ? palette.success.withValues(alpha: 0.15)
                    : item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.allDay ? 'ALL DAY' : _formatTime(item.startAt),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? palette.success : item.color,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle.isNotEmpty)
                    Text(
                      item.subtitle,
                      style: context.text.bodySmall!.copyWith(
                        fontSize: 11,
                        color: palette.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Badge / Action
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NOW',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.statusLabel ?? 'EVENT',
                  style: TextStyle(
                    fontSize: 9,
                    color: item.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
