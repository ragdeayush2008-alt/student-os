import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/practice_session.dart';
import '../topic_practice_controller.dart';
import 'practice_result_screen.dart';

/// Interactive question session solving screen.
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({
    super.key,
    required this.session,
  });

  final PracticeSession session;

  static Future<void> open(BuildContext context, PracticeSession session) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeSessionScreen(session: session),
      ),
    );
  }

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  Timer? _timer;
  int _elapsedSec = 0;
  bool _submitting = false;

  // Localized timer: only the timer label listens, never the whole screen.
  final ValueNotifier<int> _elapsed = ValueNotifier<int>(0);

  // Guard against per-second model notifies so only real state changes
  // (answer submitted, question advances) rebuild the screen.
  int _lastQuestionIndex = -1;
  int _lastAnsweredCount = -1;

  @override
  void initState() {
    super.initState();
    _elapsedSec = widget.session.elapsedSeconds;
    _elapsed.value = _elapsedSec;
    _lastQuestionIndex = widget.session.currentQuestionIndex;
    _lastAnsweredCount = widget.session.answeredCount;
    widget.session.addListener(_onSessionChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _elapsedSec++;
      widget.session.updateElapsedSeconds(_elapsedSec);
      _elapsed.value = _elapsedSec;
    });
  }

  void _onSessionChanged() {
    final qIdx = widget.session.currentQuestionIndex;
    final answeredCount = widget.session.answeredCount;
    if (qIdx == _lastQuestionIndex && answeredCount == _lastAnsweredCount) return;
    _lastQuestionIndex = qIdx;
    _lastAnsweredCount = answeredCount;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsed.dispose();
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit practice?'),
        content: const Text(
          'Your current session progress will not be saved as a completed attempt.',
        ),
        actions: [
          TextButton(
            child: const Text('Keep Practicing'),
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

  Future<void> _completeSession() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();

    final session = widget.session;
    final result = session.complete();

    // Idempotent record in TopicPracticeController
    try {
      if (session.topicId != null && session.topicId!.isNotEmpty) {
        await TopicPracticeController.instance.recordAttempt(
          topicId: session.topicId!,
          subjectId: session.subjectId,
          chapterId: session.chapterId,
          durationSec: result.durationSec,
          totalQuestions: result.totalQuestions,
          correctAnswers: result.correctCount,
          incorrectAnswers: result.incorrectCount,
          score: result.totalQuestions > 0
              ? ((result.correctCount / result.totalQuestions) * 100).clamp(0.0, 100.0)
              : null,
          notes: 'Completed practice session (${result.accuracyPercentage}% accuracy)',
        );
      }
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PracticeResultScreen(result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final session = widget.session;

    if (session.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(session.title)),
        body: const Center(
          child: Text('No questions in this session.'),
        ),
      );
    }

    final currentQ = session.currentQuestion;
    final totalQ = session.totalQuestions;
    final currentIndex = session.currentQuestionIndex;
    final progressFraction = totalQ > 0 ? (currentIndex + 1) / totalQ : 0.0;

    final isAnswered = currentQ != null && session.isAnswered(currentQ.id);
    final selectedOption = currentQ != null ? session.selectedAnswerFor(currentQ.id) : null;
    final isLearningMode = session.feedbackMode == PracticeFeedbackMode.learning;

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
            session.title,
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
                      Icon(Icons.timer_outlined, size: 14,
                          color: palette.onSurfaceMuted),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progressFraction,
              backgroundColor: palette.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
              minHeight: 4,
            ),
          ),
        ),
        body: SafeArea(
          child: currentQ == null
              ? const Center(child: Text('Question not found'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Progress & Mode header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'QUESTION ${currentIndex + 1} OF $totalQ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: palette.onSurfaceMuted,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLearningMode
                                        ? palette.primary.withValues(alpha: 0.12)
                                        : AppColors.secondary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    session.feedbackMode.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isLearningMode
                                          ? palette.primary
                                          : AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Question Text Card
                            AppCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Text(
                                currentQ.questionText,
                                style: context.text.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Options List
                            for (int i = 0; i < currentQ.options.length; i++) ...[
                              _OptionTile(
                                optionText: currentQ.options[i],
                                isSelected: selectedOption == currentQ.options[i],
                                isAnswered: isAnswered,
                                isLearningMode: isLearningMode,
                                isCorrect: currentQ.isOptionCorrect(currentQ.options[i]),
                                onTap: () {
                                  if (isLearningMode && isAnswered) return;
                                  session.selectAnswer(currentQ.options[i]);
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],

                            // Instant Feedback Box (Learning Mode)
                            if (isLearningMode && isAnswered && selectedOption != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              _InstantFeedbackBox(
                                isCorrect: currentQ.isOptionCorrect(selectedOption),
                                correctAnswer: currentQ.correctAnswer,
                                explanation: currentQ.explanation,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Bottom Navigation Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        border: Border(
                          top: BorderSide(
                            color: palette.outline.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (session.hasPrevious)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.chevron_left_rounded),
                              label: const Text('Previous'),
                              onPressed: () => session.previous(),
                            )
                          else
                            const SizedBox.shrink(),

                          const Spacer(),

                          // Skip Button (when not answered)
                          if (!isAnswered && session.hasNext)
                            TextButton.icon(
                              icon: const Icon(Icons.skip_next_rounded, size: 18),
                              label: const Text('Skip'),
                              onPressed: () => session.skipCurrent(),
                            ),

                          const SizedBox(width: AppSpacing.sm),

                          // Next / Complete Button
                          if (session.hasNext)
                            FilledButton.icon(
                              icon: const Icon(Icons.chevron_right_rounded),
                              label: const Text('Next'),
                              onPressed: () => session.next(),
                            )
                          else
                            FilledButton.icon(
                              icon: _submitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: palette.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded),
                              label: Text(_submitting ? 'Submitting...' : 'Submit Practice'),
                              onPressed: _submitting ? null : _completeSession,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.optionText,
    required this.isSelected,
    required this.isAnswered,
    required this.isLearningMode,
    required this.isCorrect,
    required this.onTap,
  });

  final String optionText;
  final bool isSelected;
  final bool isAnswered;
  final bool isLearningMode;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    Color borderColor;
    Color? bgColor;
    Widget leadingIcon;

    if (isLearningMode && isAnswered) {
      if (isSelected && isCorrect) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.12);
        leadingIcon = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
      } else if (isSelected && !isCorrect) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.12);
        leadingIcon = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20);
      } else if (!isSelected && isCorrect) {
        borderColor = AppColors.success.withValues(alpha: 0.6);
        bgColor = AppColors.success.withValues(alpha: 0.05);
        leadingIcon = const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20);
      } else {
        borderColor = palette.outline.withValues(alpha: 0.3);
        leadingIcon = Icon(Icons.radio_button_unchecked_rounded, color: palette.onSurfaceMuted, size: 20);
      }
    } else {
      if (isSelected) {
        borderColor = palette.primary;
        bgColor = palette.primary.withValues(alpha: 0.1);
        leadingIcon = Icon(Icons.radio_button_checked_rounded, color: palette.primary, size: 20);
      } else {
        borderColor = palette.outline.withValues(alpha: 0.4);
        leadingIcon = Icon(Icons.radio_button_unchecked_rounded, color: palette.onSurfaceMuted, size: 20);
      }
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      borderColor: borderColor,
      color: bgColor,
      onTap: onTap,
      child: Row(
        children: [
          leadingIcon,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              optionText,
              style: context.text.bodyMedium!.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstantFeedbackBox extends StatelessWidget {
  const _InstantFeedbackBox({
    required this.isCorrect,
    required this.correctAnswer,
    this.explanation,
  });

  final bool isCorrect;
  final String correctAnswer;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final color = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct! Nicely done.' : 'Not quite. The correct answer is:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 4),
            Text(
              correctAnswer,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
          if (explanation != null && explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              explanation!,
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurface,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
