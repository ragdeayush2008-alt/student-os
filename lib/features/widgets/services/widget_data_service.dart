import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/assistant/assistant_planning_engine.dart';
import '../../../core/auth/auth_isolation.dart';
import '../../../data/models/task.dart';
import '../../auth/auth_service.dart';
import '../../exams/exam_controller.dart';
import '../../focus/controller/focus_controller.dart';
import '../../planning/controllers/planning_block_controller.dart';
import '../../revision/revision_controller.dart';
import '../../sleep/models/sleep_schedule.dart';
import '../../sleep/sleep_controller.dart';
import '../../../core/services/streak_service.dart';
import '../../study/study_controller.dart';
import '../../subjects/subject_controller.dart';
import '../../tasks/task_controller.dart';
import '../../premium/services/entitlement_service.dart';
import '../models/widget_snapshot.dart';

/// Central widget data projection (home-screen widgets foundation).
///
/// Reads existing controllers, builds one compact [WidgetSnapshot], writes
/// it to platform-shared storage (`home_widget`), and asks the OS to
/// refresh. No second database, no business logic, no secrets — snapshots
/// contain display strings and counts only.
///
/// Refresh is event-driven (controller notifications, coalesced) plus
/// explicit [refreshNow]/[clearForLogout]. Never polls.
class WidgetDataService extends ChangeNotifier {
  WidgetDataService._();

  static final WidgetDataService instance = WidgetDataService._();

  /// Storage key shared with native widgets (both platforms).
  static const String snapshotKey = 'student_os_widget_snapshot';

  /// iOS App Group id (matches the Widget extension group capability).
  static const String iosAppGroupId =
      'group.com.ragdetechnologies.studentos.widgets';

  bool _listenersAttached = false;
  bool _disposed = false;
  DateTime? _lastRefreshAt;
  String _lastUserId = '';

  /// Android provider class names refreshed on every snapshot write.
  static const List<String> androidProviders = [
    'com.ragdetechnologies.student_os.StudentOsExamCountdownWidget',
    'com.ragdetechnologies.student_os.StudentOsTasksWidget',
    'com.ragdetechnologies.student_os.StudentOsPlanWidget',
    'com.ragdetechnologies.student_os.StudentOsFocusWidget',
    'com.ragdetechnologies.student_os.StudentOsAssistantWidget',
    'com.ragdetechnologies.student_os.StudentOsSleepWidget',
    'com.ragdetechnologies.student_os.StudentOsStudyWidget',
    'com.ragdetechnologies.student_os.StudentOsBriefWidget',
  ];

  static const List<String> iosKinds = [
    'StudentOsExamCountdown',
    'StudentOsTasks',
    'StudentOsPlan',
    'StudentOsFocus',
    'StudentOsAssistant',
    'StudentOsSleep',
    'StudentOsStudy',
    'StudentOsBrief',
  ];

  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void init() {
    _attachListeners();
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    TaskController.instance.addListener(_onSourceChanged);
    ExamController.instance.addListener(_onSourceChanged);
    PlanningBlockController.instance.addListener(_onSourceChanged);
    FocusController.instance.addListener(_onFocusChanged);
    SleepController.instance.addListener(_onSourceChanged);
    StudyController.instance.addListener(_onSourceChanged);
    SubjectController.instance.addListener(_onSourceChanged);
    AuthService.instance.addListener(_onAuthChanged);
  }

  String? _lastFocusSessionId;
  bool _lastFocusHasActive = false;

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

  void _onAuthChanged() {
    final uid = _userId ?? '';
    if (uid != _lastUserId) {
      _lastUserId = uid;
      if (uid.isEmpty) {
        clearForLogout();
      } else {
        refreshNow();
      }
    }
  }

  void _onSourceChanged() {
    if (_disposed) return;
    final now = DateTime.now();
    if (_lastRefreshAt != null &&
        now.difference(_lastRefreshAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastRefreshAt = now;
    refreshNow();
  }

  /// Rebuilds the snapshot from live controllers and pushes it to the OS.
  /// Safe to call any time; failures degrade silently (stale snapshot
  /// remains rather than blanking widgets).
  Future<void> refreshNow() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) {
      await clearForLogout();
      return;
    }
    _lastUserId = uid;
    WidgetSnapshot snapshot;
    try {
      snapshot = buildSnapshot(uid, DateTime.now());
    } catch (_) {
      return;
    }
    await writeSnapshot(snapshot);
  }

