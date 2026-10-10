import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../tasks/task_controller.dart';
import '../study/study_controller.dart';
import '../exams/exam_controller.dart';
import '../focus/controller/focus_controller.dart';
import 'progression_controller.dart';

class ProgressWorkspaceScreen extends StatelessWidget {
  const ProgressWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final pc = ProgressionController.instance;
    final tc = TaskController.instance;
    final sc = StudyController.instance;
    final ec = ExamController.instance;
    final fc = FocusController.instance;

    final completedToday = tc.tasks.where((t) => t.isCompleted).length;
    final activeTasks = tc.activeTasks.length;
    final studyToday = sc.sessions.fold<int>(0, (s, se) => s + se.duration.inMinutes);
    final focusToday = fc.sessions.fold<int>(0, (s, se) => s + se.focusDuration.inMinutes);
    final upcomingExams = ec.exams.where((e) => e.examDateTime != null && e.examDateTime!.isAfter(DateTime.now())).length;

    return AppScaffold(
      title: 'Progress',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(title: 'Today', icon: Icons.today_outlined),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _StatTile(label: 'Completed', value: '$completedToday', color: palette.success)),
                Expanded(child: _StatTile(label: 'Active', value: '$activeTasks', color: palette.info)),
                Expanded(child: _StatTile(label: 'Study', value: '${studyToday}m', color: palette.primary)),
                Expanded(child: _StatTile(label: 'Focus', value: '${focusToday}m', color: palette.warning)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSectionHeader(title: 'Progression', icon: Icons.trending_up_rounded),
            const SizedBox(height: AppSpacing.sm),
            _ProgressionCard(pc: pc, palette: palette),
            const SizedBox(height: AppSpacing.lg),
            AppSectionHeader(title: 'Exam Pressure', icon: Icons.calendar_today_rounded),
            const SizedBox(height: AppSpacing.sm),
            Text(
              upcomingExams > 0 ? '$upcomingExams upcoming exam${upcomingExams == 1 ? '' : 's'}' : 'No upcoming exams',
              style: context.text.bodyMedium?.copyWith(color: palette.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppTheme.colorsOf(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colorsOf(context).outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.colorsOf(context).onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _ProgressionCard extends StatelessWidget {
  const _ProgressionCard({required this.pc, required this.palette});
  final ProgressionController pc;
  final AppPalette palette;
  @override
  Widget build(BuildContext context) {
    final level = pc.currentLevel;
    final xp = pc.totalXp;
    final nextXp = level.xpToNextLevel;
    final pct = nextXp > 0 ? (xp / nextXp).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Level ${level.level}', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            Text('$xp / $nextXp XP', style: context.text.bodySmall?.copyWith(color: palette.onSurfaceMuted)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: palette.outline.withValues(alpha: 0.3), valueColor: AlwaysStoppedAnimation(palette.primary))),
        ],
      ),
    );
  }
}
