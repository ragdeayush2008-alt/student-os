import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/animations/animated_entrance.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../features/sleep/widgets/sleep_summary_card.dart';
import '../../../features/premium/services/entitlement_service.dart';
import '../../../features/premium/services/premium_gate.dart';
import '../../../features/premium/widgets/premium_widgets.dart';
import '../assistant_quick_actions.dart';
import '../daily_assistant_controller.dart';
import '../assistant_daily_state.dart';
import '../student_assistant_action.dart';
import '../student_assistant_context.dart';
import '../student_assistant_controller.dart';
import '../student_assistant_engine.dart';
import '../student_assistant_result.dart';
import '../../../core/design/student_os_premium.dart';
import '../../../features/guides/guide_controller.dart';
import '../assistant_launch_context.dart';
import '../../../features/guides/guide_overlay.dart';
import '../../../features/guides/guide_targets.dart';
import '../../../core/widgets/student_os_assistant_visual.dart';
import 'question_catalog_sheet.dart';
import 'assistant_result_card.dart';

/// Assistant Command Center (P1): the main Assistant screen.
///
/// HEADER (identity + greeting) · Next Best Action (existing intelligence,
/// guarded) · Today summary + sleep context (real snapshot data) · quick
/// actions · persisted conversation · input. No fake AI: every section reads
/// live controllers and degrades to honest empty states.
class AssistantCommandCenterScreen extends StatefulWidget {
  const AssistantCommandCenterScreen({super.key, this.initialQuery});

  /// Optional query asked automatically on open (used by unified entries
  /// that deep-link a question, e.g. "Ask: I have 2 hours").
  final String? initialQuery;

  @override
  State<AssistantCommandCenterScreen> createState() =>
      _AssistantCommandCenterScreenState();
}

