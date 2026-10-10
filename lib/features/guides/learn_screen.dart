import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import 'guide_controller.dart';
import 'guide_overlay.dart';
import 'guide_progress_store.dart';
import 'guide_registry.dart';
import 'models/guide_models.dart';

/// Permanent "Learn Student OS" center (learning layer only).
///
/// Premium grouped catalog: progressive unlocking, live completion states,
/// continue/restart/replay. Entry points: Settings, Assistant, contextual
/// help buttons. Starting a guide navigates into the REAL feature.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  @override
  void initState() {
    super.initState();
    GuideProgressStore.instance.load();
    GuideProgressStore.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    GuideProgressStore.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final store = GuideProgressStore.instance;
    final inProgress = GuideRegistry.all.where((g) {
      final p = store.progressOf(g.id);
      return p.status == GuideStatus.inProgress && p.stepIndex > 0;
    }).toList();

    return AppScaffold(
      title: 'Learn Student OS',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Learn by doing.',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Interactive guides that take you directly into Student OS.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (inProgress.isNotEmpty) ...[
                  const AppSectionHeader(title: 'Continue learning'),
                  const SizedBox(height: AppSpacing.xs),
                  for (final g in inProgress)
                    _GuideCard(
                      guide: g,
                      progress: store.progressOf(g.id),
                      unlocked: true,
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final category in GuideCategory.values) ...[
                  AppSectionHeader(title: category.label),
                  const SizedBox(height: AppSpacing.xs),
                  for (final g in GuideRegistry.inCategory(category))
                    _GuideCard(
                      guide: g,
                      progress: store.progressOf(g.id),
                      unlocked: GuideRegistry.isUnlocked(
                          g, store.all),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.guide,
    required this.progress,
    required this.unlocked,
  });

  final GuideDefinition guide;
  final GuideProgress progress;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final completed = progress.status == GuideStatus.completed;
    final started = progress.status == GuideStatus.inProgress;
    return Semantics(
      button: unlocked,
      label:
          '${guide.title}. ${guide.description}. ${completed ? 'Completed' : started ? 'In progress' : unlocked ? 'Not started' : 'Locked until basics are complete'}.',
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: completed
                  ? palette.primary.withValues(alpha: 0.5)
                  : palette.sage.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(
                    alpha: completed ? 0.12 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: unlocked
                  ? () {
                      // Start first: the guide navigates to the real feature
                      // and covers Learn. Learn stays underneath, so Back
                      // returns here. Never pop-then-start (that strands
                      // the session without a context and looks broken).
                      GuideOverlayManager.ensureListening();
                      GuideController.instance.startGuide(guide.id);
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            palette.primary.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        completed
                            ? Icons.check_rounded
                            : unlocked
                                ? Icons.play_arrow_rounded
                                : Icons.lock_outline_rounded,
                        color: palette.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guide.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            guide.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: palette.onSurfaceMuted,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${guide.durationLabel} · ${started && !completed ? 'Step ${progress.stepIndex + 1}/${guide.steps.length} · ' : ''}${completed ? 'Completed · Replay' : started ? 'Continue' : unlocked ? 'Start' : 'Complete basics to unlock'}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: palette.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
