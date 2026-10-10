import 'package:flutter/foundation.dart';

/// User-scoped active academic course / exam track selection in Student OS.
///
/// Encapsulates the complete hierarchical selection and ensures safe,
/// non-destructive academic context switching.
@immutable
class ActiveCourseSelection {
  ActiveCourseSelection({
    required this.userId,
    required this.categoryId,
    required this.familyId,
    required this.programId,
    required this.programTitle,
    required this.levelId,
    required this.levelTitle,
    this.subLevelId,
    this.subLevelTitle,
    this.year = '2026',
    this.selectedPaperIds = const [],
    this.authority,
    this.institution,
    DateTime? selectedAt,
    DateTime? updatedAt,
    this.metadata,
  })  : selectedAt = selectedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? selectedAt ?? DateTime.now();

  final String userId;
  final String categoryId;
  final String familyId;
  final String programId;
  final String programTitle;
  final String levelId;
  final String levelTitle;
  final String? subLevelId;
  final String? subLevelTitle;
  final String year;
  final List<String> selectedPaperIds;
  final String? authority;
  final String? institution;
  final DateTime selectedAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  String get fullDisplayName {
    final buffer = StringBuffer(programTitle);
    if (levelTitle.isNotEmpty && levelTitle != programTitle) {
      buffer.write(' · $levelTitle');
    }
    if (subLevelTitle != null && subLevelTitle!.isNotEmpty) {
      buffer.write(' ($subLevelTitle)');
    }
    if (year.isNotEmpty) {
      buffer.write(' $year');
    }
    return buffer.toString();
  }

  ActiveCourseSelection copyWith({
    String? userId,
    String? categoryId,
    String? familyId,
    String? programId,
    String? programTitle,
    String? levelId,
    String? levelTitle,
    String? subLevelId,
    String? subLevelTitle,
    String? year,
    List<String>? selectedPaperIds,
    String? authority,
    String? institution,
    DateTime? selectedAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ActiveCourseSelection(
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      familyId: familyId ?? this.familyId,
      programId: programId ?? this.programId,
      programTitle: programTitle ?? this.programTitle,
      levelId: levelId ?? this.levelId,
      levelTitle: levelTitle ?? this.levelTitle,
      subLevelId: subLevelId ?? this.subLevelId,
      subLevelTitle: subLevelTitle ?? this.subLevelTitle,
      year: year ?? this.year,
      selectedPaperIds: selectedPaperIds ?? this.selectedPaperIds,
      authority: authority ?? this.authority,
      institution: institution ?? this.institution,
      selectedAt: selectedAt ?? this.selectedAt,
      updatedAt: updatedAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'categoryId': categoryId,
    'familyId': familyId,
    'programId': programId,
    'programTitle': programTitle,
    'levelId': levelId,
    'levelTitle': levelTitle,
    if (subLevelId != null) 'subLevelId': subLevelId,
    if (subLevelTitle != null) 'subLevelTitle': subLevelTitle,
    'year': year,
    if (selectedPaperIds.isNotEmpty) 'selectedPaperIds': selectedPaperIds,
    if (authority != null) 'authority': authority,
    if (institution != null) 'institution': institution,
    'selectedAt': selectedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (metadata != null) 'metadata': metadata,
  };

  factory ActiveCourseSelection.fromJson(Map<String, dynamic> json) {
    return ActiveCourseSelection(
      userId: (json['userId'] as String?) ?? '',
      categoryId: (json['categoryId'] as String?) ?? '',
      familyId: (json['familyId'] as String?) ?? '',
      programId: (json['programId'] as String?) ?? '',
      programTitle: (json['programTitle'] as String?) ?? '',
      levelId: (json['levelId'] as String?) ?? '',
      levelTitle: (json['levelTitle'] as String?) ?? '',
      subLevelId: json['subLevelId'] as String?,
      subLevelTitle: json['subLevelTitle'] as String?,
      year: (json['year'] as String?) ?? '2026',
      selectedPaperIds: (json['selectedPaperIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      authority: json['authority'] as String?,
      institution: json['institution'] as String?,
      selectedAt: json['selectedAt'] != null
          ? DateTime.tryParse(json['selectedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveCourseSelection &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          programId == other.programId &&
          levelId == other.levelId &&
          subLevelId == other.subLevelId &&
          year == other.year;

  @override
  int get hashCode => Object.hash(
    userId,
    programId,
    levelId,
    subLevelId,
    year,
  );
}
