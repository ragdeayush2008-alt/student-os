import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/core/services/supabase_service.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// PART27 FLOW 11: offline → full local use (tasks, planning, knowledge,
/// focus, analytics) → online restores without loss.
///
/// Supabase is unconfigured in tests (client == null), which is the honest
/// offline stand-in: every controller must remain usable and must never
/// block on, or fabricate, remote data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('flow11_user');
    await StorageService.instance.clearUser(userId: 'flow11_user');
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  test('local-first work completes with no backend', () async {
    // Backend genuinely absent.
    expect(SupabaseService.instance.client, isNull);

    // Tasks, subjects, planning all work offline.
    final sub =
        await SubjectController.instance.createSubject(name: 'Geography');
    final task = await TaskController.instance.createTask(
      title: 'Offline worksheet',
      subjectId: sub.id,
    );
    final now = DateTime.now();
    final start = now.hour == 23 && now.minute >= 50
        ? DateTime(now.year, now.month, now.day, 23, 50)
        : now.add(const Duration(minutes: 2));
    final block = await PlanningBlockController.instance.scheduleBlock(
      task.id,
      start,
      start.add(const Duration(minutes: 30)),
      subjectId: sub.id,
    );
    expect(block.taskId, task.id);

    // Analytics derive from local data with no network waits.
    final state = StudentOSIntelligenceEngine.computeDailyStudentState(
      subjects: SubjectController.instance.activeSubjects,
      sessions: StudyController.instance.sessions,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
    );
    expect(state.plannedMinutes, 30);

    final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
      subjects: SubjectController.instance.activeSubjects,
      tasks: TaskController.instance.tasks,
      blocks: PlanningBlockController.instance.blocks,
    );
    expect(action.title, isNotEmpty);

    // Task completion persists locally.
    await TaskController.instance.completeTask(task.id);
    expect(
      TaskController.instance.tasks
          .firstWhere((t) => t.id == task.id)
          .isCompleted,
      isTrue,
    );

    // Cloud attempts are safe no-ops offline (never throw, never fake).
    await TaskController.instance.load();
    expect(
      TaskController.instance.tasks
          .firstWhere((t) => t.id == task.id)
          .isCompleted,
      isTrue,
    );
  });
}
