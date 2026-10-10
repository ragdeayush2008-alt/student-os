import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_session_a');
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
  });

  tearDown(() {
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('Focus 3.0 P2 — Active Session Protection & Isolation Regression Tests', () {
    test('1. PlanningBlock directly starts Focus without mode picker', () {
      final fc = FocusController.instance;

      final now = DateTime.now();
      final block = PlanningBlock(
        id: 'block_p2_test',
        userId: 'user_session_a',
        subjectId: 'sub_tax',
        customTitle: 'Income from Salary Revision',
        startAt: now.add(const Duration(minutes: 5)),
        endAt: now.add(const Duration(minutes: 45)),
      );

      // Simulate AppRouter.startPlanningBlockFocus behavior
      fc.startTimer(
        duration: const Duration(minutes: 40),
        subjectId: block.subjectId,
        objective: block.customTitle!,
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.subjectId, 'sub_tax');
      expect(fc.activeSession!.plannedDuration, const Duration(minutes: 40));
      expect(fc.activeSession!.objective, 'Income from Salary Revision');

      fc.clearData();
    });

    test('2. Starting a new session while one is active properly ends the old one (FocusController behavior)', () {
      final fc = FocusController.instance;

      // Start session 1
      fc.startTimer(
        duration: const Duration(minutes: 50),
        subjectId: 'sub_1',
        subjectName: 'Subject 1',
        objective: 'Initial Study',
      );
      final oldSessionId = fc.activeSession!.id;

      // Start session 2 - FocusController ends the old one and starts new
      fc.startTimer(
        duration: const Duration(minutes: 30),
        subjectId: 'sub_2',
        subjectName: 'Subject 2',
        objective: 'Second Study',
      );

      // New session is active
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.subjectId, 'sub_2');
      expect(fc.activeSession!.objective, 'Second Study');
      expect(fc.activeSession!.plannedDuration, const Duration(minutes: 30));

      // Old session is in history with interrupted outcome
      final oldSession = fc.sessions.where((s) => s.id == oldSessionId).firstOrNull;
      expect(oldSession, isNotNull);
      expect(oldSession!.outcome, SessionOutcome.interrupted);

      fc.clearData();
    });

    test('3. User Isolation: clearData properly clears sessions before loading new user data', () async {
      // User A creates history
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        subjectName: 'User A Secret Subject',
      );
      FocusController.instance.completeSession();
      expect(FocusController.instance.sessions.length, 1);

      // Clear data and verify sessions are gone
      FocusController.instance.clearData();
      expect(FocusController.instance.sessions, isEmpty);
      expect(FocusController.instance.hasActiveSession, isFalse);

      // Switch to User B
      AuthIsolation.instance.clearSession();
      AuthIsolation.instance.setAuthenticatedUser('user_session_b');

      // Load for User B - should be empty since User B has no sessions
      await FocusController.instance.load();
      expect(FocusController.instance.sessions, isEmpty);
      expect(FocusController.instance.hasActiveSession, isFalse);
    });
  });
}