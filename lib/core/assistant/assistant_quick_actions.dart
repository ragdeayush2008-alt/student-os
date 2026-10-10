import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../navigation/universal_action_executor.dart';
import 'student_assistant_controller.dart';

/// P1 Assistant quick actions: the six foundation entries.
///
/// Each action either navigates to the relevant existing screen or sends a
/// structured prompt through the engine — never a faked completion. P2
/// attaches deeper execution behind the same ids.
@immutable
class AssistantQuickAction {
  const AssistantQuickAction({
    required this.id,
    required this.label,
    required this.icon,
    this.prompt,
    this.navigatesToSleep = false,
    this.navigatesToPlan = false,
    this.navigatesToLearn = false,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Engine prompt to ask when tapped (null when the action navigates).
  final String? prompt;
  final bool navigatesToSleep;
  final bool navigatesToPlan;
  final bool navigatesToLearn;

  static const List<AssistantQuickAction> all = [
    AssistantQuickAction(
      id: 'plan_my_day',
      label: 'Plan my day',
      icon: Icons.calendar_today_rounded,
      navigatesToPlan: true,
    ),
    AssistantQuickAction(
      id: 'what_study',
      label: 'What should I study?',
      icon: Icons.menu_book_rounded,
      prompt: 'What should I study?',
    ),
    AssistantQuickAction(
      id: 'whats_urgent',
      label: "What's urgent?",
      icon: Icons.priority_high_rounded,
      prompt: "What's urgent?",
    ),
    AssistantQuickAction(
      id: 'behind',
      label: "I'm behind",
      icon: Icons.trending_down_rounded,
      prompt: "I'm behind",
    ),
    AssistantQuickAction(
      id: 'fix_day',
      label: 'Fix my day',
      icon: Icons.build_rounded,
      prompt: 'Fix my day',
    ),
    AssistantQuickAction(
      id: 'exam_prep',
      label: 'Prepare for exam',
      icon: Icons.school_rounded,
      prompt: 'Plan my exam',
    ),
    AssistantQuickAction(
      id: 'sleep_schedule',
      label: 'Set sleep schedule',
      icon: Icons.bedtime_rounded,
      navigatesToSleep: true,
    ),
    AssistantQuickAction(
      id: 'do_now',
      label: 'What should I do now?',
      icon: Icons.play_arrow_rounded,
      prompt: 'What should I do now?',
    ),
    AssistantQuickAction(
      id: 'learn_os',
      label: 'Learn Student OS',
      icon: Icons.school_outlined,
      navigatesToLearn: true,
    ),
  ];
}

/// Executes a quick action: navigation for screen actions, otherwise a
/// structured engine prompt whose result renders as a normal turn.
Future<void> executeAssistantQuickAction(
  BuildContext context,
  AssistantQuickAction action,
) async {
  if (action.navigatesToSleep) {
    AppRouter.openSleepSchedule(context);
    return;
  }
  if (action.navigatesToPlan) {
    UniversalActionExecutor.openPlanMyDay(context);
    return;
  }
  if (action.navigatesToLearn) {
    AppRouter.openLearnCenter(context);
    return;
  }
  final prompt = action.prompt;
  if (prompt != null && prompt.isNotEmpty) {
    await StudentAssistantController.instance.ask(prompt);
  }
}
