import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';
import 'package:student_os/features/widgets/services/widget_data_service.dart';

/// Refresh + isolation: meaningful changes rebuild the snapshot, logout
/// writes the logged-out empty state, and users never cross.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  tearDown(() async {
    for (final t in List.of(TaskController.instance.tasks)) {
      await TaskController.instance.deleteTask(t.id);
    }
    for (final e in List.of(ExamController.instance.exams)) {
      await ExamController.instance.deleteExam(e.id);
    }
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  WidgetDataService service() => WidgetDataService.instance;

  Future<void> login(String user) async {
    AuthIsolation.instance.setAuthenticatedUser(user);
    ControllerIsolation.instance.reloadAllControllers(user);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  Future<void> logout() async {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  }

  group('refresh on meaningful changes', () {
    test('creating an exam changes the snapshot user content', () async {
      await login('w_refresh_a');
      final before = service().buildSnapshot('w_refresh_a', DateTime.now());
      expect(before.nextExam, isNull);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await ExamController.instance.createExam(
        title: 'Refresh Exam',
        examDateTime: today.add(const Duration(days: 4)),
      );

      final after = service().buildSnapshot('w_refresh_a', DateTime.now());
      expect(after.nextExam?.title, 'Refresh Exam');
      expect(after.nextExam?.daysLeft, 4);
    });

    test('completing a task moves it across counters', () async {
      await login('w_refresh_b');
      final task = await TaskController.instance.createTask(
        title: 'Countdown chore',
        dueDate: DateTime.now(),
      );
      final open = service().buildSnapshot('w_refresh_b', DateTime.now());
      final remainingBefore = open.todayTasks?.remaining ?? -1;

      await TaskController.instance.completeTask(task.id);
      final done = service().buildSnapshot('w_refresh_b', DateTime.now());
      expect(
        done.todayTasks?.remaining ?? 99,
        lessThanOrEqualTo(remainingBefore),
      );
      expect(done.todayTasks?.completed ?? 0, greaterThanOrEqualTo(1));
    });
  });

  group('logout + user switching', () {
    test("logout writes the logged-out empty snapshot", () async {
      await login('w_iso_a');
      await ExamController.instance.createExam(title: 'Private Exam');

      await logout();
      final snap = service().buildSnapshot('', DateTime.now());
      expect(snap.nextExam, isNull);
      expect(snap.todayTasks?.remaining ?? 0, 0);
    });

    test('user B never sees user A snapshot content', () async {
      await login('w_iso_a');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await ExamController.instance.createExam(
        title: 'A Secret Exam',
        examDateTime: today.add(const Duration(days: 3)),
      );
      await TaskController.instance.createTask(title: 'A secret task');
      final snapA = service().buildSnapshot('w_iso_a', DateTime.now());
      expect(snapA.nextExam?.title, 'A Secret Exam');

      await logout();
      await login('w_iso_b');
      final snapB = service().buildSnapshot('w_iso_b', DateTime.now());
      expect(snapB.nextExam, isNull);
      expect(snapB.userId, 'w_iso_b');

      await logout();
      await login('w_iso_a');
      final restored =
          service().buildSnapshot('w_iso_a', DateTime.now());
      expect(restored.nextExam?.title, 'A Secret Exam');
    });
  });
}
