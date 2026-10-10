import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/assistant/assistant_launch_context.dart';
import '../../guides/guide_controller.dart';
import '../../guides/guide_overlay.dart';
import '../../guides/guide_targets.dart';
import '../../premium/services/premium_gate.dart';
import '../../premium/widgets/premium_widgets.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_states.dart';
import '../models/sleep_schedule.dart';
import '../sleep_controller.dart';

/// P1 Sleep schedule screen: bedtime, wake time, duration, days, reminders.
///
/// Draft-then-save: edits are local until Save validates (overnight-aware)
/// and persists through [SleepController]. Overnight windows such as
/// 11:30 PM → 7:30 AM compute as 8h, never as a negative same-day span.
class SleepScheduleScreen extends StatefulWidget {
  const SleepScheduleScreen({super.key});

  @override
  State<SleepScheduleScreen> createState() => _SleepScheduleScreenState();
}

class _SleepScheduleScreenState extends State<SleepScheduleScreen> {
  late int _bedtime;
  late int _wake;
  late bool _enabled;
  late List<int> _days;
  late bool _bedtimeReminder;
  late bool _windDownReminder;
  late int _windDownMinutes;
  bool _saving = false;
  String? _error;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _loadDraft(SleepController.instance.schedule);
    SleepController.instance.addListener(_onChanged);
  }

  void _loadDraft(SleepSchedule? schedule) {
    _bedtime = schedule?.bedtimeMinutes ?? 1380;
    _wake = schedule?.wakeMinutes ?? 420;
    _enabled = schedule?.enabled ?? true;
    _days = List<int>.from(schedule?.days ?? const [1, 2, 3, 4, 5, 6, 7]);
    _bedtimeReminder = schedule?.bedtimeReminderEnabled ?? true;
    _windDownReminder = schedule?.windDownReminderEnabled ?? true;
    _windDownMinutes = schedule?.windDownMinutes ?? 30;
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SleepController.instance.removeListener(_onChanged);
    super.dispose();
  }

  int get _duration => SleepScheduleValidation.plannedMinutes(
        bedtimeMinutes: _bedtime,
        wakeMinutes: _wake,
      );

  String get _durationLabel {
    final h = _duration ~/ 60;
    final m = _duration % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Future<void> _pickTime({required bool isBedtime}) async {
    final initial = isBedtime ? _bedtime : _wake;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (picked != null && mounted) {
      setState(() {
        _error = null;
        if (isBedtime) {
          _bedtime = picked.hour * 60 + picked.minute;
        } else {
          _wake = picked.hour * 60 + picked.minute;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await SleepController.instance.saveSchedule(
      SleepSchedule(
        bedtimeMinutes: _bedtime,
        wakeMinutes: _wake,
        enabled: _enabled,
        days: _days,
        bedtimeReminderEnabled: _bedtimeReminder,
        windDownReminderEnabled: _windDownReminder,
        windDownMinutes: _windDownMinutes,
        createdAt: SleepController.instance.schedule?.createdAt,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _confirmRemove() async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove sleep schedule?'),
        content: const Text(
          'Student OS will stop planning around a sleep window and cancel its reminders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove == true) {
      await SleepController.instance.clearSchedule();
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final hasSchedule = SleepController.instance.hasSchedule;

    return AppScaffold(
      title: 'Sleep Schedule',
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          tooltip: 'How does Sleep planning work?',
          onPressed: () {
            GuideOverlayManager.ensureListening();
            GuideController.instance.startGuide('sleep');
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Window summary (light canonical treatment) ──
            AppCard(
              borderColor: palette.primary.withValues(alpha: 0.30),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bedtime_rounded,
                      color: palette.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${SleepScheduleValidation.formatClock12(_bedtime)} → '
                          '${SleepScheduleValidation.formatClock12(_wake)}',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_durationLabel planned',
                          style: context.text.bodySmall?.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(
              title: 'Schedule',
              subtitle: 'Overnight windows are fully supported',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  GuideTargetAnchor(
                    id: 'sleep.bedtime',
                    child: _TimeRow(
                      icon: Icons.bedtime_outlined,
                      label: 'Bedtime',
                      value: SleepScheduleValidation.formatClock12(_bedtime),
                      onTap: () => _pickTime(isBedtime: true),
                    ),
                  ),
                  const Divider(height: AppSpacing.lg),
                  GuideTargetAnchor(
                    id: 'sleep.wake',
                    child: _TimeRow(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Wake up',
                      value: SleepScheduleValidation.formatClock12(_wake),
                      onTap: () => _pickTime(isBedtime: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active days',
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        ChoiceChip(
                          label: Text(_dayLabels[d - 1]),
                          selected: _days.contains(d),
                          onSelected: (selected) {
                            setState(() {
                              _error = null;
                              if (selected) {
                                if (!_days.contains(d)) _days.add(d);
                              } else {
                                _days.remove(d);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Schedule enabled'),
                    subtitle: Text(
                      _enabled
                          ? 'Planning and reminders use this window'
                          : 'Paused — kept but ignored',
                    ),
                    value: _enabled,
                    onChanged: (v) =>
                        setState(() => _enabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(
              title: 'Reminders',
              subtitle: 'Gentle daily nudges, never medical advice',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bedtime reminder'),
                    subtitle: Text(
                      'Daily at ${SleepScheduleValidation.formatClock12(_bedtime)}',
                    ),
                    value: _bedtimeReminder,
                    onChanged: (v) =>
                        setState(() => _bedtimeReminder = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Wind-down reminder'),
                    subtitle: Text(
                      '$_windDownMinutes min before bed',
                    ),
                    value: _windDownReminder,
                    onChanged: (v) =>
                        setState(() => _windDownReminder = v),
                  ),
                  if (_windDownReminder)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final m in [15, 30, 45, 60])
                          ChoiceChip(
                            label: Text('${m}m'),
                            selected: _windDownMinutes == m,
                            onSelected: (_) =>
                                setState(() => _windDownMinutes = m),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppErrorState(message: _error!, onRetry: _save),
            ],
            const SizedBox(height: AppSpacing.lg),
            GuideTargetAnchor(
              id: 'sleep.save',
              child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_saving ? 'Saving…' : 'Save Schedule'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                // Sleep-aware planning is Pro; the schedule itself is free.
                if (!PremiumGate.check(
                    context, 'premium.sleep.awareness')) {
                  return;
                }
                AppRouter.openAssistant(
                  context,
                  initialQuery: 'Plan my day around my sleep',
                  launchContext: const AssistantLaunchContext(
                    origin: AssistantOrigin.sleep,
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Plan around my sleep'),
                  SizedBox(width: 6),
                  PremiumBadge(),
                ],
              ),
            ),
            if (hasSchedule) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _confirmRemove,
                child: Text(
                  'Remove schedule',
                  style: TextStyle(color: palette.error),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: palette.onSurfaceMuted, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: context.text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.onSurfaceMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
