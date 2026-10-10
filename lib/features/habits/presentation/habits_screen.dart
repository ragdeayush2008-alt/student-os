import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_states.dart';
import '../../../data/models/habit_item.dart';
import '../habit_controller.dart';

/// Habits workspace — Tracks daily consistency routines and habit streaks.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final HabitController _controller = HabitController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDataChanged);
    _controller.load();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onDataChanged);
    super.dispose();
  }

  void _createHabitDialog() {
    final titleCtrl = TextEditingController();
    HabitFrequency freq = HabitFrequency.daily;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Create New Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g. Read 20 pages, Review flashcards',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Frequency:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              DropdownButton<HabitFrequency>(
                value: freq,
                isExpanded: true,
                onChanged: (v) {
                  if (v != null) setDlgState(() => freq = v);
                },
                items: HabitFrequency.values
                    .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  _controller.createHabit(
                    title: titleCtrl.text.trim(),
                    frequency: freq,
                  );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final habits = _controller.habits;

    return AppScaffold(
      title: 'Habits Tracker',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          tooltip: 'New Habit',
          onPressed: _createHabitDialog,
        ),
      ],
      body: habits.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppEmptyState(
                      title: 'No habits tracked',
                      icon: Icons.local_fire_department_rounded,
                      description: 'Build sustainable study routines by adding your first habit.',
                      compact: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _createHabitDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Habit'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screen),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return _HabitCard(
                  habit: habit,
                  onToggleToday: () => _controller.toggleHabitToday(habit.id),
                  onDelete: () => _controller.deleteHabit(habit.id),
                );
              },
            ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.onToggleToday,
    required this.onDelete,
  });

  final HabitItem habit;
  final VoidCallback onToggleToday;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final streak = habit.currentStreak;
    final isDoneToday = habit.isCompletedToday;
    final now = DateTime.now();

    // Past 7 days (including today)
    final pastDays = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDoneToday
                        ? palette.success.withValues(alpha: 0.15)
                        : palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    isDoneToday ? Icons.check_circle_rounded : Icons.local_fire_department_rounded,
                    size: 20,
                    color: isDoneToday ? palette.success : palette.streak,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            habit.frequency.label,
                            style: context.text.labelSmall!.copyWith(
                              color: palette.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                          if (streak > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: palette.streak.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '$streak d streak',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: palette.streak,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isDoneToday ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: isDoneToday ? palette.primary : palette.onSurfaceMuted,
                    size: 28,
                  ),
                  tooltip: isDoneToday ? 'Completed today' : 'Mark completed today',
                  onPressed: onToggleToday,
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: palette.onSurfaceMuted),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(Icons.delete_outline, color: palette.error),
                              title: Text('Delete Habit', style: TextStyle(color: palette.error)),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                onDelete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.xs),

            // 7-day mini activity history
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final day in pastDays) ...[
                  _DayBubble(
                    day: day,
                    isCompleted: habit.isCompletedOn(day),
                    isToday: HabitItem.dateKey(day) == HabitItem.dateKey(now),
                    palette: palette,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBubble extends StatelessWidget {
  const _DayBubble({
    required this.day,
    required this.isCompleted,
    required this.isToday,
    required this.palette,
  });

  final DateTime day;
  final bool isCompleted;
  final bool isToday;
  final AppPalette palette;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _weekdays[day.weekday - 1],
          style: TextStyle(
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday ? palette.primary : palette.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? palette.primary
                : palette.surfaceVariant.withValues(alpha: 0.5),
            border: isToday
                ? Border.all(color: palette.primary, width: 1.2)
                : null,
          ),
          child: isCompleted
              ? Icon(Icons.check, size: 12, color: palette.onPrimary,)
              : null,
        ),
      ],
    );
  }
}
