import 'package:flutter/material.dart';

import '../tasks/task_controller.dart';
import '../auth/auth_service.dart';
import '../guides/guide_targets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icon_size.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_progress.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/app_states.dart';
import '../../data/models/exam.dart';
import 'exam_controller.dart';
import 'widgets/exam_creation_sheet.dart';
import 'widgets/exam_detail_screen.dart';

/// Premium Exam Command Center — the academic intelligence layer.
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headerAnim;
  late final Animation<double> _heroAnim;
  late final Animation<double> _prepAnim;
  late final Animation<double> _timelineAnim;
  late final Animation<double> _insightsAnim;
  late final Animation<double> _milestonesAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();

    _headerAnim = _stagger(0.00, 0.22);
    _heroAnim = _stagger(0.14, 0.42);
    _prepAnim = _stagger(0.28, 0.56);
    _timelineAnim = _stagger(0.40, 0.68);
    _insightsAnim = _stagger(0.52, 0.78);
    _milestonesAnim = _stagger(0.64, 0.88);

    ExamController.instance.addListener(_onChanged);
    TaskController.instance.addListener(_onChanged);
  }

  Animation<double> _stagger(double begin, double end) {
    return _entranceController.drive(
      CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic)),
    );
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _entranceController.dispose();
    ExamController.instance.removeListener(_onChanged);
    TaskController.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ec = ExamController.instance;
    final upcoming = ec.upcomingExams;
    final nextExam = ec.nextExam;
    final insights = ec.getInsights();
    final milestones = ec.getMilestones();
    final past = [...ec.completedExams, ...ec.cancelledExams];

    // Skeleton only while signed in and still fetching (same rule as Home
    // and Subjects: signed-out and widget tests render content states).
    if (AuthService.instance.isAuthenticated &&
        !ec.isLoaded &&
        ec.exams.isEmpty) {
      return const AppScaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              AppSkeletonCard(lines: 3),
              SizedBox(height: AppSpacing.md),
              AppSkeletonCard(lines: 2),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EntranceSection(
              animation: _headerAnim,
              child: _ExamHeader(
                examCount: ec.totalExamCount,
                upcomingCount: ec.upcomingCount,
                onAdd: () => _showCreateSheet(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (nextExam != null)
              _EntranceSection(
                animation: _heroAnim,
                child: _NextExamHero(exam: nextExam),
              ),
            if (nextExam != null) const SizedBox(height: AppSpacing.xl),
            _EntranceSection(
              animation: _prepAnim,
              child: _PreparationStatus(
                totalItems: ec.totalSyllabusItems,
                completedItems: ec.completedSyllabusItems,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _EntranceSection(
              animation: _timelineAnim,
              child: _ExamTimeline(exams: upcoming),
            ),
            if (past.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _EntranceSection(
                animation: _timelineAnim,
                child: _PastExams(exams: past),
              ),
            ],
            if (insights.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _EntranceSection(
                animation: _insightsAnim,
                child: _AcademicInsights(insights: insights),
              ),
            ],
            if (milestones.any((m) => m.earned)) ...[
              const SizedBox(height: AppSpacing.xl),
              _EntranceSection(
                animation: _milestonesAnim,
                child: _AcademicMilestones(milestones: milestones),
              ),
            ],
            if (upcoming.isEmpty && ec.completedExams.isEmpty)
              _EntranceSection(
                animation: _heroAnim,
                child: _EmptyExamState(
                  onCreate: () => _showCreateSheet(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExamCreationSheet(),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────

class _ExamHeader extends StatelessWidget {
  const _ExamHeader({
    required this.examCount,
    required this.upcomingCount,
    required this.onAdd,
  });

  final int examCount;
  final int upcomingCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final subtitle = upcomingCount > 0
        ? '$upcomingCount upcoming exam${upcomingCount == 1 ? '' : 's'}'
        : examCount > 0
        ? 'No upcoming exams'
        : 'No exams yet';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exams', style: context.text.headlineMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          GuideTargetAnchor(
            id: 'exams.add',
            child: _HeaderAction(
              icon: Icons.add_rounded,
              tooltip: 'Add exam',
              onTap: onAdd,
              primary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Tooltip(
      message: tooltip,
      child: AppPressable(
        onTap: onTap,
        pressedScale: 0.92,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primary ? palette.primary : palette.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            size: AppIconSize.md,
            color: primary ? Colors.white : palette.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─── Next Exam Hero ────────────────────────────────────────────────────

class _NextExamHero extends StatelessWidget {
  const _NextExamHero({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final days = exam.daysUntilExam;
    final isUrgent = days != null && days <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        color: isUrgent
            ? AppColors.error.withValues(alpha: 0.08)
            : palette.primary.withValues(alpha: 0.06),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        (isUrgent ? AppColors.error : palette.primary)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 22,
                    color: isUrgent ? AppColors.error : palette.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next exam', style: context.text.labelLarge),
                      Text(
                        exam.title,
                        style: context.text.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Wrap (not Row): long subject names flow to a second line
            // instead of overflowing on narrow screens.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (exam.subject.isNotEmpty)
                  _InfoChip(icon: Icons.book_outlined, label: exam.subject),
                if (exam.countdown != null)
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: exam.countdown!,
                    color: isUrgent ? AppColors.error : null,
                  ),
              ],
            ),
            if (exam.hasSyllabus) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${exam.syllabusCompleted}/${exam.syllabusTotal} topics',
                          style: context.text.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        AppLinearProgress(
                          value: exam.syllabusProgress,
                          height: 6,
                          color: exam.allSyllabusComplete
                              ? palette.success
                              : palette.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final chipColor = color ?? palette.onSurfaceMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          // Capped so very long labels ellipsize inside the Wrap line.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              style: context.text.labelSmall!.copyWith(color: chipColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Preparation Status ────────────────────────────────────────────────

class _PreparationStatus extends StatelessWidget {
  const _PreparationStatus({
    required this.totalItems,
    required this.completedItems,
  });

  final int totalItems;
  final int completedItems;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Preparation',
              icon: Icons.trending_up_rounded,
              subtitle: totalItems > 0
                  ? '$completedItems of $totalItems topics'
                  : 'Add syllabus to track progress',
            ),
            if (totalItems > 0) ...[
              const SizedBox(height: AppSpacing.md),
              AppLinearProgress(
                value: progress,
                height: 8,
                color: progress >= 0.7
                    ? palette.success
                    : progress >= 0.4
                    ? palette.warning
                    : palette.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '${(progress * 100).round()}% complete',
                    style: context.text.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${totalItems - completedItems} remaining',
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Add syllabus items to your exams to track preparation progress.',
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Exam Timeline ─────────────────────────────────────────────────────

class _ExamTimeline extends StatelessWidget {
  const _ExamTimeline({required this.exams});

  final List<StudentExam> exams;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Upcoming exams',
            icon: Icons.event_outlined,
            subtitle: exams.isEmpty
                ? 'No upcoming exams'
                : '${exams.length} exams',
          ),
          const SizedBox(height: AppSpacing.md),
          if (exams.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'All clear — no upcoming exams scheduled.',
                  style: context.text.bodyMedium!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ),
            )
          else
            ...exams.map(
              (exam) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _ExamTile(exam: exam),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final days = exam.daysUntilExam;
    final isUrgent = days != null && days <= 3;
    final readiness = ExamController.instance.readinessLabel(exam);
    final subtitle = [
      if (exam.subject.isNotEmpty) exam.subject,
      readiness,
    ].join(' · ');

    return AppPressable(
      onTap: () => _openDetail(context),
      semanticLabel: 'View exam ${exam.title}',
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: isUrgent ? AppColors.error : palette.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (exam.countdown != null)
                  Text(
                    exam.countdown!,
                    style: context.text.labelMedium!.copyWith(
                      color: isUrgent
                          ? AppColors.error
                          : palette.onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (exam.hasSyllabus)
                  Text(
                    '${exam.syllabusCompleted}/${exam.syllabusTotal}',
                    style: context.text.labelSmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExamDetailScreen(examId: exam.id),
      ),
    );
  }
}

// ─── Past exams (completed + cancelled) ────────────────────────────────

class _PastExams extends StatelessWidget {
  const _PastExams({required this.exams});

  final List<StudentExam> exams;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Past exams',
            icon: Icons.history_rounded,
            subtitle: '${exams.length} exams',
          ),
          const SizedBox(height: AppSpacing.md),
          ...exams.map(
            (exam) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _PastExamTile(exam: exam),
            ),
          ),
        ],
      ),
    );
  }
}

class _PastExamTile extends StatelessWidget {
  const _PastExamTile({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final statusColor = exam.isCompleted
        ? palette.success
        : palette.onSurfaceMuted;

    return AppPressable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExamDetailScreen(examId: exam.id),
        ),
      ),
      semanticLabel: 'View past exam ${exam.title}',
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(
              exam.isCompleted
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              size: 20,
              color: statusColor,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exam.subject.isNotEmpty)
                    Text(
                      exam.subject,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                exam.status.label,
                style: context.text.labelSmall!.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Academic Insights ─────────────────────────────────────────────────

class _AcademicInsights extends StatelessWidget {
  const _AcademicInsights({required this.insights});

  final List<ExamInsight> insights;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Insights',
            icon: Icons.psychology_outlined,
            subtitle: 'Academic preparation signals',
          ),
          const SizedBox(height: AppSpacing.md),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _InsightCard(insight: insight),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final ExamInsight insight;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final tint = insight.tint ?? palette.primary;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(insight.icon, size: 18, color: tint),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: context.text.labelLarge!.copyWith(color: tint),
                ),
                Text(insight.detail, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Academic Milestones ───────────────────────────────────────────────

class _AcademicMilestones extends StatelessWidget {
  const _AcademicMilestones({required this.milestones});

  final List<ExamMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    final earned = milestones.where((m) => m.earned).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Milestones',
            icon: Icons.military_tech_outlined,
            subtitle: '$earned of ${milestones.length} earned',
          ),
          const SizedBox(height: AppSpacing.md),
          ...milestones
              .where((m) => m.earned)
              .map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _MilestoneRow(milestone: m),
                ),
              ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone});

  final ExamMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: palette.streak.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(milestone.icon, size: 18, color: palette.streak),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(milestone.title, style: context.text.labelLarge),
                Text(
                  milestone.detail,
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              'Earned',
              style: context.text.labelSmall!.copyWith(color: palette.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────

class _EmptyExamState extends StatelessWidget {
  const _EmptyExamState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.primaryContainer.withValues(alpha: 0.5),
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: AppIconSize.xl,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('No exams yet', style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add your first exam to start\ntracking academic milestones.',
                style: context.text.bodyMedium!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add exam'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Entrance wrapper — TCC lightweight (Fade + 4% slide, static child)
class _EntranceSection extends StatelessWidget {
  const _EntranceSection({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
