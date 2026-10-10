import 'package:flutter/material.dart';

/// Availability of a Premium catalog feature.
///
/// ACTIVE features exist behind a working gate. COMING_SOON features are
/// announced but not yet built — they never grant access and never redirect
/// as if they were available.
enum PremiumFeatureStatus {
  active('Active'),
  comingSoon('Coming soon'),
  unavailable('Unavailable');

  const PremiumFeatureStatus(this.label);
  final String label;
}

/// Catalog sections for the benefits page.
enum PremiumFeatureCategory {
  assistant('Assistant'),
  focus('Focus'),
  planning('Planning'),
  academic('Academic'),
  insights('Insights'),
  sleep('Sleep'),
  personalization('Personalization');

  const PremiumFeatureCategory(this.label);
  final String label;
}

/// One Premium capability. IDs are stable internal identifiers — never
/// provider product IDs (see [PremiumPlan.providerMappings]).
@immutable
class PremiumFeature {
  const PremiumFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final PremiumFeatureCategory category;
  final PremiumFeatureStatus status;
}

/// Master Premium feature catalog: the single source of truth for feature
/// IDs, display copy, and availability. UI renders from this — never from
/// scattered literals.
abstract final class PremiumCatalog {
  static const List<PremiumFeature> features = [
    PremiumFeature(
      id: 'premium.assistant.advanced',
      title: 'Advanced Assistant',
      description:
          'Proactive preparation, attention triggers, and advanced actions across your day.',
      icon: Icons.auto_awesome_rounded,
      category: PremiumFeatureCategory.assistant,
      status: PremiumFeatureStatus.active,
    ),
    PremiumFeature(
      id: 'premium.focus.deep',
      title: 'Deep Focus',
      description:
          'Stronger session commitment with deep distraction protection and deliberate exits.',
      icon: Icons.center_focus_strong_rounded,
      category: PremiumFeatureCategory.focus,
      status: PremiumFeatureStatus.active,
    ),
    PremiumFeature(
      id: 'premium.focus.strict',
      title: 'Strict Focus',
      description:
          'Commitment-first focus with limited navigation and an intentional exit flow.',
      icon: Icons.shield_rounded,
      category: PremiumFeatureCategory.focus,
      status: PremiumFeatureStatus.active,
    ),
    PremiumFeature(
      id: 'premium.planning.smart',
      title: 'Smart Planning',
      description:
          'Priority-, deadline-, and exam-aware day plans with automatic overload fixes.',
      icon: Icons.calendar_today_rounded,
      category: PremiumFeatureCategory.planning,
      status: PremiumFeatureStatus.active,
    ),
    PremiumFeature(
      id: 'premium.planning.weekly',
      title: 'Advanced Weekly Planning',
      description: 'Week-level workload shaping beyond the day view.',
      icon: Icons.date_range_rounded,
      category: PremiumFeatureCategory.planning,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.planning.scenario',
      title: 'Scenario Planning',
      description: 'Compare alternate plans before committing.',
      icon: Icons.compare_arrows_rounded,
      category: PremiumFeatureCategory.planning,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.exam.intelligence',
      title: 'Exam Intelligence',
      description:
          'Phased preparation plans built from your real exams, subjects, and topics.',
      icon: Icons.school_rounded,
      category: PremiumFeatureCategory.academic,
      status: PremiumFeatureStatus.active,
    ),
    PremiumFeature(
      id: 'premium.study.intelligence',
      title: 'Advanced Study Intelligence',
      description: 'Smarter study recommendations from your activity.',
      icon: Icons.menu_book_rounded,
      category: PremiumFeatureCategory.academic,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.revision.intelligence',
      title: 'Advanced Revision Intelligence',
      description: 'Deeper revision scheduling and retention insight.',
      icon: Icons.refresh_rounded,
      category: PremiumFeatureCategory.academic,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.catchup',
      title: 'Catch-Up Engine',
      description:
          'Backlog triage that spreads unfinished work realistically.',
      icon: Icons.trending_up_rounded,
      category: PremiumFeatureCategory.planning,
      status: PremiumFeatureStatus.active,
    ),
    PremiumFeature(
      id: 'premium.analytics.advanced',
      title: 'Advanced Analytics',
      description:
          'Study, focus, and planning patterns beyond basic progress.',
      icon: Icons.insights_rounded,
      category: PremiumFeatureCategory.insights,
      status: PremiumFeatureStatus.active,
    ),
    PremiumFeature(
      id: 'premium.assistant.proactive',
      title: 'Proactive Assistant',
      description:
          'Morning preparation, attention triggers, and evening review — automatically.',
      icon: Icons.notifications_active_rounded,
      category: PremiumFeatureCategory.assistant,
      status: PremiumFeatureStatus.active,
    ),
    PremiumFeature(
      id: 'premium.sleep.awareness',
      title: 'Sleep-Aware Planning',
      description:
          'Plans that protect your sleep window and adapt around it.',
      icon: Icons.bedtime_rounded,
      category: PremiumFeatureCategory.sleep,
      status: PremiumFeatureStatus.active,
    ),
    PremiumFeature(
      id: 'premium.study.ai_tools',
      title: 'AI Study Tools',
      description: 'Applied study tools where actually implemented.',
      icon: Icons.psychology_rounded,
      category: PremiumFeatureCategory.academic,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.notes.intelligence',
      title: 'Intelligent Notes',
      description: 'Smarter resource features where actually implemented.',
      icon: Icons.note_alt_rounded,
      category: PremiumFeatureCategory.insights,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.dashboard.customization',
      title: 'Home Customization',
      description: 'Arrange the Home command center your way.',
      icon: Icons.dashboard_customize_rounded,
      category: PremiumFeatureCategory.personalization,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.personalization.advanced',
      title: 'Advanced Personalization',
      description: 'Premium themes and customization beyond XP unlocks.',
      icon: Icons.palette_rounded,
      category: PremiumFeatureCategory.personalization,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.history.extended',
      title: 'Extended History',
      description: 'Longer assistant and analytics history.',
      icon: Icons.history_rounded,
      category: PremiumFeatureCategory.insights,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.smart.notifications',
      title: 'Smart Notifications',
      description: 'Intelligent reminders tuned to your day.',
      icon: Icons.notifications_rounded,
      category: PremiumFeatureCategory.insights,
      status: PremiumFeatureStatus.comingSoon,
    ),
    PremiumFeature(
      id: 'premium.widgets',
      title: 'Premium Widgets',
      description: 'Quick-access widgets where implemented.',
      icon: Icons.widgets_rounded,
      category: PremiumFeatureCategory.personalization,
      status: PremiumFeatureStatus.comingSoon,
    ),
  ];

