import 'academic_context.dart';

import 'package:meta/meta.dart';

import 'adaptive_priority_engine.dart';

/// Supported available study time options for a student's daily plan.
/// P3: covers 15/30/45/60/90/120/180 plus custom durations (e.g. 45m via parser).
enum AvailableTimeBudget {
  fifteenMinutes(15, '15 min (Micro)'),
  thirtyMinutes(30, '30 min (Quick Burst)'),
  fortyFiveMinutes(45, '45 min (Focus)'),
  oneHour(60, '1 hour (Standard)'),
  ninetyMinutes(90, '90 min (Extended)'),
  twoHours(120, '2 hours (Deep Focus)'),
  threePlusHours(180, '3+ hours (Intensive)');

  const AvailableTimeBudget(this.minutes, this.label);
  final int minutes;
  final String label;

  /// Resolve a budget from an arbitrary minute count (nearest bucket, or custom).
  static AvailableTimeBudget fromMinutes(int minutes) {
    if (minutes <= 15) return fifteenMinutes;
    if (minutes <= 30) return thirtyMinutes;
    if (minutes <= 45) return fortyFiveMinutes;
    if (minutes <= 60) return oneHour;
    if (minutes <= 90) return ninetyMinutes;
    if (minutes <= 120) return twoHours;
    return threePlusHours;
  }

  /// Whether this budget was derived from a custom duration not exactly matching a bucket.
  bool get isCustomDuration => !AvailableTimeBudget.values.any((b) => b.minutes == minutes);
}

/// A structured daily plan fitted to the student's available study time.
@immutable
class TodayPlan {
  const TodayPlan({
    required this.targetBudget,
    required this.plannedMinutes,
    required this.actions,
    required this.deferredActionsCount,
    required this.focusSummary,
    required this.isGentleRecovery,
  });

  final AvailableTimeBudget targetBudget;
  final int plannedMinutes;
  final List<PrioritizedAction> actions;
  final int deferredActionsCount;
  final String focusSummary;
  final bool isGentleRecovery;

  /// Whether the plan contains any actions.
  bool get hasActions => actions.isNotEmpty;
}

/// Generates realistic daily plans constrained by student time budgets.
class TodayPlanEngine {
  const TodayPlanEngine({this.priorityEngine = const AdaptivePriorityEngine()});

  final AdaptivePriorityEngine priorityEngine;

  /// Creates a realistic, non-overwhelming TodayPlan for the given academic context and budget.
  TodayPlan generatePlan({
    required AcademicContext context,
    AvailableTimeBudget budget = AvailableTimeBudget.oneHour,
    bool gentleRecoveryMode = false,
  }) {
    final rankedActions = priorityEngine.derivePrioritizedActions(context);

    final selectedActions = <PrioritizedAction>[];
    int currentAllocatedMinutes = 0;
    final maxMinutes = budget.minutes;

    // In gentle recovery mode, limit to top 2-3 essential tasks to prevent anxiety
    final maxActionsAllowed = gentleRecoveryMode ? 2 : 5;

    for (final action in rankedActions) {
      if (selectedActions.length >= maxActionsAllowed) break;

      // Allow action if it fits or if it's the very first action (so budget is not completely empty)
      if (currentAllocatedMinutes + action.estimatedMinutes <= maxMinutes ||
          selectedActions.isEmpty) {
        selectedActions.add(action);
        currentAllocatedMinutes += action.estimatedMinutes;
      }
    }

    final deferredCount = (rankedActions.length - selectedActions.length).clamp(
      0,
      9999,
    );

    String focusSummary;
    if (selectedActions.isEmpty) {
      focusSummary =
          'All caught up! Take time to rest or explore optional study topics.';
    } else if (gentleRecoveryMode) {
      focusSummary =
          'Gentle recovery focus: Tackling ${selectedActions.length} key priority without burnout.';
    } else {
      final primary = selectedActions.first;
      focusSummary = 'Primary focus: ${primary.title} (${primary.reason}).';
    }

    return TodayPlan(
      targetBudget: budget,
      plannedMinutes: currentAllocatedMinutes,
      actions: selectedActions,
      deferredActionsCount: deferredCount,
      focusSummary: focusSummary,
      isGentleRecovery: gentleRecoveryMode,
    );
  }
}
