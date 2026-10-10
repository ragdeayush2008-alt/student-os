import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'app_completion_check.dart';
import 'app_pressable.dart';

/// Clean, responsive task tile with priority stripe, title, category, and date.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.showCheckbox = true,
  });

  final StudentTask task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final isCompleted = task.isCompleted;
    final isOverdue = task.isOverdue && !isCompleted;
    final priorityColor = isOverdue
        ? AppColors.error
        : task.priority.color;

    Widget card = AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      color: isCompleted ? palette.surfaceVariant.withValues(alpha: 0.4) : null,
      child: Row(
        children: [
          if (showCheckbox) ...[
            AppCompletionCheck(
              completed: isCompleted,
              onTap: onToggle ?? () {},
              size: 22,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Container(
            width: 3.5,
            height: 24,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.title,
                  style: context.text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? palette.onSurfaceMuted
                        : palette.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dueDate != null || task.category.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (task.category.isNotEmpty) ...[
                        Text(
                          task.category,
                          style: context.text.labelSmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                        if (task.dueDate != null)
                          Text(
                            ' · ',
                            style: TextStyle(
                              color: palette.onSurfaceMuted,
                              fontSize: 10,
                            ),
                          ),
                      ],
                      if (task.dueDate != null)
                        Text(
                          _formatDate(task.dueDate!),
                          style: context.text.labelSmall!.copyWith(
                            color: isOverdue
                                ? AppColors.error
                                : palette.onSurfaceMuted,
                            fontWeight: isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      card = AppPressable(onTap: onTap!, child: card);
    }

    return card;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'In $diff days';
    return '${date.day}/${date.month}';
  }
}
