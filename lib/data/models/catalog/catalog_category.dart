import 'package:flutter/material.dart';

/// Top-level Category in the Student OS Catalog 2.0 Information Architecture.
///
/// Supports 18 master categories spanning school, competitive exams,
/// higher education, and professional qualifications.
@immutable
class CatalogCategory2 {
  const CatalogCategory2({
    required this.id,
    required this.title,
    this.shortTitle,
    this.description,
    this.iconName,
    this.iconData,
    this.order = 0,
    this.isPopular = false,
    this.familyCount = 0,
    this.programCount = 0,
    this.metadata,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String? shortTitle;
  final String? description;
  final String? iconName;
  final IconData? iconData;
  final int order;
  final bool isPopular;
  final int familyCount;
  final int programCount;
  final Map<String, dynamic>? metadata;
  final bool isActive;

  String get displayTitle => shortTitle ?? title;

  IconData get resolvedIcon {
    if (iconData != null) return iconData!;
    return switch (iconName ?? id) {
      'school_boards_olympiads' => Icons.school_rounded,
      'engineering_technology' => Icons.engineering_rounded,
      'medical_healthcare' => Icons.medical_services_rounded,
      'law' => Icons.gavel_rounded,
      'management_business' => Icons.business_center_rounded,
      'commerce_accounting_finance' => Icons.account_balance_rounded,
      'government_job_exams' => Icons.account_balance_outlined,
      'banking_financial_recruitment' => Icons.payments_rounded,
      'defence' => Icons.shield_rounded,
      'teaching_education' => Icons.menu_book_rounded,
      'research_net_exams' => Icons.biotech_rounded,
      'design' => Icons.palette_rounded,
      'architecture_planning' => Icons.apartment_rounded,
      'agriculture' => Icons.agriculture_rounded,
      'science_university_entrance' => Icons.science_rounded,
      'postgraduate_entrance' => Icons.psychology_rounded,
      'professional_certifications' => Icons.verified_rounded,
      'other_career_upskilling' => Icons.auto_awesome_rounded,
      _ => Icons.category_rounded,
    };
  }

  CatalogCategory2 copyWith({
    String? id,
    String? title,
    String? shortTitle,
    String? description,
    String? iconName,
    IconData? iconData,
    int? order,
    bool? isPopular,
    int? familyCount,
    int? programCount,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return CatalogCategory2(
      id: id ?? this.id,
      title: title ?? this.title,
      shortTitle: shortTitle ?? this.shortTitle,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      iconData: iconData ?? this.iconData,
      order: order ?? this.order,
      isPopular: isPopular ?? this.isPopular,
      familyCount: familyCount ?? this.familyCount,
      programCount: programCount ?? this.programCount,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (shortTitle != null) 'shortTitle': shortTitle,
    if (description != null) 'description': description,
    if (iconName != null) 'iconName': iconName,
    'order': order,
    'isPopular': isPopular,
    'familyCount': familyCount,
    'programCount': programCount,
    if (metadata != null) 'metadata': metadata,
    'isActive': isActive,
  };

  factory CatalogCategory2.fromJson(Map<String, dynamic> json) {
    return CatalogCategory2(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      shortTitle: json['shortTitle'] as String?,
      description: json['description'] as String?,
      iconName: json['iconName'] as String?,
      order: (json['order'] as int?) ?? 0,
      isPopular: (json['isPopular'] as bool?) ?? false,
      familyCount: (json['familyCount'] as int?) ?? 0,
      programCount: (json['programCount'] as int?) ?? 0,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogCategory2 &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
