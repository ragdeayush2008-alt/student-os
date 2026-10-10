import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_context.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';

/// P1 — sleep in Assistant context: injected schedule appears, missing or
/// disabled schedules degrade to "no schedule", never secrets.
void main() {
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

  test('injected schedule surfaces window + duration', () {
    final snapshot = AssistantContextSnapshot.capture(
      sleepSchedule: const SleepSchedule(
        bedtimeMinutes: 1380,
        wakeMinutes: 420,
      ),
    );
    expect(snapshot.hasSleepSchedule, isTrue);
    expect(snapshot.sleepWindowLabel, '11 PM → 7 AM');
    expect(snapshot.sleepDurationLabel, '8h');
    expect(snapshot.summaryLine, contains('Sleep 11 PM → 7 AM'));
  });

  test('disabled schedule is treated as no schedule', () {
    final snapshot = AssistantContextSnapshot.capture(
      sleepSchedule: const SleepSchedule(enabled: false),
    );
    expect(snapshot.hasSleepSchedule, isFalse);
    expect(snapshot.sleepWindowLabel, isNull);
    expect(snapshot.summaryLine, isNot(contains('Sleep')));
  });

  test('no schedule degrades cleanly', () {
    final snapshot = AssistantContextSnapshot.capture();
    expect(snapshot.hasSleepSchedule, isFalse);
    expect(snapshot.sleepWindowLabel, isNull);
  });

  test('live controller schedule flows into context', () async {
    AuthIsolation.instance.setAuthenticatedUser('p1_ctx_user');
    await SleepController.instance.saveSchedule(
      const SleepSchedule(bedtimeMinutes: 1410, wakeMinutes: 450),
    );
    final snapshot = AssistantContextSnapshot.capture();
    expect(snapshot.hasSleepSchedule, isTrue);
    expect(snapshot.sleepDurationLabel, '8h');
  });

  test('context exposes no credentials or identifiers', () {
    final snapshot = AssistantContextSnapshot.capture(
      sleepSchedule: const SleepSchedule(),
    );
    final json = snapshot.summaryLine;
    expect(json.contains('sb_'), isFalse);
    expect(json.contains('eyJ'), isFalse);
  });
}
