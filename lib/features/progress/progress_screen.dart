import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../exams/exam_controller.dart';
import '../study/study_controller.dart';
import '../tasks/task_controller.dart';
import 'progress_controller.dart';
import 'widgets/achievements_section.dart';
import 'widgets/activity_chart.dart';
import 'widgets/early_user_state.dart';
import 'widgets/insights_section.dart';
import 'widgets/milestones_section.dart';
import 'widgets/momentum_hero.dart';
import 'widgets/performance_section.dart';
import 'widgets/progress_base.dart';
import 'widgets/progress_header.dart';
import 'widgets/progression_section.dart';
import 'widgets/range_selector.dart';
import 'widgets/rewards_progress_section.dart';

/// The premium Progress Command Center — the intelligence and reflection layer
/// of the Student OS ecosystem.
///
/// Analytics are derived live from [TaskController] and [StudyController] via
/// [ProgressController]; nothing is duplicated or persisted here. The screen
/// reflects changes from other modules without an app restart.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final ProgressEntranceSequence _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = ProgressEntranceSequence(this);
    TaskController.instance.addListener(_onDataChanged);
    StudyController.instance.addListener(_onDataChanged);
    ProgressController.instance.addListener(_onDataChanged);
    ExamController.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    // Rebuild with new data, but do nothing special: the entrance controller
    // has already finished, so no entrance animation replays. Numbers and bars
    // animate via their own TweenAnimationBuilders.
    setState(() {});
  }

  @override
  void dispose() {
    TaskController.instance.removeListener(_onDataChanged);
    StudyController.instance.removeListener(_onDataChanged);
    ProgressController.instance.removeListener(_onDataChanged);
    ExamController.instance.removeListener(_onDataChanged);
    _entrance.dispose();
    super.dispose();
  }

  void _navigateToPlan() => AppRouter.openPlan(context);
  void _navigateToStudy() => AppRouter.openStudy(context);
  void _navigateToTasks() => AppRouter.openTasks(context);

  @override
  Widget build(BuildContext context) {
    final pc = ProgressController.instance;
    final range = pc.range;
    final snapshot = pc.snapshotFor(range);
    final milestones = pc.milestones();

    // Wire actionable insight kinds to ecosystem navigation.
    final insights = pc.insightsFor(snapshot).map((i) {
      if (i.id == ProgressInsightKind.overdue) {
        return ProgressInsight(
          id: i.id,
          icon: i.icon,
          title: i.title,
          detail: i.detail,
          tint: i.tint,
          onTap: _navigateToTasks,
        );
      }
      return i;
    }).toList();

    final isEarlyUser = !snapshot.hasAnyActivity;

    return AppScaffold(
      title: 'Progress',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProgressEntrance(
              animation: _entrance.header,
              child: ProgressHeader(
                snapshot: snapshot,
                milestones: milestones,
                onPlan: _navigateToPlan,
                onStudy: _navigateToStudy,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ProgressEntrance(
              animation: _entrance.hero,
              child: MomentumHero(
                snapshot: snapshot,
                onTasks: _navigateToTasks,
                onStudy: _navigateToStudy,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ProgressEntrance(
              animation: _entrance.selector,
              child: RangeSelector(range: range, onSelect: pc.selectRange),
            ),
            const SizedBox(height: AppSpacing.xl),
            ProgressEntrance(
              animation: _entrance.chart,
              child: WeeklyActivity(days: snapshot.weeklyDays),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (isEarlyUser)
              ProgressEntrance(
                animation: _entrance.performance,
                child: EarlyUserState(
                  onPlan: _navigateToPlan,
                  onTasks: _navigateToTasks,
                  onStudy: _navigateToStudy,
                ),
              )
            else ...[
              ProgressEntrance(
                animation: _entrance.performance,
                child: PerformanceBreakdown(
                  snapshot: snapshot,
                  onTasks: _navigateToTasks,
                  onStudy: _navigateToStudy,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ProgressEntrance(
                animation: _entrance.insights,
                child: InsightsSection(snapshot: snapshot, insights: insights),
              ),
              const SizedBox(height: AppSpacing.xl),
              ProgressEntrance(
                animation: _entrance.milestones,
                child: MilestonesSection(milestones: milestones),
              ),
              const SizedBox(height: AppSpacing.xl),
              const AchievementsSection(),
              const SizedBox(height: AppSpacing.xl),
              const ProgressionSection(),
              const SizedBox(height: AppSpacing.xl),
              const RewardsProgressSection(),
            ],
          ],
        ),
      ),
    );
  }
}
