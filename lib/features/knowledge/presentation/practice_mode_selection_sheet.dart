import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/practice_session.dart';
import '../../../data/models/topic.dart';
import '../practice_question_controller.dart';
import 'practice_record_sheet.dart';
import 'practice_session_screen.dart';
import 'question_creation_sheet.dart';

/// Modal sheet to configure and start a practice session.
class PracticeModeSelectionSheet extends StatefulWidget {
  const PracticeModeSelectionSheet({
    super.key,
    required this.topic,
  });

  final Topic topic;

  static Future<void> show(BuildContext context, {required Topic topic}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PracticeModeSelectionSheet(topic: topic),
    );
  }

  @override
  State<PracticeModeSelectionSheet> createState() =>
      _PracticeModeSelectionSheetState();
}

class _PracticeModeSelectionSheetState extends State<PracticeModeSelectionSheet> {
  PracticeFeedbackMode _feedbackMode = PracticeFeedbackMode.learning;
  int? _selectedQuestionCount;

  @override
  void initState() {
    super.initState();
    PracticeQuestionController.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PracticeQuestionController.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _startPractice(int questionCount) {
    final session = PracticeQuestionController.instance.createSession(
      topicId: widget.topic.id,
      chapterId: widget.topic.chapterId,
      subjectId: widget.topic.subjectId,
      title: widget.topic.title,
      questionLimit: questionCount,
      feedbackMode: _feedbackMode,
    );

    Navigator.of(context).pop();
    PracticeSessionScreen.open(context, session);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final availableQuestions =
        PracticeQuestionController.instance.questionsForTopic(widget.topic.id);
    final count = availableQuestions.length;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.onSurfaceMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title & Topic
              Text(
                'Practice & Quiz',
                style: context.text.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.topic.title,
                style: context.text.bodyMedium!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Empty State check (NO fake questions!)
              if (count == 0) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: palette.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 36,
                        color: palette.onSurfaceMuted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No practice questions are available for this topic yet.',
                        style: context.text.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can record a manual practice attempt or add your own practice questions.',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add_task_rounded, size: 16),
                              label: const Text('Record Practice'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                PracticeRecordSheet.show(context, widget.topic);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Questions'),
                              onPressed: () {
                                QuestionCreationSheet.show(
                                  context,
                                  topic: widget.topic,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Feedback Mode Selection
                Text(
                  'FEEDBACK MODE',
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
                      child: _ModeOptionCard(
                        title: 'Learning Mode',
                        subtitle: 'Instant answer feedback & explanation',
                        icon: Icons.lightbulb_outline_rounded,
                        isSelected:
                            _feedbackMode == PracticeFeedbackMode.learning,
                        onTap: () => setState(
                          () => _feedbackMode = PracticeFeedbackMode.learning,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ModeOptionCard(
                        title: 'Assessment',
                        subtitle: 'Simulate quiz without immediate answers',
                        icon: Icons.timer_outlined,
                        isSelected:
                            _feedbackMode == PracticeFeedbackMode.assessment,
                        onTap: () => setState(
                          () => _feedbackMode = PracticeFeedbackMode.assessment,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Question Count Selection (Strictly derived from available count)
                Text(
                  'NUMBER OF QUESTIONS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                Column(
                  children: [
                    if (count >= 5)
                      _CountOptionTile(
                        label: 'Quick Practice',
                        questionCount: 5,
                        estimatedMinutes: 5,
                        isSelected: _selectedQuestionCount == 5,
                        onTap: () => setState(() => _selectedQuestionCount = 5),
                      ),
                    if (count >= 10)
                      _CountOptionTile(
                        label: 'Standard Practice',
                        questionCount: 10,
                        estimatedMinutes: 10,
                        isSelected: _selectedQuestionCount == 10,
                        onTap: () => setState(() => _selectedQuestionCount = 10),
                      ),
                    if (count >= 20)
                      _CountOptionTile(
                        label: 'Deep Practice',
                        questionCount: 20,
                        estimatedMinutes: 20,
                        isSelected: _selectedQuestionCount == 20,
                        onTap: () => setState(() => _selectedQuestionCount = 20),
                      ),
                    _CountOptionTile(
                      label: count >= 5 ? 'All Available' : '$count Questions Available',
                      questionCount: count,
                      estimatedMinutes: math.max(1, count),
                      isSelected: _selectedQuestionCount == count ||
                          (_selectedQuestionCount == null && count < 5),
                      onTap: () => setState(() => _selectedQuestionCount = count),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Start Practice Action
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    'Start Practice (${_selectedQuestionCount ?? (count >= 5 ? 5 : count)} questions)',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () {
                    final chosenCount = _selectedQuestionCount ?? (count >= 5 ? 5 : count);
                    _startPractice(chosenCount);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: isSelected ? palette.primary : palette.outline.withValues(alpha: 0.3),
      color: isSelected ? palette.primary.withValues(alpha: 0.08) : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? palette.primary : palette.onSurfaceMuted,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: context.text.titleSmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected ? palette.primary : palette.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountOptionTile extends StatelessWidget {
  const _CountOptionTile({
    required this.label,
    required this.questionCount,
    required this.estimatedMinutes,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int questionCount;
  final int estimatedMinutes;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        borderColor: isSelected ? palette.primary : palette.outline.withValues(alpha: 0.3),
        color: isSelected ? palette.primary.withValues(alpha: 0.08) : null,
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? palette.primary : palette.onSurfaceMuted,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$questionCount questions · ~$estimatedMinutes min',
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
