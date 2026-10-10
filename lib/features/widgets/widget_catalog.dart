import 'package:flutter/material.dart';

/// Widget size families. SMALL = one fact; MEDIUM = fact + action;
/// LARGE = richer context. Platform layouts differ; the identity is shared.
enum WidgetSize { small, medium, large }

/// Widget tiers: Tier 1 ships fully functional now; Tier 2/3 ride the same
/// snapshot + native plumbing once their native layouts land.
enum WidgetTier { tier1, tier2, tier3 }

/// One home-screen widget definition. [premiumFeatureId] is null for Free
/// widgets; otherwise the native side renders locked until the app reports
/// access (tap still deep-links into the paywall via the app).
@immutable
class StudentWidgetDef {
  const StudentWidgetDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.sizes,
    this.premiumFeatureId,
    required this.deepLink,
    this.configurable = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final WidgetTier tier;
  final List<WidgetSize> sizes;
  final String? premiumFeatureId;
  final String deepLink;
  final bool configurable;

  bool get isFree => premiumFeatureId == null;
}

/// Deep link for a catalog entry given its lock state: locked widgets
/// route to the paywall with feature context; unlocked ones go straight
/// to the destination.
String widgetDeepLinkFor(StudentWidgetDef def, {required bool locked}) {
  if (locked && def.premiumFeatureId != null) {
    return 'studentos://widget/premium?feature=${def.premiumFeatureId}';
  }
  return def.deepLink;
}

