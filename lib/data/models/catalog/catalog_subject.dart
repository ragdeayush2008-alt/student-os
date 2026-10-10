import 'package:flutter/foundation.dart';

/// Defines how a subject is required within a course curriculum.
enum SubjectRequirementType {
  compulsory('Compulsory'),
  optional('Optional'),
  elective('Elective'),
  groupSpecific('Group Specific'),
  specializationSpecific('Specialization Specific');

  const SubjectRequirementType(this.label);
  final String label;

  static SubjectRequirementType fromString(String? val) {
    if (val == null || val.isEmpty) return SubjectRequirementType.compulsory;
    for (final t in SubjectRequirementType.values) {
      if (t.name.toLowerCase() == val.toLowerCase()) return t;
    }
    return SubjectRequirementType.compulsory;
  }
}

/// A curriculum subject definition in the Course Catalog.
///
/// Distinct from [Subject] (which represents a student's personal enrolled subject instance).
@immutable
class CatalogSubject {
  const CatalogSubject({
    required this.id,
    required this.name,
    this.code,
    this.shortName,
    this.description,
    this.type = SubjectRequirementType.compulsory,
    this.credits,
    this.color,
    this.iconCodePoint,
    this.metadata,
  });

  final String id;
  final String name;
  final String? code;
  final String? shortName;
  final String? description;
  final SubjectRequirementType type;
  final double? credits;
  final int? color;
  final int? iconCodePoint;
  final Map<String, dynamic>? metadata;

  String get displayName =>
      (shortName != null && shortName!.isNotEmpty) ? shortName! : name;

  bool get isCompulsory => type == SubjectRequirementType.compulsory;
  bool get isElective => type == SubjectRequirementType.elective;
  bool get isOptional => type == SubjectRequirementType.optional;

  CatalogSubject copyWith({
    String? id,
    String? name,
    String? code,
    String? shortName,
    String? description,
    SubjectRequirementType? type,
    double? credits,
    int? color,
    int? iconCodePoint,
    Map<String, dynamic>? metadata,
  }) {
    return CatalogSubject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      shortName: shortName ?? this.shortName,
      description: description ?? this.description,
      type: type ?? this.type,
      credits: credits ?? this.credits,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (code != null) 'code': code,
    if (shortName != null) 'shortName': shortName,
    if (description != null) 'description': description,
    'type': type.name,
    if (credits != null) 'credits': credits,
    if (color != null) 'color': color,
    if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
    if (metadata != null) 'metadata': metadata,
  };

  factory CatalogSubject.fromJson(Map<String, dynamic> json) {
    return CatalogSubject(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      code: json['code'] as String?,
      shortName: json['shortName'] as String?,
      description: json['description'] as String?,
      type: SubjectRequirementType.fromString(json['type'] as String?),
      credits: (json['credits'] as num?)?.toDouble(),
      color: json['color'] as int?,
      iconCodePoint: json['iconCodePoint'] as int?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogSubject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          code == other.code &&
          shortName == other.shortName &&
          description == other.description &&
          type == other.type &&
          credits == other.credits &&
          color == other.color &&
          iconCodePoint == other.iconCodePoint;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    code,
    shortName,
    description,
    type,
    credits,
    color,
    iconCodePoint,
  );
}
