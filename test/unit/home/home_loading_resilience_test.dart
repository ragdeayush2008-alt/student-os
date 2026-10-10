import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Home loading-gate resilience.
///
/// Home shows an infinite loading state while any of Tasks/Exams/Study
/// reports `isLoaded == false`. A corrupt local cache entry must never leave
/// a controller permanently "not loaded" — load() must always terminate in
/// the loaded state (starting empty; cloud sync heals when available).
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
    AuthIsolation.instance.clearSession();
  });

  group('corrupt cache never bricks loading', () {
    test('tasks: garbage entry still ends loaded (empty, not stuck)',
        () async {
      AuthIsolation.instance.setAuthenticatedUser('home_resilience_user');
      await StorageService.instance.saveJsonList(
        userId: 'home_resilience_user',
        key: 'tasks',
        list: [
          {'id': 123, 'title': 456},
        ],
      );

      await TaskController.instance.load();

      expect(TaskController.instance.isLoaded, isTrue);
      expect(TaskController.instance.tasks, isEmpty);
    });

    test('exams: garbage entry still ends loaded (empty, not stuck)',
        () async {
      AuthIsolation.instance.setAuthenticatedUser('home_resilience_user');
      await StorageService.instance.saveJsonList(
        userId: 'home_resilience_user',
        key: 'exams',
        list: [
          {'id': 123, 'title': 456},
        ],
      );

      await ExamController.instance.load();

      expect(ExamController.instance.isLoaded, isTrue);
      expect(ExamController.instance.exams, isEmpty);
    });

    test('study: garbage entry still ends loaded (empty, not stuck)',
        () async {
      AuthIsolation.instance.setAuthenticatedUser('home_resilience_user');
      await StorageService.instance.saveJsonList(
        userId: 'home_resilience_user',
        key: 'study_sessions',
        list: [
          {'id': 123},
        ],
      );

      await StudyController.instance.load();

      expect(StudyController.instance.isLoaded, isTrue);
      expect(StudyController.instance.sessions, isEmpty);
    });
  });
}
