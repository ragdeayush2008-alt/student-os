import 'dart:math' as math;

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/streak_service.dart';
import '../../data/models/study_session.dart';
import '../auth/auth_service.dart';
import '../progression/progression_controller.dart';
import '../notifications/notification_controller.dart';

import 'package:flutter/foundation.dart';

/// Manages real study sessions for the Study destination.
///
/// Follows the existing [TaskController] pattern: a ChangeNotifier singleton
/// persisting user-scoped data through [StorageService]. Completed sessions are
/// stored persistently; the currently running focus session is held in memory
/// and, when ended, is added to that persisted list.
class StudyController extends ChangeNotifier {
  StudyController._();

  /// Clears in-memory state without touching persistent storage.
  void clearData() {
    _sessions.clear();
    notifyListeners();
  }

  static final StudyController instance = StudyController._();

  static const _sessionsKey = 'study_sessions';

  /// Suggested daily focus target captured in a session, in whole seconds.
  static const Duration dailyFocusTarget = Duration(minutes: 120);

  List<StudySession> _sessions = [];
  bool _loaded = false;
  bool _disposed = false;
  int _counter = 0;

  // ── Active focus session (in-memory) ─────────────────────────────────

  DateTime? _activeStart;
  Duration _accumulated = Duration.zero;
  bool _running = false;
  String _activeSubject = 'General';
  String? _activeTaskId;
  String? _activeSubjectId;
  String? _activeTopicId;
  String? _activeChapterId;
  String? _activeExamId;

  List<StudySession> get sessions => List.unmodifiable(_sessions);
  bool get isLoaded => _loaded;

  /// Whether a focus session is currently being tracked (running or paused).
  bool get hasActiveSession => _activeStart != null;

  /// Whether the active focus session is currently counting up.
  bool get isRunning => _running;

  String get activeSubject => _activeSubject;
  String? get activeTaskId => _activeTaskId;
  String? get activeSubjectId => _activeSubjectId;
  String? get activeTopicId => _activeTopicId;
  String? get activeChapterId => _activeChapterId;
  String? get activeExamId => _activeExamId;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  /// Elapsed time of the active focus session, accounting for pauses.
  Duration get activeElapsed {
    if (_activeStart == null) return Duration.zero;
    final start = _activeStart!;
    final base = _running ? DateTime.now().difference(start) : Duration.zero;
    return _accumulated + base;
  }

