import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/assistant/student_assistant_controller.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/guides/guide_controller.dart';
import 'package:student_os/features/guides/guide_overlay.dart';
import 'package:student_os/features/guides/guide_progress_store.dart';
import 'package:student_os/features/guides/guide_registry.dart';
import 'package:student_os/features/guides/guide_targets.dart';
import 'package:student_os/features/guides/models/guide_models.dart';
import 'package:student_os/features/guides/learn_screen.dart';
import 'package:student_os/features/tools/presentation/tools_hub_screen.dart';

/// Phase 3 §35: Tutorial Center flow, Back navigation, Tools guide,
/// Settings entry, and Assistant launch — end to end on real widgets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('tutorial_user');
    ControllerIsolation.instance.clearAllControllers();
    StudentAssistantController.instance.clearData();
    GuideProgressStore.instance.clearData();
    GuideTargetRegistry.instance.debugReset();
    GuideOverlayManager.ensureListening();
  });

  tearDown(() async {
    await GuideController.instance.exitGuide().catchError((_) {});
    await StudentAssistantController.instance.clearConversation();
    StudentAssistantController.instance.clearData();
    GuideProgressStore.instance.clearData();
    GuideTargetRegistry.instance.debugReset();
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  Widget host(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      navigatorKey: AppRouter.navigatorKey,
      routes: AppRouter.routes(),
      home: Scaffold(body: child),
    );
  }

  /// Flushes the guide anchor-settling timer chain (production timers must
  /// not pend at teardown).
  Future<void> settleGuide(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('Learn Student OS opens a real Tutorial Center, not Home',
      (tester) async {
    await tester.pumpWidget(host(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => AppRouter.openLearnCenter(context),
          child: const Text('learn'),
        ),
      ),
    ));
    await tester.tap(find.text('learn'));
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    expect(find.text('Learn by doing.'), findsOneWidget);
    // Tools category renders with the new guide.
    expect(find.text('Tools'), findsWidgets);
    expect(find.text('How to use Tools Hub'), findsOneWidget);
  });

  testWidgets('Back returns to the previous step', (tester) async {
    await tester.pumpWidget(host(const LearnScreen()));
    await tester.pumpAndSettle();

    // Start the quick tour (first guide card).
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('quick_tour');
    await settleGuide(tester);

    expect(GuideController.instance.stepIndex, 0);
    await GuideController.instance.continueStep();
    await settleGuide(tester);
    expect(GuideController.instance.stepIndex, 1);

    await GuideController.instance.previousStep();
    await settleGuide(tester);
    expect(GuideController.instance.stepIndex, 0);

    // Back on the first step is a no-op.
    await GuideController.instance.previousStep();
    await settleGuide(tester);
    expect(GuideController.instance.stepIndex, 0);

    // Progress persisted the revisit honestly.
    expect(
      GuideProgressStore.instance.progressOf('quick_tour').stepIndex,
      0,
    );
  });

  testWidgets('coach card shows Back from the second step', (tester) async {
    await tester.pumpWidget(host(const LearnScreen()));
    await tester.pumpAndSettle();

    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('quick_tour');
    await settleGuide(tester);
    await GuideController.instance.continueStep();
    await settleGuide(tester);

    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await settleGuide(tester);
    expect(GuideController.instance.stepIndex, 0);
  });

  testWidgets('tools guide targets resolve on the real Tools Hub',
      (tester) async {
    final def = GuideRegistry.byId('tools')!;
    expect(
      def.steps.map((s) => s.destination).toSet(),
      {GuideDestination.toolsHub},
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: ToolsHubScreen()),
    ));
    await tester.pumpAndSettle();

    for (final step in def.steps) {
      final id = step.targetAnchorId!;
      expect(GuideTargetRegistry.instance.contains(id), isTrue,
          reason: 'anchor missing: $id');
      expect(GuideTargetRegistry.instance.rectOf(id), isNotNull,
          reason: 'anchor has no rect: $id');
    }
  });

  testWidgets('assistant routes tool questions to the tutorial engine',
      (tester) async {
    await StudentAssistantController.instance
        .ask('How do I use the tools hub?');
    expect(
      StudentAssistantController.instance.consumePendingGuide(),
      'tools',
    );
  });

  testWidgets('tools guide completes and persists per user', (tester) async {
    await tester.pumpWidget(host(const LearnScreen()));
    await tester.pumpAndSettle();

    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('tools');
    await settleGuide(tester);
    expect(GuideController.instance.isActive, isTrue);

    // Step through both continueTap steps.
    await GuideController.instance.continueStep();
    await settleGuide(tester);
    await GuideController.instance.continueStep();
    await settleGuide(tester);

    expect(GuideController.instance.isCompleted, isTrue);
    expect(
      GuideProgressStore.instance.progressOf('tools').status.name,
      'completed',
    );
  });
}
