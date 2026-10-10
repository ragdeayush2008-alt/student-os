import 'package:flutter/material.dart';

/// Category of reward for marketplace organization.
enum RewardCategory {
  featured('Featured'),
  forYou('For You'),
  cosmetic('Cosmetics'),
  academic('Academic'),
  focus('Focus & Productivity'),
  premium('Premium'),
  feature('Features');

  const RewardCategory(this.label);
  final String label;

  static RewardCategory fromString(String? val) {
    if (val == null) return RewardCategory.cosmetic;
    for (final c in RewardCategory.values) {
      if (c.name.toLowerCase() == val.toLowerCase()) return c;
    }
    return RewardCategory.cosmetic;
  }
}

/// Availability status of a reward.
enum RewardAvailability {
  available('Available'),
  locked('Locked'),
  comingSoon('Coming Soon'),
  limitedTime('Limited Time');

  const RewardAvailability(this.label);
  final String label;

  static RewardAvailability fromString(String? val) {
    if (val == null) return RewardAvailability.available;
    for (final a in RewardAvailability.values) {
      if (a.name.toLowerCase() == val.toLowerCase()) return a;
    }
    return RewardAvailability.available;
  }
}

/// Rarity tier for marketplace rewards (cosmetic distinction only).
///
/// Tonal emerald luminosity ladder — no blue/purple/gold. Higher tiers read
/// as deeper, more luminous greens; labels + glow carry the distinction.
enum RewardRarity {
  common('Common', Color(0xFF8B9A91)),
  rare('Rare', Color(0xFF4F7D68)),
  epic('Epic', Color(0xFF285C4D)),
  legendary('Legendary', Color(0xFF1F5C44));

  const RewardRarity(this.label, this.color);
  final String label;
  final Color color;

  static RewardRarity fromString(String? val) {
    if (val == null) return RewardRarity.common;
    for (final r in RewardRarity.values) {
      if (r.name.toLowerCase() == val.toLowerCase()) return r;
    }
    return RewardRarity.common;
  }
}

/// Method or prerequisite required to unlock the reward.
enum RewardUnlockType {
  xp('XP'),
  level('Level'),
  streak('Streak'),
  achievement('Achievement'),
  milestone('Milestone'),
  premium('Premium'),
  special('Special');

  const RewardUnlockType(this.label);
  final String label;

  static RewardUnlockType fromString(String? val) {
    if (val == null) return RewardUnlockType.xp;
    for (final u in RewardUnlockType.values) {
      if (u.name.toLowerCase() == val.toLowerCase()) return u;
    }
    return RewardUnlockType.xp;
  }
}

/// Type of utility or cosmetic benefit granted upon redemption.
enum RewardBenefitType {
  theme('Theme'),
  badge('Badge'),
  profileFrame('Profile Frame'),
  focusStyle('Focus Style'),
  academic('Academic Utility'),
  analytics('Advanced Analytics'),
  smartScheduling('Smart Scheduling'),
  template('Study Template'),
  preset('Focus Preset'),
  premiumTrial('Premium Trial'),
  discount('Premium Discount'),
  feature('Feature Unlock');

  const RewardBenefitType(this.label);
  final String label;

  static RewardBenefitType fromString(String? val) {
    if (val == null) return RewardBenefitType.theme;
    for (final b in RewardBenefitType.values) {
      if (b.name.toLowerCase() == val.toLowerCase()) return b;
    }
    return RewardBenefitType.theme;
  }
}

