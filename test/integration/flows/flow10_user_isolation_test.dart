import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/core/services/streak_service.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// PART27 FLOW 10: User A → work → logout → User B (only B) → logout →
/// User A (only A restored).
///
/// Exercises real controllers + real StorageService namespaces: tasks,
/// planning blocks, subjects, focus sessions, study ledger, XP events,
/// recommendations, and streak.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.clearUser(userId: 'flow10_user_a');
    await StorageService.instance.clearUser(userId: 'flow10_user_b');
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  tearDown(() {
    FocusController.instance.clearData();
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  Future<void> login(String userId) async {
    AuthIsolation.instance.setAuthenticatedUser(userId);
    await TaskController.instance.load();
    await PlanningBlockController.instance.load();
    await SubjectController.instance.load();
    await StudyController.instance.load();
    await FocusController.instance.load();
    await ProgressionController.instance.load();
  }

  void logout() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  }

  test('full A → B → A isolation across every domain', () async {
    // ── USER A works ──────────────────────────────────────────────
    await login('flow10_user_a');
    final subA =
        await SubjectController.instance.createSubject(name: 'Botany');
    await TaskController.instance.createTask(
      title: 'User A leaf diagram',
      subjectId: subA.id,
    );
    final startA = DateTime.now().add(const Duration(hours: 1));
    await PlanningBlockController.instance.scheduleSubjectBlock(
      subA.id,
      startA,
      startA.add(const Duration(hours: 1)),
      customTitle: 'User A field study',
    );
    var nowA = DateTime.now();
    FocusController.instance.setClockForTesting(() => nowA);
    FocusController.instance.startTimer(
      duration: const Duration(minutes: 20),
      subjectId: subA.id,
      subjectName: 'Botany',
      objective: 'User A focus',
    );
    final sessionAId = FocusController.instance.activeSession!.id;
    nowA = nowA.add(const Duration(minutes: 20));
    FocusController.instance.completeSession();
    FocusController.instance.resetClockForTesting();

    expect(TaskController.instance.tasks.length, 1);
    expect(PlanningBlockController.instance.blocks.length, 1);
    expect(
      StudyController.instance.sessions
          .where((s) => s.focusSessionId == sessionAId)
          .length,
      1,
    );

    final actionA = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
      subjects: [Subject(id: subA.id, name: 'Botany')],
      tasks: TaskController.instance.tasks,
    );
    expect(actionA.title, contains('User A'));

    // ── LOGOUT → USER B sees only B ───────────────────────────────
    logout();
    await login('flow10_user_b');

    expect(TaskController.instance.tasks, isEmpty);
    expect(PlanningBlockController.instance.blocks, isEmpty);
    expect(SubjectController.instance.subjects, isEmpty);
    expect(StudyController.instance.sessions, isEmpty);
    expect(FocusController.instance.sessions, isEmpty);
    expect(FocusController.instance.hasActiveSession, isFalse);
    expect(ProgressionController.instance.events, isEmpty);
    expect(StreakService.instance.currentStreak, 0);

    final actionB = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
      subjects: const [],
      tasks: TaskController.instance.tasks,
    );
    expect(actionB.title.contains('User A'), isFalse);

    final subB =
        await SubjectController.instance.createSubject(name: 'Algebra');
    await TaskController.instance.createTask(title: 'User B equations');
    expect(TaskController.instance.tasks.length, 1);
    expect(SubjectController.instance.subjects.length, 1);
    expect(subB.name, 'Algebra');

    // ── LOGOUT → USER A recovers only A ───────────────────────────
    logout();
    await login('flow10_user_a');

    expect(
      TaskController.instance.tasks.map((t) => t.title),
      contains('User A leaf diagram'),
    );
    expect(
      TaskController.instance.tasks
          .where((t) => t.title.contains('User B'))
          .length,
      0,
    );
    expect(
      PlanningBlockController.instance.blocks.length,
      1,
    );
    expect(
      SubjectController.instance.subjects.map((s) => s.name),
      contains('Botany'),
    );
    expect(
      StudyController.instance.sessions
          .where((s) => s.focusSessionId == sessionAId)
          .length,
      1,
    );
    expect(
      FocusController.instance.sessions.any((s) => s.id == sessionAId),
      isTrue,
    );
  });
}
