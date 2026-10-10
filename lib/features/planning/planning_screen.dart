import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/assistant/assistant_launch_context.dart';
import '../guides/guide_targets.dart';
import '../premium/services/premium_gate.dart';
import '../../core/animations/animated_entrance.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/intelligence/academic_intelligence_controller.dart';
import '../../core/intelligence/academic_intelligence_engine.dart';
import '../../core/navigation/universal_action_executor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/student_os_assistant_visual.dart';
import '../../core/widgets/student_os_page_header.dart';
import '../../core/widgets/student_os_segmented_control.dart';
import '../../data/models/exam.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/topic.dart';
import '../exams/exam_controller.dart';
import '../focus/controller/focus_controller.dart';
import '../knowledge/academic_knowledge_controller.dart';
import '../knowledge/presentation/topic_detail_sheet.dart';
import '../study/study_controller.dart';
import '../subjects/presentation/subject_creation_sheet.dart';
import '../subjects/subject_controller.dart';
import '../tasks/presentation/task_creation_sheet.dart';
import '../tasks/task_controller.dart';
import 'controllers/planning_block_controller.dart';
import 'models/planning_block.dart';
import 'plan_controller.dart';
import 'plan_study_state.dart';
import 'services/planning_engine.dart';
import 'widgets/daily_plan_sheet.dart';
import 'widgets/plan_study_widgets.dart';
import 'widgets/topic_plan_sheet.dart';

/// Top-level switcher modes for Plan & Study.
enum PlanStudyTab { plan, study }

