import 'package:flutter/material.dart';

/// Type of academic resource.
enum ResourceType {
  note('Note', Icons.sticky_note_2_rounded),
  link('Link', Icons.link_rounded),
  document('Document', Icons.description_rounded),
  video('Video', Icons.play_circle_rounded),
  article('Article', Icons.article_rounded),
  revision('Revision', Icons.replay_rounded),
  other('Other', Icons.folder_rounded);

  const ResourceType(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// A saved academic resource for Student OS.
///
/// Supports notes, links, documents, videos, articles, and revision material.
/// Optionally links to a subject and/or an exam. Mutable pattern with
/// backward-compatible deserialization for persisted data.
class AcademicResource {
  AcademicResource({
    required this.id,
    required this.title,
    this.description = '',
    this.resourceType = ResourceType.note,
    this.subjectId,
    this.examId,
    this.reference,
    this.content,
    this.tags = const [],
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastAccessedAt,
    this.accessCount = 0,
    this.archived = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String description;
  final ResourceType resourceType;
  final String? subjectId;
  final String? examId;

  /// URL or reference string for the resource.
  final String? reference;

  /// Body content (used for notes).
  final String? content;

  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAccessedAt;
  final int accessCount;
  final bool archived;

  // ─── Convenience getters ───────────────────────────────────────────

  bool get isActive => !archived;

  bool get isNote => resourceType == ResourceType.note;

  bool get isLink => resourceType == ResourceType.link;

  bool get isDocument => resourceType == ResourceType.document;

  bool get isRevision => resourceType == ResourceType.revision;

  bool get hasTags => tags.isNotEmpty;

  bool get hasSubject => subjectId != null;

  bool get hasExam => examId != null;

  bool get hasContent => content != null && content!.trim().isNotEmpty;

  // ─── Tag normalization ─────────────────────────────────────────────

  /// Lowercases, trims, and deduplicates the given tags while preserving
  /// the original order.
  static List<String> normalizeTags(List<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in tags) {
      final tag = raw.trim().toLowerCase();
      if (tag.isNotEmpty && seen.add(tag)) {
        result.add(tag);
      }
    }
    return result;
  }

  // ─── copyWith ──────────────────────────────────────────────────────

  AcademicResource copyWith({
    String? title,
    String? description,
    ResourceType? resourceType,
    String? subjectId,
    String? examId,
    String? reference,
    String? content,
    List<String>? tags,
    bool? isFavorite,
    DateTime? lastAccessedAt,
    int? accessCount,
    bool? archived,
    bool clearSubjectId = false,
    bool clearExamId = false,
    bool clearReference = false,
    bool clearContent = false,
    bool clearLastAccessedAt = false,
  }) {
    return AcademicResource(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      resourceType: resourceType ?? this.resourceType,
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      examId: clearExamId ? null : (examId ?? this.examId),
      reference: clearReference ? null : (reference ?? this.reference),
      content: clearContent ? null : (content ?? this.content),
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastAccessedAt: clearLastAccessedAt
          ? null
          : (lastAccessedAt ?? this.lastAccessedAt),
      accessCount: accessCount ?? this.accessCount,
      archived: archived ?? this.archived,
    );
  }

  // ─── Serialization ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'resourceType': resourceType.name,
    'subjectId': subjectId,
    'examId': examId,
    'reference': reference,
    'content': content,
    'tags': tags,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    'accessCount': accessCount,
    'archived': archived,
  };

  /// Backward-compatible factory — safely deserializes existing resources
  /// that lack any optional fields (reference, content, tags, favorite,
  /// dates, access count, archived).
  factory AcademicResource.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null;

    return AcademicResource(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      resourceType: ResourceType.values.firstWhere(
        (t) => t.name == json['resourceType'],
        orElse: () => ResourceType.note,
      ),
      subjectId: json['subjectId'] as String?,
      examId: json['examId'] as String?,
      reference: json['reference'] as String?,
      content: json['content'] as String?,
      tags: normalizeTags(
        (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
            const [],
      ),
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      accessCount: (json['accessCount'] as int?) ?? 0,
      archived: (json['archived'] as bool?) ?? false,
    );
  }
}
