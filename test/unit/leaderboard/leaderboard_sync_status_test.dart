import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/leaderboard_service.dart';
import 'package:student_os/core/services/supabase_service.dart';
import 'package:student_os/data/models/leaderboard_entry.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/leaderboard_controller.dart';
import 'package:student_os/features/progression/progression_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_sync_user');
    ProgressionController.instance.clearData();
    LeaderboardController.instance.clearData();
    SupabaseService.instance.resetForTesting();
    await ProgressionController.instance.load();
  });

  tearDown(() {
    ProgressionController.instance.clearData();
    LeaderboardController.instance.clearData();
    SupabaseService.instance.resetForTesting();
    AuthIsolation.instance.clearSession();
  });

  group('Leaderboard Sync Status & Connectivity Unit Tests', () {
    test('distinguishes live and offline fallback states honestly', () async {
      final lc = LeaderboardController.instance;

      // Initially, when Supabase is not ready, sync falls back to local/cached data
      await lc.load();

      expect(lc.isLoaded, isTrue);
      // In test environment without auth session, remote fetch will fail
      // but local data should still be present
      expect(lc.syncStatus, anyOf(
        LeaderboardSyncStatus.offlineFallback,
        LeaderboardSyncStatus.authRequired,
      ));
    });

    test('retains user XP integrity without fabricating fake competitors', () async {
      await ProgressionController.instance.recordEvent(
        XpEvent(
          id: 'xp_honest_1',
          type: XpEventType.taskCompleted,
          amount: 100,
          timestamp: DateTime.now(),
          reason: 'Honest XP task',
        ),
      );

      final lc = LeaderboardController.instance;
      await lc.load();

      final current = lc.currentUserEntry;
      expect(current, isNotNull);
      expect(current!.xp, 100);
      expect(current.isCurrentUser, isTrue);
      // No fake entries generated
      expect(lc.entries.length, 1);
      expect(lc.entries.first.userId, 'test_sync_user');
    });

    test('seamlessly merges cached entries when offline without wiping them', () async {
      await LeaderboardService.instance.saveCachedEntries(
        LeaderboardPeriod.thisWeek,
        [
          LeaderboardEntry(
            userId: 'peer_cached_1',
            displayName: 'Study Buddy',
            xp: 250,
            level: 2,
            rank: 1,
          ),
        ],
      );

      final lc = LeaderboardController.instance;
      await lc.load();

      expect(lc.entries.length, 2);
      expect(lc.entries.any((e) => e.userId == 'peer_cached_1'), isTrue);
      expect(lc.entries.any((e) => e.userId == 'test_sync_user'), isTrue);
      // Remote fetch will fail in test environment
      expect(lc.syncStatus, anyOf(
        LeaderboardSyncStatus.offlineFallback,
        LeaderboardSyncStatus.authRequired,
      ));
    });

    test('user isolation ensures user B does not see user A cache', () async {
      await LeaderboardService.instance.saveCachedEntries(
        LeaderboardPeriod.thisWeek,
        [
          LeaderboardEntry(
            userId: 'user_a',
            displayName: 'Alice',
            xp: 500,
            level: 3,
            rank: 1,
            isCurrentUser: true,
          ),
        ],
      );

      // Switch to user B
      AuthIsolation.instance.setAuthenticatedUser('user_b');
      LeaderboardController.instance.clearData();
      ProgressionController.instance.clearData();
      await ProgressionController.instance.load();
      await LeaderboardController.instance.load();

      final entryB = LeaderboardController.instance.currentUserEntry;
      expect(entryB?.userId, 'user_b');
      expect(entryB?.xp, 0);
    });
  });
}