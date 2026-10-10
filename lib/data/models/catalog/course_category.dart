import 'package:flutter/material.dart';

/// Top-level education categories for the Course & Subject System.
enum CourseCategory {
  school('School', Icons.school_outlined),
  seniorSecondary('Senior Secondary', Icons.account_balance_outlined),
  undergraduate('Undergraduate', Icons.business_center_outlined),
  postgraduate('Postgraduate', Icons.history_edu_outlined),
  professional('Professional', Icons.verified_outlined),
  diploma('Diploma', Icons.card_membership_outlined),
  vocational('Vocational', Icons.build_outlined),
  certification('Certification', Icons.military_tech_outlined);

  const CourseCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static CourseCategory fromString(String? value) {
    if (value == null || value.isEmpty) return CourseCategory.school;
    for (final c in CourseCategory.values) {
      if (c.name.toLowerCase() == value.toLowerCase()) return c;
    }
    return CourseCategory.school;
  }
}
