import 'package:flutter/foundation.dart';
import 'course_category.dart';
import 'catalog_curriculum.dart';

/// Top-level course entity in the Course Catalog.
///
/// Represents an academic or professional offering (e.g. "CBSE Class 10",
/// "ICAI Chartered Accountancy", "B.Tech Computer Science") under an [EducationCategory].
@immutable
class CatalogCourse {
  const CatalogCourse({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.authority,
    this.catalogVersion = 'DEFAULT',
    this.active = true,
    this.curricula = const [],
    this.metadata,
  });

  final String id;
  final String name;
  final CourseCategory category;
  final String? description;
  final String? authority;
  final String catalogVersion;
  final bool active;
  final List<CatalogCurriculum> curricula;
  final Map<String, dynamic>? metadata;

  /// Returns the currently active curriculum version, or the first available.
  CatalogCurriculum? get activeCurriculum {
    if (curricula.isEmpty) return null;
    for (final c in curricula) {
      if (c.isActive && c.versionCode == catalogVersion) return c;
    }
    for (final c in curricula) {
      if (c.isActive) return c;
    }
    return curricula.first;
  }

  /// Retrieves a specific curriculum by its version code.
  CatalogCurriculum? getCurriculumByVersion(String versionCode) {
    for (final c in curricula) {
      if (c.versionCode == versionCode) return c;
    }
    return null;
  }

  CatalogCourse copyWith({
    String? id,
    String? name,
    CourseCategory? category,
    String? description,
    String? authority,
    String? catalogVersion,
    bool? active,
    List<CatalogCurriculum>? curricula,
    Map<String, dynamic>? metadata,
  }) {
    return CatalogCourse(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      authority: authority ?? this.authority,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      active: active ?? this.active,
      curricula: curricula ?? this.curricula,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    if (description != null) 'description': description,
    if (authority != null) 'authority': authority,
    'catalogVersion': catalogVersion,
    'active': active,
    if (curricula.isNotEmpty)
      'curricula': curricula.map((c) => c.toJson()).toList(),
    if (metadata != null) 'metadata': metadata,
  };

  factory CatalogCourse.fromJson(Map<String, dynamic> json) {
    return CatalogCourse(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      category: CourseCategory.fromString(json['category'] as String?),
      description: json['description'] as String?,
      authority: json['authority'] as String?,
      catalogVersion: (json['catalogVersion'] as String?) ?? 'DEFAULT',
      active: (json['active'] as bool?) ?? true,
      curricula: (json['curricula'] as List<dynamic>?)
              ?.map((c) => CatalogCurriculum.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogCourse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          description == other.description &&
          authority == other.authority &&
          catalogVersion == other.catalogVersion &&
          active == other.active &&
          listEquals(curricula, other.curricula);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    description,
    authority,
    catalogVersion,
    active,
    Object.hashAll(curricula),
  );
}
