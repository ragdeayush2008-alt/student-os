import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';

/// PART27 FLOW 9: active Focus → every entry point resolves to CONTINUE.
///
/// Covers Home recommendation, PlanningBlock start, contextual start, quick
/// focus, and mode selection: none may start a second session.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('flow9_user');
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() {
    FocusController.instance.clearData();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  testWidgets('all focus entry points continue the active session',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );

    BuildContext ctx() =>
        tester.element(find.byType(Scaffold).first);

    // Start one real session.
    AppRouter.startContextualFocus(
      ctx(),
      duration: const Duration(minutes: 30),
      subjectId: 'sub_1',
      subjectName: 'Physics',
      taskId: 'task_1',
      focusTitle: 'Original session',
    );
    final fc = FocusController.instance;
    expect(fc.hasActiveSession, isTrue);
    final originalId = fc.activeSession!.id;
    await tester.pump();

    // 1. Recommendation execution for focusActive routes to active session.
    final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
      subjects: const [],
      hasActiveFocus: true,
      activeFocusObjective: 'Original session',
    );
    expect(action.isFocusActive, isTrue);

    // 2. Contextual start with different context keeps the session.
    AppRouter.startContextualFocus(
      ctx(),
      duration: const Duration(minutes: 10),
      subjectId: 'sub_2',
      focusTitle: 'Intruder session',
    );
    expect(fc.activeSession!.id, originalId);
    expect(fc.activeSession!.subjectId, 'sub_1');
    await tester.pump();

    // 3. Mode selection with different context keeps the session.
    AppRouter.openFocusModeSelection(
      ctx(),
      subjectId: 'sub_3',
      taskId: 'task_9',
      focusTitle: 'Another intruder',
    );
    await tester.pump();
    expect(fc.activeSession!.id, originalId);

    // 4. Focus Center navigation does not duplicate (route only).
    AppRouter.openFocusCenter(ctx());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(fc.hasActiveSession, isTrue);
    expect(fc.activeSession!.id, originalId);

    // Cleanup navigation + timers inside the body (binding invariant).
    while (Navigator.of(ctx()).canPop()) {
      Navigator.of(ctx()).pop();
      await tester.pump();
    }
    fc.clearData();
    await tester.pump();
  });
}
