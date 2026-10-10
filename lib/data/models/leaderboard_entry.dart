import 'package:meta/meta.dart';

/// Time periods for leaderboard rankings.
enum LeaderboardPeriod {
  thisWeek('This Week', 'Week'),
  thisMonth('This Month', 'Month'),
  allTime('All Time', 'All');

  const LeaderboardPeriod(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}

/// Scope of ranking (e.g. global vs. class/friends for future social extension).
enum LeaderboardScope {
  global('Global');

  const LeaderboardScope(this.label);

  final String label;
}

/// Movement direction compared to the previous ranking checkpoint.
enum RankMovementType {
  up,
  down,
  same,
  neutral;
}

/// Represents the change in rank position with accessible labels.
@immutable
class RankMovement {
  const RankMovement._({
    required this.type,
    required this.delta,
  });

  const RankMovement.up(int places)
      : this._(type: RankMovementType.up, delta: places < 0 ? -places : places);

  const RankMovement.down(int places)
      : this._(type: RankMovementType.down, delta: places < 0 ? -places : places);

  const RankMovement.same() : this._(type: RankMovementType.same, delta: 0);

  const RankMovement.neutral() : this._(type: RankMovementType.neutral, delta: 0);

  final RankMovementType type;
  final int delta;

  String get symbol => switch (type) {
    RankMovementType.up => '↑',
    RankMovementType.down => '↓',
    RankMovementType.same => '—',
    RankMovementType.neutral => '—',
  };

  String get formatted => switch (type) {
    RankMovementType.up => '↑$delta',
    RankMovementType.down => '↓$delta',
    RankMovementType.same => '—',
    RankMovementType.neutral => '—',
  };

