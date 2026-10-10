import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';

/// P2 — sleep commands: single-field updates, duration clarification,
/// evening cutoffs, sleep-aware planning.
void main() {
  const parser = DeterministicStudentIntentParser();
  const engine = StudentAssistantEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    SleepController.instance.clearData();
  });

  tearDown(() async {
    await SleepController.instance.clearSchedule();
    AuthIsolation.instance.clearSession();
    SleepController.instance.clearData();
  });

  group('bedtime / wake updates', () {
    test('"Change my bedtime to 11:30" proposes keeping wake', () async {
      AuthIsolation.instance.setAuthenticatedUser('p2_sleep_cmd');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      final result = engine.process('Change my bedtime to 11:30');
      expect(result.requiresConfirmation, isTrue);
      expect(
        result.primaryAction?.type,
        AssistantActionType.updateSleepSchedule,
      );
      expect(result.primaryAction?.sleepBedtimeMinutes, 1410);
      expect(result.primaryAction?.sleepWakeMinutes, 420);
    });

    test('"Wake me up at 6" proposes keeping bedtime', () async {
      AuthIsolation.instance.setAuthenticatedUser('p2_sleep_cmd');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      final result = engine.process('Wake me up at 6am');
      expect(result.requiresConfirmation, isTrue);
      expect(result.primaryAction?.sleepWakeMinutes, 360);
      expect(result.primaryAction?.sleepBedtimeMinutes, 1380);
    });

    test('"I want 8 hours of sleep" asks for wake time', () async {
      AuthIsolation.instance.setAuthenticatedUser('p2_sleep_cmd');
      await SleepController.instance.saveSchedule(
        const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
      );
      final intent = parser.parse('I want 8 hours of sleep');
      expect(intent.intentType, AssistantIntentType.updateSleepSchedule);
      expect(intent.durationMinutes, 480);
      final result = engine.process(
        'I want 8 hours of sleep',
        explicitIntent: intent,
      );
      expect(result.clarificationRequired, isTrue);
      expect(result.clarificationChoices, isNotEmpty);
    });
  });

  group('evening cutoff', () {
    test('"Don\'t schedule anything after 10pm" plans with cutoff', () {
      final intent = parser.parse("Don't schedule anything after 10pm");
      expect(intent.intentType, AssistantIntentType.planTime);
      expect(intent.eveningCutoffMinutes, 22 * 60);
    });

    test('"Plan my day around my sleep" is sleep-aware planning', () {
      final intent = parser.parse('Plan my day around my sleep');
      expect(intent.intentType, AssistantIntentType.planTime);
    });
  });
}
