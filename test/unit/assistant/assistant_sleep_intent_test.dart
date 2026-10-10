import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';

/// P1 — sleep-schedule intents: routing takes precedence over the sleep
/// summary, explicit times parse deterministically, invalid windows error
/// instead of proposing, valid windows propose through confirmation.
void main() {
  const parser = DeterministicStudentIntentParser();
  const engine = StudentAssistantEngine();

  group('parser routing', () {
    test('"set sleep schedule" opens the schedule', () {
      final intent = parser.parse('set sleep schedule');
      expect(intent.intentType, AssistantIntentType.openSleepSchedule);
    });

    test('"show sleep schedule" opens the schedule, not the log summary',
        () {
      final intent = parser.parse('show sleep schedule');
      expect(intent.intentType, AssistantIntentType.openSleepSchedule);
    });

    test('"set sleep 11pm to 7am" parses explicit 1380/420', () {
      final intent = parser.parse('set sleep 11pm to 7am');
      expect(intent.intentType, AssistantIntentType.updateSleepSchedule);
      expect(intent.bedtimeMinutes, 1380);
      expect(intent.wakeMinutes, 420);
    });

    test('"set sleep 11:30pm to 7:30am" parses half hours', () {
      final intent = parser.parse('set sleep 11:30pm to 7:30am');
      expect(intent.intentType, AssistantIntentType.updateSleepSchedule);
      expect(intent.bedtimeMinutes, 1410);
      expect(intent.wakeMinutes, 450);
    });

    test('"how did i sleep" still shows the logged summary', () {
      final intent = parser.parse('how did i sleep');
      expect(intent.intentType, AssistantIntentType.showSleepSummary);
    });

    test('"log sleep" still shows the logged summary', () {
      final intent = parser.parse('log sleep');
      expect(intent.intentType, AssistantIntentType.showSleepSummary);
    });
  });

  group('engine proposals', () {
    test('openSleepSchedule with no schedule shows empty state', () {
      final result = engine.process(
        'set sleep schedule',
        explicitIntent: const StudentAssistantIntent(
          rawText: 'set sleep schedule',
          intentType: AssistantIntentType.openSleepSchedule,
        ),
      );
      expect(result.success, isTrue);
      expect(result.primaryAction, isNotNull);
    });

    test('equal bed/wake times produce an error, never a proposal', () {
      final result = engine.process(
        'set sleep',
        explicitIntent: const StudentAssistantIntent(
          rawText: 'set sleep',
          intentType: AssistantIntentType.updateSleepSchedule,
          bedtimeMinutes: 420,
          wakeMinutes: 420,
        ),
      );
      expect(result.success, isFalse);
      expect(result.requiresConfirmation, isFalse);
    });

    test('valid times propose through the confirmation gate', () {
      final result = engine.process(
        'set sleep 11pm to 7am',
        explicitIntent: const StudentAssistantIntent(
          rawText: 'set sleep 11pm to 7am',
          intentType: AssistantIntentType.updateSleepSchedule,
          bedtimeMinutes: 1380,
          wakeMinutes: 420,
        ),
      );
      expect(result.success, isTrue);
      expect(result.requiresConfirmation, isTrue);
      expect(result.primaryAction, isNotNull);
      expect(result.primaryAction!.sleepBedtimeMinutes, 1380);
      expect(result.primaryAction!.sleepWakeMinutes, 420);
    });
  });
}
