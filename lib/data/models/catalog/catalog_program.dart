import 'package:flutter/foundation.dart';
import 'catalog_course.dart';
import 'catalog_curriculum.dart';
import 'catalog_level.dart';
import 'course_category.dart';

/// Top-level Program / Course / Exam offering in Catalog 2.0.
///
/// Models diverse offerings such as JEE Main, CA Foundation, GATE 2026,
/// NEET UG, CLAT UG, SSC CGL, UGC NET, B.Tech CSE, etc.
@immutable
class CatalogProgram {
  const CatalogProgram({
    required this.id,
    required this.familyId,
    required this.categoryId,
    required this.title,
    this.shortTitle,
    this.code,
    this.description,
    this.authority,
    this.order = 0,
    this.isPopular = false,
    this.defaultYear = '2026',
    this.availableYears = const ['2026'],
    this.aliases = const [],
    this.levels = const [],
    this.metadata,
    this.isActive = true,
  });

  final String id;
  final String familyId;
  final String categoryId;
  final String title;
  final String? shortTitle;
  final String? code;
  final String? description;
  final String? authority;
  final int order;
  final bool isPopular;
  final String defaultYear;
  final List<String> availableYears;
  final List<String> aliases;
  final List<CatalogLevel> levels;
  final Map<String, dynamic>? metadata;
  final bool isActive;

  String get displayTitle => shortTitle ?? title;

  /// Converts this program to a legacy [CatalogCourse] for backward compatibility.
  CatalogCourse toCatalogCourse() {
    final legacyCategory = CourseCategory.fromString(categoryId);
    final curriculum = CatalogCurriculum(
      id: 'curr_$id',
      courseId: id,
      versionCode: defaultYear,
      name: '$title Curriculum ($defaultYear)',
      structure: levels.map((l) => l.toCatalogNode()).toList(),
    );

    return CatalogCourse(
      id: id,
      name: title,
      category: legacyCategory,
      authority: authority,
      description: description,
      catalogVersion: defaultYear,
      curricula: [curriculum],
      metadata: metadata,
      active: isActive,
    );
  }

  CatalogProgram copyWith({
    String? id,
    String? familyId,
    String? categoryId,
    String? title,
    String? shortTitle,
    String? code,
    String? description,
    String? authority,
    int? order,
    bool? isPopular,
    String? defaultYear,
    List<String>? availableYears,
    List<String>? aliases,
    List<CatalogLevel>? levels,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return CatalogProgram(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      shortTitle: shortTitle ?? this.shortTitle,
      code: code ?? this.code,
      description: description ?? this.description,
      authority: authority ?? this.authority,
      order: order ?? this.order,
      isPopular: isPopular ?? this.isPopular,
      defaultYear: defaultYear ?? this.defaultYear,
      availableYears: availableYears ?? this.availableYears,
      aliases: aliases ?? this.aliases,
      levels: levels ?? this.levels,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'familyId': familyId,
    'categoryId': categoryId,
    'title': title,
    if (shortTitle != null) 'shortTitle': shortTitle,
    if (code != null) 'code': code,
    if (description != null) 'description': description,
    if (authority != null) 'authority': authority,
    'order': order,
    'isPopular': isPopular,
    'defaultYear': defaultYear,
    'availableYears': availableYears,
    'aliases': aliases,
    if (levels.isNotEmpty) 'levels': levels.map((l) => l.toJson()).toList(),
    if (metadata != null) 'metadata': metadata,
    'isActive': isActive,
  };

  factory CatalogProgram.fromJson(Map<String, dynamic> json) {
    return CatalogProgram(
      id: (json['id'] as String?) ?? '',
      familyId: (json['familyId'] as String?) ?? '',
      categoryId: (json['categoryId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      shortTitle: json['shortTitle'] as String?,
      code: json['code'] as String?,
      description: json['description'] as String?,
      authority: json['authority'] as String?,
      order: (json['order'] as int?) ?? 0,
      isPopular: (json['isPopular'] as bool?) ?? false,
      defaultYear: (json['defaultYear'] as String?) ?? '2026',
      availableYears: (json['availableYears'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['2026'],
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      levels: (json['levels'] as List<dynamic>?)
              ?.map((l) => CatalogLevel.fromJson(l as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogProgram &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
