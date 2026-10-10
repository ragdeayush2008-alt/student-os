import 'package:flutter/foundation.dart';

import '../../features/planning/services/planning_engine.dart';
import 'assistant_planning_engine.dart';
import 'student_assistant_action.dart';
import 'student_assistant_intent.dart';

/// Structured response card classification (Phase 4 §20).
///
/// The UI selects a presentational treatment per kind; it never changes the
/// underlying data or actions.
enum AssistantCardKind {
  neutral,
  recommendation,
  nextAction,
  todayPlan,
  studyTopic,
  revision,
  practice,
  exam,
  schedulePreview,
  confirmation,
  success,
  empty,
  error,
  clarification,
}

/// One actionable row inside a structured plan/recommendation card.
@immutable
class AssistantResultStep {
  const AssistantResultStep({
    required this.label,
    this.detail,
    this.minutes,
    this.isPrimary = false,
    this.id,
    this.kind,
    this.subjectId,
    this.chapterId,
    this.topicId,
    this.taskId,
    this.examId,
  });

  final String label;
  final String? detail;
  final int? minutes;
  final bool isPrimary;

  /// Stable identity used by ephemeral conversation follow-ups
  /// (e.g. "plan the first one").
  final String? id;

  /// Entity kind: 'topic', 'subject', 'task', 'exam', 'block'.
  final String? kind;
  final String? subjectId;
  final String? chapterId;
  final String? topicId;
  final String? taskId;
  final String? examId;
}

@immutable
class StudentAssistantResult {
  const StudentAssistantResult({
    required this.success,
    required this.intent,
    required this.title,
    required this.message,
    this.explanation,
    this.primaryAction,
    this.secondaryActions = const [],
    this.suggestedPrompts = const [],
    this.previewItems = const [],
    this.planResult,
    this.proposal,
    this.requiresConfirmation = false,
    this.clarificationRequired = false,
    this.clarificationQuestion,
    this.clarificationChoices = const [],
    this.cardKind = AssistantCardKind.neutral,
    this.contextLine,
    this.steps = const [],
  });

  final bool success;
  final StudentAssistantIntent intent;
  final String title;
  final String message;
  final String? explanation;
  final StudentAssistantAction? primaryAction;
  final List<StudentAssistantAction> secondaryActions;
  final List<String> suggestedPrompts;
  final List<String> previewItems;
  final DailyPlanResult? planResult;

  /// P2 proposal attached to preview results (day plan / fix-day moves /
  /// catch-up / exam creations). The controller stages it as pending and
  /// applies it through existing controllers only after confirmation.
  final AssistantDayPlan? proposal;
  final bool requiresConfirmation;
  final bool clarificationRequired;
  final String? clarificationQuestion;
  final List<String> clarificationChoices;

  /// Presentational classification used by the Assistant UI.
  final AssistantCardKind cardKind;

  /// A short, student-friendly sentence describing the context the assistant
  /// looked at (e.g. "Today's plan · 3 blocks · 2h 15m"). Never raw IDs.
  final String? contextLine;

  /// Optional structured rows for plan/recommendation cards.
  final List<AssistantResultStep> steps;

  bool get hasAction => primaryAction != null;
  bool get hasProposal => proposal != null && !proposal!.isEmpty;
  bool get hasPlan => planResult != null && planResult!.hasItems;
  bool get hasSteps => steps.isNotEmpty;

  StudentAssistantResult copyWith({
    AssistantCardKind? cardKind,
    String? contextLine,
    List<AssistantResultStep>? steps,
    AssistantDayPlan? proposal,
  }) {
    return StudentAssistantResult(
      success: success,
      intent: intent,
      title: title,
      message: message,
      explanation: explanation,
      primaryAction: primaryAction,
      secondaryActions: secondaryActions,
      suggestedPrompts: suggestedPrompts,
      previewItems: previewItems,
      planResult: planResult,
      proposal: proposal ?? this.proposal,
      requiresConfirmation: requiresConfirmation,
      clarificationRequired: clarificationRequired,
      clarificationQuestion: clarificationQuestion,
      clarificationChoices: clarificationChoices,
      cardKind: cardKind ?? this.cardKind,
      contextLine: contextLine ?? this.contextLine,
      steps: steps ?? this.steps,
    );
  }

  static StudentAssistantResult empty({
    String title = 'How can I help you?',
    String message = 'Ask what to study, plan available time, or check revision.',
    List<String> suggestedPrompts = const [
      'What should I do?',
      'I have 2 hours',
      'What should I revise?',
      'Continue my day',
      'Show my exams',
    ],
  }) {
    return StudentAssistantResult(
      success: true,
      intent: const StudentAssistantIntent(
        rawText: '',
        intentType: AssistantIntentType.greeting,
      ),
      title: title,
      message: message,
      suggestedPrompts: suggestedPrompts,
    );
  }

  static StudentAssistantResult clarification({
    required StudentAssistantIntent intent,
    required String question,
    required List<String> choices,
    String title = 'Clarification Needed',
  }) {
    return StudentAssistantResult(
      success: true,
      intent: intent,
      title: title,
      message: question,
      clarificationRequired: true,
      clarificationQuestion: question,
      clarificationChoices: choices,
    );
  }

  static StudentAssistantResult error({
    required StudentAssistantIntent intent,
    required String message,
    String title = 'Unable to Process',
  }) {
    return StudentAssistantResult(
      success: false,
      intent: intent,
      title: title,
      message: message,
      suggestedPrompts: const [
        'What should I do?',
        'I have 2 hours',
        'What should I revise?',
      ],
    );
  }
}
