import 'package:flutter/foundation.dart';
import 'catalog_node.dart';
import 'catalog_subject.dart';

/// A versioned curriculum structure for a [CatalogCourse].
///
/// Enables syllabus versioning (e.g. "Old Scheme 2018" vs "New Scheme 2024" for CA,
/// or "2023-24" vs "2024-25" for CBSE) without overwriting historical data.
@immutable
class CatalogCurriculum {
  const CatalogCurriculum({
    required this.id,
    required this.courseId,
    required this.versionCode,
    required this.name,
    this.description,
    this.effectiveFromYear,
    this.effectiveToYear,
    this.isActive = true,
    this.structure = const [],
    this.metadata,
  });

  final String id;
  final String courseId;
  final String versionCode;
  final String name;
  final String? description;
  final int? effectiveFromYear;
  final int? effectiveToYear;
  final bool isActive;
  final List<CatalogNode> structure;
  final Map<String, dynamic>? metadata;

  /// Recursively retrieves all subjects across all root nodes in this curriculum.
  List<CatalogSubject> get allSubjects {
    final list = <CatalogSubject>[];
    for (final node in structure) {
      list.addAll(node.allSubjects);
    }
    return List.unmodifiable(list);
  }

  /// Total count of subjects in this curriculum version.
  int get totalSubjectCount => allSubjects.length;

  /// Finds any structural node by ID across the curriculum tree.
  CatalogNode? findNodeById(String nodeId) {
    for (final node in structure) {
      final match = node.findNodeById(nodeId);
      if (match != null) return match;
    }
    return null;
  }

  /// Finds any subject by ID across the curriculum tree.
  CatalogSubject? findSubjectById(String subjectId) {
    for (final node in structure) {
      final match = node.findSubjectById(subjectId);
      if (match != null) return match;
    }
    return null;
  }

  CatalogCurriculum copyWith({
    String? id,
    String? courseId,
    String? versionCode,
    String? name,
    String? description,
    int? effectiveFromYear,
    int? effectiveToYear,
    bool? isActive,
    List<CatalogNode>? structure,
    Map<String, dynamic>? metadata,
  }) {
    return CatalogCurriculum(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      versionCode: versionCode ?? this.versionCode,
      name: name ?? this.name,
      description: description ?? this.description,
      effectiveFromYear: effectiveFromYear ?? this.effectiveFromYear,
      effectiveToYear: effectiveToYear ?? this.effectiveToYear,
      isActive: isActive ?? this.isActive,
      structure: structure ?? this.structure,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'versionCode': versionCode,
    'name': name,
    if (description != null) 'description': description,
    if (effectiveFromYear != null) 'effectiveFromYear': effectiveFromYear,
    if (effectiveToYear != null) 'effectiveToYear': effectiveToYear,
    'isActive': isActive,
    if (structure.isNotEmpty)
      'structure': structure.map((n) => n.toJson()).toList(),
    if (metadata != null) 'metadata': metadata,
  };

  factory CatalogCurriculum.fromJson(Map<String, dynamic> json) {
    return CatalogCurriculum(
      id: (json['id'] as String?) ?? '',
      courseId: (json['courseId'] as String?) ?? '',
      versionCode: (json['versionCode'] as String?) ?? 'DEFAULT',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      effectiveFromYear: json['effectiveFromYear'] as int?,
      effectiveToYear: json['effectiveToYear'] as int?,
      isActive: (json['isActive'] as bool?) ?? true,
      structure: (json['structure'] as List<dynamic>?)
              ?.map((n) => CatalogNode.fromJson(n as Map<String, dynamic>))
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
      other is CatalogCurriculum &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          courseId == other.courseId &&
          versionCode == other.versionCode &&
          name == other.name &&
          description == other.description &&
          effectiveFromYear == other.effectiveFromYear &&
          effectiveToYear == other.effectiveToYear &&
          isActive == other.isActive &&
          listEquals(structure, other.structure);

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    versionCode,
    name,
    description,
    effectiveFromYear,
    effectiveToYear,
    isActive,
    Object.hashAll(structure),
  );
}
