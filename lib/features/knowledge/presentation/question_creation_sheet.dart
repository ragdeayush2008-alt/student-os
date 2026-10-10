import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/question.dart';
import '../../../data/models/topic.dart';
import '../practice_question_controller.dart';

/// Modal sheet for locally authoring practice questions for a topic.
class QuestionCreationSheet extends StatefulWidget {
  const QuestionCreationSheet({
    super.key,
    required this.topic,
  });

  final Topic topic;

  static Future<void> show(BuildContext context, {required Topic topic}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestionCreationSheet(topic: topic),
    );
  }

  @override
  State<QuestionCreationSheet> createState() => _QuestionCreationSheetState();
}

class _QuestionCreationSheetState extends State<QuestionCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _explanationController = TextEditingController();

  int _correctOptionIndex = 0;
  final _difficulty = QuestionDifficulty.medium;
  bool _saving = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    final questionText = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least 2 options.')),
      );
      return;
    }

    if (_correctOptionIndex >= options.length) {
      _correctOptionIndex = 0;
    }
    final correctAnswer = options[_correctOptionIndex];

    setState(() => _saving = true);

    try {
      await PracticeQuestionController.instance.addQuestion(
        topicId: widget.topic.id,
        chapterId: widget.topic.chapterId,
        subjectId: widget.topic.subjectId,
        questionText: questionText,
        options: options,
        correctAnswer: correctAnswer,
        explanation: _explanationController.text.trim(),
        difficulty: _difficulty,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Practice question saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving question: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl + bottomInset,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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

                Text(
                  'Add Practice Question',
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

                // Question Text
                TextFormField(
                  controller: _questionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question text *',
                    hintText: 'Enter question prompt...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Question prompt is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Options with radio selection for correct answer
                Text(
                  'OPTIONS & CORRECT ANSWER *',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                for (int i = 0; i < _optionControllers.length; i++) ...[
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _correctOptionIndex == i
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _correctOptionIndex == i
                              ? palette.primary
                              : palette.onSurfaceMuted,
                        ),
                        tooltip: 'Mark as correct answer',
                        onPressed: () => setState(() => _correctOptionIndex = i),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${String.fromCharCode(65 + i)} ${i < 2 ? "*" : "(optional)"}',
                            hintText: 'Option ${String.fromCharCode(65 + i)}',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          validator: i < 2
                              ? (val) => val == null || val.trim().isEmpty
                                  ? 'Option required'
                                  : null
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.sm),

                // Explanation
                TextFormField(
                  controller: _explanationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Explanation (optional)',
                    hintText: 'Why is this the correct answer?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save button
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save Question'),
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
