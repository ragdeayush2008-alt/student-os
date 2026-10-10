import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/student_note.dart';
import '../auth/auth_service.dart';
import '../knowledge/academic_knowledge_controller.dart';
import '../subjects/subject_controller.dart';
import 'services/note_search_engine.dart';

/// Single source of truth for student-authored notes.
///
/// Ensures offline-first, user-isolated persistence and provides query
/// methods across the academic hierarchy (Subject -> Chapter -> Topic -> Resource).
class StudentNoteController extends ChangeNotifier {
  StudentNoteController._();

  static final StudentNoteController instance = StudentNoteController._();

  static const String _storageKey = 'student_notes';

  List<StudentNote> _notes = [];
  bool _loaded = false;
  bool _disposed = false;

  List<StudentNote> get notes => List.unmodifiable(_notes);
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  /// Clears in-memory notes state without wiping persistent storage.
  void clearData() {
    _notes.clear();
    _loaded = false;
    if (!_disposed) notifyListeners();
  }

  // ─── Query Accessors ─────────────────────────────────────────────────

  List<StudentNote> get allActiveNotes =>
      _notes.where((n) => n.isActive).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<StudentNote> get pinnedNotes =>
      allActiveNotes.where((n) => n.isPinned).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<StudentNote> get recentNotes =>
      allActiveNotes.take(10).toList();

  List<StudentNote> get archivedNotes =>
      _notes.where((n) => n.isArchived).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  StudentNote? noteById(String id) =>
      _notes.where((n) => n.id == id).firstOrNull;

  StudentNote? getNote(String id) => noteById(id);

