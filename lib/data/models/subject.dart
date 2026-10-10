import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Curated, const-safe subject icons for the visual identity selector.
///
/// `IconData.codePoint` is annotated `@mustBeConst`, so dynamically built
/// `IconData`s are avoided. Persisted subjects store a codepoint int and look
/// it up against this catalog, falling back to a default when unknown.
const List<IconData> kSubjectIcons = [
  Icons.book_outlined,
  Icons.menu_book_rounded,
  Icons.auto_stories_rounded,
  Icons.calculate_rounded,
  Icons.science_rounded,
  Icons.psychology_rounded,
  Icons.code_rounded,
  Icons.language_rounded,
  Icons.history_edu_rounded,
  Icons.palette_outlined,
  Icons.music_note_rounded,
  Icons.sports_soccer_rounded,
];

/// Default icon codepoint — `Icons.book_outlined`.
const int kDefaultSubjectIconCodePoint = 0xeedf;

/// Default color — AppColors.primary (via ARGB32)
const int kDefaultSubjectColor = 0xFF285C4D;

/// Student study preference / priority for a subject.
enum SubjectPreference {
  high('High', 1.5),
  normal('Normal', 1.0),
  low('Low', 0.6);

  const SubjectPreference(this.label, this.weightMultiplier);
  final String label;
  final double weightMultiplier;
}

/// A real academic subject with visual identity and persistence.
class Subject {
  static const List<IconData> availableIcons = kSubjectIcons;
  static const int defaultColor = kDefaultSubjectColor;
  static const int defaultIconCodePoint = kDefaultSubjectIconCodePoint;
  Subject({
    required this.id,
    required this.name,
    this.shortName = '',
    this.description = '',
    int? color,
    int? iconCodePoint,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.archived = false,
    this.preference = SubjectPreference.normal,
    this.catalogSubjectId,
    this.catalogCourseId,
    this.catalogVersion,
    this.code,
    this.credits,
  }) : color = color ?? AppColors.primary.toARGB32(),
       iconCodePoint = iconCodePoint ?? kDefaultSubjectIconCodePoint,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String shortName;
  final String description;
  final int color;
  final int iconCodePoint;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final SubjectPreference preference;

  // Optional Course Catalog reference metadata
  final String? catalogSubjectId;
  final String? catalogCourseId;
  final String? catalogVersion;
  final String? code;
  final double? credits;

  bool get isCatalogLinked => catalogSubjectId != null && catalogSubjectId!.isNotEmpty;

  bool get isActive => !archived;
  Color get colorValue => Color(color);

  /// Const-safe icon resolution: looks the stored codepoint up in
  /// [kSubjectIcons] and falls back to the default icon otherwise.
  IconData get icon {
    for (final candidate in kSubjectIcons) {
      if (candidate.codePoint == iconCodePoint) return candidate;
    }
    return kSubjectIcons.first;
  }

  String get displayName => shortName.isNotEmpty ? shortName : name;

  Subject copyWith({
    String? name,
    String? shortName,
    String? description,
    int? color,
    int? iconCodePoint,
    bool? archived,
    SubjectPreference? preference,
    String? catalogSubjectId,
    String? catalogCourseId,
    String? catalogVersion,
    String? code,
    double? credits,
    bool clearShortName = false,
    bool clearDescription = false,
    bool clearArchived = false,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      shortName: clearShortName ? '' : (shortName ?? this.shortName),
      description: clearDescription ? '' : (description ?? this.description),
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      archived: clearArchived ? false : (archived ?? this.archived),
      preference: preference ?? this.preference,
      catalogSubjectId: catalogSubjectId ?? this.catalogSubjectId,
      catalogCourseId: catalogCourseId ?? this.catalogCourseId,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      code: code ?? this.code,
      credits: credits ?? this.credits,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'description': description,
    'color': color,
    'iconCodePoint': iconCodePoint,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'archived': archived,
    'preference': preference.name,
    if (catalogSubjectId != null) 'catalogSubjectId': catalogSubjectId,
    if (catalogCourseId != null) 'catalogCourseId': catalogCourseId,
    if (catalogVersion != null) 'catalogVersion': catalogVersion,
    if (code != null) 'code': code,
    if (credits != null) 'credits': credits,
  };

  factory Subject.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;
    return Subject(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      shortName: (json['shortName'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      color: (json['color'] as int?) ?? AppColors.primary.toARGB32(),
      iconCodePoint:
          (json['iconCodePoint'] as int?) ?? kDefaultSubjectIconCodePoint,
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      archived: (json['archived'] as bool?) ?? false,
      preference: SubjectPreference.values.firstWhere(
        (p) => p.name == json['preference'],
        orElse: () => SubjectPreference.normal,
      ),
      catalogSubjectId: json['catalogSubjectId'] as String?,
      catalogCourseId: json['catalogCourseId'] as String?,
      catalogVersion: json['catalogVersion'] as String?,
      code: json['code'] as String?,
      credits: (json['credits'] as num?)?.toDouble(),
    );
  }
}
