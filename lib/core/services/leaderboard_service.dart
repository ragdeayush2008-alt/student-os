import 'package:flutter/foundation.dart';

import '../../data/models/leaderboard_entry.dart';
import '../../data/models/level.dart';
import '../../features/auth/auth_service.dart';
import '../../features/progression/progression_controller.dart';
import '../auth/auth_isolation.dart';
import '../services/ranking_engine.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';
import '../services/student_service.dart';
import '../services/supabase_service.dart';
import '../sync/sync_engine.dart';

/// Service managing leaderboard data derivation, offline persistence, and cloud synchronization.
///
/// Follows the Student OS architecture:
/// - Reuses existing [ProgressionController] as the single source of truth for XP.
/// - Never fabricates fake competitors or fake XP values.
/// - Persists per-user local cache in [StorageService].
/// - Enforces strict user isolation and non-leaking state on logout.
class LeaderboardService {
  LeaderboardService._();

  static final LeaderboardService instance = LeaderboardService._();

  static const String _cachePrefix = 'leaderboard_cache_';
  static const String _prevRanksPrefix = 'leaderboard_prev_ranks_';
  static const String _tableName = 'leaderboard_entries';

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Local User Entry Derivation ────────────────────────────────────────

  /// Builds the authoritative [LeaderboardEntry] for the currently active user
  /// directly from verified local controllers.
  LeaderboardEntry createCurrentUserEntry(
    LeaderboardPeriod period, {
    int rank = 1,
    int? previousRank,
  }) {
    final pc = ProgressionController.instance;
    final profile = StudentService.instance.profile;
    final streak = StreakService.instance.currentStreak;

    final periodXp = RankingEngine.calculatePeriodXp(pc.events, period);
    final totalXp = pc.totalXp;
    final level = LevelCurve.forXp(totalXp).level;

    final displayName = profile.displayName.trim().isNotEmpty
        ? profile.displayName.trim()
        : (profile.email.isNotEmpty ? profile.email.split('@').first : 'You');

    // Unattributed in-memory marker when identity is unknown; such entries
    // are never persisted (cache writes skip null identities) nor synced.
    final uid = _userId;
    return LeaderboardEntry(
      userId: uid ?? '',
      displayName: displayName,
      xp: periodXp,
      level: level,
      rank: rank,
      previousRank: previousRank,
      streak: streak,
      period: period,
      updatedAt: DateTime.now(),
      isCurrentUser: true,
    );
  }

  // ─── Local Storage Caching ──────────────────────────────────────────────

  /// Loads cached leaderboard entries for the active user and period.
  Future<List<LeaderboardEntry>> loadCachedEntries(LeaderboardPeriod period) async {
    final uid = _userId;
    if (uid == null) return const [];
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: '$_cachePrefix${period.name}',
    );

    if (list == null || list.isEmpty) {
      return const [];
    }