  /// Builds the snapshot purely from existing controllers. Each section is
  /// independently guarded so one bad domain never blanks the rest.
  WidgetSnapshot buildSnapshot(String userId, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return WidgetSnapshot(
      userId: userId,
      generatedAt: now,
      nextExam: _safe(() => _projectNextExam()),
      upcomingExams: _safeList(() => _projectUpcomingExams()),
      examPrep: _safe(() => _projectExamPrep(now)),
      todayStudy: _safe(() => _projectStudy(now, today)),
      subjectProgress: _safe(() => _projectSubject()),
      nextAction: _safe(() => _projectNextAction()),
      todayTasks: _safe(() => _projectTasks()),
      todayPlan: _safe(() => _projectPlan(now, today)),
      backlog: _safe(() => _projectBacklog()),
      focus: _safe(() => _projectFocus()),
      focusStats: _safe(() => _projectFocusStats(now, today)),
      focusStreakDays: _safe(() => StreakService.instance.currentStreak),
      assistant: _safe(() => _projectAssistant()),
      sleep: _safe(() => _projectSleep()),
      dayBalance: _safe(() => _projectBalance(now, today)),
      brief: _safe(() => _projectBrief(now)),
      lockedWidgetIds: _lockedWidgets(),
    );
  }

  T? _safe<T>(T? Function() build) {
    try {
      return build();
    } catch (_) {
      return null;
    }
  }

  List<T> _safeList<T>(List<T> Function() build) {
    try {
      return build();
    } catch (_) {
      return [];
    }
  }

  // ─── Projections (one per widget family) ───────────────────────────

  ExamWidgetData? _projectNextExam() {
    final exam = ExamController.instance.nextExam;
    if (exam == null) return null;
    return ExamWidgetData(
      id: exam.id,
      title: exam.title,
      subject: exam.subject,
      dateLabel: _dateLabel(exam.examDateTime),
      daysLeft: exam.daysUntilExam,
      windowDays: exam.preparationWindowDays,
    );
  }

  List<ExamWidgetData> _projectUpcomingExams() {
    return ExamController.instance.upcomingExams
        .where((e) => e.examDateTime != null)
        .take(4)
        .map(
          (e) => ExamWidgetData(
            id: e.id,
            title: e.title,
            subject: e.subject,
            dateLabel: _dateLabel(e.examDateTime),
            daysLeft: e.daysUntilExam,
            windowDays: e.preparationWindowDays,
          ),
        )
        .toList();
  }

