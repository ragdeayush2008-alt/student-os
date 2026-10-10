import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/assistant/assistant_launch_context.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/intelligence/academic_knowledge_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/topic.dart';
import '../../../data/models/topic_practice_attempt.dart';
import '../../study/study_controller.dart';
import '../../subjects/subject_controller.dart';
import '../academic_knowledge_controller.dart';
import '../practice_question_controller.dart';
import '../topic_practice_controller.dart';
import 'practice_mode_selection_sheet.dart';

/// Dedicated Practice Center workspace.
///
/// Features:
/// - Overall practice performance & statistics
/// - Recommended practice targets based on academic intelligence
/// - Weak topic detection & targeted intervention
/// - Truthful historical practice attempts log
/// - Subject and topic practice launcher
class PracticeCenterScreen extends StatefulWidget {
  const PracticeCenterScreen({super.key});

  @override
  State<PracticeCenterScreen> createState() => _PracticeCenterScreenState();
}

class _PracticeCenterScreenState extends State<PracticeCenterScreen> {
  @override
  void initState() {
    super.initState();
    TopicPracticeController.instance.addListener(_onChanged);
    PracticeQuestionController.instance.addListener(_onChanged);
    AcademicKnowledgeController.instance.addListener(_onChanged);
    SubjectController.instance.addListener(_onChanged);
    StudyController.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    TopicPracticeController.instance.removeListener(_onChanged);
    PracticeQuestionController.instance.removeListener(_onChanged);
    AcademicKnowledgeController.instance.removeListener(_onChanged);
    SubjectController.instance.removeListener(_onChanged);
    StudyController.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subjects = SubjectController.instance.activeSubjects;
    final allTopics = AcademicKnowledgeController.instance.topics;
    final sessions = StudyController.instance.sessions;
    final practiceAttempts = TopicPracticeController.instance.attempts;

    // Derived statistics
    final totalAttempts = practiceAttempts.length;
    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalSec = 0;
    for (final a in practiceAttempts) {
      totalSec += a.durationSec;
      if (a.totalQuestions != null && a.totalQuestions! > 0) {
        totalQuestions += a.totalQuestions!;
        totalCorrect += (a.correctAnswers ?? 0);
      }
    }
    final int? avgAccuracy = totalQuestions > 0
        ? ((totalCorrect / totalQuestions) * 100).round().clamp(0, 100)
        : null;
    final totalMins = totalSec ~/ 60;

    // Recommended topics
    final recommendedTopics =
        AcademicKnowledgeEngine.getRecommendedPracticeTopics(
      topics: allTopics,
      sessions: sessions,
      practiceAttempts: practiceAttempts,
    );
    final topRecommendation = recommendedTopics.firstOrNull;

    // Weak topics
    final weakTopics = AcademicKnowledgeEngine.getWeakTopics(
      topics: allTopics,
      sessions: sessions,
      practiceAttempts: practiceAttempts,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice & Quiz Center'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Assistant',
            onPressed: () => AppRouter.openAssistant(
              context,
              initialQuery: 'What should I practice?',
              launchContext: const AssistantLaunchContext(
                origin: AssistantOrigin.study,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Hero Header ──────────────────────────────────────────────
            Text(
              'PRACTICE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sharpen what you know.',
              style: context.text.headlineSmall!.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Overall Stats Grid ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Attempts',
                    value: '$totalAttempts',
                    subtitle: 'Completed sessions',
                    icon: Icons.quiz_outlined,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: 'Questions',
                    value: '$totalQuestions',
                    subtitle: '$totalCorrect correct',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Accuracy',
                    value: avgAccuracy != null ? '$avgAccuracy%' : '—',
                    subtitle: avgAccuracy != null
                        ? (avgAccuracy >= 75 ? 'Strong recall' : 'Needs attention')
                        : 'No quiz data yet',
                    icon: Icons.percent_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: 'Practice Time',
                    value: '${totalMins}m',
                    subtitle: 'Active problem solving',
                    icon: Icons.timer_outlined,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Recommended Practice Hero Card ───────────────────────────
            if (topRecommendation != null) ...[
              _SectionHeader(
                title: 'RECOMMENDED PRACTICE',
                icon: Icons.auto_awesome_rounded,
                color: palette.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                borderColor: palette.primary.withValues(alpha: 0.35),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topRecommendation.topic.title,
                                style: context.text.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topRecommendation.recommendationReason ??
                                    'Reinforce retention with questions.',
                                style: context.text.bodySmall!.copyWith(
                                  color: palette.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            PracticeModeSelectionSheet.show(
                              context,
                              topic: topRecommendation.topic,
                            );
                          },
                          child: const Text('START'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Needs Practice / Weak Topics ─────────────────────────────
            if (weakTopics.isNotEmpty) ...[
              _SectionHeader(
                title: 'NEEDS PRACTICE',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final weak in weakTopics.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    onTap: () {
                      PracticeModeSelectionSheet.show(
                        context,
                        topic: weak.topic,
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.priority_high_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                weak.topic.title,
                                style: context.text.titleSmall!.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                weak.weakTopicReason ?? 'Needs practice',
                                style: context.text.bodySmall!.copyWith(
                                  color: palette.onSurfaceMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Recent Practice History ──────────────────────────────────
            _SectionHeader(
              title: 'RECENT ATTEMPTS',
              icon: Icons.history_rounded,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.sm),

            if (practiceAttempts.isEmpty) ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 32,
                        color: palette.onSurfaceMuted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No practice attempts yet.',
                        style: context.text.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Complete a practice session or record problem solving to build your history.',
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              for (final attempt in practiceAttempts.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _HistoryAttemptCard(attempt: attempt),
                ),
            ],
            const SizedBox(height: AppSpacing.xl),

            // ── Browse All Topics by Subject ─────────────────────────────
            _SectionHeader(
              title: 'BROWSE BY SUBJECT',
              icon: Icons.menu_book_rounded,
              color: palette.onSurface,
            ),
            const SizedBox(height: AppSpacing.sm),

            if (subjects.isEmpty) ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Add subjects in your academic curriculum to organize practice topics.',
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ),
            ] else ...[
              for (final subject in subjects) ...[
                _SubjectPracticeGroup(
                  subject: subject,
                  topics: AcademicKnowledgeController.instance.topicsForSubject(subject.id),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.text.titleLarge!.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HistoryAttemptCard extends StatelessWidget {
  const _HistoryAttemptCard({required this.attempt});

  final TopicPracticeAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final topic = AcademicKnowledgeController.instance.topicById(attempt.topicId);
    final subject = attempt.subjectId != null
        ? SubjectController.instance.subjectById(attempt.subjectId!)
        : null;

    final acc = attempt.accuracyPercentage;
    final mins = attempt.durationSec ~/ 60;
    final now = DateTime.now();
    final days = now.difference(attempt.startedAt).inDays;
    final dateLabel = days == 0 ? 'Today' : (days == 1 ? 'Yesterday' : '${days}d ago');

    Color accColor = palette.primary;
    if (acc != null) {
      if (acc >= 80) {
        accColor = AppColors.success;
      } else if (acc >= 60) {
        accColor = AppColors.warning;
      } else {
        accColor = AppColors.error;
      }
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (acc != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '$acc%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accColor,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 16,
                color: palette.onSurfaceMuted,
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic?.title ?? (attempt.notes.isNotEmpty ? attempt.notes : 'Practice Attempt'),
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${subject?.displayName ?? "Curriculum"} • $dateLabel • ${mins > 0 ? "${mins}m" : "${attempt.durationSec}s"}${attempt.totalQuestions != null ? " • ${attempt.totalQuestions} questions" : ""}',
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
    );
  }
}

class _SubjectPracticeGroup extends StatelessWidget {
  const _SubjectPracticeGroup({
    required this.subject,
    required this.topics,
  });

  final Subject subject;
  final List<Topic> topics;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject.displayName,
            style: context.text.titleSmall!.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (topics.isEmpty)
            Text(
              'No topics defined for this subject.',
              style: context.text.bodySmall!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            )
          else
            for (final topic in topics) ...[
              InkWell(
                onTap: () {
                  PracticeModeSelectionSheet.show(context, topic: topic);
                },
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 16,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          topic.title,
                          style: context.text.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Practice',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: palette.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
