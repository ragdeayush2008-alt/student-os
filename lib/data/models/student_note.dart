import 'package:flutter/foundation.dart';

/// Represents a personal academic note authored or curated by the student.
///
/// Notes act as the personal academic memory layer in Student OS, linking
/// directly to subjects, chapters, topics, and academic resources without
/// conflating personal learning notes with tasks, exams, or automated mastery.
@immutable
class StudentNote {
  StudentNote({
    required this.id,
    this.userId,
    required this.title,
    this.content = '',
    String? plainText,
    this.subjectId,
    this.chapterId,
    this.topicId,
    List<String>? resourceIds,
    List<String>? tags,
    this.isPinned = false,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastViewedAt,
    int? wordCount,
  })  : plainText = plainText ?? extractPlainText(content),
        resourceIds = List.unmodifiable(resourceIds ?? const <String>[]),
        tags = List.unmodifiable(normalizeTags(tags ?? const <String>[])),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now(),
        wordCount = wordCount ?? computeWordCount(content);

  final String id;
  final String? userId;
  final String title;
  final String content;
  final String plainText;
  final String? subjectId;
  final String? chapterId;
  final String? topicId;
  final List<String> resourceIds;
  final List<String> tags;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastViewedAt;
  final int wordCount;

  // ─── Convenience Getters ─────────────────────────────────────────────

  bool get isActive => !isArchived;
  bool get hasSubject => subjectId != null && subjectId!.trim().isNotEmpty;
  bool get hasChapter => chapterId != null && chapterId!.trim().isNotEmpty;
  bool get hasTopic => topicId != null && topicId!.trim().isNotEmpty;
  bool get hasResources => resourceIds.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  /// Estimated reading time in minutes (assuming ~200 words per minute).
  int get estimatedReadMinutes => (wordCount / 200).ceil().clamp(1, 120);

  /// A brief 1-line snippet of the note content.
  String get snippet {
    final text = plainText.trim();
    if (text.isEmpty) return 'No additional text';
    if (text.length <= 120) return text;
    return '${text.substring(0, 117)}...';
  }

  // ─── Deterministic Utilities ─────────────────────────────────────────

  /// Computes the word count deterministically from plain text.
  static int computeWordCount(String raw) {
    if (raw.trim().isEmpty) return 0;
    final words = raw.trim().split(RegExp(r'\s+'));
    return words.where((w) => w.isNotEmpty).length;
  }

