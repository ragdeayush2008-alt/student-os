import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// PART27 FLOWS 5+6: Assistant → existing engine → executable action.
///
/// - "what should I do?" delegates to StudentOSIntelligenceEngine and the
///   resulting action carries the ids needed to start without losing context.
/// - Active focus resolves to continue (never a second session).
/// - "I have 2 hours" delegates to PlanningEngine with a real budget.
void main() {
  const engine = StudentAssistantEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('flow_assistant');
    await StorageService.instance.clearUser(userId: 'flow_assistant');
    ControllerIsolation.instance.clearAllControllers();
    FocusController.instance.resetClockForTesting();
  });

  tearDown(() {
    FocusController.instance.resetClockForTesting();
    FocusController.instance.clearData();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  test('FLOW 5: "what should I do?" yields a startable task action', () async {
    final now = DateTime.now();
    await SubjectController.instance.createSubject(name: 'Physics');
    final task = await TaskController.instance.createTask(
      title: 'Flow5 overdue worksheet',
      dueDate: now.subtract(const Duration(days: 1)),
      estimatedMinutes: 30,
    );

    final result = engine.process('what should I do?', referenceTime: now);

    expect(result.success, isTrue);
    expect(result.primaryAction, isNotNull);
    final action = result.primaryAction!;
    // Start-type action directed at the real overdue task.
    expect(
      action.type == AssistantActionType.startTask ||
          action.type == AssistantActionType.startFocus,
      isTrue,
      reason: 'unexpected action type ${action.type}',
    );
    expect(action.taskId, task.id);
  });

  test('FLOW 5b: active focus resolves to continue', () async {
    FocusController.instance.startTimer(
      duration: const Duration(minutes: 25),
      subjectName: 'Biology',
      objective: 'Flow5b session',
    );
    expect(FocusController.instance.hasActiveSession, isTrue);

    final result = engine.process(
      'what should I do?',
      referenceTime: DateTime.now(),
    );

    expect(result.success, isTrue);
    expect(result.primaryAction?.type, AssistantActionType.startFocus);
    expect(result.primaryAction?.label, contains('Focus'));
  });

  test('FLOW 6: "I have 2 hours" yields a budgeted executable plan',
      () async {
    final now = DateTime.now();
    final sub = await SubjectController.instance.createSubject(
      name: 'Accountancy',
    );
    final ch = await AcademicKnowledgeController.instance.createChapter(
      subjectId: sub.id,
      title: 'Partnership',
    );
    final topic = await AcademicKnowledgeController.instance.createTopic(
      chapterId: ch.id,
      subjectId: sub.id,
      title: 'Flow6 admission topic',
      estimatedMinutes: 45,
    );

    final result = engine.process('I have 2 hours', referenceTime: now);

    expect(result.success, isTrue);
    expect(result.planResult, isNotNull);
    // P2: Apply is the primary confirm-gated action; Start rides along.
    expect(result.primaryAction?.type, AssistantActionType.applyPlan);
    final start = result.secondaryActions
        .where((a) => a.type == AssistantActionType.startPlan)
        .firstOrNull;
    expect(start, isNotNull);
    // Plan references the real topic within the 2-hour budget.
    expect(start?.topicId, topic.id);
    expect(start?.duration, isNotNull);
    expect(
      start!.duration!.inMinutes,
      lessThanOrEqualTo(120),
    );
  });
}