/// Plan & Study 3.0 — The Academic Command Center.
///
/// One navigation destination answering two questions about the same
/// curriculum:
/// - PLAN: “What should I do?”
/// - STUDY: “How do I learn it?”
///
/// Both tabs read the same authoritative planning and academic systems through
/// [PlanStudyState]; this file only renders and dispatches.
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({
    super.key,
    this.initialTab = PlanStudyTab.plan,
  });

  final PlanStudyTab initialTab;

  /// Canonical completion rule — single source of truth for every consumer.
  static bool isBlockCompleted(PlanningBlock block) =>
      PlanStudyState.isBlockCompleted(block);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late PlanStudyTab _activeTab;
  int _quickBudgetMinutes = 120; // Default 2 hours

  // Focus tick filter: Planning only reflects session presence/identity, not
  // per-second elapsed time, so ignore the 1s ticker except on real changes.
  String? _lastFocusId;
  bool _lastFocusHasActive = false;
  String _lastFocusObjective = '';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;

    PlanController.instance.addListener(_onDataChanged);
    PlanningBlockController.instance.addListener(_onDataChanged);
    TaskController.instance.addListener(_onDataChanged);
    SubjectController.instance.addListener(_onDataChanged);
    ExamController.instance.addListener(_onDataChanged);
    StudyController.instance.addListener(_onDataChanged);
    FocusController.instance.addListener(_onFocusDataChanged);
    AcademicIntelligenceController.instance.addListener(_onDataChanged);
    AcademicKnowledgeController.instance.addListener(_onDataChanged);
    _syncFocusSnapshot();
  }

  void _syncFocusSnapshot() {
    final fc = FocusController.instance;
    _lastFocusId = fc.activeSession?.id;
    _lastFocusHasActive = fc.hasActiveSession;
    _lastFocusObjective = fc.activeSession?.objective ?? '';
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusDataChanged() {
    final fc = FocusController.instance;
    final id = fc.activeSession?.id;
    final hasActive = fc.hasActiveSession;
    final objective = fc.activeSession?.objective ?? '';
    if (id != _lastFocusId ||
        hasActive != _lastFocusHasActive ||
        objective != _lastFocusObjective) {
      _lastFocusId = id;
      _lastFocusHasActive = hasActive;
      _lastFocusObjective = objective;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    PlanController.instance.removeListener(_onDataChanged);
    PlanningBlockController.instance.removeListener(_onDataChanged);
    TaskController.instance.removeListener(_onDataChanged);
    SubjectController.instance.removeListener(_onDataChanged);
    ExamController.instance.removeListener(_onDataChanged);
    StudyController.instance.removeListener(_onDataChanged);
    FocusController.instance.removeListener(_onFocusDataChanged);
    AcademicIntelligenceController.instance.removeListener(_onDataChanged);
    AcademicKnowledgeController.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _openCreateTaskSheet() {
    final selected = PlanController.instance.selectedDay;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskCreationSheet(
        initialDueDate: selected,
        initialScheduledDate: selected,
      ),
    );
  }

  void _openDailyPlanSheet() {
    final selected = PlanController.instance.selectedDay;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DailyPlanSheet(targetDay: selected),
    );
  }

  Future<void> _quickAutoPlan(int minutes) async {
    final pc = PlanController.instance;
    final selected = pc.selectedDay;
    final planResult = pc.generateDailyPlan(day: selected, budgetMinutes: minutes);
    await PlanningEngine.applyDailyPlan(planResult);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-planned ${planResult.items.length} sessions for today!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── §6 / §20 — one Focus entry point for every academic surface ──────────
  //
  // Blocks, topics and subjects all funnel into SprintX through
  // AppRouter.startPlanningBlockFocus / startContextualFocus. PLAN & STUDY
  // never constructs a session itself.

  void _startBlock(PlanBlockView view) {
    AppRouter.startPlanningBlockFocus(context, view.block);
  }

  void _continueActiveFocus() {
    AppRouter.openActiveFocusSession(context);
  }

  // ── §17 / §20 — topic entry points ──────────────────────────────────────

  void _openTopic(StudyTopicView view) {
    TopicDetailSheet.show(context, view.topic.id);
  }

  void _openTopicById(String topicId) {
    TopicDetailSheet.show(context, topicId);
  }

  void _studyTopicDirect(StudyTopicView view) {
    final subjectName = SubjectController.instance
        .subjectById(view.topic.subjectId)
        ?.displayName;
    AppRouter.startContextualFocus(
      context,
      duration: Duration(minutes: view.topic.estimatedMinutes),
      subjectId: view.topic.subjectId,
      subjectName: subjectName,
      topicId: view.topic.id,
      chapterId: view.topic.chapterId,
      focusTitle: view.title,
    );
  }

  void _studySubject(String subjectId, {String? title}) {
    final subject = SubjectController.instance.subjectById(subjectId);
    AppRouter.openFocusModeSelection(
      context,
      subjectId: subjectId,
      subjectName: subject?.displayName,
      focusTitle: title ?? subject?.displayName,
    );
  }

  // ── §26 — STUDY → PLAN ──────────────────────────────────────────────────

  Future<void> _planTopic(Topic topic) async {
    final id = await TopicPlanSheet.show(context, topic: topic);
    if (!mounted || id == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${topic.title}" added to your plan'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── §10 — SMART RESCHEDULING ─────────────────────────────────────────────
  //
  // A missed block is never deleted. The user picks one of the real free slots
  // the planning engine found, and the existing block is moved there.

  Future<void> _rescheduleBlock(PlanBlockView view) async {
    final pc = PlanController.instance;
    final slots = PlanningEngine.findRecoverySlots(
      view.block,
      availableMinutes: pc.dailyBudgetMinutes,
    );

    if (slots.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No free slot found in the next few days'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecoverySlotSheet(
        title: view.subjectName ?? view.title,
        minutes: view.durationMinutes,
        slots: slots,
      ),
    );
    if (!mounted || picked == null) return;

    final moved = await PlanningBlockController.instance.rescheduleBlock(
      view.block.id,
      picked,
      picked.add(Duration(minutes: view.durationMinutes)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          moved == null
              ? 'Could not reschedule that block'
              : 'Rescheduled to ${formatPlanMinutes(view.durationMinutes)} slot',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.sm,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Canonical sibling header: same DNA as Home/Tools/Workspace ──
                const AnimatedEntrance(
                  child: StudentOSPageHeader(
                    eyebrow: 'Academic command',
                    title: 'Plan & Study',
                    subtitle: 'What to do, and how to learn it.',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // ── Assistant entry (canonical identity, progressive) ──
                AnimatedEntrance(
                  child: StudentOSAssistantEntryCard(
                    onTap: () => UniversalActionExecutor.openAssistant(
                      context,
                      launchContext: const AssistantLaunchContext(
                        origin: AssistantOrigin.planning,
                      ),
                    ),
                    title: 'Ask Student OS',
                    subtitle: 'Not sure what to plan? Ask for a suggestion.',
                    status: StudentOSAssistantStatus.idle,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
            // ── TOP SWITCHER: PLAN | STUDY ──
            AnimatedEntrance(
              child: _PlanStudySwitcher(
                selectedTab: _activeTab,
                onTabChanged: (tab) => setState(() => _activeTab = tab),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── TAB CONTENT ──
            if (_activeTab == PlanStudyTab.plan)
              _buildPlanTab(context, palette)
            else
              _buildStudyTab(context, palette),

            const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PLAN VIEW — "What am I doing today?"
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPlanTab(BuildContext context, AppPalette palette) {
    final pc = PlanController.instance;
    final tc = TaskController.instance;
    final ec = ExamController.instance;
    final fc = FocusController.instance;
    final selected = pc.selectedDay;
    final isToday = pc.isToday(selected);

    final dayBlocks = PlanningBlockController.instance.blocksForDay(selected);
    final dayTasks = pc.tasksFor(selected);
    final overdueTasks = tc.overdueTasks;
    final nextExam = ec.nextExam;
    final missedSessions = isToday ? pc.missedSessionsToday : const <MissedSession>[];

    final hasPlan = dayBlocks.isNotEmpty;
    final hasActiveFocus = fc.hasActiveSession;

    // Calculate planned & completed minutes
    int plannedMins = 0;
    for (final b in dayBlocks) {
      plannedMins += b.endAt.difference(b.startAt).inMinutes;
    }
    int completedMins = 0;
    for (final b in dayBlocks.where((b) => PlanningScreen.isBlockCompleted(b))) {
      completedMins += b.endAt.difference(b.startAt).inMinutes;
    }
    final allCompleted = hasPlan && dayBlocks.every((b) => PlanningScreen.isBlockCompleted(b));

    // §3 — one derived read-out for the whole PLAN surface.
    final dayView = PlanStudyState.planDay(
      selected,
      availableMinutes: pc.dailyBudgetMinutes,
    );
    final allocation =
        PlanStudyState.allocation(budgetMinutes: _quickBudgetMinutes, day: selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Day Selector Strip ──
        AnimatedEntrance(
          child: _DaySelector(controller: pc, onSelect: pc.selectDay),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── §4 ACADEMIC PLANNING HEADER ──
        AnimatedEntrance(child: PlanStudyPlanHeader(day: dayView)),
        const SizedBox(height: AppSpacing.md),

        // ── §10 SMART RESCHEDULING — missed work, never silently dropped ──
        if (dayView.hasMissed) ...[
          AppSectionHeader(
            title: 'Missed',
            icon: Icons.replay_rounded,
            subtitle: 'Pick a new slot — nothing is deleted',
            trailing: TextButton(
              onPressed: () async {
                await pc.rebalanceSelectedDay();
                if (context.mounted) _showSnack('Rebalanced into open slots');
              },
              child: const Text('Auto-fit'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final missed in dayView.missedBlocks) ...[
            AnimatedEntrance(
              child: PlanMissedBlockRow(
                view: missed,
                onReschedule: () => _rescheduleBlock(missed),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.md),
        ] else if (isToday && missedSessions.isNotEmpty) ...[
          AnimatedEntrance(
            child: _MissedSessionsAlert(
              missedCount: missedSessions.length,
              onFixPlan: () async {
                await pc.rebalanceSelectedDay();
                if (context.mounted) _showSnack('Rescheduled missed sessions to open slots');
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── HERO CARD (Adaptive: Active Focus / Plan Exists / Empty State / Caught Up) ──
        AnimatedEntrance(
          child: hasActiveFocus
              ? _ActiveFocusHero(focusController: fc)
              : (allCompleted
                  ? _AllCaughtUpHero(
                      completedMinutes: completedMins,
                      sessionCount: dayBlocks.length,
                    )
                  : (hasPlan
                      ? _ExistingPlanHero(
                          plannedMinutes: plannedMins,
                          completedMinutes: completedMins,
                          nextBlock: _findNextActionableBlock(dayBlocks),
                          onStartBlock: (block) => AppRouter.startPlanningBlockFocus(context, block),
                          onPlanDay: _openDailyPlanSheet,
                        )
                      : _EmptyPlanHero(
                          selectedMinutes: _quickBudgetMinutes,
                          onMinutesChanged: (m) => setState(() => _quickBudgetMinutes = m),
                          onAutoPlan: () => _quickAutoPlan(_quickBudgetMinutes),
                          onCustomPlan: _openDailyPlanSheet,
                        ))),
        ),

        // ── §6 ACTIVE BLOCK — shown only when a block window is live ──
        if (dayView.hasActiveBlock) ...[
          const SizedBox(height: AppSpacing.md),
          AnimatedEntrance(
            child: PlanActiveBlockCard(
              day: dayView,
              onStart: _startBlock,
              onContinueFocus: _continueActiveFocus,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),

        // ── DAY TIMELINE / AGENDA ──
        if (hasPlan) ...[
          AppSectionHeader(
            title: isToday ? "Today's Schedule" : "Day Schedule",
            icon: Icons.schedule_rounded,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    // Smart Planning is Pro; the planner itself stays free.
                    if (!PremiumGate.check(
                        context, 'premium.planning.smart')) {
                      return;
                    }
                    AppRouter.openAssistant(
                      context,
                      initialQuery: 'Fix my day',
                      launchContext: const AssistantLaunchContext(
                        origin: AssistantOrigin.planning,
                      ),
                    );
                  },
                  child: const Text('Optimize'),
                ),
                TextButton(
                  onPressed: _openDailyPlanSheet,
                  child: const Text('Edit Plan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedEntrance(
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < dayView.blocks.length; i++) ...[
                    PlanBlockRow(
                      view: dayView.blocks[i],
                      onStart: _startBlock,
                      onReschedule: () => _rescheduleBlock(dayView.blocks[i]),
                    ),
                    if (i < dayView.blocks.length - 1)
                      Divider(
                        height: 1,
                        indent: 78,
                        color: palette.outline.withValues(alpha: 0.3),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── §8/§9 AVAILABLE TIME → SUBJECT ALLOCATION ──
        if (SubjectController.instance.activeSubjects.isNotEmpty ||
            tc.activeTasks.isNotEmpty) ...[
          AppSectionHeader(
            title: 'Available Time',
            icon: Icons.hourglass_bottom_rounded,
            subtitle: 'Say what you have — see what fits',
            trailing: TextButton.icon(
              onPressed: _openDailyPlanSheet,
              icon: const Icon(Icons.auto_awesome_rounded, size: 15),
              label: const Text('Plan My Day'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedEntrance(child: PlanSubjectAllocationList(allocation: allocation)),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── TODAY'S TASKS ──
        AppSectionHeader(
          title: "Tasks",
          icon: Icons.checklist_rounded,
          trailing: GuideTargetAnchor(
            id: 'plan.addTask',
            child: TextButton.icon(
              onPressed: _openCreateTaskSheet,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedEntrance(
          child: _TasksChecklistSection(
            tasks: isToday ? (dayTasks + overdueTasks.where((t) => !dayTasks.contains(t)).toList()) : dayTasks,
            onToggle: (id) => tc.completeTask(id),
            onOpenTask: (id) => AppRouter.openTaskDetail(context, id),
          ),
        ),

        // ── UPCOMING EXAM CONTEXT ──
        if (nextExam != null && (nextExam.daysUntilExam ?? 99) <= 30) ...[
          const SizedBox(height: AppSpacing.lg),
          AnimatedEntrance(child: _UpcomingExamCard(exam: nextExam)),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STUDY VIEW — "What should I study?"
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStudyTab(BuildContext context, AppPalette palette) {
    final aic = AcademicIntelligenceController.instance;
    final sc = SubjectController.instance;
    final fc = FocusController.instance;
    final dayBlocks = PlanningBlockController.instance.blocksForDay(DateTime.now());

    final subjects = sc.activeSubjects;
    final recommendation = aic.primaryStudyRecommendation;
    final hasPlanToday = dayBlocks.isNotEmpty;

    // §13 — one derived read-out for the whole STUDY surface.
    final overview = PlanStudyState.studyOverview();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Active Focus Banner (if active) ──
        if (fc.hasActiveSession) ...[
          AnimatedEntrance(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.timer_rounded, color: palette.streak, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Focus session active', style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w700)),
                        Text(fc.activeSession?.objective ?? 'Deep Focus', style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => AppRouter.openActiveFocusSession(context),
                    child: const Text('Continue Focus'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── YOUR STUDY PLAN TODAY (if plan exists) ──
        if (hasPlanToday) ...[
          AppSectionHeader(
            title: 'Your Planned Study Today',
            icon: Icons.event_note_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedEntrance(
            child: _StudyPlanStrip(
              blocks: dayBlocks,
              onStartBlock: (block) => AppRouter.startPlanningBlockFocus(context, block),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── WHAT SHOULD I STUDY? (Smart Recommendations) ──
        AppSectionHeader(
          title: 'What Should I Study?',
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedEntrance(
          child: recommendation != null
              ? _StudyRecommendationHero(
                  recommendation: recommendation,
                  onStart: () {
                    AppRouter.openFocusModeSelection(
                      context,
                      subjectId: recommendation.subjectId,
                      subjectName: recommendation.subjectName,
                      topicId: recommendation.topicId,
                      topicName: recommendation.topicTitle,
                      chapterId: recommendation.chapterId,
                      focusTitle: recommendation.title,
                      suggestedDuration: Duration(minutes: recommendation.suggestedDurationMinutes),
                    );
                  },
                )
              : AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'All caught up on study recommendations!',
                      style: context.text.bodyMedium!.copyWith(color: palette.onSurfaceMuted),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 30-MINUTE FOCUS BURST ──
        AnimatedEntrance(
          child: _ThirtyMinuteBurstCard(
            onStart: () {
              final burst = aic.thirtyMinuteBurstAction;
              UniversalActionExecutor.startQuickFocus(
                context,
                subjectName: burst.subjectName,
                subjectId: burst.subjectId,
                taskId: burst.taskId,
                examId: burst.examId,
                focusTitle: burst.title,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── MY SUBJECTS ──
        AppSectionHeader(
          title: 'My Subjects',
          icon: Icons.book_rounded,
          trailing: TextButton(
            onPressed: () => AppRouter.openSubjectList(context),
            child: const Text('View All'),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedEntrance(
          child: subjects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SubjectCreationSheet(),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Subject'),
                    ),
                  ),
                )
              : _SubjectsGrid(
                  subjects: subjects,
                  onOpenSubject: (id) => AppRouter.openSubjectDetail(context, id),
                  onFocusSubject: (s) {
                    AppRouter.openFocusModeSelection(
                      context,
                      subjectId: s.id,
                      subjectName: s.displayName,
                      focusTitle: s.displayName,
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ══════════════════════════════════════════════════════════════════
        // PLAN & STUDY 3.0 — ACADEMIC COMMAND CENTER
        // Derived entirely from the academic knowledge engine.
        // ══════════════════════════════════════════════════════════════════

        // ── §13 STUDY OVERVIEW ──
        if (!overview.hasCourse) ...[
          AnimatedEntrance(
            child: PlanStudyEmptyState(
              icon: Icons.school_outlined,
              title: 'No course yet',
              message:
                  'Set up a subject and add chapters to unlock study progress, '
                  'revision and practice signals.',
              actionLabel: 'Set Up Course',
              onAction: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SubjectCreationSheet(),
                );
              },
            ),
          ),
        ] else ...[
          AnimatedEntrance(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderColor: palette.sage.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dashboard_outlined,
                          size: 16, color: palette.forest),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Study Overview',
                          style: context.text.titleSmall!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${overview.syllabusPercentage}%',
                        style: context.text.titleSmall!.copyWith(
                          color: palette.forest,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${overview.studiedTopics} of ${overview.totalTopics} topics studied'
                    '${overview.totalStudyMinutes > 0 ? ' · ${formatPlanMinutes(overview.totalStudyMinutes)} logged' : ''}',
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StudySignalChip(
                        label: '${overview.subjects.length} subjects',
                        color: palette.sage,
                      ),
                      if (overview.hasRevisionDue)
                        _StudySignalChip(
                          label: '${overview.revisionDueTopics.length} to revise',
                          color: palette.warning,
                        ),
                      if (overview.weakTopics.isNotEmpty)
                        _StudySignalChip(
                          label: '${overview.weakTopics.length} weak',
                          color: palette.error,
                        ),
                      if (overview.practiceOpportunities.isNotEmpty)
                        _StudySignalChip(
                          label: '${overview.practiceOpportunities.length} to practise',
                          color: palette.accent,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── §18 CONTINUE LEARNING (real persisted data only) ──
          if (overview.continueLearning != null) ...[
            AppSectionHeader(
              title: 'Continue Learning',
              icon: Icons.history_rounded,
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedEntrance(
              child: StudyContinueLearningCard(
                continueLearning: overview.continueLearning!,
                onContinue: () {
                  final cl = overview.continueLearning!;
                  if (cl.topicId != null) {
                    _openTopicById(cl.topicId!);
                  } else {
                    _studySubject(
                      cl.subjectId ?? '',
                      title: cl.subjectName,
                    );
                  }
                },
                onPlan: () {
                  final cl = overview.continueLearning!;
                  final topic = cl.topicId == null
                      ? null
                      : AcademicKnowledgeController.instance.topics
                          .where((t) => t.id == cl.topicId)
                          .firstOrNull;
                  if (topic != null) {
                    _planTopic(topic);
                  } else {
                    _showSnack('Add a topic to this subject to plan it');
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── §19 ONE STRONG RECOMMENDATION (3.0) ──
          if (overview.recommended != null) ...[
            AppSectionHeader(
              title: 'Recommended',
              icon: Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedEntrance(
              child: StudyRecommendationCard(
                recommended: overview.recommended!,
                onStudy: () => _studyTopicDirect(overview.recommended!),
                onPlan: () => _planTopic(overview.recommended!.topic),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── §14 SUBJECT PROGRESS (compact, Forest/Sage) ──
          AppSectionHeader(
            title: 'Subjects',
            icon: Icons.auto_stories_rounded,
            subtitle: 'Progress, revision and exam pressure',
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final sv in overview.subjects) ...[
            AnimatedEntrance(
              child: StudySubjectRow(
                view: sv,
                onOpen: () => AppRouter.openSubjectDetail(context, sv.subject.id),
                onStudy: () => _studySubject(sv.subject.id),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.md),

          // ── §13 WEAK AREAS ──
          if (overview.weakTopics.isNotEmpty) ...[
            AppSectionHeader(
              title: 'Weak Areas',
              icon: Icons.trending_up_rounded,
              subtitle: 'Low confidence from your own evidence',
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final tv in overview.weakTopics) ...[
              StudyTopicRow(
                view: tv,
                onOpen: () => _openTopic(tv),
                onPlan: () => _planTopic(tv.topic),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            const SizedBox(height: AppSpacing.md),
          ],

          // ── §13 REVISION DUE ──
          if (overview.hasRevisionDue) ...[
            AppSectionHeader(
              title: 'Revision Due',
              icon: Icons.replay_rounded,
              subtitle: 'Spaced repetition schedule',
              trailing: TextButton(
                onPressed: () => AppRouter.openRevision(context),
                child: const Text('Open'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final tv in overview.revisionDueTopics) ...[
              StudyTopicRow(
                view: tv,
                onOpen: () => _openTopic(tv),
                onPlan: () => _planTopic(tv.topic),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            const SizedBox(height: AppSpacing.md),
          ],

          // ── §22 PRACTICE OPPORTUNITIES ──
          if (overview.practiceOpportunities.isNotEmpty) ...[
            AppSectionHeader(
              title: 'Practise',
              icon: Icons.psychology_alt_outlined,
              subtitle: 'Studied but never practised',
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final tv in overview.practiceOpportunities) ...[
              StudyTopicRow(
                view: tv,
                onOpen: () => _openTopic(tv),
                onPlan: () => _planTopic(tv.topic),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            const SizedBox(height: AppSpacing.md),
          ],

          // ── §30 NO STUDY HISTORY ──
          if (!overview.hasHistory) ...[
            AnimatedEntrance(
              child: PlanStudyEmptyState(
                icon: Icons.history_toggle_off_rounded,
                title: 'No study history',
                message:
                    'Start a topic and your progress, revision and continue '
                    'state will build from real sessions.',
                actionLabel: 'Start Studying',
                onAction: () {
                  final first = overview.subjects.isEmpty
                      ? null
                      : overview.subjects.first;
                  if (first == null) {
                    _showSnack('Add a subject first');
                  } else {
                    _studySubject(first.subject.id);
                  }
                },
              ),
            ),
          ] else if (!overview.hasRevisionDue) ...[
            AnimatedEntrance(
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: palette.softSage),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        "You're clear for now — no revision due.",
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  PlanningBlock? _findNextActionableBlock(List<PlanningBlock> blocks) {
    final now = DateTime.now();
    for (final b in blocks) {
      if (!PlanningScreen.isBlockCompleted(b) && b.endAt.isAfter(now)) {
        return b;
      }
    }
    return blocks.where((b) => !PlanningScreen.isBlockCompleted(b)).firstOrNull;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// TOP SWITCHER: PLAN | STUDY
// ══════════════════════════════════════════════════════════════════════════

class _PlanStudySwitcher extends StatelessWidget {
  const _PlanStudySwitcher({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final PlanStudyTab selectedTab;
  final ValueChanged<PlanStudyTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    // Shared SprintX segmented control: one component, sliding emerald pill,
    // same labels/icons as before. No per-screen switcher duplication.
    return StudentOSSegmentedControl<PlanStudyTab>(
      semanticLabel: 'Plan or Study selector',
      segments: const [
        StudentOSSegment(
          value: PlanStudyTab.plan,
          label: 'Plan',
          icon: Icons.calendar_today_rounded,
        ),
        StudentOSSegment(
          value: PlanStudyTab.study,
          label: 'Study',
          icon: Icons.menu_book_rounded,
        ),
      ],
      selected: selectedTab,
      onChanged: onTabChanged,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PLAN HEROES: Existing Plan / Empty Plan / Active Focus / Caught Up
// ══════════════════════════════════════════════════════════════════════════

class _ExistingPlanHero extends StatelessWidget {
  const _ExistingPlanHero({
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.nextBlock,
    required this.onStartBlock,
    required this.onPlanDay,
  });

  final int plannedMinutes;
  final int completedMinutes;
  final PlanningBlock? nextBlock;
  final ValueChanged<PlanningBlock> onStartBlock;
  final VoidCallback onPlanDay;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final remaining = (plannedMinutes - completedMinutes).clamp(0, 9999);
    final fraction = plannedMinutes > 0 ? (completedMinutes / plannedMinutes).clamp(0.0, 1.0) : 0.0;

    final blockTitle = nextBlock?.customTitle ??
        (nextBlock?.subjectId != null
            ? SubjectController.instance.subjectById(nextBlock!.subjectId!)?.displayName
            : 'Scheduled Session') ??
        'Session';
    final blockDuration = nextBlock != null ? nextBlock!.endAt.difference(nextBlock!.startAt).inMinutes : 30;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S PLAN",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: palette.primary,
                ),
              ),
              Text(
                '$completedMinutes m done · $remaining m left',
                style: context.text.labelSmall!.copyWith(color: palette.onSurfaceMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: palette.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Next action highlight
          if (nextBlock != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: palette.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: palette.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXT ACTIVITY',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                        Text(
                          blockTitle,
                          style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$blockDuration minutes planned',
                          style: context.text.labelSmall!.copyWith(color: palette.onSurfaceMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    key: const Key('start_planning_block_button'),
                    onPressed: () => onStartBlock(nextBlock!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('START', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPlanHero extends StatelessWidget {
  const _EmptyPlanHero({
    required this.selectedMinutes,
    required this.onMinutesChanged,
    required this.onAutoPlan,
    required this.onCustomPlan,
  });

  final int selectedMinutes;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onAutoPlan;
  final VoidCallback onCustomPlan;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wb_sunny_rounded, color: palette.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR DAY IS OPEN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: palette.primary,
                      ),
                    ),
                    Text(
                      'How much time do you have today?',
                      style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick time chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final mins in [30, 60, 120, 180]) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => onMinutesChanged(mins),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          // Light canonical selected treatment (same family
                          // as every Student OS card): tonal wash + primary
                          // text, never a dark fill.
                          color: selectedMinutes == mins
                              ? palette.primary.withValues(
                                  alpha: palette.isDark ? 0.22 : 0.14)
                              : palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedMinutes == mins
                                ? palette.primary.withValues(alpha: 0.6)
                                : palette.outline.withValues(alpha: 0.3),
                            width: selectedMinutes == mins ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            mins < 60 ? '${mins}m' : '${mins ~/ 60}h',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: selectedMinutes == mins
                                  ? palette.primary
                                  : palette.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Auto Plan hero action: canonical primary CTA (theme-paired
          // foreground, full pressed/disabled/focus states from the theme).
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAutoPlan,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                'PLAN MY ${selectedMinutes < 60 ? "$selectedMinutes MINUTES" : "${selectedMinutes ~/ 60} HOURS"}',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFocusHero extends StatelessWidget {
  const _ActiveFocusHero({required this.focusController});

  final FocusController focusController;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final session = focusController.activeSession;
    final title = session?.objective.isNotEmpty == true ? session!.objective : 'Deep Focus';
    final remainingMins = focusController.activeRemaining.inMinutes;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.streak.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_rounded, color: palette.streak, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOCUS SESSION IN PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: palette.streak,
                      ),
                    ),
                    Text(
                      title,
                      style: context.text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      remainingMins > 0 ? '$remainingMins min remaining' : 'In progress',
                      style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => AppRouter.openActiveFocusSession(context),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('CONTINUE FOCUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.streak,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllCaughtUpHero extends StatelessWidget {
  const _AllCaughtUpHero({
    required this.completedMinutes,
    required this.sessionCount,
  });

  final int completedMinutes;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, color: palette.success, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "YOU'RE ALL CAUGHT UP 🎉",
            style: context.text.titleMedium!.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            'Nice work! $completedMinutes min completed across $sessionCount session(s).',
            style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

class _MissedSessionsAlert extends StatelessWidget {
  const _MissedSessionsAlert({
    required this.missedCount,
    required this.onFixPlan,
  });

  final int missedCount;
  final VoidCallback onFixPlan;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$missedCount missed session(s) today',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: palette.onSurface),
            ),
          ),
          TextButton(
            onPressed: onFixPlan,
            style: TextButton.styleFrom(foregroundColor: palette.warning),
            child: const Text('Fix My Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════
// STUDY TAB COMPONENTS: Recommendations, Subjects, Study Plan
// ══════════════════════════════════════════════════════════════════════════

class _StudyRecommendationHero extends StatelessWidget {
  const _StudyRecommendationHero({
    required this.recommendation,
    required this.onStart,
  });

  final StudyRecommendation recommendation;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_rounded, color: palette.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.subjectName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: palette.primary,
                      ),
                    ),
                    Text(
                      recommendation.title,
                      style: context.text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      recommendation.primaryReason,
                      style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              'START ${recommendation.suggestedDurationMinutes} MIN STUDY',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyPlanStrip extends StatelessWidget {
  const _StudyPlanStrip({
    required this.blocks,
    required this.onStartBlock,
  });

  final List<PlanningBlock> blocks;
  final ValueChanged<PlanningBlock> onStartBlock;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final b in blocks) ...[
            Container(
              width: 160,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: palette.outline.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.customTitle ?? 'Session',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${b.endAt.difference(b.startAt).inMinutes} min',
                    style: TextStyle(color: palette.onSurfaceMuted, fontSize: 11),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: OutlinedButton(
                      onPressed: () => onStartBlock(b),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: palette.primary),
                      ),
                      child: Text(
                        PlanningScreen.isBlockCompleted(b) ? 'Review' : 'Start',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThirtyMinuteBurstCard extends StatelessWidget {
  const _ThirtyMinuteBurstCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppPressable(
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: palette.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flash_on_rounded, color: palette.primary, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '30-Minute Study Burst',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    'Quick focus on your highest priority learning item',
                    style: TextStyle(fontSize: 11, color: palette.onSurfaceMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: palette.primary),
          ],
        ),
      ),
    );
  }
}

class _SubjectsGrid extends StatelessWidget {
  const _SubjectsGrid({
    required this.subjects,
    required this.onOpenSubject,
    required this.onFocusSubject,
  });

  final List<Subject> subjects;
  final ValueChanged<String> onOpenSubject;
  final ValueChanged<Subject> onFocusSubject;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final s in subjects) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SubjectTile(
              subject: s,
              onTap: () => onOpenSubject(s.id),
              onFocus: () => onFocusSubject(s),
            ),
          ),
        ],
      ],
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({
    required this.subject,
    required this.onTap,
    required this.onFocus,
  });

  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.book_rounded, color: palette.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.displayName,
                    style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Tap to view topics & learning outline',
                    style: context.text.labelSmall!.copyWith(color: palette.onSurfaceMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_circle_outline_rounded, color: palette.primary, size: 24),
              tooltip: 'Focus on ${subject.displayName}',
              onPressed: onFocus,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CONTEXTUAL SECTIONS: Tasks Checklist & Exam Cards
// ══════════════════════════════════════════════════════════════════════════

class _TasksChecklistSection extends StatelessWidget {
  const _TasksChecklistSection({
    required this.tasks,
    required this.onToggle,
    required this.onOpenTask,
  });

  final List<StudentTask> tasks;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onOpenTask;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    if (tasks.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Text(
            'No tasks scheduled for today.',
            style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < tasks.take(5).length; i++) ...[
            _TaskRow(
              task: tasks[i],
              onToggle: () => onToggle(tasks[i].id),
              onTap: () => onOpenTask(tasks[i].id),
              palette: palette,
            ),
            if (i < tasks.take(5).length - 1)
              Divider(height: 1, indent: 48, color: palette.outline.withValues(alpha: 0.3)),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.palette,
  });

  final StudentTask task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    // §27 — a task linked to a subject shows that academic context inline.
    // StudentTask carries subjectId only; chapter/topic are not modelled on
    // the task, so nothing is invented here.
    final subjectName = task.subjectId == null
        ? null
        : SubjectController.instance.subjectById(task.subjectId!)?.displayName;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) => onToggle(),
              activeColor: palette.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? palette.onSurfaceMuted : palette.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subjectName != null)
                    Text(
                      subjectName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: palette.mutedGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (task.isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: palette.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('Overdue', style: TextStyle(fontSize: 9.5, color: palette.error, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingExamCard extends StatelessWidget {
  const _UpcomingExamCard({required this.exam});

  final StudentExam exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final days = exam.daysUntilExam ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_rounded, color: palette.error, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPCOMING EXAM',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: palette.error,
                  ),
                ),
                Text(
                  exam.title,
                  style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  days == 0 ? 'Exam is today!' : 'In $days day${days == 1 ? "" : "s"}',
                  style: TextStyle(fontSize: 11, color: palette.onSurfaceMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => AppRouter.openExamDetail(context, exam.id),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// DAY SELECTOR STRIP WIDGET
// ══════════════════════════════════════════════════════════════════════════

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.controller,
    required this.onSelect,
  });

  final PlanController controller;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final weekDays = controller.week;
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: [
        for (int i = 0; i < weekDays.length; i++) ...[
          Expanded(
            child: _DayTab(
              day: weekDays[i],
              weekdayLabel: weekdays[weekDays[i].weekday - 1],
              isSelected: controller.isSelected(weekDays[i]),
              isToday: controller.isToday(weekDays[i]),
              onTap: () => onSelect(weekDays[i]),
              palette: palette,
            ),
          ),
        ],
      ],
    );
  }
}

class _DayTab extends StatelessWidget {
  const _DayTab({
    required this.day,
    required this.weekdayLabel,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    required this.palette,
  });

  final DateTime day;
  final String weekdayLabel;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : (isToday ? palette.primary.withValues(alpha: 0.12) : Colors.transparent),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(
              weekdayLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? palette.onPrimary : palette.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? palette.onPrimary : (isToday ? palette.primary : palette.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PHASE 3 SUPPORT WIDGETS
// ══════════════════════════════════════════════════════════════════════════

/// §10 — Recovery destination picker. Only real free slots, chosen explicitly.
/// Nothing is moved or deleted until the student taps one.
class _RecoverySlotSheet extends StatelessWidget {
  const _RecoverySlotSheet({
    required this.title,
    required this.minutes,
    required this.slots,
  });

  final String title;
  final int minutes;
  final List<DateTime> slots;

  String _label(DateTime t) {
    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(t.year, t.month, t.day);
    final dayLabel = target.difference(today).inDays == 0
        ? 'Today'
        : (target.difference(today).inDays == 1
            ? 'Tomorrow'
            : '${weekdays[t.weekday - 1]} ${t.day}/${t.month}');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$dayLabel · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reschedule',
            style: context.text.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$title · $minutes min — respects existing blocks and commitments',
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final slot in slots) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              onTap: () => Navigator.of(context).pop(slot),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 18, color: palette.forest),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _label(slot),
                      style: context.text.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: palette.onSurfaceMuted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep as is'),
          ),
        ],
      ),
    );
  }
}

/// §13 — Small signal chip used by the study overview header.
class _StudySignalChip extends StatelessWidget {
  const _StudySignalChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: context.text.labelSmall!.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
