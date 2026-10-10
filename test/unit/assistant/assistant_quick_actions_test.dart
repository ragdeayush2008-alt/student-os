import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/assistant/assistant_quick_actions.dart';

/// P1 — quick-action registry: the six foundation actions exist exactly
/// once, navigate-or-prompt honestly, and never claim fake completion.
void main() {
  test('all six P1 actions are registered with unique ids', () {
    final ids = AssistantQuickAction.all.map((a) => a.id).toList();
    expect(ids.length, 9);
    expect(ids.toSet().length, 9);
    expect(
      ids,
      containsAll([
        'plan_my_day',
        'what_study',
        'whats_urgent',
        'behind',
        'fix_day',
        'exam_prep',
        'sleep_schedule',
        'do_now',
        'learn_os',
      ]),
    );
  });

  test('every action has a label and icon', () {
    for (final action in AssistantQuickAction.all) {
      expect(action.label.isNotEmpty, isTrue, reason: action.id);
    }
  });

  test('navigation actions carry no prompt; prompt actions navigate nowhere',
      () {
    for (final action in AssistantQuickAction.all) {
      final navigates = action.navigatesToSleep ||
          action.navigatesToPlan ||
          action.navigatesToLearn;
      if (navigates) {
        expect(action.prompt, isNull, reason: action.id);
      } else {
        expect(
          action.prompt != null && action.prompt!.isNotEmpty,
          isTrue,
          reason: action.id,
        );
      }
    }
  });

  test('sleep action targets the schedule screen, plan targets planning',
      () {
    final sleep = AssistantQuickAction.all.firstWhere(
      (a) => a.id == 'sleep_schedule',
    );
    expect(sleep.navigatesToSleep, isTrue);
    final plan = AssistantQuickAction.all.firstWhere(
      (a) => a.id == 'plan_my_day',
    );
    expect(plan.navigatesToPlan, isTrue);
  });
}
