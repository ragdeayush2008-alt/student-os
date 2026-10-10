import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/academic_resource.dart';
import '../auth/auth_service.dart';
import '../notes/student_note_controller.dart';

import 'package:flutter/foundation.dart';

/// Manages the student's academic resources with local persistence and
/// optional Supabase cloud sync.
class ResourceController extends ChangeNotifier {
  ResourceController._();

  /// Clears in-memory state without touching persistent storage.
  void clearData() {
    _resources.clear();
    notifyListeners();
  }

  static final ResourceController instance = ResourceController._();

  static const _resourcesKey = 'academic_resources';

  List<AcademicResource> _resources = [];
  bool _loaded = false;
  bool _disposed = false;

  List<AcademicResource> get resources => List.unmodifiable(_resources);
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Derived queries ────────────────────────────────────────────────

  List<AcademicResource> get allActiveResources =>
      _resources.where((r) => r.isActive).toList();

  List<AcademicResource> get favoriteResources =>
      allActiveResources.where((r) => r.isFavorite).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<AcademicResource> get recentResources {
    final accessed =
        allActiveResources.where((r) => r.lastAccessedAt != null).toList()
          ..sort((a, b) => b.lastAccessedAt!.compareTo(a.lastAccessedAt!));
    return accessed.take(10).toList();
  }

  List<AcademicResource> get noteResources =>
      allActiveResources.where((r) => r.isNote).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<AcademicResource> get linkResources =>
      allActiveResources.where((r) => r.isLink).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<AcademicResource> get revisionResources =>
      allActiveResources.where((r) => r.isRevision).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<AcademicResource> resourcesForSubject(String subjectId) =>
      allActiveResources.where((r) => r.subjectId == subjectId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<AcademicResource> resourcesForExam(String examId) =>
      allActiveResources.where((r) => r.examId == examId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<AcademicResource> resourcesForTag(String tag) =>
      allActiveResources
          .where((r) => r.tags.contains(tag.toLowerCase()))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  /// Real search across title, description, tags, and content.
  List<AcademicResource> searchResources(String query) {
    if (query.trim().isEmpty) return allActiveResources;
    final q = query.toLowerCase().trim();
    return allActiveResources.where((r) {
      if (r.title.toLowerCase().contains(q)) return true;
      if (r.description.toLowerCase().contains(q)) return true;
      if (r.content != null && r.content!.toLowerCase().contains(q)) {
        return true;
      }
      if (r.tags.any((t) => t.contains(q))) return true;
      return false;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// All unique tags across active resources.
  Set<String> get allTags {
    final tags = <String>{};
    for (final r in allActiveResources) {
      tags.addAll(r.tags);
    }
    return tags;
  }

  int get totalCount => _resources.length;
  int get activeCount => allActiveResources.length;
  int get noteCount => noteResources.length;
  int get favoriteCount => favoriteResources.length;
  bool get hasResources => _resources.isNotEmpty;
  bool get hasFavorites => favoriteResources.isNotEmpty;
  bool get hasRecent => recentResources.isNotEmpty;

  // ─── Loading / persistence ──────────────────────────────────────────

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
    if (uid == null) return;
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _resourcesKey,
    );
    if (list != null) {
      _resources = list.map((j) => AcademicResource.fromJson(j)).toList();
    }
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      final response = await client
          .from('academic_resources')
          .select()
          .eq('user_id', uid)
          .order('updated_at', ascending: false);
      if (response.isNotEmpty) {
        _resources = response.map((j) => AcademicResource.fromJson(j)).toList();
        await _saveLocal();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ResourceController] Cloud load failed: $e');
    }
  }

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _resourcesKey,
      list: _resources.map((r) => r.toJson()).toList(),
    );
  }

  Future<void> _attemptCloudSave() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      await client
          .from('academic_resources')
          .upsert(
            _resources.map((r) => {...r.toJson(), 'user_id': uid}).toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('[ResourceController] Cloud save failed: $e');
    }
  }

  // ─── CRUD ───────────────────────────────────────────────────────────

  Future<AcademicResource> createResource({
    required String title,
    String description = '',
    required ResourceType resourceType,
    String? subjectId,
    String? examId,
    String? reference,
    String? content,
    List<String> tags = const [],
    bool isFavorite = false,
  }) async {
    final resource = AcademicResource(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      resourceType: resourceType,
      subjectId: subjectId,
      examId: examId,
      reference: reference?.trim(),
      content: content,
      tags: AcademicResource.normalizeTags(tags),
      isFavorite: isFavorite,
    );
    _resources.add(resource);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
    return resource;
  }

  Future<void> updateResource(AcademicResource updated) async {
    final index = _resources.indexWhere((r) => r.id == updated.id);
    if (index < 0) return;
    final normalized = updated.copyWith(
      tags: AcademicResource.normalizeTags(updated.tags),
    );
    _resources[index] = normalized;
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> deleteResource(String resourceId) async {
    _resources.removeWhere((r) => r.id == resourceId);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
    await StudentNoteController.instance.clearResourceReference(resourceId);
  }

  Future<void> archiveResource(String resourceId) async {
    final index = _resources.indexWhere((r) => r.id == resourceId);
    if (index < 0) return;
    _resources[index] = _resources[index].copyWith(archived: true);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> restoreResource(String resourceId) async {
    final index = _resources.indexWhere((r) => r.id == resourceId);
    if (index < 0) return;
    _resources[index] = _resources[index].copyWith(archived: false);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> toggleFavorite(String resourceId) async {
    final index = _resources.indexWhere((r) => r.id == resourceId);
    if (index < 0) return;
    _resources[index] = _resources[index].copyWith(
      isFavorite: !_resources[index].isFavorite,
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  /// Clears subject references for resources linked to the given subject.
  ///
  /// Preserves the resources themselves — only the link is removed — so
  /// deletion of a subject never silently deletes study material. The resource
  /// stays searchable and editable and can later be linked to another subject.
  Future<void> clearSubjectReference(String subjectId) async {
    var changed = false;
    for (var i = 0; i < _resources.length; i++) {
      if (_resources[i].subjectId == subjectId) {
        _resources[i] = _resources[i].copyWith(clearSubjectId: true);
        changed = true;
      }
    }
    if (changed) {
      await _saveLocal();
      if (!_disposed) notifyListeners();
      _attemptCloudSave();
    }
  }

  /// Clears exam references for resources linked to the given exam.
  ///
  /// Preserves the resources themselves — only the link is removed — so
  /// deletion of an exam never silently deletes study material.
  Future<void> clearExamReference(String examId) async {
    var changed = false;
    for (var i = 0; i < _resources.length; i++) {
      if (_resources[i].examId == examId) {
        _resources[i] = _resources[i].copyWith(clearExamId: true);
        changed = true;
      }
    }
    if (changed) {
      await _saveLocal();
      if (!_disposed) notifyListeners();
      _attemptCloudSave();
    }
  }

  /// Marks a resource as opened — updates lastAccessedAt and accessCount.
  Future<void> markOpened(String resourceId) async {
    final index = _resources.indexWhere((r) => r.id == resourceId);
    if (index < 0) return;
    _resources[index] = _resources[index].copyWith(
      lastAccessedAt: DateTime.now(),
      accessCount: _resources[index].accessCount + 1,
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
