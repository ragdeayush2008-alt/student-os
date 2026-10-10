import '../../data/models/reward.dart';

/// Reward pricing tiers for economic balance.
abstract final class RewardTier {
  /// Starter rewards (1-4 days of engagement).
  static const int starter = 50;
  static const int starterMax = 250;

  /// Progress rewards (5-7 days of engagement).
  static const int progress = 300;
  static const int progressMax = 600;

  /// Advanced rewards (1-2 weeks of engagement).
  static const int advanced = 700;
  static const int advancedMax = 1000;

  /// Premium rewards (2-4 weeks of engagement).
  static const int premium = 1100;
  static const int premiumMax = 2000;

  /// Elite rewards (6-8 weeks of sustained engagement).
  static const int elite = 2500;
  static const int eliteMax = 4000;
}

/// Centralized reward catalog service for Rewards Marketplace 2.0.
class RewardCatalog {
  RewardCatalog._();

  static final RewardCatalog instance = RewardCatalog._();

  /// All available collections in the marketplace.
  List<RewardCollection> get collections => _collections;

  /// All rewards in the catalog.
  List<Reward> get allRewards => _catalog;

  /// Rewards filtered by category.
  List<Reward> rewardsInCategory(RewardCategory category) {
    if (category == RewardCategory.featured) {
      return _catalog.where((r) => r.isFeatured).toList();
    }
    return _catalog.where((r) => r.category == category).toList();
  }

  /// Rewards available for redemption (not coming soon or locked system-wide).
  List<Reward> get availableRewards {
    return _catalog
        .where(
          (r) =>
              r.availability == RewardAvailability.available ||
              r.availability == RewardAvailability.limitedTime,
        )
        .toList();
  }

  /// Featured rewards for the marketplace hero section.
  List<Reward> get featuredRewards {
    return _catalog.where((r) => r.isFeatured).toList();
  }

