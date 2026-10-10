import 'package:flutter/material.dart';

/// Enum name without relying on dynamic dispatch (robust across all enums
/// used by the guide system, including older compiled forms).
String guideEnumName(Object value) =>
    value.toString().split('.').last;

/// Interactive guide system data model (learning layer only).
///
/// Guides describe navigation + ordered steps. They never duplicate feature
/// logic: expectations are evaluated against the REAL controllers
/// (Focus/Sleep/Tasks/Exams/Planning) and the REAL widget tree via
/// [GuideTargetAnchor] ids.
enum GuideCategory {
  startHere('Start here'),
  planStudy('Plan & study'),
  focus('Focus'),
  studentLife('Student life'),
  tools('Tools'),
  assistant('Assistant');

  const GuideCategory(this.label);
  final String label;
}

enum GuideDifficulty { beginner, intermediate, advanced }

/// Where a step takes the user. Navigation reuses existing [AppRouter]
/// helpers — the engine never pushes routes itself.
enum GuideDestination {
  home,
  plan,
  tasks,
  exams,
  focusCenter,
  sleep,
  assistant,
  rewards,
  progress,
  toolsHub,
  learnCenter,
}

/// What must happen for a step to complete. `continueTap` steps require the
/// user to read and press Continue — honest because the copy instructs the
/// user to perform the real action first. State-backed expectations are
/// verified against live controllers.
enum GuideExpectationKind {
  /// Destination reached (navigation settled). Always the implicit first
  /// gate of a step that declares a destination.
  screenSeen,

  /// User pressed Continue after performing the described real action.
  continueTap,

  /// A real focus session is running ([FocusController.hasActiveSession]).
  focusSessionStarted,

  /// A sleep schedule exists ([SleepController.hasSchedule]).
  sleepScheduleSaved,

  /// Task count grew past the baseline captured when the step started.
  taskCreated,

  /// Exam count grew past the baseline captured when the step started.
  examCreated,

  /// Planning block count grew past the baseline captured at step start.
  planningBlockCreated,
}

@immutable
class GuideStep {
  const GuideStep({
    required this.id,
    required this.title,
    required this.message,
    this.destination,
    this.targetAnchorId,
    this.expectation = GuideExpectationKind.continueTap,
    this.expectationPayload = 0,
    this.hint = 'Try the highlighted control to continue.',
    this.navigateOnEnter = true,
  });

  final String id;
  final String title;
  final String message;

  /// Screen this step lives on. Null = stays on the current screen.
  final GuideDestination? destination;

  /// Registered [GuideTargetAnchor] id to spotlight. Null = no spotlight
  /// (coach card only). Missing anchors degrade gracefully, never crash.
  final String? targetAnchorId;

  final GuideExpectationKind expectation;

  /// Reserved payload (e.g. expected minutes). Currently informational.
  final int expectationPayload;

  /// Gentle hint when the user interacts elsewhere.
  final String hint;

  /// Navigate to [destination] when the step becomes current.
  final bool navigateOnEnter;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'destination':
            destination == null ? null : guideEnumName(destination!),
        'targetAnchorId': targetAnchorId,
        'expectation': expectation.name,
        'expectationPayload': expectationPayload,
        'hint': hint,
        'navigateOnEnter': navigateOnEnter,
      };

  factory GuideStep.fromJson(Map<String, dynamic> json) {
    T? enumByName<T>(List<T> values, Object? name) {
      for (final v in values) {
        if (guideEnumName(v as Object) == name) {
          return v;
        }
      }
      return null;
    }

    return GuideStep(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      destination:
          enumByName(GuideDestination.values, json['destination']),
      targetAnchorId: json['targetAnchorId'] as String?,
      expectation: enumByName(
            GuideExpectationKind.values,
            json['expectation'],
          ) ??
          GuideExpectationKind.continueTap,
      expectationPayload: (json['expectationPayload'] as num?)?.toInt() ?? 0,
      hint: (json['hint'] as String?) ?? '',
      navigateOnEnter: (json['navigateOnEnter'] as bool?) ?? true,
    );
  }
}

@immutable
class GuideDefinition {
  const GuideDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.difficulty = GuideDifficulty.beginner,
    this.estimatedSeconds = 60,
    this.unlockAfter = const [],
    this.steps = const [],
  }) : prerequisiteIds = unlockAfter;

  final String id;
  final String title;
  final String description;
  final GuideCategory category;
  final GuideDifficulty difficulty;
  final int estimatedSeconds;

  /// Guide ids that must be completed before this unlocks (progressive
  /// discovery). Empty = always visible.
  final List<String> unlockAfter;

  final List<String> prerequisiteIds;

  final List<GuideStep> steps;

  String get durationLabel {
    if (estimatedSeconds < 60) {
      return '~$estimatedSeconds sec';
    }
    final m = (estimatedSeconds / 60).round();
    return '~$m min';
  }
}

enum GuideStatus { notStarted, inProgress, completed }

@immutable
class GuideProgress {
  const GuideProgress({
    this.status = GuideStatus.notStarted,
    this.stepIndex = 0,
  });

  final GuideStatus status;
  final int stepIndex;

  Map<String, dynamic> toJson() => {
        'status': guideEnumName(status),
        'stepIndex': stepIndex,
      };

  factory GuideProgress.fromJson(Map<String, dynamic> json) {
    GuideStatus status = GuideStatus.notStarted;
    for (final s in GuideStatus.values) {
      if (guideEnumName(s) == json['status']) {
        status = s;
      }
    }
    return GuideProgress(
      status: status,
      stepIndex: (json['stepIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
