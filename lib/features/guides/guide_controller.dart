import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/sleep/sleep_controller.dart';
import '../../features/tasks/task_controller.dart';
import 'guide_navigator.dart';
import 'guide_progress_store.dart';
import 'guide_registry.dart';
import 'guide_targets.dart';
import 'models/guide_models.dart';

/// Active guide session state (learning layer only).
enum GuideSessionPhase {
  idle,
  navigating,
  guiding,
  completed,
}

/// Reusable interactive-guide engine.
///
/// Interprets [GuideDefinition]s: navigates to real screens via existing
/// [AppRouter] helpers, spotlights real controls via [GuideTargetAnchor] ids,
/// and verifies real actions against live controllers. Never duplicates
/// feature logic and never claims completion the user didn't earn.
class GuideController extends ChangeNotifier {
  GuideController._();

  static final GuideController instance = GuideController._();

  GuideDefinition? _guide;
  int _stepIndex = 0;
  GuideSessionPhase _phase = GuideSessionPhase.idle;
  bool _waitingForTarget = false;
  bool _disposed = false;
  final List<Timer> _pendingTimers = [];

  // Baselines captured when a count-based step starts.
  int _taskBaseline = 0;
  int _examBaseline = 0;
  int _blockBaseline = 0;

  /// Invalidated whenever the session moves on, so stale anchor waits can
  /// never fire (and never leak pending timers past test teardown).
  int _waitToken = 0;

  GuideDefinition? get guide => _guide;
  GuideSessionPhase get phase => _phase;
  bool get isActive => _guide != null && _phase != GuideSessionPhase.idle;
  bool get isCompleted =>
      _guide != null && _phase == GuideSessionPhase.completed;

  int get stepIndex => _stepIndex;

  GuideStep? get currentStep {
    final g = _guide;
    if (g == null || _stepIndex < 0 || _stepIndex >= g.steps.length) {
      return null;
    }
    return g.steps[_stepIndex];
  }

  double get progressFraction {
    final g = _guide;
    if (g == null || g.steps.isEmpty) {
      return 0;
    }
    if (_phase == GuideSessionPhase.completed) {
      return 1;
    }
    return _stepIndex / g.steps.length;
  }

  bool get waitingForTarget => _waitingForTarget;

  BuildContext? get _navContext => AppRouter.navigatorKey.currentContext;

  /// Context for overlay insertion (same navigator context, nullable).
  BuildContext? get navContextForOverlay =>
      AppRouter.navigatorKey.currentContext;

  /// Starts (or resumes) a guide. Safe to call when another guide is active:
  /// the previous session is exited first (progress preserved).
  Future<void> startGuide(String guideId) async {
    final def = GuideRegistry.byId(guideId);
    if (def == null || def.steps.isEmpty) {
      return;
    }
    if (isActive) {
      await exitGuide();
    }
    await GuideProgressStore.instance.load();
    final saved =
        GuideProgressStore.instance.progressOf(guideId);
    _guide = def;
    if (saved.status == GuideStatus.inProgress &&
        saved.stepIndex >= 0 &&
        saved.stepIndex < def.steps.length) {
      _stepIndex = saved.stepIndex;
    } else {
      _stepIndex = 0;
      await GuideProgressStore.instance.saveProgress(
        guideId,
        const GuideProgress(
            status: GuideStatus.inProgress, stepIndex: 0),
      );
    }
    _attachListeners();
    _notify();
    _enterStep();
  }

  /// Advances from a Continue press. State-backed expectations ignore this
  /// (they auto-advance on real detection) — pressing Continue there is a
  /// no-op, never a fake completion.
  Future<void> continueStep() async {
    final step = currentStep;
    if (!isActive || step == null || _phase != GuideSessionPhase.guiding) {
      return;
    }
    switch (step.expectation) {
      case GuideExpectationKind.screenSeen:
      case GuideExpectationKind.continueTap:
        await _advance();
        break;
      case GuideExpectationKind.focusSessionStarted:
      case GuideExpectationKind.sleepScheduleSaved:
      case GuideExpectationKind.taskCreated:
      case GuideExpectationKind.examCreated:
      case GuideExpectationKind.planningBlockCreated:
        // Real detection only — no-op to avoid fake completion claims.
        break;
    }
  }

  /// Skips the current step without verifying it. Progress records the skip
  /// position honestly (status stays inProgress).
  Future<void> skipStep() async {
    if (!isActive) {
      return;
    }
    await _advance();
  }

