import 'package:flutter/foundation.dart';
import 'catalog_subject.dart';

/// Semantic types of structural nodes in the course hierarchy.
enum CatalogNodeType {
  level('Level'),
  year('Year'),
  semester('Semester'),
  stream('Stream'),
  group('Group'),
  specialization('Specialization'),
  module('Module'),
  paperGroup('Paper Group'),
  stage('Stage'),
  custom('Custom');

  const CatalogNodeType(this.label);
  final String label;

  static CatalogNodeType fromString(String? val) {
    if (val == null || val.isEmpty) return CatalogNodeType.custom;
    for (final t in CatalogNodeType.values) {
      if (t.name.toLowerCase() == val.toLowerCase()) return t;
    }
    return CatalogNodeType.custom;
  }
}

/// A node in a course's curriculum hierarchy.
///
/// Supports arbitrary depth and structures:
/// - School: Board -> Class -> Subjects
/// - Senior Secondary: Class -> Stream -> Subjects
/// - Professional: Level -> Group -> Papers
/// - University: Specialization -> Semester -> Subjects
@immutable
class CatalogNode {
  const CatalogNode({
    required this.id,
    required this.name,
    this.type = CatalogNodeType.level,
    this.description,
    this.sortOrder = 0,
    this.children = const [],
    this.subjects = const [],
    this.metadata,
  });

  final String id;
  final String name;
  final CatalogNodeType type;
  final String? description;
  final int sortOrder;
  final List<CatalogNode> children;
  final List<CatalogSubject> subjects;
  final Map<String, dynamic>? metadata;

  /// Recursively retrieves all subjects contained in this node and all its child nodes.
  List<CatalogSubject> get allSubjects {
    final list = <CatalogSubject>[...subjects];
    for (final child in children) {
      list.addAll(child.allSubjects);
    }
    return List.unmodifiable(list);
  }

  /// Total count of all subjects under this node.
  int get totalSubjectCount => allSubjects.length;

  /// Whether this node is a leaf (contains subjects directly and no children).
  bool get isLeaf => children.isEmpty;

  /// Finds a descendant node by ID.
  CatalogNode? findNodeById(String nodeId) {
    if (id == nodeId) return this;
    for (final child in children) {
      final match = child.findNodeById(nodeId);
      if (match != null) return match;
    }
    return null;
  }

  /// Finds a subject by ID anywhere within this subtree.
  CatalogSubject? findSubjectById(String subjectId) {
    for (final s in subjects) {
      if (s.id == subjectId) return s;
    }
    for (final child in children) {
      final match = child.findSubjectById(subjectId);
      if (match != null) return match;
    }
    return null;
  }

  CatalogNode copyWith({
    String? id,
    String? name,
    CatalogNodeType? type,
    String? description,
    int? sortOrder,
    List<CatalogNode>? children,
    List<CatalogSubject>? subjects,
    Map<String, dynamic>? metadata,
  }) {
    return CatalogNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      children: children ?? this.children,
      subjects: subjects ?? this.subjects,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    if (description != null) 'description': description,
    'sortOrder': sortOrder,
    if (children.isNotEmpty)
      'children': children.map((c) => c.toJson()).toList(),
    if (subjects.isNotEmpty)
      'subjects': subjects.map((s) => s.toJson()).toList(),
    if (metadata != null) 'metadata': metadata,
  };

  factory CatalogNode.fromJson(Map<String, dynamic> json) {
    return CatalogNode(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      type: CatalogNodeType.fromString(json['type'] as String?),
      description: json['description'] as String?,
      sortOrder: (json['sortOrder'] as int?) ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => CatalogNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((s) => CatalogSubject.fromJson(s as Map<String, dynamic>))
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
      other is CatalogNode &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          description == other.description &&
          sortOrder == other.sortOrder &&
          listEquals(children, other.children) &&
          listEquals(subjects, other.subjects);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    description,
    sortOrder,
    Object.hashAll(children),
    Object.hashAll(subjects),
  );
}
