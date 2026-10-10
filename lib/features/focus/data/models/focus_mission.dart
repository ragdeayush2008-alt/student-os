enum FocusMode {
  timer,
  stopwatch,
  focusGuard;

  static FocusMode fromString(String? name) {
    if (name == null) return FocusMode.timer;
    switch (name) {
      case 'timer':
      case 'quick':
      case 'pomodoro':
      case 'deepFocus':
      case 'examSprint':
        return FocusMode.timer;
      case 'stopwatch':
        return FocusMode.stopwatch;
      case 'focusGuard':
      case 'guard':
        return FocusMode.focusGuard;
      default:
        return FocusMode.timer;
    }
  }
}

enum FocusPhase {
  preparing,
  focusing,
  shortBreak,
  longBreak,
  completed,
  paused,
  interrupted,
}

enum DistractionProtectionLevel { off, light, strict, deep }

enum SessionOutcome { completed, partial, interrupted, cancelled }

enum FocusState {
  idle,
  active,
  paused,
  completed,
  cancelled,
}

extension FocusModeExtension on FocusMode {
  String get label {
    switch (this) {
      case FocusMode.timer:
        return 'Timer';
      case FocusMode.stopwatch:
        return 'Stopwatch';
      case FocusMode.focusGuard:
        return 'Focus Guard';
    }
  }
}

extension DistractionProtectionLevelExtension on DistractionProtectionLevel {
  String get label {
    switch (this) {
      case DistractionProtectionLevel.off:
        return 'Off';
      case DistractionProtectionLevel.light:
        return 'Light';
      case DistractionProtectionLevel.strict:
        return 'Strict';
      case DistractionProtectionLevel.deep:
        return 'Deep';
    }
  }
}

