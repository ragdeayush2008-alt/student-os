import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/three_d_tilt_wrapper.dart';
import 'guide_controller.dart';
import 'guide_targets.dart';
import 'models/guide_models.dart';

/// Overlay host: inserts a single [OverlayEntry] showing [GuideOverlayView]
/// whenever a guide session is active. Managed centrally so feature screens
/// never host tutorial widgets themselves.
class GuideOverlayManager {
  GuideOverlayManager._();

  static OverlayEntry? _entry;
  static bool _listening = false;

  static void ensureListening() {
    if (_listening) {
      return;
    }
    _listening = true;
    GuideController.instance.addListener(_sync);
    _sync();
  }

  static void _sync() {
    final active = GuideController.instance.isActive;
    if (active && _entry == null) {
      final overlay = _overlayOf();
      if (overlay == null) {
        return;
      }
      _entry = OverlayEntry(builder: (_) => const GuideOverlayView());
      try {
        overlay.insert(_entry!);
      } catch (_) {
        _entry = null;
      }
    } else if (!active && _entry != null) {
      try {
        _entry!.remove();
      } catch (_) {}
      _entry = null;
    }
  }

  static OverlayState? _overlayOf() {
    try {
      final ctx = GuideController.instance.navContextForOverlay;
      if (ctx == null) {
        return null;
      }
      return Navigator.of(ctx, rootNavigator: true).overlay;
    } catch (_) {
      return null;
    }
  }
}

/// Full-screen guide overlay: dim + spotlight hole (taps pass through to
/// the REAL control), emerald glow ring, coach card, completion state.
class GuideOverlayView extends StatefulWidget {
  const GuideOverlayView({super.key});

  @override
  State<GuideOverlayView> createState() => _GuideOverlayViewState();
}

class _GuideOverlayViewState extends State<GuideOverlayView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  int _prevStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    GuideController.instance.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
      _syncPulse();
    }
  }

  bool get _isTest {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  void _syncPulse() {
    if (!mounted) {
      return;
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    // Never repeat forever in widget tests — pumpAndSettle must settle.
    if (reduce || _isTest) {
      if (_pulse.isAnimating) {
        _pulse.stop();
      }
      return;
    }
    if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    GuideController.instance.removeListener(_onChanged);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = GuideController.instance;
    final guide = controller.guide;
    final step = controller.currentStep;
    if (guide == null) {
      return const SizedBox.shrink();
    }
    if (controller.isCompleted) {
      return _CompletionView(guide: guide);
    }
    if (step == null) {
      return const SizedBox.shrink();
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _prevStepIndex = controller.stepIndex;

    Rect? target;
    if (step.targetAnchorId != null) {
      target = GuideTargetRegistry.instance.rectOf(step.targetAnchorId!);
    }

    return Semantics(
      label: 'Interactive guide: ${guide.title}, step ${controller.stepIndex + 1} of ${guide.steps.length}',
      child: Stack(
        children: [
          // Dim with a real hole: blockers cover everything EXCEPT the
          // target rect, so the underlying control stays tappable.
          if (target != null)
            ..._blockers(target)
          else
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Color(0x9908211C)),
              ),
            ),
          if (target != null) _SpotlightRing(target: target, pulse: _pulse),
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final card = _CoachCard(
                    guide: guide,
                    step: step,
                    stepNumber: controller.stepIndex + 1,
                    stepCount: guide.steps.length,
                    progress: controller.progressFraction,
                    reduceMotion: reduceMotion,
                  );

                  final cardWidget = AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(controller.stepIndex),
                      child: card,
                    ),
                  );

                  if (target == null) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        child: cardWidget,
                      ),
                    );
                  }
                  const cardHeight = 300.0;
                  final belowTop = target.bottom + 16;
                  final fitsBelow =
                      belowTop + cardHeight < constraints.maxHeight;
                  if (fitsBelow) {
                    return Stack(
                      children: [
                        Positioned(
                          top: belowTop,
                          left: AppSpacing.screen,
                          right: AppSpacing.screen,
                          child: cardWidget,
                        ),
                      ],
                    );
                  }
                  final aboveTop = (target.top - 16 - cardHeight)
                      .clamp(0.0, constraints.maxHeight - cardHeight);
                  return Stack(
                    children: [
                      Positioned(
                        top: aboveTop,
                        left: AppSpacing.screen,
                        right: AppSpacing.screen,
                        child: cardWidget,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Four absorbing blockers around the hole; taps show the step hint.
  List<Widget> _blockers(Rect target) {
    Widget blocker({
      double? left,
      double? top,
      double? right,
      double? bottom,
      double? width,
      double? height,
    }) {
      return Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: SizedBox(width: width, height: height),
        ),
      );
    }

    return [
      blocker(left: 0, top: 0, right: 0, height: target.top),
      blocker(left: 0, top: target.bottom, right: 0, bottom: 0),
      blocker(
          left: 0,
          top: target.top,
          width: target.left,
          height: target.height),
      blocker(
          left: target.right,
          top: target.top,
          right: 0,
          height: target.height),
      // Dim veil painted under the blockers (ignore pointer, hole cut out).
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _DimPainter(hole: target)),
        ),
      ),
    ];
  }
}

