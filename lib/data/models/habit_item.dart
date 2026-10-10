import 'package:flutter/foundation.dart';

/// Frequency for student habits.
enum HabitFrequency {
  daily('Daily'),
  weekdays('Weekdays (Mon-Fri)'),
  weekly('Weekly');

  const HabitFrequency(this.label);
  final String label;

  static HabitFrequency fromString(String? val) {
    if (val == null) return HabitFrequency.daily;
    for (final f in HabitFrequency.values) {
      if (f.name == val) return f;
    }
    return HabitFrequency.daily;
  }
}

/// A student habit model tracking real completion history and streak.
@immutable
class HabitItem {
  const HabitItem({
    required this.id,
    required this.title,
    this.iconName = 'check',
    this.frequency = HabitFrequency.daily,
    this.completedDates = const {},
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String iconName;
  final HabitFrequency frequency;
  final Set<String> completedDates; // 'YYYY-MM-DD'
  final bool isActive;
  final DateTime createdAt;

  static String dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool isCompletedOn(DateTime dt) => completedDates.contains(dateKey(dt));

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// Calculates the consecutive day streak for this specific habit.
  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = dateKey(today);

    // If completed today, start from 0 days ago (today); otherwise start from 1 day ago (yesterday)
    var offset = completedDates.contains(todayKey) ? 0 : 1;
    var streak = 0;

    while (true) {
      final checkDate = today.subtract(Duration(days: offset));
      if (frequency == HabitFrequency.weekdays && (checkDate.weekday == 6 || checkDate.weekday == 7)) {
        offset++;
        continue;
      }
      final key = dateKey(checkDate);
      if (completedDates.contains(key)) {
        streak++;
        offset++;
      } else {
        break;
      }
    }
    return streak;
  }

  HabitItem copyWith({
    String? id,
    String? title,
    String? iconName,
    HabitFrequency? frequency,
    Set<String>? completedDates,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return HabitItem(
      id: id ?? this.id,
      title: title ?? this.title,
      iconName: iconName ?? this.iconName,
      frequency: frequency ?? this.frequency,
      completedDates: completedDates ?? this.completedDates,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'iconName': iconName,
        'frequency': frequency.name,
        'completedDates': completedDates.toList(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    return HabitItem(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      iconName: (json['iconName'] as String?) ?? 'check',
      frequency: HabitFrequency.fromString(json['frequency'] as String?),
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
