import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/practice_session_result.dart';

/// Modal sheet for reviewing questions, student answers, and explanations after practice.
class PracticeReviewMistakesSheet extends StatefulWidget {
  const PracticeReviewMistakesSheet({
    super.key,
    required this.result,
    this.initialShowMistakesOnly = true,
  });

  final PracticeSessionResult result;
  final bool initialShowMistakesOnly;

  static Future<void> show(
    BuildContext context, {
    required PracticeSessionResult result,
    bool initialShowMistakesOnly = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PracticeReviewMistakesSheet(
        result: result,
        initialShowMistakesOnly: initialShowMistakesOnly,
      ),
    );
  }

  @override
  State<PracticeReviewMistakesSheet> createState() =>
      _PracticeReviewMistakesSheetState();
}

class _PracticeReviewMistakesSheetState
    extends State<PracticeReviewMistakesSheet> {
  late bool _showMistakesOnly;

  @override
  void initState() {
    super.initState();
    final hasMistakes = widget.result.incorrectCount > 0 ||
        widget.result.skippedCount > 0;
    _showMistakesOnly = widget.initialShowMistakesOnly && hasMistakes;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final displayedDetails = _showMistakesOnly
        ? widget.result.details.where((d) => !d.isCorrect).toList()
        : widget.result.details;

    final hasMistakes = widget.result.incorrectCount > 0 ||
        widget.result.skippedCount > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Questions',
                        style: context.text.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${widget.result.correctCount} of ${widget.result.totalQuestions} correct (${widget.result.accuracyPercentage}%)',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
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
            const SizedBox(height: AppSpacing.sm),

            // Filter Toggle (if mistakes exist)
            if (hasMistakes)
              Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      'Mistakes & Skipped (${widget.result.incorrectCount + widget.result.skippedCount})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: _showMistakesOnly,
                    onSelected: (val) {
                      if (val) setState(() => _showMistakesOnly = true);
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: Text(
                      'All Questions (${widget.result.totalQuestions})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: !_showMistakesOnly,
                    onSelected: (val) {
                      if (val) setState(() => _showMistakesOnly = false);
                    },
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),

            // Question List
            Expanded(
              child: displayedDetails.isEmpty
                  ? Center(
                      child: Text(
                        'No questions to show.',
                        style: context.text.bodyMedium!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayedDetails.length,
                      itemBuilder: (context, index) {
                        final detail = displayedDetails[index];
                        final qNumber = widget.result.details.indexOf(detail) + 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _QuestionReviewCard(
                            questionNumber: qNumber,
                            detail: detail,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.questionNumber,
    required this.detail,
  });

  final int questionNumber;
  final QuestionResultDetail detail;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (detail.isCorrect) {
      statusColor = AppColors.success;
      statusLabel = 'Correct';
      statusIcon = Icons.check_circle_rounded;
    } else if (detail.isSkipped) {
      statusColor = AppColors.warning;
      statusLabel = 'Skipped';
      statusIcon = Icons.skip_next_rounded;
    } else {
      statusColor = AppColors.error;
      statusLabel = 'Incorrect';
      statusIcon = Icons.cancel_rounded;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: statusColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Number & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUESTION $questionNumber',
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Question Text
          Text(
            detail.questionText,
            style: context.text.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Student's Answer (if not correct)
          if (!detail.isCorrect) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: detail.isSkipped
                    ? palette.surfaceVariant.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: detail.isSkipped
                      ? palette.outline.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your answer: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      detail.isSkipped
                          ? '(Skipped)'
                          : (detail.studentAnswer ?? 'None'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: detail.isSkipped
                            ? palette.onSurfaceMuted
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          // Correct Answer
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Correct answer: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: Text(
                    detail.correctAnswer,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Explanation (if available)
          if (detail.explanation != null &&
              detail.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Explanation',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail.explanation!,
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurface,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
