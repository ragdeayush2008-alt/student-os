import 'package:flutter/foundation.dart';

/// Proactive trigger kinds (P3). Each maps to an engine prompt the user can
/// tap — triggers never execute anything themselves (automation Level 1).
enum AssistantTriggerKind {
  fixDay('Fix My Day', 'Fix my day'),
  catchUp('Catch Up', "I'm behind"),
  examPrep('Exam Prep', 'Plan my exam'),
  overdueTask('Overdue', "What's urgent?"),
  sleepBoundary('Sleep Boundary', 'Fix my day'),
  sleepChanged('Sleep Changed', 'Plan my day'),
  aheadOfPlan('Ahead', 'What should I focus on?'),
  behindPlan('Behind', 'Fix my day');

  const AssistantTriggerKind(this.label, this.prompt);

  final String label;

  /// Engine prompt executed when the student taps the trigger.
  final String prompt;
}

/// One proactive, dismissable surfacing.
@immutable
class AssistantTrigger {
  const AssistantTrigger({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    this.detail,
  });

  /// Stable per-day id, e.g. `2026-10-04:fixDay`.
  final String id;
  final AssistantTriggerKind kind;
  final String title;
  final String message;
  final String? detail;
}

/// Per-day Assistant state (P3 daily loop).
///
/// Persisted per user; rolls over on date change (yesterday's flags never
/// leak into today). Records only what the loop needs: preparation,
// review, adaptations, dismissals, and a short visible activity log.
@immutable
class DailyAssistantState {
  const DailyAssistantState({
    required this.date,
    this.prepared = false,
    this.planGeneratedAt,
    this.planVersion = 0,
    this.reviewed = false,
    this.lastAdaptationAt,
    this.appliedSessions = 0,
    this.appliedMoves = 0,
    this.appliedCreations = 0,
    this.dismissedTriggerIds = const [],
    this.lastTriggerEvalKey,
    this.lastTriggerEvalAt,
    this.actionLog = const [],
    this.sleepFingerprint,
  });

  /// Calendar day (midnight) this state belongs to.
  final DateTime date;
  final bool prepared;
  final DateTime? planGeneratedAt;
  final int planVersion;
  final bool reviewed;
  final DateTime? lastAdaptationAt;
  final int appliedSessions;
  final int appliedMoves;
  final int appliedCreations;
  final List<String> dismissedTriggerIds;
  final String? lastTriggerEvalKey;
  final DateTime? lastTriggerEvalAt;

  /// User-visible log lines, newest last, capped at 20.
  final List<String> actionLog;

  /// Window label of the sleep schedule the current plan was built around.
  /// A mismatch means the schedule changed since preparation.
  final String? sleepFingerprint;

  static DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  bool isFor(DateTime t) {
    final d = dayOf(t);
    return date.year == d.year && date.month == d.month && date.day == d.day;
  }

  bool isDismissed(String triggerId) => dismissedTriggerIds.contains(
        triggerId,
      );

