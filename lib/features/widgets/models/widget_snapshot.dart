import 'package:flutter/foundation.dart';

/// Compact, serializable projection of Student OS state for home-screen
/// widgets. Every field is nullable/tolerant: a corrupt or partial payload
/// degrades to empty states, never a crash. No auth material, no secrets,
/// no full databases — only what configured widgets render.
@immutable
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.userId,
    required this.generatedAt,
    this.loggedOut = false,
    this.nextExam,
    this.upcomingExams = const [],
    this.examPrep,
    this.todayStudy,
    this.subjectProgress,
    this.nextAction,
    this.todayTasks,
    this.todayPlan,
    this.backlog,
    this.focus,
    this.focusStats,
    this.focusStreakDays,
    this.assistant,
    this.sleep,
    this.dayBalance,
    this.brief,
    this.lockedWidgetIds = const [],
    this.version = 1,
  });

  final String userId;
  final DateTime generatedAt;
  final bool loggedOut;
  final ExamWidgetData? nextExam;
  final List<ExamWidgetData> upcomingExams;
  final ExamPrepWidgetData? examPrep;
  final StudyWidgetData? todayStudy;
  final SubjectProgressWidgetData? subjectProgress;
  final ActionWidgetData? nextAction;
  final TasksWidgetData? todayTasks;
  final PlanWidgetData? todayPlan;
  final BacklogWidgetData? backlog;
  final FocusWidgetData? focus;
  final FocusStatsWidgetData? focusStats;
  final int? focusStreakDays;
  final AssistantWidgetData? assistant;
  final SleepWidgetData? sleep;
  final DayBalanceWidgetData? dayBalance;
  final BriefWidgetData? brief;

  /// Widget ids the native side must render locked (Pro-gated at tap).
  final List<String> lockedWidgetIds;
  final int version;

  bool isLocked(String widgetId) => lockedWidgetIds.contains(widgetId);

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'generatedAt': generatedAt.toIso8601String(),
        'loggedOut': loggedOut,
        'nextExam': nextExam?.toJson(),
        'upcomingExams': upcomingExams.map((e) => e.toJson()).toList(),
        'examPrep': examPrep?.toJson(),
        'todayStudy': todayStudy?.toJson(),
        'subjectProgress': subjectProgress?.toJson(),
        'nextAction': nextAction?.toJson(),
        'todayTasks': todayTasks?.toJson(),
        'todayPlan': todayPlan?.toJson(),
        'backlog': backlog?.toJson(),
        'focus': focus?.toJson(),
        'focusStats': focusStats?.toJson(),
        'focusStreakDays': focusStreakDays,
        'assistant': assistant?.toJson(),
        'sleep': sleep?.toJson(),
        'dayBalance': dayBalance?.toJson(),
        'brief': brief?.toJson(),
        'lockedWidgetIds': lockedWidgetIds,
        'version': version,
      };

  /// Never throws: any malformed input yields an empty (logged-out-safe)
  /// snapshot so widgets show empty states instead of stale data.
  factory WidgetSnapshot.fromJson(Map<String, dynamic> json) {
    DateTime generatedAt;
    try {
      generatedAt = DateTime.parse(_strOpt(json['generatedAt']) ?? '');
    } catch (_) {
      generatedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }
    T? read<T>(String key, T Function(Map<String, dynamic>) parse) {
      try {
        final raw = json[key];
        if (raw is Map) {
          return parse(Map<String, dynamic>.from(raw));
        }
      } catch (_) {}
      return null;
    }

    List<ExamWidgetData> upcoming = const [];
    try {
      final raw = json['upcomingExams'];
      if (raw is List) {
        upcoming = raw
            .whereType<Map>()
            .map((e) {
              try {
                return ExamWidgetData.fromJson(
                  Map<String, dynamic>.from(e),
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<ExamWidgetData>()
            .take(4)
            .toList();
      }
    } catch (_) {}

    List<String> locked = const [];
    try {
      final raw = json['lockedWidgetIds'];
      if (raw is List) locked = raw.map((e) => e.toString()).toList();
    } catch (_) {}

    return WidgetSnapshot(
      userId: _str(json['userId']),
      generatedAt: generatedAt,
      loggedOut: _bool(json['loggedOut'], false),
      nextExam: read('nextExam', ExamWidgetData.fromJson),
      upcomingExams: upcoming,
      examPrep: read('examPrep', ExamPrepWidgetData.fromJson),
      todayStudy: read('todayStudy', StudyWidgetData.fromJson),
      subjectProgress:
          read('subjectProgress', SubjectProgressWidgetData.fromJson),
      nextAction: read('nextAction', ActionWidgetData.fromJson),
      todayTasks: read('todayTasks', TasksWidgetData.fromJson),
      todayPlan: read('todayPlan', PlanWidgetData.fromJson),
      backlog: read('backlog', BacklogWidgetData.fromJson),
      focus: read('focus', FocusWidgetData.fromJson),
      focusStats: read('focusStats', FocusStatsWidgetData.fromJson),
      focusStreakDays: _int(json['focusStreakDays']),
      assistant: read('assistant', AssistantWidgetData.fromJson),
      sleep: read('sleep', SleepWidgetData.fromJson),
      dayBalance: read('dayBalance', DayBalanceWidgetData.fromJson),
      brief: read('brief', BriefWidgetData.fromJson),
      lockedWidgetIds: locked,
      version: _int(json['version']) ?? 1,
    );
  }

  static WidgetSnapshot empty({String userId = '', bool loggedOut = true}) {
    return WidgetSnapshot(
      userId: userId,
      generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      loggedOut: loggedOut,
    );
  }

  /// Minutes since generation; null when the timestamp is unusable.
  int? get ageMinutes {
    try {
      return DateTime.now().difference(generatedAt).inMinutes;
    } catch (_) {
      return null;
    }
  }
}

@immutable
class ExamWidgetData {
  const ExamWidgetData({
    required this.id,
    required this.title,
    this.subject = '',
    this.dateLabel = '',
    this.daysLeft,
    this.windowDays,
  });

  final String id;
  final String title;
  final String subject;
  final String dateLabel;
  final int? daysLeft;
  final int? windowDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'dateLabel': dateLabel,
        'daysLeft': daysLeft,
        'windowDays': windowDays,
      };

  factory ExamWidgetData.fromJson(Map<String, dynamic> json) {
    return ExamWidgetData(
      id: _str(json['id']),
      title: _str(json['title']),
      subject: _str(json['subject']),
      dateLabel: _str(json['dateLabel']),
      daysLeft: _int(json['daysLeft']),
      windowDays: _int(json['windowDays']),
    );
  }
}

@immutable
class ExamPrepWidgetData {
  const ExamPrepWidgetData({
    required this.examId,
    required this.title,
    this.daysLeft,
    this.targetTitle,
    this.targetMinutes,
  });

  final String examId;
  final String title;
  final int? daysLeft;
  final String? targetTitle;
  final int? targetMinutes;

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'title': title,
        'daysLeft': daysLeft,
        'targetTitle': targetTitle,
        'targetMinutes': targetMinutes,
      };

  factory ExamPrepWidgetData.fromJson(Map<String, dynamic> json) {
    return ExamPrepWidgetData(
      examId: _str(json['examId']),
      title: _str(json['title']),
      daysLeft: _int(json['daysLeft']),
      targetTitle: _strOpt(json['targetTitle']),
      targetMinutes: _int(json['targetMinutes']),
    );
  }
}

@immutable
class StudyWidgetData {
  const StudyWidgetData({
    this.plannedMinutes = 0,
    this.completedMinutes = 0,
  });

  final int plannedMinutes;
  final int completedMinutes;
  int get remainingMinutes =>
      (plannedMinutes - completedMinutes).clamp(0, 1 << 30);

  Map<String, dynamic> toJson() => {
        'plannedMinutes': plannedMinutes,
        'completedMinutes': completedMinutes,
      };

  factory StudyWidgetData.fromJson(Map<String, dynamic> json) {
    return StudyWidgetData(
      plannedMinutes: _int(json['plannedMinutes']) ?? 0,
      completedMinutes: _int(json['completedMinutes']) ?? 0,
    );
  }
}

@immutable
class SubjectProgressWidgetData {
  const SubjectProgressWidgetData({
    required this.subjectId,
    required this.subjectName,
    this.studyPercent,
    this.revisionDone,
    this.revisionTotal,
  });

  final String subjectId;
  final String subjectName;
  final int? studyPercent;
  final int? revisionDone;
  final int? revisionTotal;

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'studyPercent': studyPercent,
        'revisionDone': revisionDone,
        'revisionTotal': revisionTotal,
      };

  factory SubjectProgressWidgetData.fromJson(Map<String, dynamic> json) {
    return SubjectProgressWidgetData(
      subjectId: _str(json['subjectId']),
      subjectName: _str(json['subjectName']),
      studyPercent: _int(json['studyPercent']),
      revisionDone: _int(json['revisionDone']),
      revisionTotal: _int(json['revisionTotal']),
    );
  }
}

