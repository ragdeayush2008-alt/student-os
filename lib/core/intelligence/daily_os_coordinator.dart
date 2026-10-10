import 'package:flutter/foundation.dart';

import '../intelligence/daily_academic_snapshot.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/subjects/subject_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/study/study_controller.dart';

/// Reactive coordinator for Daily OS derived state.
/// Subscribes to real controllers; derives snapshot; never mutates data.
class DailyOsCoordinator extends ChangeNotifier {
  DailyOsCoordinator._();
  static final DailyOsCoordinator instance = DailyOsCoordinator._();

  DailyAcademicSnapshot? _snapshot;
  bool _disposed = false;
  bool _initialized = false;

  DailyAcademicSnapshot? get snapshot => _snapshot;

  /// Initialize listeners from existing controllers.
  ///
  /// Idempotent: safe to call multiple times (e.g. when a Home tab is
  /// recreated) without registering duplicate listeners. The coordinator is a
  /// shared singleton and must remain alive for the app's lifetime; call
  /// [clearOnLogout] on session change instead of disposing it.
  void init() {
    if (_initialized) return;
    _initialized = true;
    _rebuild();
    TaskController.instance.addListener(_onTaskChanged);
    FocusController.instance.addListener(_onFocusChanged);
    StudyController.instance.addListener(_onStudyChanged);
    ExamController.instance.addListener(_onExamChanged);
    SubjectController.instance.addListener(_onSubjectChanged);
  }

  void _onTaskChanged() => _rebuild();
  DateTime? _lastFocusRebuild;

  /// FocusController ticks every second while a session runs. Collapsing those
  /// ticks here keeps Home (and every coordinator listener) free of
  /// per-second rebuilds: session start/end flips [hasActiveFocus] and always
  /// rebuilds immediately, while minute-level metric drift refreshes at most
  /// every 15 seconds. Task/study/exam mutations still rebuild instantly via
  /// their own listeners.
  void _onFocusChanged() {
    final flipped =
        _snapshot != null &&
        _snapshot!.hasActiveFocus != FocusController.instance.hasActiveSession;
    final now = DateTime.now();
    if (!flipped &&
        _lastFocusRebuild != null &&
        now.difference(_lastFocusRebuild!) < const Duration(seconds: 15)) {
      return;
    }
    _lastFocusRebuild = now;
    _rebuild();
  }

  void _onStudyChanged() => _rebuild();
  void _onExamChanged() => _rebuild();
  void _onSubjectChanged() => _rebuild();

  void _rebuild() {
    if (_disposed) return;
    final prev = _snapshot;
    try {
      _snapshot = DailyAcademicSnapshot.fromControllers();
    } catch (_) {
      // Never crash Home because one module has no data; keep last snapshot.
      return;
    }
    // Only notify if semantically changed (stable equality via fields).
    // Covers NOW/NEXT identity, counts, focus presence, progress and exam.
    if (prev == null ||
        prev.nowAction?.id != _snapshot!.nowAction?.id ||
        prev.nextAction?.id != _snapshot!.nextAction?.id ||
        prev.completedToday != _snapshot!.completedToday ||
        prev.todayTaskCount != _snapshot!.todayTaskCount ||
        prev.overdueCount != _snapshot!.overdueCount ||
        prev.focusMinutesToday != _snapshot!.focusMinutesToday ||
        prev.studyMinutesToday != _snapshot!.studyMinutesToday ||
        prev.hasActiveFocus != _snapshot!.hasActiveFocus ||
        prev.upcomingExamDays != _snapshot!.upcomingExamDays ||
        (prev.completionRatio - _snapshot!.completionRatio).abs() > 0.001) {
      if (!_disposed) notifyListeners();
    }
  }

  /// Force rebuild (e.g., after explicit user action confirmation).
  void refresh() => _rebuild();

  /// Clear derived state on user switch/logout; unsubscribe after.
  void clearOnLogout() {
    _snapshot = null;
    _initialized = false;
    if (_disposed) return;
    try {
      TaskController.instance.removeListener(_onTaskChanged);
    } catch (_) {}
    try {
      FocusController.instance.removeListener(_onFocusChanged);
    } catch (_) {}
    try {
      StudyController.instance.removeListener(_onStudyChanged);
    } catch (_) {}
    try {
      ExamController.instance.removeListener(_onExamChanged);
    } catch (_) {}
    try {
      SubjectController.instance.removeListener(_onSubjectChanged);
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    clearOnLogout();
    super.dispose();
  }
}
