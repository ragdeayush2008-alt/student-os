import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/services/xp_engine.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/auth/auth_isolation.dart';
import '../../../features/auth/auth_service.dart';
import '../../../features/progression/progression_controller.dart';
import '../../../features/notifications/notification_controller.dart';
import '../../../features/study/study_controller.dart';
import '../../../features/tasks/task_controller.dart';
import '../data/models/focus_mission.dart';
import '../data/models/focus_models.dart';

class FocusController extends ChangeNotifier {
  FocusController._();

  static final FocusController instance = FocusController._();

  DateTime Function() _clock = DateTime.now;

  @visibleForTesting
  void setClockForTesting(DateTime Function() clock) {
    _clock = clock;
  }

  @visibleForTesting
  void resetClockForTesting() {
    _clock = DateTime.now;
  }

  void clearData() {
    _stopTicker();
    for (final t in _checkpointTimers) {
      t.cancel();
    }
    _checkpointTimers.clear();
    _prepTimer?.cancel();
    _prepTimer = null;
    _sessions.clear();
    _distractions.clear();
    _checkpoints.clear();
    _insights.clear();
    _activeSession = null;
    _loaded = false;
    _counter = 0;
    if (!_disposed) notifyListeners();
  }

  static const _focusSessionsKey = 'focus_sessions';
  static const _distractionsKey = 'focus_distractions';
  static const _activeSessionKey = 'focus_active_session';
  static const _checkpointsKey = 'focus_checkpoints';
  static const _insightsKey = 'focus_insights';

  List<FocusSession> _sessions = [];
  List<DistractionCapture> _distractions = [];
  List<FocusCheckpoint> _checkpoints = [];
  List<FocusInsight> _insights = [];
  FocusSession? _activeSession;
  bool _loaded = false;
  bool _disposed = false;
  Timer? _tickTimer;
  Timer? _prepTimer;
  final List<Timer> _checkpointTimers = [];
  int _counter = 0;

  List<FocusSession> get sessions => List.unmodifiable(_sessions);
  List<DistractionCapture> get distractions => List.unmodifiable(_distractions);
  List<FocusCheckpoint> get checkpoints => List.unmodifiable(_checkpoints);
  List<FocusInsight> get insights => List.unmodifiable(_insights);
  FocusSession? get activeSession => _activeSession;
  bool get hasActiveSession =>
      _activeSession != null && _activeSession!.isActive;
  bool get isLoaded => _loaded;

