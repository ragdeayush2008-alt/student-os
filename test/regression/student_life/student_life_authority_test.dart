import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/notification_service.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/student_life/models/student_life_preferences.dart';
import 'package:student_os/features/student_life/student_life_controller.dart';
import 'package:student_os/features/student_life/presentation/student_life_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 30, 9);
  final day = DateTime(2026, 9, 30);

  Future<void> signIn(String userId) async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    AppClock.freezeAt(now);
    AuthIsolation.instance.setAuthenticatedUser(userId);
    await PlanningBlockController.instance.load();
    await AcademicScheduleController.instance.load();
    await StudentLifeController.instance.load();
  }

  tearDown(() {
    AppClock.reset();
  });

  group('Student Life regression — authority boundaries', () {
    test('L1. deriving a plan never mutates planning blocks', () async {
      await signIn('sl_regression_blocks');
      final block = await PlanningBlockController.instance.scheduleBlock(
        'task_alpha',
        DateTime(2026, 9, 30, 10),
        DateTime(2026, 9, 30, 12),
      );

      for (var i = 0; i < 3; i++) {
        StudentLifeController.instance.dailyPlan(day);
      }

      final blocks = PlanningBlockController.instance.blocksForDay(day);
      expect(blocks, hasLength(1));
      expect(blocks.single.id, block.id);
      expect(blocks.single.startAt, block.startAt);
      expect(blocks.single.endAt, block.endAt);
    });

    test('L2. deriving a plan never writes to the academic calendar', () async {
      await signIn('sl_regression_calendar');

      StudentLifeController.instance.dailyPlan(day);
      StudentLifeController.instance.dailyPlan(day.add(const Duration(days: 1)));

      expect(AcademicScheduleController.instance.events, isEmpty);
    });

    test('L3. Student Life storage stays user-scoped', () async {
      await signIn('sl_regression_scope');
      await StudentLifeController.instance.logSleep(
        bedtime: DateTime(2026, 9, 29, 23),
        wakeTime: DateTime(2026, 9, 30, 7),
      );

      final storage = StorageService.instance;
      final mine = await storage.loadJsonList(
        userId: 'sl_regression_scope',
        key: 'student_life_sleep_records',
      );
      final theirs = await storage.loadJsonList(
        userId: 'sl_regression_other',
        key: 'student_life_sleep_records',
      );

      expect(mine, hasLength(1));
      expect(theirs, isNull);

      AuthIsolation.instance.setAuthenticatedUser('sl_regression_other');
      await StudentLifeController.instance.load();

      expect(StudentLifeController.instance.sleepRecords, isEmpty);
    });

    test('L4. Student Life notification ids never collide with existing ones',
        () {
      final existing = <int>{
        NotificationIds.studyReminder(),
        NotificationIds.planningReminder(),
        NotificationIds.taskReminder('task_1'),
        NotificationIds.examReminder('exam_1', 1),
      };
      final studentLife = [
        'hydration',
        'breakfast',
        'lunch',
        'dinner',
        'exercise',
        'wind_down',
        'bedtime',
        'nap',
        'study_break',
      ].map(NotificationIds.studentLifeReminder).toSet();

      expect(studentLife.intersection(existing), isEmpty);
      expect(studentLife, hasLength(studentLife.length));
      expect(
        NotificationIds.studentLifeReminder('hydration'),
        NotificationIds.studentLifeReminder('hydration'),
      );
    });

    test('L5. notification payload type flags stay independent', () {
      final task = NotificationPayload(type: 'task', entityId: 't1');
      final studentLife = NotificationPayload(
        type: 'student_life',
        entityId: 'bedtime',
      );

      expect(task.isTask, isTrue);
      expect(task.isStudentLife, isFalse);
      expect(studentLife.isStudentLife, isTrue);
      expect(studentLife.isTask, isFalse);
      expect(studentLife.isExam, isFalse);
    });

    testWidgets('L6. the Student Life route stays registered in the app router',
        (tester) async {
      final routes = AppRouter.routes();

      expect(routes.containsKey(AppRouter.studentLifeRoute), isTrue);

      late Widget built;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            built = routes[AppRouter.studentLifeRoute]!(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(built, isA<StudentLifeScreen>());
    });

    test('L7. existing preference keys are untouched by Student Life', () async {
      await signIn('sl_regression_prefs');
      await StudentLifeController.instance.updatePreferences(
        const StudentLifePreferences(targetSleepMinutes: 400),
      );

      final storage = StorageService.instance;
      final studentLifePrefs = await storage.loadJson(
        userId: 'sl_regression_prefs',
        key: 'student_life_preferences',
      );
      final appPrefs = await storage.loadJson(
        userId: 'sl_regression_prefs',
        key: 'user_preferences',
      );

      expect(studentLifePrefs?['targetSleepMinutes'], 400);
      expect(appPrefs, isNull);
    });
  });
}