  ExamPrepWidgetData? _projectExamPrep(DateTime now) {
    final exam = ExamController.instance.nextExam;
    if (exam == null) return null;
    final prepTasks = TaskController.instance.tasks
        .where((t) => !t.isCompleted && t.examId == exam.id)
        .toList();
    StudentTask? target;
    if (prepTasks.isNotEmpty) {
      prepTasks.sort((a, b) {
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
      target = prepTasks.first;
    }
    return ExamPrepWidgetData(
      examId: exam.id,
      title: exam.title,
      daysLeft: exam.daysUntilExam,
      targetTitle: target?.title,
      targetMinutes: target == null
          ? null
          : (target.estimatedMinutes > 0 ? target.estimatedMinutes : 30),
    );
  }

  StudyWidgetData _projectStudy(DateTime now, DateTime today) {
    var planned = 0;
    var completed = 0;
    for (final s in StudyController.instance.sessions) {
      final start = s.startedAt;
      if (start.year != today.year ||
          start.month != today.month ||
          start.day != today.day) {
        continue;
      }
      planned += s.durationSec ~/ 60;
      if (s.isCompleted) completed += s.durationSec ~/ 60;
    }
    // Focus time counts toward completed study.
    for (final s in FocusController.instance.sessions) {
      final end = s.endedAt;
      if (end == null ||
          end.year != today.year ||
          end.month != today.month ||
          end.day != today.day) {
        continue;
      }
      if (s.outcome == null) continue;
      completed +=
          (s.actualDuration ?? s.plannedDuration).inMinutes;
    }
    return StudyWidgetData(
      plannedMinutes: planned,
      completedMinutes: completed,
    );
  }

  SubjectProgressWidgetData? _projectSubject() {
    final subjects = SubjectController.instance.activeSubjects;
    if (subjects.isEmpty) return null;
    final subject = subjects.first;
    var taskCount = 0;
    try {
      taskCount = TaskController.instance.tasks
          .where((t) => !t.isCompleted && t.subjectId == subject.id)
          .length;
    } catch (_) {}
    int? revisions;
    try {
      revisions = RevisionController.instance.records
          .where((r) => r.subjectId == subject.id)
          .length;
    } catch (_) {
      revisions = null;
    }
    return SubjectProgressWidgetData(
      subjectId: subject.id,
      subjectName: subject.displayName,
      revisionDone: revisions,
      revisionTotal: revisions == null ? null : revisions + taskCount,
    );
  }

  ActionWidgetData? _projectNextAction() {
    final tasks = TaskController.instance.tasks;
    if (tasks.isEmpty) return null;
    final ranked = AssistantPlanningEngine.rankTasks(tasks, DateTime.now(), const []);
    if (ranked.isEmpty) return null;
    final top = ranked.first;
    String reason = 'Up next';
    if (top.isOverdue) {
      reason = 'Overdue';
    } else if (top.isDueToday) {
      reason = 'Due today';
    } else if (top.examId != null) {
      reason = 'Exam prep';
    } else if (top.priority == TaskPriority.high ||
        top.priority == TaskPriority.critical) {
      reason = 'High priority';
    }
    return ActionWidgetData(
      title: top.title,
      subtitle: top.examId != null ? 'Exam prep' : '',
      minutes:
          top.estimatedMinutes > 0 ? top.estimatedMinutes : 30,
      reason: reason,
      taskId: top.id,
      kind: 'task',
    );
  }

  TasksWidgetData _projectTasks() {
    final tc = TaskController.instance;
    final remaining = tc.todayTasks.length + tc.overdueTasks.length;
    final completed = tc.tasks
        .where((t) {
          final c = t.completedAt;
          if (c == null) return false;
          final now = DateTime.now();
          return c.year == now.year &&
              c.month == now.month &&
              c.day == now.day;
        })
        .length;
    final ranked = AssistantPlanningEngine.rankTasks(
      tc.tasks,
      DateTime.now(),
      const [],
    );
    final top = ranked.isEmpty ? null : ranked.first;
    return TasksWidgetData(
      remaining: remaining,
      completed: completed,
      topTitle: top?.title,
      topPriority: top?.priority.label,
    );
  }

  PlanWidgetData _projectPlan(DateTime now, DateTime today) {
    final blocks = PlanningBlockController.instance.blocksForDay(today);
    final items = blocks.take(6).map((b) {
      final start = b.startAt;
      final time =
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      final title = b.customTitle?.isNotEmpty == true
          ? b.customTitle!
          : 'Planned session';
      return PlanItemData(
        time: time,
        title: title,
        minutes: b.endAt.difference(b.startAt).inMinutes,
      );
    }).toList();
    PlanItemData? next;
    for (final b in blocks) {
      if (b.endAt.isAfter(now)) {
        final start = b.startAt.isAfter(now) ? b.startAt : now;
        next = PlanItemData(
          time: '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
          title: b.customTitle?.isNotEmpty == true
              ? b.customTitle!
              : 'Planned session',
          minutes: b.endAt.difference(start).inMinutes,
        );
        break;
      }
    }
    return PlanWidgetData(
      items: items,
      nextTitle: next?.title,
      nextMinutes: next?.minutes,
    );
  }

  BacklogWidgetData _projectBacklog() {
    final tc = TaskController.instance;
    final overdue = tc.overdueTasks;
    final unfinished =
        tc.tasks.where((t) => !t.isCompleted).length;
    String? top;
    if (overdue.isNotEmpty) {
      final ranked = AssistantPlanningEngine.rankTasks(
        overdue,
        DateTime.now(),
        const [],
      );
      top = (ranked.isEmpty ? overdue.first : ranked.first).title;
    }
    return BacklogWidgetData(
      unfinished: unfinished,
      overdue: overdue.length,
      topTitle: top,
    );
  }

  FocusWidgetData _projectFocus() {
    final fc = FocusController.instance;
    final active = fc.activeSession;
    if (active == null || !fc.hasActiveSession) {
      return const FocusWidgetData(hasActive: false);
    }
    final remaining = fc.activeRemaining;
    final label =
        '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')} left';
    return FocusWidgetData(
      hasActive: true,
      title: active.objective.isNotEmpty
          ? active.objective
          : 'Focus session',
      remainingLabel: label,
      mode: active.mode.name,
    );
  }

  FocusStatsWidgetData _projectFocusStats(DateTime now, DateTime today) {
    var todayMinutes = 0;
    var sessionsToday = 0;
    var weekMinutes = 0;
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    for (final s in FocusController.instance.sessions) {
      final end = s.endedAt;
      if (end == null || s.outcome == null) continue;
      final minutes =
          (s.actualDuration ?? s.plannedDuration).inMinutes;
      final day = DateTime(end.year, end.month, end.day);
      if (day == today) {
        todayMinutes += minutes;
        sessionsToday++;
      }
      if (!day.isBefore(weekStart)) weekMinutes += minutes;
    }
    return FocusStatsWidgetData(
      todayMinutes: todayMinutes,
      sessionsToday: sessionsToday,
      weekMinutes: weekMinutes,
    );
  }