  FocusState get state => _activeSession?.status ?? FocusState.idle;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );
  int get _nextId => ++_counter;

  Duration get activeElapsed {
    final session = _activeSession;
    if (session == null) return Duration.zero;
    return session.effectiveElapsedAt(_clock());
  }

  Duration get activeRemaining {
    final session = _activeSession;
    if (session == null || session.mode == FocusMode.stopwatch) {
      return Duration.zero;
    }
    final rem = session.plannedDuration.inSeconds - session.effectiveElapsedAt(_clock()).inSeconds;
    return Duration(seconds: rem > 0 ? rem : 0);
  }

  double get activeProgress {
    final session = _activeSession;
    if (session == null || session.mode == FocusMode.stopwatch) return 0.0;
    final planned = session.plannedDuration.inSeconds;
    if (planned <= 0) return 0.0;
    return (session.effectiveElapsedAt(_clock()).inSeconds / planned).clamp(0.0, 1.0);
  }

  Future<void> load() async {
    _stopTicker();

    // Unknown identity → memory-only: preserve in-memory state, mark loaded,
    // never touch a shared fallback namespace, and stay side-effect-free
    // (no notify) so this is safe from initState/build paths.
    final uid = _userId;
    if (uid == null) {
      _loaded = true;
      return;
    }

    try {
      final sessionList = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _focusSessionsKey,
      );
      if (sessionList != null) {
        _sessions =
            sessionList
                .whereType<Map<String, dynamic>>()
                .map((j) {
                  try {
                    final id = j['id'];
                    if (id == null || (id is String && id.isEmpty)) {
                      return null;
                    }
                    return FocusSession.fromJson(j);
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<FocusSession>()
                .toList()
              ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      } else {
        _sessions = [];
      }
      _counter = _sessions.length;

      final distList = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _distractionsKey,
      );
      if (distList != null) {
        _distractions =
            distList
                .whereType<Map<String, dynamic>>()
                .map((j) {
                  try {
                    return DistractionCapture.fromJson(j);
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<DistractionCapture>()
                .toList()
              ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      } else {
        _distractions = [];
      }

      final ckptList = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _checkpointsKey,
      );
      if (ckptList != null) {
        _checkpoints =
            ckptList
                .whereType<Map<String, dynamic>>()
                .map((j) {
                  try {
                    return FocusCheckpoint.fromJson(j);
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<FocusCheckpoint>()
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else {
        _checkpoints = [];
      }

      final insightList = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _insightsKey,
      );
      if (insightList != null) {
        _insights = insightList
            .whereType<Map<String, dynamic>>()
            .map((j) {
              try {
                return FocusInsight.fromJson(j);
              } catch (_) {
                return null;
              }
            })
            .whereType<FocusInsight>()
            .toList();
      } else {
        _insights = [];
      }

      final activeJson = await StorageService.instance.loadJson(
        userId: uid,
        key: _activeSessionKey,
      );
      if (activeJson != null) {
        try {
          final restored = FocusSession.fromJson(
            Map<String, dynamic>.from(activeJson),
          );
          if (restored.outcome == null && restored.isActive) {
            final now = _clock();
            if (restored.mode != FocusMode.stopwatch &&
                !restored.isPaused &&
                restored.effectiveElapsedAt(now) >= restored.plannedDuration) {
              restored.endedAt = restored.startedAt.add(
                restored.plannedDuration + restored.totalPausedDuration,
              );
              restored.actualDuration = restored.plannedDuration;
              restored.outcome = SessionOutcome.completed;
              restored.status = FocusState.completed;
              restored.phase = FocusPhase.completed;
              _calculateScore(restored);
              _sessions.insert(0, restored);
              await _saveSessions();
              await _clearActiveSession();
              _handleCompletion(restored);
              _generateInsights(restored);
              _activeSession = null;
            } else {
              _activeSession = restored;
              if (!restored.isPaused) {
                _startTicker();
              }
            }
          } else {
            await _clearActiveSession();
            _activeSession = null;
          }
        } catch (_) {
          await _clearActiveSession();
          _activeSession = null;
        }
      } else {
        _activeSession = null;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FocusController] load error: $e\n$st');
      }
    } finally {
      _loaded = true;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _saveSessions() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _focusSessionsKey,
      list: _sessions.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> _saveDistractions() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _distractionsKey,
      list: _distractions.map((d) => d.toJson()).toList(),
    );
  }

  Future<void> _saveCheckpoints() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _checkpointsKey,
      list: _checkpoints.map((c) => c.toJson()).toList(),
    );
  }

  Future<void> _saveInsights() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _insightsKey,
      list: _insights.map((i) => i.toJson()).toList(),
    );
  }

  Future<void> persistActiveSession() async {
    final session = _activeSession;
    if (session == null || session.outcome != null) {
      await _clearActiveSession();
      return;
    }
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJson(
      userId: uid,
      key: _activeSessionKey,
      json: session.toJson(),
    );
  }

  Future<void> _clearActiveSession() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.remove(
      userId: uid,
      key: _activeSessionKey,
    );
  }

  void startTimer({
    required Duration duration,
    String? subjectId,
    String? subjectName,
    String? taskId,
    String? examId,
    String? topicId,
    String? chapterId,
    String? planningBlockId,
    String? objective,
  }) {
    _createSession(
      mode: FocusMode.timer,
      duration: duration,
      subjectId: subjectId,
      subjectName: subjectName,
      taskId: taskId,
      examId: examId,
      topicId: topicId,
      chapterId: chapterId,
      planningBlockId: planningBlockId,
      objective: objective ?? (subjectName != null && subjectName.isNotEmpty ? subjectName : 'Timer Focus'),
    );
  }

  void startStopwatch({
    String? subjectId,
    String? subjectName,
    String? taskId,
    String? examId,
    String? topicId,
    String? chapterId,
    String? planningBlockId,
    String? objective,
  }) {
    _createSession(
      mode: FocusMode.stopwatch,
      duration: Duration.zero,
      subjectId: subjectId,
      subjectName: subjectName,
      taskId: taskId,
      examId: examId,
      topicId: topicId,
      chapterId: chapterId,
      planningBlockId: planningBlockId,
      objective: objective ?? (subjectName != null && subjectName.isNotEmpty ? subjectName : 'Stopwatch Focus'),
    );
  }

  void startFocusGuard({
    required Duration duration,
    Set<String>? blockedPackages,
    String? subjectId,
    String? subjectName,
    String? taskId,
    String? examId,
    String? topicId,
    String? chapterId,
    String? planningBlockId,
    String? objective,
  }) {
    _createSession(
      mode: FocusMode.focusGuard,
      duration: duration,
      blockedPackages: blockedPackages ?? const {},
      subjectId: subjectId,
      subjectName: subjectName,
      taskId: taskId,
      examId: examId,
      topicId: topicId,
      chapterId: chapterId,
      planningBlockId: planningBlockId,
      objective: objective ?? (subjectName != null && subjectName.isNotEmpty ? subjectName : 'Focus Guard'),
    );
  }

  void startQuickFocus({
    Duration? duration,
    String? subjectId,
    String? subjectName,
    String? taskId,
    String? examId,
    String? topicId,
    String? chapterId,
    String? planningBlockId,
  }) {
    startTimer(
      duration: duration ?? const Duration(minutes: 25),
      subjectId: subjectId,
      subjectName: subjectName,
      taskId: taskId,
      examId: examId,
      topicId: topicId,
      chapterId: chapterId,
      planningBlockId: planningBlockId,
      objective: 'Quick Focus',
    );
  }

  void startMission(FocusMission mission) {
    switch (mission.mode) {
      case FocusMode.stopwatch:
        _createSession(
          mode: FocusMode.stopwatch,
          duration: Duration.zero,
          subjectId: mission.subjectId,
          subjectName: mission.subjectName,
          taskId: mission.taskId,
          examId: mission.examId,
          topicId: mission.topicId,
          chapterId: mission.chapterId,
          objective: mission.objective.isNotEmpty ? mission.objective : 'Stopwatch Focus',
          missionId: mission.id,
        );
        break;
      case FocusMode.focusGuard:
        _createSession(
          mode: FocusMode.focusGuard,
          duration: mission.plannedDuration,
          subjectId: mission.subjectId,
          subjectName: mission.subjectName,
          taskId: mission.taskId,
          examId: mission.examId,
          topicId: mission.topicId,
          chapterId: mission.chapterId,
          objective: mission.objective.isNotEmpty ? mission.objective : 'Focus Guard',
          missionId: mission.id,
        );
        break;
      case FocusMode.timer:
        _createSession(
          mode: FocusMode.timer,
          duration: mission.plannedDuration,
          subjectId: mission.subjectId,
          subjectName: mission.subjectName,
          taskId: mission.taskId,
          examId: mission.examId,
          topicId: mission.topicId,
          chapterId: mission.chapterId,
          objective: mission.objective.isNotEmpty ? mission.objective : 'Timer Focus',
          missionId: mission.id,
        );
        break;
    }
  }

  void _createSession({
    required FocusMode mode,
    required Duration duration,
    Set<String> blockedPackages = const {},
    String? subjectId,
    String? subjectName,
    String? taskId,
    String? examId,
    String? topicId,
    String? chapterId,
    String? planningBlockId,
    String objective = '',
    String? missionId,
  }) {
    if (_activeSession != null) {
      _endSessionInternal(SessionOutcome.interrupted);
    }

    final now = _clock();
    final session = FocusSession(
      id: 'fs_${now.millisecondsSinceEpoch}_$_nextId',
      userId: _userId,
      missionId: missionId ?? '',
      objective: objective,
      subjectId: subjectId,
      subjectName: subjectName,
      taskId: taskId,
      examId: examId,
      topicId: topicId,
      chapterId: chapterId,
      planningBlockId: planningBlockId,
      mode: mode,
      status: FocusState.active,
      startedAt: now,
      phase: FocusPhase.focusing,
      focusDuration: duration,
      durationSeconds: mode == FocusMode.stopwatch ? null : duration.inSeconds,
      breakDuration: const Duration(minutes: 5),
      pomodoroCycles: 0,
      cycleCount: 0,
      cycleNumber: 1,
      blockedPackages: blockedPackages,
    );

    _activeSession = session;
    persistActiveSession();
    _scheduleCheckpoints(session);
    if (!_disposed) notifyListeners();
    _startTicker();
  }

  void _scheduleCheckpoints(FocusSession session) {
    for (final t in _checkpointTimers) {
      t.cancel();
    }
    _checkpointTimers.clear();

    final focusMin = session.plannedDuration.inMinutes;
    if (focusMin < 15) return;

    final checkpointTimes = <Duration>[];
    if (focusMin >= 15) checkpointTimes.add(const Duration(minutes: 15));
    if (focusMin >= 30) checkpointTimes.add(const Duration(minutes: 30));
    if (focusMin >= 45) checkpointTimes.add(const Duration(minutes: 45));

    for (final dur in checkpointTimes) {
      final t = Timer(dur, () {
        if (_activeSession?.id == session.id &&
            _activeSession?.phase == FocusPhase.focusing) {
          _addCheckpoint(session);
        }
      });
      _checkpointTimers.add(t);
    }
  }

  void _addCheckpoint(FocusSession session) {
    final elapsed = session.effectiveElapsedAt(_clock());
    final checkpoint = FocusCheckpoint(
      id: 'ckpt_${_clock().millisecondsSinceEpoch}_$_nextId',
      sessionId: session.id,
      elapsed: elapsed,
      timestamp: _clock(),
    );
    _checkpoints.add(checkpoint);
    _saveCheckpoints();
    session.checkpointsCompleted++;

    if (!session.isComplete) {
      _showCheckpointDialog(session);
    }
  }

  void _showCheckpointDialog(FocusSession session) {
    if (!_disposed) notifyListeners();
  }

  void setPhase(FocusPhase phase) {
    if (_activeSession != null) {
      _activeSession!.phase = phase;
      persistActiveSession();
      if (!_disposed) notifyListeners();
    }
  }

  void reportDistraction() {
    if (_activeSession != null) {
      _activeSession!.distractionAttempts++;
      persistActiveSession();
      if (!_disposed) notifyListeners();
    }
  }

  void pause() => pauseSession();
  void resume() => resumeSession();
  void complete({String note = ''}) => completeSession(note: note);
  void cancel({String note = ''}) => cancelSession(note: note);

  void pauseSession() {
    final session = _activeSession;
    if (session == null || session.status != FocusState.active || session.isPaused) return;

    final now = _clock();
    final elapsed = session.effectiveElapsedAt(now);
    session.pausedAt = now;
    session.elapsedWhenPaused = elapsed;
    session.phase = FocusPhase.paused;
    session.status = FocusState.paused;
    persistActiveSession();
    if (!_disposed) notifyListeners();
  }

  void resumeSession() {
    final session = _activeSession;
    if (session == null || session.status != FocusState.paused) return;

    final now = _clock();
    if (session.pausedAt != null) {
      final pauseDuration = now.difference(session.pausedAt!);
      session.totalPausedDuration += pauseDuration;
      session.pausedAt = null;
    }
    session.phase = FocusPhase.focusing;
    session.status = FocusState.active;
    persistActiveSession();
    if (!_disposed) notifyListeners();
  }

  /// Lifecycle: IDLE → STARTING → RUNNING → PAUSED → STOPPED / COMPLETED.
  ///
  /// STOP explicitly ends the current Timer/Stopwatch session: active-session
  /// state is cleared, the ticker stops, and the session is recorded with a
  /// partial outcome — never falsely marked as completed. Distinct from
  /// [resetSession] (restart fresh, unrecorded) and [completeSession].
  void stopSession({String note = ''}) {
    final session = _activeSession;
    if (session == null ||
        (session.status != FocusState.active &&
            session.status != FocusState.paused)) {
      return;
    }
    _endSessionInternal(SessionOutcome.partial, note: note);
  }

  void completeSession({String note = ''}) {
    final session = _activeSession;
    if (session == null || (session.status != FocusState.active && session.status != FocusState.paused)) return;
    _endSessionInternal(SessionOutcome.completed, note: note);
  }

  void endSessionEarly({String note = ''}) {
    final session = _activeSession;
    if (session == null || (session.status != FocusState.active && session.status != FocusState.paused)) return;
    _endSessionInternal(SessionOutcome.partial, note: note);
  }

  void cancelSession({String note = ''}) {
    final session = _activeSession;
    if (session == null || (session.status != FocusState.active && session.status != FocusState.paused)) return;
    _endSessionInternal(SessionOutcome.cancelled, note: note);
  }

  void interruptSession({String note = ''}) {
    final session = _activeSession;
    if (session == null || (session.status != FocusState.active && session.status != FocusState.paused)) return;
    _endSessionInternal(SessionOutcome.interrupted, note: note);
  }

  /// Resets the active session: discards current progress without recording
  /// it in history or awarding any completion effects, then starts a fresh
  /// session with the same mode, duration, and context.
  ///
  /// Used by the Timer/Stopwatch HUD RESET control to restart cleanly.
  void resetSession({Duration? duration}) {
    final session = _activeSession;
    if (session == null ||
        (session.status != FocusState.active &&
            session.status != FocusState.paused)) {
      return;
    }

    final planned = duration ?? session.plannedDuration;
    _discardActiveSession();

    _createSession(
      mode: session.mode,
      duration: planned,
      blockedPackages: session.blockedPackages,
      subjectId: session.subjectId,
      subjectName: session.subjectName,
      taskId: session.taskId,
      examId: session.examId,
      topicId: session.topicId,
      chapterId: session.chapterId,
      planningBlockId: session.planningBlockId,
      objective: session.objective,
      missionId: session.missionId,
    );
  }

  /// Clears the active session entirely without persisting it to history or
  /// triggering XP/streak/study effects (RESET = start fresh).
  void _discardActiveSession() {
    _activeSession = null;
    _stopTicker();
    _clearActiveSession();
  }

  void _endSessionInternal(SessionOutcome outcome, {String note = ''}) {
    final session = _activeSession;
    if (session == null) return;

    _activeSession = null;

    final now = _clock();
    session.endedAt = now;
    if (session.isPaused && session.pausedAt != null) {
      session.totalPausedDuration += now.difference(session.pausedAt!);
      session.pausedAt = null;
    }
    session.actualDuration = session.effectiveElapsedAt(now);
    if (note.isNotEmpty) session.note = note;
    session.outcome = outcome;
    session.status = outcome == SessionOutcome.completed
        ? FocusState.completed
        : FocusState.cancelled;
    session.phase = outcome == SessionOutcome.completed
        ? FocusPhase.completed
        : FocusPhase.interrupted;

    _calculateScore(session);

    _sessions.insert(0, session);
    _saveSessions();
    _clearActiveSession();
    _stopTicker();
    if (!_disposed) notifyListeners();

    _handleCompletion(session);
    _generateInsights(session);
  }

  void _calculateScore(FocusSession session) {
    final durationMinutes = session.effectiveElapsedAt(_clock()).inMinutes;
    final plannedMinutes = session.plannedDuration.inMinutes;
    var score = 0;

    if (plannedMinutes > 0) {
      score += (durationMinutes / plannedMinutes.clamp(1, 999) * 50)
          .clamp(0, 50)
          .toInt();
    } else {
      score += (durationMinutes * 2).clamp(0, 50);
    }

    if (session.outcome == SessionOutcome.completed) score += 25;

    if ((session.outcome == SessionOutcome.partial ||
            session.outcome == SessionOutcome.cancelled) &&
        (plannedMinutes == 0 || durationMinutes >= plannedMinutes * 0.5)) {
      score += 10;
    }

    score += (session.distractionAttempts <= 2 ? 10 : 0);
    score += (session.checkpointsCompleted * 5).clamp(0, 15);

    session.sessionScore = score.clamp(0, 100);
  }

  void _handleCompletion(FocusSession session) {
    final durationSec = session.actualFocusedDuration.inSeconds;
    if (durationSec >= XpEngine.minStudyDurationSeconds) {
      ProgressionController.instance.awardStudySession(
        sessionId: session.id,
        durationSeconds: durationSec,
        startedAt: session.startedAt,
        subjectId: session.subjectId,
      );
    }

    // Bridge into the authoritative study ledger (idempotent): Focus
    // history, daily/weekly progress, streak, and analytics then agree on
    // one underlying event. Abandoned outcomes record as not completed so
    // existing counting rules exclude them. XP/streak/notification effects
    // stay here to avoid any double award.
    if (durationSec > 0) {
      StudyController.instance.recordFocusCompletion(
        focusSessionId: session.id,
        subject: (session.subjectName != null &&
                session.subjectName!.trim().isNotEmpty)
            ? session.subjectName!
            : (session.objective.trim().isNotEmpty
                ? session.objective.trim()
                : 'General'),
        taskId: session.taskId,
        subjectId: session.subjectId,
        topicId: session.topicId,
        chapterId: session.chapterId,
        examId: session.examId,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        durationSec: durationSec,
        completed: session.outcome == SessionOutcome.completed,
        note: session.note,
      );
    }

    StreakService.instance.refresh();
    ProgressionController.instance.awardStreakMilestone(
      StreakService.instance.currentStreak,
    );

    if (session.outcome == SessionOutcome.completed) {
      NotificationController.instance.onFocusCompleted(session);
      if (session.isMission && session.taskId != null) {
        TaskController.instance.completeTask(session.taskId!);
      }
    }
  }

  void _generateInsights(FocusSession session) {
    // Focus analytics count Focus Guard (protected) sessions only; plain
    // Timer/Stopwatch sessions are excluded from the analytics surface.
    final completed = _sessions
        .where((s) => s.isComplete && s.mode == FocusMode.focusGuard)
        .toList();
    if (completed.length < 3) return;

    final avgDuration =
        completed.fold<int>(
          0,
          (sum, s) => sum + s.effectiveElapsedAt(_clock()).inMinutes,
        ) ~/
        completed.length;

    final subjectTimes = <String, int>{};
    for (final s in completed) {
      final subj = s.subjectName ?? 'General';
      subjectTimes[subj] =
          (subjectTimes[subj] ?? 0) + s.effectiveElapsedAt(_clock()).inMinutes;
    }
    if (subjectTimes.isEmpty) return;

    final topSubject = subjectTimes.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    final insights = <FocusInsight>[];

    if (avgDuration >= 30) {
      insights.add(
        FocusInsight(
          id: 'ins_${_clock().millisecondsSinceEpoch}_$_nextId',
          text:
              'Your most productive sessions are around $avgDuration minutes.',
          type: 'duration',
        ),
      );
    }

    insights.add(
      FocusInsight(
        id: 'ins_${_clock().millisecondsSinceEpoch}_${_nextId + 1}',
        text: '${topSubject.key} received the most focus time this period.',
        type: 'subject',
      ),
    );

    if (insights.isNotEmpty) {
      _insights.addAll(insights);
      _saveInsights();
    }
  }

  void captureDistraction(String thought, {String category = 'Other'}) {
    final capture = DistractionCapture(
      id: 'dc_${_clock().millisecondsSinceEpoch}_$_nextId',
      thought: thought,
      capturedAt: _clock(),
      sessionId: _activeSession?.id,
      category: category,
    );
    _distractions.add(capture);
    _saveDistractions();

    if (_activeSession != null) {
      _activeSession!.distractionsCaptured++;
      persistActiveSession();
    }

    if (!_disposed) notifyListeners();
  }

  void resolveDistraction(String distractionId) {
    final idx = _distractions.indexWhere((d) => d.id == distractionId);
    if (idx >= 0) {
      _distractions[idx].resolved = true;
      _saveDistractions();
      if (!_disposed) notifyListeners();
    }
  }

  void unresolveDistraction(String distractionId) {
    final idx = _distractions.indexWhere((d) => d.id == distractionId);
    if (idx >= 0) {
      _distractions[idx].resolved = false;
      _saveDistractions();
      if (!_disposed) notifyListeners();
    }
  }

  void deleteDistraction(String distractionId) {
    _distractions.removeWhere((d) => d.id == distractionId);
    _saveDistractions();
    if (!_disposed) notifyListeners();
  }

  Future<void> convertDistractionToTask(String distractionId) async {
    final idx = _distractions.indexWhere((d) => d.id == distractionId);
    if (idx < 0) return;

    final d = _distractions[idx];
    await TaskController.instance.createTask(
      title: d.thought,
      category: d.category,
    );

    // Mark distraction as resolved once converted to an explicit Task
    _distractions[idx].resolved = true;
    await _saveDistractions();
    if (!_disposed) notifyListeners();
  }

  List<DistractionCapture> get unresolvedDistractions =>
      _distractions.where((d) => !d.resolved).toList();

  List<DistractionCapture> get resolvedDistractions =>
      _distractions.where((d) => d.resolved).toList();

  List<DistractionCapture> get recentDistractions =>
      _distractions.take(10).toList();

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeSession != null) {
        final session = _activeSession!;
        if (session.isRunning) {
          if (session.mode != FocusMode.stopwatch &&
              session.effectiveElapsedAt(_clock()) >= session.plannedDuration) {
            completeSession();
            return;
          }
          if (!_disposed) notifyListeners();
        }
      } else {
        _stopTicker();
      }
    });
  }

  void _stopTicker() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _prepTimer?.cancel();
    _prepTimer = null;
    for (final t in _checkpointTimers) {
      t.cancel();
    }
    _checkpointTimers.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTicker();
    super.dispose();
  }
}
