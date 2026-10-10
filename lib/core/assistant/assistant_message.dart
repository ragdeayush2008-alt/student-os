import 'package:flutter/foundation.dart';

/// A single persisted turn in the Assistant conversation (P1 foundation).
///
/// Minimal by design: role + text + timestamp (+ optional title/kind for
/// assistant turns). Structured follow-ups (ordinals, durations,
/// confirmations) keep working through the existing ephemeral
/// [AssistantConversationContext]; this list is the visible, persisted
/// history P2 builds on.
enum AssistantMessageRole { user, assistant }

@immutable
class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.title,
    this.cardKind,
  });

  final AssistantMessageRole role;
  final String text;
  final DateTime timestamp;

  /// Assistant turns may carry the result card title for history rendering.
  final String? title;

  /// Assistant card kind name (e.g. `confirmation`, `error`) for styling.
  final String? cardKind;

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'title': title,
        'cardKind': cardKind,
      };

  /// Tolerant: skips nothing, defaults everything — a corrupt entry degrades
  /// to a plain user message instead of breaking history load.
  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(json['timestamp'] as String? ?? '');
    } catch (_) {
      timestamp = DateTime.now();
    }
    return AssistantMessage(
      role: (json['role'] as String?) == 'assistant'
          ? AssistantMessageRole.assistant
          : AssistantMessageRole.user,
      text: (json['text'] as String?) ?? '',
      timestamp: timestamp,
      title: json['title'] as String?,
      cardKind: json['cardKind'] as String?,
    );
  }
}