  /// Goes back one step (coach-card Back button). Position persists so
  /// resume lands on the revisited step. No-op on the first step.
  Future<void> previousStep() async {
    final g = _guide;
    if (!isActive ||
        g == null ||
        _stepIndex <= 0 ||
        _phase == GuideSessionPhase.completed) {
      return;
    }
    _cancelPendingTimers();
    _waitToken++;
    _stepIndex -= 1;
    await GuideProgressStore.instance.saveProgress(
      g.id,
      GuideProgress(status: GuideStatus.inProgress, stepIndex: _stepIndex),
    );
    _notify();
    _enterStep();
  }

  Future<void> restartGuide() async {
    final g = _guide;
    if (g == null) {
      return;
    }
    _stepIndex = 0;
    await GuideProgressStore.instance.saveProgress(
      g.id,
      const GuideProgress(status: GuideStatus.inProgress, stepIndex: 0),
    );
    _notify();
    _enterStep();
  }

  /// Exits now, preserving the current position for resume.
  Future<void> exitGuide() async {
    final g = _guide;
    if (g == null) {
      return;
    }
    if (_phase != GuideSessionPhase.completed) {
      await GuideProgressStore.instance.saveProgress(
        g.id,
        GuideProgress(status: GuideStatus.inProgress, stepIndex: _stepIndex),
      );
    }
    _detachListeners();
    _cancelPendingTimers();
    _waitToken++;
    _guide = null;
    _stepIndex = 0;
    _phase = GuideSessionPhase.idle;
    _waitingForTarget = false;
    _notify();
  }

  // ─── internals ─────────────────────────────────────────────────

  Future<void> _advance() async {
    final g = _guide;
    if (g == null) {
      return;
    }
    _cancelPendingTimers();
    _waitToken++;
    if (_stepIndex + 1 >= g.steps.length) {
      await _complete();
      return;
    }
    _stepIndex += 1;
    await GuideProgressStore.instance.saveProgress(
      g.id,
      GuideProgress(status: GuideStatus.inProgress, stepIndex: _stepIndex),
    );
    _notify();
    _enterStep();
  }

  Future<void> _complete() async {
    final g = _guide;
    if (g == null) {
      return;
    }
    _cancelPendingTimers();
    _waitToken++;
    _phase = GuideSessionPhase.completed;
    await GuideProgressStore.instance.saveProgress(
      g.id,
      GuideProgress(
          status: GuideStatus.completed, stepIndex: g.steps.length),
    );
    if (g.id == 'quick_tour') {
      await GuideProgressStore.instance.setTourState('completed');
    }
    _notify();
  }

  /// Enters the current step synchronously. The phase is guiding
  /// immediately (the overlay shows a fallback card until the anchor
  /// resolves); anchor settling runs in the background and only triggers
  /// re-resolves, so callers never block on timers.
  void _enterStep() {
    _cancelPendingTimers();
    final step = currentStep;
    final ctx = _navContext;
    if (step == null || ctx == null) {
      _phase = GuideSessionPhase.guiding;
      _waitingForTarget = false;
      _notify();
      return;
    }
    _captureBaselines(step);
    if (step.destination != null && step.navigateOnEnter) {
      try {
        GuideNavigator.open(ctx, step.destination!);
      } catch (_) {
        // Navigation must never break a guide; the overlay falls back
        // to coach-card mode on the current screen.
      }
      _phase = GuideSessionPhase.guiding;
      _waitingForTarget = step.targetAnchorId != null &&
          GuideTargetRegistry.instance.rectOf(step.targetAnchorId!) ==
              null;
      _notify();
      final enteredId = step.id;
      final token = ++_waitToken;
      _settleTarget(step, token, enteredId);
      // Re-check expectations immediately (e.g. schedule already exists).
      _evaluateStateExpectations();
      return;
    }
    _phase = GuideSessionPhase.guiding;
    _waitingForTarget = false;
    _notify();
    // Steps that stay on the current screen still verify immediately, so a
    // pre-satisfied expectation (existing schedule) advances without input.
    _evaluateStateExpectations();
  }

  void _captureBaselines(GuideStep step) {
    switch (step.expectation) {
      case GuideExpectationKind.taskCreated:
        _taskBaseline = _safeCount(() => TaskController.instance.tasks.length);
        break;
      case GuideExpectationKind.examCreated:
        _examBaseline =
            _safeCount(() => ExamController.instance.exams.length);
        break;
      case GuideExpectationKind.planningBlockCreated:
        _blockBaseline =
            _safeCount(() => PlanningBlockController.instance.blocks.length);
        break;
      case GuideExpectationKind.screenSeen:
      case GuideExpectationKind.continueTap:
      case GuideExpectationKind.focusSessionStarted:
      case GuideExpectationKind.sleepScheduleSaved:
        break;
    }
  }

