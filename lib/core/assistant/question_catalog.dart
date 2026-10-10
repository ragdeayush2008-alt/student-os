import 'package:flutter/material.dart';

import 'assistant_launch_context.dart';

/// Curated question catalog for the canonical Assistant.
///
/// Every entry resolves to REAL capability: engine prompts parse to
/// implemented intents (verified by unit tests), and `guideId` entries
/// launch the Interactive Guide Engine. Nothing here is decorative.
@immutable
class CatalogQuestion {
  const CatalogQuestion({
    required this.prompt,
    this.hint,
    this.guideId,
  });

  /// Exact text sent to `StudentAssistantController.ask`, or displayed for
  /// guide entries (guide launches via the teach-me interception).
  final String prompt;
  final String? hint;

  /// When non-null, tapping asks [prompt] which the Assistant routes to
  /// this interactive guide.
  final String? guideId;
}

@immutable
class QuestionCategory {
  const QuestionCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.questions,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<CatalogQuestion> questions;
}

abstract final class QuestionCatalog {
  static const List<QuestionCategory> categories = [
    QuestionCategory(
      id: 'today',
      label: 'Today',
      icon: Icons.today_rounded,
      questions: [
        CatalogQuestion(prompt: 'Plan my day'),
        CatalogQuestion(prompt: 'What should I do now?'),
        CatalogQuestion(prompt: 'I have 2 hours'),
        CatalogQuestion(prompt: "What's urgent?"),
        CatalogQuestion(prompt: 'Fix my day'),
        CatalogQuestion(prompt: "I'm behind"),
      ],
    ),
    QuestionCategory(
      id: 'study',
      label: 'Study',
      icon: Icons.menu_book_rounded,
      questions: [
        CatalogQuestion(prompt: 'What should I study?'),
        CatalogQuestion(prompt: 'What should I revise?'),
        CatalogQuestion(prompt: 'What am I neglecting?'),
        CatalogQuestion(prompt: 'Give me a 30-minute study session'),
      ],
    ),
    QuestionCategory(
      id: 'exams',
      label: 'Exams',
      icon: Icons.school_rounded,
      questions: [
        CatalogQuestion(prompt: 'Prepare for my exam'),
        CatalogQuestion(prompt: 'Build an exam plan'),
        CatalogQuestion(prompt: 'What should I prioritize for my exam?'),
        CatalogQuestion(prompt: 'Show my exams'),
      ],
    ),
    QuestionCategory(
      id: 'planning',
      label: 'Planning',
      icon: Icons.calendar_month_rounded,
      questions: [
        CatalogQuestion(prompt: 'Show today plan'),
        CatalogQuestion(prompt: 'Rebalance my day'),
        CatalogQuestion(prompt: 'Move unfinished tasks to tomorrow'),
        CatalogQuestion(prompt: 'Check my free time'),
      ],
    ),
    QuestionCategory(
      id: 'tasks',
      label: 'Tasks',
      icon: Icons.checklist_rounded,
      questions: [
        CatalogQuestion(prompt: 'Create a task'),
        CatalogQuestion(prompt: "What's overdue?"),
        CatalogQuestion(prompt: 'Show my tasks'),
        CatalogQuestion(prompt: 'What can I postpone?'),
      ],
    ),
    QuestionCategory(
      id: 'focus',
      label: 'Focus',
      icon: Icons.center_focus_strong_rounded,
      questions: [
        CatalogQuestion(prompt: 'Start a focus session'),
        CatalogQuestion(prompt: 'I only have 30 minutes'),
        CatalogQuestion(prompt: 'I have 45 minutes'),
        CatalogQuestion(prompt: 'What should I focus on?'),
        CatalogQuestion(
          prompt: 'How do I use Deep Focus?',
          hint: 'Interactive guide',
          guideId: 'deep_focus',
        ),
      ],
    ),
    QuestionCategory(
      id: 'sleep',
      label: 'Sleep',
      icon: Icons.bedtime_rounded,
      questions: [
        CatalogQuestion(prompt: 'Set my sleep schedule'),
        CatalogQuestion(prompt: 'I want to sleep at 11 PM'),
        CatalogQuestion(prompt: 'Wake me at 7 AM'),
        CatalogQuestion(prompt: 'Plan my day around my sleep'),
        CatalogQuestion(
          prompt: 'How does Sleep planning work?',
          hint: 'Interactive guide',
          guideId: 'sleep',
        ),
      ],
    ),
    QuestionCategory(
      id: 'progress',
      label: 'Progress',
      icon: Icons.trending_up_rounded,
      questions: [
        CatalogQuestion(prompt: 'How am I doing?'),
        CatalogQuestion(prompt: 'Show my progress'),
        CatalogQuestion(prompt: 'What improved this week?'),
      ],
    ),
    QuestionCategory(
      id: 'rewards',
      label: 'Rewards',
      icon: Icons.emoji_events_rounded,
      questions: [
        CatalogQuestion(prompt: 'How does XP work?'),
        CatalogQuestion(prompt: 'What can I unlock?'),
      ],
    ),
    QuestionCategory(
      id: 'learn',
      label: 'Learn Student OS',
      icon: Icons.school_outlined,
      questions: [
        CatalogQuestion(
          prompt: 'How do I use Planning?',
          hint: 'Interactive guide',
          guideId: 'planning',
        ),
        CatalogQuestion(
          prompt: 'How do I use SprintX?',
          hint: 'Interactive guide',
          guideId: 'sprintx',
        ),
        CatalogQuestion(
          prompt: 'How do I use Deep Focus?',
          hint: 'Interactive guide',
          guideId: 'deep_focus',
        ),
        CatalogQuestion(
          prompt: 'Show me how to add an exam',
          hint: 'Interactive guide',
          guideId: 'add_exam',
        ),
        CatalogQuestion(
          prompt: 'How do I use Sleep?',
          hint: 'Interactive guide',
          guideId: 'sleep',
        ),
      ],
    ),
    QuestionCategory(
      id: 'support',
      label: 'Support',
      icon: Icons.favorite_outline_rounded,
      questions: [
        CatalogQuestion(prompt: 'Help me decide what to do'),
        CatalogQuestion(prompt: "I'm overwhelmed"),
        CatalogQuestion(prompt: 'I missed my plan'),
        CatalogQuestion(prompt: 'Help me catch up'),
      ],
    ),
  ];

