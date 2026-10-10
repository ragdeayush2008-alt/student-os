import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/planning/planning_screen.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('plan_study_2_user');
    ControllerIsolation.instance.clearAllControllers();
    await SubjectController.instance.load();
    await TaskController.instance.load();
    await PlanningBlockController.instance.load();
  });

  group('Plan & Study 2.0 — Unit Tests', () {
    test('1. PlanStudyTab enum has plan and study with plan default', () {
      expect(PlanStudyTab.values, contains(PlanStudyTab.plan));
      expect(PlanStudyTab.values, contains(PlanStudyTab.study));
      expect(const PlanningScreen().initialTab, PlanStudyTab.plan);
    });

    test('2. Quick auto-plan generates valid daily plan items for available time', () async {
      final s1 = await SubjectController.instance.createSubject(name: 'Accountancy');
      final s2 = await SubjectController.instance.createSubject(name: 'Economics');

      final targetDay = DateTime.now();
      final plan30 = PlanController.instance.generateDailyPlan(day: targetDay, budgetMinutes: 30);
      expect(plan30.items.isNotEmpty, isTrue);
      expect(plan30.totalPlannedMinutes, lessThanOrEqualTo(30));

      final plan120 = PlanController.instance.generateDailyPlan(day: targetDay, budgetMinutes: 120);
      expect(plan120.items.length, greaterThanOrEqualTo(1));
      expect(plan120.totalPlannedMinutes, lessThanOrEqualTo(120));
    });

    test('3. Applying daily plan writes planning blocks without duplication', () async {
      await SubjectController.instance.createSubject(name: 'Business Law');
      final targetDay = DateTime(2026, 10, 15);

      final plan = PlanController.instance.generateDailyPlan(day: targetDay, budgetMinutes: 60);
      final blocks = await PlanningEngine.applyDailyPlan(plan);

      expect(blocks.isNotEmpty, isTrue);
      final count = PlanningBlockController.instance.blocksForDay(targetDay).length;
      expect(count, blocks.length);
    });
  });
}