  String get semanticLabel => switch (type) {
    RankMovementType.up => 'Moved up $delta ${delta == 1 ? "place" : "places"}',
    RankMovementType.down => 'Moved down $delta ${delta == 1 ? "place" : "places"}',
    RankMovementType.same => 'Rank unchanged',
    RankMovementType.neutral => 'No prior rank data',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankMovement &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          delta == other.delta;

  @override
  int get hashCode => Object.hash(type, delta);
}

/// A single student's entry in a leaderboard ranking.
///
/// Contains only public, non-sensitive progression information:
/// - No emails or authentication credentials
/// - No private tasks, exams, notes, or goals
/// - Purely user identity, display name, XP, level, rank, and streak.
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.xp,
    required this.level,
    required this.rank,
    this.previousRank,
    this.streak,
    this.period = LeaderboardPeriod.allTime,
    this.scope = LeaderboardScope.global,
    DateTime? updatedAt,
    this.isCurrentUser = false,
  }) : updatedAt = updatedAt ?? const _ConstDateTime();

  final String userId;
  final String displayName;
  final int xp;
  final int level;
  final int rank;
  final int? previousRank;
  final int? streak;
  final LeaderboardPeriod period;
  final LeaderboardScope scope;
  final DateTime updatedAt;
  final bool isCurrentUser;

  /// Pure derived rank movement from current [rank] and [previousRank].
  RankMovement get movement {
    final prev = previousRank;
    if (prev == null || prev <= 0) return const RankMovement.neutral();
    if (prev > rank) return RankMovement.up(prev - rank);
    if (prev < rank) return RankMovement.down(rank - prev);
    return const RankMovement.same();
  }

  /// Clean display label for the student (never blank).
  String get displayTitle {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (isCurrentUser) return 'You';
    return 'Student';
  }

  /// Single letter initials for avatar representation.
  String get initials {
    final name = displayTitle;
    if (name.isEmpty) return 'S';
    return name[0].toUpperCase();
  }

  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    int? xp,
    int? level,
    int? rank,
    int? previousRank,
    int? streak,
    LeaderboardPeriod? period,
    LeaderboardScope? scope,
    DateTime? updatedAt,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      rank: rank ?? this.rank,
      previousRank: previousRank ?? this.previousRank,
      streak: streak ?? this.streak,
      period: period ?? this.period,
      scope: scope ?? this.scope,
      updatedAt: updatedAt ?? this.updatedAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'xp': xp,
    'level': level,
    'rank': rank,
    if (previousRank != null) 'previousRank': previousRank,
    if (streak != null) 'streak': streak,
    'period': period.name,
    'scope': scope.name,
    'updatedAt': updatedAt.toIso8601String(),
    'isCurrentUser': isCurrentUser,
  };

  factory LeaderboardEntry.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final rawUserId = (json['userId'] ?? json['user_id'] ?? '') as String;
    final isCurrent = (json['isCurrentUser'] as bool?) ??
        (currentUserId != null && currentUserId.isNotEmpty && rawUserId == currentUserId);

    final rawPeriod = json['period'] as String?;
    final period = LeaderboardPeriod.values.firstWhere(
      (p) => p.name == rawPeriod,
      orElse: () => LeaderboardPeriod.allTime,
    );

    final rawScope = json['scope'] as String?;
    final scope = LeaderboardScope.values.firstWhere(
      (s) => s.name == rawScope,
      orElse: () => LeaderboardScope.global,
    );

    final rawUpdatedAt = json['updatedAt'] ?? json['updated_at'];
    final updatedAt = rawUpdatedAt is String
        ? DateTime.tryParse(rawUpdatedAt) ?? DateTime.now()
        : DateTime.now();

    return LeaderboardEntry(
      userId: rawUserId,
      displayName: (json['displayName'] ?? json['display_name'] ?? '') as String,
      xp: (json['xp'] ?? json['total_xp'] ?? 0) as int,
      level: (json['level'] ?? 1) as int,
      rank: (json['rank'] ?? 0) as int,
      previousRank: json['previousRank'] as int? ?? json['previous_rank'] as int?,
      streak: json['streak'] as int?,
      period: period,
      scope: scope,
      updatedAt: updatedAt,
      isCurrentUser: isCurrent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          xp == other.xp &&
          level == other.level &&
          rank == other.rank &&
          previousRank == other.previousRank &&
          period == other.period &&
          scope == other.scope &&
          isCurrentUser == other.isCurrentUser;

  @override
  int get hashCode => Object.hash(
    userId,
    xp,
    level,
    rank,
    previousRank,
    period,
    scope,
    isCurrentUser,
  );
}

class _ConstDateTime implements DateTime {
  const _ConstDateTime();

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  @override
  DateTime add(Duration duration) => _epoch.add(duration);

  @override
  int compareTo(DateTime other) => _epoch.compareTo(other);

  @override
  int get day => 1;

  @override
  Duration difference(DateTime other) => _epoch.difference(other);

  @override
  int get hour => 0;

  @override
  bool isAfter(DateTime other) => _epoch.isAfter(other);

  @override
  bool isAtSameMomentAs(DateTime other) => _epoch.isAtSameMomentAs(other);

  @override
  bool isBefore(DateTime other) => _epoch.isBefore(other);

  @override
  bool get isUtc => true;

  @override
  int get microsecond => 0;

  @override
  int get microsecondsSinceEpoch => 0;

  @override
  int get millisecond => 0;

  @override
  int get millisecondsSinceEpoch => 0;

  @override
  int get minute => 0;

  @override
  int get month => 1;

  @override
  int get second => 0;

  @override
  DateTime subtract(Duration duration) => _epoch.subtract(duration);

  @override
  String get timeZoneName => 'UTC';

  @override
  Duration get timeZoneOffset => Duration.zero;

  @override
  String toIso8601String() => '1970-01-01T00:00:00.000Z';

  @override
  DateTime toLocal() => _epoch.toLocal();

  @override
  DateTime toUtc() => _epoch;

  @override
  int get weekday => DateTime.thursday;

  @override
  int get year => 1970;
}