  // ── Loading / persistence ────────────────────────────────────────────

  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    try {
      final uid = _userId;
      if (uid == null) return;
      final list = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _sessionsKey,
      );
      if (list != null) {
        _sessions =
            list
                .whereType<Map<String, dynamic>>()
                .map(StudySession.fromJson)
                .toList()
              ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
        _counter = _sessions.length;
      }
    } catch (_) {
      // A corrupt cache entry must never leave the controller permanently
      // "not loaded" (Home gates on [isLoaded] and would spin forever).
      _sessions = [];
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
      key: _sessionsKey,
      list: _sessions.map((s) => s.toJson()).toList(),
    );
  }

  // ── Focus session controls ───────────────────────────────────────────

  /// Begins a new focus session. Any in-flight session is ended first.
  void startSession({
    String subject = 'General',
    String? taskId,
    String? subjectId,
    String? topicId,
    String? chapterId,
    String? examId,
  }) {
    if (_activeStart != null) {
      _completeActive();
    }
    _activeStart = DateTime.now();
    _accumulated = Duration.zero;
    _running = true;
    _activeSubject = subject.trim().isEmpty ? 'General' : subject.trim();
    _activeTaskId = taskId;
    _activeSubjectId = subjectId;
    _activeTopicId = topicId;
    _activeChapterId = chapterId;
    _activeExamId = examId;
    if (!_disposed) notifyListeners();
  }

  void pauseSession() {
    if (!hasActiveSession || !_running) return;
    _accumulated += DateTime.now().difference(_activeStart!);
    _running = false;
    if (!_disposed) notifyListeners();
  }

  void resumeSession() {
    if (!hasActiveSession || _running) return;
    _activeStart = DateTime.now();
    _running = true;
    if (!_disposed) notifyListeners();
  }

  /// Ends and persists the active focus session, returning the created
  /// [StudySession]. No-op and returns null when no session is active.
  Future<StudySession?> endSession({String note = ''}) async {
    if (!hasActiveSession) return null;
    final session = _buildCompletedSession(note, end: DateTime.now());
    _resetActive();
    await _persistSession(session);
    return session;
  }

  /// Ends the active session without persisting it.
  void cancelSession({String note = ''}) {
    if (!hasActiveSession) return;
    _resetActive();
    if (!_disposed) notifyListeners();
  }

  StudySession _buildCompletedSession(String note, {required DateTime end}) {
    final elapsed = activeElapsed;
    return StudySession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}_${++_counter}',
      subject: _activeSubject,
      taskId: _activeTaskId,
      subjectId: _activeSubjectId,
      topicId: _activeTopicId,
      chapterId: _activeChapterId,
      examId: _activeExamId,
      startedAt: end.subtract(elapsed),
      endedAt: end,
      durationSec: elapsed.inSeconds,
      completed: true,
      note: note,
    );
  }

  void _completeActive() {
    if (!hasActiveSession) return;
    final end = DateTime.now();
    final session = _buildCompletedSession('', end: end);
    _resetActive();
    // fire-and-forget persistence of the superseded session
    _persistSession(session);
  }

  Future<void> _persistSession(StudySession session) async {
    _sessions = [..._sessions, session]
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    await _saveSessions();
    if (!_disposed) notifyListeners();

    // Award XP for completing study session
    await ProgressionController.instance.awardStudySession(
      sessionId: session.id,
      durationSeconds: session.durationSec,
      startedAt: session.startedAt,
      subjectId: session.subjectId,
    );

    // Refresh streak and check for streak milestones
    StreakService.instance.refresh();
    await ProgressionController.instance.awardStreakMilestone(
      StreakService.instance.currentStreak,
    );

    await NotificationController.instance.onStudyCompleted(session);
  }

  /// Bridges a finished Focus session into the authoritative study ledger so
  /// Focus history, daily/weekly progress, streak, and analytics agree on one
  /// underlying event (PART 5 consistency).
  ///
  /// Idempotent: a [focusSessionId] already present is returned as-is, so
  /// restarts, recovery paths, and repeated completion calls never
  /// double-count the same session.
  ///
  /// Side-effect safe: records history only — XP, streak refresh, and
  /// notifications stay owned by the Focus completion path that calls this,
  /// so nothing is awarded or sent twice.
  ///
  /// Abandoned sessions ([completed] false) are recorded as not completed and
  /// are therefore excluded from study minutes and streaks by existing rules.
  Future<StudySession> recordFocusCompletion({
    required String focusSessionId,
    required String subject,
    String? taskId,
    String? subjectId,
    String? topicId,
    String? chapterId,
    String? examId,
    DateTime? startedAt,
    DateTime? endedAt,
    int durationSec = 0,
    bool completed = true,
    String note = '',
  }) async {
    final existing = _sessions.where((s) => s.focusSessionId == focusSessionId);
    if (existing.isNotEmpty) return existing.first;

    final now = DateTime.now();
    final session = StudySession(
      id: 'study_$focusSessionId',
      subject: subject.trim().isEmpty ? 'General' : subject.trim(),
      taskId: taskId,
      subjectId: subjectId,
      topicId: topicId,
      chapterId: chapterId,
      examId: examId,
      focusSessionId: focusSessionId,
      startedAt: startedAt ?? now,
      endedAt: endedAt ?? now,
      durationSec: durationSec,
      completed: completed,
      note: note,
    );
    _sessions = [..._sessions, session]
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    await _saveSessions();
    if (!_disposed) notifyListeners();
    return session;
  }

  void _resetActive() {
    _activeStart = null;
    _accumulated = Duration.zero;
    _running = false;
    _activeSubject = 'General';
    _activeTaskId = null;
    _activeSubjectId = null;
    _activeTopicId = null;
    _activeChapterId = null;
    _activeExamId = null;
  }

  // ── Derived analytics ────────────────────────────────────────────────

  List<StudySession> get completedSessions =>
      _sessions.where((s) => s.isCompleted).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  List<StudySession> sessionsOn(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _sessions.where((s) => s.date == date).toList();
  }

  Duration durationOn(DateTime day) {
    final sessions = sessionsOn(day);
    return Duration(
      seconds: sessions.fold<int>(0, (sum, s) => sum + s.durationSec),
    );
  }

  List<StudySession> get todaySessions => sessionsOn(DateTime.now());
  Duration get todayDuration => durationOn(DateTime.now());

  double get todayProgress {
    if (dailyFocusTarget.inSeconds == 0) return 0;
    return (todayDuration.inSeconds / dailyFocusTarget.inSeconds).clamp(
      0.0,
      1.0,
    );
  }

  int get todayCompletedCount =>
      todaySessions.where((s) => s.isCompleted).length;

  DateTime get _todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _weekStart {
    final today = _todayDate;
    return today.subtract(Duration(days: today.weekday - 1));
  }

  /// Durations for each day of the current week (Monday first).
  List<Duration> get weekDurations {
    final start = _weekStart;
    return List<Duration>.generate(
      7,
      (i) => durationOn(start.add(Duration(days: i))),
    );
  }

  Duration get weekTotalDuration {
    return weekDurations.fold(Duration.zero, (a, b) => a + b);
  }

  int get weekSessionCount => _sessions.where((s) {
    final date = s.date;
    return !date.isBefore(_weekStart) && !date.isAfter(_todayDate);
  }).length;

  /// Fraction of days this week with at least one completed study session.
  double get weekConsistency {
    var activeDays = 0;
    for (final duration in weekDurations) {
      if (duration.inSeconds > 0) activeDays++;
    }
    // Do not penalize future days of the week.
    final weekday = _todayDate.weekday;
    final elapsedDays = math.max(weekday, 1);
    return activeDays / elapsedDays;
  }

  /// Date of the day in the current week with the most studied time, if any.
  DateTime? get strongestDay {
    final start = _weekStart;
    var best = -1;
    var bestIndex = -1;
    for (var i = 0; i < weekDurations.length; i++) {
      if (weekDurations[i].inSeconds > best) {
        best = weekDurations[i].inSeconds;
        bestIndex = i;
      }
    }
    if (bestIndex <= _todayDate.weekday - 1 && best > 0) {
      return start.add(Duration(days: bestIndex));
    }
    return null;
  }

  List<StudySession> get recentSessions {
    final sorted = completedSessions.take(8).toList();
    return sorted;
  }

  /// Total study minutes for a specific subject within the last [days] days.
  int studyMinutesForSubject(String subjectName, {int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final needle = subjectName.trim().toLowerCase();
    int totalSec = 0;
    for (final s in _sessions) {
      if (!s.isCompleted || s.startedAt.isBefore(cutoff)) continue;
      if (s.subject.trim().toLowerCase() == needle) {
        totalSec += s.durationSec;
      }
    }
    return totalSec ~/ 60;
  }

  /// Total study minutes for a specific topic within the last [days] days (or all time if days is null).
  int studyMinutesForTopic(String topicId, {int? days}) {
    final cutoff = days != null ? DateTime.now().subtract(Duration(days: days)) : null;
    int totalSec = 0;
    for (final s in _sessions) {
      if (!s.isCompleted) continue;
      if (cutoff != null && s.startedAt.isBefore(cutoff)) continue;
      if (s.topicId == topicId) {
        totalSec += s.durationSec;
      }
    }
    return totalSec ~/ 60;
  }

  /// Total study minutes for a specific chapter within the last [days] days (or all time if days is null).
  int studyMinutesForChapter(String chapterId, {int? days}) {
    final cutoff = days != null ? DateTime.now().subtract(Duration(days: days)) : null;
    int totalSec = 0;
    for (final s in _sessions) {
      if (!s.isCompleted) continue;
      if (cutoff != null && s.startedAt.isBefore(cutoff)) continue;
      if (s.chapterId == chapterId) {
        totalSec += s.durationSec;
      }
    }
    return totalSec ~/ 60;
  }

  List<StudySession> sessionsForTopic(String topicId) {
    return _sessions.where((s) => s.topicId == topicId).toList();
  }

  List<StudySession> sessionsForChapter(String chapterId) {
    return _sessions.where((s) => s.chapterId == chapterId).toList();
  }

  /// Date when [topicId] was most recently studied, or null if never.
  DateTime? lastStudiedDateForTopic(String topicId) {
    DateTime? latest;
    for (final s in _sessions) {
      if (!s.isCompleted) continue;
      if (s.topicId == topicId) {
        if (latest == null || s.startedAt.isAfter(latest)) {
          latest = s.startedAt;
        }
      }
    }
    return latest;
  }

  /// Date when [subjectName] was most recently studied, or null if never.
  DateTime? lastStudiedDate(String subjectName) {
    final needle = subjectName.trim().toLowerCase();
    DateTime? latest;
    for (final s in _sessions) {
      if (!s.isCompleted) continue;
      if (s.subject.trim().toLowerCase() == needle) {
        if (latest == null || s.startedAt.isAfter(latest)) {
          latest = s.startedAt;
        }
      }
    }
    return latest;
  }

  /// Number of consecutive days (ending today) with a completed session.
  int get studyStreakDays {
    if (_sessions.isEmpty) return 0;
    final activeDates =
        _sessions
            .where((s) => s.isCompleted)
            .map((s) => s.date)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (activeDates.isEmpty) return 0;

    var streak = 0;
    for (var offset = 0; offset < activeDates.length; offset++) {
      final expected = _todayDate.subtract(Duration(days: offset));
      if (activeDates.contains(expected)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
