import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/assistant/assistant_launch_context.dart';
import '../../../core/constants/app_colors.dart';
import '../../guides/guide_targets.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icon_size.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_completion_check.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../data/models/task.dart';
import '../../exams/exam_controller.dart';
import '../../subjects/subject_controller.dart';
import '../task_controller.dart';
import '../task_recommendation_engine.dart';
import 'task_creation_sheet.dart';
import 'task_detail_screen.dart';

/// Task view modes.
enum _TaskView { today, overdue, upcoming, inbox, all, completed }

/// The premium Tasks Command Center — a workload intelligence interface.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headerAnim;
  late final Animation<double> _smartAnim;
  late final Animation<double> _viewsAnim;
  late final Animation<double> _listAnim;

  _TaskView _currentView = _TaskView.today;
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Deep-links from Subject/Exam workspaces pre-set a scoped filter on the
    // controller; land on the full matching list instead of Today's slice.
    if (TaskController.instance.filter.isScoped) {
      _currentView = _TaskView.all;
    }
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();

    _headerAnim = _stagger(0.00, 0.25);
    _smartAnim = _stagger(0.12, 0.40);
    _viewsAnim = _stagger(0.24, 0.52);
    _listAnim = _stagger(0.36, 0.68);

    TaskController.instance.addListener(_onTasksChanged);
  }

  Animation<double> _stagger(double begin, double end) {
    return _entranceController.drive(
      CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic)),
    );
  }

  void _onTasksChanged() => setState(() {});

  @override
  void dispose() {
    _entranceController.dispose();
    TaskController.instance.removeListener(_onTasksChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StudentTask> get _visibleTasks {
    final tc = TaskController.instance;
    // Every view flows through the controller filter so search, priorities,
    // flags, and subject/exam scope apply consistently (previously only the
    // "All" view respected them and other views silently ignored input).
    return switch (_currentView) {
      _TaskView.today => tc.applyFilter(
        tc.todayTasks +
            tc.overdueTasks.where((t) => !tc.todayTasks.contains(t)).toList(),
      ),
      _TaskView.overdue => tc.applyFilter(tc.overdueTasks),
      _TaskView.upcoming => tc.applyFilter(tc.upcomingTasks),
      _TaskView.inbox => tc.applyFilter(tc.inboxTasks),
      _TaskView.all => tc.filteredTasks,
      _TaskView.completed => tc.applyFilter(tc.completedTasks),
    };
  }

  String get _headerTitle {
    final tc = TaskController.instance;
    final active = tc.activeCount;
    final overdue = tc.overdueTasks.length;
    if (overdue > 0) return '$overdue overdue · $active active';
    if (active == 0 && tc.completedCount == 0) return 'No tasks yet';
    return '$active task${active == 1 ? '' : 's'} in your system';
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskController.instance;
    final recommendations = TaskRecommendationEngine.recommend(tc.tasks);

    return AppScaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _EntranceSection(
              animation: _headerAnim,
              child: _CommandHeader(
                title: 'Tasks',
                subtitle: _headerTitle,
                onAdd: () => _showCreateSheet(context),
                onOrganize: () => AppRouter.openAssistant(
                  context,
                  initialQuery: "What's urgent?",
                  launchContext: const AssistantLaunchContext(
                    origin: AssistantOrigin.tasks,
                  ),
                ),
                onSearch: () {
                  setState(() => _showSearch = !_showSearch);
                  if (!_showSearch) tc.clearSearch();
                },
                showSearch: _showSearch,
                searchCtrl: _searchCtrl,
                onSearchChanged: (q) => tc.search(q),
              ),
            ),
          ),

          // Smart recommendations — hidden while any filter/search/scope is
          // active so the list below shows exactly what was asked for.
          if (recommendations.isNotEmpty &&
              _currentView != _TaskView.completed &&
              tc.filter.isEmpty)
            SliverToBoxAdapter(
              child: _EntranceSection(
                animation: _smartAnim,
                child: _SmartRecommendations(
                  recommendations: recommendations,
                  onTap: (task) => _openTaskDetail(context, task),
                  onQuickComplete: (task) =>
                      TaskController.instance.completeTask(task.id),
                ),
              ),
            ),

          // View selector
          SliverToBoxAdapter(
            child: _EntranceSection(
              animation: _viewsAnim,
              child: _ViewSelector(
                current: _currentView,
                onChanged: (v) => setState(() => _currentView = v),
                counts: _ViewCounts(
                  today: tc.todayTasks.length + tc.overdueTasks.length,
                  overdue: tc.overdueTasks.length,
                  upcoming: tc.upcomingTasks.length,
                  inbox: tc.inboxCount,
                  all: tc.activeCount,
                  completed: tc.completedCount,
                ),
              ),
            ),
          ),

          // Filter indicator
          if (!tc.filter.isEmpty)
            SliverToBoxAdapter(
              child: _FilterIndicator(
                filter: tc.filter,
                onClear: () => tc.clearFilters(),
              ),
            ),

          // Task list
          SliverToBoxAdapter(
            child: _EntranceSection(
              animation: _listAnim,
              child: _TaskListSection(
                tasks: _visibleTasks,
                view: _currentView,
                onTap: (task) => _openTaskDetail(context, task),
                onToggle: (task) {
                  if (task.isCompleted) {
                    tc.reopenTask(task.id);
                  } else {
                    tc.completeTask(task.id);
                  }
                },
                onDelete: (task) => _confirmDelete(context, task),
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskCreationSheet(),
    );
  }

  void _openTaskDetail(BuildContext context, StudentTask task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  void _confirmDelete(BuildContext context, StudentTask task) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete task'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              TaskController.instance.deleteTask(task.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Command Header ────────────────────────────────────────────────────

class _CommandHeader extends StatelessWidget {
  const _CommandHeader({
    required this.title,
    required this.subtitle,
    required this.onAdd,
    this.onOrganize,
    required this.onSearch,
    required this.showSearch,
    required this.searchCtrl,
    required this.onSearchChanged,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final VoidCallback? onOrganize;
  final VoidCallback onSearch;
  final bool showSearch;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop())
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _HeaderAction(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.headlineMedium),
                    const SizedBox(height: 3),
                    Text(subtitle, style: context.text.bodySmall),
                  ],
                ),
              ),
              _HeaderAction(
                icon: showSearch ? Icons.close_rounded : Icons.search_rounded,
                tooltip: showSearch ? 'Close search' : 'Search',
                onTap: onSearch,
              ),
              if (onOrganize != null) ...[
                const SizedBox(width: AppSpacing.xs),
                _HeaderAction(
                  icon: Icons.auto_awesome_rounded,
                  tooltip: 'Organize with Assistant',
                  onTap: onOrganize!,
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              GuideTargetAnchor(
                id: 'tasks.add',
                child: _HeaderAction(
                  icon: Icons.add_rounded,
                  tooltip: 'Add task',
                  onTap: onAdd,
                  primary: true,
                ),
              ),
            ],
          ),
          // Search bar
          AnimatedSize(
            duration: AppDurations.normal,
            curve: Curves.easeOutCubic,
            child: showSearch
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      style: context.text.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: context.text.bodyMedium!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: palette.onSurfaceMuted,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: palette.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                      ),
                      onChanged: onSearchChanged,
                    ),
                  )
                : const SizedBox.shrink(),
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
            color: primary ? palette.onPrimary : palette.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─── Smart Recommendations ─────────────────────────────────────────────

class _SmartRecommendations extends StatelessWidget {
  const _SmartRecommendations({
    required this.recommendations,
    required this.onTap,
    required this.onQuickComplete,
  });

  final List<RecommendedTask> recommendations;
  final ValueChanged<StudentTask> onTap;
  final ValueChanged<StudentTask> onQuickComplete;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Focus now',
            icon: Icons.lightbulb_outline_rounded,
            subtitle: 'Recommended next',
          ),
          const SizedBox(height: AppSpacing.md),
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                onTap: () => onTap(rec.task),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    AppCompletionCheck(
                      completed: false,
                      onTap: () => onQuickComplete(rec.task),
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: rec.task.priority.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.task.title,
                            style: context.text.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            rec.reason,
                            style: context.text.labelSmall!.copyWith(
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: palette.onSurfaceMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── View Selector ─────────────────────────────────────────────────────

class _ViewCounts {
  const _ViewCounts({
    required this.today,
    required this.overdue,
    required this.upcoming,
    required this.inbox,
    required this.all,
    required this.completed,
  });

  final int today;
  final int overdue;
  final int upcoming;
  final int inbox;
  final int all;
  final int completed;
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({
    required this.current,
    required this.onChanged,
    required this.counts,
  });

  final _TaskView current;
  final ValueChanged<_TaskView> onChanged;
  final _ViewCounts counts;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final views = [
      (_TaskView.today, 'Today', counts.today),
      (_TaskView.overdue, 'Overdue', counts.overdue),
      (_TaskView.upcoming, 'Upcoming', counts.upcoming),
      (_TaskView.inbox, 'Inbox', counts.inbox),
      (_TaskView.all, 'All', counts.all),
      (_TaskView.completed, 'Done', counts.completed),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        0,
        0,
      ),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: views.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (_, i) {
            final (view, label, count) = views[i];
            final isSelected = view == current;
            return GestureDetector(
              onTap: () => onChanged(view),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? palette.primary : palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: context.text.labelMedium!.copyWith(
                        color: isSelected
                            ? palette.onPrimary
                            : palette.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : palette.onSurfaceMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: context.text.labelSmall!.copyWith(
                            color: isSelected
                                ? Colors.white
                                : palette.onSurfaceMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Filter indicator ──────────────────────────────────────────────────

class _FilterIndicator extends StatelessWidget {
  const _FilterIndicator({required this.filter, required this.onClear});

  final TaskFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final chips = <String>[];
    if (filter.subjectId != null) {
      final name = SubjectController.instance
          .subjectById(filter.subjectId!)
          ?.name;
      chips.add('Subject: ${name ?? 'Unknown'}');
    }
    if (filter.examId != null) {
      final title = ExamController.instance.exams
          .where((e) => e.id == filter.examId)
          .firstOrNull
          ?.title;
      chips.add('Exam: ${title ?? 'Unknown'}');
    }
    if (filter.priorities.isNotEmpty) {
      chips.add(filter.priorities.map((p) => p.label).join(', '));
    }
    if (filter.isOverdue == true) chips.add('Overdue');
    if (filter.isInbox == true) chips.add('Inbox');
    if (filter.hasSubtasks == true) chips.add('With subtasks');
    if (filter.hasRecurrence == true) chips.add('Recurring');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        0,
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, size: 14, color: palette.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              chips.join(' · '),
              style: context.text.labelSmall!.copyWith(color: palette.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Clear',
              style: context.text.labelSmall!.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Task List Section ─────────────────────────────────────────────────

class _TaskListSection extends StatelessWidget {
  const _TaskListSection({
    required this.tasks,
    required this.view,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final List<StudentTask> tasks;
  final _TaskView view;
  final ValueChanged<StudentTask> onTap;
  final ValueChanged<StudentTask> onToggle;
  final ValueChanged<StudentTask> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    if (tasks.isEmpty) {
      return _EmptyTaskState(view: view);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (view == _TaskView.completed)
            AppSectionHeader(
              title: 'Completed',
              icon: Icons.check_circle_outline_rounded,
              subtitle: '${tasks.length} tasks',
              trailing: Text(
                '${tasks.length}',
                style: context.text.labelMedium!.copyWith(
                  color: palette.success,
                ),
              ),
            ),
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _TaskCard(
                task: task,
                onTap: () => onTap(task),
                onToggle: () => onToggle(task),
                onDelete: () => onDelete(task),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Task Card ─────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final StudentTask task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final isCompleted = task.isCompleted;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Dismissible(
      key: ValueKey(task.id),
      direction: isCompleted
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        onTap: onTap,
        child: Row(
          children: [
            AppCompletionCheck(
              completed: isCompleted,
              onTap: onToggle,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: reduceMotion ? Duration.zero : AppDurations.fast,
                    curve: AppCurves.standard,
                    style: context.text.bodyMedium!.copyWith(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: palette.onSurfaceMuted,
                      color: isCompleted
                          ? palette.onSurfaceMuted
                          : palette.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.description.isNotEmpty && !isCompleted) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  _TaskMetaRow(task: task, isCompleted: isCompleted),
                ],
              ),
            ),
            // Right side indicators
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isCompleted)
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: task.priority.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (task.hasRecurrence)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.repeat_rounded,
                      size: 14,
                      color: palette.onSurfaceMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Task meta row ─────────────────────────────────────────────────────

class _TaskMetaRow extends StatelessWidget {
  const _TaskMetaRow({required this.task, required this.isCompleted});

  final StudentTask task;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subjectName = task.subjectId != null
        ? SubjectController.instance.subjectById(task.subjectId!)?.name
        : null;
    final examTitle = task.examId != null
        ? ExamController.instance.exams
              .where((e) => e.id == task.examId)
              .firstOrNull
              ?.title
        : null;
    final hasMeta =
        task.dueDate != null ||
        task.category.isNotEmpty ||
        task.hasSubtasks ||
        subjectName != null ||
        examTitle != null;

    if (!hasMeta) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          if (task.dueDate != null) ...[
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: task.isOverdue && !isCompleted
                  ? AppColors.error
                  : palette.onSurfaceMuted,
            ),
            const SizedBox(width: 3),
            Text(
              _formatDate(task.dueDate!),
              style: context.text.labelSmall!.copyWith(
                color: task.isOverdue && !isCompleted
                    ? AppColors.error
                    : palette.onSurfaceMuted,
              ),
            ),
          ],
          if (task.hasSubtasks) ...[
            if (task.dueDate != null) const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.checklist_rounded,
              size: 14,
              color: task.allSubtasksComplete
                  ? palette.success
                  : palette.onSurfaceMuted,
            ),
            const SizedBox(width: 3),
            Text(
              '${task.subtasksCompleted}/${task.subtaskCount}',
              style: context.text.labelSmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
          ],
          if (task.category.isNotEmpty) ...[
            if (task.dueDate != null || task.hasSubtasks)
              const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: palette.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.category,
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
            ),
          ],
          if (subjectName != null) ...[
            if (task.dueDate != null ||
                task.hasSubtasks ||
                task.category.isNotEmpty)
              const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.menu_book_outlined,
              size: 14,
              color: palette.onSurfaceMuted,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                subjectName,
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (examTitle != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.school_outlined,
              size: 14,
              color: palette.onSurfaceMuted,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                examTitle,
                style: context.text.labelSmall!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff < 7) return 'In $diff days';
    return '${date.day}/${date.month}';
  }
}

// ─── Empty task state ──────────────────────────────────────────────────

class _EmptyTaskState extends StatelessWidget {
  const _EmptyTaskState({required this.view});

  final _TaskView view;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final (icon, title, subtitle) = switch (view) {
      _TaskView.today => (
        Icons.wb_sunny_outlined,
        'Nothing for today',
        'Enjoy a clear day or add new tasks.',
      ),
      _TaskView.overdue => (
        Icons.warning_amber_rounded,
        'Nothing overdue',
        'Overdue tasks will appear here so nothing slips.',
      ),
      _TaskView.upcoming => (
        Icons.upcoming_rounded,
        'No upcoming tasks',
        'Tasks with future dates appear here.',
      ),
      _TaskView.inbox => (
        Icons.inbox_rounded,
        'Inbox is empty',
        'Quick-capture tasks without dates. Plan them later.',
      ),
      _TaskView.all => (
        Icons.task_alt_rounded,
        'No tasks yet',
        'Create your first task to start building momentum.',
      ),
      _TaskView.completed => (
        Icons.check_circle_outline_rounded,
        'No completed tasks',
        'Complete tasks to see them here.',
      ),
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primaryContainer.withValues(alpha: 0.5),
              ),
              child: Icon(icon, size: AppIconSize.xl, color: palette.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: context.text.bodyMedium!.copyWith(
                color: palette.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
    // FadeTransition + SlideTransition isolate animation; child is static,
    // minimizing per-frame rebuilds. Slide 4% vertical (TCC).
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