    final entries = <LeaderboardEntry>[];
    for (final item in list) {
      try {
        entries.add(LeaderboardEntry.fromJson(item, currentUserId: _userId));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[LeaderboardService] Error parsing cached entry: $e');
        }
      }
    }

    return entries;
  }

  /// Saves cached leaderboard entries for the active user and period.
  Future<void> saveCachedEntries(
    LeaderboardPeriod period,
    List<LeaderboardEntry> entries,
  ) async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: '$_cachePrefix${period.name}',
      list: entries.map((e) => e.toJson()).toList(),
    );
  }

  /// Loads saved previous rank mapping (`userId -> rank`) to calculate honest movement.
  Future<Map<String, int>> loadPreviousRanks(LeaderboardPeriod period) async {
    final uid = _userId;
    if (uid == null) return const {};
    final json = await StorageService.instance.loadJson(
      userId: uid,
      key: '$_prevRanksPrefix${period.name}',
    );

    if (json == null) return const {};

    final map = <String, int>{};
    for (final entry in json.entries) {
      if (entry.value is int) {
        map[entry.key] = entry.value as int;
      }
    }
    return map;
  }

  /// Saves previous rank positions for historical movement tracking.
  Future<void> savePreviousRanks(
    LeaderboardPeriod period,
    Map<String, int> ranks,
  ) async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJson(
      userId: uid,
      key: '$_prevRanksPrefix${period.name}',
      json: ranks,
    );
  }

  /// Clears all cached leaderboard data for the active user (called on logout/account reset).
  Future<void> clearUserCache() async {
    final uid = _userId;
    if (uid == null) return;
    for (final p in LeaderboardPeriod.values) {
      await StorageService.instance.remove(
        userId: uid,
        key: '$_cachePrefix${p.name}',
      );
      await StorageService.instance.remove(
        userId: uid,
        key: '$_prevRanksPrefix${p.name}',
      );
    }
  }

  // ─── Cloud Sync & Fetch ──────────────────────────────────────────────────

  /// Fetches remote leaderboard entries from Supabase if connected.
  ///
  /// Strictly queries period-specific columns (`week_xp`, `month_xp`, `total_xp`)
  /// to ensure weekly/monthly scores are never conflated with lifetime XP.
  /// Returns null if offline, unconfigured, or if the remote table is unreachable.
  Future<List<LeaderboardEntry>?> fetchRemoteEntries(LeaderboardPeriod period) async {
    final result = await fetchRemoteEntriesWithDiagnostics(period);
    return result.entries;
  }

  /// Enqueues current user's public progression aggregate for cloud sync.
  ///
  /// Safe and privacy-preserving: only public display name, period XP, total XP, level, and streak are sent.
  Future<void> syncCurrentUserProgression() async {
    final user = AuthService.instance.user;
    if (user == null) return;

    final pc = ProgressionController.instance;
    final profile = StudentService.instance.profile;
    final streak = StreakService.instance.currentStreak;

    final weekXp = RankingEngine.calculatePeriodXp(pc.events, LeaderboardPeriod.thisWeek);
    final monthXp = RankingEngine.calculatePeriodXp(pc.events, LeaderboardPeriod.thisMonth);
    final totalXp = pc.totalXp;

    final payload = <String, dynamic>{
      'user_id': user.id,
      'display_name': profile.displayLabel,
      'total_xp': totalXp,
      'week_xp': weekXp,
      'month_xp': monthXp,
      'level': pc.currentLevel.level,
      'streak': streak,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await SyncQueue.instance.enqueue(
      table: _tableName,
      recordId: user.id,
      type: SyncOperationType.upsert,
      payload: payload,
    );

    // Trigger cloud sync
    SyncEngine.instance.synchronize();
  }

  // ─── Full Ranking Resolution ─────────────────────────────────────────────

  /// Resolves the complete, deterministically ranked leaderboard for [period].
  ///
  /// Combines authoritative local user stats with remote or cached entries,
  /// preserving offline usability without fabricating fake data.
  ///
  /// Returns a record with:
  /// - `entries`: ranked entries (may be empty if no data)
  /// - `isOffline`: true if remote fetch failed or was unavailable
  /// - `isStale`: true if cached data is being shown instead of live data
  /// - `remoteError`: a diagnostic string for the remote failure, or null
  Future<({List<LeaderboardEntry> entries, bool isOffline, bool isStale, String? remoteError})>
      resolveLeaderboard(LeaderboardPeriod period) async {
    final previousRanks = await loadPreviousRanks(period);

    // 1. Attempt remote fetch
    final remoteResult = await fetchRemoteEntriesWithDiagnostics(period);
    final bool isOffline = remoteResult.entries == null;
    final bool isRemoteSuccess = remoteResult.entries != null;
    final String? remoteError = remoteResult.error;
    bool isStale = false;

    List<LeaderboardEntry> baseEntries;
    if (isRemoteSuccess && remoteResult.entries!.isNotEmpty) {
      baseEntries = remoteResult.entries!;
    } else {
      // 2. Fall back to local cache
      final cached = await loadCachedEntries(period);
      if (cached.isNotEmpty) {
        baseEntries = cached;
        isStale = true;
      } else {
        baseEntries = const [];
      }
    }

    // 3. Guarantee current user presence with authoritative local XP.
    // Skipped when identity is unknown: never merge unattributed entries.
    final uid = _userId;
    final merged = <String, LeaderboardEntry>{};
    for (final entry in baseEntries) {
      if (entry.userId.isNotEmpty) {
        merged[entry.userId] = entry;
      }
    }
    if (uid != null && uid.isNotEmpty) {
      final localUserEntry = createCurrentUserEntry(
        period,
        previousRank: previousRanks[uid],
      );
      // Local authoritative data always takes precedence for current user
      merged[uid] = localUserEntry;
    }

    // 4. Deterministic ranking
    final ranked = RankingEngine.rankEntries(
      merged.values.toList(),
      previousRanks: previousRanks,
    );

    // 5. Persist to cache
    await saveCachedEntries(period, ranked);

    // 6. Update previous ranks cache if we had fresh remote data
    if (isRemoteSuccess && ranked.isNotEmpty) {
      final newRanks = <String, int>{};
      for (final item in ranked) {
        newRanks[item.userId] = item.rank;
      }
      await savePreviousRanks(period, newRanks);
    }

    return (
      entries: ranked,
      isOffline: isOffline,
      isStale: isStale,
      remoteError: remoteError,
    );
  }

  /// Fetches remote entries with diagnostic error reporting.
  ///
  /// Distinguishes between:
  /// - Network/offline: returns null with no error
  /// - Auth required: returns null with auth error
  /// - Query/schema failure: returns null with error detail
  /// - Success: returns entries
  Future<({List<LeaderboardEntry>? entries, String? error})>
      fetchRemoteEntriesWithDiagnostics(LeaderboardPeriod period) async {
    // Wait for Supabase initialization if it's in progress.
    // This handles the cold-start race where LeaderboardController.load()
    // runs before the post-frame SupabaseService.initialize() call in main().
    if (SupabaseService.instance.currentState == SupabaseInitState.initializing) {
      await SupabaseService.instance.ensureInitialized(
        timeout: const Duration(seconds: 4),
      );
    }

    final client = SupabaseService.instance.client;
    final supaState = SupabaseService.instance.currentState;

    if (client == null || supaState != SupabaseInitState.ready) {
      if (kDebugMode) {
        debugPrint('[LeaderboardService] Supabase not ready: state=$supaState');
      }
      return (entries: null, error: 'supabase_not_ready');
    }

    // Check authentication state
    final supabaseUser = client.auth.currentUser;
    if (supabaseUser == null) {
      if (kDebugMode) {
        debugPrint('[LeaderboardService] No authenticated Supabase session');
      }
      return (entries: null, error: 'auth_required');
    }

    final xpCol = switch (period) {
      LeaderboardPeriod.thisWeek => 'week_xp',
      LeaderboardPeriod.thisMonth => 'month_xp',
      LeaderboardPeriod.allTime => 'total_xp',
    };

    try {
      final response = await client
          .from(_tableName)
          .select('user_id, display_name, $xpCol, total_xp, level, streak, updated_at')
          .order(xpCol, ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 6));

      final remoteList = (response as List).map((json) {
        final map = json as Map<String, dynamic>;
        final uid = (map['user_id'] ?? '') as String;
        final rawPeriodXp = map[xpCol];
        final periodXp = rawPeriodXp is int
            ? rawPeriodXp
            : (period == LeaderboardPeriod.allTime ? (map['total_xp'] as int? ?? 0) : 0);

        return LeaderboardEntry(
          userId: uid,
          displayName: (map['display_name'] ?? '') as String,
          xp: periodXp,
          level: (map['level'] ?? 1) as int,
          rank: 0,
          streak: map['streak'] as int?,
          period: period,
          updatedAt: map['updated_at'] != null
              ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
              : DateTime.now(),
          isCurrentUser: uid == _userId,
        );
      }).toList();

      if (kDebugMode) {
        debugPrint('[LeaderboardService] Remote fetch succeeded: ${remoteList.length} entries');
      }
      return (entries: remoteList, error: null);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LeaderboardService] Remote fetch failed for period $period: $e');
      }
      return (entries: null, error: e.toString());
    }
  }
}
