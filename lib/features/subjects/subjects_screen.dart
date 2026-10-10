import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/app_states.dart';
import '../../data/models/subject.dart';
import '../auth/auth_service.dart';
import '../exams/exam_controller.dart';
import '../tasks/task_controller.dart';
import 'presentation/subject_creation_sheet.dart';
import 'subject_controller.dart';

/// Subjects workspace list — the entry point to every subject.
///
/// Each row shows truthful derived workload (active/overdue tasks, upcoming
/// exams) from existing controllers. Tapping a row preserves [Subject.id]
/// into [SubjectDetailScreen].
class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  @override
  void initState() {
    super.initState();
    SubjectController.instance.addListener(_onChanged);
    TaskController.instance.addListener(_onChanged);
    ExamController.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SubjectController.instance.removeListener(_onChanged);
    TaskController.instance.removeListener(_onChanged);
    ExamController.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _addSubject() => SubjectCreationSheet.show(context);

  @override
  Widget build(BuildContext context) {
    final sc = SubjectController.instance;

    return AppScaffold(
      title: 'Subjects',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Add subject',
          onPressed: _addSubject,
        ),
      ],
      // Skeleton only while signed in and still fetching; signed-out (and
      // widget tests) always render content states. Matches Home behavior.
      body:
          AuthService.instance.isAuthenticated &&
              !sc.isLoaded &&
              !sc.hasSubjects
          ? const _SubjectsLoading()
          : sc.hasSubjects
          ? _SubjectsList(onAdd: _addSubject)
          : _SubjectsEmpty(onAdd: _addSubject),
    );
  }
}

class _SubjectsLoading extends StatelessWidget {
  const _SubjectsLoading();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screen),
      child: Column(
        children: [
          AppSkeletonCard(lines: 2),
          SizedBox(height: AppSpacing.sm),
          AppSkeletonCard(lines: 2),
        ],
      ),
    );
  }
}

class _SubjectsEmpty extends StatelessWidget {
  const _SubjectsEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'No subjects yet',
      icon: Icons.menu_book_outlined,
      description:
          'Add your first subject to organize tasks, exams, and study.',
      action: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add subject'),
      ),
    );
  }
}

class _SubjectsList extends StatelessWidget {
  const _SubjectsList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final sc = SubjectController.instance;
    final active = sc.activeSubjects;
    final archived = sc.archivedSubjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Active',
            icon: Icons.folder_outlined,
            trailing: Text(
              '${active.length}',
              style: context.text.labelMedium?.copyWith(
                color: AppTheme.colorsOf(context).onSurfaceMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (active.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppTheme.colorsOf(context).onSurfaceMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'All subjects are archived. Restore one below or add a new subject.',
                      style: context.text.bodySmall?.copyWith(
                        color: AppTheme.colorsOf(context).onSurfaceMuted,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...active.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _SubjectRow(subject: s),
              ),
            ),
          if (archived.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: 'Archived',
              icon: Icons.archive_outlined,
              trailing: Text(
                '${archived.length}',
                style: context.text.labelMedium?.copyWith(
                  color: AppTheme.colorsOf(context).onSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...archived.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _SubjectRow(subject: s),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final tc = TaskController.instance;
    final ec = ExamController.instance;

    final activeTasks = tc.activeTasksForSubject(subject.id).length;
    final overdueTasks = tc
        .activeTasksForSubject(subject.id)
        .where((t) => t.isOverdue)
        .length;
    final upcomingExams = ec.examsForSubjectName(subject.name).length;

    final parts = <String>[];
    if (activeTasks > 0) {
      parts.add('$activeTasks task${activeTasks == 1 ? '' : 's'}');
    }
    if (overdueTasks > 0) {
      parts.add('$overdueTasks overdue');
    }
    if (upcomingExams > 0) {
      parts.add('$upcomingExams exam${upcomingExams == 1 ? '' : 's'}');
    }
    final secondary = parts.isEmpty
        ? (subject.archived ? 'Archived' : 'No work linked yet')
        : parts.join(' · ');

    return AppPressable(
      onTap: () => AppRouter.openSubjectDetail(context, subject.id),
      semanticLabel: 'Open subject ${subject.name}',
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: subject.colorValue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(subject.icon, color: subject.colorValue, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subject.name,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    style: context.text.bodySmall!.copyWith(
                      color: overdueTasks > 0
                          ? palette.error
                          : palette.onSurfaceMuted,
                      fontWeight: overdueTasks > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (subject.archived)
              IconButton(
                icon: const Icon(Icons.unarchive_rounded, size: 20),
                tooltip: 'Restore subject',
                color: palette.primary,
                onPressed: () =>
                    SubjectController.instance.restoreSubject(subject.id),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: palette.onSurfaceMuted,
              ),
          ],
        ),
      ),
    );
  }
}
