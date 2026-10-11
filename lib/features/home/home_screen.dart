import 'package:flutter/material.dart' hide Actions;
import '../../core/intelligence/adaptive_priority_engine.dart' as intelligence;
import '../../core/widgets/app_hit_test_area.dart';

import '../../app/app_router.dart';
import '../../core/assistant/assistant_launch_context.dart';
import '../../core/animations/animated_entrance.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/design/student_os_premium.dart';
import '../../core/design/tokens/student_os_tokens.dart';
import '../guides/guide_controller.dart';
import '../guides/guide_overlay.dart';
import '../guides/guide_progress_store.dart';
import '../guides/guide_targets.dart';
import '../../core/intelligence/academic_intelligence_controller.dart';
import '../../core/intelligence/autopilot_engine.dart';
import '../../core/intelligence/daily_academic_snapshot.dart';
import '../../core/intelligence/daily_os_coordinator.dart';
import '../../core/intelligence/student_os_intelligence_engine.dart';
import '../../core/navigation/universal_action_executor.dart';
import '../../core/services/streak_service.dart';
import '../../core/services/student_service.dart';
import '../../core/time/app_clock.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/app_states.dart';
import '../../core/design/components/buttons/app_button.dart';
import '../../core/widgets/student_os_action_cards.dart';
import '../../core/widgets/student_os_assistant_visual.dart';
import '../../data/models/exam.dart';
import '../auth/auth_service.dart';
import '../exams/exam_controller.dart';
import '../focus/controller/focus_controller.dart';
import '../goals/goal_controller.dart';
import '../planning/controllers/planning_block_controller.dart';
import '../planning/models/planning_block.dart';
import '../planning/services/planning_engine.dart';
import '../progression/progression_controller.dart';
import '../resources/resource_controller.dart';
import '../study/study_controller.dart';
import '../student_life/models/student_life_preferences.dart';
import '../student_life/student_life_controller.dart';
import '../subjects/subject_controller.dart';
import '../sleep/widgets/sleep_summary_card.dart';
import '../tasks/presentation/task_creation_sheet.dart';
import '../tasks/task_controller.dart';
import '../calendar/academic_schedule_controller.dart';
import 'home_controller.dart';
import 'adaptive_intelligence_widgets.dart';
import 'home_command_center_state.dart';
import 'home_command_center_widgets.dart';

