import 'package:meta/meta.dart';

/// Student's current level and progression state.
///
/// This is a derived value computed from total XP. The level itself is not
/// persisted separately — only the XP events are stored, and levels are
/// calculated on-demand using the level curve.
@immutable
class StudentLevel {
  const StudentLevel({
    required this.level,
    required this.currentXp,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
  });

  /// Current level (1-based).
  final int level;

  /// Total lifetime XP earned.
  final int currentXp;

  /// XP threshold required to reach this level.
  final int xpForCurrentLevel;

  /// XP threshold required to reach the next level.
  final int xpForNextLevel;

  /// XP earned within this level.
  int get xpInLevel => currentXp - xpForCurrentLevel;

  /// XP required to progress within this level.
  int get xpNeededInLevel => xpForNextLevel - xpForCurrentLevel;

  /// Progress within this level (0.0-1.0).
  double get progressInLevel {
    if (xpNeededInLevel <= 0) return 1.0;
    return (xpInLevel / xpNeededInLevel).clamp(0.0, 1.0);
  }

  /// XP remaining until next level.
  int get xpToNextLevel => (xpForNextLevel - currentXp).clamp(0, 999999999);

  /// Whether the student just leveled up (used for level-up detection).
  bool justLeveledUp(int previousXp) {
    final previousLevel = LevelCurve.levelForXp(previousXp);
    return level > previousLevel;
  }
}

/// Deterministic XP-to-level curve.
///
/// Uses a balanced exponential curve that avoids both:
/// - Extremely fast early progression followed by impossible grind
/// - Linear progression that feels unrewarding
///
/// Design philosophy:
/// - Early levels feel achievable (encourage engagement)
/// - Mid levels require consistent effort (reward daily usage)
/// - High levels represent serious commitment (prestige)
abstract final class LevelCurve {
  /// Base XP for level 1.
  static const int baseXp = 100;

  /// Growth factor for exponential curve.
  static const double growthFactor = 1.15;

  /// Maximum supported level.
  static const int maxLevel = 100;

  /// Calculates the total XP required to reach a given level.
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    if (level > maxLevel) return xpForLevel(maxLevel);

    // Exponential curve: XP = base * (growth^(level-1) - 1) / (growth - 1)
    // This creates smooth exponential growth
    final exponent = level - 1;
    final totalXp =
        (baseXp * ((_pow(growthFactor, exponent) - 1) / (growthFactor - 1)))
            .round();
    return totalXp;
  }

  /// Calculates the current level for a given total XP.
  static int levelForXp(int xp) {
    if (xp < 0) return 1;

    // Binary search for efficiency
    int low = 1;
    int high = maxLevel;

    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (xpForLevel(mid) <= xp) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }

    return low;
  }

  /// Creates a StudentLevel for the given total XP.
  static StudentLevel forXp(int xp) {
    final level = levelForXp(xp);
    return StudentLevel(
      level: level,
      currentXp: xp,
      xpForCurrentLevel: xpForLevel(level),
      xpForNextLevel: xpForLevel(level + 1),
    );
  }

  /// Helper for power calculation (handles large exponents).
  static double _pow(double base, int exponent) {
    if (exponent == 0) return 1.0;
    if (exponent == 1) return base;

    double result = 1.0;
    double current = base;
    int exp = exponent;

    while (exp > 0) {
      if (exp % 2 == 1) {
        result *= current;
      }
      current *= current;
      exp ~/= 2;
    }

    return result;
  }

  /// Descriptive label for a level range.
  static String labelForLevel(int level) {
    if (level < 5) return 'Getting Started';
    if (level < 10) return 'Focused Learner';
    if (level < 20) return 'Consistent Student';
    if (level < 35) return 'Academic Builder';
    if (level < 50) return 'Dedicated Scholar';
    if (level < 70) return 'Study Master';
    if (level < 90) return 'Academic Elite';
    return 'Student OS Legend';
  }
}
