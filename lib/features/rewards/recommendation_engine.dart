import 'package:flutter/foundation.dart';

import '../../core/intelligence/student_snapshot.dart';
import '../../core/services/course_catalog_service.dart';
import '../../data/models/reward.dart';
import '../progression/progression_controller.dart';
import 'redemption_controller.dart';
import 'reward_catalog.dart';

/// Contextual recommendation reason with human-readable explanation.
enum RecommendationReason {
  examPreparation('Prepare for upcoming exams'),
  affordableNow('Ready to unlock with your XP balance'),
  consistencyReward('Reward your daily study streak'),
  focusHabit('Enhances your deep focus sessions'),
  courseContext('Tailored for your active academic track'),
  milestoneReach('Close to unlocking this milestone'),
  starterChoice('Recommended starter unlock');

  const RecommendationReason(this.label);
  final String label;
}

/// A reward packaged with explainable AI recommendation rationale.
@immutable
class RecommendedReward {
  const RecommendedReward({
    required this.reward,
    required this.reason,
    required this.priorityScore,
    this.customExplanation,
  });

  final Reward reward;
  final RecommendationReason reason;
  final double priorityScore;
  final String? customExplanation;

  String get explanation =>
      customExplanation ?? reward.whyThisText ?? reason.label;
}

/// Recommendation engine for Rewards Marketplace 2.0.
///
/// Combines multi-dimensional student context (XP, level, active course track,
/// upcoming exams, focus habits, and existing entitlements) to provide
/// deterministic, motivating, and actionable reward recommendations.
abstract final class RecommendationEngine {
  /// Generates ranked recommendations for the student based on current live state.
  static List<RecommendedReward> getRecommendations({
    StudentSnapshot? snapshot,
    int maxRecommendations = 6,
  }) {
    final snap = snapshot ?? StudentSnapshot.fromControllers();
    final progression = ProgressionController.instance;
    final redemption = RedemptionController.instance;
    final level = progression.currentLevel.level;
    final spendableXp = progression.spendableXp;

    final catalog = RewardCatalog.instance.availableRewards;
    final recommendations = <RecommendedReward>[];
    final activeCourse = CourseCatalogService.instance.getActiveCourse();

    for (final reward in catalog) {
      if (reward.isOneTime && redemption.ownsReward(reward.id)) {
        continue;
      }

      double score = 0.0;
      RecommendationReason reason = RecommendationReason.affordableNow;
      String? customExp;

      // 1. Active course context
      if (activeCourse != null && activeCourse.isNotEmpty) {
        if (reward.category == RewardCategory.academic ||
            reward.id == 'academic_revision_pack') {
          score += 35.0;
          reason = RecommendationReason.courseContext;
          customExp = 'Recommended for your $activeCourse preparation.';
        }
      }

      // 2. Upcoming exams
      final nextExamDays = snap.nextExam?.daysUntilExam;
      if (nextExamDays != null && nextExamDays >= 0 && nextExamDays <= 14) {
        if (reward.id == 'badge_exam_master' ||
            reward.id == 'theme_exam_season' ||
            reward.id == 'academic_exam_countdown_pack' ||
            reward.id == 'theme_midnight_scholar') {
          score += 50.0;
          reason = RecommendationReason.examPreparation;
          customExp = 'Exam approaching in $nextExamDays days.';
        }
      }

      // 3. Study streak & consistency
      if (snap.currentStreak >= 3) {
        if (reward.id == 'badge_consistent_learner' ||
            reward.id == 'badge_streak_7' ||
            reward.id == 'theme_focus_dark') {
          score += 40.0;
          reason = RecommendationReason.consistencyReward;
          customExp = 'Matches your ${snap.currentStreak}-day study streak!';
        }
      }

      // 4. Focus / Study usage
      if (snap.weekStudyMinutes >= 30) {
        if (reward.category == RewardCategory.focus ||
            reward.id == 'focus_timer_minimal' ||
            reward.id == 'theme_focus_dark') {
          score += 35.0;
          reason = RecommendationReason.focusHabit;
          customExp = 'You have ${snap.weekStudyMinutes}m of study this week.';
        }
      }

      // 5. Early user starter choice
      if (level <= 2 && reward.category == RewardCategory.featured) {
        score += 45.0;
        reason = RecommendationReason.starterChoice;
      }

      // 6. Affordability factor
      final isAffordable =
          reward.minimumLevel <= level && reward.xpCost <= spendableXp;
      if (isAffordable) {
        score += 30.0;
        if (score < 35.0) {
          reason = RecommendationReason.affordableNow;
        }
      } else if (reward.minimumLevel <= level &&
          reward.xpCost <= spendableXp + 150) {
        score += 25.0;
        final xpNeeded = reward.xpCost - spendableXp;
        customExp = 'Only $xpNeeded XP away from unlocking!';
        if (score < 35.0) {
          reason = RecommendationReason.milestoneReach;
        }
      } else {
        score -= (reward.minimumLevel - level) * 5.0;
      }

      if (score > 0) {
        recommendations.add(
          RecommendedReward(
            reward: reward,
            reason: reason,
            priorityScore: score,
            customExplanation: customExp,
          ),
        );
      }
    }

    recommendations.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return recommendations.take(maxRecommendations).toList();
  }

  /// Returns rewards that the student can afford right now (level + XP eligible).
  static List<Reward> getAffordableRewards() {
    final progression = ProgressionController.instance;
    final redemption = RedemptionController.instance;
    final level = progression.currentLevel.level;
    final spendableXp = progression.spendableXp;

    return RewardCatalog.instance.availableRewards.where((r) {
      if (r.isOneTime && redemption.ownsReward(r.id)) return false;
      return r.minimumLevel <= level && r.xpCost <= spendableXp;
    }).toList();
  }
}
