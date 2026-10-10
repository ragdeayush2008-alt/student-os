import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/achievement.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/level.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/leaderboard_entry.dart';
import 'package:student_os/data/models/app_notification.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/data/models/focus_mission.dart';
import 'package:student_os/features/notifications/notification_controller.dart';
import 'package:student_os/features/preferences/user_preferences_controller.dart';
import 'package:student_os/features/progression/achievement_controller.dart';
import 'package:student_os/features/progression/leaderboard_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/rewards/redemption_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('integration_student');
    await NotificationController.instance.clearAllNotifications();
    TaskController.instance.clearData();
    ExamController.instance.clearData();
    ProgressionController.instance.clearData();
    AchievementController.instance.clearData();
    StudyController.instance.clearData();
    FocusController.instance.clearData();
    RedemptionController.instance.clearData();
    LeaderboardController.instance.clearData();
    await UserPreferencesController.instance.load();
    await NotificationController.instance.load();
  });

  group('Notification & Activity Center 2.0 Integration Tests', () {
    test('Task completion generates taskCompleted notification', () async {
      final task = await TaskController.instance.createTask(
        title: 'Complete Math Assignment',
      );

      await TaskController.instance.completeTask(task.id);

      final notifs = NotificationController.instance.notifications;
      expect(notifs.any((n) => n.id == 'task_completed_${task.id}'), isTrue);
      final notif =
          notifs.firstWhere((n) => n.id == 'task_completed_${task.id}');
      expect(notif.type, NotificationType.taskCompleted);
      expect(notif.entityId, task.id);
      expect(notif.isRead, isFalse);
    });

    test('Progression level-up generates levelUp notification', () async {
      const newLevel = StudentLevel(
        level: 5,
        currentXp: 1200,
        xpForCurrentLevel: 1000,
        xpForNextLevel: 1500,
      );

      await NotificationController.instance.onLevelUp(newLevel);

      final notifs = NotificationController.instance.notifications;
      expect(notifs.any((n) => n.id == 'level_up_5'), isTrue);
      final notif = notifs.firstWhere((n) => n.id == 'level_up_5');
      expect(notif.type, NotificationType.levelUp);
      expect(notif.title, contains('Level 5'));
    });

    test('Achievement unlock generates achievementUnlocked notification', () async {
      final achievement = AchievementCatalog.achievements.first;

      await NotificationController.instance.onAchievementUnlocked(achievement);

      final notifs = NotificationController.instance.notifications;
      expect(
        notifs.any((n) => n.id == 'achievement_unlocked_${achievement.id}'),
        isTrue,
      );
      final notif = notifs.firstWhere(
        (n) => n.id == 'achievement_unlocked_${achievement.id}',
      );
      expect(notif.type, NotificationType.achievementUnlocked);
      expect(notif.title, 'Achievement Unlocked!');
      expect(notif.body, contains(achievement.title));
    });

    test('Focus session completion generates focusCompleted notification', () async {
      final now = DateTime.now();
      final session = FocusSession(
        id: 'focus_sess_1',
        missionId: 'mission_1',
        objective: 'Study Chem',
        startedAt: now.subtract(const Duration(minutes: 25)),
        focusDuration: const Duration(minutes: 25),
        subjectName: 'Organic Chemistry',
        mode: FocusMode.timer,
        outcome: SessionOutcome.completed,
      );

      await NotificationController.instance.onFocusCompleted(session);

      final notifs = NotificationController.instance.notifications;
      expect(
        notifs.any((n) => n.id == 'focus_completed_${session.id}'),
        isTrue,
      );
      final notif =
          notifs.firstWhere((n) => n.id == 'focus_completed_${session.id}');
      expect(notif.type, NotificationType.focusCompleted);
      expect(notif.body, contains('Organic Chemistry'));
    });

    test('Study session completion generates studyCompleted notification', () async {
      final now = DateTime.now();
      final session = StudySession(
        id: 'study_sess_1',
        subject: 'History',
        startedAt: now.subtract(const Duration(minutes: 40)),
        endedAt: now,
        durationSec: 2400,
        completed: true,
      );

      await NotificationController.instance.onStudyCompleted(session);

      final notifs = NotificationController.instance.notifications;
      expect(
        notifs.any((n) => n.id == 'study_completed_${session.id}'),
        isTrue,
      );
      final notif =
          notifs.firstWhere((n) => n.id == 'study_completed_${session.id}');
      expect(notif.type, NotificationType.studyCompleted);
      expect(notif.body, contains('History'));
    });

    test('Exam evaluation generates examUpcoming notification idempotently', () async {
      final now = DateTime.now();
      final exam = StudentExam(
        id: 'exam_upcoming_test',
        title: 'Final Biology Exam',
        examDateTime: now.add(const Duration(days: 3)),
        status: ExamStatus.upcoming,
      );

      await NotificationController.instance.evaluateUpcomingExams([exam]);
      final initialCount =
          NotificationController.instance.notifications.length;
      expect(initialCount, 1);

      // Repeated evaluation must not create duplicate
      await NotificationController.instance.evaluateUpcomingExams([exam]);
      expect(
        NotificationController.instance.notifications.length,
        initialCount,
      );
    });

    test('Streak milestone generates streakMilestone notification', () async {
      await NotificationController.instance.onStreakMilestone(7);

      final notifs = NotificationController.instance.notifications;
      expect(notifs.any((n) => n.id == 'streak_milestone_7'), isTrue);
      final notif = notifs.firstWhere((n) => n.id == 'streak_milestone_7');
      expect(notif.type, NotificationType.streakMilestone);
      expect(notif.title, contains('7-Day Streak'));
    });

    test('Leaderboard rank movement generates leaderboardMovement notification', () async {
      await NotificationController.instance.onLeaderboardRankChanged(
        LeaderboardPeriod.thisWeek,
        15,
        10,
      );

      final notifs = NotificationController.instance.notifications;
      expect(
        notifs.any((n) => n.type == NotificationType.leaderboardMovement),
        isTrue,
      );
      final notif = notifs.firstWhere(
        (n) => n.type == NotificationType.leaderboardMovement,
      );
      expect(notif.body, contains('#15 to #10'));
    });

    test('Reward unlocked generates rewardUnlocked notification', () async {
      await NotificationController.instance.onRewardUnlocked(
        'theme_academic',
        'Academic Light Theme',
      );

      final notifs = NotificationController.instance.notifications;
      expect(
        notifs.any((n) => n.id == 'reward_unlocked_theme_academic'),
        isTrue,
      );
      final notif = notifs.firstWhere(
        (n) => n.id == 'reward_unlocked_theme_academic',
      );
      expect(notif.type, NotificationType.rewardUnlocked);
      expect(notif.body, contains('Academic Light Theme'));
    });
  });
}