  AssistantWidgetData? _projectAssistant() {
    final action = _projectNextAction();
    if (action == null) return null;
    return AssistantWidgetData(
      headline: action.title,
      reason: action.reason,
      minutes: action.minutes,
    );
  }

  SleepWidgetData? _projectSleep() {
    final schedule = SleepController.instance.schedule;
    if (schedule == null || !schedule.enabled) return null;
    return SleepWidgetData(
      bedtimeLabel:
          SleepScheduleValidation.formatClock12(schedule.bedtimeMinutes),
      wakeLabel:
          SleepScheduleValidation.formatClock12(schedule.wakeMinutes),
      durationLabel: schedule.durationLabel,
    );
  }

  DayBalanceWidgetData _projectBalance(DateTime now, DateTime today) {
    final study = _projectStudy(now, today);
    final focus = _projectFocusStats(now, today);
    final remaining = _projectTasks().remaining;
    final sleep = _projectSleep();
    return DayBalanceWidgetData(
      studyMinutes: study.plannedMinutes,
      focusMinutes: focus.todayMinutes,
      tasksRemaining: remaining,
      sleepLabel: sleep == null
          ? null
          : '${sleep.bedtimeLabel} → ${sleep.wakeLabel}',
    );
  }

  BriefWidgetData? _projectBrief(DateTime now) {
    final tasks = _projectTasks();
    final exam = _projectNextExam();
    final sleep = _projectSleep();
    if (tasks.remaining == 0 && exam == null) return null;
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final lines = <String>[
      if (exam != null && exam.daysLeft != null)
        '🎓 ${exam.title} · ${exam.daysLeft}d',
      if (tasks.remaining > 0) '📋 ${tasks.remaining} remaining',
      if (sleep != null)
        '🌙 ${sleep.bedtimeLabel} → ${sleep.wakeLabel}',
    ];
    return BriefWidgetData(greeting: greeting, lines: lines);
  }

  List<String> _lockedWidgets() {
    const gated = {
      'daily_brief': 'premium.assistant.proactive',
      'focus_stats': 'premium.analytics.advanced',
    };
    final locked = <String>[];
    for (final entry in gated.entries) {
      try {
        if (!EntitlementService.instance
            .hasFeatureAccess(entry.value)) {
          locked.add(entry.key);
        }
      } catch (_) {}
    }
    return locked;
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = date.hour;
    final suffix = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final mm = date.minute == 0
        ? ''
        : ':${date.minute.toString().padLeft(2, '0')}';
    return '${date.day} ${months[date.month - 1]} · $h12$mm $suffix';
  }

  // ─── Shared storage + OS refresh ───────────────────────────────────

  /// Writes the snapshot to platform-shared storage and nudges the OS.
  /// Returns false when the platform channel is unavailable (web/tests).
  ///
  /// The snapshot is stored as one JSON string: the plugin only supports
  /// primitive values, and a single document keeps native parsing trivial.
  /// Payloads stay small (display strings + counts, capped lists).
  /// JSON-encoding shared by both writers. Returns null when the payload
  /// cannot be encoded (never writes partial data).
  String? _encode(WidgetSnapshot snapshot) {
    try {
      return jsonEncode(snapshot.toJson());
    } catch (_) {
      return null;
    }
  }

  Future<bool> writeSnapshot(WidgetSnapshot snapshot) {
    return _writeEncoded(_encode(snapshot));
  }

  Future<bool> _writeEncoded(String? encoded) async {
    if (encoded == null) return false;
    try {
      await HomeWidget.setAppGroupId(iosAppGroupId);
    } catch (_) {}
    try {
      await HomeWidget.saveWidgetData<String>(snapshotKey, encoded);
    } catch (_) {
      return false;
    }
    try {
      for (final provider in androidProviders) {
        await HomeWidget.updateWidget(qualifiedAndroidName: provider);
      }
      for (final kind in iosKinds) {
        await HomeWidget.updateWidget(iOSName: kind);
      }
    } catch (_) {}
    if (!_disposed) notifyListeners();
    return true;
  }

  /// Clears the snapshot and refreshes widgets to the logged-out state.
  /// Called on logout/user switch — never leaves prior user data visible.
  Future<void> clearForLogout() async {
    _lastUserId = '';
    try {
      await HomeWidget.setAppGroupId(iosAppGroupId);
    } catch (_) {}
    try {
      final encoded = _encode(WidgetSnapshot.empty());
      if (encoded != null) {
        await HomeWidget.saveWidgetData<String>(snapshotKey, encoded);
      }
    } catch (_) {}
    try {
      for (final provider in androidProviders) {
        await HomeWidget.updateWidget(qualifiedAndroidName: provider);
      }
      for (final kind in iosKinds) {
        await HomeWidget.updateWidget(iOSName: kind);
      }
    } catch (_) {}
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
