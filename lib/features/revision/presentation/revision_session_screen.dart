import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/revision_record.dart';
import '../../../data/models/topic.dart';
import '../../knowledge/practice_question_controller.dart';
import '../../knowledge/presentation/practice_mode_selection_sheet.dart';
import '../../resources/resource_controller.dart';
import '../../subjects/subject_controller.dart';
import '../revision_controller.dart';

/// Interactive Revision Session 2.0 with active recall evaluation.
class RevisionSessionScreen extends StatefulWidget {
  const RevisionSessionScreen({
    super.key,
    required this.topic,
    this.suggestedDurationMinutes = 20,
    this.initialNotes = '',
  });

  final Topic topic;
  final int suggestedDurationMinutes;
  final String initialNotes;

  static Future<void> open(
    BuildContext context, {
    required Topic topic,
    int suggestedDurationMinutes = 20,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RevisionSessionScreen(
          topic: topic,
          suggestedDurationMinutes: suggestedDurationMinutes,
        ),
      ),
    );
  }

  @override
  State<RevisionSessionScreen> createState() => _RevisionSessionScreenState();
}

class _RevisionSessionScreenState extends State<RevisionSessionScreen> {
  Timer? _timer;
  int _elapsedSec = 0;
  bool _revealedContent = false;
  RevisionRecallOutcome? _selectedOutcome;
  late final TextEditingController _notesController;
  bool _submitting = false;

  // Localized timer: only the timer label listens, never the whole screen.
  final ValueNotifier<int> _elapsed = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _elapsedSec++;
      _elapsed.value = _elapsedSec;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsed.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit revision?'),
        content: const Text(
          'Your current progress will not be saved as a completed revision session.',
        ),
        actions: [
          TextButton(
            child: const Text('Keep Revising'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Exit'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _completeRevision() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();

    final outcome = _selectedOutcome ?? RevisionRecallOutcome.unassessed;
    final notes = _notesController.text.trim();

    try {
      final record = await RevisionController.instance.recordRevision(
        topicId: widget.topic.id,
        chapterId: widget.topic.chapterId,
        subjectId: widget.topic.subjectId,
        durationSec: _elapsedSec,
        recallOutcome: outcome,
        notes: notes,
        source: 'recall_session',
      );

      if (mounted) {
        _showCompletionDialog(record);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record revision: $e')),
        );
      }
    }
  }

  void _showCompletionDialog(RevisionRecord record) {
    final hasQuestions = PracticeQuestionController.instance
        .hasQuestionsForTopic(widget.topic.id);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Revision Complete! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recorded ${_elapsedSec ~/ 60}m revision on "${widget.topic.title}". Spaced repetition schedule updated (+XP awarded).',
            ),
            if (hasQuestions) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Next step: Practice questions for this topic to test retention.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          if (hasQuestions)
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                PracticeModeSelectionSheet.show(context, topic: widget.topic);
              },
              child: const Text('Practice Now'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subject =
        SubjectController.instance.subjectById(widget.topic.subjectId);
    final resources =
        ResourceController.instance.resourcesForSubject(widget.topic.subjectId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.topic.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final shouldExit = await _confirmExit();
              if (shouldExit && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: _elapsed,
                builder: (context, secs, _) {
                  final mins = secs ~/ 60;
                  final rem = secs % 60;
                  final timerString =
                      '${mins.toString().padLeft(2, "0")}:${rem.toString().padLeft(2, "0")}';
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14, color: palette.onSurfaceMuted),
                      const SizedBox(width: 4),
                      Text(
                        timerString,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.onSurface,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Topic Context Header ─────────────────────────────────────
                Text(
                  'ACTIVE RECALL REVISION',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.topic.title,
                  style: context.text.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subject?.displayName ?? 'Curriculum Topic',
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Step 1: Active Recall Prompt ─────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  borderColor: AppColors.warning.withValues(alpha: 0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology_outlined,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Step 1: Active Retrieval',
                            style: context.text.titleSmall!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Before opening your notes, pause and retrieve key principles, formulas, definitions, and problem-solving steps from memory.',
                        style: context.text.bodyMedium!.copyWith(
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (!_revealedContent)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Reveal Notes & Resources'),
                          onPressed: () =>
                              setState(() => _revealedContent = true),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Revealed Resources / Notes ───────────────────────────────
                if (_revealedContent) ...[
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes_rounded,
                                size: 16, color: palette.primary),
                            const SizedBox(width: 6),
                            Text(
                              'REFERENCE CONTENT',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: palette.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (widget.topic.description.isNotEmpty)
                          Text(
                            widget.topic.description,
                            style: context.text.bodyMedium,
                          )
                        else
                          Text(
                            'Review the material in your textbook or saved notes.',
                            style: context.text.bodySmall!.copyWith(
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                        if (resources.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Saved subject resources:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                          for (final r in resources.take(3))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: InkWell(
                                onTap: () => AppRouter.openResourceDetail(
                                    context, r.id),
                                child: Text(
                                  '• ${r.title} (${r.resourceType.name})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Step 2: Self-Evaluation (Recall Outcome) ─────────────────
                Text(
                  'HOW WAS YOUR RECALL?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                Row(
                  children: [
                    Expanded(
                      child: _RecallButton(
                        label: 'I Knew It',
                        subtitle: 'Clear recall',
                        outcome: RevisionRecallOutcome.knew,
                        color: AppColors.success,
                        isSelected:
                            _selectedOutcome == RevisionRecallOutcome.knew,
                        onTap: () => setState(
                          () => _selectedOutcome = RevisionRecallOutcome.knew,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _RecallButton(
                        label: 'Partly',
                        subtitle: 'Struggled',
                        outcome: RevisionRecallOutcome.partial,
                        color: AppColors.warning,
                        isSelected:
                            _selectedOutcome == RevisionRecallOutcome.partial,
                        onTap: () => setState(
                          () =>
                              _selectedOutcome = RevisionRecallOutcome.partial,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _RecallButton(
                        label: 'Forgot',
                        subtitle: 'Need review',
                        outcome: RevisionRecallOutcome.forgot,
                        color: AppColors.error,
                        isSelected:
                            _selectedOutcome == RevisionRecallOutcome.forgot,
                        onTap: () => setState(
                          () => _selectedOutcome = RevisionRecallOutcome.forgot,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Notes Field ──────────────────────────────────────────────
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Revision Notes (optional)',
                    hintText:
                        'e.g. Mastered the formula, need to double-check edge cases',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Submit / Complete Button ─────────────────────────────────
                FilledButton.icon(
                  onPressed: _submitting ? null : _completeRevision,
                  icon: _submitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _submitting
                        ? 'Saving...'
                        : 'Complete Revision (${_elapsedSec ~/ 60}m)',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecallButton extends StatelessWidget {
  const _RecallButton({
    required this.label,
    required this.subtitle,
    required this.outcome,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final RevisionRecallOutcome outcome;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderColor: isSelected ? color : color.withValues(alpha: 0.25),
      color: isSelected ? color.withValues(alpha: 0.15) : null,
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