  int _safeCount(int Function() read) {
    try {
      return read();
    } catch (_) {
      return 0;
    }
  }

  /// Re-resolves the anchor a few times after navigation so the spotlight
  /// appears once the destination builds. Never blocks callers; aborts on
  /// step change / exit. Missing anchors stay in fallback card mode.
  ///
  /// Uses cancellable [Timer]s (not bare futures) so no pending timer can
  /// outlive the session — including under widget-test invariants.
  void _settleTarget(GuideStep step, int token, String enteredId) {
    final anchorId = step.targetAnchorId;
    if (anchorId == null) {
      return;
    }
    var attempt = 0;
    void schedule(int ms) {
      late final Timer timer;
      timer = Timer(Duration(milliseconds: ms), () {
        _pendingTimers.remove(timer);
        if (_disposed ||
            !isActive ||
            token != _waitToken ||
            currentStep?.id != enteredId) {
          return;
        }
        if (GuideTargetRegistry.instance.rectOf(anchorId) != null) {
          _waitingForTarget = false;
          _notify();
          return;
        }
        attempt += 1;
        if (attempt >= 3) {
          _waitingForTarget = false;
          _notify();
          return;
        }
        schedule(attempt == 1 ? 800 : 1200);
      });
      _pendingTimers.add(timer);
    }

    schedule(450);
  }

  void _cancelPendingTimers() {
    for (final t in _pendingTimers) {
      try {
        t.cancel();
      } catch (_) {}
    }
    _pendingTimers.clear();
  }

  // ─── live detection ────────────────────────────────────────────

  bool _listening = false;

  void _attachListeners() {
    if (_listening) {
      return;
    }
    _listening = true;
    try {
      FocusController.instance.addListener(_evaluateStateExpectations);
    } catch (_) {}
    try {
      SleepController.instance.addListener(_evaluateStateExpectations);
    } catch (_) {}
    try {
      TaskController.instance.addListener(_evaluateStateExpectations);
    } catch (_) {}
    try {
      ExamController.instance.addListener(_evaluateStateExpectations);
    } catch (_) {}
    try {
      PlanningBlockController.instance
          .addListener(_evaluateStateExpectations);
    } catch (_) {}
  }

  void _detachListeners() {
    if (!_listening) {
      return;
    }
    _listening = false;
    try {
      FocusController.instance.removeListener(_evaluateStateExpectations);
    } catch (_) {}
    try {
      SleepController.instance.removeListener(_evaluateStateExpectations);
    } catch (_) {}
    try {
      TaskController.instance.removeListener(_evaluateStateExpectations);
    } catch (_) {}
    try {
      ExamController.instance.removeListener(_evaluateStateExpectations);
    } catch (_) {}
    try {
      PlanningBlockController.instance
          .removeListener(_evaluateStateExpectations);
    } catch (_) {}
  }

  void _evaluateStateExpectations() {
    final step = currentStep;
    if (!isActive ||
        step == null ||
        _phase == GuideSessionPhase.completed) {
      return;
    }
    var satisfied = false;
    try {
      switch (step.expectation) {
        case GuideExpectationKind.screenSeen:
        case GuideExpectationKind.continueTap:
          return;
        case GuideExpectationKind.focusSessionStarted:
          satisfied = FocusController.instance.hasActiveSession;
          break;
        case GuideExpectationKind.sleepScheduleSaved:
          satisfied = SleepController.instance.hasSchedule;
          break;
        case GuideExpectationKind.taskCreated:
          satisfied =
              TaskController.instance.tasks.length > _taskBaseline;
          break;
        case GuideExpectationKind.examCreated:
          satisfied =
              ExamController.instance.exams.length > _examBaseline;
          break;
        case GuideExpectationKind.planningBlockCreated:
          satisfied = PlanningBlockController.instance.blocks.length >
              _blockBaseline;
          break;
      }
    } catch (_) {
      return;
    }
    if (satisfied) {
      // Defer to avoid re-entrancy inside controller notification.
      Future.microtask(() async {
        if (!isActive || currentStep?.id != step.id) {
          return;
        }
        await _advance();
      });
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelPendingTimers();
    _detachListeners();
    super.dispose();
  }
}
