import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/study/study_screen.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    FocusController.instance.clearData();
    TaskController.instance.clearData();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      navigatorKey: AppRouter.navigatorKey,
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  group('Focus Resume Navigation Regression', () {
    testWidgets(
      'Active Timer: Continue Focus navigates to FocusSessionScreen and preserves same session',
      (tester) async {
        final task = await TaskController.instance.createTask(
          title: 'Quantum Physics Homework',
          estimatedMinutes: 45,
        );

        FocusController.instance.startTimer(
          duration: const Duration(minutes: 45),
          taskId: task.id,
          subjectName: 'Physics',
          objective: 'Quantum Physics Homework',
        );

        expect(FocusController.instance.hasActiveSession, isTrue);
        final activeSession = FocusController.instance.activeSession!;
        final sessionId = activeSession.id;

        await tester.pumpWidget(wrapWithApp(const StudyScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Focus session active'), findsOneWidget);
        expect(find.text('Continue Focus'), findsOneWidget);

        // Tap "Continue Focus"
        await tester.tap(find.text('Continue Focus'));
        await tester.pumpAndSettle();

        // Must navigate to FocusSessionScreen
        expect(find.byType(FocusSessionScreen), findsOneWidget);
        expect(find.textContaining('Quantum Physics Homework'), findsOneWidget);

        // The session instance must remain the EXACT SAME session ID
        expect(FocusController.instance.activeSession?.id, sessionId);
        expect(FocusController.instance.activeSession?.taskId, task.id);
        expect(FocusController.instance.activeSession?.mode, FocusMode.timer);
        expect(FocusController.instance.sessions.length, 0); // No premature ended sessions

        // Pause/Resume works on existing session
        FocusController.instance.pause();
        expect(FocusController.instance.activeSession?.isPaused, isTrue);

        FocusController.instance.resume();
        expect(FocusController.instance.activeSession?.isPaused, isFalse);

        FocusController.instance.endSessionEarly();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Active Stopwatch: Continue Focus navigates to FocusSessionScreen and retains mode',
      (tester) async {
        FocusController.instance.startStopwatch(
          subjectName: 'Mathematics',
          objective: 'Problem Solving',
        );

        final activeSession = FocusController.instance.activeSession!;
        final sessionId = activeSession.id;

        await tester.pumpWidget(wrapWithApp(const StudyScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Continue Focus'), findsOneWidget);
        await tester.tap(find.text('Continue Focus'));
        await tester.pumpAndSettle();

        expect(find.byType(FocusSessionScreen), findsOneWidget);
        expect(FocusController.instance.activeSession?.id, sessionId);
        expect(FocusController.instance.activeSession?.mode, FocusMode.stopwatch);

        FocusController.instance.endSessionEarly();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Active Focus Guard: Continue Focus navigates to FocusSessionScreen and retains blocked packages',
      (tester) async {
        FocusController.instance.startFocusGuard(
          duration: const Duration(minutes: 30),
          blockedPackages: {'com.instagram.android', 'com.twitter.android'},
          subjectName: 'Chemistry',
          objective: 'Organic Reactions',
        );

        final activeSession = FocusController.instance.activeSession!;
        final sessionId = activeSession.id;

        await tester.pumpWidget(wrapWithApp(const StudyScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Continue Focus'), findsOneWidget);
        await tester.tap(find.text('Continue Focus'));
        await tester.pumpAndSettle();

        expect(find.byType(FocusSessionScreen), findsOneWidget);
        expect(FocusController.instance.activeSession?.id, sessionId);
        expect(FocusController.instance.activeSession?.mode, FocusMode.focusGuard);
        expect(
          FocusController.instance.activeSession?.blockedPackages,
          contains('com.instagram.android'),
        );

        FocusController.instance.endSessionEarly();
        await tester.pumpAndSettle();
      },
    );
  });
}
