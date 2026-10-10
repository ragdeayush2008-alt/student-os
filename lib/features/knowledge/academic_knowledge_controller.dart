import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/chapter.dart';
import '../../data/models/topic.dart';
import '../auth/auth_service.dart';
import '../notes/student_note_controller.dart';

class AcademicKnowledgeController extends ChangeNotifier {
  AcademicKnowledgeController._();

  static final AcademicKnowledgeController instance =
      AcademicKnowledgeController._();

  static const _chaptersKey = 'academic_chapters';
  static const _topicsKey = 'academic_topics';

  List<Chapter> _chapters = [];
  List<Topic> _topics = [];
  bool _loaded = false;
  bool _disposed = false;

  List<Chapter> get chapters => List.unmodifiable(_chapters);
  List<Topic> get topics => List.unmodifiable(_topics);
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void clearData() {
    _chapters.clear();
    _topics.clear();
    _loaded = false;
    notifyListeners();
  }

  List<Chapter> chaptersForSubject(String subjectId) {
    return _chapters
        .where((c) => c.subjectId == subjectId)
        .toList()
      ..sort((a, b) {
        final cmp = a.order.compareTo(b.order);
        if (cmp != 0) return cmp;
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  List<Topic> topicsForChapter(String chapterId) {
    return _topics
        .where((t) => t.chapterId == chapterId)
        .toList()
      ..sort((a, b) {
        final cmp = a.order.compareTo(b.order);
        if (cmp != 0) return cmp;
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  List<Topic> topicsForSubject(String subjectId) {
    final subjectChapters = chaptersForSubject(subjectId);
    final chapterOrderMap = <String, int>{};
    for (int i = 0; i < subjectChapters.length; i++) {
      chapterOrderMap[subjectChapters[i].id] = i;
    }

    return _topics
        .where((t) => t.subjectId == subjectId)
        .toList()
      ..sort((a, b) {
        final chOrderA = chapterOrderMap[a.chapterId] ?? 999;
        final chOrderB = chapterOrderMap[b.chapterId] ?? 999;
        final cmpCh = chOrderA.compareTo(chOrderB);
        if (cmpCh != 0) return cmpCh;
        final cmp = a.order.compareTo(b.order);
        if (cmp != 0) return cmp;
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  Chapter? chapterById(String id) {
    try {
      return _chapters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Topic? topicById(String id) {
    try {
      return _topics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  bool hasKnowledge(String subjectId) {
    return _chapters.any((c) => c.subjectId == subjectId) ||
        _topics.any((t) => t.subjectId == subjectId);
  }

  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
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
    if (uid == null) {
      _chapters = [];
      _topics = [];
      return;
    }
    final chaptersList = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _chaptersKey,
    );
    if (chaptersList != null) {
      _chapters = chaptersList
          .whereType<Map<String, dynamic>>()
          .map((j) {
            try {
              return Chapter.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<Chapter>()
          .toList();
    } else {
      _chapters = [];
    }

    final topicsList = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _topicsKey,
    );
    if (topicsList != null) {
      _topics = topicsList
          .whereType<Map<String, dynamic>>()
          .map((j) {
            try {
              return Topic.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<Topic>()
          .toList();
    } else {
      _topics = [];
    }
  }

  Future<void> _saveChaptersLocal() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _chaptersKey,
      list: _chapters.map((c) => c.toJson()).toList(),
    );
  }

  Future<void> _saveTopicsLocal() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _topicsKey,
      list: _topics.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      final chResponse = await client
          .from('academic_chapters')
          .select()
          .eq('user_id', uid)
          .order('order');
      if (chResponse.isNotEmpty) {
        _chapters = chResponse.map((j) => Chapter.fromJson(j)).toList();
        await _saveChaptersLocal();
      }

      final topResponse = await client
          .from('academic_topics')
          .select()
          .eq('user_id', uid)
          .order('order');
      if (topResponse.isNotEmpty) {
        _topics = topResponse.map((j) => Topic.fromJson(j)).toList();
        await _saveTopicsLocal();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicKnowledgeController] Cloud load failed: $e');
    }
  }

  Future<void> _attemptCloudSaveChapters() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      await client.from('academic_chapters').upsert(
            _chapters
                .map((c) => {...c.toJson(), 'user_id': uid})
                .toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicKnowledgeController] Cloud save chapters failed: $e');
    }
  }

  Future<void> _attemptCloudSaveTopics() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      await client.from('academic_topics').upsert(
            _topics
                .map((t) => {...t.toJson(), 'user_id': uid})
                .toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicKnowledgeController] Cloud save topics failed: $e');
    }
  }

  Future<Chapter> createChapter({
    required String subjectId,
    required String title,
    String description = '',
    int? order,
    int? estimatedMinutes,
  }) async {
    final subjectChapters = chaptersForSubject(subjectId);
    final nextOrder = order ?? (subjectChapters.isEmpty ? 0 : subjectChapters.last.order + 1);

    final chapter = Chapter(
      id: 'ch_${DateTime.now().millisecondsSinceEpoch}_${_chapters.length + 1}',
      subjectId: subjectId,
      title: title.trim(),
      description: description.trim(),
      order: nextOrder,
      estimatedMinutes: estimatedMinutes,
      userId: _userId,
    );

    _chapters.add(chapter);
    await _saveChaptersLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSaveChapters();
    return chapter;
  }

  Future<void> updateChapter(Chapter updated) async {
    final index = _chapters.indexWhere((c) => c.id == updated.id);
    if (index < 0) return;
    _chapters[index] = updated;
    await _saveChaptersLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSaveChapters();
  }

  Future<void> deleteChapter(String chapterId) async {
    _chapters.removeWhere((c) => c.id == chapterId);
    _topics.removeWhere((t) => t.chapterId == chapterId);
    await _saveChaptersLocal();
    await _saveTopicsLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSaveChapters();
    _attemptCloudSaveTopics();
    await StudentNoteController.instance.clearChapterReference(chapterId);
  }

  Future<void> reorderChapters(
    String subjectId,
    List<String> orderedChapterIds,
  ) async {
    for (int i = 0; i < orderedChapterIds.length; i++) {
      final index = _chapters.indexWhere((c) => c.id == orderedChapterIds[i]);
      if (index >= 0) {
        _chapters[index] = _chapters[index].copyWith(order: i);
      }
    }
    await _saveChaptersLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSaveChapters();
  }

  Future<Topic> createTopic({
    required String chapterId,
    required String subjectId,
    required String title,
    String description = '',
    int? order,
    int estimatedMinutes = 35,
    TopicImportance importance = TopicImportance.normal,
  }) async {
    final chapterTopics = topicsForChapter(chapterId);
    final nextOrder = order ?? (chapterTopics.isEmpty ? 0 : chapterTopics.last.order + 1);

    final topic = Topic(
      id: 'top_${DateTime.now().millisecondsSinceEpoch}_${_topics.length + 1}',
      chapterId: chapterId,
      subjectId: subjectId,
      title: title.trim(),
      description: description.trim(),
      order: nextOrder,
      estimatedMinutes: estimatedMinutes,
      importance: importance,
      userId: _userId,
    );

    _topics.add(topic);
    await _saveTopicsLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSaveTopics();
    return topic;
  }

  Future<void> updateTopic(Topic updated) async {
    final index = _topics.indexWhere((t) => t.id == updated.id);
    if (index < 0) return;
    _topics[index] = updated;
    await _saveTopicsLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSaveTopics();
  }

  Future<void> deleteTopic(String topicId) async {
    _topics.removeWhere((t) => t.id == topicId);
    await _saveTopicsLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSaveTopics();
    await StudentNoteController.instance.clearTopicReference(topicId);
  }

  Future<void> reorderTopics(
    String chapterId,
    List<String> orderedTopicIds,
  ) async {
    for (int i = 0; i < orderedTopicIds.length; i++) {
      final index = _topics.indexWhere((t) => t.id == orderedTopicIds[i]);
      if (index >= 0) {
        _topics[index] = _topics[index].copyWith(order: i);
      }
    }
    await _saveTopicsLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSaveTopics();
  }

  Future<void> clearSubjectKnowledge(String subjectId) async {
    _chapters.removeWhere((c) => c.subjectId == subjectId);
    _topics.removeWhere((t) => t.subjectId == subjectId);
    await _saveChaptersLocal();
    await _saveTopicsLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSaveChapters();
    _attemptCloudSaveTopics();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