  /// Find a reward by ID.
  Reward? findById(String id) {
    try {
      return _catalog.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Find a collection by ID.
  RewardCollection? findCollectionById(String id) {
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Rewards eligible for a student with the given level and spendable XP.
  List<Reward> eligibleRewards(int level, int spendableXp) {
    return availableRewards
        .where((r) => r.minimumLevel <= level && r.xpCost <= spendableXp)
        .toList();
  }

  /// Rewards the student is not yet eligible for (level or XP locked).
  List<Reward> lockedRewards(int level, int spendableXp) {
    return availableRewards
        .where((r) => r.minimumLevel > level || r.xpCost > spendableXp)
        .toList();
  }

  /// Returns the next reward the student can unlock (closest to affordable).
  Reward? nextUnlockableReward(int level, int spendableXp) {
    final locked = lockedRewards(level, spendableXp);
    if (locked.isEmpty) return null;

    locked.sort((a, b) {
      final aLevelGap = (a.minimumLevel - level).clamp(0, 999);
      final bLevelGap = (b.minimumLevel - level).clamp(0, 999);

      if (aLevelGap > 0 && bLevelGap > 0) {
        return aLevelGap.compareTo(bLevelGap);
      }

      if (aLevelGap == 0 && bLevelGap == 0) {
        return a.xpCost.compareTo(b.xpCost);
      }

      return aLevelGap.compareTo(bLevelGap);
    });

    return locked.first;
  }

  /// Returns rewards in a specific pricing tier.
  List<Reward> rewardsInTier({required int minXp, required int maxXp}) {
    return availableRewards
        .where((r) => r.xpCost >= minXp && r.xpCost <= maxXp)
        .toList();
  }

  /// Fast local search across title, description, category, collection, and benefits.
  List<Reward> search(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return allRewards;

    return allRewards.where((r) {
      if (r.title.toLowerCase().contains(clean)) return true;
      if (r.description.toLowerCase().contains(clean)) return true;
      if (r.subtitle?.toLowerCase().contains(clean) ?? false) return true;
      if (r.category.label.toLowerCase().contains(clean)) return true;
      if (r.benefitType.label.toLowerCase().contains(clean)) return true;
      if (r.rarity.label.toLowerCase().contains(clean)) return true;
      return false;
    }).toList();
  }

  // ─── THEMED REWARD COLLECTIONS ────────────────────────────────────────

  static final List<RewardCollection> _collections = [
    const RewardCollection(
      id: 'focus_master',
      title: 'Focus Master Collection',
      description: 'Cosmetics, styles, and presets for deep study sessions.',
      iconName: 'center_focus_strong',
      colorHex: '#285C4D',
      rewardIds: [
        'theme_focus_dark',
        'focus_timer_minimal',
        'focus_preset_deep_sprint',
        'frame_neon_focus',
      ],
      completionBadgeId: 'badge_focus_master_collector',
    ),
    const RewardCollection(
      id: 'exam_ready',
      title: 'Exam Ready Collection',
      description: 'Everything to prepare, revise, and conquer exam season.',
      iconName: 'school',
      colorHex: '#2E7D5B',
      rewardIds: [
        'badge_exam_master',
        'theme_exam_season',
        'academic_revision_pack',
        'academic_exam_countdown_pack',
      ],
      completionBadgeId: 'badge_exam_ready_collector',
    ),
    const RewardCollection(
      id: 'consistency',
      title: 'Consistency Collection',
      description: 'Celebrate daily study habits and unbroken streaks.',
      iconName: 'local_fire_department',
      colorHex: '#1F5C44',
      rewardIds: [
        'badge_first_steps',
        'badge_consistent_learner',
        'badge_streak_7',
        'badge_streak_30',
      ],
      completionBadgeId: 'badge_consistency_collector',
    ),
    const RewardCollection(
      id: 'scholar',
      title: 'Scholar Collection',
      description: 'Prestige aesthetics and academic intelligence unlocks.',
      iconName: 'workspace_premium',
      colorHex: '#4F7D68',
      rewardIds: [
        'theme_academic_light',
        'theme_midnight_scholar',
        'frame_gold_scholar',
        'feature_advanced_analytics',
        'badge_legend',
      ],
      completionBadgeId: 'badge_scholar_collector',
    ),
  ];

  // ─── MASTER REWARDS CATALOG ──────────────────────────────────────────

  static final List<Reward> _catalog = [
    // ── 1. Starter & Milestones ──
    const Reward(
      id: 'badge_first_steps',
      title: 'First Steps',
      subtitle: 'Welcome Badge',
      description: 'Welcome to Student OS! Your academic journey begins here.',
      type: 'badge',
      category: RewardCategory.featured,
      xpCost: 50,
      minimumLevel: 1,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.badge,
      rarity: RewardRarity.common,
      collectionId: 'consistency',
      isFeatured: true,
      availability: RewardAvailability.available,
      iconName: 'star',
      whyThisText: 'Great starting reward for new learners.',
      metadata: {'badgeColor': '#3B82F6'},
    ),

    const Reward(
      id: 'badge_consistent_learner',
      title: 'Consistent Learner',
      subtitle: 'Habit Milestone Badge',
      description: 'Awarded to students who maintain regular study habits and consistency.',
      type: 'badge',
      category: RewardCategory.cosmetic,
      xpCost: 200,
      minimumLevel: 5,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.badge,
      rarity: RewardRarity.rare,
      collectionId: 'consistency',
      availability: RewardAvailability.available,
      iconName: 'local_fire_department',
      whyThisText: 'Reward for building a daily study habit.',
      metadata: {'badgeColor': '#F59E0B'},
    ),

    const Reward(
      id: 'badge_exam_master',
      title: 'Exam Master',
      subtitle: 'Exam Conqueror',
      description: 'Conquer your exams with high focus, syllabus tracking, and preparation.',
      type: 'badge',
      category: RewardCategory.academic,
      xpCost: 400,
      minimumLevel: 10,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.badge,
      rarity: RewardRarity.epic,
      collectionId: 'exam_ready',
      isFeatured: true,
      availability: RewardAvailability.available,
      iconName: 'school',
      whyThisText: 'Recommended because you have upcoming exams.',
      metadata: {'badgeColor': '#10B981'},
    ),

    // ── 2. Themes ──
    const Reward(
      id: 'theme_focus_dark',
      title: 'Focus Theme',
      subtitle: 'Distraction-Free Dark Mode',
      description: 'A premium dark theme with high contrast, designed for nighttime and intense focus.',
      type: 'theme',
      category: RewardCategory.cosmetic,
      xpCost: 150,
      minimumLevel: 3,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.theme,
      rarity: RewardRarity.rare,
      collectionId: 'focus_master',
      isFeatured: true,
      availability: RewardAvailability.available,
      iconName: 'palette',
      whyThisText: 'You frequently use Focus mode.',
      metadata: {'themeId': 'focus_dark', 'primaryColor': '#1E293B'},
    ),

    const Reward(
      id: 'theme_academic_light',
      title: 'Academic Light',
      subtitle: 'Bright Command Center',
      description: 'A clean, bright theme designed for structured daytime study sessions.',
      type: 'theme',
      category: RewardCategory.cosmetic,
      xpCost: 250,
      minimumLevel: 5,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.theme,
      rarity: RewardRarity.rare,
      collectionId: 'scholar',
      availability: RewardAvailability.available,
      iconName: 'wb_sunny',
      whyThisText: 'Clean daytime aesthetic for serious study.',
      metadata: {'themeId': 'academic_light', 'primaryColor': '#F8FAFC'},
    ),

    const Reward(
      id: 'theme_midnight_scholar',
      title: 'Midnight Scholar',
      subtitle: 'Deep Navy Blue Theme',
      description: 'A deep oceanic blue palette tailored for late-night study sessions and revision.',
      type: 'theme',
      category: RewardCategory.cosmetic,
      xpCost: 350,
      minimumLevel: 8,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.theme,
      rarity: RewardRarity.rare,
      collectionId: 'scholar',
      availability: RewardAvailability.available,
      iconName: 'nights_stay',
      metadata: {'themeId': 'midnight_scholar', 'primaryColor': '#0F172A'},
    ),

    const Reward(
      id: 'theme_exam_season',
      title: 'Exam Season',
      subtitle: 'High Alert Focus Theme',
      description: 'Energetic theme with emerald accents to keep motivation peak during exam weeks.',
      type: 'theme',
      category: RewardCategory.cosmetic,
      xpCost: 350,
      minimumLevel: 7,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.theme,
      rarity: RewardRarity.rare,
      collectionId: 'exam_ready',
      availability: RewardAvailability.available,
      iconName: 'timer_outlined',
      metadata: {'themeId': 'exam_season', 'primaryColor': '#064E3B'},
    ),

    // ── 3. Academic & Feature Unlocks ──
    const Reward(
      id: 'feature_advanced_analytics',
      title: 'Advanced Analytics',
      subtitle: 'Deep Performance Insights',
      description: 'Unlocks deeper academic analytics: consistency trends, topic mastery, and subject breakdown.',
      type: 'feature',
      category: RewardCategory.academic,
      xpCost: 500,
      minimumLevel: 10,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.analytics,
      rarity: RewardRarity.epic,
      collectionId: 'scholar',
      isFeatured: true,
      availability: RewardAvailability.available,
      iconName: 'analytics',
      whyThisText: 'Unlock deeper study trend insights.',
      metadata: {'featureFlag': 'advanced_analytics'},
    ),

    const Reward(
      id: 'feature_smart_scheduling',
      title: 'Smart Scheduling',
      subtitle: 'Intelligent Planning Allocation',
      description: 'AI-assisted study block scheduling prioritizing weak areas, exam pressure, and available budget.',
      type: 'feature',
      category: RewardCategory.academic,
      xpCost: 600,
      minimumLevel: 12,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.smartScheduling,
      rarity: RewardRarity.epic,
      availability: RewardAvailability.available,
      iconName: 'auto_awesome',
      whyThisText: 'Automate smart planning distribution.',
      metadata: {'featureFlag': 'smart_scheduling'},
    ),

    const Reward(
      id: 'academic_revision_pack',
      title: 'Revision Pack',
      subtitle: 'Spaced Repetition Scheduler',
      description: 'Unlocks smart spaced repetition queues and automated review prompts for all active subjects.',
      type: 'academic',
      category: RewardCategory.academic,
      xpCost: 300,
      minimumLevel: 6,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.academic,
      rarity: RewardRarity.rare,
      collectionId: 'exam_ready',
      availability: RewardAvailability.available,
      iconName: 'history_edu',
      metadata: {'featureFlag': 'revision_pack'},
    ),

    const Reward(
      id: 'academic_exam_countdown_pack',
      title: 'Exam Countdown Pack',
      subtitle: 'Preparation Pressure Tracker',
      description: 'Enhanced exam countdown cards with syllabus completion percentage and pressure indicators.',
      type: 'academic',
      category: RewardCategory.academic,
      xpCost: 350,
      minimumLevel: 7,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.academic,
      rarity: RewardRarity.rare,
      collectionId: 'exam_ready',
      availability: RewardAvailability.available,
      iconName: 'alarm_on',
      metadata: {'featureFlag': 'exam_countdown'},
    ),

    // ── 4. Focus & Productivity ──
    const Reward(
      id: 'focus_timer_minimal',
      title: 'Minimal Focus Timer',
      subtitle: 'Clean Timer Display Style',
      description: 'Ultra-clean, uncluttered timer presentation for distractionless deep-work focus sessions.',
      type: 'focusStyle',
      category: RewardCategory.focus,
      xpCost: 150,
      minimumLevel: 3,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.focusStyle,
      rarity: RewardRarity.common,
      collectionId: 'focus_master',
      availability: RewardAvailability.available,
      iconName: 'hourglass_empty',
      metadata: {'focusStyleId': 'minimal'},
    ),

    const Reward(
      id: 'focus_preset_deep_sprint',
      title: 'Deep Sprint Preset',
      subtitle: '90-Minute Focus Configuration',
      description: 'Pre-configured 90-minute deep study sprint with structured recovery breaks.',
      type: 'preset',
      category: RewardCategory.focus,
      xpCost: 200,
      minimumLevel: 4,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.preset,
      rarity: RewardRarity.rare,
      collectionId: 'focus_master',
      availability: RewardAvailability.available,
      iconName: 'bolt',
      metadata: {'presetMinutes': 90},
    ),

    const Reward(
      id: 'frame_neon_focus',
      title: 'Neon Focus Frame',
      subtitle: 'Cosmetic Profile Border',
      description: 'Electric blue border for your student profile avatar signaling active deep focus.',
      type: 'frame',
      category: RewardCategory.cosmetic,
      xpCost: 300,
      minimumLevel: 6,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.profileFrame,
      rarity: RewardRarity.rare,
      collectionId: 'focus_master',
      availability: RewardAvailability.available,
      iconName: 'crop_square_rounded',
      metadata: {'frameColor': '#2E7D5B'},
    ),

    const Reward(
      id: 'frame_gold_scholar',
      title: 'Gold Scholar Frame',
      subtitle: 'Prestige Profile Border',
      description: 'An elegant golden frame for your student identity showcasing high academic dedication.',
      type: 'frame',
      category: RewardCategory.cosmetic,
      xpCost: 400,
      minimumLevel: 8,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.profileFrame,
      rarity: RewardRarity.epic,
      collectionId: 'scholar',
      availability: RewardAvailability.available,
      iconName: 'military_tech',
      metadata: {'frameColor': '#1F5C44'},
    ),

    // ── 5. Streak & Milestones ──
    const Reward(
      id: 'badge_streak_7',
      title: '7-Day Flame',
      subtitle: 'Week Consistency Milestone',
      description: 'Maintained an unbroken 7-day study streak. Consistency is the key to mastery.',
      type: 'badge',
      category: RewardCategory.cosmetic,
      xpCost: 100,
      minimumLevel: 2,
      requiredStreak: 7,
      unlockType: RewardUnlockType.streak,
      benefitType: RewardBenefitType.badge,
      rarity: RewardRarity.common,
      collectionId: 'consistency',
      availability: RewardAvailability.available,
      iconName: 'whatshot',
      whyThisText: 'Unlocked by achieving a 7-day streak.',
      metadata: {'badgeColor': '#EF4444'},
    ),

    const Reward(
      id: 'badge_streak_30',
      title: '30-Day Master',
      subtitle: 'Monthly Habit Milestone',
      description: 'Unbroken 30-day streak of academic discipline and daily progress.',
      type: 'badge',
      category: RewardCategory.cosmetic,
      xpCost: 500,
      minimumLevel: 10,
      requiredStreak: 30,
      unlockType: RewardUnlockType.streak,
      benefitType: RewardBenefitType.badge,
      rarity: RewardRarity.epic,
      collectionId: 'consistency',
      availability: RewardAvailability.available,
      iconName: 'auto_awesome',
      metadata: {'badgeColor': '#8B5CF6'},
    ),

    // ── 6. Premium Tier ──
    const Reward(
      id: 'discount_premium_trial',
      title: 'Premium Trial',
      subtitle: '7-Day Full Premium Access',
      description: 'Activate a 7-day trial of Student OS Premium with complete feature access.',
      type: 'discount',
      category: RewardCategory.premium,
      xpCost: 800,
      minimumLevel: 15,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.premiumTrial,
      rarity: RewardRarity.epic,
      isOneTime: true,
      availability: RewardAvailability.available,
      iconName: 'workspace_premium',
      metadata: {'trialDays': 7},
    ),

    const Reward(
      id: 'discount_premium_monthly',
      title: 'Premium Discount',
      subtitle: '20% Off Premium Coupon',
      description: 'Redeem a 20% entitlement discount applied toward your Student OS Premium membership.',
      type: 'discount',
      category: RewardCategory.premium,
      xpCost: 1000,
      minimumLevel: 20,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.discount,
      rarity: RewardRarity.epic,
      isOneTime: true,
      availability: RewardAvailability.available,
      iconName: 'discount',
      metadata: {'discountPercent': 20, 'durationMonths': 1},
    ),

    // ── 7. Peak Legend ──
    const Reward(
      id: 'badge_legend',
      title: 'Student OS Legend',
      subtitle: 'Peak Academic Excellence',
      description: 'The ultimate achievement: you have mastered Student OS and reached the summit of academic excellence.',
      type: 'badge',
      category: RewardCategory.feature,
      xpCost: 3500,
      minimumLevel: 50,
      unlockType: RewardUnlockType.xp,
      benefitType: RewardBenefitType.badge,
      rarity: RewardRarity.legendary,
      collectionId: 'scholar',
      isFeatured: true,
      availability: RewardAvailability.available,
      iconName: 'emoji_events',
      whyThisText: 'Ultimate milestone for elite students.',
      metadata: {'badgeColor': '#FFD700', 'isLegendary': true},
    ),
  ];
}