class _DimPainter extends CustomPainter {
  _DimPainter({required this.hole});

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0x9908211C);
    final full = Path()
      ..addRect(Offset.zero & size);
    final cut = Path()
      ..addRRect(
        RRect.fromRectAndRadius(hole.inflate(10), const Radius.circular(20)),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, cut),
      dim,
    );
  }

  @override
  bool shouldRepaint(covariant _DimPainter oldDelegate) =>
      oldDelegate.hole != hole;
}

class _SpotlightRing extends StatelessWidget {
  const _SpotlightRing({required this.target, required this.pulse});

  final Rect target;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final rect = target.inflate(10);
    return Positioned.fromRect(
      rect: rect,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final pulseValue = reduceMotion ? 0.0 : pulse.value;
          final glow = reduceMotion ? 0.30 : 0.24 + pulseValue * 0.14;
          return IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.sage.withValues(alpha: 0.9),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forest.withValues(alpha: glow),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.guide,
    required this.step,
    required this.stepNumber,
    required this.stepCount,
    required this.progress,
    required this.reduceMotion,
  });

  final GuideDefinition guide;
  final GuideStep step;
  final int stepNumber;
  final int stepCount;
  final double progress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final controller = GuideController.instance;
    final needsRealAction = switch (step.expectation) {
      GuideExpectationKind.screenSeen => false,
      GuideExpectationKind.continueTap => false,
      GuideExpectationKind.focusSessionStarted => true,
      GuideExpectationKind.sleepScheduleSaved => true,
      GuideExpectationKind.taskCreated => true,
      GuideExpectationKind.examCreated => true,
      GuideExpectationKind.planningBlockCreated => true,
    };

    return ThreeDTiltWrapper(
      reduceMotion: reduceMotion,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: palette.sage.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Semantics(
                    label: 'Step $stepNumber of $stepCount',
                    child: Text(
                      '$stepNumber / $stepCount',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guide.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.onSurfaceMuted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Exit guide',
                  onPressed: () => controller.exitGuide(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              step.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.onSurfaceMuted,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              needsRealAction
                  ? 'Do it in the app above — the guide moves when it happens.'
                  : step.hint,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.onSurfaceMuted.withValues(alpha: 0.85),
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: palette.sage.withValues(alpha: 0.25),
                valueColor:
                    AlwaysStoppedAnimation<Color>(palette.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (stepNumber > 1)
                  TextButton(
                    onPressed: () => controller.previousStep(),
                    child: const Text('Back'),
                  ),
                TextButton(
                  onPressed: () => controller.skipStep(),
                  child: Text(
                    stepNumber >= stepCount ? 'Finish' : 'Skip step',
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: needsRealAction
                      ? null
                      : () => controller.continueStep(),
                  child: Text(
                      stepNumber >= stepCount ? 'Done' : 'Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.guide});

  final GuideDefinition guide;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final controller = GuideController.instance;
    return Material(
      color: const Color(0x9908211C),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Semantics(
              label: 'Guide complete: ${guide.title}',
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: palette.sage.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.25),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.primary.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: palette.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'You’re ready.',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nicely done — you just learned ${guide.title}.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: palette.onSurfaceMuted),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => controller.restartGuide(),
                            child: const Text('Replay'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                controller.exitGuide(),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
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
