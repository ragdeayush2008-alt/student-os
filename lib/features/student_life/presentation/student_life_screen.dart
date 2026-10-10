import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../preferences/user_preferences_controller.dart';
import '../models/daily_life_plan.dart';
import '../models/life_routine_item.dart';
import '../models/sleep_summary.dart';
import '../models/student_life_preferences.dart';
import '../student_life_controller.dart';

class StudentLifeScreen extends StatefulWidget {
  const StudentLifeScreen({super.key});

  @override
  State<StudentLifeScreen> createState() => _StudentLifeScreenState();
}

class _StudentLifeScreenState extends State<StudentLifeScreen> {
  StudentLifeController get _controller => StudentLifeController.instance;

  @override
  void initState() {
    super.initState();
    _controller.init();
    _controller.addListener(_onChanged);
    _controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final plan = _controller.dailyPlan();
    final summary = _controller.sleepSummary();

    return AppScaffold(
      title: 'Student Life',
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Routine settings',
          onPressed: _openSettings,
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxxl,
            ),
            children: [
              _SleepCard(
                plan: plan,
                summary: summary,
                palette: palette,
                onLogSleep: _openLogSleep,
              ),
              const SizedBox(height: AppSpacing.md),
              if (plan.hasWarnings) ...[
                _WarningsCard(warnings: plan.warnings, palette: palette),
                const SizedBox(height: AppSpacing.md),
              ],
              _StudyTargetCard(plan: plan, palette: palette),
              const SizedBox(height: AppSpacing.md),
              _RoutineCard(
                plan: plan,
                palette: palette,
                isDone: (item) => _controller.isRoutineItemDone(
                  plan.day,
                  item.id,
                ),
                onToggle: (item) =>
                    _controller.toggleRoutineItemDone(plan.day, item.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLogSleep() async {
    final prefs = _controller.preferences;
    final now = TimeOfDay.now();
    var bedtime = TimeOfDay(
      hour: prefs.targetBedtimeMinutes ~/ 60,
      minute: prefs.targetBedtimeMinutes % 60,
    );
    var wake = TimeOfDay(
      hour: prefs.targetWakeMinutes ~/ 60,
      minute: prefs.targetWakeMinutes % 60,
    );
    if (bedtime.hour == 0 && bedtime.minute == 0) bedtime = now;
    if (wake.hour == 0 && wake.minute == 0) wake = now;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          title: const Text('Log sleep'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bedtime'),
                trailing: Text(
                  formatTimeOfDay(bedtime),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: bedtime,
                  );
                  if (picked != null) setDlg(() => bedtime = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Wake up'),
                trailing: Text(
                  formatTimeOfDay(wake),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: wake,
                  );
                  if (picked != null) setDlg(() => wake = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final today = DateTime.now();
                var bedtimeDt = DateTime(
                  today.year,
                  today.month,
                  today.day,
                  bedtime.hour,
                  bedtime.minute,
                );
                var wakeDt = DateTime(
                  today.year,
                  today.month,
                  today.day,
                  wake.hour,
                  wake.minute,
                );
                if (!wakeDt.isAfter(bedtimeDt)) {
                  wakeDt = wakeDt.add(const Duration(days: 1));
                }
                if (bedtimeDt.isAfter(today)) {
                  bedtimeDt = bedtimeDt.subtract(const Duration(days: 1));
                  wakeDt = wakeDt.subtract(const Duration(days: 1));
                }
                await _controller.logSleep(
                  bedtime: bedtimeDt,
                  wakeTime: wakeDt,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    var prefs = _controller.preferences;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) {
          Future<void> update(StudentLifePreferences next) async {
            prefs = next;
            setSheet(() {});
            await _controller.updatePreferences(next);
          }

          Future<void> pickTime({
            required int currentMinutes,
            required ValueChanged<int> onPicked,
          }) async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: currentMinutes ~/ 60,
                minute: currentMinutes % 60,
              ),
            );
            if (picked != null) {
              onPicked(picked.hour * 60 + picked.minute);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Routine settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Student Life enabled'),
                    subtitle: const Text('Show daily routine and sleep.'),
                    value: prefs.enabled,
                    onChanged: (v) => update(prefs.copyWith(enabled: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Routine reminders'),
                    subtitle: const Text('Hydration, meals, wind-down, bedtime.'),
                    value: prefs.notificationsEnabled,
                    onChanged: (v) =>
                        update(prefs.copyWith(notificationsEnabled: v)),
                  ),
                  const Divider(),
                  Text(
                    'Sleep target',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Slider(
                    value: prefs.targetSleepMinutes.toDouble(),
                    min: 300,
                    max: 600,
                    divisions: 20,
                    label: _formatMinutes(prefs.targetSleepMinutes),
                    onChanged: (v) => update(
                      prefs.copyWith(targetSleepMinutes: v.round()),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Target bedtime'),
                    trailing: Text(
                      StudentLifePreferences.formatClock(
                        prefs.targetBedtimeMinutes,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => pickTime(
                      currentMinutes: prefs.targetBedtimeMinutes,
                      onPicked: (m) => update(
                        prefs.copyWith(targetBedtimeMinutes: m),
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Target wake time'),
                    trailing: Text(
                      StudentLifePreferences.formatClock(
                        prefs.targetWakeMinutes,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => pickTime(
                      currentMinutes: prefs.targetWakeMinutes,
                      onPicked: (m) => update(
                        prefs.copyWith(targetWakeMinutes: m),
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Wind-down'),
                    trailing: Text(
                      '${prefs.windDownMinutes}m',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => update(
                      prefs.copyWith(
                        windDownMinutes: prefs.windDownMinutes == 30 ? 60 : 30,
                      ),
                    ),
                  ),
                  const Divider(),
                  Text(
                    'Daily routine',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Study target'),
                    trailing: Text(
                      '${prefs.dailyStudyTargetMinutes}m',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      final next = (prefs.dailyStudyTargetMinutes + 30) % 330;
                      update(
                        prefs.copyWith(dailyStudyTargetMinutes: next),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hydration reminders'),
                    trailing: DropdownButton<HydrationFrequency>(
                      value: prefs.hydration,
                      onChanged: (v) {
                        if (v != null) update(prefs.copyWith(hydration: v));
                      },
                      items: HydrationFrequency.values
                          .map(
                            (h) => DropdownMenuItem(
                              value: h,
                              child: Text(h.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Meal reminders'),
                    value: prefs.mealRemindersEnabled,
                    onChanged: (v) =>
                        update(prefs.copyWith(mealRemindersEnabled: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Optional nap'),
                    value: prefs.napEnabled,
                    onChanged: (v) => update(prefs.copyWith(napEnabled: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Exercise anchor'),
                    value: prefs.exerciseEnabled,
                    onChanged: (v) =>
                        update(prefs.copyWith(exerciseEnabled: v)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class _SleepCard extends StatelessWidget {
  const _SleepCard({
    required this.plan,
    required this.summary,
    required this.palette,
    required this.onLogSleep,
  });

  final DailyLifePlan plan;
  final SleepSummary summary;
  final AppPalette palette;
  final VoidCallback onLogSleep;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nightlight_round, color: palette.forest),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Sleep',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: onLogSleep,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Last night',
                  value: summary.lastNightLabel,
                  palette: palette,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: '7-night average',
                  value: summary.averageLabel,
                  palette: palette,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Target',
                  value: _formatMinutes(plan.targetSleepMinutes),
                  palette: palette,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tonight\'s window: '
            '${StudentLifePreferences.formatClock(plan.sleepWindowStart.hour * 60 + plan.sleepWindowStart.minute)}'
            ' – '
            '${StudentLifePreferences.formatClock(plan.sleepWindowEnd.hour * 60 + plan.sleepWindowEnd.minute)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          if (summary.lastNightBedtime != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Bedtime ${StudentLifePreferences.formatClock(summary.lastNightBedtime!.hour * 60 + summary.lastNightBedtime!.minute)}'
              ' · Wake ${StudentLifePreferences.formatClock(summary.lastNightWake!.hour * 60 + summary.lastNightWake!.minute)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WarningsCard extends StatelessWidget {
  const _WarningsCard({required this.warnings, required this.palette});

  final List<String> warnings;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: palette.warning.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: palette.warning),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Protect your sleep',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Text(
                '• $warning',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _StudyTargetCard extends StatelessWidget {
  const _StudyTargetCard({required this.plan, required this.palette});

  final DailyLifePlan plan;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final target = plan.studyTargetMinutes;
    final scheduled = plan.scheduledStudyMinutes;
    final progress = target <= 0 ? 0.0 : (scheduled / target).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: palette.forest),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Study target',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '$scheduled / ${target}m',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: palette.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            ),
          ),
          if (target > 0 && scheduled < target) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${target - scheduled}m left — a goal, not a requirement.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.plan,
    required this.palette,
    required this.isDone,
    required this.onToggle,
  });

  final DailyLifePlan plan;
  final AppPalette palette;
  final bool Function(LifeRoutineItem item) isDone;
  final ValueChanged<LifeRoutineItem> onToggle;

  @override
  Widget build(BuildContext context) {
    final items = plan.routineItems;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: palette.forest),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Today\'s routine',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${plan.completedRoutineCount}/${items.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          if (items.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No routine items scheduled.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
          for (final item in items)
            _RoutineRow(
              item: item,
              palette: palette,
              done: isDone(item),
              onToggle: () => onToggle(item),
            ),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.item,
    required this.palette,
    required this.done,
    required this.onToggle,
  });

  final LifeRoutineItem item;
  final AppPalette palette;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final timeLabel = StudentLifePreferences.formatClock(
      item.startAt.hour * 60 + item.startAt.minute,
    );
    return InkWell(
      onTap: onToggle,
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: done ? palette.forest : palette.textTertiary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 52,
              child: Text(
                timeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? palette.textTertiary : palette.textPrimary,
                    ),
                  ),
                  if (item.detail != null)
                    Text(
                      item.detail!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (item.isOptional)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: AppRadius.xsAll,
                ),
                child: Text(
                  'Optional',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