class FocusMission {
  FocusMission({
    required this.id,
    required this.objective,
    this.subjectId,
    this.subjectName,
    this.taskId,
    this.examId,
    this.topicId,
    this.chapterId,
    this.mode = FocusMode.timer,
    this.plannedDuration = const Duration(minutes: 25),
    this.distractionProtection = DistractionProtectionLevel.off,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String objective;
  final String? subjectId;
  final String? subjectName;
  final String? taskId;
  final String? examId;
  final String? topicId;
  final String? chapterId;
  final FocusMode mode;
  final Duration plannedDuration;
  final DistractionProtectionLevel distractionProtection;
  final DateTime createdAt;

  String get modeLabel => mode.label;

  bool get hasConnectedTask => taskId != null;
  bool get hasConnectedExam => examId != null;
  bool get hasConnectedSubject => subjectId != null || subjectName != null;
  bool get hasConnectedTopic => topicId != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'objective': objective,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'taskId': taskId,
    'examId': examId,
    if (topicId != null) 'topicId': topicId,
    if (chapterId != null) 'chapterId': chapterId,
    'mode': mode.name,
    'plannedDuration': plannedDuration.inSeconds,
    'distractionProtection': distractionProtection.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FocusMission.fromJson(Map<String, dynamic> json) => FocusMission(
    id: json['id'] as String? ?? '',
    objective: json['objective'] as String? ?? '',
    subjectId: json['subjectId'] as String?,
    subjectName: json['subjectName'] as String?,
    taskId: json['taskId'] as String?,
    examId: json['examId'] as String?,
    topicId: json['topicId'] as String?,
    chapterId: json['chapterId'] as String?,
    mode: FocusMode.fromString(json['mode'] as String?),
    plannedDuration: Duration(
      seconds: (json['plannedDuration'] as int?) ?? 1500,
    ),
    distractionProtection: DistractionProtectionLevel.values.firstWhere(
      (d) => d.name == json['distractionProtection'],
      orElse: () => DistractionProtectionLevel.off,
    ),
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
        : DateTime.now(),
  );
}

class FocusSession {
  FocusSession({
    required this.id,
    this.userId,
    this.missionId = '',
    this.objective = '',
    this.subjectId,
    this.subjectName,
    this.taskId,
    this.examId,
    this.topicId,
    this.chapterId,
    this.planningBlockId,
    this.mode = FocusMode.timer,
    FocusState? status,
    required this.startedAt,
    this.endedAt,
    this.pausedAt,
    this.totalPausedDuration = Duration.zero,
    this.elapsedWhenPaused = Duration.zero,
    this.actualDuration,
    this.durationSeconds,
    this.phase = FocusPhase.preparing,
    this.cycleCount = 0,
    this.cycleNumber = 0,
    this.pomodoroCycles = 0,
    this.focusDuration = const Duration(minutes: 25),
    this.breakDuration = const Duration(minutes: 5),
    this.distractionAttempts = 0,
    this.distractionsCaptured = 0,
    this.checkpointsCompleted = 0,
    this.sessionScore = 0,
    this.outcome,
    this.note = '',
    this.blockedPackages = const {},
    DateTime? createdAt,
    this.updatedAt,
  })  : status = status ?? _deduceInitialStatus(outcome, phase),
        createdAt = createdAt ?? startedAt;

  final String id;
  final String? userId;
  final String missionId;
  final String objective;
  final String? subjectId;
  final String? subjectName;
  final String? taskId;
  final String? examId;
  final String? topicId;
  final String? chapterId;
  /// Preserved PlanningBlock id when launched from a scheduled block.
  /// Nullable for backward compatibility with pre-CODE-5 sessions.
  final String? planningBlockId;
  final FocusMode mode;
  FocusState status;
  final DateTime startedAt;
  DateTime? endedAt;
  DateTime? pausedAt;
  Duration totalPausedDuration;
  Duration elapsedWhenPaused;
  Duration? actualDuration;
  final int? durationSeconds;
  FocusPhase phase;
  int cycleCount;
  int cycleNumber;
  int pomodoroCycles;
  final Duration focusDuration;
  final Duration breakDuration;
  int distractionAttempts;
  int distractionsCaptured;
  int checkpointsCompleted;
  int sessionScore;
  SessionOutcome? outcome;
  String note;
  Set<String> blockedPackages;
  final DateTime createdAt;
  DateTime? updatedAt;

  static FocusState _deduceInitialStatus(SessionOutcome? outcome, FocusPhase phase) {
    if (outcome == SessionOutcome.completed) return FocusState.completed;
    if (outcome != null) return FocusState.cancelled;
    if (phase == FocusPhase.paused) return FocusState.paused;
    if (phase == FocusPhase.completed) return FocusState.completed;
    if (phase == FocusPhase.interrupted) return FocusState.cancelled;
    return FocusState.active;
  }

  String get modeLabel => mode.label;

  bool get isMission => missionId.isNotEmpty && !missionId.startsWith('default_');

  DateTime? get completedAt => outcome == SessionOutcome.completed ? endedAt : null;
  DateTime? get cancelledAt => outcome != null && outcome != SessionOutcome.completed ? endedAt : null;

  Duration get plannedDuration {
    if (mode == FocusMode.stopwatch) {
      return Duration.zero;
    }
    if (durationSeconds != null) {
      return Duration(seconds: durationSeconds!);
    }
    return focusDuration;
  }

  Duration effectiveElapsedAt(DateTime now) {
    if (actualDuration != null) return actualDuration!;
    if (endedAt != null) {
      final diff = endedAt!.difference(startedAt) - totalPausedDuration;
      return diff.isNegative ? Duration.zero : diff;
    }
    if (status == FocusState.paused || phase == FocusPhase.paused || pausedAt != null) {
      return elapsedWhenPaused;
    }
    final running = now.difference(startedAt) - totalPausedDuration;
    return running.isNegative ? Duration.zero : running;
  }

  Duration get effectiveElapsed => effectiveElapsedAt(DateTime.now());

  Duration get actualFocusedDuration => actualDuration ?? effectiveElapsed;

  Duration get remaining {
    if (mode == FocusMode.stopwatch) {
      return Duration.zero;
    }
    final elapsed = effectiveElapsed.inSeconds;
    final planned = plannedDuration.inSeconds;
    final rem = planned - elapsed;
    return Duration(seconds: rem > 0 ? rem : 0);
  }

  double get progress {
    if (mode == FocusMode.stopwatch) {
      return 0.0;
    }
    final planned = plannedDuration.inSeconds;
    if (planned <= 0) return 0.0;
    return (effectiveElapsed.inSeconds / planned).clamp(0.0, 1.0);
  }

  bool get isComplete => status == FocusState.completed || outcome == SessionOutcome.completed;
  bool get isPaused => status == FocusState.paused || phase == FocusPhase.paused;
  bool get isRunning =>
      status == FocusState.active &&
      (phase == FocusPhase.focusing || phase == FocusPhase.preparing) &&
      outcome == null;
  bool get isActive =>
      (status == FocusState.active || status == FocusState.paused) &&
      outcome == null;

  FocusState get state => status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'missionId': missionId,
    'objective': objective,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'taskId': taskId,
    'examId': examId,
    if (topicId != null) 'topicId': topicId,
    if (chapterId != null) 'chapterId': chapterId,
    if (planningBlockId != null) 'planningBlockId': planningBlockId,
    'mode': mode.name,
    'status': status.name,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'pausedAt': pausedAt?.toIso8601String(),
    'totalPausedDuration': totalPausedDuration.inSeconds,
    'elapsedWhenPaused': elapsedWhenPaused.inSeconds,
    'actualDuration': (actualDuration ?? (endedAt != null ? effectiveElapsed : null))?.inSeconds,
    'durationSeconds': durationSeconds ?? (mode == FocusMode.stopwatch ? null : plannedDuration.inSeconds),
    'phase': phase.name,
    'cycleCount': cycleCount,
    'cycleNumber': cycleNumber,
    'pomodoroCycles': pomodoroCycles,
    'focusDuration': focusDuration.inSeconds,
    'breakDuration': breakDuration.inSeconds,
    'distractionAttempts': distractionAttempts,
    'distractionsCaptured': distractionsCaptured,
    'checkpointsCompleted': checkpointsCompleted,
    'sessionScore': sessionScore,
    'outcome': outcome?.name,
    'note': note,
    'blockedPackages': blockedPackages.toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    final outcomeStr = json['outcome'] as String?;
    final outcome = outcomeStr != null
        ? SessionOutcome.values.firstWhere(
            (o) => o.name == outcomeStr,
            orElse: () => SessionOutcome.interrupted,
          )
        : null;

    final phaseStr = json['phase'] as String?;
    final phase = phaseStr != null
        ? FocusPhase.values.firstWhere(
            (p) => p.name == phaseStr,
            orElse: () => FocusPhase.preparing,
          )
        : FocusPhase.preparing;

    final statusStr = json['status'] as String?;
    final status = statusStr != null
        ? FocusState.values.firstWhere(
            (s) => s.name == statusStr,
            orElse: () => _deduceInitialStatus(outcome, phase),
          )
        : _deduceInitialStatus(outcome, phase);

    final startedAtStr = json['startedAt'] as String?;
    final startedAt = startedAtStr != null
        ? (DateTime.tryParse(startedAtStr) ?? DateTime.now())
        : DateTime.now();

    final blockedPkgs = (json['blockedPackages'] as List<dynamic>?)
            ?.whereType<String>()
            .toSet() ??
        <String>{};

    final durationSecs = json['durationSeconds'] as int?;
    final focusDurationSecs = (json['focusDuration'] as int?) ?? (durationSecs ?? 1500);

    return FocusSession(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      missionId: json['missionId'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String?,
      taskId: json['taskId'] as String?,
      examId: json['examId'] as String?,
      topicId: json['topicId'] as String?,
      chapterId: json['chapterId'] as String?,
      planningBlockId: json['planningBlockId'] as String?,
      mode: FocusMode.fromString(json['mode'] as String?),
      status: status,
      startedAt: startedAt,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)
          : null,
      pausedAt: json['pausedAt'] != null
          ? DateTime.tryParse(json['pausedAt'] as String)
          : null,
      totalPausedDuration: Duration(
        seconds: (json['totalPausedDuration'] as int?) ?? 0,
      ),
      elapsedWhenPaused: Duration(
        seconds: (json['elapsedWhenPaused'] as int?) ?? 0,
      ),
      actualDuration: json['actualDuration'] != null
          ? Duration(seconds: json['actualDuration'] as int)
          : null,
      durationSeconds: durationSecs,
      phase: phase,
      cycleCount: json['cycleCount'] as int? ?? 0,
      cycleNumber: json['cycleNumber'] as int? ?? 0,
      pomodoroCycles: json['pomodoroCycles'] as int? ?? 0,
      focusDuration: Duration(seconds: focusDurationSecs),
      breakDuration: Duration(seconds: (json['breakDuration'] as int?) ?? 300),
      distractionAttempts: json['distractionAttempts'] as int? ?? 0,
      distractionsCaptured: json['distractionsCaptured'] as int? ?? 0,
      checkpointsCompleted: json['checkpointsCompleted'] as int? ?? 0,
      sessionScore: json['sessionScore'] as int? ?? 0,
      outcome: outcome,
      note: json['note'] as String? ?? '',
      blockedPackages: blockedPkgs,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? startedAt)
          : startedAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
