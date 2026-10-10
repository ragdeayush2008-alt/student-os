import 'package:flutter/foundation.dart';

import '../../data/models/task.dart';
import '../../features/exams/exam_controller.dart';
import '../../features/focus/controller/focus_controller.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/sleep/models/sleep_schedule.dart';
import '../../features/sleep/sleep_controller.dart';
import '../../features/tasks/task_controller.dart';
import '../auth/auth_isolation.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/auth_service.dart';
import 'assistant_daily_state.dart';

/// Proactive daily loop state (P3): preparation flags, trigger surfacing
/// with anti-spam guards, visible action log, briefing notifications.
///
/// Reads existing controllers only (diff-based, no new stores) and never
/// writes academic data. Consequential actions stay behind the P2
/// confirmation gate; this controller only prepares and surfaces.
class DailyAssistantController extends ChangeNotifier {
  DailyAssistantController._();

  static final DailyAssistantController instance =
      DailyAssistantController._();

  static const _stateKey = 'assistant_daily_state';
  static const _prefsKey = 'assistant_preferences';
  static const _maxTriggers = 3;
  static const _maxLog = 20;

  DailyAssistantState _state = DailyAssistantState(
    date: DailyAssistantState.dayOf(DateTime.now()),
  );
  AssistantPreferences _prefs = const AssistantPreferences();
  bool _loaded = false;
  bool _disposed = false;
  DateTime? _lastNotifyAt;

  // Focus tick filter: only session identity/presence matters.
  String? _lastFocusSessionId;
  bool _lastFocusHasActive = false;

  DailyAssistantState get state => _state;
  AssistantPreferences get preferences => _prefs;
  bool get isLoaded => _loaded;

