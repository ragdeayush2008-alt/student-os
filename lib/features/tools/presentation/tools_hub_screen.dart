import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/assistant/assistant_launch_context.dart';
import '../../../core/animations/animated_entrance.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/intelligence/academic_intelligence_controller.dart';
import '../../../core/intelligence/academic_intelligence_engine.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/student_os_action_cards.dart';
import '../../../core/widgets/student_os_assistant_visual.dart';
import '../../../core/widgets/student_os_page_header.dart';
import '../../../features/guides/guide_targets.dart';
import '../../calendar/academic_schedule_controller.dart';
import '../../checklist/checklist_controller.dart';
import '../../exams/exam_controller.dart';
import '../../focus/controller/focus_controller.dart';
import '../../focus/presentation/screens/focus_guard_settings_screen.dart';
import '../../habits/habit_controller.dart';
import '../../knowledge/academic_knowledge_controller.dart';
import '../../knowledge/topic_practice_controller.dart';
import '../../notes/student_note_controller.dart';
import '../../notifications/notification_controller.dart';
import '../../resources/resource_controller.dart';
import '../../revision/revision_controller.dart';
import '../../study/study_controller.dart';
import '../../subjects/subject_controller.dart';
import '../../tasks/task_controller.dart';
import '../../sleep/sleep_controller.dart';

/// Categories for organizing secondary tools within the Tools Hub.
enum ToolCategory {
  all('All', Icons.apps_rounded),
  intelligence('Student OS AI', Icons.psychology_rounded),
  knowledge('Knowledge & Notes', Icons.menu_book_rounded),
  practice('Academic & Practice', Icons.quiz_rounded),
  schedule('Schedule & Tasks', Icons.calendar_today_rounded),
  focus('Focus & Wellbeing', Icons.timer_rounded),
  utilities('Academic Utilities', Icons.calculate_rounded),
  settings('Settings & Account', Icons.tune_rounded);

  const ToolCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// A structured tool entry in the Tools Hub.
class ToolItem {
  const ToolItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.tags,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.accentColor,
    this.isInteractive = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final ToolCategory category;
  final List<String> tags;
  final void Function(BuildContext context) onTap;
  final String? badge;
  final Color? badgeColor;
  final Color? accentColor;
  final bool isInteractive;
}

/// Tools 2.0 — The Comprehensive Utility & Secondary Feature Hub for Student OS.
///
/// Top: Primary Six Tools (Icon-First layout):
/// 1. Quick Notes
/// 2. Calculator
/// 3. Wellness
/// 4. Checklist
/// 5. Habits
/// 6. Distraction Box
///
/// Below: Secondary tools & utilities organized into sensible categories.
class ToolsHubScreen extends StatefulWidget {
  const ToolsHubScreen({super.key});

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  ToolCategory _selectedCategory = ToolCategory.all;
  String _searchQuery = '';
  int _selectedAllocatedMinutes = 60;

  // Focus tick filter: Tools only shows an unresolved-distraction badge, a
  // value that changes on capture/handle events, not on the 1s ticker.
  int _lastUnresolvedDistractions = -1;

  @override
  void initState() {
    super.initState();
    _lastUnresolvedDistractions =
        FocusController.instance.unresolvedDistractions.length;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });

