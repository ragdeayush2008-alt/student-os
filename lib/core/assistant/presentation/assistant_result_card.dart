import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../assistant_message.dart';
import '../student_assistant_action.dart';
import '../student_assistant_result.dart';

/// Shared Assistant rendering (P1): the rich result card plus conversation
/// history bubbles. Used by BOTH the assistant bottom sheet and the
/// Assistant Command Center screen — one implementation, no duplicates.

Color assistantAccentFor(AssistantCardKind kind, AppPalette palette) {
  switch (kind) {
    case AssistantCardKind.exam:
    case AssistantCardKind.confirmation:
      return palette.warning;
    case AssistantCardKind.error:
      return AppColors.error;
    case AssistantCardKind.success:
      return AppColors.success;
    case AssistantCardKind.schedulePreview:
      return AppColors.secondary;
    case AssistantCardKind.recommendation:
    case AssistantCardKind.nextAction:
    case AssistantCardKind.todayPlan:
    case AssistantCardKind.studyTopic:
    case AssistantCardKind.revision:
    case AssistantCardKind.practice:
      return palette.accent;
    case AssistantCardKind.neutral:
    case AssistantCardKind.empty:
    case AssistantCardKind.clarification:
      return palette.onSurfaceMuted;
  }
}

IconData assistantIconFor(AssistantCardKind kind) {
  switch (kind) {
    case AssistantCardKind.recommendation:
    case AssistantCardKind.nextAction:
      return Icons.bolt_rounded;
    case AssistantCardKind.todayPlan:
      return Icons.calendar_today_rounded;
    case AssistantCardKind.studyTopic:
      return Icons.menu_book_rounded;
    case AssistantCardKind.revision:
      return Icons.refresh_rounded;
    case AssistantCardKind.practice:
      return Icons.fitness_center_rounded;
    case AssistantCardKind.exam:
      return Icons.school_rounded;
    case AssistantCardKind.schedulePreview:
      return Icons.schedule_rounded;
    case AssistantCardKind.confirmation:
      return Icons.check_circle_outline_rounded;
    case AssistantCardKind.success:
      return Icons.check_circle_rounded;
    case AssistantCardKind.empty:
      return Icons.inbox_rounded;
    case AssistantCardKind.error:
      return Icons.error_outline_rounded;
    case AssistantCardKind.clarification:
      return Icons.help_outline_rounded;
    case AssistantCardKind.neutral:
      return Icons.auto_awesome_rounded;
  }
}

/// The rich single-card rendering of a [StudentAssistantResult], including
/// clarification choices, confirmation Cancel/Confirm, and action buttons.
///
/// Action execution is injected: the sheet dismisses itself first, while the
/// Command Center screen executes in place.
class AssistantResultCard extends StatelessWidget {
  const AssistantResultCard({
    super.key,
    required this.result,
    required this.onExecuteAction,
    required this.onConfirmAction,
    required this.onCancelConfirmation,
    required this.onSelectChoice,
    this.onEdit,
  });

  final StudentAssistantResult result;

  /// Runs a primary/secondary action (navigation or engine execution).
  final Future<void> Function(StudentAssistantAction action) onExecuteAction;

  /// Confirms the pending mutating action.
  final Future<void> Function() onConfirmAction;

  /// Cancels the pending confirmation.
  final void Function() onCancelConfirmation;

  /// Picks a clarification choice.
  final void Function(String choice) onSelectChoice;

  /// Optional Edit affordance for proposal previews: focuses the input so
  /// the student can adjust in words ("remove X", "make Y first").
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    if (result.clarificationRequired) {
      return _buildClarificationCard(context, result, palette);
    }

    final accent = assistantAccentFor(result.cardKind, palette);
    final showSteps = result.steps.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  assistantIconFor(result.cardKind),
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  result.title,
                  style: context.text.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.message,
            style: context.text.bodyMedium!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          if (result.explanation != null &&
              result.explanation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.explanation!,
              style: context.text.bodySmall!.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showSteps) ...[
            const SizedBox(height: AppSpacing.md),
            ...result.steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (step.isPrimary
                                ? accent
                                : palette.surfaceVariant)
                            .withValues(alpha: step.isPrimary ? 0.18 : 0.35),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: context.text.labelSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: step.isPrimary ? accent : palette.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label,
                            style: context.text.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (step.detail != null ||
                              (step.minutes != null && step.minutes! > 0))
                            Text(
                              [
                                if (step.detail != null) step.detail!,
                                if (step.minutes != null && step.minutes! > 0)
                                  '${step.minutes} min',
                              ].join(' · '),
                              style: context.text.bodySmall!.copyWith(
                                color: palette.onSurfaceMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else if (result.previewItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...result.previewItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: context.text.bodySmall!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          if (result.contextLine != null &&
              result.contextLine!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 13,
                    color: palette.onSurfaceMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      result.contextLine!,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (result.primaryAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            if (result.requiresConfirmation) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: onCancelConfirmation,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () => onConfirmAction(),
                      child: Text(result.primaryAction!.label),
                    ),
                  ),
                ],
              ),
              if (onEdit != null) ...[
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: onEdit,
                  ),
                ),
              ],
            ] else ...[
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(result.primaryAction!.label),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () =>
                    onExecuteAction(result.primaryAction!),
              ),
            ],
          ],
          if (result.secondaryActions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...result.secondaryActions.map((sec) {
              return TextButton(
                onPressed: () => onExecuteAction(sec),
                child: Text(sec.label),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildClarificationCard(
    BuildContext context,
    StudentAssistantResult result,
    AppPalette palette,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: palette.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                result.title,
                style: context.text.titleSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            result.message,
            style: context.text.bodyMedium!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.clarificationChoices.map((choice) {
              return AppPressable(
                onTap: () => onSelectChoice(choice),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: palette.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    choice,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Plain history bubbles for persisted conversation turns.
///
/// The latest assistant turn is rendered as the rich [AssistantResultCard]
/// by the parent, so the trailing assistant message is skipped here to
/// avoid duplication. Typing state renders while the engine works.
class AssistantHistoryView extends StatelessWidget {
  const AssistantHistoryView({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.skipTrailingAssistant,
  });

  final List<AssistantMessage> messages;
  final bool isLoading;
  final bool skipTrailingAssistant;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    var visible = messages;
    if (skipTrailingAssistant &&
        visible.isNotEmpty &&
        visible.last.role == AssistantMessageRole.assistant) {
      visible = visible.sublist(0, visible.length - 1);
    }
    if (visible.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...visible.map((m) => _MessageBubble(message: m)),
        if (isLoading) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceVariant.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thinking…',
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    if (message.role == AssistantMessageRole.user) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: palette.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  message.text,
                  style: context.text.bodyMedium!.copyWith(
                    color: palette.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.title != null && message.title!.isNotEmpty)
            Text(
              message.title!,
              style: context.text.labelSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.onSurfaceMuted,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            message.text,
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }
}
