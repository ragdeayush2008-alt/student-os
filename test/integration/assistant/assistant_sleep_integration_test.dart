import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_context.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';

/// P1 integration — Sleep × Assistant × isolation.
///
/// User A sets a sleep window → Assistant context sees it → logout/login as
/// B shows nothing → B sets their own → A returns to only A's data, and
/// A's conversation history survived the round trip.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  tearDown(() async {
    await SleepController.instance.clearSchedule();
    await StudentAssistantController.instance.clearConversation();
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
  });

  test('sleep → context → isolation round trip', () async {
    // User A sets a window and chats.
    AuthIsolation.instance.setAuthenticatedUser('p1_int_user_a');
    await SleepController.instance.load();
    await SleepController.instance.saveSchedule(
      const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
    );
    await StudentAssistantController.instance.ask('What should I do now?');

    var snapshot = AssistantContextSnapshot.capture();
    expect(snapshot.hasSleepSchedule, isTrue);
    expect(snapshot.sleepWindowLabel, '11 PM → 7 AM');

    // Logout: everything user-scoped drops from memory.
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();

    // User B: clean slate everywhere.
    AuthIsolation.instance.setAuthenticatedUser('p1_int_user_b');
    await SleepController.instance.load();
    await StudentAssistantController.instance.loadConversation();
    snapshot = AssistantContextSnapshot.capture();
    expect(snapshot.hasSleepSchedule, isFalse);
    expect(
      StudentAssistantController.instance.messages,
      isEmpty,
    );

    // User B sets their own window.
    await SleepController.instance.saveSchedule(
      const SleepSchedule(bedtimeMinutes: 1320, wakeMinutes: 360),
    );

    // Back to A: only A's window + A's history.
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    SleepController.instance.clearData();
    AuthIsolation.instance.setAuthenticatedUser('p1_int_user_a');
    await SleepController.instance.load();
    await StudentAssistantController.instance.loadConversation();

    snapshot = AssistantContextSnapshot.capture();
    expect(snapshot.hasSleepSchedule, isTrue);
    expect(snapshot.sleepWindowLabel, '11 PM → 7 AM');
    expect(
      StudentAssistantController.instance.messages.length,
      2,
    );
  });
}
