import 'package:flutter/foundation.dart';
import 'catalog_node.dart';
import 'catalog_paper.dart';

/// Level / Stage / Tier / Stream / Year / Semester / Paper Group in a course program.
@immutable
class CatalogLevel {
  const CatalogLevel({
    required this.id,
    required this.programId,
    required this.title,
    this.parentId,
    this.code,
    this.shortTitle,
    this.description,
    this.type = CatalogNodeType.level,
    this.year,
    this.order = 0,
    this.papers = const [],
    this.children = const [],
    this.metadata,
    this.isActive = true,
  });

  final String id;
  final String programId;
  final String title;
  final String? parentId;
  final String? code;
  final String? shortTitle;
  final String? description;
  final CatalogNodeType type;
  final String? year;
  final int order;
  final List<CatalogPaper> papers;
  final List<CatalogLevel> children;
  final Map<String, dynamic>? metadata;
  final bool isActive;

  String get displayTitle => shortTitle ?? title;

  /// Recursively retrieves all papers in this level and any child sub-levels.
  List<CatalogPaper> get allPapers {
    final list = <CatalogPaper>[...papers];
    for (final child in children) {
      list.addAll(child.allPapers);
    }
    return list;
  }

  /// Finds a sub-level by ID.
  CatalogLevel? findLevelById(String targetId) {
    if (id == targetId) return this;
    for (final child in children) {
      final found = child.findLevelById(targetId);
      if (found != null) return found;
    }
    return null;
  }

  /// Converts this level and sub-tree to a legacy [CatalogNode] for backward compatibility.
  CatalogNode toCatalogNode() {
    return CatalogNode(
      id: id,
      name: title,
      type: type,
      description: description,
      sortOrder: order,
      subjects: papers.map((p) => p.toCatalogSubject()).toList(),
      children: children.map((c) => c.toCatalogNode()).toList(),
      metadata: metadata,
    );
  }

  CatalogLevel copyWith({
    String? id,
    String? programId,
    String? title,
    String? parentId,
    String? code,
    String? shortTitle,
    String? description,
    CatalogNodeType? type,
    String? year,
    int? order,
    List<CatalogPaper>? papers,
    List<CatalogLevel>? children,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return CatalogLevel(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      title: title ?? this.title,
      parentId: parentId ?? this.parentId,
      code: code ?? this.code,
      shortTitle: shortTitle ?? this.shortTitle,
      description: description ?? this.description,
      type: type ?? this.type,
      year: year ?? this.year,
      order: order ?? this.order,
      papers: papers ?? this.papers,
      children: children ?? this.children,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'programId': programId,
    'title': title,
    if (parentId != null) 'parentId': parentId,
    if (code != null) 'code': code,
    if (shortTitle != null) 'shortTitle': shortTitle,
    if (description != null) 'description': description,
    'type': type.name,
    if (year != null) 'year': year,
    'order': order,
    if (papers.isNotEmpty) 'papers': papers.map((p) => p.toJson()).toList(),
    if (children.isNotEmpty)
      'children': children.map((c) => c.toJson()).toList(),
    if (metadata != null) 'metadata': metadata,
    'isActive': isActive,
  };

  factory CatalogLevel.fromJson(Map<String, dynamic> json) {
    return CatalogLevel(
      id: (json['id'] as String?) ?? '',
      programId: (json['programId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      parentId: json['parentId'] as String?,
      code: json['code'] as String?,
      shortTitle: json['shortTitle'] as String?,
      description: json['description'] as String?,
      type: CatalogNodeType.fromString(json['type'] as String?),
      year: json['year'] as String?,
      order: (json['order'] as int?) ?? 0,
      papers: (json['papers'] as List<dynamic>?)
              ?.map((p) => CatalogPaper.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => CatalogLevel.fromJson(c as Map<String, dynamic>))
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
      other is CatalogLevel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
