import '../../../data/models/chapter.dart';
import '../../../data/models/student_note.dart';
import '../../../data/models/subject.dart';
import '../../../data/models/topic.dart';

/// Deterministic ranking score container for a searched note.
class NoteSearchResult {
  const NoteSearchResult({
    required this.note,
    required this.score,
    this.matchedField,
  });

  final StudentNote note;
  final int score;
  final String? matchedField;
}

/// Deterministic, offline-first local search engine for [StudentNote].
abstract final class NoteSearchEngine {
  /// Normalizes a query or target string by lowercasing, trimming,
  /// and stripping punctuation.
  static String normalize(String text) {
    if (text.isEmpty) return '';
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Searches and ranks notes deterministically according to the ranking specification:
  /// 1. Exact title match (Score: 1000)
  /// 2. Title prefix match (Score: 800)
  /// 3. Title substring match (Score: 600)
  /// 4. Tag exact / substring match (Score: 400)
  /// 5. Topic / Chapter / Subject match (Score: 200)
  /// 6. Content match (Score: 100)
  ///
  /// In the event of a tie in score, the more recently updated note ranks higher.
  static List<StudentNote> search({
    required List<StudentNote> notes,
    required String query,
    String? subjectId,
    String? chapterId,
    String? topicId,
    String? tag,
    bool includeArchived = false,
    List<Subject> subjects = const [],
    List<Chapter> chapters = const [],
    List<Topic> topics = const [],
  }) {
    // 1. Initial filtering by active status & context
    final filtered = notes.where((note) {
      if (!includeArchived && note.isArchived) return false;
      if (subjectId != null && note.subjectId != subjectId) return false;
      if (chapterId != null && note.chapterId != chapterId) return false;
      if (topicId != null && note.topicId != topicId) return false;
      if (tag != null && !note.tags.contains(tag.toLowerCase().trim())) return false;
      return true;
    }).toList();

    final q = normalize(query);
    if (q.isEmpty) {
      // Return filtered notes sorted by pinned then updated descending
      return filtered..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    }

    // Build lookup maps for subjects, chapters, topics for fast hierarchy matching
    final subjectMap = {for (final s in subjects) s.id: normalize(s.displayName)};
    final chapterMap = {for (final c in chapters) c.id: normalize(c.title)};
    final topicMap = {for (final t in topics) t.id: normalize(t.title)};

    final scored = <NoteSearchResult>[];

    for (final note in filtered) {
      final normalizedTitle = normalize(note.title);
      final normalizedContent = normalize(note.plainText);

      int score = 0;
      String? matched;

      // 1. Exact title match
      if (normalizedTitle == q) {
        score = 1000;
        matched = 'title_exact';
      }
      // 2. Title prefix
      else if (normalizedTitle.startsWith(q)) {
        score = 800;
        matched = 'title_prefix';
      }
      // 3. Title substring / word boundary
      else if (normalizedTitle.contains(q)) {
        score = 600;
        matched = 'title_substring';
      }
      // 4. Tag match
      else if (note.tags.any((t) => normalize(t) == q || normalize(t).contains(q))) {
        score = 400;
        matched = 'tag';
      }
      // 5. Topic / Chapter / Subject match
      else if (_matchesHierarchy(note, q, subjectMap, chapterMap, topicMap)) {
        score = 200;
        matched = 'hierarchy';
      }
      // 6. Content match
      else if (normalizedContent.contains(q)) {
        score = 100;
        matched = 'content';
      }

      if (score > 0) {
        // Boost slightly if pinned
        if (note.isPinned) {
          score += 10;
        }
        scored.add(NoteSearchResult(note: note, score: score, matchedField: matched));
      }
    }

    // Sort by score descending, then by updatedAt descending
    scored.sort((a, b) {
      final diff = b.score.compareTo(a.score);
      if (diff != 0) return diff;
      return b.note.updatedAt.compareTo(a.note.updatedAt);
    });

    return scored.map((r) => r.note).toList();
  }

  static bool _matchesHierarchy(
    StudentNote note,
    String q,
    Map<String, String> subjectMap,
    Map<String, String> chapterMap,
    Map<String, String> topicMap,
  ) {
    if (note.subjectId != null) {
      final sName = subjectMap[note.subjectId!];
      if (sName != null && sName.contains(q)) return true;
    }
    if (note.chapterId != null) {
      final cName = chapterMap[note.chapterId!];
      if (cName != null && cName.contains(q)) return true;
    }
    if (note.topicId != null) {
      final tName = topicMap[note.topicId!];
      if (tName != null && tName.contains(q)) return true;
    }
    return false;
  }
}
