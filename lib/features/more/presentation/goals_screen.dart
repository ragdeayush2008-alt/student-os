import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_animated_number.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_progress.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../goals/goal_controller.dart';
import '../../study/study_controller.dart';
import '../../tasks/task_controller.dart';

/// The full goals management screen.
///
/// Shows current targets, real progress toward those targets, and editing
/// capabilities. Every metric comes from [GoalController] (targets),
/// [StudyController] (study data) and [TaskController] (task data).
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    GoalController.instance.addListener(_onChanged);
    StudyController.instance.addListener(_onChanged);
    TaskController.instance.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    GoalController.instance.removeListener(_onChanged);
    StudyController.instance.removeListener(_onChanged);
    TaskController.instance.removeListener(_onChanged);
    super.dispose();
  }

  GoalProgress _dailyStudyProgress() {
    final target = GoalController.instance.dailyStudyTarget;
    final actual = StudyController.instance.todayDuration;
    return GoalProgress(
      current: actual.inMinutes.toDouble(),
      target: target.inMinutes.toDouble(),
      label: 'Daily study',
      unit: 'm',
    );
  }

  GoalProgress _weeklyStudyProgress() {
    final target = GoalController.instance.weeklyStudyTarget;
    final actual = StudyController.instance.weekTotalDuration;
    return GoalProgress(
      current: actual.inMinutes.toDouble(),
      target: target.inMinutes.toDouble(),
      label: 'Weekly study',
      unit: 'm',
    );
  }

  GoalProgress _weeklyTaskProgress() {
    final target = GoalController.instance.weeklyTaskTarget;
    final completed = _tasksCompletedThisWeek();
    return GoalProgress(
      current: completed.toDouble(),
      target: target.toDouble(),
      label: 'Weekly tasks',
      unit: 'tasks',
    );
  }

  int _tasksCompletedThisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday;
    final weekStart = today.subtract(Duration(days: weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return TaskController.instance.tasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      final completed = t.completedAt!;
      return !completed.isBefore(weekStart) && completed.isBefore(weekEnd);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final gc = GoalController.instance;
    final daily = _dailyStudyProgress();
    final weeklyStudy = _weeklyStudyProgress();
    final weeklyTasks = _weeklyTaskProgress();

    return AppScaffold(
      title: 'Goals',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: 'Study goals',
              icon: Icons.timer_outlined,
              subtitle: 'Track your focus rhythm',
            ),
            const SizedBox(height: AppSpacing.md),
            _GoalCard(
              title: 'Daily study target',
              progress: daily,
              icon: Icons.wb_sunny_outlined,
              onEdit: () => _editDailyTarget(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            _GoalCard(
              title: 'Weekly study target',
              progress: weeklyStudy,
              icon: Icons.view_week_outlined,
              onEdit: () => _editWeeklyStudyTarget(context),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: 'Productivity goal',
              icon: Icons.bolt_rounded,
              subtitle: 'Weekly task completion target',
            ),
            const SizedBox(height: AppSpacing.md),
            _GoalCard(
              title: 'Weekly task target',
              progress: weeklyTasks,
              icon: Icons.task_alt_rounded,
              onEdit: () => _editWeeklyTaskTarget(context),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: 'Personal focus',
              icon: Icons.center_focus_strong_rounded,
              subtitle: 'Your short-term goal',
            ),
            const SizedBox(height: AppSpacing.md),
            _PersonalGoalCard(
              goal: gc.personalGoal,
              onEdit: () => _editPersonalGoal(context),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _editDailyTarget(BuildContext context) {
    final current = GoalController.instance.dailyStudyTarget.inMinutes;
    _showNumberEditSheet(
      context,
      title: 'Daily study target',
      subtitle: 'How many minutes of study per day?',
      currentValue: current,
      unit: 'minutes',
      min: 5,
      max: 480,
      onSave: (v) =>
          GoalController.instance.setDailyStudyTarget(Duration(minutes: v)),
    );
  }

  void _editWeeklyStudyTarget(BuildContext context) {
    final current = GoalController.instance.weeklyStudyTarget.inMinutes;
    _showNumberEditSheet(
      context,
      title: 'Weekly study target',
      subtitle: 'How many minutes of study per week?',
      currentValue: current,
      unit: 'minutes',
      min: 10,
      max: 2400,
      onSave: (v) =>
          GoalController.instance.setWeeklyStudyTarget(Duration(minutes: v)),
    );
  }

  void _editWeeklyTaskTarget(BuildContext context) {
    _showNumberEditSheet(
      context,
      title: 'Weekly task target',
      subtitle: 'How many tasks to complete per week?',
      currentValue: GoalController.instance.weeklyTaskTarget,
      unit: 'tasks',
      min: 1,
      max: 100,
      onSave: GoalController.instance.setWeeklyTaskTarget,
    );
  }

  void _editPersonalGoal(BuildContext context) {
    final ctrl = TextEditingController(
      text: GoalController.instance.personalGoal,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PersonalGoalSheet(
        controller: ctrl,
        onSave: () {
          GoalController.instance.setPersonalGoal(ctrl.text);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showNumberEditSheet(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int currentValue,
    required String unit,
    required int min,
    required int max,
    required ValueChanged<int> onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NumberEditSheet(
        title: title,
        subtitle: subtitle,
        initialValue: currentValue,
        unit: unit,
        min: min,
        max: max,
        onSave: onSave,
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.title,
    required this.progress,
    required this.icon,
    required this.onEdit,
  });

  final String title;
  final GoalProgress progress;
  final IconData icon;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final color = progress.isComplete ? palette.success : palette.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    Text(
                      progress.hasTarget ? progress.summary : 'Not configured',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (progress.hasTarget)
                AppCircularProgress(
                  value: progress.fraction,
                  size: 56,
                  strokeWidth: 5,
                  color: color,
                  labelBuilder: (ctx, p) => AppAnimatedNumberText(
                    value: p * 100,
                    format: (v) => '${v.round()}%',
                    style: context.text.labelMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (progress.hasTarget) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: AppLinearProgress(
                value: progress.fraction,
                height: 6,
                color: color,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (progress.hasTarget && progress.remaining > 0)
                Text(
                  '${_formatRemaining(progress.remaining, progress.unit)} remaining',
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                )
              else if (progress.isComplete)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: palette.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Target reached',
                      style: context.text.bodySmall!.copyWith(
                        color: palette.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Edit target',
                    style: context.text.labelSmall!.copyWith(
                      color: palette.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRemaining(double value, String unit) {
    if (unit == 'm') {
      final mins = value.round();
      if (mins >= 60) {
        final h = mins ~/ 60;
        final m = mins % 60;
        return m == 0 ? '${h}h' : '${h}h ${m}m';
      }
      return '${mins}m';
    }
    if (unit == 'h') {
      final h = value.floor();
      final m = ((value - h) * 60).round();
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${value.round()} $unit';
  }
}

class _PersonalGoalCard extends StatelessWidget {
  const _PersonalGoalCard({required this.goal, required this.onEdit});

  final String goal;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (goal.isEmpty)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    size: 18,
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No personal goal set',
                        style: context.text.titleSmall,
                      ),
                      Text(
                        'Add a short-term focus to stay motivated.',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: palette.streak.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    size: 18,
                    color: palette.streak,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    goal,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                goal.isEmpty ? 'Set goal' : 'Edit goal',
                style: context.text.labelSmall!.copyWith(
                  color: palette.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberEditSheet extends StatefulWidget {
  const _NumberEditSheet({
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.unit,
    required this.min,
    required this.max,
    required this.onSave,
  });

  final String title;
  final String subtitle;
  final int initialValue;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onSave;

  @override
  State<_NumberEditSheet> createState() => _NumberEditSheetState();
}

class _NumberEditSheetState extends State<_NumberEditSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int? get _parsedValue => int.tryParse(_ctrl.text.trim());
  bool get _isValid {
    final v = _parsedValue;
    return v != null && v >= widget.min && v <= widget.max;
  }

  void _save() {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    widget.onSave(_parsedValue!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.subtitle, style: context.text.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              style: context.text.headlineSmall,
              decoration: InputDecoration(
                suffixText: widget.unit,
                hintStyle: context.text.bodyLarge!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: palette.outline),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: palette.primary, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_parsedValue != null && !_isValid)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Enter a value between ${widget.min} and ${widget.max}',
                  style: context.text.bodySmall!.copyWith(color: palette.error),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isValid && !_saving) ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  disabledBackgroundColor: palette.primary.withValues(
                    alpha: 0.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            palette.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Save',
                        style: context.text.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalGoalSheet extends StatefulWidget {
  const _PersonalGoalSheet({required this.controller, required this.onSave});

  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  State<_PersonalGoalSheet> createState() => _PersonalGoalSheetState();
}

class _PersonalGoalSheetState extends State<_PersonalGoalSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  bool get _canSave => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Personal goal', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'What are you focusing on right now?',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: widget.controller,
              autofocus: true,
              maxLines: 3,
              style: context.text.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g. Master algebra basics this week',
                hintStyle: context.text.bodyLarge!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: palette.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: palette.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canSave ? widget.onSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  disabledBackgroundColor: palette.primary.withValues(
                    alpha: 0.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save goal',
                  style: context.text.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
