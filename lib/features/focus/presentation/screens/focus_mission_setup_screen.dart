import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../data/models/exam.dart';
import '../../../../data/models/task.dart';
import '../../../../features/exams/exam_controller.dart';
import '../../../../features/tasks/task_controller.dart';
import '../../controller/focus_controller.dart';
import '../../../premium/services/premium_gate.dart';
import '../../../premium/widgets/premium_widgets.dart';
import '../../controller/focus_guard_controller.dart';
import '../../data/models/focus_guard_models.dart';
import '../../data/models/focus_mission.dart';
import 'focus_guard_settings_screen.dart';
import 'focus_session_screen.dart';
import '../../../../features/study/study_subjects.dart';

class FocusMissionSetupScreen extends StatefulWidget {
  const FocusMissionSetupScreen({super.key});

  @override
  State<FocusMissionSetupScreen> createState() =>
      _FocusMissionSetupScreenState();
}

class _FocusMissionSetupScreenState extends State<FocusMissionSetupScreen> {
  final _objectiveController = TextEditingController();
  FocusMode _selectedMode = FocusMode.timer;
  Duration _selectedDuration = const Duration(minutes: 25);
  DistractionProtectionLevel _protectionLevel = DistractionProtectionLevel.off;
  String? _selectedTaskId;
  String? _selectedExamId;
  String? _selectedSubject;