  /// Extracts readable plain text by stripping common Markdown / notation symbols.
  static String extractPlainText(String raw) {
    if (raw.isEmpty) return '';
    var text = raw;
    // Remove Markdown headers (# Header)
    text = text.replaceAll(RegExp(r'^#+\s+', multiLine: true), '');
    // Remove bold/italics markers (*, _)
    text = text.replaceAll(RegExp(r'[\*_]{1,3}'), '');
    // Remove strikethrough (~~)
    text = text.replaceAll(RegExp(r'~{2}'), '');
    // Remove blockquotes (> )
    text = text.replaceAll(RegExp(r'^>\s+', multiLine: true), '');
    // Remove bullet and checklist markers (- [ ] , - [x] , * , - , + )
    text = text.replaceAll(RegExp(r'^[\*\-\+]\s+(\[[ xX]\]\s+)?', multiLine: true), '');
    // Remove numbered list markers (1. )
    text = text.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    // Remove inline code ticks (`code`)
    text = text.replaceAll(RegExp(r'`{1,3}'), '');
    // Remove Markdown links [label](url) -> label
    text = text.replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\)'), (m) => m.group(1) ?? '');
    // Normalize excessive newlines and whitespace
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return text;
  }

  /// Normalizes, cleans, and deduplicates tags.
  static List<String> normalizeTags(List<String> rawTags) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in rawTags) {
      var tag = raw.trim().toLowerCase();
      if (tag.startsWith('#')) {
        tag = tag.substring(1).trim();
      }
      if (tag.isNotEmpty && seen.add(tag)) {
        result.add(tag);
      }
    }
    return result;
  }

  // ─── copyWith ────────────────────────────────────────────────────────

  StudentNote copyWith({
    String? title,
    String? content,
    String? plainText,
    String? subjectId,
    String? chapterId,
    String? topicId,
    List<String>? resourceIds,
    List<String>? tags,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastViewedAt,
    int? wordCount,
    String? userId,
    bool clearSubjectId = false,
    bool clearChapterId = false,
    bool clearTopicId = false,
    bool clearLastViewedAt = false,
    bool clearUserId = false,
  }) {
    final newContent = content ?? this.content;
    return StudentNote(
      id: id,
      userId: clearUserId ? null : (userId ?? this.userId),
      title: title ?? this.title,
      content: newContent,
      plainText: plainText ?? (content != null ? extractPlainText(newContent) : this.plainText),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      chapterId: clearChapterId ? null : (chapterId ?? this.chapterId),
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      resourceIds: resourceIds ?? this.resourceIds,
      tags: tags != null ? normalizeTags(tags) : this.tags,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastViewedAt: clearLastViewedAt ? null : (lastViewedAt ?? this.lastViewedAt),
      wordCount: wordCount ?? (content != null ? computeWordCount(newContent) : this.wordCount),
    );
  }

  // ─── Serialization ───────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'userId': userId,
        'title': title,
        'content': content,
        'plainText': plainText,
        if (subjectId != null) 'subjectId': subjectId,
        if (chapterId != null) 'chapterId': chapterId,
        if (topicId != null) 'topicId': topicId,
        'resourceIds': resourceIds,
        'tags': tags,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (lastViewedAt != null) 'lastViewedAt': lastViewedAt!.toIso8601String(),
        'wordCount': wordCount,
      };

  factory StudentNote.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final rawContent = json['content'] is String ? json['content'] as String : '';
    final rawPlainText = json['plainText'] is String ? json['plainText'] as String : null;
    final rawWordCount = json['wordCount'] is int ? json['wordCount'] as int : null;

    final created = parseDate(json['createdAt']) ?? DateTime.now();
    final updated = parseDate(json['updatedAt']) ?? created;
    final lastViewed = parseDate(json['lastViewedAt']);

    List<String> parseStringList(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return const <String>[];
    }

    return StudentNote(
      id: json['id'] is String
          ? json['id'] as String
          : (json['id'] != null ? json['id'].toString() : 'note_${DateTime.now().millisecondsSinceEpoch}'),
      userId: json['userId'] is String ? json['userId'] as String : null,
      title: json['title'] is String ? json['title'] as String : '',
      content: rawContent,
      plainText: rawPlainText ?? extractPlainText(rawContent),
      subjectId: json['subjectId'] is String ? json['subjectId'] as String : null,
      chapterId: json['chapterId'] is String ? json['chapterId'] as String : null,
      topicId: json['topicId'] is String ? json['topicId'] as String : null,
      resourceIds: parseStringList(json['resourceIds']),
      tags: normalizeTags(parseStringList(json['tags'])),
      isPinned: json['isPinned'] is bool ? json['isPinned'] as bool : false,
      isArchived: json['isArchived'] is bool ? json['isArchived'] as bool : false,
      createdAt: created,
      updatedAt: updated,
      lastViewedAt: lastViewed,
      wordCount: rawWordCount ?? computeWordCount(rawContent),
    );
  }

  // ─── Equality & HashCode ─────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentNote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          content == other.content &&
          subjectId == other.subjectId &&
          chapterId == other.chapterId &&
          topicId == other.topicId &&
          isPinned == other.isPinned &&
          isArchived == other.isArchived &&
          wordCount == other.wordCount &&
          listEquals(resourceIds, other.resourceIds) &&
          listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        title,
        content,
        subjectId,
        chapterId,
        topicId,
        isPinned,
        isArchived,
        wordCount,
        Object.hashAll(resourceIds),
        Object.hashAll(tags),
      );
}