@immutable
class ActionWidgetData {
  const ActionWidgetData({
    required this.title,
    this.subtitle = '',
    this.minutes,
    this.reason = '',
    this.taskId,
    this.kind = 'task',
  });

  final String title;
  final String subtitle;
  final int? minutes;
  final String reason;
  final String? taskId;

  /// task | focus | assistant
  final String kind;

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'minutes': minutes,
        'reason': reason,
        'taskId': taskId,
        'kind': kind,
      };

  factory ActionWidgetData.fromJson(Map<String, dynamic> json) {
    return ActionWidgetData(
      title: _str(json['title']),
      subtitle: _str(json['subtitle']),
      minutes: _int(json['minutes']),
      reason: _str(json['reason']),
      taskId: _strOpt(json['taskId']),
      kind: (_strOpt(json['kind'])) ?? 'task',
    );
  }
}

@immutable
class TasksWidgetData {
  const TasksWidgetData({
    this.remaining = 0,
    this.completed = 0,
    this.topTitle,
    this.topPriority,
  });

  final int remaining;
  final int completed;
  final String? topTitle;
  final String? topPriority;

  Map<String, dynamic> toJson() => {
        'remaining': remaining,
        'completed': completed,
        'topTitle': topTitle,
        'topPriority': topPriority,
      };

