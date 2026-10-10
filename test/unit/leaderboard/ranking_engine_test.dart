import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/ranking_engine.dart';
import 'package:student_os/data/models/leaderboard_entry.dart';
import 'package:student_os/data/models/xp_event.dart';

void main() {
  group('RankingEngine — Period XP Calculation', () {
    final baseTime = DateTime(2026, 9, 10, 12, 0); // Thursday

    final events = [
      // Event 1: Today (Thursday Sep 10, 2026)
      XpEvent(
        id: 'ev1',
        type: XpEventType.taskCompleted,
        amount: 30,
        timestamp: DateTime(2026, 9, 10, 10, 0),
        reason: 'Task 1',
      ),
      // Event 2: Earlier this week (Tuesday Sep 8, 2026)
      XpEvent(
        id: 'ev2',
        type: XpEventType.studySessionCompleted,
        amount: 50,
        timestamp: DateTime(2026, 9, 8, 15, 0),
        reason: 'Study 1',
      ),
      // Event 3: Earlier this month but previous week (Thursday Sep 3, 2026)
      XpEvent(
        id: 'ev3',
        type: XpEventType.examCompleted,
        amount: 100,
        timestamp: DateTime(2026, 9, 3, 11, 0),
        reason: 'Exam 1',
      ),
      // Event 4: Last month (August 20, 2026)
      XpEvent(
        id: 'ev4',
        type: XpEventType.taskCompleted,
        amount: 200,
        timestamp: DateTime(2026, 8, 20, 9, 0),
        reason: 'Old Task',
      ),
    ];

    test('calculatePeriodXp returns correct total for allTime', () {
      final xp = RankingEngine.calculatePeriodXp(
        events,
        LeaderboardPeriod.allTime,
        referenceTime: baseTime,
      );
      expect(xp, 30 + 50 + 100 + 200); // 380
    });

    test('calculatePeriodXp returns correct total for thisWeek', () {
      final xp = RankingEngine.calculatePeriodXp(
        events,
        LeaderboardPeriod.thisWeek,
        referenceTime: baseTime,
      );
      // Week starts Monday Sep 7, 2026. Only ev1 (Sep 10) and ev2 (Sep 8) qualify.
      expect(xp, 30 + 50); // 80
    });

    test('calculatePeriodXp returns correct total for thisMonth', () {
      final xp = RankingEngine.calculatePeriodXp(
        events,
        LeaderboardPeriod.thisMonth,
        referenceTime: baseTime,
      );
      // Month starts Sep 1, 2026. ev1 (Sep 10), ev2 (Sep 8), and ev3 (Sep 3) qualify.
      expect(xp, 30 + 50 + 100); // 180
    });

    test('calculatePeriodXp handles empty event ledger gracefully', () {
      expect(RankingEngine.calculatePeriodXp([], LeaderboardPeriod.allTime), 0);
      expect(RankingEngine.calculatePeriodXp([], LeaderboardPeriod.thisWeek), 0);
      expect(RankingEngine.calculatePeriodXp([], LeaderboardPeriod.thisMonth), 0);
    });

    test('proves thisWeek != thisMonth != allTime when events span multiple boundaries', () {
      final weekXp = RankingEngine.calculatePeriodXp(
        events,
        LeaderboardPeriod.thisWeek,
        referenceTime: baseTime,
      );
      final monthXp = RankingEngine.calculatePeriodXp(
        events,
        LeaderboardPeriod.thisMonth,
        referenceTime: baseTime,
      );
      final allTimeXp = RankingEngine.calculatePeriodXp(
        events,
        LeaderboardPeriod.allTime,
        referenceTime: baseTime,
      );

      expect(weekXp, 80);
      expect(monthXp, 180);
      expect(allTimeXp, 380);

      expect(weekXp, isNot(equals(monthXp)));
      expect(monthXp, isNot(equals(allTimeXp)));
      expect(weekXp, isNot(equals(allTimeXp)));
    });
  });

  group('RankingEngine — Deterministic Ranking & Tie Handling', () {
    test('ranks entries strictly in descending XP order', () {
      final raw = [
        LeaderboardEntry(userId: 'u1', displayName: 'Low', xp: 100, level: 1, rank: 0),
        LeaderboardEntry(userId: 'u2', displayName: 'High', xp: 500, level: 3, rank: 0),
        LeaderboardEntry(userId: 'u3', displayName: 'Mid', xp: 300, level: 2, rank: 0),
      ];

      final ranked = RankingEngine.rankEntries(raw);

      expect(ranked.length, 3);
      expect(ranked[0].userId, 'u2');
      expect(ranked[0].rank, 1);
      expect(ranked[1].userId, 'u3');
      expect(ranked[1].rank, 2);
      expect(ranked[2].userId, 'u1');
      expect(ranked[2].rank, 3);
    });

    test('breaks equal XP ties deterministically using earlier updatedAt', () {
      final early = DateTime(2026, 9, 10, 8, 0);
      final late = DateTime(2026, 9, 10, 12, 0);

      final raw = [
        LeaderboardEntry(
          userId: 'u_late',
          displayName: 'Late',
          xp: 400,
          level: 2,
          rank: 0,
          updatedAt: late,
        ),
        LeaderboardEntry(
          userId: 'u_early',
          displayName: 'Early',
          xp: 400,
          level: 2,
          rank: 0,
          updatedAt: early,
        ),
      ];

      final ranked = RankingEngine.rankEntries(raw);

      expect(ranked[0].userId, 'u_early');
      expect(ranked[0].rank, 1);
      expect(ranked[1].userId, 'u_late');
      expect(ranked[1].rank, 2);
    });

    test('breaks identical XP and identical timestamp ties with deterministic userId sort', () {
      final sameTime = DateTime(2026, 9, 10, 10, 0);

      final raw = [
        LeaderboardEntry(
          userId: 'user_z',
          displayName: 'Zack',
          xp: 500,
          level: 3,
          rank: 0,
          updatedAt: sameTime,
        ),
        LeaderboardEntry(
          userId: 'user_a',
          displayName: 'Anna',
          xp: 500,
          level: 3,
          rank: 0,
          updatedAt: sameTime,
        ),
      ];

      final ranked = RankingEngine.rankEntries(raw);

      expect(ranked[0].userId, 'user_a');
      expect(ranked[0].rank, 1);
      expect(ranked[1].userId, 'user_z');
      expect(ranked[1].rank, 2);
    });

    test('applies previous rank mappings for movement calculations', () {
      final raw = [
        LeaderboardEntry(userId: 'u1', displayName: 'Alice', xp: 1000, level: 4, rank: 0),
        LeaderboardEntry(userId: 'u2', displayName: 'Bob', xp: 500, level: 2, rank: 0),
      ];

      final prevRanks = {
        'u1': 3, // Was rank 3, now rank 1 -> moved up 2
        'u2': 1, // Was rank 1, now rank 2 -> moved down 1
      };

      final ranked = RankingEngine.rankEntries(raw, previousRanks: prevRanks);

      expect(ranked[0].userId, 'u1');
      expect(ranked[0].rank, 1);
      expect(ranked[0].previousRank, 3);
      expect(ranked[0].movement, const RankMovement.up(2));

      expect(ranked[1].userId, 'u2');
      expect(ranked[1].rank, 2);
      expect(ranked[1].previousRank, 1);
      expect(ranked[1].movement, const RankMovement.down(1));
    });

    test('deduplicates duplicate user entries safely', () {
      final raw = [
        LeaderboardEntry(userId: 'u1', displayName: 'Alice Old', xp: 200, level: 1, rank: 0),
        LeaderboardEntry(userId: 'u1', displayName: 'Alice New', xp: 500, level: 2, rank: 0),
      ];

      final ranked = RankingEngine.rankEntries(raw);
      expect(ranked.length, 1);
      expect(ranked[0].userId, 'u1');
      expect(ranked[0].xp, 500);
    });

    test('ranking is idempotent and deterministic across repeated executions', () {
      final raw = [
        LeaderboardEntry(userId: 'u3', displayName: 'Charlie', xp: 150, level: 1, rank: 0),
        LeaderboardEntry(userId: 'u1', displayName: 'Alice', xp: 800, level: 3, rank: 0),
        LeaderboardEntry(userId: 'u2', displayName: 'Bob', xp: 450, level: 2, rank: 0),
      ];

      final result1 = RankingEngine.rankEntries(raw);
      final result2 = RankingEngine.rankEntries(raw);
      final result3 = RankingEngine.rankEntries(result1);

      expect(result1, equals(result2));
      expect(result1, equals(result3));
    });
  });
}
