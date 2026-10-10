import 'package:flutter/material.dart';

/// A demo item shown on the achievements/progress preview cards.
@immutable
class MockAchievement {
  const MockAchievement({
    required this.title,
    required this.icon,
    this.earned = true,
  });

  final String title;
  final IconData icon;
  final bool earned;
}

/// Demo data backing the Home, Plan, Study and Progress screens.
abstract final class MockDashboard {
  static const String userName = 'Alex';
  static const String journey = 'Goal-oriented student';

  static const int streakDays = 12;
  static const String focusSubject = 'Mathematics';
  static const int dailyGoal = 8;

  // Hourly progress indicators (0..1).
  static const double studyProgress = 0.65;
  static const double timeProgress = 0.5;
  static const double dailyCompletion = 0.72;

  static const String nextMilestoneTitle = 'Complete Algebra module';
  static const String nextMilestoneDate = 'SAT, SEP 5';

  static const List<String> quickActions = [
    'Plan my day',
    'Start study',
    'Add a task',
    'Track progress',
  ];

  static const List<MockAchievement> achievements = [
    MockAchievement(title: '7-day streak', icon: Icons.local_fire_department),
    MockAchievement(title: 'Early bird', icon: Icons.wb_sunny_outlined),
    MockAchievement(
      title: 'Focus master',
      icon: Icons.timer_outlined,
      earned: false,
    ),
    MockAchievement(
      title: 'Milestone maven',
      icon: Icons.emoji_events_outlined,
      earned: false,
    ),
  ];

  static const List<Color> achievementColors = [
    Color(0xFF1F5C44),
    Color(0xFF4F7D68),
    Color(0xFF2E7D5B),
    Color(0xFF6F967F),
  ];
}
