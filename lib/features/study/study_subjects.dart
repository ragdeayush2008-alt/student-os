import 'package:flutter/material.dart';

/// A curated study subject with an icon and brand color.
///
/// This is a lightweight catalog used to label focus sessions. It is not fake
/// study *statistics* — session data itself always comes from persisted,
/// user-generated [StudySession] records.
class StudySubject {
  const StudySubject(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

/// Default subjects offered when starting a focus session.
abstract final class StudySubjects {
  static const List<StudySubject> all = [
    StudySubject('Mathematics', Icons.calculate_outlined, Color(0xFF123D35)),
    StudySubject('Physics', Icons.science_outlined, Color(0xFF285C4D)),
    StudySubject('Chemistry', Icons.biotech_outlined, Color(0xFF2E7D5B)),
    StudySubject('English', Icons.menu_book_outlined, Color(0xFF4F7D68)),
    StudySubject('Computer Science', Icons.code_rounded, Color(0xFF6F967F)),
    StudySubject('General', Icons.menu_book_rounded, Color(0xFF7A8450)),
  ];

  /// Fallback descriptor used when a persisted subject is not in [all] (e.g.
  /// linked to a task with its own category).
  static const StudySubject fallback = StudySubject(
    'General',
    Icons.menu_book_rounded,
    Color(0xFF7A8450),
  );

  static StudySubject of(String name) {
    for (final subject in all) {
      if (subject.name == name) return subject;
    }
    return fallback;
  }
}