  @override
  void dispose() {
    _objectiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final tc = TaskController.instance;
    final ec = ExamController.instance;
    final activeTasks = tc.activeTasks.take(5).toList();
    final upcomingExams = ec.upcomingExams.take(5).toList();

    return AppScaffold(
      title: 'Focus Mission',
      onBack: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Objective ──────────────────────────────
            const _SectionHeader(
              icon: Icons.flag_rounded,
              title: 'WHAT ARE YOU WORKING ON?',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: TextField(
                controller: _objectiveController,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., Finish Chapter 3, Solve 20 math questions',
                  hintStyle: context.text.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Connect to existing ────────────────────
            const _SectionHeader(
              icon: Icons.link_rounded,
              title: 'CONNECT TO EXISTING',
            ),
            const SizedBox(height: AppSpacing.sm),
            if (activeTasks.isNotEmpty) ...[
              Text(
                'Tasks',
                style: context.text.labelSmall?.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...activeTasks.map((task) => _buildTaskChip(task, palette)),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (upcomingExams.isNotEmpty) ...[
              Text(
                'Exams',
                style: context.text.labelSmall?.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...upcomingExams.map((exam) => _buildExamChip(exam, palette)),
              const SizedBox(height: AppSpacing.sm),
            ],
            _buildSubjectPicker(palette),
            const SizedBox(height: AppSpacing.md),

            // ── Duration ───────────────────────────────
            const _SectionHeader(icon: Icons.timer_rounded, title: 'HOW LONG?'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final d in [
                  const Duration(minutes: 15),
                  const Duration(minutes: 25),
                  const Duration(minutes: 45),
                  const Duration(minutes: 60),
                  const Duration(minutes: 90),
                ])
                  _DurationChip(
                    duration: d,
                    selected: _selectedDuration == d,
                    onTap: () => setState(() => _selectedDuration = d),
                    palette: palette,
                  ),
                AppPressable(
                  onTap: () => _showCustomDurationDialog(context, palette),
                  child: AppCard(
                    color: _selectedDuration.inMinutes == 0
                        ? palette.primaryContainer.withValues(alpha: 0.15)
                        : null,
                    borderColor: _selectedDuration.inMinutes == 0
                        ? palette.primary.withValues(alpha: 0.3)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'Custom',
                      style: context.text.labelMedium?.copyWith(
                        color: _selectedDuration.inMinutes == 0
                            ? palette.primary
                            : palette.onSurfaceMuted,
                        fontWeight: _selectedDuration.inMinutes == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Focus Style ────────────────────────────
            const _SectionHeader(
              icon: Icons.auto_awesome_rounded,
              title: 'FOCUS STYLE',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final mode in FocusMode.values)
                  _ModeChip(
                    mode: mode,
                    selected: _selectedMode == mode,
                    onTap: () => setState(() => _selectedMode = mode),
                    palette: palette,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Distraction Protection ─────────────────
            const _SectionHeader(
              icon: Icons.shield_rounded,
              title: 'DISTRACTION PROTECTION',
            ),
            const SizedBox(height: AppSpacing.sm),
            ...DistractionProtectionLevel.values.map(
              (level) => _ProtectionOption(
                level: level,
                selected: _protectionLevel == level,
                onTap: () {
                  // Deep protection is Pro; other levels stay free.
                  if (level == DistractionProtectionLevel.deep &&
                      !PremiumGate.check(
                          context, 'premium.focus.deep')) {
                    return;
                  }
                  setState(() => _protectionLevel = level);
                },
                palette: palette,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Start Button ───────────────────────────
            AppPressable(
              onTap: _selectedMode == FocusMode.timer
                  ? () => _startQuick()
                  : () => _startMission(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: palette.onPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _selectedMode == FocusMode.timer
                          ? 'Start Focus'
                          : 'Start Mission',
                      style: context.text.titleMedium?.copyWith(
                        color: palette.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskChip(StudentTask task, AppPalette palette) {
    final selected = _selectedTaskId == task.id;
    return AppPressable(
      onTap: () => setState(() => _selectedTaskId = selected ? null : task.id),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        color: selected
            ? palette.primaryContainer.withValues(alpha: 0.15)
            : null,
        borderColor: selected ? palette.primary.withValues(alpha: 0.3) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3.5,
              height: 20,
              decoration: BoxDecoration(
                color: task.priority.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              task.title,
              style: context.text.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamChip(StudentExam exam, AppPalette palette) {
    final selected = _selectedExamId == exam.id;
    return AppPressable(
      onTap: () => setState(() => _selectedExamId = selected ? null : exam.id),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        color: selected
            ? palette.primaryContainer.withValues(alpha: 0.15)
            : null,
        borderColor: selected ? palette.primary.withValues(alpha: 0.3) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_rounded, color: palette.primary, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Text(
              exam.title,
              style: context.text.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPicker(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject',
          style: context.text.labelSmall?.copyWith(
            color: palette.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ...StudySubjects.all.map(
              (subj) => AppPressable(
                onTap: () => setState(
                  () => _selectedSubject = subj.name == _selectedSubject
                      ? null
                      : subj.name,
                ),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  color: _selectedSubject == subj.name
                      ? subj.color.withValues(alpha: 0.15)
                      : null,
                  borderColor: _selectedSubject == subj.name
                      ? subj.color.withValues(alpha: 0.4)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        subj.icon,
                        size: 14,
                        color: _selectedSubject == subj.name
                            ? subj.color
                            : palette.onSurfaceMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subj.name,
                        style: context.text.labelSmall?.copyWith(
                          color: _selectedSubject == subj.name
                              ? subj.color
                              : palette.onSurfaceMuted,
                          fontWeight: _selectedSubject == subj.name
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCustomDurationDialog(BuildContext context, AppPalette palette) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Custom Duration',
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Minutes',
                  suffixText: 'min',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPressable(
                onTap: () {
                  final mins = int.tryParse(controller.text);
                  if (mins != null && mins > 0) {
                    setState(() {
                      _selectedDuration = Duration(minutes: mins);
                    });
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Center(
                    child: Text(
                      'Set',
                      style: context.text.labelMedium?.copyWith(
                        color: palette.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuick() {
    FocusController.instance.startQuickFocus(duration: _selectedDuration);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FocusSessionScreen()),
    );
  }

  void _startMission() {
    final guard = FocusGuardController.instance;
    if (guard.isGuardEnabled &&
        guard.blockedPackages.isNotEmpty &&
        guard.permissionStatus != FocusGuardPermissionStatus.ready &&
        guard.permissionStatus != FocusGuardPermissionStatus.unsupported) {
      _showPermissionWarningDialog();
      return;
    }
    _proceedWithStartMission();
  }

  void _proceedWithStartMission() {
    final objective = _objectiveController.text.trim().isEmpty
        ? 'Study Session'
        : _objectiveController.text.trim();

    final mission = FocusMission(
      id: 'mission_${DateTime.now().millisecondsSinceEpoch}_${FocusController.instance.sessions.length + 1}',
      objective: objective,
      subjectName: _selectedSubject,
      taskId: _selectedTaskId,
      examId: _selectedExamId,
      mode: _selectedMode,
      plannedDuration: _selectedDuration,
      distractionProtection: _protectionLevel,
    );

    FocusController.instance.startMission(mission);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FocusSessionScreen()),
    );
  }

  void _showPermissionWarningDialog() {
    final palette = AppTheme.colorsOf(context);
    final guard = FocusGuardController.instance;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          'Focus Guard Setup',
          style: ctx.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus Guard is configured to block ${guard.blockedPackages.length} apps, but required Android permissions are missing.',
              style: ctx.text.bodyMedium?.copyWith(color: palette.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  guard.hasUsageAccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: guard.hasUsageAccess ? palette.success : palette.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text('Usage Access', style: ctx.text.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  guard.hasOverlayPermission ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: guard.hasOverlayPermission ? palette.success : palette.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text('Display over other apps', style: ctx.text.bodySmall),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _proceedWithStartMission();
            },
            child: Text(
              'Continue Without Guard',
              style: TextStyle(color: palette.onSurfaceMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FocusGuardSettingsScreen()),
              );
            },
            child: const Text('Set up Focus Guard'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.colorsOf(context).primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.duration,
    required this.selected,
    required this.onTap,
    required this.palette,
  });
  final Duration duration;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        color: selected
            ? palette.primaryContainer.withValues(alpha: 0.15)
            : null,
        borderColor: selected ? palette.primary.withValues(alpha: 0.3) : null,
        child: Text(
          '${duration.inMinutes} min',
          style: context.text.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? palette.primary : palette.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.onTap,
    required this.palette,
  });
  final FocusMode mode;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        color: selected
            ? palette.primaryContainer.withValues(alpha: 0.15)
            : null,
        borderColor: selected ? palette.primary.withValues(alpha: 0.3) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _modeIcon(mode),
              size: 14,
              color: selected ? palette.primary : palette.onSurfaceMuted,
            ),
            const SizedBox(width: 4),
            Text(
              mode.label,
              style: context.text.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? palette.primary : palette.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _modeIcon(FocusMode mode) {
    switch (mode) {
      case FocusMode.timer:
        return Icons.timer_outlined;
      case FocusMode.stopwatch:
        return Icons.av_timer_rounded;
      case FocusMode.focusGuard:
        return Icons.shield_outlined;
    }
  }
}

class _ProtectionOption extends StatelessWidget {
  const _ProtectionOption({
    required this.level,
    required this.selected,
    required this.onTap,
    required this.palette,
  });
  final DistractionProtectionLevel level;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        color: selected
            ? palette.primaryContainer.withValues(alpha: 0.1)
            : null,
        borderColor: selected ? palette.primary.withValues(alpha: 0.2) : null,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? palette.primary : palette.surfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                level.label,
                style: context.text.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      selected ? palette.primary : palette.onSurfaceMuted,
                ),
              ),
            ),
            if (level == DistractionProtectionLevel.deep)
              const PremiumBadge(),
          ],
        ),
      ),
    );
  }
}
