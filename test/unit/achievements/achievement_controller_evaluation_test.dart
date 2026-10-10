import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/data/models/academic_resource.dart';
import 'package:student_os/data/models/achievement.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/progression/achievement_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/resources/resource_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AchievementController.instance.clearData();
    ProgressionController.instance.clearData();
    TaskController.instance.clearData();
    StudyController.instance.clearData();
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    ResourceController.instance.clearData();
    await ProgressionController.instance.load();
    await AchievementController.instance.load();
  });

  group('AchievementController Evaluation & Live Progress', () {
    test('task completion advances task achievements and unlocks threshold', () async {
      final ac = AchievementController.instance;
      expect(ac.earnedIds.contains('first_task'), isFalse);

      // Create and complete task
      final task = await TaskController.instance.createTask(title: 'Read chapter 1');
      await TaskController.instance.completeTask(task.id);
      await ac.evaluate();

      expect(ac.earnedIds.contains('first_task'), isTrue);
    });

    test('unlocking achievement with xpReward awards XP into ProgressionController', () async {
      final ac = AchievementController.instance;
      final pc = ProgressionController.instance;

      expect(pc.totalXp, 0);

      // Complete 1 task
      final task = await TaskController.instance.createTask(title: 'HW 1');
      await TaskController.instance.completeTask(task.id);

      await ac.evaluate();

      // first_task awards 10 XP
      expect(pc.totalXp, greaterThanOrEqualTo(10));
    });

    test('repeated evaluations do not duplicate XP awards (idempotency)', () async {
      final ac = AchievementController.instance;
      final pc = ProgressionController.instance;

      final task = await TaskController.instance.createTask(title: 'HW Repeat');
      await TaskController.instance.completeTask(task.id);

      await ac.evaluate();
      final xpAfterFirst = pc.totalXp;

      // Evaluate multiple times
      await ac.evaluate();
      await ac.evaluate();
      await ac.evaluate();

      expect(pc.totalXp, equals(xpAfterFirst));
    });

    test('entriesForCategory filters catalog entries accurately', () {
      final ac = AchievementController.instance;

      final all = ac.entriesForCategory(AchievementCategory.all);
      expect(all.length, AchievementCatalog.achievements.length);

      final focusOnly = ac.entriesForCategory(AchievementCategory.focus);
      expect(focusOnly.every((e) => e.achievement.category == AchievementCategory.focus), isTrue);

      final consistencyOnly = ac.entriesForCategory(AchievementCategory.consistency);
      expect(consistencyOnly.every((e) => e.achievement.category == AchievementCategory.consistency), isTrue);
    });

    test('exploration achievements unlock when adding subject and resource', () async {
      final ac = AchievementController.instance;

      // Add subject
      await SubjectController.instance.createSubject(name: 'Mathematics');
      var unlocked = await ac.evaluate();
      expect(unlocked.any((a) => a.id == 'first_subject'), isTrue);

      // Add resource
      await ResourceController.instance.createResource(
        title: 'Formula Sheet',
        resourceType: ResourceType.note,
      );
      unlocked = await ac.evaluate();
      expect(unlocked.any((a) => a.id == 'first_resource'), isTrue);
    });
  });
}
