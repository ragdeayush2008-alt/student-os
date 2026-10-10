import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanningBlock -> Focus Launch Regression Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_plan_focus_user');
      FocusController.instance.clearData();
      SubjectController.instance.clearData();
      TaskController.instance.clearData();
      await FocusController.instance.load();
      await SubjectController.instance.load();
      await TaskController.instance.load();
    });

    tearDown(() {
      if (FocusController.instance.hasActiveSession) {
        FocusController.instance.cancelSession();
      }
      FocusController.instance.clearData();
      SubjectController.instance.clearData();
      TaskController.instance.clearData();
      AuthIsolation.instance.clearSession();
    });

    testWidgets('1. Starting a PlanningBlock opens the mode-selection sheet; choosing Timer launches immediately with assigned 45-min duration & context', (tester) async {
      // Create subject
      final sub = await SubjectController.instance.createSubject(
        name: 'Audit & Assurance',
      );

      final now = DateTime.now();
      final start = now.add(const Duration(minutes: 5));
      final end = start.add(const Duration(minutes: 45));

      final block = PlanningBlock(
        id: 'block_audit_45',
        userId: 'test_plan_focus_user',
        startAt: start,
        endAt: end,
        subjectId: sub.id,
        customTitle: 'Audit & Assurance',
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppRouter.startPlanningBlockFocus(ctx, block),
                child: const Text('Start Block'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Block'));
      await tester.pumpAndSettle();

      // Mode-selection sheet must appear (never a hidden re-ask).
      expect(find.text('What do you want to do?'), findsOneWidget);
      expect(find.text('45 min scheduled'), findsOneWidget);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      // Focus session must be active
      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      final active = fc.activeSession!;
      expect(active.plannedDuration.inMinutes, 45);
      expect(active.subjectId, sub.id);
      expect(active.objective, 'Audit & Assurance');
      expect(active.mode, FocusMode.timer);
      expect(active.planningBlockId, block.id);

      fc.cancelSession();
      fc.clearData();
    });

    testWidgets('2. Starting late block calculates remaining planned duration safely', (tester) async {
      final now = DateTime.now();
      // Block started 15 minutes ago, ends in 30 minutes (total 45 min)
      final start = now.subtract(const Duration(minutes: 15));
      final end = now.add(const Duration(minutes: 30));

      final block = PlanningBlock(
        id: 'block_late_start',
        userId: 'test_plan_focus_user',
        startAt: start,
        endAt: end,
        customTitle: 'Late Block',
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppRouter.startPlanningBlockFocus(ctx, block),
                child: const Text('Start Block'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Block'));
      await tester.pumpAndSettle();

      expect(find.text('What do you want to do?'), findsOneWidget);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      // Remaining duration is approximately 30 minutes
      expect(fc.activeSession!.plannedDuration.inMinutes, inInclusiveRange(29, 31));

      fc.cancelSession();
      fc.clearData();
    });

    testWidgets('3. Expired block falls back safely to full assigned duration without crash', (tester) async {
      final now = DateTime.now();
      // Block ended 10 minutes ago
      final start = now.subtract(const Duration(minutes: 55));
      final end = now.subtract(const Duration(minutes: 10));

      final block = PlanningBlock(
        id: 'block_expired',
        userId: 'test_plan_focus_user',
        startAt: start,
        endAt: end, // 45 min duration
        customTitle: 'Expired Block',
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppRouter.startPlanningBlockFocus(ctx, block),
                child: const Text('Start Block'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Block'));
      await tester.pumpAndSettle();

      expect(find.text('What do you want to do?'), findsOneWidget);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.plannedDuration.inMinutes, 45);

      fc.cancelSession();
      fc.clearData();
    });

    testWidgets('4. If Focus is already active, starting another block routes to active session without clobbering', (tester) async {
      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 50),
        objective: 'Original Session',
      );
      expect(fc.hasActiveSession, isTrue);
      final originalId = fc.activeSession!.id;

      final block = PlanningBlock(
        id: 'block_second',
        userId: 'test_plan_focus_user',
        startAt: DateTime.now(),
        endAt: DateTime.now().add(const Duration(minutes: 25)),
        customTitle: 'Second Block',
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppRouter.startPlanningBlockFocus(ctx, block),
                child: const Text('Start Second Block'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Second Block'));
      await tester.pumpAndSettle();

      // Original session must be preserved!
      expect(fc.activeSession!.id, originalId);
      expect(fc.activeSession!.objective, 'Original Session');
      expect(fc.activeSession!.plannedDuration.inMinutes, 50);

      fc.cancelSession();
      fc.clearData();
    });
  });
}