  /// The sleep window planning may use right now: null when the student
  /// turned sleep-aware planning off, or when no schedule is enabled.
  /// Single choke point so the preference maps to real behavior.
  static SleepSchedule? effectiveSleepSchedule() {
    if (!instance._prefs.sleepAwarePlanning) return null;
    try {
      final s = SleepController.instance.schedule;
      if (s == null || !s.enabled) return null;
      return s;
    } catch (_) {
      return null;
    }
  }

  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void clearData() {
    _state = DailyAssistantState(
      date: DailyAssistantState.dayOf(DateTime.now()),
    );
    // Preferences are per-user in storage: never carry another user's
    // toggles in memory across a switch.
    _prefs = const AssistantPreferences();
    _loaded = false;
    _lastFocusSessionId = null;
    _lastFocusHasActive = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      _state = DailyAssistantState(
        date: DailyAssistantState.dayOf(DateTime.now()),
      );
      _prefs = const AssistantPreferences();
      _loaded = true;
      if (!_disposed) notifyListeners();
      return;
    }
    try {
      final prefsJson = await StorageService.instance.loadJson(
        userId: uid,
        key: _prefsKey,
      );
      // No stored prefs for this user → defaults, never the previous
      // user's in-memory toggles.
      _prefs = prefsJson == null
          ? const AssistantPreferences()
          : AssistantPreferences.fromJson(prefsJson);
      final stateJson = await StorageService.instance.loadJson(
        userId: uid,
        key: _stateKey,
      );
      _state = stateJson == null
          ? DailyAssistantState(
              date: DailyAssistantState.dayOf(DateTime.now()),
            )
          : DailyAssistantState.fromJson(stateJson);
    } catch (_) {
      _state = DailyAssistantState(
        date: DailyAssistantState.dayOf(DateTime.now()),
      );
    } finally {
      _loaded = true;
      if (!_disposed) notifyListeners();
    }
    _attachListeners();
    await reconcileBriefingNotifications();
  }

  bool _listenersAttached = false;

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    TaskController.instance.addListener(_onSourceChanged);
    FocusController.instance.addListener(_onFocusChanged);
    SleepController.instance.addListener(_onSleepChanged);
    ExamController.instance.addListener(_onSourceChanged);
    PlanningBlockController.instance.addListener(_onSourceChanged);
  }

  void _onSourceChanged() {
    if (_disposed) return;
    final now = DateTime.now();
    if (_lastNotifyAt != null &&
        now.difference(_lastNotifyAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastNotifyAt = now;
    notifyListeners();
  }

  void _onFocusChanged() {
    final fc = FocusController.instance;
    final id = fc.activeSession?.id;
    final hasActive = fc.hasActiveSession;
    if (id == _lastFocusSessionId && hasActive == _lastFocusHasActive) {
      return;
    }
    _lastFocusSessionId = id;
    _lastFocusHasActive = hasActive;
    _onSourceChanged();
  }

  String? _lastSleepFingerprint;

  void _onSleepChanged() {
    final current = effectiveSleepSchedule();
    final fingerprint = current?.windowLabel;
    if (fingerprint != _lastSleepFingerprint) {
      _lastSleepFingerprint = fingerprint;
      // A prepared plan built around a different window is stale: preparation
      // lapses (quietly), and the sleep-changed trigger offers a rebuild.
      if (_state.prepared &&
          _state.sleepFingerprint != null &&
          _state.sleepFingerprint != fingerprint) {
        _state = _state.copyWith(prepared: false);
        _saveState();
      }
    }
    _onSourceChanged();
    reconcileBriefingNotifications();
  }

  Future<void> _saveState() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await StorageService.instance.saveJson(
        userId: uid,
        key: _stateKey,
        json: _state.toJson(),
      );
    } catch (_) {}
  }

  Future<void> updatePreferences(AssistantPreferences prefs) async {
    _prefs = prefs;
    final uid = _userId;
    if (uid != null) {
      try {
        await StorageService.instance.saveJson(
          userId: uid,
          key: _prefsKey,
          json: prefs.toJson(),
        );
      } catch (_) {}
    }
    if (!_disposed) notifyListeners();
    await reconcileBriefingNotifications();
  }

  // ─── Daily loop transitions ──────────────────────────────────────────

  /// Marks today's plan prepared (called when a morning briefing proposal
  /// is staged). Records the sleep window it was built around.
  Future<void> markPrepared() async {
    final sleep = effectiveSleepSchedule();
    _state = _state.copyWith(
      prepared: true,
      planGeneratedAt: DateTime.now(),
      planVersion: _state.planVersion + 1,
      sleepFingerprint: sleep?.windowLabel ?? 'none',
    );
    await _saveState();
    if (!_disposed) notifyListeners();
  }

  Future<void> markReviewed() async {
    _state = _state.copyWith(reviewed: true);
    await _saveState();
    if (!_disposed) notifyListeners();
  }

  Future<void> noteAdaptation() async {
    _state = _state.copyWith(lastAdaptationAt: DateTime.now());
    await _saveState();
    if (!_disposed) notifyListeners();
  }

  Future<void> noteApplied({
    int sessions = 0,
    int moves = 0,
    int creations = 0,
  }) async {
    _state = _state.copyWith(
      appliedSessions: _state.appliedSessions + sessions,
      appliedMoves: _state.appliedMoves + moves,
      appliedCreations: _state.appliedCreations + creations,
      lastAdaptationAt: DateTime.now(),
    );
    await _saveState();
    if (!_disposed) notifyListeners();
  }

  Future<void> dismissTrigger(String triggerId) async {
    if (_state.isDismissed(triggerId)) return;
    _state = _state.copyWith(
      dismissedTriggerIds: [..._state.dismissedTriggerIds, triggerId],
    );
    await _saveState();
    if (!_disposed) notifyListeners();
  }

  /// Today's id prefix (yyyy-mm-dd) for trigger and dismissal ids.
  static String todayPrefix([DateTime? now]) {
    final day = DailyAssistantState.dayOf(now ?? DateTime.now());
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  /// Dismisses a trigger kind for today (e.g. NBA "Later").
  Future<void> dismissTriggerKind(AssistantTriggerKind kind) async {
    await dismissTrigger('${todayPrefix()}:${kind.name}');
  }

  /// Whether a short id (e.g. `nba`) was dismissed today.
  bool isDismissedToday(String shortId) =>
      _state.isDismissed('${todayPrefix()}:$shortId');

  /// User-visible log (labels only, capped). Called for confirmed actions.
  Future<void> logAction(String entry) async {
    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final log = [..._state.actionLog, '$stamp $entry'];
    _state = _state.copyWith(
      actionLog: log.length > _maxLog
          ? log.sublist(log.length - _maxLog)
          : log,
    );
    await _saveState();
    if (!_disposed) notifyListeners();
  }

  // ─── Trigger evaluation ────────────────────────────────────────────
  //
  // Computed on demand from live controllers + daily state. Suppression
  // order: preferences → active focus → dismissed-today → completed work →
  // cap. No timers, no polling, no background work.

  /// Stable fingerprint of everything triggers depend on. Changes mean
  /// "recalculate when useful" without continuous recomputation.
  String evaluationKey(DateTime now) {
    final tc = TaskController.instance;
    final overdue = tc.tasks.where((t) => t.isOverdue).length;
    final unfinished = tc.tasks.where((t) => !t.isCompleted).length;
    final completedToday = _completedToday(now).length;
    final exams = ExamController.instance.upcomingExams
        .where((e) => !e.isCompleted)
        .toList();
    final nearest = exams.isEmpty
        ? 'none'
        : '${exams.first.id}:${exams.first.daysUntilExam}';
    final sleep = effectiveSleepSchedule();
    final sleepLabel = sleep?.windowLabel ?? 'none';
    return '$overdue|$unfinished|$completedToday|$nearest|$sleepLabel';
  }

  List<AssistantTrigger> buildTriggers({DateTime? now}) {
    try {
      return _buildTriggers(now ?? DateTime.now());
    } catch (_) {
      return const [];
    }
  }

  List<AssistantTrigger> _buildTriggers(DateTime now) {
    if (!_prefs.proactiveEnabled) return const [];
    // Never interrupt an active focus session with proactive cards.
    if (FocusController.instance.hasActiveSession) return const [];

    final day = DailyAssistantState.dayOf(now);
    final prefix =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final out = <AssistantTrigger>[];

    void add(AssistantTrigger t) {
      if (out.length >= _maxTriggers) return;
      if (_state.isDismissed(t.id)) return;
      if (out.any((e) => e.id == t.id)) return;
      out.add(t);
    }

    final tc = TaskController.instance;
    final activeTasks = tc.tasks.where((t) => !t.isCompleted).toList();
    final overdue =
        activeTasks.where((t) => t.isOverdue).toList();
    final sleep = effectiveSleepSchedule();
    final sleepEnabled = sleep != null;
    final window = sleepEnabled ? sleep.windowLabel : 'none';

    // Sleep changed since preparation → offer a rebuild.
    if (_state.sleepFingerprint != null &&
        _state.sleepFingerprint != window &&
        !_state.prepared) {
      add(
        AssistantTrigger(
          id: '$prefix:sleepChanged',
          kind: AssistantTriggerKind.sleepChanged,
          title: 'Sleep schedule changed',
          message: _state.sleepFingerprint == 'none'
              ? 'You set a sleep window. Rebuild today\'s plan around it?'
              : 'Your sleep window moved from ${_state.sleepFingerprint}. Rebuild the plan around it?',
        ),
      );
    }

    // Sleep boundary pressure: unfinished work vs time left tonight.
    if (sleep != null && sleep.enabled) {
      final bed = sleep.bedtimeMinutes;
      var bedtime =
          DateTime(now.year, now.month, now.day, bed ~/ 60, bed % 60);
      if (!bedtime.isAfter(now)) {
        bedtime = bedtime.add(const Duration(days: 1));
      }
      final left = bedtime.difference(now).inMinutes;
      final unfinishedToday = activeTasks.where((t) {
        if (t.dueDate == null) return false;
        final due =
            DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return !due.isAfter(day);
      }).length;
      if (left > 0 && left < 60 && unfinishedToday > 0) {
        add(
          AssistantTrigger(
            id: '$prefix:sleepBoundary',
            kind: AssistantTriggerKind.sleepBoundary,
            title: '$left min before bedtime',
            message:
                '$unfinishedToday unfinished item${unfinishedToday == 1 ? '' : 's'} — pick something light or defer the rest.',
          ),
        );
      }
    }

    // Overload: remaining due work exceeds time left tonight.
    final remaining = _remainingTodayMinutes(now, activeTasks);
    final available = _availableMinutes(now);
    if (remaining > 0 && remaining > available && available > 0) {
      add(
        AssistantTrigger(
          id: '$prefix:fixDay',
          kind: AssistantTriggerKind.fixDay,
          title: 'Day needs attention',
          message:
              '~${remaining}m of due work, ~${available}m left. Move the lowest priority to tomorrow?',
        ),
      );
    }

    // Overdue backlog.
    if (overdue.isNotEmpty) {
      add(
        AssistantTrigger(
          id: '$prefix:overdue',
          kind: AssistantTriggerKind.overdueTask,
          title: overdue.length == 1
              ? '1 overdue task'
              : '${overdue.length} overdue tasks',
          message:
              '“${overdue.first.title}”${overdue.length == 1 ? ' is' : ' and ${overdue.length - 1} more are'} waiting.',
        ),
      );
    }

    // Exam approaching (≤ 7 days).
    final exams = ExamController.instance.upcomingExams
        .where((e) => !e.isCompleted && e.daysUntilExam != null)
        .toList()
      ..sort((a, b) => a.daysUntilExam!.compareTo(b.daysUntilExam!));
    if (exams.isNotEmpty && exams.first.daysUntilExam! <= 7) {
      final exam = exams.first;
      add(
        AssistantTrigger(
          id: '$prefix:exam:${exam.id}',
          kind: AssistantTriggerKind.examPrep,
          title: '${exam.title} in ${exam.daysUntilExam}d',
          message: 'Review preparation before it gets close.',
        ),
      );
    }

    // Backlog accumulation (5+ unfinished due recently).
    if (activeTasks.length >= 5) {
      final recent = activeTasks.where((t) {
        if (t.dueDate == null) return t.isOverdue;
        final due =
            DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return !due.isAfter(day.add(const Duration(days: 1)));
      }).length;
      if (recent >= 5) {
        add(
          AssistantTrigger(
            id: '$prefix:catchUp',
            kind: AssistantTriggerKind.catchUp,
            title: 'Backlog building up',
            message:
              'Let\'s make $recent unfinished items manageable.',
          ),
        );
      }
    }

    // Finished early: last completed focus session beat its plan by 15m+.
    final ahead = _aheadSession(now);
    if (ahead != null) {
      add(
        AssistantTrigger(
          id: '$prefix:ahead:${ahead.$1}',
          kind: AssistantTriggerKind.aheadOfPlan,
          title: '${ahead.$2}m ahead of plan',
          message: 'A short revision fits in the freed time.',
        ),
      );
    }

    return out;
  }

  List<StudentTask> _completedToday(DateTime now) {
    final day = DailyAssistantState.dayOf(now);
    return TaskController.instance.tasks.where((t) {
      final c = t.completedAt;
      if (c == null) return false;
      return c.year == day.year && c.month == day.month && c.day == day.day;
    }).toList();
  }

  int _remainingTodayMinutes(
    DateTime now,
    List<StudentTask> activeTasks,
  ) {
    final day = DailyAssistantState.dayOf(now);
    var total = 0;
    for (final t in activeTasks) {
      if (t.dueDate == null) continue;
      final due =
          DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      if (due.isAfter(day)) continue;
      total += t.estimatedMinutes > 0 ? t.estimatedMinutes : 30;
    }
    return total;
  }

  int _availableMinutes(DateTime now) {
    final sleep = effectiveSleepSchedule();
    if (sleep != null) {
      final bed = sleep.bedtimeMinutes;
      var bedtime =
          DateTime(now.year, now.month, now.day, bed ~/ 60, bed % 60);
      if (!bedtime.isAfter(now)) {
        bedtime = bedtime.add(const Duration(days: 1));
      }
      return bedtime.difference(now).inMinutes.clamp(0, 720);
    }
    return 180;
  }

  /// Returns (sessionId, minutesAhead) when today's last completed focus
  /// session finished 15+ minutes under its plan.
  (String, int)? _aheadSession(DateTime now) {
    try {
      final day = DailyAssistantState.dayOf(now);
      final sessions = FocusController.instance.sessions.where((s) {
        final end = s.endedAt;
        return end != null &&
            end.year == day.year &&
            end.month == day.month &&
            end.day == day.day &&
            s.outcome != null;
      }).toList();
      if (sessions.isEmpty) return null;
      sessions.sort((a, b) => b.endedAt!.compareTo(a.endedAt!));
      final last = sessions.first;
      final planned = last.plannedDuration.inMinutes;
      final actual = (last.actualDuration ?? last.plannedDuration).inMinutes;
      final ahead = planned - actual;
      if (ahead >= 15) return (last.id, ahead);
    } catch (_) {}
    return null;
  }

  // ─── Briefing notifications (existing daily primitive) ───────────────

  Future<void> reconcileBriefingNotifications() async {
    try {
      await NotificationService.instance.cancel(
        NotificationIds.fromString('assistant_morning_briefing'),
      );
      await NotificationService.instance.cancel(
        NotificationIds.fromString('assistant_evening_review'),
      );
    } catch (_) {}

    if (!NotificationService.instance.hasPermission) return;
    if (!_prefs.proactiveEnabled) return;

    try {
      if (_prefs.morningBriefing && _prefs.briefingNotification) {
        final sleep = effectiveSleepSchedule();
        final wake =
            sleep != null ? sleep.wakeMinutes : 7 * 60 + 30;
        await NotificationService.instance.scheduleDaily(
          id: NotificationIds.fromString('assistant_morning_briefing'),
          title: 'Morning briefing ready',
          body: 'Your day is prepared. Review priorities and start.',
          hour: wake ~/ 60,
          minute: wake % 60,
          payload: const NotificationPayload(
            type: 'briefing',
            entityId: 'morning',
          ).encode(),
        );
      }
      if (_prefs.eveningReview && _prefs.eveningNotification) {
        await NotificationService.instance.scheduleDaily(
          id: NotificationIds.fromString('assistant_evening_review'),
          title: 'Evening review',
          body: 'See what you accomplished today.',
          hour: 21,
          minute: 0,
          payload: const NotificationPayload(
            type: 'review',
            entityId: 'evening',
          ).encode(),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
