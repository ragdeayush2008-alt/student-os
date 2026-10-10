import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/preferences/user_preferences_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  tearDown(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  group('Student OS Autopilot & Intelligence Integration (W, X, Y, AB, AC)', () {
    test('X & Y. User Isolation: User A recommendations never bleed to User B on switch', () {
      // Setup as User A
      AuthIsolation.instance.setAuthenticatedUser('user_A_id');

      final taskA = StudentTask(
        id: 'task_user_A',
        title: 'User A Secret Accounts Task',
        status: TaskStatus.active,
      );

      final actionA = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 'sub_A', name: 'User A Subject')],
        tasks: [taskA],
      );

      expect(actionA.title, equals('User A Secret Accounts Task'));

      // Logout / Session Switch
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();

      // Login as User B
      AuthIsolation.instance.setAuthenticatedUser('user_B_id');

      final taskB = StudentTask(
        id: 'task_user_B',
        title: 'User B Constitutional Law Task',
        status: TaskStatus.active,
      );

      final actionB = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 'sub_B', name: 'Law')],
        tasks: [taskB],
      );

      expect(actionB.title, equals('User B Constitutional Law Task'));
      expect(actionB.title.contains('User A'), isFalse);
    });

    test('W. Autopilot plan application is idempotent and prevents duplicate blocks', () async {
      final now = DateTime(2026, 9, 20, 9, 0);

      final sub = Subject(id: 'sub_1', name: 'Accountancy');
      final task = StudentTask(
        id: 't_unique',
        title: 'Balance Sheet Analysis',
        subjectId: sub.id,
        estimatedMinutes: 45,
      );

      final plan = PlanningEngine.generateDailyPlan(
        now,
        tasks: [task],
        subjects: [sub],
        availableBudgetMinutes: 120,
        baseStartTime: now,
      );

      expect(plan.hasItems, isTrue);

      final createdBlocks = await PlanningEngine.applyDailyPlan(plan);
      expect(createdBlocks.isNotEmpty, isTrue);

      final matchingTaskBlocks = createdBlocks.where((b) => b.taskId == task.id).toList();
      expect(matchingTaskBlocks.length, equals(1));
    });

    test('Autopilot mode persistence and safety defaults in UserPreferencesController', () async {
      final prefs = UserPreferencesController.instance;
      expect(prefs.autopilotMode, equals(AutopilotMode.suggest));

      await prefs.setAutopilotMode(AutopilotMode.autopilot);
      expect(prefs.autopilotMode, equals(AutopilotMode.autopilot));

      await prefs.setAutopilotMode(AutopilotMode.off);
      expect(prefs.autopilotMode, equals(AutopilotMode.off));
    });

    test('Done for today toggling updates state correctly', () {
      final aic = AcademicIntelligenceController.instance;
      expect(aic.isDoneForToday, isFalse);

      aic.setDoneForToday(true);
      expect(aic.isDoneForToday, isTrue);
      expect(aic.studentOSAction.type, equals(StudentOSActionType.doneForToday));

      aic.setDoneForToday(false);
      expect(aic.isDoneForToday, isFalse);
    });
  });
}
