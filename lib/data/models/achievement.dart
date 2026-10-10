import 'package:flutter/material.dart';

/// Categories of achievements grouped by activity domain.
enum AchievementCategory {
  all('All', Icons.grid_view_rounded),
  academic('Academic', Icons.school_rounded),
  focus('Focus', Icons.center_focus_strong_rounded),
  consistency('Consistency', Icons.local_fire_department_rounded),
  progression('Progression', Icons.trending_up_rounded),
  goals('Goals', Icons.flag_rounded),
  exploration('Exploration', Icons.explore_rounded);

  // Backwards compatibility aliases
  static const tasks = academic;
  static const study = academic;
  static const exams = academic;
  static const streak = consistency;

  const AchievementCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// A single immutable definition of an achievement in Student OS.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
    required this.condition,
    this.targetValue = 1,
    this.unit = '',
    this.xpReward = 0,
  });

  /// Unique identifier (e.g. 'first_task', 'streak_7').
  final String id;

  /// Display title.
  final String title;

  /// Explanatory description.
  final String description;

  /// Material icon name for rendering.
  final String iconName;

  /// Category grouping.
  final AchievementCategory category;

  /// Human-readable condition required to unlock.
  final String condition;

  /// Numeric threshold for completion.
  final int targetValue;

  /// Unit label (e.g. 'tasks', 'sessions', 'days', 'mins', 'XP', 'Level').
  final String unit;

  /// XP bonus awarded upon first unlock.
  final int xpReward;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconName': iconName,
    'category': category.name,
    'condition': condition,
    'targetValue': targetValue,
    'unit': unit,
    'xpReward': xpReward,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final catName = json['category'] as String?;
    final cat = AchievementCategory.values.firstWhere(
      (c) => c.name == catName,
      orElse: () => AchievementCategory.academic,
    );

    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String,
      category: cat,
      condition: json['condition'] as String? ?? '',
      targetValue: (json['targetValue'] as int?) ?? 1,
      unit: (json['unit'] as String?) ?? '',
      xpReward: (json['xpReward'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Live presentation state of an achievement combining definition with user progress.
@immutable
class AchievementEntry {
  const AchievementEntry({
    required this.achievement,
    required this.isUnlocked,
    required this.currentProgress,
    this.unlockedAt,
  });

  final Achievement achievement;
  final bool isUnlocked;
  final int currentProgress;
  final DateTime? unlockedAt;

  /// Backwards-compatible alias for [isUnlocked].
  bool get earned => isUnlocked;

  /// Progress clamped between 0.0 and 1.0.
  double get progressFraction {
    if (achievement.targetValue <= 0) return isUnlocked ? 1.0 : 0.0;
    if (isUnlocked) return 1.0;
    return (currentProgress / achievement.targetValue).clamp(0.0, 1.0);
  }

  /// True progress display string, e.g. "8 / 10 tasks".
  String get progressSummary {
    if (isUnlocked) {
      return 'Unlocked';
    }
    final target = achievement.targetValue;
    final unit = achievement.unit;
    final curr = currentProgress.clamp(0, target);
    return '$curr / $target $unit'.trim();
  }

  /// Actionable instruction for locked achievements.
  String get actionNeeded {
    if (isUnlocked) return 'Earned on ${_formatDate(unlockedAt)}';
    final remaining = (achievement.targetValue - currentProgress).clamp(1, achievement.targetValue);
    final unit = achievement.unit;
    return 'Complete $remaining more $unit to unlock.';
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return 'completed';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  AchievementEntry copyWith({
    Achievement? achievement,
    bool? isUnlocked,
    int? currentProgress,
    DateTime? unlockedAt,
  }) {
    return AchievementEntry(
      achievement: achievement ?? this.achievement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// The authoritative static catalog of achievements.
abstract final class AchievementCatalog {
  static const achievements = <Achievement>[
    // ─── Academic ──────────────────────────────────────────────────────────
    Achievement(
      id: 'first_task',
      title: 'First Steps',
      description: 'Complete your first task',
      iconName: 'check_circle',
      category: AchievementCategory.academic,
      condition: 'Complete 1 task',
      targetValue: 1,
      unit: 'task',
      xpReward: 10,
    ),
    Achievement(
      id: 'tasks_10',
      title: 'Getting Things Done',
      description: 'Complete 10 tasks',
      iconName: 'task_alt',
      category: AchievementCategory.academic,
      condition: 'Complete 10 tasks',
      targetValue: 10,
      unit: 'tasks',
      xpReward: 25,
    ),
    Achievement(
      id: 'tasks_50',
      title: 'Task Master',
      description: 'Complete 50 tasks',
      iconName: 'assignment_turned_in',
      category: AchievementCategory.academic,
      condition: 'Complete 50 tasks',
      targetValue: 50,
      unit: 'tasks',
      xpReward: 50,
    ),
    Achievement(
      id: 'first_study',
      title: 'Bookworm',
      description: 'Complete your first study session',
      iconName: 'menu_book',
      category: AchievementCategory.academic,
      condition: 'Complete 1 study session',
      targetValue: 1,
      unit: 'session',
      xpReward: 15,
    ),
    Achievement(
      id: 'study_10',
      title: 'Deep Learner',
      description: 'Complete 10 study sessions',
      iconName: 'school',
      category: AchievementCategory.academic,
      condition: 'Complete 10 study sessions',
      targetValue: 10,
      unit: 'sessions',
      xpReward: 30,
    ),
    Achievement(
      id: 'study_50',
      title: 'Dedicated Scholar',
      description: 'Complete 50 study sessions',
      iconName: 'school',
      category: AchievementCategory.academic,
      condition: 'Complete 50 study sessions',
      targetValue: 50,
      unit: 'sessions',
      xpReward: 75,
    ),
    Achievement(
      id: 'first_exam',
      title: 'Exam Ready',
      description: 'Complete your first exam',
      iconName: 'emoji_events',
      category: AchievementCategory.academic,
      condition: 'Complete 1 exam',
      targetValue: 1,
      unit: 'exam',
      xpReward: 50,
    ),

    // ─── Focus ─────────────────────────────────────────────────────────────
    Achievement(
      id: 'first_focus',
      title: 'Deep Focus',
      description: 'Complete your first focus session',
      iconName: 'center_focus_strong',
      category: AchievementCategory.focus,
      condition: 'Complete 1 focus session',
      targetValue: 1,
      unit: 'session',
      xpReward: 15,
    ),
    Achievement(
      id: 'focus_10',
      title: 'Focused Mind',
      description: 'Complete 10 focus sessions',
      iconName: 'psychology',
      category: AchievementCategory.focus,
      condition: 'Complete 10 focus sessions',
      targetValue: 10,
      unit: 'sessions',
      xpReward: 30,
    ),
    Achievement(
      id: 'focus_50',
      title: 'Focus Master',
      description: 'Complete 50 focus sessions',
      iconName: 'self_improvement',
      category: AchievementCategory.focus,
      condition: 'Complete 50 focus sessions',
      targetValue: 50,
      unit: 'sessions',
      xpReward: 75,
    ),
    Achievement(
      id: 'focus_60_mins',
      title: 'Power Hour',
      description: 'Accumulate 60 minutes of total focus time',
      iconName: 'timer',
      category: AchievementCategory.focus,
      condition: 'Log 60 minutes of focus',
      targetValue: 60,
      unit: 'mins',
      xpReward: 20,
    ),

    // ─── Consistency ───────────────────────────────────────────────────────
    Achievement(
      id: 'streak_3',
      title: 'Momentum',
      description: 'Maintain a 3-day activity streak',
      iconName: 'local_fire_department',
      category: AchievementCategory.consistency,
      condition: '3-day streak',
      targetValue: 3,
      unit: 'days',
      xpReward: 20,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintain a 7-day activity streak',
      iconName: 'whatshot',
      category: AchievementCategory.consistency,
      condition: '7-day streak',
      targetValue: 7,
      unit: 'days',
      xpReward: 40,
    ),
    Achievement(
      id: 'streak_14',
      title: 'Unstoppable',
      description: 'Maintain a 14-day activity streak',
      iconName: 'bolt',
      category: AchievementCategory.consistency,
      condition: '14-day streak',
      targetValue: 14,
      unit: 'days',
      xpReward: 60,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Iron Will',
      description: 'Maintain a 30-day activity streak',
      iconName: 'shield',
      category: AchievementCategory.consistency,
      condition: '30-day streak',
      targetValue: 30,
      unit: 'days',
      xpReward: 100,
    ),

    // ─── Progression ───────────────────────────────────────────────────────
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach Level 5 in Student OS',
      iconName: 'star',
      category: AchievementCategory.progression,
      condition: 'Reach Level 5',
      targetValue: 5,
      unit: 'Level',
      xpReward: 50,
    ),
    Achievement(
      id: 'level_10',
      title: 'Level 10 Achieved',
      description: 'Reach Level 10 in Student OS',
      iconName: 'stars',
      category: AchievementCategory.progression,
      condition: 'Reach Level 10',
      targetValue: 10,
      unit: 'Level',
      xpReward: 100,
    ),
    Achievement(
      id: 'level_25',
      title: 'Quarter Century',
      description: 'Reach Level 25 in Student OS',
      iconName: 'military_tech',
      category: AchievementCategory.progression,
      condition: 'Reach Level 25',
      targetValue: 25,
      unit: 'Level',
      xpReward: 250,
    ),
    Achievement(
      id: 'xp_1000',
      title: 'Millennium Scholar',
      description: 'Accumulate 1,000 lifetime XP',
      iconName: 'auto_awesome',
      category: AchievementCategory.progression,
      condition: 'Earn 1,000 total XP',
      targetValue: 1000,
      unit: 'XP',
      xpReward: 50,
    ),

    // ─── Goals ─────────────────────────────────────────────────────────────
    Achievement(
      id: 'daily_task_goal',
      title: 'Goal Crusher',
      description: 'Meet your daily task target',
      iconName: 'flag',
      category: AchievementCategory.goals,
      condition: 'Complete daily task target',
      targetValue: 1,
      unit: 'goal',
      xpReward: 20,
    ),

    // ─── Exploration ───────────────────────────────────────────────────────
    Achievement(
      id: 'first_subject',
      title: 'Course Architect',
      description: 'Create your first academic subject',
      iconName: 'folder',
      category: AchievementCategory.exploration,
      condition: 'Create 1 subject',
      targetValue: 1,
      unit: 'subject',
      xpReward: 10,
    ),
    Achievement(
      id: 'first_resource',
      title: 'Resource Curator',
      description: 'Save your first study note or resource',
      iconName: 'library_books',
      category: AchievementCategory.exploration,
      condition: 'Add 1 resource',
      targetValue: 1,
      unit: 'resource',
      xpReward: 10,
    ),
  ];

  static Achievement? findById(String id) {
    for (final a in achievements) {
      if (a.id == id) return a;
    }
    return null;
  }
}
