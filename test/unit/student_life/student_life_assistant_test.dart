import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_result.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/features/student_life/student_life_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = StudentAssistantEngine();
  final now = DateTime(2026, 9, 30, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    AppClock.freezeAt(now);
    AuthIsolation.instance.setAuthenticatedUser('sl_assistant');
    await StudentLifeController.instance.load();
  });

  tearDown(() {
    AppClock.reset();
  });

  StudentAssistantResult ask(String query) => engine.process(
    query,
    subjects: const [],
    chapters: const [],
    topics: const [],
    tasks: const [],
    exams: const [],
    sessions: const [],
    blocks: const [],
    referenceTime: now,
  );

  group('Assistant — Student Life intents', () {
    test('H1. "my routine" returns the routine card with a read action', () {
      final result = ask('my routine');

      expect(result.intent.intentType, AssistantIntentType.showStudentLife);
      expect(result.title, "Today's Routine");
      expect(result.cardKind, AssistantCardKind.recommendation);
      expect(result.hasSteps, isTrue);
      expect(
        result.primaryAction?.type,
        AssistantActionType.openStudentLife,
      );
      expect(
        result.primaryAction?.actionClass,
        AssistantActionClass.read,
      );
    });

    test('H2. "student life" also routes to Student Life', () {
      expect(
        ask('student life').intent.intentType,
        AssistantIntentType.showStudentLife,
      );
    });

    test('H3. "how did i sleep" is honest when nothing is logged', () {
      final result = ask('how did i sleep');

      expect(result.intent.intentType, AssistantIntentType.showSleepSummary);
      expect(result.title, 'No Sleep Logged Yet');
      expect(result.cardKind, AssistantCardKind.empty);
      expect(
        result.primaryAction?.type,
        AssistantActionType.openStudentLife,
      );
    });

    test('H4. "log sleep" asks for a real log rather than inventing one', () {
      final result = ask('log sleep');

      expect(result.intent.intentType, AssistantIntentType.showSleepSummary);
      expect(result.message, contains('manually'));
    });

    test('H5. sleep summary reports the logged night', () async {
      await StudentLifeController.instance.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );

      final result = ask('how much did i sleep');

      expect(result.title, 'Sleep Summary');
      expect(result.message, contains('8h'));
      expect(result.steps.length, 3);
      expect(result.steps.first.minutes, 480);
      expect(result.contextLine, contains('Bed 23:00'));
    });

    test('H6. "wind down" is a safe navigation action', () {
      final result = ask('wind down');

      expect(result.intent.intentType, AssistantIntentType.startWindDown);
      expect(result.title, 'Start Winding Down');
      expect(result.primaryAction?.type, AssistantActionType.startWindDown);
      expect(
        result.primaryAction?.actionClass,
        AssistantActionClass.safeNavigation,
      );
      expect(result.requiresConfirmation, isFalse);
    });

    test('H7. new Student Life actions never require confirmation', () {
      expect(
        AssistantActionType.openStudentLife.actionClass,
        AssistantActionClass.read,
      );
      expect(
        AssistantActionType.openStudentLife.isReadOnly,
        isTrue,
      );
      expect(
        AssistantActionType.startWindDown.isSafeNavigation,
        isTrue,
      );
      expect(
        AssistantActionType.startWindDown.requiresPreview,
        isFalse,
      );
    });

    test('H8. existing academic intents are unaffected', () {
      expect(
        ask('what should I do?').intent.intentType,
        AssistantIntentType.whatShouldIDo,
      );
      expect(
        ask("today's plan").intent.intentType,
        AssistantIntentType.showTodayPlan,
      );
    });
  });
}
