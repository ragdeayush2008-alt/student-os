import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../tasks/presentation/task_creation_sheet.dart';
import '../plan_controller.dart';
import '../services/planning_engine.dart';

/// Modal bottom sheet for previewing, customizing, and applying an automated Daily Plan.
class DailyPlanSheet extends StatefulWidget {
  const DailyPlanSheet({
    super.key,
    required this.targetDay,
  });

  final DateTime targetDay;

  @override
  State<DailyPlanSheet> createState() => _DailyPlanSheetState();
}

class _DailyPlanSheetState extends State<DailyPlanSheet> {
  late int _selectedBudgetMinutes;
  DailyPlanResult? _currentPlan;
  bool _isApplying = false;

  static const _presetBudgets = [15, 30, 60, 120, 180, 240, 300];

  @override
  void initState() {
    super.initState();
    _selectedBudgetMinutes = PlanController.instance.dailyBudgetMinutes;
    _regeneratePlan();
  }

  void _regeneratePlan() {
    _currentPlan = PlanController.instance.generateDailyPlan(
      day: widget.targetDay,
      budgetMinutes: _selectedBudgetMinutes,
    );
  }

  String _formatTime(DateTime dt) {
    final tod = TimeOfDay.fromDateTime(dt);
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _editItemDuration(int index) {
    final plan = _currentPlan;
    if (plan == null || index < 0 || index >= plan.items.length) return;
    final item = plan.items[index];

    final durations = [15, 25, 30, 45, 60, 90];
    final palette = AppTheme.colorsOf(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Adjust Duration for ${item.title}',
              style: ctx.text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Select session length:',
              style: ctx.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: durations.map((d) {
                final isCurrent = d == item.estimatedMinutes;
                return ChoiceChip(
                  label: Text('$d min'),
                  selected: isCurrent,
                  onSelected: (selected) {
                    if (selected) {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _currentPlan = PlanningEngine.updatePlanItemDuration(
                          _currentPlan!,
                          index,
                          d,
                        );
                      });
                    }
                  },
                  selectedColor: palette.primary,
                  labelStyle: TextStyle(
                    color: isCurrent ? Colors.white : palette.onSurface,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _removeItem(int index) {
    final plan = _currentPlan;
    if (plan == null || index < 0 || index >= plan.items.length) return;
    setState(() {
      _currentPlan = PlanningEngine.removePlanItem(plan, index);
    });
  }

  void _promptCustomBudget() {
    final palette = AppTheme.colorsOf(context);
    final controller = TextEditingController(text: '$_selectedBudgetMinutes');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: const Text('Custom Available Time'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total minutes',
            suffixText: 'min',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.of(ctx).pop();
                setState(() {
                  _selectedBudgetMinutes = val;
                  _regeneratePlan();
                });
                PlanController.instance.setDailyBudgetMinutes(val);
              }
            },
            child: const Text('Set Budget'),
          ),
        ],
      ),
    );
  }

  void _openAddTaskSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskCreationSheet(
        initialDueDate: widget.targetDay,
        initialScheduledDate: widget.targetDay,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _regeneratePlan();
        });
      }
    });
  }

  Future<void> _applyPlan() async {
    final plan = _currentPlan;
    if (plan == null) return;

    setState(() => _isApplying = true);
    try {
      await PlanController.instance.applyDailyPlan(plan);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scheduled ${plan.items.length} sessions for today with transition reminders',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final plan = _currentPlan ??
        PlanController.instance.generateDailyPlan(
          day: widget.targetDay,
          budgetMinutes: _selectedBudgetMinutes,
        );

    final remainingOrOver = _selectedBudgetMinutes - plan.totalPlannedMinutes;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.onSurfaceMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan My Day',
                      style: context.text.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Automated distribution across subjects & tasks',
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: palette.onSurfaceMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Budget Selector Header + Add Task shortcut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How much time do you have?',
                style: context.text.labelMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.onSurfaceMuted,
                ),
              ),
              TextButton.icon(
                onPressed: _openAddTaskSheet,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Add Task'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Time Budget Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._presetBudgets.map((mins) {
                  final isSelected = mins == _selectedBudgetMinutes;
                  final label = mins >= 60 ? '${mins ~/ 60}h' : '${mins}m';
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedBudgetMinutes = mins;
                            _regeneratePlan();
                          });
                          PlanController.instance.setDailyBudgetMinutes(mins);
                        }
                      },
                      selectedColor: palette.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? palette.onPrimary : palette.onSurface,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: const Icon(Icons.tune_rounded, size: 14),
                    label: const Text('Custom'),
                    onPressed: _promptCustomBudget,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Status bar (Planned vs Available vs Remaining)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: plan.isOverloaded
                  ? palette.error.withValues(alpha: 0.1)
                  : palette.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: plan.isOverloaded
                  ? Border.all(color: palette.error.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  plan.isOverloaded
                      ? Icons.warning_amber_rounded
                      : Icons.auto_awesome_rounded,
                  size: 16,
                  color: plan.isOverloaded ? palette.error : palette.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.isOverloaded
                        ? 'Over budget by ${plan.overloadMinutes} min (${plan.totalPlannedMinutes} min planned / $_selectedBudgetMinutes min budget)'
                        : '${plan.items.length} sessions · ${plan.totalPlannedMinutes}m planned · ${remainingOrOver > 0 ? '$remainingOrOver min free' : 'fits budget'}',
                    style: context.text.bodySmall!.copyWith(
                      color: plan.isOverloaded ? palette.error : palette.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Items List
          Expanded(
            child: plan.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 32,
                          color: palette.onSurfaceMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No subjects or tasks found.',
                          style: context.text.titleSmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select subjects in Courses or add a task to get started.',
                          style: context.text.bodySmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: plan.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = plan.items[index];
                      final isScheduled = item.isAlreadyScheduled;

                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        borderColor: isScheduled
                            ? palette.primary.withValues(alpha: 0.3)
                            : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Time interval badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: palette.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                '${_formatTime(item.suggestedStart)}\n${_formatTime(item.suggestedEnd)}',
                                textAlign: TextAlign.center,
                                style: context.text.labelSmall!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Title & reason
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: context.text.titleSmall!.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isScheduled)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(AppRadius.xs),
                                          ),
                                          child: Text(
                                            'Scheduled',
                                            style: context.text.labelSmall!.copyWith(
                                              color: palette.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 8,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    item.reason,
                                    style: context.text.bodySmall!.copyWith(
                                      color: palette.onSurfaceMuted,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Editable Duration chip
                            AppPressable(
                              onTap: () => _editItemDuration(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.estimatedMinutes}m',
                                      style: context.text.labelSmall!.copyWith(
                                        color: palette.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 10,
                                      color: palette.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Remove block button
                            if (!isScheduled) ...[
                              const SizedBox(width: 2),
                              IconButton(
                                onPressed: () => _removeItem(index),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                color: palette.onSurfaceMuted,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                tooltip: 'Remove from plan',
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Apply Button
          if (plan.items.isNotEmpty)
            AppPressable(
              onTap: _isApplying ? () {} : _applyPlan,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: palette.accentGradient),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: _isApplying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Apply Plan',
                          style: context.text.labelLarge!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