  factory TasksWidgetData.fromJson(Map<String, dynamic> json) {
    return TasksWidgetData(
      remaining: _int(json['remaining']) ?? 0,
      completed: _int(json['completed']) ?? 0,
      topTitle: _strOpt(json['topTitle']),
      topPriority: _strOpt(json['topPriority']),
    );
  }
}

@immutable
class PlanItemData {
  const PlanItemData({
    required this.time,
    required this.title,
    this.minutes,
  });

  final String time;
  final String title;
  final int? minutes;

  Map<String, dynamic> toJson() => {
        'time': time,
        'title': title,
        'minutes': minutes,
      };

  factory PlanItemData.fromJson(Map<String, dynamic> json) {
    return PlanItemData(
      time: _str(json['time']),
      title: _str(json['title']),
      minutes: _int(json['minutes']),
    );
  }
}

@immutable
class PlanWidgetData {
  const PlanWidgetData({
    this.items = const [],
    this.nextTitle,
    this.nextMinutes,
  });

  final List<PlanItemData> items;
  final String? nextTitle;
  final int? nextMinutes;

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'nextTitle': nextTitle,
        'nextMinutes': nextMinutes,
      };

  factory PlanWidgetData.fromJson(Map<String, dynamic> json) {
    var items = const <PlanItemData>[];
    try {
      final raw = json['items'];
      if (raw is List) {
        items = raw
            .whereType<Map>()
            .map((e) {
              try {
                return PlanItemData.fromJson(
                  Map<String, dynamic>.from(e),
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<PlanItemData>()
            .take(6)
            .toList();
      }
    } catch (_) {}
    return PlanWidgetData(
      items: items,
      nextTitle: _strOpt(json['nextTitle']),
      nextMinutes: _int(json['nextMinutes']),
    );
  }
}

@immutable
class BacklogWidgetData {
  const BacklogWidgetData({
    this.unfinished = 0,
    this.overdue = 0,
    this.topTitle,
  });

  final int unfinished;
  final int overdue;
  final String? topTitle;

  Map<String, dynamic> toJson() => {
        'unfinished': unfinished,
        'overdue': overdue,
        'topTitle': topTitle,
      };

  factory BacklogWidgetData.fromJson(Map<String, dynamic> json) {
    return BacklogWidgetData(
      unfinished: _int(json['unfinished']) ?? 0,
      overdue: _int(json['overdue']) ?? 0,
      topTitle: _strOpt(json['topTitle']),
    );
  }
}

@immutable
class FocusWidgetData {
  const FocusWidgetData({
    this.hasActive = false,
    this.title,
    this.remainingLabel,
    this.mode,
  });

  final bool hasActive;
  final String? title;
  final String? remainingLabel;
  final String? mode;

  Map<String, dynamic> toJson() => {
        'hasActive': hasActive,
        'title': title,
        'remainingLabel': remainingLabel,
        'mode': mode,
      };

  factory FocusWidgetData.fromJson(Map<String, dynamic> json) {
    return FocusWidgetData(
      hasActive: _bool(json['hasActive'], false),
      title: _strOpt(json['title']),
      remainingLabel: _strOpt(json['remainingLabel']),
      mode: _strOpt(json['mode']),
    );
  }
}

@immutable
class FocusStatsWidgetData {
  const FocusStatsWidgetData({
    this.todayMinutes = 0,
    this.sessionsToday = 0,
    this.weekMinutes = 0,
  });

  final int todayMinutes;
  final int sessionsToday;
  final int weekMinutes;

  Map<String, dynamic> toJson() => {
        'todayMinutes': todayMinutes,
        'sessionsToday': sessionsToday,
        'weekMinutes': weekMinutes,
      };

  factory FocusStatsWidgetData.fromJson(Map<String, dynamic> json) {
    return FocusStatsWidgetData(
      todayMinutes: _int(json['todayMinutes']) ?? 0,
      sessionsToday: _int(json['sessionsToday']) ?? 0,
      weekMinutes: _int(json['weekMinutes']) ?? 0,
    );
  }
}

@immutable
class AssistantWidgetData {
  const AssistantWidgetData({
    required this.headline,
    this.reason = '',
    this.minutes,
  });

  final String headline;
  final String reason;
  final int? minutes;

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'reason': reason,
        'minutes': minutes,
      };

  factory AssistantWidgetData.fromJson(Map<String, dynamic> json) {
    return AssistantWidgetData(
      headline: _str(json['headline']),
      reason: _str(json['reason']),
      minutes: _int(json['minutes']),
    );
  }
}

@immutable
class SleepWidgetData {
  const SleepWidgetData({
    required this.bedtimeLabel,
    required this.wakeLabel,
    required this.durationLabel,
  });

  final String bedtimeLabel;
  final String wakeLabel;
  final String durationLabel;

  Map<String, dynamic> toJson() => {
        'bedtimeLabel': bedtimeLabel,
        'wakeLabel': wakeLabel,
        'durationLabel': durationLabel,
      };

  factory SleepWidgetData.fromJson(Map<String, dynamic> json) {
    return SleepWidgetData(
      bedtimeLabel: _str(json['bedtimeLabel']),
      wakeLabel: _str(json['wakeLabel']),
      durationLabel: _str(json['durationLabel']),
    );
  }
}

@immutable
class DayBalanceWidgetData {
  const DayBalanceWidgetData({
    this.studyMinutes = 0,
    this.focusMinutes = 0,
    this.tasksRemaining = 0,
    this.sleepLabel,
  });

  final int studyMinutes;
  final int focusMinutes;
  final int tasksRemaining;
  final String? sleepLabel;

  Map<String, dynamic> toJson() => {
        'studyMinutes': studyMinutes,
        'focusMinutes': focusMinutes,
        'tasksRemaining': tasksRemaining,
        'sleepLabel': sleepLabel,
      };

  factory DayBalanceWidgetData.fromJson(Map<String, dynamic> json) {
    return DayBalanceWidgetData(
      studyMinutes: _int(json['studyMinutes']) ?? 0,
      focusMinutes: _int(json['focusMinutes']) ?? 0,
      tasksRemaining: _int(json['tasksRemaining']) ?? 0,
      sleepLabel: _strOpt(json['sleepLabel']),
    );
  }
}

@immutable
class BriefWidgetData {
  const BriefWidgetData({
    required this.greeting,
    this.lines = const [],
  });

  final String greeting;
  final List<String> lines;

  Map<String, dynamic> toJson() => {
        'greeting': greeting,
        'lines': lines,
      };

  factory BriefWidgetData.fromJson(Map<String, dynamic> json) {
    var lines = const <String>[];
    try {
      final raw = json['lines'];
      if (raw is List) {
        lines = raw.map((e) => e.toString()).take(6).toList();
      }
    } catch (_) {}
    return BriefWidgetData(
      greeting: _str(json['greeting']),
      lines: lines,
    );
  }
}

/// Tolerant converters: native/widget payloads may carry wrong types after
/// corruption — coerce instead of throwing.
String _str(Object? v) => v?.toString() ?? '';
String? _strOpt(Object? v) => v?.toString();
int? _int(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
bool _bool(Object? v, bool fallback) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final t = v.toLowerCase();
    if (t == 'true') return true;
    if (t == 'false') return false;
  }
  return fallback;
}