/// Home 2.0 — The Intelligent Student OS Dashboard.
///
/// Designed around four core answers:
/// 1. What should I do now? (Primary Student OS recommendation or Active Focus)
/// 2. What is happening today? (Planned time, remaining time, daily progress)
/// 3. What needs my attention? (Contextual urgency/risk alerts only when real data requires it)
/// 4. How do I quickly start something? (Compact 4-button Quick Actions + Global Add)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use a ChangeNotifier or dedicated State controller to manage the derived Home state.
  // This will prevent rebuilding the entire screen for every small controller change.
  late HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
    DailyOsCoordinator.instance.init();

    // Listen to changes in the controller, NOT every single underlying service.
    _homeController.addListener(_onDataChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferTour());
  }

  // ... (keep the rest of the file mostly the same for now,
  // but replace the listeners with _homeController listening)

  /// One-time 60-second tour offer after fresh onboarding. Never traps:
  /// both choices dismiss permanently (Start launches, Skip records).
  Future<void> _maybeOfferTour() async {
    if (!mounted) {
      return;
    }
    try {
      final store = GuideProgressStore.instance;
      await store.load();
      if (!mounted) {
        return;
      }
      if (!store.tourOfferPending || store.tourState != null) {
        return;
      }
      await store.setTourOfferPending(false);
      if (!mounted) {
        return;
      }
      final start = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => const _TourOfferDialog(),
      );
      if (!mounted) {
        return;
      }
      if (start == true) {
        GuideOverlayManager.ensureListening();
        await GuideController.instance.startGuide('quick_tour');
      } else {
        await store.setTourState('skipped');
      }
    } catch (_) {
      // Tour offer is best-effort; Home must never break because of it.
    }
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

  String get _userName {
    final profile = StudentService.instance.profile;
    if (profile.displayName.isNotEmpty) return profile.displayName;
    if (profile.email.isNotEmpty) return profile.email.split('@').first;
    return 'Student';
  }

  /// Time-of-day greeting derived from the testable clock, so the "Home
  /// changes through the day" behaviour is verifiable without a real device.
  String get _greeting {
    final hour = AppClock.current.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateLabel {
    final now = AppClock.current;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  void _openCreateTaskSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskCreationSheet(),
    );
  }

  void _retrySnapshot() {
    DailyOsCoordinator.instance.refresh();
    AcademicIntelligenceController.instance.refresh();
    if (mounted) setState(() {});
  }

  /// Never lets an intelligence/derived read crash Home: returns [fallback]
  /// when the read throws. Callers render loading/empty/error states instead.
  static T? _safeRead<T>(T Function() read, {T? fallback}) {
    try {
      return read();
    } catch (_) {
      return fallback;
    }
  }

  /// Explains the recommendation using only the engine's own reasons, so Home
  /// never asserts anything the intelligence layer did not derive.
  void _showWhyRecommended(BuildContext context, HomeCommandCenterState home) {
    final rec = home.recommendation;
    if (rec == null) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Why this?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rec.reason),
            if (rec.supportingReasons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final line in rec.supportingReasons)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $line'),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskController.instance;
    final ec = ExamController.instance;
    final sc = StudyController.instance;
    final fc = FocusController.instance;
    final aic = AcademicIntelligenceController.instance;

    DailyAcademicSnapshot? snapshot;
    try {
      snapshot = DailyOsCoordinator.instance.snapshot;
    } catch (_) {
      snapshot = null;
    }

    final hasAnyData =
        tc.tasks.isNotEmpty ||
        ec.exams.isNotEmpty ||
        sc.sessions.isNotEmpty ||
        fc.sessions.isNotEmpty ||
        fc.hasActiveSession;
    final controllersLoading = !tc.isLoaded || !ec.isLoaded || !sc.isLoaded;
    final isAuthenticated = AuthService.instance.isAuthenticated;
    final isLoading = isAuthenticated && controllersLoading && !hasAnyData;

    final showError =
        !isLoading &&
        isAuthenticated &&
        !controllersLoading &&
        snapshot == null;

    final currentAction = _safeRead(() => aic.studentOSAction);
    final dailyState = _safeRead(() => aic.dailyStudentState);
    final autopilotState = _safeRead(() => aic.autopilotDayState);
    final streak = _safeRead(
      () => StreakService.instance.currentStreak,
      fallback: 0,
    )!;
    final HomeCommandCenterState? home = _safeRead(
      () => HomeCommandCenterState.derive(),
    );

    // A failed derivation degrades to the error state below (with Retry) —
    // the branch uses explicit null checks (which also promote these for
    // the content branch). Never a build crash / blank screen.

    // P4 single pipeline: authoritative Today inputs (no duplicate calc).
    // Null-aware: when derivation failed these degrade to empty and the
    // error state below takes over the screen.
    final now = home?.now ?? AppClock.current;
    final todayBlocks = home?.plannedBlocks ?? const [];
    final focusMinutesToday = home?.focusMinutesToday ?? 0;
    final isFirstTime = tc.tasks.isEmpty &&
        todayBlocks.isEmpty &&
        SubjectController.instance.subjects.isEmpty &&
        ec.exams.isEmpty;
    // Subtle hero hint only — the Today card keeps the single authoritative
    // overload / recovery surface (one badge, one Rebalance, one Recover).
    String? dayHint;
    if (dailyState?.workloadState == WorkloadState.overloaded) {
      dayHint =
          'Heads up: today is packed (${dailyState?.plannedMinutes}m planned vs '
          '${dailyState?.availableMinutes}m available) — see Today below.';
    } else if ((autopilotState?.recoverySessions ?? const []).isNotEmpty) {
      dayHint =
          'You have some unfinished work — see Today below for the next step.';
    }

    return AppScaffold(
      showAmbient: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: AppSpacing.sm,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // ── 1. HEADER (locked) ────
            AnimatedEntrance(
              child: _HomeHeader(
                greeting: _greeting,
                userName: _userName,
                dateLabel: _dateLabel,
                streak: streak,
                onAdd: () => UniversalActionExecutor.openGlobalAdd(context),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (isLoading) ...[
              const _HomeLoadingState(),
            ] else if (showError ||
                home == null ||
                currentAction == null ||
                dailyState == null ||
                autopilotState == null) ...[
              AppErrorState(
                message:
                    "Couldn't load your day. Check your connection "
                    'and try again — your data is safe.',
                onRetry: _retrySnapshot,
              ),
            ] else ...[
              // ── ACTIVE SESSION (highest contextual priority) ──
              // Reflects the ONE session that already exists in
              // FocusController. Home never starts or stops one.
              if (home.hasActiveSession) ...[
                AnimatedEntrance(
                  child: HomeActiveSessionBanner(
                    session: home.activeSession!,
                    // Switch to the Focus destination, which already owns this
                    // session. Home never starts a second one.
                    onContinue: () => AppRouter.openFocusTab(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

// ── 2. QUICK ACTIONS (locked, compact, contextual details) ──
              AnimatedEntrance(
                child: StreamBuilder<List<intelligence.PrioritizedAction>>(
                    stream: Stream.periodic(const Duration(minutes: 5), (_) => AcademicIntelligenceController.instance.rankedActions),
                    initialData: AcademicIntelligenceController.instance.rankedActions,
                    builder: (context, snapshot) {
                      final actions = snapshot.data ?? [];
                      // Map the top recommendations from the engine into the Quick Actions format
                      return _QuickActionsSection(
                        home: home,
                        onAddTask: _openCreateTaskSheet,
                      );
                    }),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Assistant entry (progressive disclosure, not duplicate hero) ──
              AnimatedEntrance(
                child: _HomeAssistantBar(
                  onTap: () => UniversalActionExecutor.openAssistant(
                      context,
                      launchContext: const AssistantLaunchContext(
                        origin: AssistantOrigin.home,
                      ),
                    ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Sleep window (P1: compact summary, no Home redesign) ──
              const AnimatedEntrance(
                child: SleepSummaryCard(compact: true),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Autopilot awareness (reads the existing preference only) ──
              if (home.autopilotAwareness != HomeAutopilotAwareness.off) ...[
                AnimatedEntrance(
                  child: HomeAutopilotStrip(
                    awareness: home.autopilotAwareness,
                    nextActionTitle: home.autopilotNextActionTitle,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── 3. TODAY'S HERO (single authoritative hero) ──
              AnimatedEntrance(
                child: GuideTargetAnchor(
                  id: 'home.hero',
                  child: StudentOSCard(
                  action: currentAction,
                  isDoneForToday: aic.isDoneForToday,
                  isStartMyDay:
                      dailyState.plannedMinutes > 0 &&
                      dailyState.completedMinutes == 0 &&
                      currentAction.type == StudentOSActionType.scheduledBlock &&
                      !currentAction.isFocusActive &&
                      !aic.isDoneForToday,
                  isContinueMyDay:
                      dailyState.plannedMinutes > 0 &&
                      dailyState.completedMinutes > 0 &&
                      currentAction.type == StudentOSActionType.scheduledBlock &&
                      !currentAction.isFocusActive &&
                      !aic.isDoneForToday,
                  dayHint: dayHint,
                  onExecuteAction: (act) =>
                      UniversalActionExecutor.executeAction(context, act),
                  onThirtyMinBurst: () {
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
                  onToggleDoneToday: (done) => aic.setDoneForToday(done),
                ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Empty / No-plan hint (progressive disclosure, below hero) ──
              if (isFirstTime) ...[
                const AnimatedEntrance(
                  child: _FirstTimeEmptyState(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── 4. TODAY PROGRESS (single authoritative progress, no duplicate metrics) ──
              AnimatedEntrance(
                child: _TodayProgressCard(
                  state: dailyState,
                  healthState: autopilotState.healthState,
                  focusMinutesToday: focusMinutesToday,
                  onViewPlan: () {
                    AppRouter.openPlan(context);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── 4b. STUDENT LIFE (minimal sleep + routine entry point) ──
              const AnimatedEntrance(
                child: _StudentLifeCard(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── 5. NEXT / SCHEDULE (single authoritative schedule, hidden when empty & not overloaded) ──
              if (todayBlocks.isNotEmpty || autopilotState.isOverloaded || autopilotState.recoverySessions.isNotEmpty) ...[
                AnimatedEntrance(
                  child: _NextScheduleSection(
                    todayBlocks: todayBlocks,
                    referenceTime: now,
                    recoverySessions: autopilotState.recoverySessions,
                    healthState: autopilotState.healthState,
                    isOverloaded: autopilotState.isOverloaded,
                    healthMessage: autopilotState.healthMessage,
                    earlyCompletion: autopilotState.earlyCompletion,
                    onRebalance: () async {
                      final count = await aic.rebalanceDay();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              count > 0
                                  ? 'Rebalanced $count ${count == 1 ? 'block' : 'blocks'} to future capacity'
                                  : 'Schedule is within capacity',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    onRecoverSession: (session) async {
                      final block = await aic.recoverMissedSession(session);
                      if (context.mounted && block != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                          content: Text(
                            'Recovered and scheduled "${session.title}"',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── 6. RECOMMENDED ACTION ──
              // Exactly ONE recommendation, selected from the existing
              // AdaptivePriorityEngine ranking. Rendered only when the engine
              // actually has something the hero is not already showing —
              // Home never fabricates a suggestion.
              if (home.recommendation != null) ...[
                AnimatedEntrance(
                  child: HomeRecommendedActionCard(
                    recommendation: home.recommendation!,
                    onStart: () => UniversalActionExecutor.executeAction(
                      context,
                      home.recommendation!.action,
                    ),
                    onWhy: () => _showWhyRecommended(context, home),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── 7. UPCOMING / EXAM (single upcoming exam, no duplicate dashboard) ──
              AnimatedEntrance(
                child: _UpcomingAndGoalsSection(
                  nextExam: dailyState.nextExam,
                  upcomingExamsCount: dailyState.upcomingExams.length,
                  revisionCount: dailyState.revisionDueCount,
                  goal: GoalController.instance.personalGoal,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── 8. PROGRESSION FOOTER (below locked sequence, allowed) ──
              AnimatedEntrance(
                child: _ProgressionBar(
                  onTap: () => AppRouter.openRewards(context),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    ),
  ),
  );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HOME HEADER — Greeting + Date, with streak and a subordinate Quick Add.
// The premium XP / Notification / Profile action group lives in the shell
// top bar, so this row stays clean and never competes with it.
// ══════════════════════════════════════════════════════════════════════════

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.userName,
    required this.dateLabel,
    required this.streak,
    required this.onAdd,
  });

  final String greeting;
  final String userName;
  final String dateLabel;
  final int streak;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$greeting, $userName',
                style: PremiumType.hero(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (streak > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: palette.streak.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 13,
                  color: palette.streak,
                ),
                const SizedBox(width: 2),
                Text(
                  '$streak d',
                  style: context.text.labelSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.streak,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Quick Add — deliberate and subordinate to the top-bar action group.
        AppPressable(
          onTap: onAdd,
          semanticLabel: 'Add item',
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: palette.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_rounded,
              size: 15,
              color: palette.onSurfaceMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.home, this.onAddTask});

  /// Derived once by Home and passed down, so tiles do no controller reads.
  final HomeCommandCenterState home;
  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    // Forest/emerald/sage tonal system defines the product.
    const focus = StudentOSColors.forest;
    const plan = StudentOSColors.mutedGreen;
    const study = StudentOSColors.sage;
    const revise = StudentOSColors.softSage;
    const addTask = StudentOSColors.forest;
    const exams = StudentOSColors.mutedGreen;
    const calendar = StudentOSColors.sage;

    // Every detail below is a real counter from the derived state. Empty
    // details are omitted rather than shown as "0".
    //
    // Only counters that are NOT already shown in a dedicated section get a
    // tile detail, so the same number never appears twice on one screen:
    // the exam countdown lives in Upcoming, the overdue count lives in Today
    // Progress. That keeps Quick Actions a launcher, not a second dashboard.
    //
    // Ask OS is intentionally NOT in this grid — it owns the dedicated
    // canonical Assistant entry card below, so it reads as special.
    final focusDetail = home.focusDetailLabel;
    final planDetail = home.planDayDetailLabel;
    final studyDetail = home.studyDetailLabel;
    final reviseDetail = home.reviseDetailLabel;

    String withFallback(String? detail, String fallback) =>
        (detail != null && detail.isNotEmpty) ? detail : fallback;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Quick Actions',
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const maxGridWidth = 560.0;
            final gridWidth = constraints.maxWidth > maxGridWidth
                ? maxGridWidth
                : constraints.maxWidth;
            final spacing = gridWidth < 380 ? 8.0 : 10.0;

            return Center(
              child: SizedBox(
                width: gridWidth,
                child: Column(
                  children: [
                    // PRIMARY: Focus / Plan Day / Study — value-first.
                    Row(
                      children: [
                        Expanded(
                          child: StudentOSFeaturedAction(
                            icon: Icons.timer_rounded,
                            title: 'Focus',
                            subtitle: 'Start a focused session',
                            color: focus,
                            detail: withFallback(
                                focusDetail, 'Start a focused session'),
                            badge: home.hasActiveSession ? 'LIVE' : null,
                            onTap: () =>
                                AppRouter.openFocusCenter(context),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: StudentOSFeaturedAction(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Plan Day',
                            subtitle: "Build today's plan",
                            color: plan,
                            detail: withFallback(
                                planDetail, "Build today's plan"),
                            onTap: () => UniversalActionExecutor
                                .openPlanMyDay(context),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: StudentOSFeaturedAction(
                            icon: Icons.menu_book_rounded,
                            title: 'Study',
                            subtitle: 'Continue learning',
                            color: study,
                            detail: withFallback(
                                studyDetail, 'Continue learning'),
                            onTap: () => AppRouter.openStudy(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    // SECONDARY: compact launchers.
                    Row(
                      children: [
                        Expanded(
                          child: StudentOSStandardAction(
                            icon: Icons.replay_rounded,
                            label: 'Revise',
                            color: revise,
                            detail: reviseDetail,
                            onTap: () =>
                                AppRouter.openRevision(context),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: StudentOSStandardAction(
                            icon: Icons.add_task_rounded,
                            label: 'Add Task',
                            color: addTask,
                            onTap: () => onAddTask?.call(),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: StudentOSStandardAction(
                            icon: Icons.school_rounded,
                            label: 'Exams',
                            color: exams,
                            onTap: () => AppRouter.openExams(context),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: StudentOSStandardAction(
                            icon: Icons.calendar_month_rounded,
                            label: 'Calendar',
                            color: calendar,
                            onTap: () =>
                                AppRouter.openCalendar(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// UPCOMING & GOALS SUMMARY SECTION
// ══════════════════════════════════════════════════════════════════════════

class _UpcomingAndGoalsSection extends StatelessWidget {
  const _UpcomingAndGoalsSection({
    this.nextExam,
    required this.upcomingExamsCount,
    required this.revisionCount,
    required this.goal,
  });

  final StudentExam? nextExam;
  final int upcomingExamsCount;
  final int revisionCount;
  final String goal;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Upcoming & Goals',
          icon: Icons.insights_rounded,
          trailing: TextButton(
            onPressed: () => AppRouter.openMore(context),
            child: const Text('More'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Next Exam strip (if any)
        if (nextExam != null) ...[
          StudentOSListRow(
            icon: Icons.school_rounded,
            title: nextExam!.title,
            subtitle: nextExam!.countdown ?? 'Upcoming',
            color: palette.streak,
            onTap: () => AppRouter.openExamDetail(context, nextExam!.id),
          ),
          const SizedBox(height: AppSpacing.xs),
        ] else if (upcomingExamsCount == 0) ...[
          StudentOSListRow(
            icon: Icons.add_rounded,
            title: 'Add your next exam',
            subtitle: 'Track the date, countdown & prep',
            color: palette.primary,
            onTap: () => AppRouter.openAddExam(context),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        // Revision items strip (if any)
        if (revisionCount > 0) ...[
          StudentOSListRow(
            icon: Icons.replay_rounded,
            title: '$revisionCount revision ${revisionCount == 1 ? "item" : "items"} due',
            subtitle: 'Review concepts and topics',
            color: palette.primary,
            onTap: () => AppRouter.openRevision(context),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        // Personal goal strip (if set)
        if (goal.trim().isNotEmpty) ...[
          StudentOSListRow(
            icon: Icons.flag_rounded,
            title: goal.trim(),
            subtitle: 'Personal Academic Goal',
            color: palette.streak,
            onTap: () => AppRouter.openGoals(context),
          ),
        ],
      ],
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════
// PROGRESSION LEVEL BAR
// ══════════════════════════════════════════════════════════════════════════

class _ProgressionBar extends StatelessWidget {
  const _ProgressionBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final ctrl = ProgressionController.instance;
    final studentLevel = ctrl.currentLevel;
    final level = studentLevel.level;
    final progress = studentLevel.progressInLevel;
    final xpToNext = studentLevel.xpToNextLevel;

    return AppPressable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: palette.accentGradient),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Level $level Scholar',
                          style: context.text.labelMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          '$xpToNext XP to Lvl ${level + 1}',
                          style: context.text.labelSmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: palette.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(palette.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, size: 18, color: palette.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ASSISTANT QUICK BAR
// ══════════════════════════════════════════════════════════════════════════

class _HomeAssistantBar extends StatelessWidget {
  const _HomeAssistantBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Canonical Assistant identity — the SAME visual used on Tools,
    // Planning and Workspace, so Ask OS reads as one entity.
    return StudentOSAssistantEntryCard(
      onTap: onTap,
      title: 'Ask Student OS',
      subtitle: '"I have 2 hours" · "What should I study?"',
      status: StudentOSAssistantStatus.ready,
      statusLabel: 'READY',
    );
  }
}

class _TodayPlanTile extends StatelessWidget {
  const _TodayPlanTile({required this.block, required this.referenceTime});

  final PlanningBlock block;
  final DateTime referenceTime;

  bool get _linkedTaskCompleted {
    if (block.taskId == null) return false;
    try {
      final task = TaskController.instance.tasks
          .where((t) => t.id == block.taskId)
          .firstOrNull;
      return task?.isCompleted ?? false;
    } catch (_) {
      return false;
    }
  }

  String _title() {
    if (block.taskId != null) {
      try {
        final task = TaskController.instance.tasks
            .where((t) => t.id == block.taskId)
            .firstOrNull;
        if (task != null) return task.title;
      } catch (_) {}
    }
    if (block.subjectId != null) {
      try {
        final subject =
            SubjectController.instance.subjectById(block.subjectId!);
        if (subject != null && block.customTitle == null) {
          return subject.displayName;
        }
      } catch (_) {}
    }
    return block.customTitle ?? 'Planned session';
  }

  String _timeRange() {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(block.startAt.hour)}:${two(block.startAt.minute)} – '
        '${two(block.endAt.hour)}:${two(block.endAt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final status = UniversalActionExecutor.derivePlanningBlockStatus(
      block,
      linkedTaskCompleted: _linkedTaskCompleted,
      referenceTime: referenceTime,
    );
    final durationMins = block.endAt.difference(block.startAt).inMinutes;

    final Color statusColor;
    final String statusLabel;
    switch (status) {
      case PlanningBlockStatus.upcoming:
        statusColor = palette.primary;
        statusLabel = 'UPCOMING';
        break;
      case PlanningBlockStatus.current:
        statusColor = palette.success;
        statusLabel = 'CURRENT';
        break;
      case PlanningBlockStatus.completed:
        statusColor = palette.onSurfaceMuted;
        statusLabel = 'COMPLETED';
        break;
      case PlanningBlockStatus.missed:
        statusColor = palette.warning;
        statusLabel = 'MISSED';
        break;
      case PlanningBlockStatus.skipped:
        statusColor = palette.onSurfaceMuted;
        statusLabel = 'SKIPPED';
        break;
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              statusLabel,
              style: context.text.labelSmall!.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title(),
                  style: context.text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_timeRange() · ${durationMins}m',
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _PlanTileAction(status: status, block: block),
        ],
      ),
    );
  }
}

class _PlanTileAction extends StatelessWidget {
  const _PlanTileAction({required this.status, required this.block});

  final PlanningBlockStatus status;
  final PlanningBlock block;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case PlanningBlockStatus.current:
      case PlanningBlockStatus.upcoming:
        return AppButton.compact(
          label: status == PlanningBlockStatus.current ? 'Continue' : 'Start',
          onPressed: () => AppRouter.startPlanningBlockFocus(context, block),
        );
      case PlanningBlockStatus.missed:
        return AppButton.compact(
          label: 'Recover',
          onPressed: () => UniversalActionExecutor.executePlanningBlockAction(
            context,
            UniversalBlockAction.recover,
            block,
          ),
        );
      case PlanningBlockStatus.completed:
      case PlanningBlockStatus.skipped:
        return IconButton(
          tooltip: 'View plan',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          onPressed: () => AppRouter.openPlan(context),
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
        );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// FIRST-TIME TOUR OFFER — one-time 60s tour dialog after fresh onboarding.
// ══════════════════════════════════════════════════════════════════════════

class _TourOfferDialog extends StatelessWidget {
  const _TourOfferDialog();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        'Welcome to Student OS',
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Want a quick 60-second tour? Home, Plan, SprintX, Assistant, Sleep, Progress — learn by doing.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.onSurfaceMuted,
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Start Tour'),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// FIRST-TIME EMPTY STATE — guided setup, no fake data.
// ══════════════════════════════════════════════════════════════════════════

class _FirstTimeEmptyState extends StatelessWidget {
  const _FirstTimeEmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's build your day.",
            style: context.text.titleSmall!.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a task or subject, then generate a plan — or just ask Student OS.',
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                onPressed: () => UniversalActionExecutor.openGlobalAdd(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Task'),
              ),
              OutlinedButton.icon(
                onPressed: () => AppRouter.openSubjectList(context),
                icon: const Icon(Icons.auto_stories_rounded, size: 16),
                label: const Text('Add Subject'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    UniversalActionExecutor.openPlanMyDay(context),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Plan My Day'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    UniversalActionExecutor.openAssistant(
                      context,
                      launchContext: const AssistantLaunchContext(
                        origin: AssistantOrigin.home,
                      ),
                    ),
                icon: const Icon(Icons.smart_toy_outlined, size: 16),
                label: const Text('Ask Student OS'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// P4 LOCKED SEQUENCE: TODAY PROGRESS (single authoritative progress)
// ══════════════════════════════════════════════════════════════════════════

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({required this.state, this.healthState, required this.focusMinutesToday, required this.onViewPlan});

  final DailyStudentState state;
  final DayHealthState? healthState;
  final int focusMinutesToday;
  final VoidCallback onViewPlan;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final isOverloaded = state.workloadState == WorkloadState.overloaded;
    final effectiveHealth = healthState;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Today', style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w800)),
                  if (effectiveHealth != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: effectiveHealth.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(effectiveHealth.label.toUpperCase(), style: context.text.labelSmall!.copyWith(color: effectiveHealth.color, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.4)),
                    ),
                  ],
                ],
              ),
              Text(
                state.plannedMinutes > 0 ? '${state.completedMinutes}m / ${state.plannedMinutes}m' : 'No plan',
                style: context.text.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: palette.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(state.summary, style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (state.plannedMinutes > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: state.progressFraction,
                minHeight: 5,
                backgroundColor: palette.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(isOverloaded ? palette.error : palette.primary),
              ),
            ),
          ],
          // Prioritised metrics instead of one long "a · b · c · d" string.
          // Home shows the 2–4 numbers that actually matter right now and
          // drops the rest, so progress never becomes a mini analytics screen.
          const SizedBox(height: AppSpacing.sm),
          HomeProgressSummary(
            plannedMinutes: state.plannedMinutes,
            completedMinutes: state.completedMinutes,
            overdueTaskCount: state.overdueTasksCount,
            focusMinutesToday: focusMinutesToday,
            isOverloaded: isOverloaded,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewPlan,
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: const Text('View Plan'),
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// P4 LOCKED SEQUENCE: NEXT / SCHEDULE (single authoritative schedule)
// ══════════════════════════════════════════════════════════════════════════

class _NextScheduleSection extends StatelessWidget {
  const _NextScheduleSection({
    required this.todayBlocks,
    required this.referenceTime,
    required this.recoverySessions,
    required this.healthState,
    this.isOverloaded = false,
    required this.healthMessage,
    required this.earlyCompletion,
    required this.onRebalance,
    required this.onRecoverSession,
  });

  final List<PlanningBlock> todayBlocks;
  final DateTime referenceTime;
  final List<MissedSession> recoverySessions;
  final DayHealthState? healthState;
  final bool isOverloaded;
  final String? healthMessage;
  final EarlyCompletionOpportunity? earlyCompletion;
  final VoidCallback? onRebalance;
  final ValueChanged<MissedSession>? onRecoverSession;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final sorted = [...todayBlocks]..sort((a, b) => a.startAt.compareTo(b.startAt));
    final hasRecovery = recoverySessions.isNotEmpty;
    final hasEarly = earlyCompletion != null;

    // Find current/next for header
    PlanningBlock? current;
    PlanningBlock? next;
    for (final b in sorted) {
      if (!referenceTime.isBefore(b.startAt) && referenceTime.isBefore(b.endAt)) {
        current ??= b;
      } else if (referenceTime.isBefore(b.startAt)) {
        next ??= b;
        if (current != null) break;
      }
    }
    final displayBlock = current ?? next;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: "Today's Plan",
          icon: Icons.schedule_rounded,
          trailing: TextButton(onPressed: () => AppRouter.openPlan(context), child: const Text('Plan')),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Single overload strip
        if (isOverloaded && onRebalance != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: palette.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: palette.error.withValues(alpha: 0.3))),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: palette.error),
                const SizedBox(width: 6),
                Expanded(child: Text(healthMessage ?? 'Today is overloaded', style: context.text.labelSmall!.copyWith(color: palette.error, fontWeight: FontWeight.w600))),
              TextButton(
                  onPressed: onRebalance,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                  ),
                  child: Text('Rebalance', style: context.text.labelSmall!.copyWith(color: palette.error, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // Single recovery strip
        if (hasRecovery && onRecoverSession != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: palette.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: palette.warning.withValues(alpha: 0.3))),
            child: Row(
              children: [
                Icon(Icons.replay_rounded, size: 14, color: palette.warning),
                const SizedBox(width: 6),
                Expanded(child: Text('Missed: ${recoverySessions.first.title}', style: context.text.labelSmall!.copyWith(color: palette.warning, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                TextButton(
                    onPressed: () => onRecoverSession!(recoverySessions.first),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                    ),
                    child: Text('Recover', style: context.text.labelSmall!.copyWith(color: palette.warning, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // Single early completion strip
        if (hasEarly) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: palette.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: palette.success.withValues(alpha: 0.3))),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: palette.success),
                const SizedBox(width: 6),
                Expanded(child: Text('${earlyCompletion!.freedMinutes}m freed up today!', style: context.text.labelSmall!.copyWith(color: palette.success, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // Current/Next block card (single authoritative NEXT location)
        if (displayBlock != null) ...[
          _NextBlockCard(block: displayBlock, referenceTime: referenceTime),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (sorted.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.event_available_outlined, size: 20, color: palette.onSurfaceMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('No blocks scheduled today. Tap Plan to build your day.', style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted))),
                TextButton(onPressed: () => UniversalActionExecutor.openPlanMyDay(context), child: const Text('Plan Day')),
              ],
            ),
          )
        else if (sorted.length == 1)
          _TodayPlanTile(block: sorted.first, referenceTime: referenceTime)
        else
          // Collapsed upcoming list (progressive disclosure)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${sorted.length} blocks today', style: context.text.labelSmall!.copyWith(color: palette.onSurfaceMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                ...sorted.take(3).map((b) {
                  final title = _blockTitle(b);
                  final time = '${b.startAt.hour.toString().padLeft(2,'0')}:${b.startAt.minute.toString().padLeft(2,'0')}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text('$time · $title', style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        SizedBox(height: 28, child: TextButton(onPressed: () => AppRouter.openPlan(context), child: const Text('View', style: TextStyle(fontSize: 11)))),
                      ],
                    ),
                  );
                }),
                if (sorted.length > 3)
                  TextButton(onPressed: () => AppRouter.openPlan(context), child: Text('View all ${sorted.length} →', style: context.text.labelSmall!.copyWith(color: palette.primary))),
              ],
            ),
          ),
      ],
    );
  }

  String _blockTitle(PlanningBlock block) {
    if (block.taskId != null) {
      try {
        final task = TaskController.instance.tasks.where((t) => t.id == block.taskId).firstOrNull;
        if (task != null) return task.title;
      } catch (_) {}
    }
    if (block.subjectId != null) {
      try {
        final subject = SubjectController.instance.subjectById(block.subjectId!);
        if (subject != null && block.customTitle == null) return subject.displayName;
      } catch (_) {}
    }
    return block.customTitle ?? 'Planned session';
  }
}

class _NextBlockCard extends StatelessWidget {
  const _NextBlockCard({required this.block, required this.referenceTime});
  final PlanningBlock block;
  final DateTime referenceTime;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final status = UniversalActionExecutor.derivePlanningBlockStatus(block, referenceTime: referenceTime, linkedTaskCompleted: block.taskId != null ? (TaskController.instance.tasks.where((t) => t.id == block.taskId).firstOrNull?.isCompleted ?? false) : false);
    final isCurrent = status == PlanningBlockStatus.current;
    final title = _title();
    final time = '${block.startAt.hour.toString().padLeft(2,'0')}:${block.startAt.minute.toString().padLeft(2,'0')} — ${block.endAt.hour.toString().padLeft(2,'0')}:${block.endAt.minute.toString().padLeft(2,'0')}';
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      borderColor: (isCurrent ? palette.success : palette.primary).withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: (isCurrent ? palette.success : palette.primary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)), child: Icon(isCurrent ? Icons.play_circle_filled_rounded : Icons.schedule_rounded, size: 16, color: isCurrent ? palette.success : palette.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((isCurrent ? 'CURRENT · ' : 'NEXT · ') + title, style: context.text.labelSmall!.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$time · ${block.endAt.difference(block.startAt).inMinutes}m', style: context.text.labelSmall!.copyWith(color: palette.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            height: 30,
            child: status == PlanningBlockStatus.missed
                ? AppHitTestArea(
                    child: OutlinedButton(
                        onPressed: () => UniversalActionExecutor.executePlanningBlockAction(context, UniversalBlockAction.recover, block),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: Size.zero),
                        child: const Text('Recover', style: TextStyle(fontSize: 12))))
                : AppHitTestArea(
                    child: ElevatedButton(
                        onPressed: () => AppRouter.startPlanningBlockFocus(context, block),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: Size.zero),
                        child: Text(isCurrent ? 'Continue' : 'Start', style: const TextStyle(fontSize: 12)))),
          ),
        ],
      ),
    );
  }

  String _title() {
    if (block.taskId != null) {
      try {
        final task = TaskController.instance.tasks.where((t) => t.id == block.taskId).firstOrNull;
        if (task != null) return task.title;
      } catch (_) {}
    }
    if (block.subjectId != null) {
      try {
        final s = SubjectController.instance.subjectById(block.subjectId!);
        if (s != null && block.customTitle == null) return s.displayName;
      } catch (_) {}
    }
    return block.customTitle ?? 'Planned session';
  }
}


// ══════════════════════════════════════════════════════════════════════════
// STUDENT LIFE (minimal home entry point)
// ══════════════════════════════════════════════════════════════════════════

class _StudentLifeCard extends StatelessWidget {
  const _StudentLifeCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final controller = StudentLifeController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.isLoaded) {
          return AppCard(
            onTap: () => AppRouter.openStudentLife(context),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.nightlight_round,
                  size: 20,
                  color: palette.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Set your sleep routine',
                    style: context.text.bodySmall?.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: palette.textTertiary,
                ),
              ],
            ),
          );
        }
        final plan = controller.dailyPlan();
        final summary = controller.sleepSummary();
        final bedtimeLabel = StudentLifePreferences.formatClock(
          plan.sleepWindowStart.hour * 60 + plan.sleepWindowStart.minute,
        );
        return AppCard(
          onTap: () => AppRouter.openStudentLife(context),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.nightlight_round, size: 20, color: palette.forest),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Life',
                      style: context.text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.lastNightLabel} slept · bed $bedtimeLabel',
                      style: context.text.bodySmall?.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: palette.textTertiary,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// LOADING SKELETON
// ══════════════════════════════════════════════════════════════════════════

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeletonCard(lines: 3),
        SizedBox(height: AppSpacing.md),
        AppSkeletonCard(lines: 2),
        SizedBox(height: AppSpacing.md),
        AppSkeletonCard(lines: 2),
      ],
    );
  }
}
