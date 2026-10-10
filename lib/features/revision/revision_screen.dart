import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/assistant/assistant_launch_context.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/intelligence/academic_knowledge_engine.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/revision_queue_item.dart';
import '../../data/models/revision_schedule.dart';
import '../exams/exam_controller.dart';
import '../knowledge/academic_knowledge_controller.dart';
import '../knowledge/practice_question_controller.dart';
import '../knowledge/presentation/practice_mode_selection_sheet.dart';
import '../planning/controllers/planning_block_controller.dart';
import '../resources/resource_controller.dart';
import '../study/study_controller.dart';
import '../subjects/subject_controller.dart';
import 'presentation/revision_session_screen.dart';
import 'revision_controller.dart';
import 'widgets/revision_why_sheet.dart';

/// Revision Center 2.0 — Adaptive Spaced Learning & Memory Command Center.
class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  int _selectedFilterIndex = 0; // 0: Due & Overdue, 1: Needs Attention, 2: Coming Up, 3: Retained

  @override
  void initState() {
    super.initState();
    RevisionController.instance.addListener(_onChanged);
    AcademicKnowledgeController.instance.addListener(_onChanged);
    StudyController.instance.addListener(_onChanged);
    ResourceController.instance.addListener(_onChanged);
    ExamController.instance.addListener(_onChanged);
    SubjectController.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    RevisionController.instance.removeListener(_onChanged);
    AcademicKnowledgeController.instance.removeListener(_onChanged);
    StudyController.instance.removeListener(_onChanged);
    ResourceController.instance.removeListener(_onChanged);
    ExamController.instance.removeListener(_onChanged);
    SubjectController.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subjects = SubjectController.instance.activeSubjects;
    final topics = AcademicKnowledgeController.instance.topics;
    final chapters = AcademicKnowledgeController.instance.chapters;
    final sessions = StudyController.instance.sessions;
    final resources = ResourceController.instance.resources;
    final exams = ExamController.instance.upcomingExams;
    final records = RevisionController.instance.records;
    final schedules = RevisionController.instance.schedules;

    // Unified Adaptive Queue
    final queue = AcademicKnowledgeEngine.buildRevisionQueue(
      topics: topics,
      resources: resources,
      subjects: subjects,
      chapters: chapters,
      exams: exams,
      sessions: sessions,
      records: records,
      schedules: schedules,
    );

    // Counts
    final dueOrOverdue = queue.where((i) => i.isDueNow).toList();
    final overdueCount = queue.where((i) => i.isOverdue).length;
    final dueTodayCount = queue.where((i) => i.dueCategory == RevisionDueCategory.dueToday).length;
    final needsAttention = queue.where((i) => i.isWeak).toList();
    final comingUp = queue.where((i) => i.dueCategory == RevisionDueCategory.upcoming).toList();
    final retained = queue.where((i) => i.dueCategory == RevisionDueCategory.stableStrong).toList();

    // Filtered Items
    List<RevisionQueueItem> displayedItems;
    switch (_selectedFilterIndex) {
      case 1:
        displayedItems = needsAttention;
        break;
      case 2:
        displayedItems = comingUp;
        break;
      case 3:
        displayedItems = retained;
        break;
      case 0:
      default:
        displayedItems = dueOrOverdue;
        break;
    }

    final topHeroItem = dueOrOverdue.firstOrNull ?? queue.firstOrNull;

    final now = DateTime.now();
    final cutoffWeek = now.subtract(const Duration(days: 7));
    final completedThisWeek = records.where((r) => r.completedAt.isAfter(cutoffWeek)).length;
    final streak = StreakService.instance.currentStreak;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision & Spaced Learning'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Assistant',
            onPressed: () => AppRouter.openAssistant(
              context,
              initialQuery: 'What should I revise?',
              launchContext: const AssistantLaunchContext(
                origin: AssistantOrigin.study,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Header Tag & Subheading ──────────────────────────────────
            Text(
              'REVISION',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your memory queue, simplified.',
              style: context.text.headlineSmall!.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Revision Momentum Bar ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MomentumCard(
                    title: 'Due Today',
                    value: '$dueTodayCount',
                    icon: Icons.notifications_active_outlined,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MomentumCard(
                    title: 'Overdue',
                    value: '$overdueCount',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MomentumCard(
                    title: 'This Week',
                    value: '$completedThisWeek',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MomentumCard(
                    title: 'Streak',
                    value: '${streak}d',
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Hero Recommendation Card ─────────────────────────────────
            if (topHeroItem != null) ...[
              AppCard(
                borderColor: AppColors.warning.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          topHeroItem.isOverdue
                              ? 'OVERDUE REVISION'
                              : 'RECOMMENDED NEXT REVISION',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: topHeroItem.isOverdue
                                ? AppColors.error
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      topHeroItem.title,
                      style: context.text.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${topHeroItem.subjectName} • ${topHeroItem.primaryReason}',
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              'Start (${topHeroItem.suggestedDurationMinutes}m)',
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: () {
                              if (topHeroItem.topic != null) {
                                RevisionSessionScreen.open(
                                  context,
                                  topic: topHeroItem.topic!,
                                  suggestedDurationMinutes:
                                      topHeroItem.suggestedDurationMinutes,
                                );
                              } else {
                                AppRouter.startContextualFocus(
                                  context,
                                  duration: Duration(
                                    minutes:
                                        topHeroItem.suggestedDurationMinutes,
                                  ),
                                  focusTitle: topHeroItem.title,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton(
                          child: const Text('Why?'),
                          onPressed: () {
                            if (topHeroItem.topic != null) {
                              RevisionWhySheet.show(
                                context,
                                topic: topHeroItem.topic!,
                                reasons: topHeroItem.reasons,
                                suggestedDurationMinutes:
                                    topHeroItem.suggestedDurationMinutes,
                                subjectName: topHeroItem.subjectName,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Category Filters ─────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Due & Overdue (${dueOrOverdue.length})',
                    isSelected: _selectedFilterIndex == 0,
                    onTap: () => setState(() => _selectedFilterIndex = 0),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Needs Attention (${needsAttention.length})',
                    isSelected: _selectedFilterIndex == 1,
                    onTap: () => setState(() => _selectedFilterIndex = 1),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Coming Up (${comingUp.length})',
                    isSelected: _selectedFilterIndex == 2,
                    onTap: () => setState(() => _selectedFilterIndex = 2),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Retained (${retained.length})',
                    isSelected: _selectedFilterIndex == 3,
                    onTap: () => setState(() => _selectedFilterIndex = 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Queue Items List ─────────────────────────────────────────
            if (displayedItems.isEmpty) ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                        size: 36,
                        color: palette.onSurfaceMuted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _selectedFilterIndex == 0
                            ? 'You\'re caught up on revision!'
                            : 'No items in this category.',
                        style: context.text.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Study curriculum topics to automatically build your spaced repetition schedule.',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              for (final item in displayedItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _RevisionQueueTile(item: item),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MomentumCard extends StatelessWidget {
  const _MomentumCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.text.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: palette.onSurfaceMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: palette.primary.withValues(alpha: 0.15),
    );
  }
}

class _RevisionQueueTile extends StatelessWidget {
  const _RevisionQueueTile({required this.item});

  final RevisionQueueItem item;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    Color badgeColor;
    switch (item.dueCategory) {
      case RevisionDueCategory.overdue:
        badgeColor = AppColors.error;
        break;
      case RevisionDueCategory.dueNow:
      case RevisionDueCategory.dueToday:
        badgeColor = AppColors.warning;
        break;
      case RevisionDueCategory.needsAttention:
        badgeColor = AppColors.warning;
        break;
      case RevisionDueCategory.upcoming:
        badgeColor = AppColors.secondary;
        break;
      case RevisionDueCategory.stableStrong:
        badgeColor = AppColors.success;
        break;
    }

    final hasQuestions = item.topic != null &&
        PracticeQuestionController.instance.hasQuestionsForTopic(item.topic!.id);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.subjectName}${item.chapter != null ? " • ${item.chapter!.title}" : ""}',
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  item.dueCategory.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Title
          Text(
            item.title,
            style: context.text.titleSmall!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),

          // Reason / Interval info
          Text(
            item.primaryReason,
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Action buttons row
          Row(
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text('Revise (${item.suggestedDurationMinutes}m)'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  if (item.topic != null) {
                    RevisionSessionScreen.open(
                      context,
                      topic: item.topic!,
                      suggestedDurationMinutes: item.suggestedDurationMinutes,
                    );
                  } else {
                    AppRouter.startContextualFocus(
                      context,
                      duration: Duration(minutes: item.suggestedDurationMinutes),
                      focusTitle: item.title,
                    );
                  }
                },
              ),
              if (hasQuestions) ...[
                const SizedBox(width: AppSpacing.xs),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    PracticeModeSelectionSheet.show(
                      context,
                      topic: item.topic!,
                    );
                  },
                  child: const Text('Practice'),
                ),
              ],
              const Spacer(),
              if (item.topic != null)
                IconButton(
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                  tooltip: 'Why revise this?',
                  onPressed: () {
                    RevisionWhySheet.show(
                      context,
                      topic: item.topic!,
                      reasons: item.reasons,
                      suggestedDurationMinutes: item.suggestedDurationMinutes,
                      subjectName: item.subjectName,
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                tooltip: 'Plan revision',
                onPressed: () async {
                  if (item.topic != null) {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, now.day, now.hour)
                        .add(Duration(minutes: ((now.minute / 15).ceil() * 15)));
                    final end = start.add(Duration(minutes: item.suggestedDurationMinutes));

                    await PlanningBlockController.instance.scheduleTopicBlock(
                      item.topic!.id,
                      start,
                      end,
                      subjectId: item.topic!.subjectId,
                      chapterId: item.topic!.chapterId,
                      customTitle: 'Revise — ${item.topic!.title}',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Scheduled revision for "${item.topic!.title}" in today\'s plan'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
