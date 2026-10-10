import 'package:flutter/foundation.dart';
import 'catalog_subject.dart';

/// Subject / Paper definition within a level or stage in the course catalog.
@immutable
class CatalogPaper {
  const CatalogPaper({
    required this.id,
    required this.programId,
    required this.levelId,
    required this.title,
    this.code,
    this.shortTitle,
    this.description,
    this.type = SubjectRequirementType.compulsory,
    this.isOptional = false,
    this.groupId,
    this.order = 0,
    this.credits,
    this.color,
    this.iconCodePoint,
    this.year,
    this.topics = const [],
    this.metadata,
    this.isActive = true,
  });

  final String id;
  final String programId;
  final String levelId;
  final String title;
  final String? code;
  final String? shortTitle;
  final String? description;
  final SubjectRequirementType type;
  final bool isOptional;
  final String? groupId;
  final int order;
  final double? credits;
  final int? color;
  final int? iconCodePoint;
  final String? year;
  final List<String> topics;
  final Map<String, dynamic>? metadata;
  final bool isActive;

  String get displayName =>
      (shortTitle != null && shortTitle!.isNotEmpty) ? shortTitle! : title;

  bool get isCompulsory =>
      !isOptional &&
      (type == SubjectRequirementType.compulsory ||
          type == SubjectRequirementType.groupSpecific);

  /// Converts this paper definition to a legacy [CatalogSubject] for backward compatibility.
  CatalogSubject toCatalogSubject() {
    return CatalogSubject(
      id: id,
      name: title,
      code: code,
      shortName: shortTitle,
      description: description,
      type: type,
      credits: credits,
      color: color,
      iconCodePoint: iconCodePoint,
      metadata: metadata,
    );
  }

  CatalogPaper copyWith({
    String? id,
    String? programId,
    String? levelId,
    String? title,
    String? code,
    String? shortTitle,
    String? description,
    SubjectRequirementType? type,
    bool? isOptional,
    String? groupId,
    int? order,
    double? credits,
    int? color,
    int? iconCodePoint,
    String? year,
    List<String>? topics,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return CatalogPaper(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      levelId: levelId ?? this.levelId,
      title: title ?? this.title,
      code: code ?? this.code,
      shortTitle: shortTitle ?? this.shortTitle,
      description: description ?? this.description,
      type: type ?? this.type,
      isOptional: isOptional ?? this.isOptional,
      groupId: groupId ?? this.groupId,
      order: order ?? this.order,
      credits: credits ?? this.credits,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      year: year ?? this.year,
      topics: topics ?? this.topics,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'programId': programId,
    'levelId': levelId,
    'title': title,
    if (code != null) 'code': code,
    if (shortTitle != null) 'shortTitle': shortTitle,
    if (description != null) 'description': description,
    'type': type.name,
    'isOptional': isOptional,
    if (groupId != null) 'groupId': groupId,
    'order': order,
    if (credits != null) 'credits': credits,
    if (color != null) 'color': color,
    if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
    if (year != null) 'year': year,
    if (topics.isNotEmpty) 'topics': topics,
    if (metadata != null) 'metadata': metadata,
    'isActive': isActive,
  };

  factory CatalogPaper.fromJson(Map<String, dynamic> json) {
    return CatalogPaper(
      id: (json['id'] as String?) ?? '',
      programId: (json['programId'] as String?) ?? '',
      levelId: (json['levelId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      code: json['code'] as String?,
      shortTitle: json['shortTitle'] as String?,
      description: json['description'] as String?,
      type: SubjectRequirementType.fromString(json['type'] as String?),
      isOptional: (json['isOptional'] as bool?) ?? false,
      groupId: json['groupId'] as String?,
      order: (json['order'] as int?) ?? 0,
      credits: (json['credits'] as num?)?.toDouble(),
      color: json['color'] as int?,
      iconCodePoint: json['iconCodePoint'] as int?,
      year: json['year'] as String?,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
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
      other is CatalogPaper &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
