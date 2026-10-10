import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/progression/achievement_controller.dart';
import 'package:student_os/data/models/leaderboard_entry.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/leaderboard_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_leaderboard_ctrl');
    await StorageService.instance.clearUser(userId: 'test_leaderboard_ctrl');
    AchievementController.instance.clearData();
    LeaderboardController.instance.clearData();
    ProgressionController.instance.clearData();
    await ProgressionController.instance.load();
    await LeaderboardController.instance.load();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
  });

  group('LeaderboardController', () {
    test('initializes with default period and loads currentUserEntry', () {
      final lc = LeaderboardController.instance;
      expect(lc.period, LeaderboardPeriod.thisWeek);
      expect(lc.isLoaded, isTrue);
      expect(lc.currentUserEntry, isNotNull);
      expect(lc.currentUserEntry!.isCurrentUser, isTrue);
    });

    test('changing period updates period and reloads leaderboard', () async {
      final lc = LeaderboardController.instance;

      await lc.setPeriod(LeaderboardPeriod.allTime);
      expect(lc.period, LeaderboardPeriod.allTime);

      await lc.setPeriod(LeaderboardPeriod.thisMonth);
      expect(lc.period, LeaderboardPeriod.thisMonth);
    });

    test('recomputes rankings in real-time when ProgressionController records XP event', () async {
      final lc = LeaderboardController.instance;
      final pc = ProgressionController.instance;

      expect(lc.currentUserEntry?.xp, 0);

      // Award XP
      await pc.recordEvent(
        XpEvent(
          id: 'live_ev_1',
          type: XpEventType.taskCompleted,
          amount: 120,
          timestamp: DateTime.now(),
          reason: 'Live task',
        ),
      );

      expect(lc.currentUserEntry?.xp, 120);
    });

    test('derived getters (topPodium, rankingList) partition entries accurately', () {
      final lc = LeaderboardController.instance;

      // When only 1 user exists
      expect(lc.topPodium.length, 1);
      expect(lc.rankingList, isEmpty);
    });

    test('clearData cleans in-memory state on logout', () {
      final lc = LeaderboardController.instance;
      expect(lc.isLoaded, isTrue);

      lc.clearData();

      expect(lc.isLoaded, isFalse);
      expect(lc.entries, isEmpty);
      expect(lc.errorMessage, isNull);
    });
  });
}