  List<StudentNote> notesForSubject(String subjectId) =>
      allActiveNotes.where((n) => n.subjectId == subjectId).toList()
        ..sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });

  List<StudentNote> notesForChapter(String chapterId) =>
      allActiveNotes.where((n) => n.chapterId == chapterId).toList()
        ..sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });

  List<StudentNote> notesForTopic(String topicId) =>
      allActiveNotes.where((n) => n.topicId == topicId).toList()
        ..sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });

  List<StudentNote> notesForResource(String resourceId) =>
      allActiveNotes.where((n) => n.resourceIds.contains(resourceId)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<StudentNote> notesByTag(String tag) {
    final t = tag.trim().toLowerCase();
    return allActiveNotes.where((n) => n.tags.contains(t)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<StudentNote> notesUpdatedToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return allActiveNotes
        .where((n) => n.updatedAt.isAfter(today))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<StudentNote> recentlyViewedNotes() {
    return allActiveNotes
        .where((n) => n.lastViewedAt != null)
        .toList()
      ..sort((a, b) => b.lastViewedAt!.compareTo(a.lastViewedAt!));
  }

  Set<String> get allTags {
    final set = <String>{};
    for (final note in allActiveNotes) {
      set.addAll(note.tags);
    }
    return set;
  }

  int get totalCount => _notes.length;
  int get activeCount => allActiveNotes.length;
  int get pinnedCount => pinnedNotes.length;
  int get archivedCount => archivedNotes.length;
  bool get hasNotes => allActiveNotes.isNotEmpty;

  // ─── Search ──────────────────────────────────────────────────────────

  List<StudentNote> searchNotes(
    String query, {
    String? subjectId,
    String? chapterId,
    String? topicId,
    String? tag,
    bool includeArchived = false,
  }) {
    final subjects = SubjectController.instance.subjects;
    final chapters = AcademicKnowledgeController.instance.chapters;
    final topics = AcademicKnowledgeController.instance.topics;

    return NoteSearchEngine.search(
      notes: _notes,
      query: query,
      subjectId: subjectId,
      chapterId: chapterId,
      topicId: topicId,
      tag: tag,
      includeArchived: includeArchived,
      subjects: subjects,
      chapters: chapters,
      topics: topics,
    );
  }

  // ─── Local-First Persistence ─────────────────────────────────────────

  Future<void> load() async {
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    await _loadLocal();
    _loaded = true;
    if (!_disposed) notifyListeners();
    _attemptCloudLoad();
  }

  Future<void> _loadLocal() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final list = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _storageKey,
      );
      if (list != null) {
        _notes = list.map((j) => StudentNote.fromJson(j)).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudentNoteController] Local load error: $e');
    }
  }

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await StorageService.instance.saveJsonList(
        userId: uid,
        key: _storageKey,
        list: _notes.map((n) => n.toJson()).toList(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[StudentNoteController] Local save error: $e');
    }
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      final response = await client
          .from('student_notes')
          .select()
          .eq('user_id', uid)
          .order('updated_at', ascending: false);
      if (response.isNotEmpty) {
        _notes = response.map((j) => StudentNote.fromJson(j)).toList();
        await _saveLocal();
        if (!_disposed) notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudentNoteController] Cloud load failed: $e');
    }
  }

  Future<void> _attemptCloudSave() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      await client.from('student_notes').upsert(
            _notes.map((n) => {...n.toJson(), 'user_id': uid}).toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('[StudentNoteController] Cloud save failed: $e');
    }
  }

  // ─── Mutations ───────────────────────────────────────────────────────

  Future<StudentNote> createNote({
    required String title,
    String content = '',
    String? plainText,
    String? subjectId,
    String? chapterId,
    String? topicId,
    List<String> resourceIds = const [],
    List<String> tags = const [],
    bool isPinned = false,
  }) async {
    final uid = _userId;
    final note = StudentNote(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      title: title.trim(),
      content: content,
      plainText: plainText,
      subjectId: subjectId,
      chapterId: chapterId,
      topicId: topicId,
      resourceIds: resourceIds,
      tags: tags,
      isPinned: isPinned,
      isArchived: false,
    );

    _notes.insert(0, note);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
    return note;
  }

  Future<void> updateNote(StudentNote updated) async {
    final index = _notes.indexWhere((n) => n.id == updated.id);
    if (index < 0) return;

    final noteToSave = updated.copyWith(
      updatedAt: DateTime.now(),
      userId: updated.userId ?? _userId,
    );
    _notes[index] = noteToSave;
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> archiveNote(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index < 0) return;
    _notes[index] = _notes[index].copyWith(isArchived: true);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> restoreNote(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index < 0) return;
    _notes[index] = _notes[index].copyWith(isArchived: false);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> togglePinned(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index < 0) return;
    _notes[index] = _notes[index].copyWith(
      isPinned: !_notes[index].isPinned,
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> markViewed(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index < 0) return;
    _notes[index] = _notes[index].copyWith(
      lastViewedAt: DateTime.now(),
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> attachResource(String noteId, String resourceId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index < 0) return;
    final current = _notes[index];
    if (current.resourceIds.contains(resourceId)) return;
    final updatedList = List<String>.from(current.resourceIds)..add(resourceId);
    _notes[index] = current.copyWith(resourceIds: updatedList);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> detachResource(String noteId, String resourceId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index < 0) return;
    final current = _notes[index];
    if (!current.resourceIds.contains(resourceId)) return;
    final updatedList = List<String>.from(current.resourceIds)..remove(resourceId);
    _notes[index] = current.copyWith(resourceIds: updatedList);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  // ─── Reference Cleaning (Preserves Notes, unlinks IDs) ───────────────

  Future<void> clearSubjectReference(String subjectId) async {
    var changed = false;
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].subjectId == subjectId) {
        _notes[i] = _notes[i].copyWith(clearSubjectId: true);
        changed = true;
      }
    }
    if (changed) {
      await _saveLocal();
      if (!_disposed) notifyListeners();
      _attemptCloudSave();
    }
  }

  Future<void> clearChapterReference(String chapterId) async {
    var changed = false;
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].chapterId == chapterId) {
        _notes[i] = _notes[i].copyWith(clearChapterId: true);
        changed = true;
      }
    }
    if (changed) {
      await _saveLocal();
      if (!_disposed) notifyListeners();
      _attemptCloudSave();
    }
  }

  Future<void> clearTopicReference(String topicId) async {
    var changed = false;
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].topicId == topicId) {
        _notes[i] = _notes[i].copyWith(clearTopicId: true);
        changed = true;
      }
    }
    if (changed) {
      await _saveLocal();
      if (!_disposed) notifyListeners();
      _attemptCloudSave();
    }
  }

  Future<void> clearResourceReference(String resourceId) async {
    var changed = false;
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].resourceIds.contains(resourceId)) {
        final updated = List<String>.from(_notes[i].resourceIds)..remove(resourceId);
        _notes[i] = _notes[i].copyWith(resourceIds: updated);
        changed = true;
      }
    }
    if (changed) {
      await _saveLocal();
      if (!_disposed) notifyListeners();
      _attemptCloudSave();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
