import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/progression/achievement_controller.dart';
import 'package:student_os/core/services/leaderboard_service.dart';
import 'package:student_os/data/models/leaderboard_entry.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/progression_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_leaderboard_svc');
    await StorageService.instance.clearUser(userId: 'test_leaderboard_svc');
    AchievementController.instance.clearData();
    ProgressionController.instance.clearData();
    await ProgressionController.instance.load();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
  });

  group('LeaderboardService', () {
    test('createCurrentUserEntry uses authoritative progression data', () async {
      await ProgressionController.instance.recordEvent(
        XpEvent(
          id: 'test_ev_1',
          type: XpEventType.taskCompleted,
          amount: 150,
          timestamp: DateTime.now(),
          reason: 'Completed homework',
        ),
      );

      final entry = LeaderboardService.instance.createCurrentUserEntry(
        LeaderboardPeriod.allTime,
      );

      expect(entry.xp, 150);
      expect(entry.isCurrentUser, isTrue);
      expect(entry.level, greaterThanOrEqualTo(1));
    });

    test('saveCachedEntries and loadCachedEntries persist and restore user-scoped data', () async {
      final entries = [
        LeaderboardEntry(
          userId: 'u1',
          displayName: 'Player One',
          xp: 800,
          level: 3,
          rank: 1,
        ),
        LeaderboardEntry(
          userId: 'demo',
          displayName: 'You',
          xp: 400,
          level: 2,
          rank: 2,
          isCurrentUser: true,
        ),
      ];

      await LeaderboardService.instance.saveCachedEntries(
        LeaderboardPeriod.thisWeek,
        entries,
      );

      final restored = await LeaderboardService.instance.loadCachedEntries(
        LeaderboardPeriod.thisWeek,
      );

      expect(restored.length, 2);
      expect(restored[0].userId, 'u1');
      expect(restored[0].xp, 800);
      expect(restored[1].userId, 'demo');
      expect(restored[1].isCurrentUser, isTrue);
    });

    test('savePreviousRanks and loadPreviousRanks store historical rankings', () async {
      final ranks = {'user_a': 1, 'user_b': 2, 'demo': 3};

      await LeaderboardService.instance.savePreviousRanks(
        LeaderboardPeriod.thisMonth,
        ranks,
      );

      final loaded = await LeaderboardService.instance.loadPreviousRanks(
        LeaderboardPeriod.thisMonth,
      );

      expect(loaded, equals(ranks));
    });

    test('clearUserCache removes all period caches for active user', () async {
      await LeaderboardService.instance.saveCachedEntries(
        LeaderboardPeriod.allTime,
        [
          LeaderboardEntry(userId: 'u1', displayName: 'X', xp: 100, level: 1, rank: 1),
        ],
      );

      await LeaderboardService.instance.clearUserCache();

      final cached = await LeaderboardService.instance.loadCachedEntries(
        LeaderboardPeriod.allTime,
      );
      expect(cached, isEmpty);
    });

    test('resolveLeaderboard seamlessly merges local authoritative user with cache when offline', () async {
      // Award local XP
      await ProgressionController.instance.recordEvent(
        XpEvent(
          id: 'test_ev_2',
          type: XpEventType.taskCompleted,
          amount: 500,
          timestamp: DateTime.now(),
          reason: 'Big project',
        ),
      );

      // Pre-seed cache with other users
      await LeaderboardService.instance.saveCachedEntries(
        LeaderboardPeriod.allTime,
        [
          LeaderboardEntry(userId: 'peer_1', displayName: 'Top Peer', xp: 1000, level: 4, rank: 1),
          LeaderboardEntry(userId: 'peer_2', displayName: 'Lower Peer', xp: 200, level: 1, rank: 2),
        ],
      );

      final result = await LeaderboardService.instance.resolveLeaderboard(
        LeaderboardPeriod.allTime,
      );

      expect(result.entries.length, 3);
      // Top Peer (1000 XP) -> Rank 1
      expect(result.entries[0].userId, 'peer_1');
      expect(result.entries[0].rank, 1);
      // Local User (500 XP + 50 XP level 5 achievement bonus) -> Rank 2.
      // Carries the authenticated user id (never a shared fallback).
      expect(result.entries[1].userId, 'test_leaderboard_svc');
      expect(result.entries[1].xp, 550);
      expect(result.entries[1].rank, 2);
      expect(result.entries[1].isCurrentUser, isTrue);
      // Lower Peer (200 XP) -> Rank 3
      expect(result.entries[2].userId, 'peer_2');
      expect(result.entries[2].rank, 3);
      // Remote fetch should fail in test environment (no auth session)
      expect(result.isOffline, isTrue);
    });

    test('period caches are strictly isolated per period', () async {
      await LeaderboardService.instance.saveCachedEntries(
        LeaderboardPeriod.thisWeek,
        [LeaderboardEntry(userId: 'u1', displayName: 'Week Guy', xp: 50, level: 1, rank: 1)],
      );

      await LeaderboardService.instance.saveCachedEntries(
        LeaderboardPeriod.allTime,
        [LeaderboardEntry(userId: 'u1', displayName: 'All Time Guy', xp: 500, level: 3, rank: 1)],
      );

      final week = await LeaderboardService.instance.loadCachedEntries(LeaderboardPeriod.thisWeek);
      final allTime = await LeaderboardService.instance.loadCachedEntries(LeaderboardPeriod.allTime);

      expect(week.first.xp, 50);
      expect(allTime.first.xp, 500);
      expect(week.first.xp, isNot(equals(allTime.first.xp)));
    });
  });
}
