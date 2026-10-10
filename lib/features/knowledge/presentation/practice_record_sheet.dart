import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/topic.dart';
import '../topic_practice_controller.dart';

/// Sheet to record a completed practice attempt on a topic.
class PracticeRecordSheet extends StatefulWidget {
  const PracticeRecordSheet({
    super.key,
    required this.topic,
  });

  final Topic topic;

  static Future<void> show(BuildContext context, Topic topic) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PracticeRecordSheet(topic: topic),
    );
  }

  @override
  State<PracticeRecordSheet> createState() => _PracticeRecordSheetState();
}

class _PracticeRecordSheetState extends State<PracticeRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController(text: '20');
  final _questionsController = TextEditingController();
  final _correctController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _durationController.dispose();
    _questionsController.dispose();
    _correctController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _saving = true);
    final durationMins = int.tryParse(_durationController.text.trim()) ?? 20;
    final totalQ = int.tryParse(_questionsController.text.trim());
    final correctQ = int.tryParse(_correctController.text.trim());
    final incorrectQ = (totalQ != null && correctQ != null)
        ? (totalQ - correctQ).clamp(0, totalQ)
        : null;
    final notes = _notesController.text.trim();

    double? score;
    if (totalQ != null && totalQ > 0 && correctQ != null) {
      score = ((correctQ / totalQ) * 100).clamp(0.0, 100.0);
    }

    try {
      final attempt = await TopicPracticeController.instance.recordAttempt(
        topicId: widget.topic.id,
        subjectId: widget.topic.subjectId,
        chapterId: widget.topic.chapterId,
        durationSec: durationMins * 60,
        totalQuestions: totalQ,
        correctAnswers: correctQ,
        incorrectAnswers: incorrectQ,
        score: score,
        notes: notes,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              attempt.accuracyPercentage != null
                  ? 'Practice recorded! Accuracy: ${attempt.accuracyPercentage}% (+XP awarded)'
                  : 'Practice session recorded! (+XP awarded)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record practice: $e')),
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
                  'Record Practice Attempt',
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

                // Duration Input
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    hintText: '20',
                    prefixIcon: Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter duration in minutes';
                    }
                    final n = int.tryParse(val.trim());
                    if (n == null || n <= 0) return 'Duration must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Question & Correct Count Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _questionsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Total Questions (optional)',
                          hintText: 'e.g. 10',
                          prefixIcon: Icon(Icons.quiz_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _correctController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Correct Answers',
                          hintText: 'e.g. 8',
                          prefixIcon: Icon(Icons.check_circle_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val != null && val.isNotEmpty) {
                            final c = int.tryParse(val);
                            final q = int.tryParse(_questionsController.text);
                            if (c != null && q != null && c > q) {
                              return 'Cannot exceed total';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Practice Notes (optional)',
                    hintText: 'e.g. Solved exercise questions, struggled with formula',
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Recording...' : 'Save Practice Attempt'),
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