  static PremiumFeature? byId(String id) =>
      features.where((f) => f.id == id).firstOrNull;

  static List<PremiumFeature> byCategory(PremiumFeatureCategory category) =>
      features.where((f) => f.category == category).toList();

  static List<PremiumFeature> get activeFeatures =>
      features.where((f) => f.status == PremiumFeatureStatus.active).toList();
}

/// Free baseline: everything a student gets without Pro. Core student
/// functionality always stays free.
abstract final class FreeBaseline {
  static const List<String> items = [
    'Basic Tasks',
    'Basic Planning',
    'Subjects',
    'Exams',
    'Basic Study tracking',
    'Basic Revision',
    'Basic Focus',
    'Basic Sleep schedule',
    'Basic Assistant',
    'Basic Progress',
    'Basic XP & Rewards',
    'Core authentication',
    'Core data storage',
  ];
}

/// Free vs Pro comparison rows rendered from one definition.
@immutable
class PlanComparisonRow {
  const PlanComparisonRow({required this.label, required this.free, required this.pro});

  final String label;
  final String free;
  final String pro;
}

abstract final class PlanComparison {
  static const List<PlanComparisonRow> rows = [
    PlanComparisonRow(
        label: 'Tasks & Planning', free: 'Basic', pro: 'Smart + Catch-Up'),
    PlanComparisonRow(
        label: 'Focus', free: 'Standard sessions', pro: 'Deep + Strict modes'),
    PlanComparisonRow(
        label: 'Assistant',
        free: 'Ask & organize',
        pro: 'Proactive + advanced actions'),
    PlanComparisonRow(
        label: 'Exams & Revision',
        free: 'Tracking',
        pro: 'Intelligence + phased plans'),
    PlanComparisonRow(
        label: 'Analytics', free: 'Basic progress', pro: 'Advanced insights'),
    PlanComparisonRow(
        label: 'Sleep',
        free: 'Schedule + reminders',
        pro: 'Sleep-aware planning'),
    PlanComparisonRow(
        label: 'Personalization',
        free: 'XP themes',
        pro: 'Premium themes (soon)'),
  ];
}