  DailyAssistantState copyWith({
    bool? prepared,
    DateTime? planGeneratedAt,
    bool clearPlanGeneratedAt = false,
    int? planVersion,
    bool? reviewed,
    DateTime? lastAdaptationAt,
    int? appliedSessions,
    int? appliedMoves,
    int? appliedCreations,
    List<String>? dismissedTriggerIds,
    String? lastTriggerEvalKey,
    DateTime? lastTriggerEvalAt,
    List<String>? actionLog,
    String? sleepFingerprint,
    bool clearSleepFingerprint = false,
  }) {
    return DailyAssistantState(
      date: date,
      prepared: prepared ?? this.prepared,
      planGeneratedAt: clearPlanGeneratedAt
          ? null
          : (planGeneratedAt ?? this.planGeneratedAt),
      planVersion: planVersion ?? this.planVersion,
      reviewed: reviewed ?? this.reviewed,
      lastAdaptationAt: lastAdaptationAt ?? this.lastAdaptationAt,
      appliedSessions: appliedSessions ?? this.appliedSessions,
      appliedMoves: appliedMoves ?? this.appliedMoves,
      appliedCreations: appliedCreations ?? this.appliedCreations,
      dismissedTriggerIds: dismissedTriggerIds ?? this.dismissedTriggerIds,
      lastTriggerEvalKey: lastTriggerEvalKey ?? this.lastTriggerEvalKey,
      lastTriggerEvalAt: lastTriggerEvalAt ?? this.lastTriggerEvalAt,
      actionLog: actionLog ?? this.actionLog,
      sleepFingerprint: clearSleepFingerprint
          ? null
          : (sleepFingerprint ?? this.sleepFingerprint),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'prepared': prepared,
        'planGeneratedAt': planGeneratedAt?.toIso8601String(),
        'planVersion': planVersion,
        'reviewed': reviewed,
        'lastAdaptationAt': lastAdaptationAt?.toIso8601String(),
        'appliedSessions': appliedSessions,
        'appliedMoves': appliedMoves,
        'appliedCreations': appliedCreations,
        'dismissedTriggerIds': dismissedTriggerIds,
        'lastTriggerEvalKey': lastTriggerEvalKey,
        'lastTriggerEvalAt': lastTriggerEvalAt?.toIso8601String(),
        'actionLog': actionLog,
        'sleepFingerprint': sleepFingerprint,
      };

  /// Tolerant: anything missing or corrupt degrades to a fresh state for
  /// the given reference day.
  factory DailyAssistantState.fromJson(
    Map<String, dynamic> json, {
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    DateTime date;
    try {
      date = DateTime.parse(json['date'] as String);
    } catch (_) {
      return DailyAssistantState(date: dayOf(now));
    }
    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return null;
      }
    }

    final state = DailyAssistantState(
      date: DateTime(date.year, date.month, date.day),
      prepared: (json['prepared'] as bool?) ?? false,
      planGeneratedAt: parseDate(json['planGeneratedAt']),
      planVersion: (json['planVersion'] as num?)?.toInt() ?? 0,
      reviewed: (json['reviewed'] as bool?) ?? false,
      lastAdaptationAt: parseDate(json['lastAdaptationAt']),
      appliedSessions: (json['appliedSessions'] as num?)?.toInt() ?? 0,
      appliedMoves: (json['appliedMoves'] as num?)?.toInt() ?? 0,
      appliedCreations: (json['appliedCreations'] as num?)?.toInt() ?? 0,
      dismissedTriggerIds: (json['dismissedTriggerIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastTriggerEvalKey: json['lastTriggerEvalKey'] as String?,
      lastTriggerEvalAt: parseDate(json['lastTriggerEvalAt']),
      actionLog: (json['actionLog'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sleepFingerprint: json['sleepFingerprint'] as String?,
    );
    // Rollover: stored state from another day never applies.
    if (!state.isFor(now)) return DailyAssistantState(date: dayOf(now));
    return state;
  }
}

/// Assistant preferences (P3 §23). Every toggle maps to real functionality;
/// all default to a calm, non-intrusive experience.
@immutable
class AssistantPreferences {
  const AssistantPreferences({
    this.proactiveEnabled = true,
    this.morningBriefing = true,
    this.eveningReview = true,
    this.sleepAwarePlanning = true,
    this.briefingNotification = true,
    this.eveningNotification = false,
  });

  final bool proactiveEnabled;
  final bool morningBriefing;
  final bool eveningReview;
  final bool sleepAwarePlanning;
  final bool briefingNotification;
  final bool eveningNotification;

  AssistantPreferences copyWith({
    bool? proactiveEnabled,
    bool? morningBriefing,
    bool? eveningReview,
    bool? sleepAwarePlanning,
    bool? briefingNotification,
    bool? eveningNotification,
  }) {
    return AssistantPreferences(
      proactiveEnabled: proactiveEnabled ?? this.proactiveEnabled,
      morningBriefing: morningBriefing ?? this.morningBriefing,
      eveningReview: eveningReview ?? this.eveningReview,
      sleepAwarePlanning: sleepAwarePlanning ?? this.sleepAwarePlanning,
      briefingNotification:
          briefingNotification ?? this.briefingNotification,
      eveningNotification:
          eveningNotification ?? this.eveningNotification,
    );
  }

  Map<String, dynamic> toJson() => {
        'proactiveEnabled': proactiveEnabled,
        'morningBriefing': morningBriefing,
        'eveningReview': eveningReview,
        'sleepAwarePlanning': sleepAwarePlanning,
        'briefingNotification': briefingNotification,
        'eveningNotification': eveningNotification,
      };

  factory AssistantPreferences.fromJson(Map<String, dynamic> json) {
    return AssistantPreferences(
      proactiveEnabled: (json['proactiveEnabled'] as bool?) ?? true,
      morningBriefing: (json['morningBriefing'] as bool?) ?? true,
      eveningReview: (json['eveningReview'] as bool?) ?? true,
      sleepAwarePlanning: (json['sleepAwarePlanning'] as bool?) ?? true,
      briefingNotification:
          (json['briefingNotification'] as bool?) ?? true,
      eveningNotification:
          (json['eveningNotification'] as bool?) ?? false,
    );
  }
}