  /// Category shown first for an entry origin (contextual discovery).
  /// Falls back to 'today'.
  static String preferredCategoryFor(AssistantOrigin origin) {
    switch (origin) {
      case AssistantOrigin.planning:
        return 'planning';
      case AssistantOrigin.tasks:
        return 'tasks';
      case AssistantOrigin.study:
      case AssistantOrigin.subject:
        return 'study';
      case AssistantOrigin.exam:
        return 'exams';
      case AssistantOrigin.sprintx:
      case AssistantOrigin.focus:
      case AssistantOrigin.deepFocus:
        return 'focus';
      case AssistantOrigin.sleep:
        return 'sleep';
      case AssistantOrigin.progress:
        return 'progress';
      case AssistantOrigin.rewards:
        return 'rewards';
      case AssistantOrigin.resources:
      case AssistantOrigin.tools:
      case AssistantOrigin.workspace:
      case AssistantOrigin.settings:
      case AssistantOrigin.global:
      case AssistantOrigin.home:
        return 'today';
    }
  }

  /// Popular starter questions shown at the top of the catalog.
  static const List<CatalogQuestion> popular = [
    CatalogQuestion(prompt: 'What should I do now?'),
    CatalogQuestion(prompt: 'Plan my next 2 hours'),
    CatalogQuestion(prompt: 'What should I study?'),
    CatalogQuestion(prompt: 'Fix my day'),
    CatalogQuestion(prompt: "I'm behind"),
    CatalogQuestion(prompt: 'Prepare for my exam'),
  ];

  static List<CatalogQuestion> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return const [];
    }
    final out = <CatalogQuestion>[];
    for (final c in categories) {
      for (final question in c.questions) {
        if (question.prompt.toLowerCase().contains(q) ||
            c.label.toLowerCase().contains(q)) {
          out.add(question);
        }
      }
    }
    return out;
  }
}
