import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/rewards/rewards_compatibility.dart';
import 'package:student_os/core/services/xp_engine.dart';
import 'package:student_os/data/models/level.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/progression_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 9 — XP Model & Serialization', () {
    test('XpEvent toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final event = XpEvent(
        id: 'test_event_1',
        type: XpEventType.taskCompleted,
        amount: 25,
        timestamp: now,
        reason: 'Completed physics assignment',
        taskId: 'task_123',
        subjectId: 'sub_456',
        metadata: {'priority': 'high'},
      );

      final json = event.toJson();
      final parsed = XpEvent.fromJson(json);

      expect(parsed.id, event.id);
      expect(parsed.type, event.type);
      expect(parsed.amount, event.amount);
      expect(parsed.reason, event.reason);
      expect(parsed.taskId, event.taskId);
      expect(parsed.subjectId, event.subjectId);
      expect(parsed.metadata?['priority'], 'high');
    });

    test('XpEvent handles missing optional fields safely', () {
      final json = {
        'id': 'minimal_event',
        'type': 'taskCompleted',
        'amount': 10,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final event = XpEvent.fromJson(json);

      expect(event.id, 'minimal_event');
      expect(event.type, XpEventType.taskCompleted);
      expect(event.amount, 10);
      expect(event.reason, isEmpty);
      expect(event.taskId, isNull);
      expect(event.examId, isNull);
      expect(event.subjectId, isNull);
      expect(event.metadata, isNull);
    });

    test('XpEvent defaults unknown event types safely', () {
      final json = {
        'id': 'future_event',
        'type': 'unknownFutureType',
        'amount': 10,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final event = XpEvent.fromJson(json);
      expect(event.type, XpEventType.taskCompleted); // Safe fallback
    });
  });

  group('Phase 9 — Level System & Curve', () {
    test('Level 1 requires 0 XP', () {
      expect(LevelCurve.xpForLevel(1), 0);
      expect(LevelCurve.levelForXp(0), 1);
      expect(LevelCurve.levelForXp(50), 1);
    });

    test('Level progression curve is monotonic and balanced', () {
      int prevXp = 0;
      for (var level = 2; level <= 20; level++) {
        final xp = LevelCurve.xpForLevel(level);
        expect(
          xp,
          greaterThan(prevXp),
          reason: 'Level $level should require more XP than Level ${level - 1}',
        );
        prevXp = xp;
      }
    });

    test('Level calculation from XP is accurate', () {
      final level5Xp = LevelCurve.xpForLevel(5);
      expect(LevelCurve.levelForXp(level5Xp), 5);
      expect(LevelCurve.levelForXp(level5Xp - 1), 4);
      expect(LevelCurve.levelForXp(level5Xp + 1), 5);
    });

    test('StudentLevel progress calculations work properly', () {
      final level = LevelCurve.forXp(150);
      expect(level.level, greaterThanOrEqualTo(1));
      expect(level.progressInLevel, inInclusiveRange(0.0, 1.0));
      expect(level.xpToNextLevel, greaterThan(0));
    });

    test('Level-up detection triggers correctly', () {
      final level4 = LevelCurve.forXp(LevelCurve.xpForLevel(4));
      final level5 = LevelCurve.forXp(LevelCurve.xpForLevel(5));

      expect(level5.justLeveledUp(level4.currentXp), isTrue);
      expect(level4.justLeveledUp(level4.currentXp), isFalse);
    });

    test('Level labels return appropriate descriptions', () {
      expect(LevelCurve.labelForLevel(1), 'Getting Started');
      expect(LevelCurve.labelForLevel(7), 'Focused Learner');
      expect(LevelCurve.labelForLevel(15), 'Consistent Student');
      expect(LevelCurve.labelForLevel(25), 'Academic Builder');
      expect(LevelCurve.labelForLevel(100), 'Student OS Legend');
    });
  });

  group('Phase 9 — XpEngine Rules', () {
    test('Task completion awards correct XP based on priority', () {
      final normalTask = StudentTask(
        id: 't1',
        title: 'Normal task',
        priority: TaskPriority.medium,
      );
      final highTask = StudentTask(
        id: 't2',
        title: 'High task',
        priority: TaskPriority.high,
      );
      final criticalTask = StudentTask(
        id: 't3',
        title: 'Critical task',
        priority: TaskPriority.critical,
      );

      expect(XpEngine.xpForTaskCompletion(normalTask), 10);
      expect(XpEngine.xpForTaskCompletion(highTask), 20);
      expect(XpEngine.xpForTaskCompletion(criticalTask), 30);
    });

    test('Study session awards XP only for meaningful duration', () {
      // Too short (< 5 min) -> 0 XP
      expect(XpEngine.xpForStudySession(120), 0);
      expect(XpEngine.xpForStudySession(299), 0);

      // Minimum session (5 min) -> 15 XP
      expect(XpEngine.xpForStudySession(300), 15);

      // 30 min session -> 15 + 5 = 20 XP
      expect(XpEngine.xpForStudySession(1800), 20);

      // 1 hour session -> 15 + 10 = 25 XP
      expect(XpEngine.xpForStudySession(3600), 25);

      // Max XP cap applied
      expect(XpEngine.xpForStudySession(36000), XpEngine.studySessionMaxXp);
    });

    test('Syllabus topic awards standard XP', () {
      expect(XpEngine.syllabusTopicXp, 25);
    });

    test('Exam completion awards standard XP', () {
      expect(XpEngine.examCompletionXp, 50);
    });

    test('Streak milestones scale appropriately', () {
      expect(XpEngine.streakMilestoneXp(1), 0);
      expect(XpEngine.streakMilestoneXp(2), 0);
      expect(XpEngine.streakMilestoneXp(3), 20);
      expect(XpEngine.streakMilestoneXp(7), 40);
      expect(XpEngine.streakMilestoneXp(14), 60);
      expect(XpEngine.streakMilestoneXp(30), 100);
    });
  });

  group('Phase 9 — Anti-Gaming & Deduplication', () {
    test('Task completion creates deterministic event ID', () {
      final now = DateTime(2026, 8, 29, 12, 0);
      final id1 = XpEngine.taskCompletionEventId('task_123', now);
      final id2 = XpEngine.taskCompletionEventId('task_123', now);

      expect(id1, id2);
      expect(id1, contains('task_complete_task_123'));
    });

    test('Syllabus completion creates deterministic event ID', () {
      final id1 = XpEngine.syllabusCompletionEventId('exam_1', 2);
      final id2 = XpEngine.syllabusCompletionEventId('exam_1', 2);
      final id3 = XpEngine.syllabusCompletionEventId('exam_1', 3);

      expect(id1, id2);
      expect(id1, isNot(id3));
    });

    test('ProgressionController prevents duplicate event processing', () async {
      final controller = ProgressionController.instance;
      await controller.load();

      final event = XpEvent(
        id: 'unique_event_test_1',
        type: XpEventType.taskCompleted,
        amount: 20,
        timestamp: DateTime.now(),
        reason: 'Test event',
      );

      final firstRecord = await controller.recordEvent(event);
      expect(firstRecord, isTrue);

      final secondRecord = await controller.recordEvent(event);
      expect(
        secondRecord,
        isFalse,
        reason: 'Duplicate event should be rejected',
      );
    });

    test('Awarding task completion multiple times is idempotent', () async {
      final controller = ProgressionController.instance;
      final task = StudentTask(
        id: 'idempotent_task_1',
        title: 'Task',
        status: TaskStatus.completed,
        completedAt: DateTime(2026, 8, 29, 10, 0),
      );

      final firstAward = await controller.awardTaskCompletion(task);
      expect(firstAward, isTrue);

      final secondAward = await controller.awardTaskCompletion(task);
      expect(secondAward, isFalse);
    });
  });

  group('Phase 9 — Rewards & Premium Compatibility', () {
    test('Eligibility check evaluates level and XP', () {
      const reward = StudentReward(
        id: 'theme_dark_gold',
        title: 'Gold Theme',
        description: 'Exclusive theme',
        type: RewardType.theme,
        requiredLevel: 5,
        xpCost: 200,
      );

      // Under level
      expect(
        RewardsCompatibility.isEligible(
          reward: reward,
          currentLevel: 4,
          availableXp: 500,
        ),
        isFalse,
      );

      // Under XP
      expect(
        RewardsCompatibility.isEligible(
          reward: reward,
          currentLevel: 10,
          availableXp: 150,
        ),
        isFalse,
      );

      // Eligible
      expect(
        RewardsCompatibility.isEligible(
          reward: reward,
          currentLevel: 5,
          availableXp: 200,
        ),
        isTrue,
      );
    });

    test('Premium discount scales gracefully with student level', () {
      expect(RewardsCompatibility.calculatePremiumDiscount(1), 0.0);
      expect(RewardsCompatibility.calculatePremiumDiscount(5), 0.05);
      expect(RewardsCompatibility.calculatePremiumDiscount(10), 0.10);
      expect(RewardsCompatibility.calculatePremiumDiscount(20), 0.15);
      expect(RewardsCompatibility.calculatePremiumDiscount(50), 0.20);
    });
  });
}
