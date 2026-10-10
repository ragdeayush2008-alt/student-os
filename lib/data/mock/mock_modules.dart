import 'package:flutter/material.dart';

import 'app_module.dart';

/// Local demo catalog of future Student OS modules, organized by category.
/// These are visual blueprints only — none of the advanced features exist yet.
abstract final class MockModules {
  static const List<AppModule> organize = [
    AppModule(
      id: 'planning',
      title: 'Planning',
      subtitle: 'Daily, weekly and long-term study planning.',
      icon: Icons.calendar_month_outlined,
      category: ModuleCategory.organize,
    ),
    AppModule(
      id: 'milestones',
      title: 'Milestones',
      subtitle: 'Define and track key achievements.',
      icon: Icons.emoji_events_outlined,
      category: ModuleCategory.organize,
    ),
    AppModule(
      id: 'preparation',
      title: 'Preparation',
      subtitle: 'Mock tests, question banks and roadmaps.',
      icon: Icons.workspace_premium_outlined,
      category: ModuleCategory.organize,
    ),
  ];

  static const List<AppModule> focus = [
    AppModule(
      id: 'study',
      title: 'Study',
      subtitle: 'Subjects, sessions and focus modes.',
      icon: Icons.menu_book_outlined,
      category: ModuleCategory.focus,
    ),
    AppModule(
      id: 'productivity',
      title: 'Productivity',
      subtitle: 'Focus timers, habits and deep work.',
      icon: Icons.bolt_outlined,
      category: ModuleCategory.focus,
    ),
    AppModule(
      id: 'wellbeing',
      title: 'Wellbeing',
      subtitle: 'Breaks, balance and sustainable study.',
      icon: Icons.spa_outlined,
      category: ModuleCategory.focus,
    ),
  ];

  static const List<AppModule> grow = [
    AppModule(
      id: 'progress',
      title: 'Progress',
      subtitle: 'Consistency, completion and milestones.',
      icon: Icons.trending_up_outlined,
      category: ModuleCategory.grow,
    ),
    AppModule(
      id: 'rewards',
      title: 'Rewards',
      subtitle: 'Badges, points and achievements preview.',
      icon: Icons.redeem_outlined,
      category: ModuleCategory.grow,
    ),
    AppModule(
      id: 'achievements',
      title: 'Achievements',
      subtitle: 'A record of accomplishments and skills.',
      icon: Icons.military_tech_outlined,
      category: ModuleCategory.grow,
    ),
  ];

  static const List<AppModule> explore = [
    AppModule(
      id: 'exams',
      title: 'Exams',
      subtitle: 'Exam profiles and syllabus organization.',
      icon: Icons.assignment_outlined,
      category: ModuleCategory.explore,
    ),
    AppModule(
      id: 'academic_tools',
      title: 'Academic Tools',
      subtitle: 'Calculators, references and utilities.',
      icon: Icons.calculate_outlined,
      category: ModuleCategory.explore,
    ),
    AppModule(
      id: 'resources',
      title: 'Resources',
      subtitle: 'Resource library, bookmarks and discovery.',
      icon: Icons.folder_copy_outlined,
      category: ModuleCategory.explore,
    ),
    AppModule(
      id: 'community',
      title: 'Community',
      subtitle: 'Study circles and peer support (opt-in).',
      icon: Icons.group_outlined,
      category: ModuleCategory.explore,
    ),
    AppModule(
      id: 'utilities',
      title: 'Utilities',
      subtitle: 'Converters, quick tools and helpers.',
      icon: Icons.handyman_outlined,
      category: ModuleCategory.explore,
    ),
  ];

  static const List<AppModule> all = [
    ...organize,
    ...focus,
    ...grow,
    ...explore,
  ];
}