    TaskController.instance.addListener(_onDataChanged);
    AcademicKnowledgeController.instance.addListener(_onDataChanged);
    ResourceController.instance.addListener(_onDataChanged);
    NotificationController.instance.addListener(_onDataChanged);
    StreakService.instance.addListener(_onDataChanged);
    RevisionController.instance.addListener(_onDataChanged);
    TopicPracticeController.instance.addListener(_onDataChanged);
    FocusController.instance.addListener(_onDataChanged);
    AcademicScheduleController.instance.addListener(_onDataChanged);
    ExamController.instance.addListener(_onDataChanged);
    SubjectController.instance.addListener(_onDataChanged);
    AcademicIntelligenceController.instance.addListener(_onDataChanged);
    StudyController.instance.addListener(_onDataChanged);
    StudentNoteController.instance.addListener(_onDataChanged);
    ChecklistController.instance.addListener(_onDataChanged);
    HabitController.instance.addListener(_onDataChanged);
    SleepController.instance.addListener(_onDataChanged);
    FocusController.instance.addListener(_onFocusDataChanged);
  }

  void _onFocusDataChanged() {
    final count = FocusController.instance.unresolvedDistractions.length;
    if (count == _lastUnresolvedDistractions) return;
    _lastUnresolvedDistractions = count;
    _onDataChanged();
  }

  void _onDataChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    TaskController.instance.removeListener(_onDataChanged);
    AcademicKnowledgeController.instance.removeListener(_onDataChanged);
    ResourceController.instance.removeListener(_onDataChanged);
    NotificationController.instance.removeListener(_onDataChanged);
    StreakService.instance.removeListener(_onDataChanged);
    RevisionController.instance.removeListener(_onDataChanged);
    TopicPracticeController.instance.removeListener(_onDataChanged);
    FocusController.instance.removeListener(_onDataChanged);
    AcademicScheduleController.instance.removeListener(_onDataChanged);
    ExamController.instance.removeListener(_onDataChanged);
    SubjectController.instance.removeListener(_onDataChanged);
    AcademicIntelligenceController.instance.removeListener(_onDataChanged);
    StudyController.instance.removeListener(_onDataChanged);
    StudentNoteController.instance.removeListener(_onDataChanged);
    ChecklistController.instance.removeListener(_onDataChanged);
    HabitController.instance.removeListener(_onDataChanged);
    SleepController.instance.removeListener(_onDataChanged);
    FocusController.instance.removeListener(_onFocusDataChanged);
    super.dispose();
  }

  /// Live badge for the Sleep entry: planned duration when a schedule is
  /// active, null otherwise.
  String? _sleepBadge() {
    final schedule = SleepController.instance.schedule;
    if (schedule == null || !schedule.enabled) return null;
    return '${schedule.durationLabel} planned';
  }

  List<ToolItem> _buildSecondaryTools(BuildContext context) {    final palette = AppTheme.colorsOf(context);
    final tc = TaskController.instance;
    final nc = NotificationController.instance;
    final resc = ResourceController.instance;
    final cal = AcademicScheduleController.instance;

    final overdueCount = tc.overdueTasks.length;
    final todayTaskCount = tc.todayTasks.length;
    final unreadNotifs = nc.unreadCount;
    final resourceCount = resc.resources.length;
    final todayEventCount = cal.eventsForDay(DateTime.now()).length;

    return [
      // ── Student OS AI: ONE unified Assistant, featured as the hero card
      // above (not a list row). The Command Center screen is canonical;
      // the quick-ask sheet (same controller, conversation and actions)
      // remains for contextual entry points.
      ToolItem(
        id: 'student_os_pro',
        title: 'Student OS Pro',
        subtitle: 'Advanced intelligence, focus modes & analytics',
        icon: Icons.workspace_premium_rounded,
        category: ToolCategory.intelligence,
        tags: ['pro', 'premium', 'membership', 'upgrade', 'subscription', 'paywall'],
        badge: 'PRO',
        onTap: (ctx) => AppRouter.openPremiumPage(ctx),
      ),
      ToolItem(
        id: 'resource_search',
        title: 'Search Student OS',
        subtitle: 'Search across all tagged materials, notes & links',
        icon: Icons.search_rounded,
        category: ToolCategory.intelligence,
        tags: ['search', 'find', 'query', 'filter', 'lookup', 'resources'],
        onTap: (ctx) => AppRouter.openResourceSearch(ctx),
      ),

      // ── Knowledge & Resources ──
      ToolItem(
        id: 'resources',
        title: 'Study Resources Library',
        subtitle: 'Documents, textbooks, links & attachments library',
        icon: Icons.folder_copy_outlined,
        category: ToolCategory.knowledge,
        tags: ['resources', 'files', 'links', 'materials', 'library', 'attachments', 'docs'],
        badge: resourceCount > 0 ? '$resourceCount files' : null,
        onTap: (ctx) => AppRouter.openResources(ctx),
      ),
      ToolItem(
        id: 'note_editor',
        title: 'Markdown Note Editor',
        subtitle: 'Write full markdown notes linked to topics and subjects',
        icon: Icons.note_alt_outlined,
        category: ToolCategory.knowledge,
        tags: ['notes', 'editor', 'markdown', 'write', 'summary', 'revision note'],
        onTap: (ctx) => AppRouter.openNoteEditor(ctx),
      ),

      // ── Schedule & Tasks ──
      ToolItem(
        id: 'academic_calendar',
        title: 'Academic Calendar',
        subtitle: 'Classes, lecture timetables & fixed commitments',
        icon: Icons.calendar_month_rounded,
        category: ToolCategory.schedule,
        tags: ['calendar', 'schedule', 'timetable', 'classes', 'lectures', 'events', 'commitments'],
        badge: todayEventCount > 0 ? '$todayEventCount today' : null,
        onTap: (ctx) => AppRouter.openCalendar(ctx),
      ),
      ToolItem(
        id: 'tasks_list',
        title: 'Academic Tasks & Deliverables',
        subtitle: 'Prioritized assignments, due dates & academic deliverables',
        icon: Icons.assignment_outlined,
        category: ToolCategory.schedule,
        tags: ['tasks', 'assignments', 'deliverables', 'homework', 'projects'],
        badge: overdueCount > 0
            ? '$overdueCount overdue'
            : (todayTaskCount > 0 ? '$todayTaskCount today' : null),
        badgeColor: overdueCount > 0 ? palette.error : null,
        onTap: (ctx) => AppRouter.openTasks(ctx),
      ),
      ToolItem(
        id: 'notifications',
        title: 'Activity & Notifications',
        subtitle: 'Reminders, deadline alerts & system notifications',
        icon: Icons.notifications_outlined,
        category: ToolCategory.schedule,
        tags: ['notifications', 'alerts', 'reminders', 'inbox', 'activity', 'messages'],
        badge: unreadNotifs > 0 ? '$unreadNotifs new' : null,
        badgeColor: unreadNotifs > 0 ? palette.primary : null,
        onTap: (ctx) => AppRouter.openNotifications(ctx),
      ),
      ToolItem(
        id: 'sleep_schedule',
        title: 'Sleep Schedule',
        subtitle: 'Planned bedtime & wake window for smarter planning',
        icon: Icons.bedtime_rounded,
        category: ToolCategory.schedule,
        tags: ['sleep', 'bedtime', 'wake', 'schedule', 'rest', 'routine', 'night'],
        badge: _sleepBadge(),
        onTap: (ctx) => AppRouter.openSleepSchedule(ctx),
      ),

      // ── Academic & Practice ──
      ToolItem(
        id: 'practice_center',
        title: 'Practice Center',
        subtitle: 'Self-assessment questions & active recall tracking',
        icon: Icons.quiz_rounded,
        category: ToolCategory.practice,
        tags: ['practice', 'questions', 'mcq', 'test', 'quiz', 'accuracy', 'self-test'],
        onTap: (ctx) => AppRouter.openPracticeCenter(ctx),
      ),
      ToolItem(
        id: 'analytics',
        title: 'Academic Analytics',
        subtitle: 'Study hours, task completion rate & consistency trends',
        icon: Icons.insights_rounded,
        category: ToolCategory.practice,
        tags: ['analytics', 'stats', 'trends', 'insights', 'performance', 'charts', 'report'],
        onTap: (ctx) => AppRouter.openAnalytics(ctx),
      ),
      ToolItem(
        id: 'study_budgeter',
        title: 'Study Time Budgeter',
        subtitle: 'Calculate optimal subject breakdown for any available time',
        icon: Icons.schedule_rounded,
        category: ToolCategory.utilities,
        tags: ['calculator', 'budget', 'allocator', 'time', 'split', 'planner'],
        isInteractive: true,
        onTap: (ctx) => _showStudyBudgetDialog(ctx),
      ),
      ToolItem(
        id: 'exam_readiness_calculator',
        title: 'Exam Preparation Breakdown',
        subtitle: 'Calculate daily topic pacing and readiness for upcoming exams',
        icon: Icons.calculate_outlined,
        category: ToolCategory.utilities,
        tags: ['calculator', 'exam', 'readiness', 'pace', 'estimator', 'countdown'],
        isInteractive: true,
        onTap: (ctx) => _showExamPacingDialog(ctx),
      ),

      // ── Focus & Wellbeing ──
      ToolItem(
        id: 'focus_center',
        title: 'Focus Center & Timer',
        subtitle: 'Timer, stopwatch & structured focus missions',
        icon: Icons.timer_outlined,
        category: ToolCategory.focus,
        tags: ['focus', 'timer', 'stopwatch', 'pomodoro', 'deep work', 'session'],
        onTap: (ctx) => AppRouter.openFocusCenter(ctx),
      ),
      ToolItem(
        id: 'focus_guard',
        title: 'Focus Guard & App Blocking',
        subtitle: 'Block distracting applications during study sessions',
        icon: Icons.shield_outlined,
        category: ToolCategory.focus,
        tags: ['guard', 'block', 'distraction', 'apps', 'screen time', 'wellbeing', 'restrict'],
        onTap: (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute<void>(
              builder: (_) => const FocusGuardSettingsScreen(),
            ),
          );
        },
      ),
      ToolItem(
        id: 'focus_insights',
        title: 'Focus Insights & Patterns',
        subtitle: 'Deep work duration, peak productivity times & analysis',
        icon: Icons.psychology_outlined,
        category: ToolCategory.focus,
        tags: ['focus insights', 'focus score', 'patterns', 'productivity', 'habits'],
        onTap: (ctx) => AppRouter.openFocusInsights(ctx),
      ),

      // ── Settings & Account ──
      ToolItem(
        id: 'settings',
        title: 'App Settings',
        subtitle: 'Appearance, themes, reminders & preferences',
        icon: Icons.settings_outlined,
        category: ToolCategory.settings,
        tags: ['settings', 'theme', 'dark mode', 'reminders', 'appearance', 'preferences'],
        onTap: (ctx) => AppRouter.openSettings(ctx),
      ),
      ToolItem(
        id: 'account_data',
        title: 'Account, Cloud & Sync',
        subtitle: 'Local-first status, Supabase cloud sync & data isolation',
        icon: Icons.cloud_sync_outlined,
        category: ToolCategory.settings,
        tags: ['account', 'cloud', 'sync', 'backup', 'data', 'supabase', 'login'],
        onTap: (ctx) => AppRouter.openAccountData(ctx),
      ),
      ToolItem(
        id: 'profile',
        title: 'Student Profile',
        subtitle: 'Curriculum, grade level, institution & academic focus',
        icon: Icons.person_outline_rounded,
        category: ToolCategory.settings,
        tags: ['profile', 'user', 'education', 'institution', 'curriculum', 'grade'],
        onTap: (ctx) => AppRouter.openProfile(ctx),
      ),
      ToolItem(
        id: 'home_widgets',
        title: 'Home-Screen Widgets',
        subtitle: 'Exam countdown, tasks, focus and more on your home screen',
        icon: Icons.widgets_rounded,
        category: ToolCategory.settings,
        tags: ['widgets', 'home screen', 'glance', 'countdown', 'android', 'ios'],
        onTap: (ctx) => AppRouter.openWidgets(ctx),
      ),
    ];
  }

  void _showStudyBudgetDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudyBudgetSheet(
        initialMinutes: _selectedAllocatedMinutes,
        onMinutesChanged: (m) => setState(() => _selectedAllocatedMinutes = m),
      ),
    );
  }

  void _showExamPacingDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ExamPacingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final secondaryTools = _buildSecondaryTools(context);

    // Primary Six badges
    final notesCount = StudentNoteController.instance.allActiveNotes.length;
    final pendingChecklist = ChecklistController.instance.pendingCount;
    final activeHabits = HabitController.instance.activeHabits.length;
    final pendingDistractions = FocusController.instance.unresolvedDistractions.length;

    // Filter secondary tools by search and category
    final filteredSecondary = secondaryTools.where((t) {
      if (_selectedCategory != ToolCategory.all && t.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;

      final titleMatch = t.title.toLowerCase().contains(_searchQuery);
      final subtitleMatch = t.subtitle.toLowerCase().contains(_searchQuery);
      final tagMatch = t.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      return titleMatch || subtitleMatch || tagMatch;
    }).toList();

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
                // ── Canonical sibling header: same DNA as Home/Plan/Workspace ──
                const AnimatedEntrance(
                  child: StudentOSPageHeader(
                    eyebrow: 'Student OS toolbox',
                    title: 'Tools Hub',
                    subtitle:
                        'Quick utilities and everything else, organized.',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
            // ── Search & Fast Filter Bar ──
            AnimatedEntrance(
              child: _SearchBar(
                controller: _searchCtrl,
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── ASSISTANT HERO (canonical entry, visually prominent) ──
            AnimatedEntrance(
              child: GuideTargetAnchor(
                id: 'tools.assistant',
                child: _AssistantHeroCard(palette: palette),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── PRIMARY SIX TOOLS (ICON-FIRST LAYOUT) ──
            if (_searchQuery.isEmpty) ...[
              AppSectionHeader(
                title: 'Quick Utilities',
                icon: Icons.stars_rounded,
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedEntrance(
                child: GuideTargetAnchor(
                  id: 'tools.primary',
                  child: _PrimarySixGrid(
                    notesCount: notesCount,
                    pendingChecklist: pendingChecklist,
                    activeHabits: activeHabits,
                    pendingDistractions: pendingDistractions,
                    palette: palette,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Category Filter Pills ──
            AnimatedEntrance(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final cat in ToolCategory.values) ...[
                      _CategoryChip(
                        category: cat,
                        isSelected: _selectedCategory == cat,
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Secondary Tools Content ──
            if (filteredSecondary.isEmpty) ...[
              AnimatedEntrance(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: palette.onSurfaceMuted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No matching tools found',
                          style: context.text.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Try a different search keyword or category filter.',
                          style: context.text.bodySmall!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = ToolCategory.all;
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else if (_selectedCategory == ToolCategory.all && _searchQuery.isEmpty) ...[
              // Categorized sections
              for (final cat in ToolCategory.values.where((c) => c != ToolCategory.all)) ...[
                _buildCategoryGroup(cat, filteredSecondary, palette),
              ],
            ] else ...[
              // Filtered list
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int i = 0; i < filteredSecondary.length; i++) ...[
                      _ToolListTile(tool: filteredSecondary[i]),
                      if (i < filteredSecondary.length - 1)
                        Divider(
                          height: 1,
                          indent: 52,
                          color: palette.outline.withValues(alpha: 0.3),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Offline & Privacy Reassurance ──
            Center(
              child: Text(
                'Tools operate offline-first with local user-scoped storage.',
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGroup(ToolCategory cat, List<ToolItem> allFiltered, AppPalette palette) {
    final catTools = allFiltered.where((t) => t.category == cat).toList();
    if (catTools.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: cat.label, icon: cat.icon),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < catTools.length; i++) ...[
                _ToolListTile(tool: catTools[i]),
                if (i < catTools.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: palette.outline.withValues(alpha: 0.3),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ASSISTANT HERO — deep forest feature card opening the canonical
// Assistant command center (same controller/state as every entry point).
// ══════════════════════════════════════════════════════════════════════════

class _AssistantHeroCard extends StatelessWidget {
  const _AssistantHeroCard({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    // Canonical Assistant identity (hero emphasis) — same visual as Home.
    return StudentOSAssistantEntryCard(
      hero: true,
      onTap: () => AppRouter.openAssistantCommandCenter(
            context,
            launchContext:
                const AssistantLaunchContext(origin: AssistantOrigin.tools),
          ),
      title: 'Student OS Assistant',
      subtitle: 'Plan, study, focus — ask anything.',
      status: StudentOSAssistantStatus.ready,
      statusLabel: 'ASK',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PRIMARY SIX TOOLS — ICON-FIRST GRID (3x2)
// ══════════════════════════════════════════════════════════════════════════

class _PrimarySixGrid extends StatelessWidget {
  const _PrimarySixGrid({
    required this.notesCount,
    required this.pendingChecklist,
    required this.activeHabits,
    required this.pendingDistractions,
    required this.palette,
  });

  final int notesCount;
  final int pendingChecklist;
  final int activeHabits;
  final int pendingDistractions;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Quick Notes | Calculator | Wellness
        Row(
          children: [
            Expanded(
              child: _PrimaryToolIconTile(
                title: 'Quick Notes',
                icon: Icons.note_alt_rounded,
                accentColor: palette.primary,
                badge: notesCount > 0 ? '$notesCount' : null,
                onTap: () => AppRouter.openQuickNotes(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PrimaryToolIconTile(
                title: 'Calculator',
                icon: Icons.calculate_rounded,
                accentColor: palette.info,
                onTap: () => AppRouter.openCalculator(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PrimaryToolIconTile(
                title: 'Wellness',
                icon: Icons.spa_rounded,
                accentColor: palette.success,
                onTap: () => AppRouter.openWellness(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Row 2: Checklist | Habits | Distraction Box
        Row(
          children: [
            Expanded(
              child: _PrimaryToolIconTile(
                title: 'Checklist',
                icon: Icons.checklist_rounded,
                accentColor: palette.warning,
                badge: pendingChecklist > 0 ? '$pendingChecklist' : null,
                onTap: () => AppRouter.openChecklist(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PrimaryToolIconTile(
                title: 'Habits',
                icon: Icons.local_fire_department_rounded,
                accentColor: palette.streak,
                badge: activeHabits > 0 ? '$activeHabits' : null,
                onTap: () => AppRouter.openHabits(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PrimaryToolIconTile(
                title: 'Distraction',
                icon: Icons.inbox_rounded,
                accentColor: palette.onSurface,
                badge: pendingDistractions > 0 ? '$pendingDistractions' : null,
                badgeColor: palette.error,
                onTap: () => AppRouter.openDistractionBox(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryToolIconTile extends StatelessWidget {
  const _PrimaryToolIconTile({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      button: true,
      child: StudentOSHoverLift(
        onTap: onTap,
        lift: 2,
        semanticLabel: title,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    StudentOSIconTreatment(
                      icon: icon,
                      color: accentColor,
                      size: 46,
                      iconSize: 22,
                    ),
                    if (badge != null)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                          decoration: BoxDecoration(
                            color: badgeColor ?? accentColor,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: context.text.labelSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SEARCH BAR WIDGET
// ══════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: palette.outline.withValues(alpha: 0.4),
        ),
      ),
      child: TextField(
        controller: controller,
        style: context.text.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search tools, notes, calculators, assistant...',
          hintStyle: context.text.bodySmall!.copyWith(
            color: palette.onSurfaceMuted,
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: palette.onSurfaceMuted),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CATEGORY CHIP WIDGET
// ══════════════════════════════════════════════════════════════════════════

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ToolCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.primary.withValues(alpha: 0.15)
              : palette.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? palette.primary.withValues(alpha: 0.6)
                : palette.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 14,
              color: isSelected ? palette.primary : palette.onSurfaceMuted,
            ),
            const SizedBox(width: 4),
            Text(
              category.label,
              style: context.text.labelSmall!.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? palette.primary : palette.onSurface,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// TOOL LIST TILE WIDGET
// ══════════════════════════════════════════════════════════════════════════

class _ToolListTile extends StatelessWidget {
  const _ToolListTile({required this.tool});

  final ToolItem tool;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return InkWell(
      onTap: () => tool.onTap(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 11,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (tool.accentColor ?? palette.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Icon(
                  tool.icon,
                  size: 18,
                  color: tool.accentColor ?? palette.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tool.title,
                          style: context.text.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tool.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (tool.badgeColor ?? palette.primary).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            tool.badge!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: tool.badgeColor ?? palette.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tool.subtitle,
                    style: context.text.labelSmall!.copyWith(
                      color: palette.onSurfaceMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.onSurfaceMuted.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// INTERACTIVE STUDY TIME BUDGET SHEET
// ══════════════════════════════════════════════════════════════════════════

class _StudyBudgetSheet extends StatefulWidget {
  const _StudyBudgetSheet({
    required this.initialMinutes,
    required this.onMinutesChanged,
  });

  final int initialMinutes;
  final ValueChanged<int> onMinutesChanged;

  @override
  State<_StudyBudgetSheet> createState() => _StudyBudgetSheetState();
}

class _StudyBudgetSheetState extends State<_StudyBudgetSheet> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subjects = SubjectController.instance.activeSubjects;
    final exams = ExamController.instance.upcomingExams;
    final sessions = StudyController.instance.sessions;
    final tasks = TaskController.instance.tasks;

    final allocation = AcademicIntelligenceEngine.allocateStudyTime(
      availableMinutes: _minutes,
      subjects: subjects,
      exams: exams,
      sessions: sessions,
      tasks: tasks,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: palette.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Study Time Budgeter', style: context.text.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Optimized subject distribution for your available time',
                        style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Time Today:', style: context.text.bodyMedium),
                Row(
                  children: [
                    for (final mins in [30, 60, 90, 120, 180]) ...[
                      InkWell(
                        onTap: () {
                          setState(() => _minutes = mins);
                          widget.onMinutesChanged(mins);
                        },
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: _minutes == mins
                                ? palette.primary
                                : palette.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${mins}m',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _minutes == mins ? palette.onPrimary : palette.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (allocation.studyBlocks.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'Add subjects to see tailored study time allocations.',
                          style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
                        ),
                      ),
                    ),
                  ] else ...[
                    for (final item in allocation.studyBlocks) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: palette.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.durationMinutes}m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: palette.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.subjectName,
                                    style: context.text.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    item.reason,
                                    style: context.text.labelSmall!.copyWith(
                                      color: palette.onSurfaceMuted,
                                      fontSize: 10.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                              tooltip: 'Focus on ${item.subjectName}',
                              onPressed: () {
                                Navigator.of(context).pop();
                                AppRouter.openFocusModeSelection(
                                  context,
                                  subjectId: item.subjectId,
                                  subjectName: item.subjectName,
                                  suggestedDuration: Duration(minutes: item.durationMinutes),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// EXAM PACING & READINESS BREAKDOWN SHEET
// ══════════════════════════════════════════════════════════════════════════

class _ExamPacingSheet extends StatelessWidget {
  const _ExamPacingSheet();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final upcomingExams = ExamController.instance.upcomingExams;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: palette.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exam Readiness & Pacing', style: context.text.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Target completion breakdown for upcoming exams',
                        style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (upcomingExams.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(
                        child: Text(
                          'No upcoming exams scheduled.',
                          style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
                        ),
                      ),
                    ),
                  ] else ...[
                    for (final exam in upcomingExams) ...[
                      _ExamPacingTile(exam: exam),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamPacingTile extends StatelessWidget {
  const _ExamPacingTile({required this.exam});

  final dynamic exam;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final days = exam.daysUntilExam ?? 0;
    final total = exam.syllabusTotal;
    final completed = exam.syllabusCompleted;
    final remaining = exam.syllabusRemaining;
    final fraction = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    final double topicsPerDay = days > 0 ? (remaining / days) : remaining.toDouble();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exam.title,
                  style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: days <= 3 ? palette.error.withValues(alpha: 0.15) : palette.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  days == 0 ? 'Today' : (days == 1 ? 'Tomorrow' : 'In $days days'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: days <= 3 ? palette.error : palette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${exam.subject} · $completed of $total topics completed (${(fraction * 100).round()}%)',
            style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted, fontSize: 11),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: palette.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                fraction >= 0.8 ? palette.success : (fraction >= 0.5 ? palette.primary : palette.warning),
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining > 0
                ? (days > 0
                    ? 'Target pace: ~${topicsPerDay.toStringAsFixed(1)} topic(s) per day to finish syllabus.'
                    : '$remaining topic(s) remaining for today!')
                : 'Syllabus 100% complete! Review and practice.',
            style: context.text.labelSmall!.copyWith(
              color: palette.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