class _AssistantCommandCenterScreenState
    extends State<AssistantCommandCenterScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    StudentAssistantController.instance.addListener(_onChanged);
    DailyAssistantController.instance.addListener(_onChanged);
    final q = widget.initialQuery;
    if (q != null && q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        StudentAssistantController.instance.ask(q.trim());
      });
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
    _scrollToEnd();
    // Guide launch requested by an explicit "teach me" query.
    final guideId =
        StudentAssistantController.instance.consumePendingGuide();
    if (guideId != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        GuideOverlayManager.ensureListening();
        GuideController.instance.startGuide(guideId);
      });
    }
  }

  void _scrollToEnd() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    StudentAssistantController.instance.removeListener(_onChanged);
    DailyAssistantController.instance.removeListener(_onChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _focusInputForEdit() {
    _inputCtrl.text =
        StudentAssistantController.instance.draftTextForEdit();
    _inputCtrl.selection = TextSelection.collapsed(
      offset: _inputCtrl.text.length,
    );
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _submit() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    StudentAssistantController.instance.ask(text);
  }

  String get _greeting {
    final hour = AppClock.current.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final controller = StudentAssistantController.instance;
    final result = controller.lastResult;

    return AppScaffold(
      title: 'Assistant',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Clear conversation',
          onPressed: () => controller.clearConversation(),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedEntrance(
                        child: _AssistantHero(greeting: _greeting),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _MorningBriefingCard(),
                      _NextBestActionCard(),
                      const SizedBox(height: AppSpacing.md),
                      _TodaySummaryCard(),
                      const SizedBox(height: AppSpacing.md),
                      _AttentionSection(),
                      _ProUpsellCard(),
                      const SleepSummaryCard(compact: true),
                      const SizedBox(height: AppSpacing.md),
                      _EveningReviewCard(),
                      _ActivityCard(),
                      AppSectionHeader(
                        title: 'Quick actions',
                        trailing: TextButton.icon(
                          onPressed: () =>
                              QuestionCatalogSheet.show(context),
                          icon: const Icon(
                              Icons.explore_outlined,
                              size: 16),
                          label: const Text('Explore questions'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GuideTargetAnchor(
                        id: 'assistant.quickActions',
                        child: _SmartQuickActions(
                          onAction: (action) =>
                              executeAssistantQuickAction(context, action),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppSectionHeader(title: 'Conversation'),
                      const SizedBox(height: AppSpacing.sm),
                      if (controller.messages.isEmpty && result == null)
                        _WelcomeEmptyState(
                          onAsk: (prompt) => controller.ask(prompt),
                        )
                      else ...[
                        AssistantHistoryView(
                          messages: controller.messages,
                          isLoading: controller.isLoading,
                          skipTrailingAssistant: result != null,
                        ),
                        if (result != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AnimatedEntrance(
                            child: AssistantResultCard(
                              result: result,
                              onExecuteAction: (action) async {
                              if (action.type ==
                                      AssistantActionType.applyPlan &&
                                  controller.hasPendingProposal) {
                                await controller.confirmAction(context);
                                return;
                              }
                              await const StudentAssistantEngine()
                                  .executeAction(context, action);
                            },
                            onConfirmAction: () => controller
                                .confirmAction(context),
                            onCancelConfirmation: () =>
                                controller.cancelConfirmation(),
                            onSelectChoice: (choice) => controller
                                .selectClarificationChoice(choice),
                            onEdit: result.requiresConfirmation &&
                                    controller.hasPendingProposal
                                ? _focusInputForEdit
                                : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SuggestedPrompts(
                            result: result,
                            onAsk: (prompt) => controller.ask(prompt),
                          ),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              GuideTargetAnchor(
                id: 'assistant.input',
                child: _InputBar(
                  controller: _inputCtrl,
                  focusNode: _focusNode,
                  isLoading: controller.isLoading,
                  onSubmit: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flagship Assistant landing hero: light canonical card (same family as
/// every Student OS card), canonical orb identity, greeting display type,
/// contextual lines. Special through identity — never a dark rectangle.
class _AssistantHero extends StatelessWidget {
  const _AssistantHero({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      borderColor: palette.primary.withValues(alpha: 0.30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const StudentOSAssistantVisual(
            size: StudentOSAssistantSize.large,
            status: StudentOSAssistantStatus.ready,
            semanticLabel: null,
          ),
          const SizedBox(height: 10),
          Text(
            greeting.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How can Student OS\nhelp you today?',
            textAlign: TextAlign.center,
            style: PremiumType.display(context).copyWith(
              color: palette.onSurface,
              fontSize: 28,
            ),
          ),
          Builder(
            builder: (ctx) {
              final line = StudentAssistantController
                  .instance.launchContext.contextLine;
              if (line == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        palette.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    line,
                    style: context.text.labelSmall?.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            "Plans, study, exams, sleep — ask anything.",
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          // Live context line keeps the hero honest (real snapshot data).
          Builder(
            builder: (ctx) {
              String? line;
              try {
                final snap = AssistantContextSnapshot.capture();
                line = snap.summaryLine;
              } catch (_) {
                line = null;
              }
              if (line == null || line.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: palette.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(
                      color: palette.onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Welcoming first-use state: greeting + tappable starter suggestions that
/// ask for real through the canonical controller. Never a dead end.
class _WelcomeEmptyState extends StatelessWidget {
  const _WelcomeEmptyState({required this.onAsk});

  final ValueChanged<String> onAsk;

  // Complements (never duplicates) the quick-action tiles below.
  static const _starters = [
    'I have 2 hours',
    'What should I revise?',
    'Show my exams',
    'Start my day',
    'Help me catch up',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: palette.primary.withValues(alpha: 0.30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const StudentOSAssistantVisual(
                size: StudentOSAssistantSize.small,
                semanticLabel: null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hey! What are we working on?',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _starters)
                ActionChip(
                  label: Text(s),
                  onPressed: () => onAsk(s),
                  backgroundColor: palette.surfaceVariant
                      .withValues(alpha: palette.isDark ? 0.4 : 0.5),
                  side: BorderSide(
                    color: palette.outline.withValues(alpha: 0.6),
                  ),
                  labelStyle: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.onSurface,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tappable follow-up prompts from the live result: engine-provided
/// prompts first, then kind-appropriate fallbacks. Tapping asks for real
/// via the controller.
class _SuggestedPrompts extends StatelessWidget {
  const _SuggestedPrompts({required this.result, required this.onAsk});

  final StudentAssistantResult result;
  final ValueChanged<String> onAsk;

  List<String> get prompts {
    if (result.suggestedPrompts.isNotEmpty) return result.suggestedPrompts;
    switch (result.cardKind) {
      case AssistantCardKind.exam:
        return const ['What should I study?', 'Plan my day', "What's weakest?"];
      case AssistantCardKind.revision:
      case AssistantCardKind.practice:
        return const ['Start a focus session', 'What should I study?'];
      case AssistantCardKind.todayPlan:
        return const ['I have 1 hour', 'What tasks are overdue?'];
      case AssistantCardKind.nextAction:
      case AssistantCardKind.recommendation:
        return const ['Plan this topic', 'I have 2 hours', 'Show my exams'];
      case AssistantCardKind.schedulePreview:
      case AssistantCardKind.confirmation:
        return const ['What should I do?', 'Show today plan'];
      default:
        return const [
          'What should I do?',
          'I have 2 hours',
          'What should I revise?',
          'Start my day',
          'Show my exams',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final prompt in prompts)
          ActionChip(
            label: Text(prompt),
            onPressed: () => onAsk(prompt),
            backgroundColor: palette.surfaceVariant
                .withValues(alpha: palette.isDark ? 0.4 : 0.5),
            side: BorderSide(
              color: palette.outline.withValues(alpha: 0.6),
            ),
            labelStyle: context.text.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.onSurface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
      ],
    );
  }
}

/// Next Best Action from the existing intelligence layer. Guarded: any
/// failure degrades to nothing (the section hides) instead of crashing.
/// Morning briefing card (P3 §2): shows 5–12h when there is unfinished
/// work and today isn't prepared yet. Preparing stages a proposal;
/// execution still needs Confirm.
class _MorningBriefingCard extends StatelessWidget {
  const _MorningBriefingCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final daily = DailyAssistantController.instance;
    final hour = AppClock.current.hour;
    if (hour < 5 ||
        hour >= 12 ||
        !daily.preferences.morningBriefing ||
        daily.state.prepared) {
      return const SizedBox.shrink();
    }
    AssistantContextSnapshot? snapshot;
    try {
      snapshot = AssistantContextSnapshot.capture();
    } catch (_) {
      snapshot = null;
    }
    final unfinished = (snapshot?.todayBlockCount ?? 0) +
        (snapshot?.overdueTaskCount ?? 0);
    if (snapshot == null || unfinished == 0) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    size: 15,
                    color: palette.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MORNING BRIEFING',
                    style: context.text.labelSmall?.copyWith(
                      color: palette.warning,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "I've prepared your day.",
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                snapshot.summaryLine,
                style: context.text.bodySmall?.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        // Automatic morning preparation is Pro.
                        if (!PremiumGate.check(
                            context, 'premium.assistant.proactive')) {
                          return;
                        }
                        StudentAssistantController.instance
                            .ask('prepare my day');
                      },
                      child: const Text('Prepare My Day'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => AppRouter.openPlan(context),
                      child: const Text('Open Plan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// Attention triggers (P3 §11): at most 3, dismissable, never during
/// focus, never repeating dismissed-today items.
class _AttentionSection extends StatelessWidget {
  const _AttentionSection();

  /// Proactive trigger kinds map to Pro features; basic urgency stays free.
  static String? _proFeatureFor(AssistantTriggerKind kind) {
    switch (kind) {
      case AssistantTriggerKind.fixDay:
        return 'premium.planning.smart';
      case AssistantTriggerKind.catchUp:
        return 'premium.catchup';
      case AssistantTriggerKind.examPrep:
        return 'premium.exam.intelligence';
      case AssistantTriggerKind.sleepBoundary:
      case AssistantTriggerKind.sleepChanged:
        return 'premium.sleep.awareness';
      case AssistantTriggerKind.overdueTask:
      case AssistantTriggerKind.aheadOfPlan:
      case AssistantTriggerKind.behindPlan:
        return null;
    }
  }

  void _openTrigger(BuildContext context, AssistantTrigger trigger) {
    final feature = _proFeatureFor(trigger.kind);
    if (feature != null &&
        !PremiumGate.check(context, feature)) {
      return;
    }
    StudentAssistantController.instance.ask(trigger.kind.prompt);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final daily = DailyAssistantController.instance;
    final triggers = daily.buildTriggers();
    if (triggers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...triggers.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: palette.warning,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          t.message,
                          style: context.text.bodySmall?.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _openTrigger(context, t),
                              child: Text(t.kind.label),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Dismiss for today',
                    onPressed: () => daily.dismissTrigger(t.id),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}

/// Evening review card (P3 §17): real completions + tomorrow priority.
/// Shown from 7 PM, or earlier once the day has meaningful activity.
class _EveningReviewCard extends StatelessWidget {
  const _EveningReviewCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final daily = DailyAssistantController.instance;
    if (!daily.preferences.eveningReview) {
      return const SizedBox.shrink();
    }
    final hour = AppClock.current.hour;
    StudentAssistantResult? result;
    try {
      result = const StudentAssistantEngine().process('evening review');
    } catch (_) {
      result = null;
    }
    if (result == null) return const SizedBox.shrink();
    final isEmpty = result.cardKind == AssistantCardKind.empty;
    if (isEmpty && hour < 19) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.nights_stay_rounded,
                    size: 15,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DAY REVIEW',
                    style: context.text.labelSmall?.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                result.message,
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => StudentAssistantController.instance
                          .ask('prepare tomorrow'),
                      child: const Text('Prepare tomorrow'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => AppRouter.openPlan(context),
                      child: const Text('View Tomorrow'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// Visible activity log (P3 §29): labels of confirmed actions today.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final log = DailyAssistantController.instance.state.actionLog;
    if (log.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TODAY WITH ASSISTANT',
                style: context.text.labelSmall?.copyWith(
                  color: palette.onSurfaceMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...log.reversed.take(5).map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✓ ',
                            style: context.text.bodySmall?.copyWith(
                              color: palette.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line,
                              style: context.text.bodySmall,
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
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// Advanced Assistant upsell (Pro): manual chat stays free; proactive
/// preparation and advanced actions are Pro. Hidden for Pro users.
class _ProUpsellCard extends StatelessWidget {
  const _ProUpsellCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    if (EntitlementService.instance.hasFeatureAccess(
      'premium.assistant.advanced',
    )) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: palette.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Advanced Assistant',
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const PremiumBadge(),
                      ],
                    ),
                    Text(
                      'Proactive prep, catch-up, exam plans and advanced actions.',
                      style: context.text.bodySmall?.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => AppRouter.openPremiumPage(
            context,
            sourceFeatureId: 'premium.assistant.advanced',
          ),
          child: const Text('Explore Pro'),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _NextBestActionCard extends StatelessWidget {
  const _NextBestActionCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final daily = DailyAssistantController.instance;
    if (daily.isDismissedToday('nba')) {
      return const SizedBox.shrink();
    }
    StudentAssistantResult? result;
    try {
      result = const StudentAssistantEngine().process('What should I do now?');
    } catch (_) {
      result = null;
    }
    if (result == null || !result.success) {
      return const SizedBox.shrink();
    }
    final action = result.primaryAction;
    final reasons = result.previewItems
        .map((r) => r.startsWith('• ') ? r.substring(2) : r)
        .take(3)
        .toList();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 15,
                color: palette.accent,
              ),
              const SizedBox(width: 6),
              Text(
                'NEXT BEST ACTION',
                style: context.text.labelSmall?.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.title,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            result.message,
            style: context.text.bodySmall?.copyWith(
              color: palette.onSurfaceMuted,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: context.text.bodySmall?.copyWith(
                        color: palette.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r,
                        style: context.text.bodySmall?.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => const StudentAssistantEngine()
                        .executeAction(context, action),
                    child: Text(action.label),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => daily.dismissTrigger(
                      '${DailyAssistantController.todayPrefix()}:nba',
                    ),
                    child: const Text('Later'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Today's summary from the real context snapshot (tasks, plan, exam,
/// sleep). Guarded: hides when the snapshot cannot be built.
class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    AssistantContextSnapshot? snapshot;
    try {
      snapshot = AssistantContextSnapshot.capture();
    } catch (_) {
      snapshot = null;
    }
    final snap = snapshot;
    if (snap == null) return const SizedBox.shrink();

    final lines = <String>[];
    if (snap.todayBlockCount > 0) {
      lines.add(
        '${snap.todayBlockCount} planned block${snap.todayBlockCount == 1 ? '' : 's'}',
      );
    } else {
      lines.add('Nothing planned yet');
    }
    if (snap.overdueTaskCount > 0) {
      lines.add(
        '${snap.overdueTaskCount} overdue',
      );
    }
    if (snap.nearestExamTitle != null && snap.daysToNearestExam != null) {
      lines.add(
        '${snap.nearestExamTitle} in ${snap.daysToNearestExam}d',
      );
    }
    if (snap.revisionDueCount > 0) {
      lines.add('${snap.revisionDueCount} to revise');
    }
    final sleepLine = snap.hasSleepSchedule && snap.sleepWindowLabel != null
        ? 'Sleep ${snap.sleepWindowLabel} (${snap.sleepDurationLabel ?? ''})'
        : 'Sleep schedule not set';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today_rounded,
                size: 15,
                color: palette.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'TODAY',
                style: context.text.labelSmall?.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            lines.join(' · '),
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.bedtime_rounded,
                size: 14,
                color: palette.onSurfaceMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sleepLine,
                  style: context.text.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick actions ordered by live context: sleep setup first when missing,
/// urgency first when overdue work exists. Same six P1 actions, smart order.
class _SmartQuickActions extends StatelessWidget {
  const _SmartQuickActions({required this.onAction});

  final Future<void> Function(AssistantQuickAction action) onAction;

  @override
  Widget build(BuildContext context) {
    AssistantContextSnapshot? snapshot;
    try {
      snapshot = AssistantContextSnapshot.capture();
    } catch (_) {
      snapshot = null;
    }
    final ordered = List<AssistantQuickAction>.from(
      AssistantQuickAction.all,
    );
    // Launch origin boosts origin-relevant actions first (§11 contextual
    // discovery), then the existing snapshot-based ordering applies.
    final originBoost = _originPriority(
      StudentAssistantController.instance.launchContext.origin,
    );
    if (originBoost.isNotEmpty) {
      ordered.sort((a, b) => originBoost
          .indexOf(b.id)
          .compareTo(originBoost.indexOf(a.id)));
    }
    final snap = snapshot;
    if (snap != null) {
      if (!snap.hasSleepSchedule) {
        ordered.sort((a, b) =>
            (b.id == 'sleep_schedule' ? 1 : 0) -
            (a.id == 'sleep_schedule' ? 1 : 0));
      } else if (snap.overdueTaskCount > 0) {
        const priority = ['whats_urgent', 'behind', 'do_now'];
        ordered.sort((a, b) =>
            priority.indexOf(b.id).compareTo(priority.indexOf(a.id)));
      } else if (snap.nearestExamTitle != null) {
        const priority = ['exam_prep', 'what_study', 'do_now'];
        ordered.sort((a, b) =>
            priority.indexOf(b.id).compareTo(priority.indexOf(a.id)));
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 420;
        if (!twoCol) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in ordered)
                _QuickActionTile(action: action, onAction: onAction),
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
          ),
          itemCount: ordered.length,
          itemBuilder: (context, i) => _QuickActionTile(
            action: ordered[i],
            onAction: onAction,
          ),
        );
      },
    );
  }
}

/// Origin → action-id priority for contextual discovery. Empty for global.
List<String> _originPriority(AssistantOrigin origin) {
  switch (origin) {
    case AssistantOrigin.sleep:
      return ['sleep_schedule', 'plan_my_day', 'do_now'];
    case AssistantOrigin.exam:
      return ['exam_prep', 'what_study', 'do_now'];
    case AssistantOrigin.sprintx:
    case AssistantOrigin.focus:
    case AssistantOrigin.deepFocus:
      return ['do_now', 'what_study', 'plan_my_day'];
    case AssistantOrigin.planning:
    case AssistantOrigin.tasks:
      return ['plan_my_day', 'whats_urgent', 'behind'];
    case AssistantOrigin.study:
    case AssistantOrigin.subject:
      return ['what_study', 'do_now', 'plan_my_day'];
    case AssistantOrigin.progress:
    case AssistantOrigin.rewards:
      return ['do_now', 'plan_my_day', 'what_study'];
    case AssistantOrigin.global:
    case AssistantOrigin.home:
    case AssistantOrigin.resources:
    case AssistantOrigin.tools:
    case AssistantOrigin.workspace:
    case AssistantOrigin.settings:
      return [];
  }
}

/// Premium tactile quick-action tile: icon aura, label, chevron affordance.
/// Behavior identical to the former chip (same callback, same ordering).
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.onAction});

  final AssistantQuickAction action;
  final Future<void> Function(AssistantQuickAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => onAction(action),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.paleSage.withValues(
                      alpha: palette.isDark ? 0.30 : 0.50),
                  palette.surface,
                ],
              ),
              border: Border.all(
                color: palette.sage.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    action.icon,
                    size: 17,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(
              color: palette.sage.withValues(alpha: 0.25)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.paleSage.withValues(
                          alpha: palette.isDark ? 0.30 : 0.55),
                      palette.surface,
                    ],
                  ),
                  border: Border.all(
                    color: palette.sage.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 3,
                  style: context.text.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Ask Student OS anything…',
                    hintStyle: context.text.bodyMedium?.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 13,
                    ),
                  ),
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.forest, AppColors.deepForest],
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isLoading ? null : onSubmit,
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