/// Complete reward model for Student OS Rewards Marketplace 2.0.
@immutable
class Reward {
  const Reward({
    required this.id,
    required this.title,
    this.subtitle,
    required this.description,
    required this.type,
    required this.category,
    required this.xpCost,
    this.minimumLevel = 1,
    this.requiredStreak,
    this.requiredAchievementId,
    this.requiredMetric,
    this.unlockType = RewardUnlockType.xp,
    this.benefitType = RewardBenefitType.theme,
    this.rarity = RewardRarity.common,
    this.collectionId,
    this.isFeatured = false,
    this.availability = RewardAvailability.available,
    this.iconName,
    this.isOneTime = true,
    this.sortOrder = 0,
    this.expiresAt,
    this.previewData,
    this.whyThisText,
    this.metadata,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String description;
  final String type; // 'theme', 'badge', 'feature', 'discount', 'frame', 'preset'
  final RewardCategory category;
  final int xpCost;
  final int minimumLevel;
  final int? requiredStreak;
  final String? requiredAchievementId;
  final String? requiredMetric;
  final RewardUnlockType unlockType;
  final RewardBenefitType benefitType;
  final RewardRarity rarity;
  final String? collectionId;
  final bool isFeatured;
  final RewardAvailability availability;
  final String? iconName;
  final bool isOneTime;
  final int sortOrder;
  final DateTime? expiresAt;
  final Map<String, dynamic>? previewData;
  final String? whyThisText;
  final Map<String, dynamic>? metadata;

  /// Whether this reward can be redeemed (available and not coming soon).
  bool get isRedeemable =>
      availability == RewardAvailability.available ||
      availability == RewardAvailability.limitedTime;

  bool get isEquippable =>
      type == 'theme' ||
      type == 'badge' ||
      type == 'frame' ||
      type == 'focusStyle';

  String get equipmentSlot {
    return switch (type) {
      'theme' => 'theme',
      'frame' => 'profileFrame',
      'focusStyle' => 'focusStyle',
      _ => 'badge',
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'description': description,
    'type': type,
    'category': category.name,
    'xpCost': xpCost,
    'minimumLevel': minimumLevel,
    if (requiredStreak != null) 'requiredStreak': requiredStreak,
    if (requiredAchievementId != null)
      'requiredAchievementId': requiredAchievementId,
    if (requiredMetric != null) 'requiredMetric': requiredMetric,
    'unlockType': unlockType.name,
    'benefitType': benefitType.name,
    'rarity': rarity.name,
    if (collectionId != null) 'collectionId': collectionId,
    'isFeatured': isFeatured,
    'availability': availability.name,
    if (iconName != null) 'iconName': iconName,
    'isOneTime': isOneTime,
    'sortOrder': sortOrder,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (previewData != null) 'previewData': previewData,
    if (whyThisText != null) 'whyThisText': whyThisText,
    if (metadata != null) 'metadata': metadata,
  };

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'theme',
      category: RewardCategory.fromString(json['category'] as String?),
      xpCost: json['xpCost'] as int? ?? 0,
      minimumLevel: json['minimumLevel'] as int? ?? 1,
      requiredStreak: json['requiredStreak'] as int?,
      requiredAchievementId: json['requiredAchievementId'] as String?,
      requiredMetric: json['requiredMetric'] as String?,
      unlockType: RewardUnlockType.fromString(json['unlockType'] as String?),
      benefitType:
          RewardBenefitType.fromString(json['benefitType'] as String?),
      rarity: RewardRarity.fromString(json['rarity'] as String?),
      collectionId: json['collectionId'] as String?,
      isFeatured: (json['isFeatured'] as bool?) ?? false,
      availability:
          RewardAvailability.fromString(json['availability'] as String?),
      iconName: json['iconName'] as String?,
      isOneTime: (json['isOneTime'] as bool?) ?? true,
      sortOrder: (json['sortOrder'] as int?) ?? 0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      previewData: json['previewData'] != null
          ? Map<String, dynamic>.from(json['previewData'] as Map)
          : null,
      whyThisText: json['whyThisText'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Reward copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? type,
    RewardCategory? category,
    int? xpCost,
    int? minimumLevel,
    int? requiredStreak,
    String? requiredAchievementId,
    String? requiredMetric,
    RewardUnlockType? unlockType,
    RewardBenefitType? benefitType,
    RewardRarity? rarity,
    String? collectionId,
    bool? isFeatured,
    RewardAvailability? availability,
    String? iconName,
    bool? isOneTime,
    int? sortOrder,
    DateTime? expiresAt,
    Map<String, dynamic>? previewData,
    String? whyThisText,
    Map<String, dynamic>? metadata,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      xpCost: xpCost ?? this.xpCost,
      minimumLevel: minimumLevel ?? this.minimumLevel,
      requiredStreak: requiredStreak ?? this.requiredStreak,
      requiredAchievementId:
          requiredAchievementId ?? this.requiredAchievementId,
      requiredMetric: requiredMetric ?? this.requiredMetric,
      unlockType: unlockType ?? this.unlockType,
      benefitType: benefitType ?? this.benefitType,
      rarity: rarity ?? this.rarity,
      collectionId: collectionId ?? this.collectionId,
      isFeatured: isFeatured ?? this.isFeatured,
      availability: availability ?? this.availability,
      iconName: iconName ?? this.iconName,
      isOneTime: isOneTime ?? this.isOneTime,
      sortOrder: sortOrder ?? this.sortOrder,
      expiresAt: expiresAt ?? this.expiresAt,
      previewData: previewData ?? this.previewData,
      whyThisText: whyThisText ?? this.whyThisText,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reward && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Themed Reward Collection grouping for long-term student progression.
@immutable
class RewardCollection {
  const RewardCollection({
    required this.id,
    required this.title,
    required this.description,
    this.iconName,
    required this.rewardIds,
    this.completionBadgeId,
    this.colorHex = '#285C4D',
  });

  final String id;
  final String title;
  final String description;
  final String? iconName;
  final List<String> rewardIds;
  final String? completionBadgeId;
  final String colorHex;

  int get totalItems => rewardIds.length;

  int unlockedCount(Set<String> ownedRewardIds) =>
      rewardIds.where((id) => ownedRewardIds.contains(id)).length;

  double progress(Set<String> ownedRewardIds) {
    if (rewardIds.isEmpty) return 0.0;
    return (unlockedCount(ownedRewardIds) / totalItems).clamp(0.0, 1.0);
  }

  bool isComplete(Set<String> ownedRewardIds) =>
      rewardIds.isNotEmpty &&
      rewardIds.every((id) => ownedRewardIds.contains(id));
}
