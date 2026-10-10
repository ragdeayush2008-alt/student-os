import '../../data/models/leaderboard_entry.dart';
import '../../data/models/xp_event.dart';
import '../utils/app_week_utils.dart';

/// Deterministic ranking engine for the Student OS leaderboard.
///
/// Rules:
/// 1. Higher XP ranks higher (descending).
/// 2. Equal XP tie-breaking is deterministic:
///    - Earliest `updatedAt` wins (first to reach the milestone).
///    - Deterministic `userId` alphabetical comparison as final tie-breaker.
/// 3. Rank movement is computed strictly from real previous rankings:
///    - Up if current rank < previous rank.
///    - Down if current rank > previous rank.
///    - Same if unchanged.
///    - Neutral if no previous rank exists.
/// 4. Rank calculations never mutate original objects and produce stable outputs.
abstract final class RankingEngine {
  /// Computes the student's XP earned within the specified [period] from verified [events].
  static int calculatePeriodXp(
    List<XpEvent> events,
    LeaderboardPeriod period, {
    DateTime? referenceTime,
  }) {
    if (events.isEmpty) return 0;
    final now = referenceTime ?? DateTime.now();

    switch (period) {
      case LeaderboardPeriod.allTime:
        return events.fold<int>(0, (sum, e) => sum + e.amount);

      case LeaderboardPeriod.thisWeek:
        final startOfWeek = AppWeekUtils.startOfWeek(now);
        return events
            .where((e) => !e.timestamp.isBefore(startOfWeek))
            .fold<int>(0, (sum, e) => sum + e.amount);

      case LeaderboardPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return events
            .where((e) => !e.timestamp.isBefore(startOfMonth))
            .fold<int>(0, (sum, e) => sum + e.amount);
    }
  }

  /// Deterministically ranks a collection of entries.
  ///
  /// Removes duplicate entries by userId (keeping highest valid XP or latest update),
  /// sorts deterministically, and assigns 1-based ranks.
  static List<LeaderboardEntry> rankEntries(
    List<LeaderboardEntry> entries, {
    Map<String, int>? previousRanks,
  }) {
    if (entries.isEmpty) return const [];

    // Deduplicate by userId
    final byUser = <String, LeaderboardEntry>{};
    for (final entry in entries) {
      if (entry.userId.trim().isEmpty) continue;
      final existing = byUser[entry.userId];
      if (existing == null) {
        byUser[entry.userId] = entry;
      } else {
        // If duplicated, choose the one with higher XP or more recent update
        if (entry.xp > existing.xp ||
            (entry.xp == existing.xp && entry.updatedAt.isAfter(existing.updatedAt))) {
          byUser[entry.userId] = entry;
        }
      }
    }

    final uniqueList = byUser.values.toList();

    // Deterministic sorting
    uniqueList.sort((a, b) {
      // 1. Primary: XP descending
      final xpCompare = b.xp.compareTo(a.xp);
      if (xpCompare != 0) return xpCompare;

      // 2. Secondary tie-breaker: Earlier updatedAt ranks higher
      final timeCompare = a.updatedAt.compareTo(b.updatedAt);
      if (timeCompare != 0) return timeCompare;

      // 3. Final tie-breaker: Deterministic userId comparison
      return a.userId.compareTo(b.userId);
    });

    // Assign 1-indexed ranks and previousRank movements
    final ranked = <LeaderboardEntry>[];
    for (var i = 0; i < uniqueList.length; i++) {
      final currentRank = i + 1;
      final item = uniqueList[i];
      final prevRank = previousRanks?[item.userId] ?? item.previousRank;

      ranked.add(
        item.copyWith(
          rank: currentRank,
          previousRank: prevRank,
        ),
      );
    }

    return ranked;
  }
}
