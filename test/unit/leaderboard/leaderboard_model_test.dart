import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry & RankMovement Models', () {
    test('RankMovement computes correct symbol, formatted string, and semantics', () {
      const up = RankMovement.up(3);
      expect(up.type, RankMovementType.up);
      expect(up.delta, 3);
      expect(up.symbol, '↑');
      expect(up.formatted, '↑3');
      expect(up.semanticLabel, 'Moved up 3 places');

      const down = RankMovement.down(2);
      expect(down.type, RankMovementType.down);
      expect(down.delta, 2);
      expect(down.symbol, '↓');
      expect(down.formatted, '↓2');
      expect(down.semanticLabel, 'Moved down 2 places');

      const same = RankMovement.same();
      expect(same.type, RankMovementType.same);
      expect(same.delta, 0);
      expect(same.symbol, '—');
      expect(same.formatted, '—');
      expect(same.semanticLabel, 'Rank unchanged');

      const neutral = RankMovement.neutral();
      expect(neutral.type, RankMovementType.neutral);
      expect(neutral.delta, 0);
      expect(neutral.symbol, '—');
      expect(neutral.formatted, '—');
      expect(neutral.semanticLabel, 'No prior rank data');
    });

    test('LeaderboardEntry movement is derived accurately from rank and previousRank', () {
      // Moved up: previous rank was 5, now rank is 2 -> moved up 3
      final entryUp = LeaderboardEntry(
        userId: 'u1',
        displayName: 'Alice',
        xp: 1500,
        level: 4,
        rank: 2,
        previousRank: 5,
      );
      expect(entryUp.movement, const RankMovement.up(3));

      // Moved down: previous rank was 2, now rank is 4 -> moved down 2
      final entryDown = LeaderboardEntry(
        userId: 'u2',
        displayName: 'Bob',
        xp: 1000,
        level: 3,
        rank: 4,
        previousRank: 2,
      );
      expect(entryDown.movement, const RankMovement.down(2));

      // Unchanged: previous rank was 3, current rank is 3
      final entrySame = LeaderboardEntry(
        userId: 'u3',
        displayName: 'Charlie',
        xp: 1200,
        level: 3,
        rank: 3,
        previousRank: 3,
      );
      expect(entrySame.movement, const RankMovement.same());

      // Neutral: no previous rank (new participant)
      final entryNeutral = LeaderboardEntry(
        userId: 'u4',
        displayName: 'David',
        xp: 800,
        level: 2,
        rank: 5,
      );
      expect(entryNeutral.movement, const RankMovement.neutral());
    });

    test('LeaderboardEntry displayTitle and initials handle fallback', () {
      final namedEntry = LeaderboardEntry(
        userId: 'u1',
        displayName: 'Sophia Loren',
        xp: 500,
        level: 2,
        rank: 1,
      );
      expect(namedEntry.displayTitle, 'Sophia Loren');
      expect(namedEntry.initials, 'S');

      final currentUserBlank = LeaderboardEntry(
        userId: 'u2',
        displayName: '',
        xp: 500,
        level: 2,
        rank: 1,
        isCurrentUser: true,
      );
      expect(currentUserBlank.displayTitle, 'You');
      expect(currentUserBlank.initials, 'Y');

      final genericBlank = LeaderboardEntry(
        userId: 'u3',
        displayName: '  ',
        xp: 500,
        level: 2,
        rank: 2,
        isCurrentUser: false,
      );
      expect(genericBlank.displayTitle, 'Student');
      expect(genericBlank.initials, 'S');
    });

    test('LeaderboardEntry serialization and deserialization roundtrip', () {
      final original = LeaderboardEntry(
        userId: 'student_123',
        displayName: 'Jane Doe',
        xp: 2450,
        level: 5,
        rank: 3,
        previousRank: 4,
        streak: 7,
        period: LeaderboardPeriod.thisWeek,
        scope: LeaderboardScope.global,
        updatedAt: DateTime(2026, 9, 10, 14, 30),
        isCurrentUser: true,
      );

      final json = original.toJson();
      final restored = LeaderboardEntry.fromJson(json, currentUserId: 'student_123');

      expect(restored.userId, original.userId);
      expect(restored.displayName, original.displayName);
      expect(restored.xp, original.xp);
      expect(restored.level, original.level);
      expect(restored.rank, original.rank);
      expect(restored.previousRank, original.previousRank);
      expect(restored.streak, original.streak);
      expect(restored.period, original.period);
      expect(restored.scope, original.scope);
      expect(restored.isCurrentUser, isTrue);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored, equals(original));
    });

    test('LeaderboardEntry handles legacy and missing JSON fields safely', () {
      final json = <String, dynamic>{
        'user_id': 'legacy_user',
        'display_name': 'Legacy Name',
        'total_xp': 900,
        'level': 3,
      };

      final entry = LeaderboardEntry.fromJson(json, currentUserId: 'other_user');
      expect(entry.userId, 'legacy_user');
      expect(entry.displayName, 'Legacy Name');
      expect(entry.xp, 900);
      expect(entry.level, 3);
      expect(entry.rank, 0);
      expect(entry.previousRank, isNull);
      expect(entry.period, LeaderboardPeriod.allTime);
      expect(entry.isCurrentUser, isFalse);
    });
  });
}
