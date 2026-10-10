import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/guides/guide_controller.dart';
import 'package:student_os/features/guides/guide_overlay.dart';
import 'package:student_os/features/guides/guide_progress_store.dart';
import 'package:student_os/features/guides/guide_targets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('guide_overlay_user');
    GuideProgressStore.instance.clearData();
    await GuideController.instance.exitGuide();
  });

  tearDown(() async {
    await GuideController.instance.exitGuide();
    GuideProgressStore.instance.clearData();
    AuthIsolation.instance.clearSession();
    GuideTargetRegistry.instance.debugReset();
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

  /// Advances fake time past the guide anchor-settling chain, then settles
  /// frames. Required because production settle timers must not pend at
  /// teardown (test invariant).
  Future<void> settleGuide(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('coach card renders with step counter and actions',
      (tester) async {
    await tester.pumpWidget(host(
      const GuideTargetAnchor(id: 't.a', child: Text('Real control')),
    ));
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('home');
    await settleGuide(tester);

    expect(find.text('Understanding your Home'), findsWidgets);
    expect(find.text('Next best move'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
    // Single-step guide: primary action reads Done, secondary Finish.
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.byTooltip('Exit guide'), findsOneWidget);
  });

  testWidgets('spotlight ring renders around a registered anchor',
      (tester) async {
    await tester.pumpWidget(host(
      const GuideTargetAnchor(id: 'home.hero', child: Text('Hero')),
    ));
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('home');
    await settleGuide(tester);

    // Dim + ring painted; coach card visible.
    expect(find.text('Next best move'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('continue completes a single-step guide', (tester) async {
    await tester.pumpWidget(host(const Text('x')));
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('home');
    await settleGuide(tester);

    await tester.tap(find.text('Done'));
    await settleGuide(tester);

    expect(find.text('You\u2019re ready.'), findsOneWidget);
    expect(
      GuideProgressStore.instance.progressOf('home').status.name,
      'completed',
    );
  });

  testWidgets('exit preserves resume position', (tester) async {
    await tester.pumpWidget(host(const Text('x')));
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('sleep');
    await settleGuide(tester);

    // Step 1 of 3 showing.
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settleGuide(tester);
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Exit guide'));
    await settleGuide(tester);
    final saved = GuideProgressStore.instance.progressOf('sleep');
    expect(saved.status.name, 'inProgress');
    expect(saved.stepIndex, 1);
    expect(GuideController.instance.isActive, isFalse);
  });

  testWidgets('missing anchor degrades to coach-card-only mode',
      (tester) async {
    // No anchor registered for progress tour step.
    await tester.pumpWidget(host(const Text('x')));
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('progress');
    await settleGuide(tester);

    expect(find.text('Your momentum'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion still renders overlay', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
            size: Size(390, 844), disableAnimations: true),
        child: host(const Text('x')),
      ),
    );
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('home');
    await settleGuide(tester);

    expect(find.text('Next best move'), findsOneWidget);
  });

  testWidgets('completion view offers replay and done', (tester) async {
    await tester.pumpWidget(host(const Text('x')));
    GuideOverlayManager.ensureListening();
    await GuideController.instance.startGuide('home');
    await settleGuide(tester);
    await tester.tap(find.text('Done'));
    await settleGuide(tester);

    expect(find.text('Replay'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Replay'));
    await settleGuide(tester);
    expect(find.text('1 / 1'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await settleGuide(tester);
    await tester.tap(find.text('Done'));
    await settleGuide(tester);
    expect(GuideController.instance.isActive, isFalse);
  });
}
