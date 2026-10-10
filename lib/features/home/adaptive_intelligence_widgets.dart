import 'package:flutter/material.dart' hide PrioritizedAction;

import '../../app/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/intelligence/adaptive_priority_engine.dart';
import '../../core/intelligence/student_os_intelligence_engine.dart';
import '../../core/intelligence/today_plan_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_section_header.dart';
import '../preferences/user_preferences_controller.dart';

/// Next Best Action Hero Card for the Home Dashboard.
class NextBestActionCard extends StatelessWidget {
  const NextBestActionCard({super.key, required this.action});

  final PrioritizedAction? action;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    if (action == null) {
      return AppCard(
        color: palette.surface,
        borderColor: palette.outline,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Caught Up!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: palette.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No urgent tasks or exam topics pending. Great time for a quick study session or rest.',
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final act = action!;
    IconData actionIcon;

    switch (act.type) {
      case AcademicActionType.examPreparation:
        actionIcon = Icons.school_rounded;
        break;
      case AcademicActionType.completeTask:
        actionIcon = Icons.assignment_late_rounded;
        break;
      case AcademicActionType.studySession:
        actionIcon = Icons.timer_outlined;
        break;
      case AcademicActionType.syllabusRevision:
        actionIcon = Icons.menu_book_rounded;
        break;
      case AcademicActionType.backlogRecovery:
        actionIcon = Icons.restart_alt_rounded;
        break;
    }

    // Light canonical treatment: the same AppCard family as every Home and
    // Setup card. Emphasis comes from the forest CTA + tonal pill, never a
    // dark fill. Navigation behavior unchanged.
    void openTarget() {
      if (act.taskId != null) {
        AppRouter.openTaskDetail(context, act.taskId!);
      } else if (act.examId != null) {
        AppRouter.openExamDetail(context, act.examId!);
      } else {
        AppRouter.openStudy(context);
      }
    }

    return AppCard(
      borderColor: palette.primary.withValues(alpha: 0.30),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(actionIcon, size: 13, color: palette.primary),
                    const SizedBox(width: 6),
                    Text(
                      'READY FOR YOUR NEXT MOVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '~${act.estimatedMinutes}m',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: palette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            act.title,
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: palette.onSurface,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            act.reason,
            style: context.text.bodySmall?.copyWith(
              color: palette.onSurfaceMuted,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: openTarget,
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
              label: const Text('START NOW'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adaptive TodayPlanSection for Home/Study Dashboard.
class TodayPlanSection extends StatelessWidget {
  const TodayPlanSection({
    super.key,
    required this.plan,
    required this.selectedBudget,
    required this.isGentleRecovery,
    required this.onBudgetChanged,
    required this.onToggleGentleRecovery,
  }) : super();

  final TodayPlan plan;
  final AvailableTimeBudget selectedBudget;
  final bool isGentleRecovery;
  final ValueChanged<AvailableTimeBudget> onBudgetChanged;
  final ValueChanged<bool> onToggleGentleRecovery;

  @override
  Widget build(BuildContext context) {
    return _TodayStudyPlanSection(
      plan: plan,
      selectedBudget: selectedBudget,
      isGentleRecovery: isGentleRecovery,
      onBudgetChanged: onBudgetChanged,
      onToggleGentleRecovery: onToggleGentleRecovery,
    );
  }
}

/// Actual content implemented to be re-usable.
class _TodayStudyPlanSection extends StatelessWidget {
  const _TodayStudyPlanSection({
    required this.plan,
    required this.selectedBudget,
    required this.isGentleRecovery,
    required this.onBudgetChanged,
    required this.onToggleGentleRecovery,
  });

  final TodayPlan plan;
  final AvailableTimeBudget selectedBudget;
  final bool isGentleRecovery;
  final ValueChanged<AvailableTimeBudget> onBudgetChanged;
  final ValueChanged<bool> onToggleGentleRecovery;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: const AppSectionHeader(
                title: "Today's Realistic Plan",
                subtitle: 'Fitted to your available study time',
              ),
            ),
            IconButton(
              tooltip: isGentleRecovery
                  ? 'Disable Gentle Recovery'
                  : 'Enable Gentle Recovery',
              onPressed: () => onToggleGentleRecovery(!isGentleRecovery),
              icon: Icon(
                isGentleRecovery ? Icons.spa_rounded : Icons.spa_outlined,
                color: isGentleRecovery
                    ? AppColors.success
                    : palette.onSurfaceMuted,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Time budget selector chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AvailableTimeBudget.values.map((budget) {
              final isSelected = budget == selectedBudget;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(
                    budget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: isSelected ? Colors.white : palette.onSurfaceMuted,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: palette.surface,
                  onSelected: (_) => onBudgetChanged(budget),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Budget usage visualization
        if (plan.hasActions) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${plan.plannedMinutes} min / ${selectedBudget.minutes} min planned',
                style: TextStyle(fontSize: 11, color: palette.onSurfaceMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (plan.plannedMinutes / selectedBudget.minutes).clamp(
                0.0,
                1.0,
              ),
              minHeight: 4,
              backgroundColor: palette.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (isGentleRecovery)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.spa_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gentle Recovery active: Focusing strictly on 2 high-impact items.',
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        if (!plan.hasActions)
          AppCard(
            color: palette.surface,
            borderColor: palette.outline,
            child: Text(
              plan.focusSummary,
              style: TextStyle(fontSize: 13, color: palette.onSurfaceMuted),
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plan.actions.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final action = plan.actions[index];
              return AppCard(
                color: palette.surface,
                borderColor: palette.outline,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action.reason,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.onSurfaceMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${action.estimatedMinutes}m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (plan.deferredActionsCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, left: 4),
              child: Text(
                '+ ${plan.deferredActionsCount} more items deferred to preserve focus and avoid overload.',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.onSurfaceMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// STUDENT OS INTELLIGENCE HERO CARD — Step 3 Central Intelligence
// ══════════════════════════════════════════════════════════════════════════

class StudentOSCard extends StatelessWidget {
  const StudentOSCard({
    super.key,
    required this.action,
    required this.onExecuteAction,
    required this.onThirtyMinBurst,
    required this.onToggleDoneToday,
    this.isDoneForToday = false,
    this.isStartMyDay = false,
    this.isContinueMyDay = false,
    /// Subtle contextual hint (overloaded / recovery) rendered as plain text.
    /// Never contains primary CTA words so the authoritative Today card keeps
    /// the single Rebalance / Recover surface (no duplicate warnings).
    this.dayHint,
  });

  final StudentOSAction action;
  final ValueChanged<StudentOSAction> onExecuteAction;
  final VoidCallback onThirtyMinBurst;
  final ValueChanged<bool> onToggleDoneToday;
  final bool isDoneForToday;
  final bool isStartMyDay;
  final bool isContinueMyDay;
  final String? dayHint;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final act = action;
    final autopilotMode = UserPreferencesController.instance.autopilotMode;

    Color badgeColor;
    IconData actionIcon;

    switch (act.type) {
      case StudentOSActionType.focusActive:
        badgeColor = palette.success;
        actionIcon = Icons.play_circle_filled_rounded;
        break;
      case StudentOSActionType.scheduledBlock:
        badgeColor = palette.primary;
        actionIcon = Icons.calendar_today_rounded;
        break;
      case StudentOSActionType.examPrep:
        badgeColor = AppColors.warning;
        actionIcon = Icons.school_rounded;
        break;
      case StudentOSActionType.reviseTopic:
        badgeColor = AppColors.info;
        actionIcon = Icons.replay_rounded;
        break;
      case StudentOSActionType.studySubject:
        badgeColor = palette.primary;
        actionIcon = Icons.menu_book_rounded;
        break;
      case StudentOSActionType.completeTask:
        badgeColor = palette.primary;
        actionIcon = Icons.assignment_turned_in_rounded;
        break;
      case StudentOSActionType.goalWork:
        badgeColor = palette.streak;
        actionIcon = Icons.flag_rounded;
        break;
      case StudentOSActionType.doneForToday:
        badgeColor = palette.success;
        actionIcon = Icons.nightlight_round;
        break;
      case StudentOSActionType.empty:
      case StudentOSActionType.planDay:
        badgeColor = palette.primary;
        actionIcon = Icons.auto_awesome_rounded;
        break;
    }

    final String badgeLabel = act.isFocusActive
        ? 'FOCUS ACTIVE'
        : act.isDoneForToday
            ? 'DONE FOR TODAY'
            : isStartMyDay
                ? 'START MY DAY'
                : isContinueMyDay
                    ? 'CONTINUE MY DAY'
                    : 'WHAT SHOULD I DO NOW?';

    final String buttonLabel = act.isFocusActive
        ? 'Continue Focus'
        : act.isDoneForToday
            ? 'View Progress'
            : isStartMyDay
                ? 'Start My Day'
                : isContinueMyDay
                    ? 'Continue'
                    : 'Start Now';

    return AppCard(
      color: palette.surface,
      borderColor: badgeColor.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Badges + Autopilot Status
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(actionIcon, size: 13, color: badgeColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                badgeLabel,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: badgeColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (autopilotMode != AutopilotMode.off) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    autopilotMode.label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
              if (act.suggestedDurationMinutes > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${act.suggestedDurationMinutes}m',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Title & Subtitle
          Text(
            act.title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: palette.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            act.subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.onSurfaceMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (act.bulletReasons.isNotEmpty && !act.isDoneForToday) ...[
            const SizedBox(height: AppSpacing.xs),
            ...act.bulletReasons.take(2).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Icon(Icons.circle, size: 4, color: badgeColor),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: palette.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (dayHint != null && dayHint!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: palette.onSurfaceMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dayHint!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          // Deterministic WHY explanation (secondary, no duplicate surface).
          if (!act.isDoneForToday) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showWhyExplanation(context, act),
                icon: const Icon(Icons.help_outline_rounded, size: 14),
                label: const Text('Why?'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 42,
                  child: AppPressable(
                    onTap: () => onExecuteAction(act),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: palette.accentGradient),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            act.isFocusActive ? Icons.play_arrow_rounded : Icons.bolt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              buttonLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: onThirtyMinBurst,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      '30m Burst',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: isDoneForToday ? 'Resume today' : 'Mark done for today',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => onToggleDoneToday(!isDoneForToday),
                icon: Icon(
                  isDoneForToday ? Icons.replay_rounded : Icons.nightlight_outlined,
                  size: 18,
                  color: isDoneForToday ? palette.primary : palette.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows the deterministic WHY explanation for a recommendation.
///
/// Uses only the engine-provided reason + bullet reasons — no new inference.
void showWhyExplanation(BuildContext context, StudentOSAction act) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Why this recommendation?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              act.reason,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final r in act.bulletReasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// ACADEMIC RISK BANNER
// ══════════════════════════════════════════════════════════════════════════

class AcademicRiskBanner extends StatelessWidget {
  const AcademicRiskBanner({
    super.key,
    required this.risks,
    required this.onAction,
  });

  final List<AcademicRisk> risks;
  final ValueChanged<AcademicRisk> onAction;

  @override
  Widget build(BuildContext context) {
    if (risks.isEmpty) return const SizedBox.shrink();
    final topRisk = risks.first;
    final color = topRisk.level.color;

    return AppCard(
      color: color.withValues(alpha: 0.06),
      borderColor: color.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(topRisk.icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topRisk.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  topRisk.detail,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.colorsOf(context).onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (topRisk.actionLabel != null) ...[
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: () => onAction(topRisk),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: color,
              ),
              child: Text(topRisk.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
