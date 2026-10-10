import 'package:flutter/material.dart';

/// Where the Assistant was opened from. All entry points funnel into the
/// same canonical Assistant; only this context changes ( §2–§3 ).
///
/// Transient and in-memory only: cleared on logout via
/// [StudentAssistantController.clearData]. Never persisted, never synced.
enum AssistantOrigin {
  global,
  home,
  planning,
  tasks,
  study,
  subject,
  exam,
  sprintx,
  focus,
  deepFocus,
  sleep,
  progress,
  rewards,
  resources,
  tools,
  workspace,
  settings,
}

/// Contextual launch payload for the canonical Assistant.
@immutable
class AssistantLaunchContext {
  const AssistantLaunchContext({
    this.origin = AssistantOrigin.global,
    this.subjectId,
    this.subjectName,
    this.taskId,
    this.taskTitle,
    this.examId,
    this.examTitle,
  });

  static const global = AssistantLaunchContext();

  final AssistantOrigin origin;
  final String? subjectId;
  final String? subjectName;
  final String? taskId;
  final String? taskTitle;
  final String? examId;
  final String? examTitle;

  bool get isGlobal => origin == AssistantOrigin.global;

  /// Short contextual line shown under the hero when launched from a
  /// feature. Null for global launches.
  String? get contextLine {
    switch (origin) {
      case AssistantOrigin.global:
      case AssistantOrigin.home:
        return null;
      case AssistantOrigin.planning:
        return 'Looking at your plan';
      case AssistantOrigin.tasks:
        return 'Looking at your tasks';
      case AssistantOrigin.study:
      case AssistantOrigin.subject:
        if (subjectName != null && subjectName!.isNotEmpty) {
          return 'Looking at $subjectName';
        }
        return 'Looking at study';
      case AssistantOrigin.exam:
        if (examTitle != null && examTitle!.isNotEmpty) {
          return 'Looking at $examTitle';
        }
        return 'Looking at your exams';
      case AssistantOrigin.sprintx:
      case AssistantOrigin.focus:
        return 'Looking at SprintX';
      case AssistantOrigin.deepFocus:
        return 'Looking at Deep Focus';
      case AssistantOrigin.sleep:
        return 'Looking at your sleep';
      case AssistantOrigin.progress:
        return 'Looking at your progress';
      case AssistantOrigin.rewards:
        return 'Looking at rewards';
      case AssistantOrigin.resources:
        return 'Looking at resources';
      case AssistantOrigin.tools:
        return 'Looking at tools';
      case AssistantOrigin.workspace:
        return 'Looking at your workspace';
      case AssistantOrigin.settings:
        return null;
    }
  }
}
