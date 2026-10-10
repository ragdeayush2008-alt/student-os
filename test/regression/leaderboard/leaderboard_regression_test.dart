import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/features/progression/achievement_controller.dart';
import 'package:student_os/core/services/leaderboard_service.dart';
import 'package:student_os/core/services/ranking_engine.dart';
import 'package:student_os/data/models/leaderboard_entry.dart';
import 'package:student_os/features/progression/leaderboard_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_leaderboard_reg');
    await StorageService.instance.clearUser(userId: 'test_leaderboard_reg');
    AchievementController.instance.clearData();
    ProgressionController.instance.clearData();
    LeaderboardController.instance.clearData();
    await ProgressionController.instance.load();
    await LeaderboardController.instance.load();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
  });

  group('Leaderboard Regression Tests', () {
    test('handles empty entry lists without throwing exceptions', () {
      final ranked = RankingEngine.rankEntries([]);
      expect(ranked, isEmpty);

      final periodXp = RankingEngine.calculatePeriodXp([], LeaderboardPeriod.allTime);
      expect(periodXp, 0);
    });

    test('recovers safely from malformed cache entries', () async {
      final prefs = await SharedPreferences.getInstance();
      // Write corrupted JSON string in SharedPreferences
      await prefs.setString(
        'uos_test_leaderboard_reg_leaderboard_cache_thisWeek',
        '[{"invalid": true, "corrupt": 123}]',
      );

      final cached = await LeaderboardService.instance.loadCachedEntries(
        LeaderboardPeriod.thisWeek,
      );

      // Should handle parse errors gracefully without throwing
      expect(cached.length, 1);
      expect(cached[0].xp, 0);
    });

    test('handles null previousRank gracefully without fabricating movement', () {
      final entry = LeaderboardEntry(
        userId: 'test_u',
        displayName: 'Test',
        xp: 300,
        level: 2,
        rank: 1,
        previousRank: null,
      );

      expect(entry.movement, const RankMovement.neutral());
      expect(entry.movement.formatted, '—');
      expect(entry.movement.symbol, '—');
    });

    test('rapid period switching does not create race conditions or invalid state', () async {
      final lc = LeaderboardController.instance;

      // Rapidly fire period switches
      final futures = [
        lc.setPeriod(LeaderboardPeriod.thisWeek),
        lc.setPeriod(LeaderboardPeriod.thisMonth),
        lc.setPeriod(LeaderboardPeriod.allTime),
        lc.setPeriod(LeaderboardPeriod.thisWeek),
      ];

      await Future.wait(futures);

      expect(lc.isLoaded, isTrue);
      expect(lc.period, LeaderboardPeriod.thisWeek);
      expect(lc.entries.isNotEmpty, isTrue);
    });
  });
}