/// Central widget catalog: the only place widget identities, tiers, sizes,
/// deep links, and premium mappings live.
abstract final class WidgetCatalog {
  static const List<StudentWidgetDef> widgets = [
    // ── Tier 1 ──
    StudentWidgetDef(
      id: 'exam_countdown',
      title: 'Next Exam Countdown',
      description: 'See your next exam at a glance.',
      icon: Icons.school_rounded,
      tier: WidgetTier.tier1,
      sizes: [WidgetSize.small, WidgetSize.medium, WidgetSize.large],
      deepLink: 'studentos://widget/exam',
      configurable: true,
    ),
    StudentWidgetDef(
      id: 'next_action',
      title: 'Next Best Action',
      description: 'Know what to do next.',
      icon: Icons.bolt_rounded,
      tier: WidgetTier.tier1,
      sizes: [WidgetSize.small, WidgetSize.medium],
      deepLink: 'studentos://widget/assistant',
    ),
    StudentWidgetDef(
      id: 'today_tasks',
      title: "Today's Tasks",
      description: "Keep today's work visible.",
      icon: Icons.checklist_rounded,
      tier: WidgetTier.tier1,
      sizes: [WidgetSize.small, WidgetSize.medium, WidgetSize.large],
      deepLink: 'studentos://widget/tasks',
    ),
    StudentWidgetDef(
      id: 'daily_plan',
      title: 'Daily Plan',
      description: 'See your schedule.',
      icon: Icons.calendar_today_rounded,
      tier: WidgetTier.tier1,
      sizes: [WidgetSize.medium, WidgetSize.large],
      deepLink: 'studentos://widget/planning',
    ),
    StudentWidgetDef(
      id: 'quick_focus',
      title: 'Quick Focus',
      description: 'Start focusing faster.',
      icon: Icons.timer_rounded,
      tier: WidgetTier.tier1,
      sizes: [WidgetSize.small, WidgetSize.medium],
      deepLink: 'studentos://widget/custom-focus',
    ),
    StudentWidgetDef(
      id: 'assistant',
      title: 'Student OS Assistant',
      description: 'Get your next recommendation.',
      icon: Icons.auto_awesome_rounded,
      tier: WidgetTier.tier1,
      sizes: [WidgetSize.small, WidgetSize.medium],
      deepLink: 'studentos://widget/assistant',
    ),
    StudentWidgetDef(
      id: 'exam_prep',
      title: 'Exam Preparation',
      description: 'Countdown plus today\'s prep target.',
      icon: Icons.assignment_rounded,
      tier: WidgetTier.tier1,
      sizes: [WidgetSize.medium, WidgetSize.large],
      deepLink: 'studentos://widget/exam',
    ),
    StudentWidgetDef(
      id: 'sleep_schedule',
      title: 'Sleep',
      description: 'See your planned sleep window.',
      icon: Icons.bedtime_rounded,
      tier: WidgetTier.tier1,
      sizes: [WidgetSize.small, WidgetSize.medium],
      deepLink: 'studentos://widget/sleep',
    ),
    // ── Tier 2 ──
    StudentWidgetDef(
      id: 'upcoming_exams',
      title: 'Upcoming Exams',
      description: 'Your next few exams with countdowns.',
      icon: Icons.event_rounded,
      tier: WidgetTier.tier2,
      sizes: [WidgetSize.medium, WidgetSize.large],
      deepLink: 'studentos://widget/exam',
      configurable: true,
    ),
    StudentWidgetDef(
      id: 'today_study',
      title: "Today's Study",
      description: 'Planned, completed, and remaining study.',
      icon: Icons.menu_book_rounded,
      tier: WidgetTier.tier2,
      sizes: [WidgetSize.medium],
      deepLink: 'studentos://widget/progress',
    ),
    StudentWidgetDef(
      id: 'focus_stats',
      title: 'Focus Statistics',
      description: 'Today and this week in focus.',
      icon: Icons.insights_rounded,
      tier: WidgetTier.tier2,
      sizes: [WidgetSize.medium],
      deepLink: 'studentos://widget/focus',
      premiumFeatureId: 'premium.analytics.advanced',
    ),
    StudentWidgetDef(
      id: 'current_focus',
      title: 'Current Focus',
      description: 'Your live session at a glance.',
      icon: Icons.play_circle_rounded,
      tier: WidgetTier.tier2,
      sizes: [WidgetSize.small, WidgetSize.medium],
      deepLink: 'studentos://widget/focus',
    ),
    StudentWidgetDef(
      id: 'backlog',
      title: 'Backlog',
      description: 'Unfinished and overdue work.',
      icon: Icons.layers_rounded,
      tier: WidgetTier.tier2,
      sizes: [WidgetSize.medium],
      deepLink: 'studentos://widget/tasks',
    ),
    StudentWidgetDef(
      id: 'subject_progress',
      title: 'Subject Progress',
      description: 'Study and revision progress per subject.',
      icon: Icons.donut_large_rounded,
      tier: WidgetTier.tier2,
      sizes: [WidgetSize.medium],
      deepLink: 'studentos://widget/progress',
      configurable: true,
    ),
    // ── Tier 3 ──
    StudentWidgetDef(
      id: 'weekly_overview',
      title: 'Weekly Overview',
      description: 'The week ahead, compact.',
      icon: Icons.date_range_rounded,
      tier: WidgetTier.tier3,
      sizes: [WidgetSize.large],
      deepLink: 'studentos://widget/planning',
    ),
    StudentWidgetDef(
      id: 'focus_streak',
      title: 'Focus Streak',
      description: 'Your daily focus momentum.',
      icon: Icons.local_fire_department_rounded,
      tier: WidgetTier.tier3,
      sizes: [WidgetSize.small],
      deepLink: 'studentos://widget/focus',
    ),
    StudentWidgetDef(
      id: 'assistant_quick_actions',
      title: 'Assistant Quick Actions',
      description: 'Plan, study, urgency — one tap.',
      icon: Icons.flash_on_rounded,
      tier: WidgetTier.tier3,
      sizes: [WidgetSize.medium],
      deepLink: 'studentos://widget/assistant',
    ),
    StudentWidgetDef(
      id: 'daily_brief',
      title: 'Daily Student Brief',
      description: 'Morning priorities, tasks, sleep.',
      icon: Icons.wb_sunny_rounded,
      tier: WidgetTier.tier3,
      sizes: [WidgetSize.large],
      deepLink: 'studentos://widget/assistant',
      premiumFeatureId: 'premium.assistant.proactive',
    ),
    StudentWidgetDef(
      id: 'quick_task_entry',
      title: 'Quick Task Entry',
      description: 'Add tasks and exams fast.',
      icon: Icons.add_task_rounded,
      tier: WidgetTier.tier3,
      sizes: [WidgetSize.small],
      deepLink: 'studentos://widget/add-task',
    ),
    StudentWidgetDef(
      id: 'day_balance',
      title: 'Day Balance',
      description: 'Study, focus, tasks, sleep.',
      icon: Icons.balance_rounded,
      tier: WidgetTier.tier3,
      sizes: [WidgetSize.medium, WidgetSize.large],
      deepLink: 'studentos://widget/home',
    ),
  ];

  static StudentWidgetDef? byId(String id) =>
      widgets.where((w) => w.id == id).firstOrNull;

  static List<StudentWidgetDef> byTier(WidgetTier tier) =>
      widgets.where((w) => w.tier == tier).toList();
}
