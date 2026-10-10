import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/guides/guide_assistant_bridge.dart';
import 'package:student_os/features/guides/guide_controller.dart';
import 'package:student_os/features/guides/guide_overlay.dart';
import 'package:student_os/features/guides/guide_progress_store.dart';
import 'package:student_os/features/guides/models/guide_models.dart';
import 'package:student_os/features/sleep/models/sleep_schedule.dart';
import 'package:student_os/features/sleep/sleep_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Flow tests: real navigation + real controller-state detection, tour
/// lifecycle, Assistant bridge, and cross-user isolation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loginAs(String user) async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser(user);
    GuideProgressStore.instance.clearData();
    await GuideController.instance.exitGuide();
    SleepController.instance.clearData();
    TaskController.instance.clearData();
  }

  tearDown(() async {
    await GuideController.instance.exitGuide();
    GuideProgressStore.instance.clearData();
    AuthIsolation.instance.clearSession();
    SleepController.instance.clearData();
    TaskController.instance.clearData();
  });

  Widget host(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      navigatorKey: AppRouter.navigatorKey,
      routes: AppRouter.routes(),
      home: AppScope(
        controller: AppShellController(),
        child: Scaffold(body: child),
      ),
    );
  }

  Future<void> settleGuide(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('sleep guide auto-advances on REAL schedule save',
      (tester) async {
    await loginAs('sleep_flow_user');
    await tester.pumpWidget(host(const Text('x')));
    GuideOverlayManager.ensureListening();

    await GuideController.instance.startGuide('sleep');
    await settleGuide(tester);
    expect(GuideController.instance.stepIndex, 0);

    // Real action through the REAL controller (as if the user saved).
    final err = await SleepController.instance.saveSchedule(
      const SleepSchedule(bedtimeMinutes: 1380, wakeMinutes: 420),
    );
    expect(err, isNull);
    await settleGuide(tester);

    // Steps 1 (bedtime) and 2 (wake) are info steps; step 3 expects the
    // save. We are still on step 1 (Continue-gated) — advance honestly.
    expect(GuideController.instance.stepIndex, 0);
    await GuideController.instance.continueStep();
    await settleGuide(tester);
    expect(GuideController.instance.stepIndex, 1);
    await GuideController.instance.continueStep();
    await settleGuide(tester);
    // Step 3 detects the already-saved schedule immediately.
    expect(GuideController.instance.stepIndex, 2);
    await settleGuide(tester);
    // Auto-advance fired on detection → completion view.
    expect(GuideController.instance.isCompleted, isTrue);
    expect(
      GuideProgressStore.instance.progressOf('sleep').status,
      GuideStatus.completed,
    );
  });

  testWidgets('tasks guide detects REAL task creation', (tester) async {
    await loginAs('task_flow_user');
    await tester.pumpWidget(host(const Text('x')));
    GuideOverlayManager.ensureListening();

    await GuideController.instance.startGuide('tasks');
    await settleGuide(tester);
    expect(GuideController.instance.stepIndex, 0);

    await TaskController.instance.createTask(title: 'Guide flow task');
    await settleGuide(tester);

    expect(GuideController.instance.stepIndex, 1);
  });

  testWidgets('continue is a no-op on state-backed steps (no fake pass)',
      (tester) async {
    await loginAs('noop_user');
    await tester.pumpWidget(host(const Text('x')));
    GuideOverlayManager.ensureListening();

    await GuideController.instance.startGuide('tasks');
    await settleGuide(tester);
    // Pressing Continue without creating a task must NOT advance.
    await GuideController.instance.continueStep();
    await settleGuide(tester);
    expect(GuideController.instance.stepIndex, 0);
    expect(GuideController.instance.isCompleted, isFalse);
  });

  testWidgets('tour offer flag + skip lifecycle', (tester) async {
    await loginAs('tour_user');
    final store = GuideProgressStore.instance;
    await store.load();
    expect(store.tourState, isNull);

    await store.setTourOfferPending(true);
    expect(store.tourOfferPending, isTrue);

    await store.setTourOfferPending(false);
    await store.setTourState('skipped');
    expect(store.tourOfferPending, isFalse);
    expect(store.tourState, 'skipped');
  });

  testWidgets('User A completion never leaks to User B', (tester) async {
    await loginAs('guide_user_a');
    await tester.pumpWidget(host(const Text('x')));
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('home');
    await settleGuide(tester);
    await GuideController.instance.continueStep();
    await settleGuide(tester);
    expect(
      GuideProgressStore.instance.progressOf('home').status,
      GuideStatus.completed,
    );

    // Switch user (fresh storage namespace).
    await loginAs('guide_user_b');
    await GuideProgressStore.instance.load();
    expect(
      GuideProgressStore.instance.progressOf('home').status,
      GuideStatus.notStarted,
    );
    expect(GuideProgressStore.instance.tourState, isNull);
  });

  test('assistant bridge matches teach-me phrasing only', () {
    expect(
      GuideAssistantBridge.matchGuideId('how do I use deep focus'),
      'deep_focus',
    );
    expect(
      GuideAssistantBridge.matchGuideTitle('show me how to add an exam'),
      'How to add an Exam',
    );
    expect(GuideAssistantBridge.matchGuideId('plan my day'), isNull);
    expect(
      GuideAssistantBridge.launchMessage('X').toLowerCase(),
      contains('interactive guide'),
    );
  });

  testWidgets('assistant ask() stages a guide launch honestly',
      (tester) async {
    await loginAs('assist_user');
    await tester.pumpWidget(host(const Text('x')));

    final result = await StudentAssistantController.instance.ask(
      'how do I use deep focus',
    );
    expect(result.title, contains('Deep Focus'));
    expect(
      StudentAssistantController.instance.pendingGuideId,
      'deep_focus',
    );
    // Consuming clears it (UI layer launches exactly once).
    expect(
      StudentAssistantController.instance.consumePendingGuide(),
      'deep_focus',
    );
    expect(
      StudentAssistantController.instance.consumePendingGuide(),
      isNull,
    );
    // And the message history is honest (guide opening, not completion).
    final last = StudentAssistantController.instance.messages.last;
    expect(last.text.toLowerCase(), contains('interactive guide'));
    await StudentAssistantController.instance.clearConversation();
  });
}
