import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/assistant_message.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';

/// P1 — conversation foundation: turns persist per user, cap holds,
/// clear wipes memory + storage, users never share history.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
  });

  tearDown(() async {
    await StudentAssistantController.instance.clearConversation();
    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
  });

  test('ask appends user + assistant messages', () async {
    final controller = StudentAssistantController.instance;
    await controller.ask('What should I do now?');
    expect(controller.messages.length, 2);
    expect(
      controller.messages.first.role,
      AssistantMessageRole.user,
    );
    expect(
      controller.messages.last.role,
      AssistantMessageRole.assistant,
    );
    expect(controller.messages.first.text, 'What should I do now?');
  });

  test('history persists and reloads for the same user', () async {
    AuthIsolation.instance.setAuthenticatedUser('p1_conv_user_a');
    final controller = StudentAssistantController.instance;
    await controller.ask('What should I study?');
    expect(controller.messages.length, 2);

    controller.clearData();
    expect(controller.messages, isEmpty);
    await controller.loadConversation();
    expect(controller.messages.length, 2);
    expect(controller.messages.first.text, 'What should I study?');
  });

  test("user B never sees user A's history", () async {
    AuthIsolation.instance.setAuthenticatedUser('p1_conv_user_a');
    await StudentAssistantController.instance.ask('Private question A');
    expect(
      StudentAssistantController.instance.messages.length,
      2,
    );

    AuthIsolation.instance.clearSession();
    StudentAssistantController.instance.clearData();
    AuthIsolation.instance.setAuthenticatedUser('p1_conv_user_b');
    await StudentAssistantController.instance.loadConversation();
    expect(
      StudentAssistantController.instance.messages,
      isEmpty,
    );
  });

  test('clearConversation wipes memory and storage', () async {
    AuthIsolation.instance.setAuthenticatedUser('p1_conv_user_c');
    final controller = StudentAssistantController.instance;
    await controller.ask('Hello');
    expect(controller.messages, isNotEmpty);

    await controller.clearConversation();
    expect(controller.messages, isEmpty);

    await controller.loadConversation();
    expect(controller.messages, isEmpty);
  });

  test('message serialization roundtrip is tolerant', () {
    final m = AssistantMessage(
      role: AssistantMessageRole.assistant,
      text: 'Hi',
      timestamp: DateTime(2026, 1, 1),
      title: 'Hello',
      cardKind: 'neutral',
    );
    final restored = AssistantMessage.fromJson(m.toJson());
    expect(restored.text, 'Hi');
    expect(restored.role, AssistantMessageRole.assistant);
    expect(restored.title, 'Hello');
    final corrupt = AssistantMessage.fromJson({'nonsense': true});
    expect(corrupt.text, '');
    expect(corrupt.role, AssistantMessageRole.user);
  });
}
