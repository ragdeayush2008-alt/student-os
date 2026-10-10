import 'package:meta/meta.dart';

/// Type of reward that can be unlocked with XP or Level progression.
enum RewardType {
  theme('Custom Theme'),
  badge('Profile Badge'),
  feature('Premium Feature'),
  discount('Student Discount');

  const RewardType(this.label);
  final String label;
}

/// Abstract representation of a student reward.
///
/// Designed as a future-proof interface for the Rewards Marketplace (Phase 10+).
/// Does not implement real payments, external partners, or fake marketplaces.
@immutable
class StudentReward {
  const StudentReward({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.requiredLevel,
    required this.xpCost,
    this.isUnlocked = false,
    this.isRedeemed = false,
  });

  final String id;
  final String title;
  final String description;
  final RewardType type;
  final int requiredLevel;
  final int xpCost;
  final bool isUnlocked;
  final bool isRedeemed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'requiredLevel': requiredLevel,
    'xpCost': xpCost,
    'isUnlocked': isUnlocked,
    'isRedeemed': isRedeemed,
  };

  factory StudentReward.fromJson(Map<String, dynamic> json) {
    return StudentReward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: RewardType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RewardType.theme,
      ),
      requiredLevel: json['requiredLevel'] as int? ?? 1,
      xpCost: json['xpCost'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isRedeemed: json['isRedeemed'] as bool? ?? false,
    );
  }
}

/// Future-proof interface for rewards management.
///
/// This interface defines the contract that future phases will implement
/// when adding the full Rewards Marketplace and Premium Subscriptions.
abstract class RewardsCompatibility {
  /// Checks if a student is eligible for a reward based on level and XP.
  static bool isEligible({
    required StudentReward reward,
    required int currentLevel,
    required int availableXp,
  }) {
    return currentLevel >= reward.requiredLevel && availableXp >= reward.xpCost;
  }

  /// Calculates discount on premium subscription based on student level.
  ///
  /// Designed for future Premium subscription integration.
  static double calculatePremiumDiscount(int level) {
    if (level < 5) return 0.0;
    if (level < 10) return 0.05; // 5% discount
    if (level < 20) return 0.10; // 10% discount
    if (level < 50) return 0.15; // 15% discount
    return 0.20; // 20% max discount
  }
}
