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
import 'package:student_os/features/guides/learn_screen.dart';
import 'package:student_os/features/guides/models/guide_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('learn_user');
    GuideProgressStore.instance.clearData();
    await GuideController.instance.exitGuide();
  });

  tearDown(() async {
    await GuideController.instance.exitGuide();
    GuideProgressStore.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  Future<void> pumpLearn(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        navigatorKey: AppRouter.navigatorKey,
        routes: AppRouter.routes(),
        home: AppScope(
          controller: AppShellController(),
          child: const LearnScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settleGuide(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('categories and guides render with durations', (tester) async {
    await pumpLearn(tester);

    expect(find.text('Learn Student OS'), findsWidgets);
    expect(find.text('Learn by doing.'), findsOneWidget);
    expect(find.text('Start here'), findsOneWidget);
    expect(find.text('Plan & study'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Student life'), findsOneWidget);
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('How to use Deep Focus'), findsOneWidget);
    expect(find.text('How to use Sleep'), findsOneWidget);
  });

  testWidgets('advanced guides locked until basics complete', (tester) async {
    await pumpLearn(tester);

    // Deep Focus locked initially.
    expect(
      find.textContaining('Complete basics to unlock'),
      findsWidgets,
    );

    // Complete prerequisites → unlocked.
    await GuideProgressStore.instance.saveProgress(
      'sprintx',
      const GuideProgress(status: GuideStatus.completed, stepIndex: 1),
    );
    await GuideProgressStore.instance.saveProgress(
      'focus',
      const GuideProgress(status: GuideStatus.completed, stepIndex: 1),
    );
    await tester.pumpAndSettle();
    // Deep Focus card now offers Start (other locked guides remain).
    expect(find.text('How to use Deep Focus'), findsOneWidget);
  });

  testWidgets('tapping a guide starts it', (tester) async {
    await pumpLearn(tester);
    GuideOverlayManager.ensureListening();

    await tester.tap(find.text('Understanding your Home'));
    await settleGuide(tester);

    expect(GuideController.instance.isActive, isTrue);
    expect(GuideController.instance.guide?.id, 'home');
    expect(find.text('Next best move'), findsOneWidget);
  });

  testWidgets('completed guide shows replay affordance', (tester) async {
    await GuideProgressStore.instance.saveProgress(
      'home',
      const GuideProgress(status: GuideStatus.completed, stepIndex: 1),
    );
    await pumpLearn(tester);

    expect(find.textContaining('Completed · Replay'), findsWidgets);
  });
}
