import 'package:flutter/material.dart';

/// Centralized goal visual identity mapping.
/// Maps exam/course titles to specific icons and visual metadata.
/// Replaces hardcoded lightning icons throughout onboarding.
abstract final class GoalIconMapping {
  // Engineering exams
  static const _engineeringIcons = {
    'JEE Main': Icons.precision_manufacturing_rounded,
    'JEE Advanced': Icons.rocket_launch_rounded,
    'GATE': Icons.settings_input_component_rounded,
    'BITSAT': Icons.layers_rounded,
  };

  // Medical exams
  static const _medicalIcons = {
    'NEET UG': Icons.monitor_heart_rounded,
    'NEET PG': Icons.psychology_rounded,
    'AIIMS': Icons.local_hospital_rounded,
  };

  // Law exams
  static const _lawIcons = {
    'CLAT UG': Icons.gavel_rounded,
    'CLAT PG': Icons.balance_rounded,
    'LSAT': Icons.description_rounded,
  };

  // Commerce/MBA exams
  static const _commerceIcons = {
    'CAT': Icons.trending_up_rounded,
    'GMAT': Icons.assessment_rounded,
    'CMA': Icons.receipt_long_rounded,
  };

  // Government/Civil service exams
  static const _governmentIcons = {
    'UPSC': Icons.account_balance_rounded,
    'SSC': Icons.shield_rounded,
    'IBPS': Icons.account_balance_wallet_rounded,
  };

  // School/Board exams
  static const _schoolIcons = {
    'CBSE': Icons.school_rounded,
    'ICSE': Icons.library_books_rounded,
    'ISC': Icons.book_rounded,
    'State Board': Icons.home_work_rounded,
  };

  // Olympiad/Competitive
  static const _olympiadIcons = {
    'JMO': Icons.calculate_rounded,
    'IJSO': Icons.science_rounded,
    'IAO': Icons.public_rounded,
    'IOI': Icons.computer_rounded,
  };

  /// Get icon for a goal/exam title using fuzzy, case-insensitive matching.
  /// Falls back to generic target icon if no specific mapping exists.
  /// Never returns bolt/lightning — that visual is retired.
  static IconData getIconForGoal(String title) {
    final t = title.toLowerCase();

    // Exact match first (fast path)
    for (final map in [
      _engineeringIcons,
      _medicalIcons,
      _lawIcons,
      _commerceIcons,
      _governmentIcons,
      _schoolIcons,
      _olympiadIcons,
    ]) {
      for (final entry in map.entries) {
        if (title == entry.key) {
          return entry.value;
        }
      }
    }

    // Fuzzy contains matching — handles "GATE 2026", "UPSC Civil Services (IAS...)", etc.
    if (t.contains('jee advanced')) {
      return Icons.rocket_launch_rounded;
    }
    if (t.contains('jee main') || t.contains('joint entrance')) {
      return Icons.precision_manufacturing_rounded;
    }
    if (t.contains('bitsat')) {
      return Icons.layers_rounded;
    }
    if (t.contains('mht-cet') || t.contains('mht cet')) {
      return Icons.engineering_rounded;
    }
    if (t.contains('gate')) {
      return Icons.settings_input_component_rounded;
    }
    if (t.contains('neet pg')) {
      return Icons.psychology_rounded;
    }
    if (t.contains('neet') || t.contains('mbbs') || t.contains('medical')) {
      return Icons.monitor_heart_rounded;
    }
    if (t.contains('nursing') || t.contains('pharm')) {
      return Icons.local_hospital_rounded;
    }
    if (t.contains('clat') || t.contains('law') || t.contains('lsat')) {
      return Icons.gavel_rounded;
    }
    if (t.contains('cat') || t.contains('mba') || t.contains('management')) {
      return Icons.trending_up_rounded;
    }
    if (t.contains('gmat')) {
      return Icons.assessment_rounded;
    }
    if (t.contains('cma') ||
        t.contains('commerce') ||
        t.contains('finance') ||
        t.contains('ca ')) {
      return Icons.receipt_long_rounded;
    }
    if (t.contains('upsc') ||
        t.contains('civil service') ||
        t.contains('ias') ||
        t.contains('ips')) {
      return Icons.account_balance_rounded;
    }
    if (t.contains('ssc') || t.contains('staff selection')) {
      return Icons.verified_user_rounded;
    }
    if (t.contains('ibps') || t.contains('bank')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (t.contains('railway') || t.contains('rrb')) {
      return Icons.train_rounded;
    }
    if (t.contains('cbse') ||
        t.contains('icse') ||
        t.contains('board') ||
        t.contains('class ')) {
      return Icons.school_rounded;
    }
    if (t.contains('olympiad') || t.contains('jmo') || t.contains('ijso')) {
      return Icons.emoji_events_rounded;
    }
    if (t.contains('cuet') || t.contains('university')) {
      return Icons.account_balance_rounded;
    }
    if (t.contains('defence') ||
        t.contains('nda') ||
        t.contains('cds') ||
        t.contains('agniveer')) {
      return Icons.shield_rounded;
    }
    if (t.contains('design') || t.contains('nid') || t.contains('uceed')) {
      return Icons.brush_rounded;
    }
    if (t.contains('computer') || t.contains('coding')) {
      return Icons.computer_rounded;
    }
    if (t.contains('science')) {
      return Icons.science_rounded;
    }
    if (t.contains('math')) {
      return Icons.calculate_rounded;
    }

    // Sophisticated generic fallback — never lightning
    return Icons.track_changes_rounded;
  }

  /// Get category label for grouping using fuzzy matching.
  static String getCategoryForGoal(String title) {
    final t = title.toLowerCase();
    if (t.contains('jee') ||
        t.contains('gate') ||
        t.contains('bitsat') ||
        t.contains('mht') ||
        t.contains('engineering')) {
      return 'Engineering';
    }
    if (t.contains('neet') ||
        t.contains('mbbs') ||
        t.contains('medical') ||
        t.contains('nursing') ||
        t.contains('pharm')) {
      return 'Medical';
    }
    if (t.contains('clat') || t.contains('law') || t.contains('lsat')) {
      return 'Law';
    }
    if (t.contains('cat') ||
        t.contains('mba') ||
        t.contains('management') ||
        t.contains('gmat') ||
        t.contains('commerce') ||
        t.contains('finance')) {
      return 'Business';
    }
    if (t.contains('upsc') ||
        t.contains('ssc') ||
        t.contains('ibps') ||
        t.contains('bank') ||
        t.contains('government') ||
        t.contains('civil')) {
      return 'Government';
    }
    if (t.contains('cbse') ||
        t.contains('icse') ||
        t.contains('board') ||
        t.contains('class') ||
        t.contains('school')) {
      return 'School';
    }
    if (t.contains('olympiad') ||
        t.contains('cuet') ||
        t.contains('university')) {
      return 'University';
    }
    if (t.contains('defence') || t.contains('nda')) {
      return 'Defence';
    }
    return 'Goal';
  }

  /// Get a color tint for visual differentiation (subtle tonal shift).
  /// All remain within Student OS green family.
  static Color getTintForGoal(String title) {
    final hash = title.hashCode;
    final tints = [
      const Color(0xFF2D5C4B), // Deep emerald
      const Color(0xFF3D7F6F), // Medium emerald
      const Color(0xFF4D9E8D), // Lighter emerald
      const Color(0xFF5FB897), // Sage-emerald
      const Color(0xFF6FC9A9), // Light sage
    ];
    return tints[hash.abs() % tints.length];
  }
}
