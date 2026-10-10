import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    StudyController.instance.clearData();
    FocusController.instance.clearData();
    TaskController.instance.clearData();
    ProgressionController.instance.clearData();
  });

  group('Study Controller — Session Analytics', () {
    test('todayDuration returns zero with no sessions', () {
      expect(StudyController.instance.todayDuration, Duration.zero);
    });

    test('todayProgress returns zero with no sessions', () {
      expect(StudyController.instance.todayProgress, 0.0);
    });

    test('completedSessions returns empty list initially', () {
      expect(StudyController.instance.completedSessions, isEmpty);
    });

    test('studyStreakDays returns zero initially', () {
      expect(StudyController.instance.studyStreakDays, 0);
    });

    test('sessionsOn filters by date', () async {
      StudyController.instance.startSession(subject: 'Math');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await StudyController.instance.endSession();

      final todaySessions = StudyController.instance.sessionsOn(DateTime.now());
      expect(todaySessions.length, 1);
    });

    test('weekDurations returns 7 durations', () {
      final durations = StudyController.instance.weekDurations;
      expect(durations.length, 7);
    });
  });

  group('Execution Loop — Task → Focus → Study Integration', () {
    test('task creation and focus session maintain context', () async {
      final task = await TaskController.instance.createTask(
        title: 'Review Chapter 5',
        priority: TaskPriority.high,
      );

      final mission = FocusMission(
        id: 'm1',
        objective: task.title,
        taskId: task.id,
      );
      FocusController.instance.startMission(mission);
      FocusController.instance.setPhase(FocusPhase.focusing);
      FocusController.instance.completeSession();

      expect(FocusController.instance.sessions.first.taskId, task.id);
      expect(FocusController.instance.sessions.first.objective, task.title);
    });

    test('study session records after focus completion', () async {
      StudyController.instance.startSession(subject: 'Physics');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final session = await StudyController.instance.endSession();

      expect(session, isNotNull);
      expect(session!.subject, 'Physics');
      expect(StudyController.instance.sessions.length, 1);
    });

    test('focus session with subject preserves subjectId', () {
      final mission = FocusMission(
        id: 'm1',
        objective: 'Study Chemistry',
        subjectId: 'sub_chem',
        subjectName: 'Chemistry',
      );
      FocusController.instance.startMission(mission);

      expect(FocusController.instance.activeSession?.subjectId, 'sub_chem');
      expect(FocusController.instance.activeSession?.subjectName, 'Chemistry');
    });

    test('focus session with exam preserves examId', () {
      final mission = FocusMission(
        id: 'm1',
        objective: 'Prepare for Final',
        examId: 'exam_final',
        subjectId: 'sub_math',
      );
      FocusController.instance.startMission(mission);

      expect(FocusController.instance.activeSession?.examId, 'exam_final');
      expect(FocusController.instance.activeSession?.subjectId, 'sub_math');
    });
  });
}
